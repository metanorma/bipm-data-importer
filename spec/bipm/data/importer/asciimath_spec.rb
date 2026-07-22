# frozen_string_literal: true

require "bipm/data/importer/asciimath"

RSpec.describe Bipm::Data::Importer::AsciiMath do
  let(:m) { described_class }

  describe "asciidoc_extract_math" do
    it "translates Greek letters to stems" do
      expect(m.asciidoc_extract_math("π")).to eq("stem:[ pi ]")
      expect(m.asciidoc_extract_math("α")).to eq("stem:[ alpha ]")
      expect(m.asciidoc_extract_math("Δ")).to eq("stem:[ sf Delta ]")
      expect(m.asciidoc_extract_math("ν")).to eq("stem:[ nu ]")
    end

    it "translates the plus-minus sign" do
      expect(m.asciidoc_extract_math("±")).to eq("stem:[ +- ]")
    end

    it "encloses bare subscript math in stem:" do
      expect(m.asciidoc_extract_math("__m__")).to eq("stem:[m]")
    end

    it "produces no nested stems" do
      out = m.asciidoc_extract_math("π and α and ± and kg")
      stems = out.scan(/stem:\[([^\]]*)\]/).flatten
      expect(stems.any? { |s| s =~ /stem:/ }).to be(false)
    end

    it "leaves no escape markers (ESCUP/ESCUN/ESCbar) in the output" do
      out = m.asciidoc_extract_math("π and ^14^C and kg")
      expect(out).not_to include("ESC")
    end

    it "normalises the en-dash to a hyphen" do
      expect(m.asciidoc_extract_math("3–4")).to eq("3-4")
    end

    it "translates the plusminus gif" do
      input = "image::/utils/special/Math/plusminus.gif[]"
      expect(m.asciidoc_extract_math(input)).to eq("stem:[ +- ]")
    end
  end
end
