# frozen_string_literal: true

require "bipm/data/importer/cli"

RSpec.describe Bipm::Data::Importer::CLI do
  describe "parse" do
    it "defaults to all bodies, all languages, base data" do
      opts = described_class.new([]).parse([])
      expect(opts.body_id).to be_nil
      expect(opts.languages).to be_nil
      expect(opts.base_dir).to eq("data")
      expect(opts.fork).to be(false)
    end

    it "parses --body=cgpm" do
      opts = described_class.new([]).parse(["--body=cgpm"])
      expect(opts.body_id).to eq(:cgpm)
    end

    it "parses --language=fr" do
      opts = described_class.new([]).parse(["--language=fr"])
      expect(opts.languages.map(&:to_s)).to eq(["fr"])
    end

    it "parses --base-dir=/tmp/x" do
      opts = described_class.new([]).parse(["--base-dir=/tmp/x"])
      expect(opts.base_dir).to eq("/tmp/x")
    end

    it "parses --fork" do
      opts = described_class.new([]).parse(["--fork"])
      expect(opts.fork).to be(true)
    end

    it "treats --language=en and --language=fr symmetrically (both first-class)" do
      en = described_class.new([]).parse(["--language=en"]).languages
      fr = described_class.new([]).parse(["--language=fr"]).languages
      expect(en.first).to be_a(Bipm::Data::Importer::Language)
      expect(fr.first).to be_a(Bipm::Data::Importer::Language)
      expect(en.first).not_to eq(fr.first)
    end

    it "rejects unknown languages" do
      expect { described_class.new([]).parse(["--language=de"]) }
        .to raise_error(ArgumentError)
    end
  end

  describe "run" do
    it "returns exit code 2 for an unknown body" do
      cli = described_class.new(["--body=nope"])
      expect(cli.run).to eq(2)
    end
  end
end
