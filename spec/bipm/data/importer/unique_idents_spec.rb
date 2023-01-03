require_relative "../../../spec_helper"

RSpec.describe "data" do
  describe "unique idents" do
    Bipm::Data::Outcomes.each do |body|
      describe body.body do
        body.each do |lbody|
          describe lbody.locale do
            lbody.meetings.each_value do |meeting|
              describe meeting.id do
                # Mistake on a website: numbering is wrong
                # https://www.bipm.org/fr/committees/jc/jcrb/43-2021
                if [body.body, lbody.locale, meeting.id] == [:jcrb, :fr, "43"]
                  xit "has unique resolution ids"
                  next
                end

                it "has unique resolution ids" do
                  resolutions = meeting.resolutions.values.map{|i| [i.type,i.id] }.sort
                  unique_resolutions = resolutions.uniq

                  expect(resolutions).to eq(unique_resolutions)
                end
              end
            end
          end
        end
      end
    end
  end
end
