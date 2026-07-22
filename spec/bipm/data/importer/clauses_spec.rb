# frozen_string_literal: true

require "bipm/data/importer/clauses"

RSpec.describe Bipm::Data::Importer::Clauses do
  let(:c) { described_class }

  describe "constants" do
    it "exposes frozen, non-empty consideration and action tables" do
      expect(c::CONSIDERATIONS).to be_frozen
      expect(c::ACTIONS).to be_frozen
      expect(c::VERBS).to be_frozen
      expect(c::CONSIDERATIONS).not_to be_empty
      expect(c::ACTIONS).not_to be_empty
      expect(c::VERBS).not_to be_empty
    end
  end

  describe "normalize_verb" do
    it "strips trailing punctuation" do
      expect(c.normalize_verb("considering.")).to eq("considering")
      expect(c.normalize_verb("noting,")).to eq("noting")
      expect(c.normalize_verb("decides:")).to eq("decides")
    end

    it "strips leading English conjunctions" do
      expect(c.normalize_verb("and decides")).to eq("decides")
      expect(c.normalize_verb("further recalling")).to eq("recalling")
    end

    it "strips leading French conjunctions" do
      expect(c.normalize_verb("et décide")).to eq("décide")
      expect(c.normalize_verb("de plus considérant")).to eq("considérant")
    end

    it "downcases" do
      expect(c.normalize_verb("Considering")).to eq("considering")
      expect(c.normalize_verb("CONSIDÉRANT")).to eq("considérant")
    end

    it "is symmetric across languages: stripping conjunctions works the same" do
      # Neither language is canonical — both go through the same pipeline.
      expect(c.normalize_verb("et adopting")).to eq("adopting")
      expect(c.normalize_verb("and adopting")).to eq("adopting")
    end
  end

  describe "lookup_verb" do
    it "returns (type, :consideration) for an English consideration verb" do
      type, category = c.lookup_verb("considering")
      expect(type).to eq("considering")
      expect(category).to eq(:consideration)
    end

    it "returns (type, :consideration) for a French consideration verb" do
      type, category = c.lookup_verb("considérant")
      expect(type).to eq("considering")
      expect(category).to eq(:consideration)
    end

    it "returns (type, :action) for an English action verb" do
      type, category = c.lookup_verb("decides")
      expect(type).to eq("decides")
      expect(category).to eq(:action)
    end

    it "returns (type, :action) for a French action verb" do
      type, category = c.lookup_verb("décide")
      expect(type).to eq("decides")
      expect(category).to eq(:action)
    end

    it "treats 'having' as a consideration in either language" do
      expect(c.lookup_verb("having").last).to eq(:consideration)
      expect(c.lookup_verb("ayant").last).to eq(:consideration)
    end

    it "falls back to decides/action for unknown verbs" do
      type, category = c.lookup_verb("zzz-not-a-verb")
      expect(type).to eq("decides")
      expect(category).to eq(:action)
    end
  end

  describe "category_for_type" do
    it "classifies consideration types" do
      expect(c.category_for_type("considering")).to eq(:consideration)
      expect(c.category_for_type("noting")).to eq(:consideration)
    end

    it "classifies action types" do
      expect(c.category_for_type("decides")).to eq(:action)
      expect(c.category_for_type("adopts")).to eq(:action)
    end

    it "defaults to action" do
      expect(c.category_for_type("made-up-type")).to eq(:action)
    end
  end
end
