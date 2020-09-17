require_relative 'common'

a = Mechanize.new

resolutions = {}
%w[en fr].each do |meeting_lang|
  meeting_lang_sfx     = (meeting_lang == 'fr') ? "-fr" : ""
  meeting_lang_sfx_dir = (meeting_lang == 'fr') ? "-fr" : "-en"

  # Let's try all years
  # 1875 was the first meeting, but after trying all, 1946 was the first found.
  (1946..Time.now.year).each do |yr|
    date = Date.parse("#{yr}-01-01") # Date is approximate

    h = {
      "metadata" => {
        "title" => "CIPM, #{yr}",
        "date" => date,
        "source" => "BIPM - Pavillon de Breteuil",
        #"url" => meeting.uri.to_s - url is not defined here
      }
    }

    exists = false

    # And possible recommendations... up to 7, but only up to 5 were found.
    h["resolutions"] = (0..7).map do |res_id|
      res = VCR.use_cassette("cipm/cipm-recommendation-#{yr}-#{res_id}#{meeting_lang_sfx}") do
        a.get "https://www.bipm.org/#{meeting_lang}/CIPM/db/#{yr}/#{res_id}/"
      rescue Mechanize::ResponseCodeError
        nil
      end
      next unless res

      exists = true

      #p res.uri
      Common.parse_resolution(res, res_id, date, :cipm)
    end.compact

    next unless exists

    FileUtils.mkdir_p("cipm/meetings#{meeting_lang_sfx_dir}")
    File.write("cipm/meetings#{meeting_lang_sfx_dir}/meeting-#{"%02d" % yr}.yml", YAML.dump(h))
  end
end
