require 'bundler/setup'

require 'mechanize'
require 'reverse_adoc'
require 'vcr'
require 'date'
require 'fileutils'

require 'pry'

require_relative 'asciimath'

VCR.configure do |c|
  c.cassette_library_dir = 'cassettes'
  c.hook_into :webmock
end

CONSIDERATIONS = {
  /(?:having(?: regard)?|ayant|acceptant|concerne|referring|se référant|vu la|agissant conformément)/i => "having / having regard",
  /(?:noting|notes|observing|observant que|taking note|takes note|constatant|constate|that|note|notant|notant que|note également|(?:prend|prenant) (?:acte|note))/i => "noting",
  /(?:recognizing|recognizes|reconnaissant|reconnaît)/i => "recognizing",
  /(?:acknowledging|accept(?:s|ing)|admet|entendu|empowered by|habilité par)/i => "acknowledging",
  /(?:(?:further )?recall(?:ing|s)|rappelant|rappelle)/i => "recalling / further recalling",
  /(?:re-?affirm(?:ing|s)|réaffirme)/i => "reaffirming",
  /(?:consid(?:ering|érant|ers)|après examen|estime)/i => "considering",
  /(?:taking into account|(prend|prenant) en considération|taking into consideration|tenant compte)/i => "taking into account",
  "pursuant to" => "pursuant to",
  /(?:bearing in mind)/i => "bearing in mind",
  /(?:emphasizing|soulignant)/i => "emphasizing",
  "concerned" => "concerned"
}

ACTIONS = {
  /(?:adopts|adopte)/ => "adopts",
  /(?:thanks|expresses[ -]appreciation|appréciant|pays tribute|rend hommage|remercie)/i => "thanks / expresses-appreciation",
  /(?:approu?ves?|approuvant|approving|entérine)/i => "approves",
  /(?:d[eé]cid(?:es|e|é)|ratifies?|judges|d[ée]clares?|d[ée]finition|sanction(?:s|ne))/i => "decides",
  /(?:The unit of length is|Supplementary units|Principl?es|Les Délégués des États|Les v\u{9C}ux ou propositions)/i => "decides", # MISC - like declares/defines
  /(?:L'unité de longueur|Unités supplémentaires|New candle|New lumen|Definitions of|Cubic decimetre|Clarification of|Revision of)/i => "decides", # MISC - like declares/defines
  /(?:Unit of force|Définitions des|Décimètre cube|Étalons secondaires|Unité spéciale|Efficacités lumineuses)/i => "decides", # MISC - like declares/defines
  /(?:asks|souhaite)/i => "asks",
  /(?:further )?invites?|renouvelle en conséquence/i => "invites / further invites",
  "resolves" => "resolves",
  /(?:confirms|confirme|confirme que)/i => "confirms",
  /(?:welcomes|accueille favorablement)/i => "welcomes",
  /recomm(?:ends|ande)/i => "recommends",
  /(?:requests?|demande)/i => "requests",
  "congratulates" => "congratulates",
  "instructs" => "instructs",
  /(?:urges|prie instamment)/i => "urges",
  /(?:appoints|autorise|empowers|charge|donne|habilite|Pendant la période)/i => "appoints",
  "resolves further" => "resolves further",
  /(?:calls upon|attire l'attention|lance un appel)/i => "calls upon",
  /(?:encourages?|espère)/i => "encourages",
  /(?:affirms|reaffirming|réaffirmant|states|remarks|remarques)/i => "affirms / reaffirming",
}

PREFIX=/(?:La Conférence |The Conference |and |et |renouvelle sa |renews its |further |and further |abrogates the |abroge la |En ce qui |après avoir )?/i

SUFFIX=/ (?:that|que)\b|(?: (?:the |that |le |que les )?((?:[A-Z]|national|laboratoires).{0,80}?)(?: to)?\b|)/

module Common
  def replace_links ps, res
    ps.css('a[href]').each do |a|
      href = a.attr('href')

      # Account for some mistakes from an upstream document
      href = href.gsub(%r"\A/jen/", '/en/')
      href = href.gsub(%r"\A/en/CGPM/jsp/", '/en/CGPM/db/')

      href = case href
      when %r'\A/(\w{2})/CGPM/db/(\d+)/(\d+)/(#.*)?\z',
           %r'\A/jsp/(\w{2})/ViewCGPMResolution\.jsp\?CGPM=(\d+)&RES=(\d+)(#.*)?\z'
        "cgpm-resolution:#{$1}/#{$2}/#{$3}#{$4}"
      when %r'\A/(\w{2})/CIPM/db/(\d+)/(\d+)/(#.*)?\z'
        "cipm-resolution:#{$1}/#{$2}/#{$3}#{$4}"
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
      ReverseAdoc.convert(part).strip.gsub("&nbsp;", ' ')
    )
  end

  def parse_resolution res, res_id, date, type = :cgpm
    # Reparse the document after fixing upstream syntax
    fixed_body = res.body.gsub("<name=", "<a name=")
    ng = Nokogiri::HTML(fixed_body, res.uri.to_s, "iso-8859-1", Nokogiri::XML::ParseOptions.new.default_html.noent)

    refs = ng.css('a.intros[href*=".pdf"]')

    r = {
      "dates" => [date],
      "title" => ng.at_css(".txt12pt .SousTitre").text.strip.gsub(/\*\Z/, ''),
      "identifier" => res_id,
      "url" => res.uri.to_s,
      "reference" => nil,

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
    else
      r.delete("reference")
    end

    ps = case type
    when :cgpm
      ng.css('td.txt12pt:not([align])')
    when :cipm
      ng.css('td.txt12pt[align="justify"]')
    end

    #binding.pry if ps.count != 1

    # Replace links
    Common.replace_links(ps, res)

    # Replace a group of centers (> 1) with a table
    Common.replace_centers(ps)

    doc = ps.inner_html.encode('utf-8').gsub("\r", '').gsub(%r'</?nobr>','')
    # doc = AsciiMath.html_to_asciimath(doc)

    parts = doc.split(/(\n(?:<p>)?<b>.*?<\/b>|<p>(?:après examen |après avoir entendu )|having noted that |decides to define |décide de définir |considers that|estime que|declares<\/p>|<a name="_ftn\d)/)
    nparts = [parts.shift]
    while parts.length > 0
      nparts << parts.shift + parts.shift
    end

    if nparts.first =~ /([mM]esures( \(CGPM\))?|CGPM| \(CCTC\)| Conference|\[de thermométrie et calorimétrie\]|,)[ \n]?(<\/p>)?\n?\z/
      r["approvals"].first["message"] = Common.format_message(nparts.shift)
    end

    prev = nil
    nparts.each do |part|
      parse = Nokogiri::HTML(part).text.strip

      CONSIDERATIONS.any? do |k,v|
        if parse =~ /\A#{PREFIX}#{k}\b/i
          r["considerations"] << prev = {
            "type" => v,
            "date_effective" => date,
            "message" => Common.format_message(part),
          }
        end
      end && next

      ACTIONS.any? do |k,v|
        if parse =~ /\A#{PREFIX}#{k}\b/i
          r["actions"] << prev = {
            "type" => v,
            "date_effective" => date,
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

      if parse =~ /\A(becquerel|gray, symbol)/
        prev["message"] += "\n" + Common.format_message(part)
        next
      end

      next if parse == ''

      r["x-unparsed"] ||= []
      r["x-unparsed"] << parse #ReverseAdoc.convert(part).strip
    end

    %w[considerations actions].each do |type|
      map = type == 'actions' ? ACTIONS : CONSIDERATIONS
      r[type] = r[type].map do |i|
        islist = false

        kk = nil

        if map.any? { |k,v| (i["message"].split("\n").first =~ /\A\s*(\*?)(#{PREFIX}#{k})\1?(#{SUFFIX})\1?\s*\z/i) && (kk = k) }
          prefix = $2
          suffix = $3
          subject = $4

          listmarker = nil
          listitems = []
          if (i["message"].split(/(?<!\+)\n/).all? { |j|
            case j
            when /\A\s*\*?#{PREFIX}#{kk}/i
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
