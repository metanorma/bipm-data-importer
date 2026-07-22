# frozen_string_literal: true

require "bipm/data/outcomes"

RSpec.describe Bipm::Data::Outcomes do
  describe "fetching bodies" do
    it "exposes every committee as a Body" do
      expect(described_class.bodies.keys).to contain_exactly(
        :ccauv, :ccem, :ccl, :ccm, :ccpr, :ccqm, :ccri, :cct, :cctf, :ccu,
        :cgpm, :cipm, :jcgm, :jcrb,
      )
    end

    it "supports [] alias" do
      expect(described_class[:cgpm]).to be_a(Bipm::Data::Outcomes::Body)
    end
  end

  describe Bipm::Data::Outcomes::Body do
    let(:body) { Bipm::Data::Outcomes[:cipm] }

    it "exposes both locales symmetrically" do
      expect(body.locales.keys).to contain_exactly(:fr, :en)
      expect(body[:en]).to be_a(Bipm::Data::Outcomes::LocalizedBody)
      expect(body[:fr]).to be_a(Bipm::Data::Outcomes::LocalizedBody)
    end

    it "builds a file_path that ends with the body name" do
      expect(body.file_path).to end_with("/cipm/")
    end

    it "iterates over localized bodies" do
      expect(body.to_a).to all(be_a(Bipm::Data::Outcomes::LocalizedBody))
    end
  end

  describe Bipm::Data::Outcomes::LocalizedBody do
    let(:lbody) { Bipm::Data::Outcomes[:cipm][:en] }

    it "exposes its locale" do
      expect(lbody.locale).to eq(:en)
    end

    it "has at least one meeting" do
      expect(lbody.meetings).not_to be_empty
    end

    it "builds Meeting objects keyed by id" do
      id, meeting = lbody.meetings.first
      expect(meeting).to be_a(Bipm::Data::Outcomes::Meeting)
      expect(meeting.id).to eq(id)
    end
  end

  describe Bipm::Data::Outcomes::Meeting do
    let(:meeting) { first_meeting_with_resolutions }

    def first_meeting_with_resolutions
      Bipm::Data::Outcomes.each do |body|
        body.each do |lbody|
          lbody.meetings.values.each do |m|
            return m if m.resolutions.any?
          end
        end
      end
      raise "no meeting with resolutions found in data/"
    end

    it "exposes metadata fields" do
      expect(meeting.title).to be_a(String)
      expect(meeting.source).to be_a(String)
    end

    it "exposes a url distinct from source (regression: url used to return source)" do
      expect(meeting.url).to be_a(String)
      expect(meeting.url).to start_with("http")
    end

    it "caches the parsed YAML document (regression: every accessor used to re-read the file)" do
      meeting # warm the memo before setting the expectation
      expect(File).not_to receive(:open)
      meeting.title
      meeting.source
      meeting.url
      meeting.resolutions
    end

    it "exposes resolutions as Resolution objects" do
      expect(meeting.resolutions.values).to all(be_a(Bipm::Data::Outcomes::Resolution))
    end
  end

  describe Bipm::Data::Outcomes::Resolution do
    let(:resolution) { first_meeting_with_resolutions.resolutions.values.first }

    def first_meeting_with_resolutions
      Bipm::Data::Outcomes.each do |body|
        body.each do |lbody|
          lbody.meetings.values.each do |m|
            return m if m.resolutions.any?
          end
        end
      end
      raise "no meeting with resolutions found in data/"
    end

    it "exposes scalar fields" do
      expect(resolution.title).to be_a(String).or(be_nil)
      expect(resolution.subject).to be_a(String).or(be_nil)
      expect(resolution.url).to be_a(String).or(be_nil)
    end

    it "returns Date objects for dates" do
      skip "no dates in this resolution" unless resolution.document["dates"]&.any?
      expect(resolution.dates).to all(be_a(Date))
    end

    it "returns type as a symbol" do
      skip "no type in this resolution" unless resolution.document["type"]
      expect(resolution.type).to be_a(Symbol)
    end

    it "exposes typed clauses" do
      expect(resolution.approvals.values).to all(be_a(Bipm::Data::Outcomes::Approval))
      expect(resolution.considerations.values).to all(be_a(Bipm::Data::Outcomes::Consideration))
      expect(resolution.actions.values).to all(be_a(Bipm::Data::Outcomes::Action))
    end

    it "caches its slice of the parent document" do
      expect(resolution.meeting).not_to receive(:document)
      resolution.title
      resolution.subject
      resolution.url
    end
  end

  describe Bipm::Data::Outcomes::Action do
    let(:action) { first_action }

    def first_action
      Bipm::Data::Outcomes.each do |body|
        body.each do |lbody|
          lbody.meetings.values.each do |m|
            m.resolutions.values.each do |r|
              r.actions.values.each { |a| return a }
            end
          end
        end
      end
      nil
    end

    it "exposes type as a symbol and date as a Date" do
      skip "no actions found in any resolution" unless action
      expect(action.type).to be_a(Symbol)
      expect(action.date_effective).to be_a(Date)
    end
  end
end
