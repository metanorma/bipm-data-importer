# frozen_string_literal: true

require "bipm/data/importer/quirks"

RSpec.describe Bipm::Data::Importer::Quirks do
  describe "fix_href" do
    it "fixes the legacy /jen/ typo" do
      expect(described_class.fix_href("/jen/foo")).to eq("/en/foo")
    end

    it "fixes the legacy /en/CGPM/jsp/ path" do
      expect(described_class.fix_href("/en/CGPM/jsp/x")).to eq("/en/CGPM/db/x")
    end

    it "rewrites CIPM 106-2017 → 104-_1-2015 for the two affected resolutions" do
      fixed = described_class.fix_href("/ci/cipm/106-2017/resolution-1")
      expect(fixed).to eq("/ci/cipm/104-_1-2015/resolution-1")
    end

    it "leaves unrelated CIPM 106-2017 paths alone" do
      expect(described_class.fix_href("/ci/cipm/106-2017/something-else")).to eq("/ci/cipm/106-2017/something-else")
    end

    it "rewrites 104-2015 to the underscore variant" do
      expect(described_class.fix_href("/ci/cipm/104-2015/x")).to eq("/ci/cipm/104-_1-2015/x")
    end

    it "localises the /web/guest/ prefix when a language is supplied" do
      expect(described_class.fix_href("/web/guest/foo", language: "fr")).to eq("/fr/foo")
      expect(described_class.fix_href("/web/guest/foo", language: "en")).to eq("/en/foo")
    end

    it "strips the https://www.bipm.org/ origin" do
      expect(described_class.fix_href("https://www.bipm.org/en/foo")).to eq("/en/foo")
    end

    it "is symmetric across languages for the /web/guest/ prefix" do
      # French and English go through the same code path; neither is special.
      fr = described_class.fix_href("/web/guest/committees/ci/cipm", language: "fr")
      en = described_class.fix_href("/web/guest/committees/ci/cipm", language: "en")
      expect(fr).to eq("/fr/committees/ci/cipm")
      expect(en).to eq("/en/committees/ci/cipm")
    end
  end

  describe "skip_meeting_year?" do
    it "skips CIPM 104-2 (duplicate of 104-1)" do
      expect(described_class.skip_meeting_year?(:cipm, "104-2")).to be true
    end

    it "does not skip CIPM 104-1" do
      expect(described_class.skip_meeting_year?(:cipm, "104-1")).to be false
    end
  end

  describe "deduplicate_resolutions" do
    it "synthesises canonical URLs for CIPM/fr/94 when duplicates exist" do
      input = %w[a b a].sort
      out = described_class.deduplicate_resolutions(:cipm, "fr", "94", input)
      expect(out.length).to eq(3)
      expect(out).to all(include("/94-2005/resolution-"))
    end

    it "leaves non-CIPM/fr/94 inputs untouched" do
      input = %w[a b a]
      expect(described_class.deduplicate_resolutions(:cipm, "en", "94", input)).to eq(input)
      expect(described_class.deduplicate_resolutions(:jcrb, "fr", "43", input)).to eq(input)
    end
  end

  describe "renumber_jcrb_43_fr" do
    it "renumbers duplicate 43-1 actions" do
      resolutions = [
        { "type" => "action", "identifier" => "43-1" },
        { "type" => "action", "identifier" => "43-1" },
      ]
      out = described_class.renumber_jcrb_43_fr(resolutions)
      ids = out.map { |r| r["identifier"] }
      expect(ids).to eq(["43-1-xxx-1", "43-1-xxx-2"])
    end

    it "leaves unique ids untouched" do
      resolutions = [
        { "type" => "action", "identifier" => "43-1" },
        { "type" => "action", "identifier" => "43-2" },
      ]
      expect(described_class.renumber_jcrb_43_fr(resolutions)).to eq(resolutions)
    end
  end
end
