# frozen_string_literal: true

require "bipm/data/importer/text/french"
require "date"

RSpec.describe Bipm::Data::Importer::Text::French do
  let(:f) { described_class }

  describe "translate_months" do
    it "translates every French month name to English" do
      {
        "janvier"    => "january",
        "février"    => "february",
        "fevrier"    => "february",
        "mars"       => "march",
        "avril"      => "april",
        "mai"        => "may",
        "juin"       => "june",
        "juillet"    => "july",
        "août"       => "august",
        "aout"       => "august",
        "septembre"  => "september",
        "octobre"    => "october",
        "novembre"   => "november",
        "décembre"   => "december",
        "decembre"   => "december",
      }.each do |fr, en|
        expect(f.translate_months(fr).downcase).to eq(en)
      end
    end

    it "preserves surrounding text" do
      expect(f.translate_months("15 février 2018").downcase).to eq("15 february 2018")
    end
  end

  describe "parse_date" do
    it "parses a single English date" do
      expect(f.parse_date("15 February 2018")).to eq(Date.new(2018, 2, 15))
    end

    it "parses a single French date" do
      expect(f.parse_date("15 février 2018")).to eq(Date.new(2018, 2, 15))
    end

    it "takes the last date in a French range" do
      expect(f.parse_date("15 février – 16 février 2018")).to eq(Date.new(2018, 2, 16))
    end

    it "takes the last date in an English range with comma" do
      expect(f.parse_date("13 October 2018, 14 October 2018")).to eq(Date.new(2018, 10, 14))
    end

    it "returns nil for empty input" do
      expect(f.parse_date(nil)).to be_nil
      expect(f.parse_date("")).to be_nil
      expect(f.parse_date("   ")).to be_nil
    end

    it "returns nil for unparseable input" do
      expect(f.parse_date("not a date at all")).to be_nil
    end

    it "is symmetric across languages for the same input" do
      expect(f.parse_date("15 février 2018")).to eq(f.parse_date("15 february 2018"))
    end
  end
end
