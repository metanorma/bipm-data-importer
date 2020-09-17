require_relative 'common'

a = Mechanize.new

meetings_en = VCR.use_cassette 'cgpm-meetings' do
  a.get "https://www.bipm.org/en/worldwide-metrology/cgpm/resolutions.html"
end

meetings_fr = VCR.use_cassette 'cgpm-meetings-fr' do
  a.get "https://www.bipm.org/fr/worldwide-metrology/cgpm/resolutions.html"
end

FileUtils.rm_rf "cgpm/meetings"
FileUtils.rm_rf "cgpm/meetings-fr"
FileUtils.rm_rf "cgpm/meetings-en"

(meetings_en.css('select[name="cgpm_value"] option') +
 meetings_fr.css('select[name="cgpm_value"] option')).each do |option|

  url = option.attr('value')
  next unless url

  meeting_id = url.split('/').last.to_i
  meeting_lang = url.split('/')[1]
  meeting_lang_sfx     = (meeting_lang == 'fr') ? "-fr" : ""
  meeting_lang_sfx_dir = (meeting_lang == 'fr') ? "-fr" : "-en"
  meeting = VCR.use_cassette("cgpm-meeting-#{meeting_id}#{meeting_lang_sfx}") { a.get url }

  title_part = meeting.at_css('.GrosTitre').text.chomp
  title, date = title_part.split(" (")
  date = date.split("-").last.gsub("juin", "june")
  date = Date.parse(date) # NB: 13-16 November 2018 -> 2018-11-16

  binding.pry if date <= Date.parse("0000-01-01") || date >= Date.today

  h = {
    "metadata" => {
      "title" => title,
      "date" => date,
      "source" => "BIPM - Pavillon de Breteuil",
      "url" => meeting.uri.to_s
    }
  }

  h["resolutions"] = meeting.links_with(class: "introGras").map do |res_link|
    res_id = res_link.href.split('/')[-1].to_i
    res = VCR.use_cassette("cgpm-resolution-#{meeting_id}-#{res_id}#{meeting_lang_sfx}") { res_link.click }

    Common.parse_resolution(res, res_id, date, :cgpm)
  end

  FileUtils.mkdir_p("cgpm/meetings#{meeting_lang_sfx_dir}")
  File.write("cgpm/meetings#{meeting_lang_sfx_dir}/meeting-#{"%02d" % meeting_id}.yml", YAML.dump(h))
end
