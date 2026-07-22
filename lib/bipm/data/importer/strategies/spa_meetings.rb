# frozen_string_literal: true

require "mechanize"
require "nokogiri"
require "yaml"
require "json"
require "date"
require "fileutils"

module Bipm
  module Data
    module Importer
      module Strategies
        # Scrapes bodies rendered through BIPM's Liferay SPA. Each body
        # exposes index/meetings/publications/(recommendations)/(outcomes)
        # pages whose DOM uses the `.meetings-list__*`, `.bipm-resolutions`,
        # `.bipm-decisions` selectors. Per-meeting and per-recommendation
        # pages are linked from the meetings listing.
        #
        # All requests are wrapped in VCR cassettes for deterministic replays
        # (set `BIPM_VCR_RECORD` env var to refresh).
        class SpaMeetings < Base
          def call(agent:)
            languages.each { |lang| scrape_language(agent, lang) }
          end

          private

          def scrape_language(agent, lang)
            index = { "meetings" => Hash[languages.map { |l| [l.to_s, []] }],
                      "decisions" => Hash[languages.map { |l| [l.to_s, []] }] }

            pages = fetch_pages(agent, lang)
            process_meetings(agent, lang, pages, index)
            write_meetings(lang, index)
            write_publications(agent, lang, pages[:publications])
            puts "* #{body.display_name}/#{lang} parsing done"
          end

          def fetch_pages(agent, lang)
            base = body.url(lang)
            {
              index:           get(agent, lang, "#{base}",                              "index"),
              meetings:        get(agent, lang, "#{base}/meetings",                     "meetings"),
              publications:    get(agent, lang, "#{base}/publications",                 "publications"),
              recommendations: get_optional(agent, lang, "#{base}/recommendations",     "recommendations"),
              outcomes:        get_optional(agent, lang, "#{base}/#{outcomes_subpath}", "outcomes"),
            }
          end

          def outcomes_subpath
            body.id == :cipm ? "outcomes" : "meeting-outcomes"
          end

          def get(agent, lang, url, kind)
            VCR.use_cassette("#{cassette_scope}/#{body.id}-#{kind}#{lang.suffix}") { agent.get(url) }
          end

          def get_optional(agent, lang, url, kind)
            VCR.use_cassette("#{cassette_scope}/#{body.id}-#{kind}#{lang.suffix}") { agent.get(url) }
          rescue Mechanize::ResponseCodeError
            nil
          end

          def cassette_scope
            body.id.to_s
          end

          def process_meetings(agent, lang, pages, index)
            meetings_page = pages[:meetings]
            publications  = pages[:publications]
            recommendations = pages[:recommendations]
            outcomes      = pages[:outcomes]

            meetings_page.css(".meetings-list__item").each do |meeting_div|
              date = Common.extract_date(meeting_div.at_css(".meetings-list__informations-date").text)
              title = meeting_div.at_css(".meetings-list__informations-title").text.strip
              href = meeting_div.at_css(".meetings-list__informations-title").attr("href")
              href = "/#{lang}" + href unless href.start_with?("/#{lang}/")

              ident = href.split("/#{body.id}/").last.gsub("/", ".")
              yr, wg, meeting_id = parse_meeting_identifiers(href)

              meeting = VCR.use_cassette("#{cassette_scope}/#{body.id}-meeting-#{ident}#{lang.suffix}") do
                agent.get(href)
              end

              yr = nil if Quirks.skip_meeting_year?(body.id, meeting_id)

              if yr
                build_meeting_entry(agent, lang, meeting, ident, yr, meeting_id, title, date, recommendations, index)
              end

              if meeting_id
                build_decision_entry(lang, meeting, ident, meeting_id, title, date, wg, outcomes, index)
              end
            end
          end

          def parse_meeting_identifiers(href)
            wg = nil
            yr = href.include?("/wg/") ? nil : href.split("-").last
            meeting_id =
              if href.include?("/wg/")
                wg = href.split("/wg/").last.split("/").first
                href.split("/").last
              else
                parts = href.split("/").last.split("-")
                if parts.length == 2
                  parts[0]
                else
                  parts[0] + parts[1].sub("_", "-")
                end
              end
            [yr, wg, meeting_id]
          end

          def build_meeting_entry(agent, lang, meeting, ident, yr, meeting_id, title, date, recommendations, index)
            pdf = Common.extract_pdf(meeting, lang)

            h = {
              "metadata" => {
                "title" => title,
                "identifier" => meeting_id,
                "date" => date.to_s,
                "source" => "BIPM - Pavillon de Breteuil",
                "url" => meeting.uri.to_s,
              },
            }
            h["pdf"] = pdf if pdf

            resolutions = meeting.css(".bipm-resolutions .publications__content").map do |res_div|
              res_div.at_css("a").attr("href")
            end

            resolutions_additional =
              recommendations&.css(".bipm-resolutions .publications__content")&.map do |res_div|
                Quirks.fix_href(res_div.at_css("a").attr("href"), language: lang.to_s)
              end&.select { |href| href.include?("/#{ident}/") } || []

            resolutions = Quirks.deduplicate_resolutions(body.id, lang, meeting_id, resolutions)
            resolutions = (resolutions + resolutions_additional).uniq

            h["resolutions"] = resolutions.map do |href|
              href = Quirks.fix_href(href, language: lang.to_s)
              res_id = href.split("-").last.to_i
              res = VCR.use_cassette("#{cassette_scope}/#{body.id}-recommendation-#{yr}-#{res_id}#{lang.suffix}") do
                agent.get(href)
              end
              Common.parse_resolution(res, res_id, date, body.id, lang.to_s, "recommendation?")
            end

            index["meetings"][lang.to_s] << h
          end

          def build_decision_entry(lang, meeting, ident, meeting_id, title, date, wg, outcomes, index)
            h = {
              "metadata" => {
                "title" => title,
                "identifier" => meeting_id,
                "date" => date.to_s,
                "source" => "BIPM - Pavillon de Breteuil",
                "url" => meeting.uri.to_s,
              },
            }
            h["metadata"]["workgroup"] = wg if wg

            decisions = meeting.css(".bipm-decisions .decisions")

            if outcomes
              decisions_additional = outcomes.css(".bipm-decisions .decisions").select do |i|
                i["data-meeting_key"] == meeting_id ||
                  i["data-meeting_key"] == "#{meeting_id}-0" ||
                  i["data-meeting"] == meeting_id
              end
              decisions = decisions.to_a + decisions_additional.to_a
            end

            h["resolutions"] = decisions.map { |tr| build_decision(tr, meeting, lang, date) }
            h["resolutions"] = Quirks.renumber_jcrb_43_fr(h["resolutions"]) if [body.id, lang.to_s, meeting_id] == [:jcrb, "fr", "43"]
            h["resolutions"] = h["resolutions"].sort_by do |i|
              [i["type"], i["identifier"].scan(/([0-9]+|[^0-9]+)/).map(&:first).map { |x| x =~ /[0-9]/ ? x.to_i : x }]
            end

            h["working_documents"] = meeting.css(".portlet-boundary_CommitteePublications_ .publications__content").map do |d|
              build_working_document(d)
            end

            index["decisions"][lang.to_s] << h
          end

          def build_decision(titletr, meeting, lang, date)
            title = titletr.at_css(".title-third").text.strip
            type = classify_decision_title(title)
            categories = JSON.parse(titletr.attr("data-decisioncategories") || "[]").map(&:strip).uniq

            r = {
              "dates" => [date.to_s],
              "subject" => body.display_name,
              "type" => type,
              "title" => title,
              "identifier" => "#{titletr.attr('data-meeting')}-#{titletr.attr('data-number')}",
              "url" => meeting.uri.to_s,
              "categories" => categories,
              "considerations" => [],
              "actions" => [],
            }

            contenttr = titletr.attr("data-text").to_s
            if contenttr.empty?
              contenttr = titletr.css("p").map(&:inner_html).join("\n")
            end
            contenttr = Nokogiri::HTML(contenttr)

            Common.replace_links(contenttr, meeting, lang.to_s)
            part = Common.ng_to_string(contenttr)
            part = part.gsub(%r"<a name=\"haut\">(.*?)</a>"m, '\1')
            parse = Nokogiri::HTML(part).text.strip

            parse =~ /\A(((the|le|la|Le secrétaire du|Le président du|Les membres du|Le directeur du) +[BC][IG]PM( Director| President| Secretary| members)?|Dr May|W\.E\. May)[, ]+)/i
            subject = $1
            if subject
              parse = parse[subject.length..-1]
              part = part.gsub(/\A(<html><body>\n*<p>)#{Regexp.escape subject}/, '\1')
            end

            xparse = parse
            (1..1024).each do |pass|
              if try_clause!(r, "considerations", xparse, part, date) then break end
              if try_clause!(r, "actions", xparse, part, date) then break end
              case pass
              when 1, 2, 3
                xparse = xparse.gsub(/\A.*?(CIPM( President| in its meeting)?:?\n*|\((2018|CIPM)\)|de la 103e session) /m, "")
              when 4
                xparse = parse.gsub(/\A.*?, /m, "")
              when 5
                xparse = parse.gsub(/\A.*? (and|et) /m, "")
              else
                r["x-unparsed"] ||= []
                r["x-unparsed"] << parse
                break
              end
            end

            r
          end

          def try_clause!(result, key, xparse, part, date)
            map = key == "actions" ? Clauses::ACTIONS : Clauses::CONSIDERATIONS
            map.each do |k, _|
              if xparse =~ /\A#{Clauses::PREFIX}#{k}\b/i
                result[key] << {
                  "type" => map[k],
                  "date_effective" => date.to_s,
                  "message" => Common.format_message(part),
                }
                return true
              end
            end
            false
          end

          def classify_decision_title(title)
            case title
            when /\AD[eé]cision/ then "decision"
            when /\AR[eé]solution/ then "resolution"
            when /\AAction/ then "action"
            when /\ARecomm[ae]ndation/ then "recommendation"
            else "decision"
            end
          end

          def build_working_document(d)
            date_str = d.at_css(".publications__date")&.text&.strip
            date_str = Date.parse(date_str).strftime("%d/%m/%Y") if date_str
            {
              "title" => d.at_css(".title-third").text.strip,
              "pdf" => d.at_css(".title-third").attr("href"),
              "description" => d.css(".publications__body").first.text.strip,
              "author" => d.css(".publications__body").last.text.strip,
              "date" => date_str,
            }.compact
          end

          def write_meetings(lang, index)
            parts = index["meetings"][lang.to_s] + index["decisions"][lang.to_s]
            parts = parts.group_by { |i| [i["metadata"]["workgroup"].to_s, i["metadata"]["identifier"].to_s] }
            parts = parts.sort_by { |(wg, i),| [wg, i.to_i, i] }.to_h

            parts.each do |(wg, mid), hs|
              h = {
                "metadata" => hs.first["metadata"],
                "pdf" => hs.first["pdf"],
                "resolutions" => hs.map { |i| i["resolutions"] }.sum([]),
                "working_documents" => hs.map { |i| i["working_documents"] || [] }.sum([]),
              }

              h.delete("pdf") unless h["pdf"]
              h.delete("working_documents") if h["working_documents"].empty?

              fn = if wg
                     "#{base_dir}/#{body.id}/workgroups/#{wg}/meetings#{lang.directory_suffix}/meeting-#{mid}.yml"
                   elsif body.id == :cgpm
                     "#{base_dir}/#{body.id}/meetings#{lang.directory_suffix}/meeting-#{format('%02d', mid.to_i)}.yml"
                   else
                     "#{base_dir}/#{body.id}/meetings#{lang.directory_suffix}/meeting-#{mid}.yml"
                   end

              FileUtils.mkdir_p(File.dirname(fn))
              File.write(fn, YAML.dump(h))
            end
          end

          def write_publications(agent, lang, publications)
            return unless publications
            categories = publications.css(".publications").map do |i|
              title = i.previous_element&.text&.strip || "Misc"
              {
                "title" => title,
                "documents" => i.css(".publications__content").map do |d|
                  {
                    "title" => d.at_css(".title-third").text.strip.gsub(/\s+/, " "),
                    "pdf" => d.at_css(".title-third")&.attr("href")&.split("?")&.first,
                  }.compact
                end,
              }
            end
            return if categories.empty?

            doc = {
              "metadata" => { "url" => "#{body.url(lang)}/publications/" },
              "categories" => categories,
            }
            File.write("#{base_dir}/#{body.id}/publications-#{lang}.yml", YAML.dump(doc))
          end
        end
      end
    end
  end
end
