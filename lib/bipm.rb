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
  /(?:having(?: regard)?|ayant|acceptant|concerne|referring)/i => "having / having regard",
  /(?:noting|notes|observing|taking note|takes note|constatant|constate|that)/i => "noting",
  /(?:recognizing|recognizes|reconnaissant|reconnaît)/i => "recognizing",
  /(?:acknowledging|accept(?:s|ing)|entendu)/i => "acknowledging",
  /(?:further )?recall(?:ing|s)/i => "recalling / further recalling",
  /re-?affirm(?:ing|s)/i => "reaffirming",
  /(?:consid(?:ering|érant|ers)|après examen)/i => "considering",
  "taking into account" => "taking into account",
  "pursuant to" => "pursuant to",
  /(?:bearing in mind|estime)/i => "bearing in mind",
  "emphasizing" => "emphasizing",
  "concerned" => "concerned"
}

ACTIONS = {
  "adopts" => "adopts",
  /(?:thanks|expresses[ -]appreciation|appréciant|pays tribute|rend hommage|remercie)/i => "thanks / expresses-appreciation",
  /(?:approu?ves?|approving|entérine)/i => "approves",
  /(?:d[eé]cid(?:es|e|é)|ratifies|judges|d[ée]clares?|definition|sanction(?:s|ne))/i => "decides",
  /(?:The unit of length is|Supplementary units|Les v\u{9C}ux ou propositions|Principles|Les Délégués des États)/i => "decides", # MISC - like declares/defines
  /(?:asks|souhaite)/i => "asks",
  /(?:further )?invites?|renouvelle en conséquence/i => "invites / further invites",
  "resolves" => "resolves",
  "confirms" => "confirms",
  "welcomes" => "welcomes",
  /recomm(?:ends|ande)/i => "recommends",
  /requests?|demande/i => "requests",
  "congratulates" => "congratulates",
  "instructs" => "instructs",
  "urges" => "urges",
  /(?:appoints|autorise|empowers|charge|donne|Pendant la période)/i => "appoints",
  "resolves further" => "resolves further",
  /(?:calls upon|attire l'attention|lance un appel)/i => "calls upon",
  /(?:encourages|espère)/i => "encourages",
  /(?:affirms|reaffirming|states|remarks)/i => "affirms / reaffirming",
}

PREFIX=/\A(?:The Conference |and |et |renews its |further |and further |abrogates the |En ce qui |après avoir )?/i

a = Mechanize.new

meetings = VCR.use_cassette 'meetings' do
  a.get "https://www.bipm.org/en/worldwide-metrology/cgpm/resolutions.html"
end

meetings.css('select[name="cgpm_value"] option').each do |option|
  url = option.attr('value')
  next unless url

  meeting_id = url.split('/').last.to_i
  meeting = VCR.use_cassette("meeting-#{meeting_id}") { a.get url }

  title_part = meeting.at_css('.GrosTitre').text.chomp
  title, date = title_part.split(" (")
  date = Date.parse(date.split("-").last) # NB: 13-16 November 2018 -> 2018-11-16

  #binding.pry if date < Date.parse("0000-01-01")

  h = {
    "metadata" => {
      "title" => title,
      "date" => date,
      "source" => "BIPM - Pavillon de Breteuil"
    }
  }

  h["resolutions"] = meeting.links_with(class: "introGras").map do |res_link|
    res_id = res_link.href.split('/')[-1].to_i
    res = VCR.use_cassette("resolution-#{meeting_id}-#{res_id}") { res_link.click }

    r = {
      "dates" => [date],
      "subject" => res.at_css(".txt12pt .SousTitre").text.strip,
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
    parts = doc.split(/(\n(?:<p>)?<b>.*?<\/b>|<p>(?:après examen |après avoir entendu )|having noted that |decides to define |considers that|declares<\/p>)/)
    nparts = [parts.shift]
    while parts.length > 0
      nparts << parts.shift + parts.shift
    end

    if nparts.first =~ /([mM]esures( \(CGPM\))?|CGPM| \(CCTC\)| Conference|,)[ \n]?(<\/p>)?\n?\z/
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

      if parse =~ /\AAppendix ([0-9]+)/
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

  FileUtils.mkdir_p('meetings')
  File.write("meetings/meeting-#{meeting_id}.yml", YAML.dump(h))
end
