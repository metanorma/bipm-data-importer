require_relative 'common'

a = Mechanize.new

%w[en fr].each do |meeting_lang|
  meeting_lang_sfx     = (meeting_lang == 'fr') ? "-fr" : ""
  meeting_lang_sfx_dir = (meeting_lang == 'fr') ? "-fr" : "-en"

  meetings = VCR.use_cassette "cipm-decisions/meetings#{meeting_lang_sfx}" do
    a.get "https://www.bipm.org/jsp/#{meeting_lang}/CIPMOutcomes.jsp"
  end

  meetings.css('select[name="Meeting"] option').each do |option|
    url = option.attr('value')
    next if !url || url == ''

    meeting_id = File.basename(url, ".html")

    meeting = VCR.use_cassette("cipm-decisions/meeting-#{meeting_id}#{meeting_lang_sfx}") { a.get url }

    title_part = option.text
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

    ref = meeting.uri.merge(meeting.at_css('a[href*=".pdf"]').attr("href")).to_s

    h["resolutions"] = meeting.css('.txt12pt>table>tr[bgcolor="#829EBA"]').map do |titletr|
      r = {
        "dates" => [date],
        "title" => titletr.at_css('td>span').text.strip,
        "identifier" => titletr.at_css('td>span').text.strip.split("/").last,
        "url" => meeting.uri.to_s,
        "reference" => ref
      }

      contenttr = titletr.next
      binding.pry if (d = contenttr.css('div[align="right"]')).length != 1
      d.remove

      r["x-content"] = Common.format_message(
        contenttr.at_css('td[colspan]').inner_html.encode('utf-8')
      )

      r
    end

    FileUtils.mkdir_p("cipm/decisions#{meeting_lang_sfx_dir}")
    File.write("cipm/decisions#{meeting_lang_sfx_dir}/meeting-#{meeting_id}.yml", YAML.dump(h))
  end
end
