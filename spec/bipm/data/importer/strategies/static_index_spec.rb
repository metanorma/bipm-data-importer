# frozen_string_literal: true

require "bipm/data/importer/strategies/static_index"
require "bipm/data/importer/bodies"

RSpec.describe Bipm::Data::Importer::Strategies::StaticIndex do
  subject(:strategy) do
    described_class.new(body: body, base_dir: "data")
  end

  let(:body) { Bipm::Data::Importer::Bodies[:cgpm] }

  describe "recording_mode" do
    it "is :live (CGPM has no cassettes, hits the live site)" do
      expect(described_class.recording_mode).to eq(:live)
      expect(strategy.recording_mode).to eq(:live)
    end
  end

  describe "normalize_res_url" do
    it "strips the language segment" do
      expect(strategy.normalize_res_url("https://www.bipm.org/en/committees/cg/cgpm/26-2018/resolution-1")).to eq("https://www.bipm.org/committees/cg/cgpm/26-2018/resolution-1")
      expect(strategy.normalize_res_url("https://www.bipm.org/fr/committees/cg/cgpm/26-2018/resolution-1")).to eq("https://www.bipm.org/committees/cg/cgpm/26-2018/resolution-1")
    end

    it "is symmetric across languages (same canonical form for en/fr pair)" do
      en = strategy.normalize_res_url("https://www.bipm.org/en/committees/cg/cgpm/26-2018/resolution-1")
      fr = strategy.normalize_res_url("https://www.bipm.org/fr/committees/cg/cgpm/26-2018/resolution-1")
      expect(en).to eq(fr)
    end
  end

  describe "extract_resolution_urls" do
    it "collects CGPM resolution URLs from a listing page" do
      html = <<~HTML
        <html><body>
          <a href="https://www.bipm.org/en/committees/cg/cgpm/26-2018/resolution-1">Res 1</a>
          <a href="/en/committees/cg/cgpm/26-2018/resolution-2">Res 2</a>
          <a href="/en/some/other/page">Other</a>
        </body></html>
      HTML

      urls = strategy.extract_resolution_urls(html, "en")
      expect(urls.length).to eq(2)
      expect(urls.first).to end_with("/en/committees/cg/cgpm/26-2018/resolution-1")
    end

    it "produces language-tagged URLs symmetric across languages" do
      html = <<~HTML
        <html><body>
          <a href="/en/committees/cg/cgpm/26-2018/resolution-1">Res 1</a>
        </body></html>
      HTML

      en_urls = strategy.extract_resolution_urls(html, "en")
      fr_urls = strategy.extract_resolution_urls(html, "fr")
      expect(en_urls.first).to include("/en/committees/")
      expect(fr_urls.first).to include("/fr/committees/")
    end

    it "deduplicates" do
      html = <<~HTML
        <html><body>
          <a href="/en/committees/cg/cgpm/26-2018/resolution-1">Res 1</a>
          <a href="/en/committees/cg/cgpm/26-2018/resolution-1">Res 1 again</a>
        </body></html>
      HTML
      expect(strategy.extract_resolution_urls(html, "en").length).to eq(1)
    end
  end

  describe "parse_date_text" do
    it "returns ISO 8601 form" do
      expect(strategy.parse_date_text("13 November 2018")).to eq("2018-11-13")
    end

    it "handles French" do
      expect(strategy.parse_date_text("15 février 2018")).to eq("2018-02-15")
    end

    it "returns nil for unparseable input" do
      expect(strategy.parse_date_text("not a date")).to be_nil
    end
  end

  describe "flush_clause" do
    it "appends to considerations for a consideration verb" do
      considerations = []
      actions = []
      strategy.flush_clause("considering", ["the rule"], [], considerations, actions, "2018-11-13")
      expect(considerations.length).to eq(1)
      expect(actions).to be_empty
      expect(considerations.first["type"]).to eq("considering")
      expect(considerations.first["message"]).to eq("the rule")
    end

    it "appends to actions for an action verb" do
      considerations = []
      actions = []
      strategy.flush_clause("decides", ["to adopt"], [], considerations, actions, "2018-11-13")
      expect(actions.length).to eq(1)
      expect(considerations).to be_empty
      expect(actions.first["type"]).to eq("decides")
    end

    it "treats French and English verbs symmetrically" do
      cons_en = []; act_en = []
      cons_fr = []; act_fr = []
      strategy.flush_clause("decides", ["x"], [], cons_en, act_en, "2018-11-13")
      strategy.flush_clause("décide", ["x"], [], cons_fr, act_fr, "2018-11-13")
      expect(act_en.first["type"]).to eq(act_fr.first["type"])
    end

    it "skips empty messages" do
      considerations = []
      actions = []
      strategy.flush_clause("decides", [], [], considerations, actions, "2018-11-13")
      expect(considerations).to be_empty
      expect(actions).to be_empty
    end
  end
end
