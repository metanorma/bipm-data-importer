require 'bundler/setup'

require 'mechanize'
require 'reverse_adoc'
require 'vcr'
require 'date'
require 'fileutils'

require 'pry'

VCR.configure do |c|
  c.cassette_library_dir = 'cassettes'
  c.hook_into :webmock
end

CONSIDERATIONS = {
  /(?:having(?: regard)?|ayant|acceptant|concerne|referring|se référant|vu la)/i => "having / having regard",
  /(?:noting|notes|observing|observant que|taking note|takes note|constatant|constate|that|note|notant|notant que|(?:prend|prenant) (?:acte|note))/i => "noting",
  /(?:recognizing|recognizes|reconnaissant|reconnaît)/i => "recognizing",
  /(?:acknowledging|accept(?:s|ing)|admet|entendu)/i => "acknowledging",
  /(?:(?:further )?recall(?:ing|s)|rappelant|rappelle)/i => "recalling / further recalling",
  /(?:re-?affirm(?:ing|s)|réaffirme)/i => "reaffirming",
  /(?:consid(?:ering|érant|ers)|après examen|estime)/i => "considering",
  /(?:taking into account|prend en considération|tenant compte)/i => "taking into account",
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
  /(?:L'unité de longueur|Unités supplémentaires)/i => "decides", # MISC - like declares/defines
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

PREFIX=/\A(?:La Conférence |The Conference |and |et |renouvelle sa |renews its |further |and further |abrogates the |abroge la |En ce qui |après avoir )?/i

a = Mechanize.new

meetings_en = VCR.use_cassette 'meetings' do
  a.get "https://www.bipm.org/en/worldwide-metrology/cgpm/resolutions.html"
end

meetings_fr = VCR.use_cassette 'meetings-fr' do
  a.get "https://www.bipm.org/fr/worldwide-metrology/cgpm/resolutions.html"
end

(meetings_en.css('select[name="cgpm_value"] option') +
 meetings_fr.css('select[name="cgpm_value"] option')).each do |option|

  url = option.attr('value')
  next unless url

  meeting_id = url.split('/').last.to_i
  meeting_lang = url.split('/')[1]
  meeting_lang_sfx = (meeting_lang == 'fr') ? "-fr" : ""
  meeting = VCR.use_cassette("meeting-#{meeting_id}#{meeting_lang_sfx}") { a.get url }

  title_part = meeting.at_css('.GrosTitre').text.chomp
  title, date = title_part.split(" (")
  date = date.split("-").last.gsub("juin", "june")
  date = Date.parse(date) # NB: 13-16 November 2018 -> 2018-11-16

  binding.pry if date <= Date.parse("0000-01-01") || date >= Date.today

  h = {
    "metadata" => {
      "title" => title,
      "date" => date,
      "source" => "BIPM - Pavillon de Breteuil"
    }
  }

  h["resolutions"] = meeting.links_with(class: "introGras").map do |res_link|
    res_id = res_link.href.split('/')[-1].to_i
    res = VCR.use_cassette("resolution-#{meeting_id}-#{res_id}#{meeting_lang_sfx}") { res_link.click }

    r = {
      "dates" => [date],
      "title" => res.at_css(".txt12pt .SousTitre").text.strip.gsub(/\*\Z/, ''),
      "identifier" => res_id,

      "approvals" => [{
        "type" => "affirmative",
        "degree" => "unanimous",
        "message" => "Unanimous"
      }],

      "considerations" => [],
      "actions" => [],
    }

    ps = res.css('td.txt12pt:not([align])')

    #binding.pry if ps.count != 1

    doc = ps.inner_html.encode('utf-8').gsub("\r", '').gsub(%r'</?nobr>','')
    parts = doc.split(/(\n(?:<p>)?<b>.*?<\/b>|<p>(?:après examen |après avoir entendu )|having noted that |decides to define |décide de définir |considers that|estime que|declares<\/p>)/)
    nparts = [parts.shift]
    while parts.length > 0
      nparts << parts.shift + parts.shift
    end

    if nparts.first =~ /([mM]esures( \(CGPM\))?|CGPM| \(CCTC\)| Conference|\[de thermométrie et calorimétrie\]|,)[ \n]?(<\/p>)?\n?\z/
      r["approvals"].first["message"] = ReverseAdoc.convert(nparts.shift).strip
    end

    prev = nil
    nparts.each do |part|
      parse = Nokogiri::HTML(part).text.strip

      CONSIDERATIONS.any? do |k,v|
        if parse =~ /#{PREFIX}#{k}\b/i
          r["considerations"] << prev = {
            "type" => v,
            "date_effective" => date,
            "message" => ReverseAdoc.convert(part).strip,
          }
        end
      end && next

      ACTIONS.any? do |k,v|
        if parse =~ /#{PREFIX}#{k}\b/i
          r["actions"] << prev = {
            "type" => v,
            "date_effective" => date,
            "message" => ReverseAdoc.convert(part).strip,
          }
        end
      end && next

      if parse =~ /\A(?:Appendix|Annexe) ([0-9]+)/
        r["appendices"] ||= []
        r["appendices"] << prev = {
          "identifier" => $1.to_i,
          "message" => ReverseAdoc.convert(part).strip,
        }
        next
      end

      if parse =~ /\A(becquerel|gray, symbol)/
        prev["message"] += "\n" + ReverseAdoc.convert(part).strip
        next
      end

      r["x-unparsed"] ||= []
      r["x-unparsed"] << parse #ReverseAdoc.convert(part).strip
    end

    r
  end

  FileUtils.mkdir_p("meetings#{meeting_lang_sfx}")
  File.write("meetings#{meeting_lang_sfx}/meeting-#{meeting_id}.yml", YAML.dump(h))
end
