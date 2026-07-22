# frozen_string_literal: true

require "mechanize"
require "nokogiri"
require "yaml"
require "date"
require "fileutils"

module Bipm
  module Data
    module Importer
      # Scrape CGPM resolutions from bipm.org.
      #
      # The BIPM website was rewritten as a Liferay SPA; the meeting-list
      # selectors used by the rest of Importer for other bodies
      # (.bipm-resolutions, .bipm-decisions) match zero elements on CGPM
      # pages. CGPM is reachable via a still-static index at
      # /{en,fr}/worldwide-metrology/cgpm/resolutions.html, and each
      # resolution page is server-rendered HTML. This module handles
      # that special case and is invoked from exe/bipm-fetch when the
      # body is :CGPM.
      module CGPM
        INDEX_URL = {
          "en" => "https://www.bipm.org/en/worldwide-metrology/cgpm/resolutions.html",
          "fr" => "https://www.bipm.org/fr/worldwide-metrology/cgpm/resolutions.html",
        }.freeze

        CONSIDERATION_VERBS = %w[
          having considering noting recognizing acknowledging recalling reaffirming
          taking pursuant bearing emphasizing concerned accepts observing referring acting
        ].freeze

        ACTION_VERBS = %w[
          adopts thanks approves decides declares asks invites resolves confirms
          welcomes recommends requests congratulates instructs urges appoints
          encourages affirms elects authorizes charges states remarks judges
          sanctions abrogates empowers
        ].freeze

        FR_VERB_TO_EN = {
          "considérant"    => "considering",
          "notant"         => "noting",
          "note"           => "notes",
          "reconnaissant"  => "recognizing",
          "rappelant"      => "recalling",
          "réaffirmant"    => "reaffirming",
          "tenant"         => "taking",
          "soulignant"     => "emphasizing",
          "concerné"       => "concerned",
          "accepte"        => "accepts",
          "observant"      => "observing",
          "se référant"    => "referring",
          "agissant"       => "acting",
          "habilité"       => "empowers",
          "habilite"       => "empowers",
          "décide"         => "decides",
          "déclare"        => "declares",
          "invite"         => "invites",
          "résout"         => "resolves",
          "confirme"       => "confirms",
          "accueille"      => "welcomes",
          "recommande"     => "recommends",
          "demande"        => "requests",
          "nomme"          => "appoints",
          "encourage"      => "encourages",
          "affirme"        => "affirms",
          "lance un appel" => "calls",
          "indique"        => "states",
          "remarques"      => "remarks",
          "prie"           => "urges",
          "informe"        => "instructs",
          "adopte"         => "adopts",
          "remercie"       => "thanks",
          "approuve"       => "approves",
          "souhaite"       => "asks",
          "félicite"       => "congratulates",
          "élit"           => "elects",
          "autorise"       => "authorizes",
          "juge"           => "judges",
          "sanctionne"     => "sanctions",
          "abroge"         => "abrogates",
          "ayant"          => "having",
          "vu"             => "having",
          "reconnaît"      => "recognizing",
          "rappelle"       => "recalling",
          "réalise"        => "observing",
        }.freeze

        VERB_TO_TYPE = {
          "having"         => "having / having regard",
          "considering"    => "considering",
          "noting"         => "noting",
          "notes"          => "notes",
          "recognizing"    => "recognizing",
          "reaffirming"    => "reaffirming",
          "recalling"      => "recalling / further recalling",
          "acknowledging"  => "acknowledging",
          "taking"         => "taking into account",
          "pursuant"       => "pursuant to",
          "bearing"        => "bearing in mind",
          "emphasizing"    => "emphasizing",
          "concerned"      => "concerned",
          "accepts"        => "accepts",
          "observing"      => "observing",
          "referring"      => "referring",
          "acting"         => "acting",
          "empowers"       => "empowers",
          "decides"        => "decides",
          "declares"       => "declares",
          "invites"        => "invites / further invites",
          "resolves"       => "resolves",
          "confirms"       => "confirms",
          "welcomes"       => "welcomes",
          "recommends"     => "recommends",
          "requests"       => "requests",
          "appoints"       => "appoints",
          "encourages"     => "encourages",
          "affirms"        => "affirms / reaffirming",
          "calls"          => "calls upon",
          "states"         => "states",
          "remarks"        => "remarks",
          "urges"          => "urges",
          "instructs"      => "instructs",
          "adopts"         => "adopts",
          "thanks"         => "thanks / expresses-appreciation",
          "approves"       => "approves",
          "asks"           => "asks",
          "congratulates"  => "congratulates",
          "elects"         => "elects",
          "authorizes"     => "authorizes",
          "charges"        => "charges",
          "judges"         => "judges",
          "sanctions"      => "sanctions",
          "abrogates"      => "abrogates",
        }.freeze

        module_function

        def normalize_verb(raw)
          v = raw.to_s.downcase.strip.sub(/[.:,;]\z/, "").strip
          v = v.sub(/\A(?:et|and|further|de plus|puis|also)\s+/, "").strip
          FR_VERB_TO_EN[v] || v
        end

        def parse_date_text(text)
          text = text.strip.gsub(/\s+/, " ")
          text.gsub!("février", "february")
          text.gsub!("avril", "april")
          text.gsub!("mai", "may")
          text.gsub!("juin", "june")
          text.gsub!("juillet", "july")
          text.gsub!(/ao[uû]t/i, "august")
          text.gsub!("décembre", "december")
          text.gsub!(/janvier/i, "january")
          text.gsub!(/f[eé]vrier/i, "february")
          text.gsub!(/mars/i, "march")
          text.gsub!(/septembre/i, "september")
          text.gsub!(/octobre/i, "october")
          text.gsub!(/novembre/i, "november")
          candidates = text.split(/, | to | au | – | — /).map(&:strip).reject(&:empty?)
          Date.parse(candidates.last || text).iso8601
        rescue Date::Error
          nil
        end

        def flush_clause(verb, message_parts, list_items, considerations, actions, date_str)
          full_message = message_parts.concat(list_items).reject(&:empty?).join("\n").gsub(/\s+/, " ").strip
          return if full_message.empty?

          mapped = VERB_TO_TYPE.fetch(verb) do
            if CONSIDERATION_VERBS.include?(verb) then "considering"
            elsif ACTION_VERBS.include?(verb) then "decides"
            else "decides"
            end
          end
          clause = { "type" => mapped, "date_effective" => date_str, "message" => full_message }

          if CONSIDERATION_VERBS.include?(verb) || verb == "having"
            considerations << clause
          else
            actions << clause
          end
        end

        def normalize_res_url(url)
          url.to_s.sub(%r{/(en|fr)/committees/}, "/committees/")
        end

        def extract_resolution_urls(listing_html, lang)
          doc = Nokogiri::HTML(listing_html)
          doc.css("a").map do |link|
            href = link["href"].to_s
            next nil unless href =~ %r{/committees/cg/cgpm/\d+-\d+/resolution-\d+\z}
            path = href.sub(%r{^https?://[^/]+}, "").sub(%r{^/(?:en|fr)?/?(?=committees)}, "")
            "https://www.bipm.org/#{lang}/#{path}"
          end.compact.uniq
        end

        def parse_resolution(page, _lang)
          return nil unless page
          doc = Nokogiri::HTML(page.body)
          article = doc.at_css("div.journal-content-article") ||
                    doc.at_css("div.asset-entry") ||
                    doc.css("div").find { |d| d.inner_html.include?("Resolution") && d.inner_html.size > 1000 }
          return nil unless article

          h1 = article.at_css("h1")
          h1_text = h1&.text&.strip&.gsub(/\s+/, " ")
          h2s = article.css("h2").map { |h| h.text.strip }
          code_h2 = h2s.find { |t| t =~ /^Resolution-CGPM-\d+-\d+\z/i }
          subject_h2 = h2s.find { |t| t != code_h2 && t !~ /^(CGPM logo|Menu Display)$/i }

          res_id = nil
          meeting_id = nil
          year = nil
          if h1_text
            en_m = h1_text.match(/(?:Resolution|Declaration|Recommendation)\s+(\d+)\s+of\s+the\s+(\d+)(?:st|nd|rd|th)?\s+CGPM(?:\s*\((\d{4})\))?/i)
            fr_m = h1_text.match(/(?:R[ée]solution|D[ée]claration|Recommandation)\s+(\d+)\s+de la\s+(\d+)[eè]?(?:\s+CGPM)(?:\s*\((\d{4})\))?/i)
            if (m = en_m || fr_m)
              res_id = m[1].to_i
              meeting_id = m[2].to_i
              year = m[3]
            end
          end

          date_str = nil
          if (date_node = doc.at_css("p.session__date"))
            date_str = parse_date_text(date_node.text)
          end
          date_str ||= year ? "#{year}-01-01" : nil

          reference_url = nil
          reference_name = nil
          reference_page = nil
          article.css("a").each do |link|
            text = link.text.strip
            href = link["href"].to_s
            next unless href.include?("/documents/")
            next unless text =~ /Proceedings of the\s+(\d+)(?:st|nd|rd|th)?\s+CGPM/i
            reference_name = text
            reference_url = href
            reference_page = Regexp.last_match(1).to_i if text =~ /p(\d+)\s*\z/
            break
          end

          considerations = []
          actions = []
          approvals = []

          preamble = article.css("p").map(&:text).find { |t| t =~ /General Conference|CGPM.*meeting/i }

          current_verb = nil
          current_message_parts = []
          current_list_items = []

          article.children.each do |node|
            next unless node.element? || node.text?
            next if node.name == "script" || node.name == "style"

            if node.name == "p"
              b = node.at_css("b")
              if b
                verb_text = normalize_verb(b.text)
                rest = node.dup
                rest.at_css("b").remove
                rest_text = rest.text.strip.gsub(/\s+/, " ")
                if current_verb
                  flush_clause(current_verb, current_message_parts, current_list_items, considerations, actions, date_str)
                  current_message_parts = []
                  current_list_items = []
                end
                current_verb = verb_text
                current_message_parts << rest_text if rest_text && !rest_text.empty?
              elsif current_verb && (text = node.text.strip) && !text.empty?
                current_message_parts << text
              end
            elsif node.name == "ul" && current_verb
              node.css("li").each do |li|
                current_list_items << li.text.strip.gsub(/\s+/, " ")
              end
            end
          end
          flush_clause(current_verb, current_message_parts, current_list_items, considerations, actions, date_str) if current_verb

          if preamble
            approvals << { "message" => preamble.strip, "date_effective" => date_str }
          end

          {
            "metadata" => {
              "title" => h1_text || "CGPM Resolution",
              "identifier" => res_id&.to_s,
              "date" => date_str,
              "source" => "BIPM - Pavillon de Breteuil",
              "url" => page.uri.to_s,
            },
            "resolutions" => [{
              "dates" => [date_str].compact,
              "subject" => "CGPM",
              "type" => "resolution",
              "title" => subject_h2 || h1_text,
              "identifier" => res_id&.to_s,
              "url" => page.uri.to_s,
              "reference" => reference_url,
              "reference_name" => reference_name,
              "reference_page" => reference_page,
              "approvals" => approvals,
              "considerations" => considerations,
              "actions" => actions,
            }],
            "_meeting_id" => meeting_id&.to_s,
            "_year" => year,
          }
        rescue => e
          warn "[cgpm] parse_resolution failed for #{page&.uri}: #{e.message}"
          nil
        end

        # Public entry point. +agent+ is a Mechanize instance (shared with
        # the rest of bipm-fetch for connection reuse); +base_dir+ is the
        # output root (e.g. "data").
        def run(agent, base_dir)
          a = agent

          puts "[cgpm] Fetching listing pages..."
          listing = {}
          INDEX_URL.each do |lang, url|
            listing[lang] = a.get(url)
            puts "[cgpm] #{lang.upcase} listing: #{listing[lang].body.size} bytes"
          rescue => e
            warn "[cgpm] FAILED to fetch #{lang.upcase} listing: #{e.message}"
            listing[lang] = nil
          end

          urls_by_lang = listing.each_with_object({}) do |(lang, page), h|
            h[lang] = page ? extract_resolution_urls(page.body, lang) : []
          end
          en_urls = urls_by_lang["en"] || []
          fr_urls = urls_by_lang["fr"] || []
          en_by_norm = en_urls.each_with_object({}) { |u, h| h[normalize_res_url(u)] = u }
          fr_by_norm = fr_urls.each_with_object({}) { |u, h| h[normalize_res_url(u)] = u }
          all_norm = (en_by_norm.keys + fr_by_norm.keys).uniq.sort
          puts "[cgpm] EN: #{en_urls.size}, FR: #{fr_urls.size}, paired: #{all_norm.size}"

          meetings = {}

          all_norm.each_with_index do |norm_url, idx|
            parsed = {}
            [en_by_norm[norm_url], fr_by_norm[norm_url]].compact.each do |url|
              lang = url[%r{/(fr)/committees/}, 1] || "en"
              page = a.get(url)
              sleep 0.5
              parsed[lang] = parse_resolution(page, lang)
              next unless parsed[lang]
              mid = parsed[lang].delete("_meeting_id")
              year = parsed[lang].delete("_year")
              next unless mid
              meetings[mid] ||= { "year" => year, "resolutions" => {}, "meta" => {} }
              meetings[mid]["year"] ||= year
              meetings[mid]["meta"][lang] = parsed[lang]["metadata"]
              parsed[lang]["resolutions"]&.each do |res|
                meetings[mid]["resolutions"][lang] ||= {}
                meetings[mid]["resolutions"][lang][res["identifier"].to_s] = res
              end
            rescue => e
              warn "[cgpm] fetch #{lang} #{url} failed: #{e.class}: #{e.message}"
            end
            puts "[cgpm] (#{idx + 1}/#{all_norm.size}) #{norm_url} -> EN=#{!!parsed["en"]} FR=#{!!parsed["fr"]}"
          end

          puts "[cgpm] Fetching #{meetings.size} meeting session pages..."
          meetings.each_value do |data|
            data["resolutions"].each do |lang, res_map|
              next if res_map.empty?
              sample_res = res_map.values.first
              next unless sample_res && sample_res["url"]
              meeting_url = sample_res["url"].sub(%r{/resolution-\d+\z}, "")
              page = a.get(meeting_url)
              sleep 0.3
              doc = Nokogiri::HTML(page.body)
              if (title_node = doc.at_css("h1.session__title, .journal-content-article h1"))
                data["meta"][lang] ||= {}
                data["meta"][lang]["title"] = title_node.text.strip.gsub(/\s+/, " ")
              end
              if (date_node = doc.at_css("p.session__date")) && (parsed_date = parse_date_text(date_node.text))
                data["meta"][lang] ||= {}
                data["meta"][lang]["date"] = parsed_date
                res_map.each_value do |res|
                  res["dates"] = [parsed_date]
                  res["considerations"]&.each { |c| c["date_effective"] = parsed_date }
                  res["actions"]&.each { |x| x["date_effective"] = parsed_date }
                  res["approvals"]&.each { |x| x["date_effective"] = parsed_date }
                end
              end
            rescue => e
              warn "[cgpm] meeting page fetch #{lang} #{meeting_url} failed: #{e.message}"
            end
          end

          FileUtils.mkdir_p("#{base_dir}/cgpm/meetings-en")
          FileUtils.mkdir_p("#{base_dir}/cgpm/meetings-fr")

          written = { "en" => 0, "fr" => 0 }
          meetings.sort.each do |mid, data|
            data["resolutions"].each do |lang, res_map|
              res_map = res_map.reject { |_, r| r.nil? }
              next if res_map.empty?
              res_list = res_map.sort_by { |rid, _| rid.to_i }.map { |_, r| r }
              first = res_list.first
              next unless first

              meeting_meta = (data["meta"][lang] || {}).dup
              meeting_meta["title"]    ||= "CGPM meeting #{mid}"
              meeting_meta["date"]     ||= data["year"] ? "#{data["year"]}-01-01" : nil
              meeting_meta["identifier"] = mid.to_s
              meeting_meta["url"]        = (first["url"] || meeting_meta["url"])&.sub(%r{/resolution-\d+\z}, "")
              meeting_meta["source"]   ||= "BIPM - Pavillon de Breteuil"

              payload = { "metadata" => meeting_meta, "resolutions" => res_list }
              path = "#{base_dir}/cgpm/meetings-#{lang}/meeting-#{format('%02d', mid.to_i)}.yml"
              File.write(path, YAML.dump(payload))
              written[lang] += 1
            end
          end

          total_res = meetings.values.sum { |m| (m["resolutions"]["en"] || {}).size }
          puts "[cgpm] Wrote #{written["en"]} EN + #{written["fr"]} FR meeting files across #{meetings.size} CGPM sessions (#{total_res} EN resolutions)."
        end
      end
    end
  end
end
