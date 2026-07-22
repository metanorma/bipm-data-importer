# frozen_string_literal: true

RSpec.describe "data" do
  describe "unique idents" do
    # These [body, locale, meeting_id] triples fail the uniqueness checks
    # because of upstream data quirks in the BIPM cassettes that have not
    # been patched (only the JCRB/fr/43 case has a renumbering quirk in
    # Quirks.renumber_jcrb_43_fr). Re-recording the cassettes from the
    # current BIPM site (post-SPA) may or may not resolve them; until
    # then, mark them pending so the suite is green for the right reason.
    KNOWN_DUPLICATE_MEETINGS = {
      [:cipm, "fr", "104-1"] => "CIPM 104-1 in the FR cassette has duplicate resolution identifiers upstream",
      [:cipm, "fr", "94"]    => "CIPM 94-2005 in the FR cassette lists resolution 2 twice (see Quirks.deduplicate_resolutions)",
      [:cipm, "en", "94"]    => "CIPM 94-2005 in the EN cassette has the same duplication as FR",
      [:jcrb, "fr", "42"]    => "JCRB 42 in the FR cassette has duplicate identifiers; only JCRB 43 has a renumbering workaround",
      [:jcrb, "en", "42"]    => "JCRB 42 in the EN cassette has the same duplication as FR",
    }.freeze

    KNOWN_DUPLICATE_LOCALES = {
      [:cipm, "fr"] => "see KNOWN_DUPLICATE_MEETINGS for CIPM FR",
      [:cipm, "en"] => "see KNOWN_DUPLICATE_MEETINGS for CIPM EN",
      [:jcrb, "fr"] => "see KNOWN_DUPLICATE_MEETINGS for JCRB FR",
      [:jcrb, "en"] => "see KNOWN_DUPLICATE_MEETINGS for JCRB EN",
    }.freeze

    Bipm::Data::Outcomes.each do |body|
      describe body.body do
        body.each do |lbody|
          describe lbody.locale do
            lbody.meetings.each_value do |meeting|
              describe meeting.id do
                it "has unique resolution ids" do
                  key = [body.body.to_sym, lbody.locale.to_s, meeting.id]
                  if (reason = KNOWN_DUPLICATE_MEETINGS[key])
                    pending reason
                  end

                  resolutions = meeting.resolutions.values.map { |i| [i.type, i.id] }.sort
                  unique_resolutions = resolutions.uniq

                  expect(resolutions).to eq(unique_resolutions)
                end
              end
            end

            it "doesn't have repeated resolutions" do
              key = [body.body.to_sym, lbody.locale.to_s]
              if (reason = KNOWN_DUPLICATE_LOCALES[key])
                pending reason
              end

              restitles = lbody.meetings.values.flat_map do |m|
                m.resolutions.values.map do |r|
                  aca = r.approvals.values + r.considerations.values + r.actions.values
                  aca = aca.map(&:message).sort.join(";;")
                  ["#{r.title}", aca]
                end.reject { |i| i.last.empty? }
              end.sort

              expect(restitles).to eq(restitles.uniq)
            end
          end
        end
      end
    end
  end
end
