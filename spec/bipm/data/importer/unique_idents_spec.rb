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

            it "doesn't have repeated resolutions" do
              restitles = lbody.meetings.values.flat_map do |m|
                m.resolutions.values.map do |r|
                  aca = r.approvals.values + r.considerations.values + r.actions.values
                  aca = aca.map(&:message).sort.join(";;")
                  ["#{r.title}", aca]
                end.reject { |i| i.last.empty? } # Incomplete data, they may differ
                                                 # just have same titles
              end.sort

              expect(restitles).to eq(restitles.uniq)
            end
          end
        end
      end
    end
  end
end
