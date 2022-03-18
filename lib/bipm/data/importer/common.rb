require 'mechanize'
require 'reverse_adoc'
require 'vcr'
require 'date'
require 'fileutils'
require_relative 'asciimath'

VCR.configure do |c|
  c.cassette_library_dir = __dir__+'/../../../../cassettes'
  c.hook_into :webmock
end

module Bipm
  module Data
    module Importer

      CONSIDERATIONS = {
        /(?:having(?: regard)?|ayant|concerne|vu la|agissant conformément|sachant)/i => "having / having regard",
        /(?:noting|took note|note[sd]?|taking note|takes note|constatant|constate|that|notant|notant que|note également|(?:prend|prenant) (?:acte|note))/i => "noting",
        /(?:recognizing|recognizes|reconnaissant|reconnaît)/i => "recognizing",
        /(?:acknowledging|admet|entendu|and aware that)/i => "acknowledging",
        /(?:(?:further )?recall(?:ing|s|ed)|rappelant|rappelle|rappelantla)/i => "recalling / further recalling",
        /(?:re-?affirm(?:ing|s)|réaffirme)/i => "reaffirming",
        /(?:consid(?:ering|érant|ère|ers|ered|érantque|érantle)|après examen|estime|is of the opinion|examinera|en raison|by reason)/i => "considering",
        /(?:taking into account|(prend|prenant) en considération|taking into consideration|tenant compte)/i => "taking into account",
        "pursuant to" => "pursuant to",
        /(?:bearing in mind)/i => "bearing in mind",
        /(?:emphasizing|soulignant)/i => "emphasizing",
        "concerned" => "concerned",
        /(?:accept(?:s|ed|ing|e)|acceptant)/i => "accepts",
        /(?:observing|observant que)/i => "observing",
        /(?:referring|se référant)/i => "referring",
        /(?:acting in accordance|agissant conformément|conformément)/i => "acting",
        /(?:empowered by|habilité par)/i => "empowers",
      }

      ACTIONS = {
        /(?:adopts|adopt[eé]d?|convient d'adopter)/ => "adopts",
        /(?:thanks|thanked|expresse[sd](?:[ -]| its )appreciation|appréciant|pays tribute|rend hommage|remercie|strongly supports)/i => "thanks / expresses-appreciation",
        /(?:approu?v[eé][ds]?|approuv[ae]nt|approving|entérine|agreed?|supported|soutient|exprime son accord|n'est pas d'accord|convient)/i => "approves",
        /(?:d[eé]cid(?:e[ds]?|é)|ratifies?|r[eé]vised?)/i => "decides",
        /(?:d[ée]clares?|d[ée]finition)/i => "declares",
        /(?:The unit of length is|Supplementary units|Derived units|Principl?es|Les Délégués des États|Les v(?:œ|\u{9C})ux ou propositions)/i => "declares",
        /(?:L'unité de longueur|Unités supplémentaires|Unités dérivées|(?:\*_)?New candle|(?:\*_)?New lumen|(?:A\) )?D[ée]finitions (?:of|des)|Cubic decimetre|Clarification of|Revision of)/i => "declares",
        /(?:Unit of force|Définitions des|Décimètre cube|Étalons secondaires|Unité spéciale|Efficacités lumineuses|From three names|Entre les trois termes)/i => "declares",
        /(?:Unité de force|(?:Joule|Watt|Volt|Ohm|Amp[eè]re|Coulomb|Farad|Henry|Weber) \(unité?|Bougie nouvelle|Lumen nouveau|announces that|annonce que)/i => "declares",
        /(?:Les unités photométriques|\(A\) D[eé]finitions|The photometric units|will (?:provide|circulate|issue|identify|notify|contact|review))/i => "declares",
        /(?:Appendix 1 of the|L'Annexe 1 de la|increased|a (?:examiné|préparé)|transmettra|fournira|increased|developed a document|prendra contact)/i => "declares",
        /(?:Le Temps Atomique International |International Atomic Time \(TAI\) )/i => "declares",
        /(?:asks|asked|souhaite|souhaiterait)/i => "asks",
        /(?:(?:further )?invit(?:[ée][ds]?|era)|renouvelle en conséquence|convient d'inviter)/i => "invites / further invites",
        /(?:resolve[sd]?)/i => "resolves",
        /(?:confirms|confirmed?|confirme que)/i => "confirms",
        /(?:welcome[sd]?|accueille favorablement(?:les)?|salue)/i => "welcomes",
        /(?:recomm(?:ends|ande|ended)|endorsed|LISTE DES RADIATIONS|1 Radiations recommandées|LIST OF RECOMMENDED|1 Recommended radiations)/i => "recommends",
        /(?:requests?|requested|demande(?:ra)?|requiert)/i => "requests",
        /(?:congratulate[sd]?|félicite)/i => "congratulates",
        /(?:instructs|instructed|informe)/i => "instructs",
        /(?:urges|prie instamment)/i => "urges",
        /(?:appoints|(?:re)?appointed|granted|reconduit|commended|accorde)/i => "appoints",
        /(?:donn(?:e|ées)|Pendant la période|voted|established a \w+ task group)/i => "appoints",
        /(?:convient d'éablir|transfère|confie|établit|Étant donné que trois sièges|As there will be three vacancies)/i => "appoints",
        /(?:La Recommandation 1 du Groupe|Recommendation 1 of the ad hoc)/i => "appoints",
        /(?:élit|nomme|elected|nominated)/ => "elects",
        /(?:gave the \w+ \w+ the authority|autorise|authorized)/ => "authorizes",
        /(?:charged?)/ => "charges",
        /(?:resolve[sd]? further)/i => "resolves further",
        /(?:calls upon|draws the attention|attire l'attention|lance un appel|called upon)/i => "calls upon",
        /(?:encourages?d?|espère|propose[ds]?)/i => "encourages",
        /(?:affirms|reaffirming|réaffirmant)/i => "affirms / reaffirming",
        /(?:states)/i => "states",
        /(?:remarks|remarques)/i => "remarks",
        /(?:judges)/i => "judges",
        /(?:sanction(?:s|né?e))/i => "sanctions",
        /(?:abrogates|abroge)/i => "abrogates",
        /(?:empowers|habilite)/i => "empowers",
      }

      PREFIX1=/(?:The|Le) CIPM |La Conférence |M. Volterra |M. le Président |unanimously |would |a |sont |will |were |did not |strongly |(?:La|The) (?:\d+(?:e|th)|Quinzième) Conférence Générale des Poids et Mesures(?: a |,\s+)?/i
      PREFIX2=/The \d+th Conférence Générale des Poids et Mesures |The Conference |and |et |has |renouvelle sa |renews its |further |and further |En ce qui |après avoir |\.\.\.\n+\t*/i
      PREFIX3=/Sur la proposition de M. le Président, la convocation de cette Conférence de Thermométrie est |Le texte corrigé, finalement |(?:The|Le) Comité International(?: des Poids et Mesures)?(?: \(CIPM\))?(?: a |,)?\s*/i

      PREFIX=/(?:#{PREFIX1}|#{PREFIX2}|#{PREFIX3})?/i

      SUFFIX=/ (?:that|que)\b|(?: (?:the |that |le |que les )?((?:[A-Z]|national|laboratoires).{0,80}?)(?: to)?\b|)/

      module Common
        def replace_links ps, res, lang
          ps.css('a[href]').each do |a|
            href = a.attr('href')

            href = href.gsub(%r'\Ahttps://www.bipm.org/', '')

            # Correct links
            href = href.gsub('/web/guest/', "/#{lang}/")

            # Account for some mistakes from an upstream document
            href = href.gsub(%r"\A/jen/", '/en/')
            href = href.gsub(%r"\A/en/CGPM/jsp/", '/en/CGPM/db/')

            href = case href
            when %r'\A/(\w{2})/CGPM/db/(\d+)/(\d+)/(#.*)?\z',
                 %r'\A/jsp/(\w{2})/ViewCGPMResolution\.jsp\?CGPM=(\d+)&RES=(\d+)(#.*)?\z',
                 %r'\A/(\w{2})/committees/cg/cgpm/(\d+)-\d+/resolution-(\d+)(#.*)?\z',
              "cgpm-resolution:#{$1}/#{$2}/#{$3}#{$4}"
            when %r'\A/(\w{2})/CIPM/db/(\d+)/(\d+)/(#.*)?\z'
              "cipm-resolution:#{$1}/#{$2}/#{$3}#{$4}"
            when %r'\A/(\w{2})/committees/cipm/meeting/([0-9()I]+).html(#.*)?\z'
              "cipm-decisions:#{$1}/#{$2}#{$3}"
            else
              URI(res.uri).merge(href).to_s # Relative -> absolute
            end

            a.set_attribute('href', href)
          end
        end

        def replace_centers ps
          centers = ps.css('center').to_a
          while centers.length > 0
            center = centers.first
            current = center
            mycenters = [center]
            loop do
              break unless current.next
              while Nokogiri::XML::Text === current.next
                current = current.next
                break if current.text.strip != ''
              end
              break unless current.next
              break unless current.next.name == "center"
              current = current.next
              mycenters << current
            end
            centers -= mycenters
            if mycenters.length > 1
              newtable = Nokogiri::HTML::Builder.new do |doc|
                doc.table {
                  mycenters.each do |i|
                    doc.tr {
                      doc.td {
                        doc << i.inner_html
                      }
                    }
                  end
                }
              end.to_html
              mycenters.first.replace newtable
              mycenters[1..-1].each &:remove
            end
          end

          # Remove the remaining centers
          ps.css('center').each do |i|
            i.replace i.inner_html
          end
        end

        def format_message part
          AsciiMath.asciidoc_extract_math(
            ReverseAdoc.convert(part).strip.gsub("&nbsp;", ' ').gsub(" \n", "\n")
          )
        end

        def ng_to_string ps
          ps.inner_html.encode('utf-8').gsub("\r", '').gsub(%r'</?nobr>','')
        end

        def parse_resolution res, res_id, date, type = :cgpm, lang = 'en'
          # Reparse the document after fixing upstream syntax
          fixed_body = res.body.gsub("<name=", "<a name=")
          fixed_body = fixed_body.force_encoding('utf-8')
          fixed_body = fixed_body.gsub('&Eacute;', 'É')
          fixed_body = fixed_body.gsub('&#171;&#032;', '« ')
          fixed_body = fixed_body.gsub('&#032;&#187;', ' »')
          fixed_body = fixed_body.sub(%r'<h1>.*?</h1>'m, '')
          fixed_body = fixed_body.sub(%r'<h2>(.*?)</h2>'m, '')
          title = $1
          fixed_body = fixed_body.sub(/(="web-content">)\s*<p>\s*(<p)/, '\1\2')
          fixed_body = fixed_body.gsub(%r"<a name=\"haut\">(.*?)</a>"m, '\1')
          ng = Nokogiri::HTML(fixed_body, res.uri.to_s, "utf-8", Nokogiri::XML::ParseOptions.new.default_html.noent)

          refs = ng.css('.publication-card_reference a')

          r = {
            "dates" => [date.to_s],
            "title" => title.strip,
            "identifier" => res_id,
            "url" => res.uri.to_s,
            "reference" => nil,
            "reference_name" => nil,
            "reference_page" => nil,

            "approvals" => [{
              "type" => "affirmative",
              "degree" => "unanimous",
              "message" => "Unanimous"
            }],

            "considerations" => [],
            "actions" => [],
          }

          if refs.length > 0
            r["reference"] = res.uri.merge(refs.first.attr('href')).to_s
            name, page = refs.first.text.strip.split(/, p(?=[0-9])/)
            r["reference_name"] = name
            if page
              r["reference_page"] = page.to_i
            else
              r.delete("reference_page")
            end
          else
            r.delete("reference")
            r.delete("reference_name")
            r.delete("reference_page")
          end

          ps = ng.css('div.journal-content-article').first

          #binding.pry if ps.count != 1

          # Replace links
          Common.replace_links(ps, res, lang)

          # Replace a group of centers (> 1) with a table
          Common.replace_centers(ps)

          doc = Common.ng_to_string(ps)
          # doc = AsciiMath.html_to_asciimath(doc)

          parts = doc.split(/(\n(?:<p>)?<b>.*?<\/b>|\n<p><i>.*?<\/i>|<div class="bipm-lame-grey">|<h3>|<p>(?:après examen |après avoir entendu )|having noted that |decides to define |décide de définir |conformément à l'invitation|acting in accordance with|recommande que les résultats|(?:considers|recommends|recommande) (?:that|que(?! « ))|estime que|declares<\/p>|déclare :<\/b><\/p>|<a name="_ftn\d)/)
          nparts = [parts.shift]
          while parts.length > 0
            nparts << parts.shift + parts.shift
          end

          if nparts.first =~ /(,|[mM]esures( \(C[GI]PM\))?|CGPM| \(CCTC\)| Conf[eé]rence|\[de thermométrie et calorimétrie\])[ \n]?(<\/p>)?\n?(\n|\n<p>[[:space:]]<\/p>\n)?\t?\z/
            r["approvals"].first["message"] = Common.format_message(nparts.shift)
          end

          prev = nil
          nparts.each do |part|
            parse = Nokogiri::HTML(part).text.strip

            if parse.start_with? /r[eé]f[eé]rence/
              next
            end

            if parse.start_with? 'NOTE'
              part = part.sub('<h3>NOTE</h3>', '')
              r["notes"] = Common.format_message(part)
              next
            end

            CONSIDERATIONS.any? do |k,v|
              if parse =~ /\A#{PREFIX}#{k}\b/i
                r["considerations"] << prev = {
                  "type" => v,
                  "date_effective" => date.to_s,
                  "message" => Common.format_message(part),
                }
              end
            end && next

            ACTIONS.any? do |k,v|
              if parse =~ /\A#{PREFIX}#{k}\b/i
                r["actions"] << prev = {
                  "type" => v,
                  "date_effective" => date.to_s,
                  "message" => Common.format_message(part),
                }
              end
            end && next

            if parse =~ /\A(?:Appendix |Annexe |\()(\d+)/
              r["appendices"] ||= []
              r["appendices"] << prev = {
                "identifier" => $1.to_i,
                "message" => Common.format_message(part),
              }
              next
            end

            if parse =~ /\A((becquerel|gray, symbol)|\d\.|2 (Recommended|Valeurs)|«[[:space:]]?11\.)/
              prev["message"] += "\n" + Common.format_message(part)
              next
            end

            next if parse =~ /\A(|\[Cliquer ici\]|Click here|\.\.\.)\z/

            r["x-unparsed"] ||= []
            r["x-unparsed"] << parse #ReverseAdoc.convert(part).strip
          end

          %w[considerations actions].each do |type|
            map = type == 'actions' ? ACTIONS : CONSIDERATIONS
            r[type] = r[type].map do |i|
              islist = false

              kk = nil

              if map.any? { |k,v| (i["message"].split("\n").first =~ /\A\s*([*_]?)(#{PREFIX}#{k})\1?(#{SUFFIX})\1?\s*\z/i) && (kk = k) }
                prefix = $2
                suffix = $3
                subject = $4

                listmarker = nil
                listitems = []
                if (i["message"].split(/(?<!\+)\n/).all? { |j|
                  case j
                  when /\A\s*[*_]?#{PREFIX}#{kk}/i
                    true
                  when /\A\s*\z/
                    true
                  when /\A(\. |\* | )(\S.*?)\z/m
                    listitems << $2
                    listmarker = $1 if !listmarker
                    listmarker == $1
                  else
                    false
                  end
                })
                  islist = true if listitems.length >= 1
                end
              end

              if subject
                #p subject
                r['subject'] ||= []
                r['subject'] << subject
              end

              if islist
                suffix = suffix.strip
                suffix = nil if suffix == ''
                listitems.map do |li|
                  i.merge 'message' => [prefix, suffix, li].compact.join(" ")
                end
              else
                i
              end
            end.flatten
          end

          if r['subject']
            r['subject'] = r['subject'].uniq.join(" and ")
          end

          r
        end

        extend self
      end

    end
  end
end
