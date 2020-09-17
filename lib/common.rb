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
  /(?:having(?: regard)?|ayant|acceptant|concerne|referring|se référant|vu la)/i => "having / having regard",
  /(?:noting|notes|observing|observant que|taking note|takes note|constatant|constate|that|note|notant|notant que|note également|(?:prend|prenant) (?:acte|note))/i => "noting",
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
      when %r'\A/(\w{2})/CIPM/db/(\d+)/(\d+)/(#.*)?\z',
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

  extend self
end
