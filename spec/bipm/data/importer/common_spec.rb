# frozen_string_literal: true

require "bipm/data/importer/common"

RSpec.describe Bipm::Data::Importer::Common do
  let(:c) { described_class }

  describe "extract_date" do
    it "parses English dates" do
      expect(c.extract_date("13 October 2018")).to eq(Date.new(2018, 10, 13))
    end

    it "parses French dates" do
      expect(c.extract_date("15 février 2018")).to eq(Date.new(2018, 2, 15))
    end

    it "takes the last date in a range" do
      expect(c.extract_date("13 October 2018, 14 October 2018")).to eq(Date.new(2018, 10, 14))
    end

    it "returns nil for nil" do
      expect(c.extract_date(nil)).to be_nil
    end

    it "returns nil for unparseable input (no longer drops into pry)" do
      expect(c.extract_date("not a date")).to be_nil
    end
  end

  describe "ng_to_string" do
    it "strips nobr tags (preserves inner text)" do
      require "nokogiri"
      node = Nokogiri::HTML("<p>hello<nobr>world</nobr></p>").at_css("p")
      expect(c.ng_to_string(node)).to eq("helloworld")
    end
  end

  describe "extract_pdf" do
    it "selects language-specific PDFs" do
      require "nokogiri"
      html = <<~HTML
        <div>
          <a class="title-third" href="/foo-en.pdf">EN</a>
          <a class="title-third" href="/foo-fr.pdf">FR</a>
        </div>
      HTML
      doc = Nokogiri::HTML(html)
      expect(c.extract_pdf(doc, "en")).to eq("/foo-en.pdf")
      expect(c.extract_pdf(doc, "fr")).to eq("/foo-fr.pdf")
    end

    it "selects language-neutral PDFs when no language suffix" do
      require "nokogiri"
      html = '<div><a class="title-third" href="/foo.pdf">A</a></div>'
      doc = Nokogiri::HTML(html)
      expect(c.extract_pdf(doc, "en")).to eq("/foo.pdf")
    end
  end

  describe "format_message" do
    it "converts HTML to AsciiDoc" do
      result = c.format_message("<p>hello <b>world</b></p>")
      expect(result).to include("hello")
      expect(result).to include("*world*")
    end
  end
end
