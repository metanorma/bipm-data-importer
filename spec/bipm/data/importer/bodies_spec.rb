# frozen_string_literal: true

require "bipm/data/importer/bodies"
require "bipm/data/importer/language"

RSpec.describe Bipm::Data::Importer::Bodies do
  it "is enumerable" do
    expect(described_class).to be_a(Module)
    expect(described_class.all).to include(Bipm::Data::Importer::Bodies[:cgpm])
  end

  it "knows all 14 bodies" do
    expect(described_class.all.map(&:id).sort).to eq(
      %i[ccauv ccem ccl ccm ccpr ccqm ccri cct cctf ccu cgpm cipm jcgm jcrb]
    )
  end

  it "treats CGPM as static_index and the rest as spa_meetings" do
    expect(described_class[:cgpm].strategy).to eq(:static_index)
    described_class.all.reject { |b| b.id == :cgpm }.each do |b|
      expect(b.strategy).to eq(:spa_meetings), "#{b.id} should be :spa_meetings"
    end
  end

  it "supports find via string or symbol" do
    expect(described_class.find("cgpm")).to eq(described_class[:cgpm])
    expect(described_class.find(:cgpm)).to eq(described_class[:cgpm])
  end

  it "raises UnknownBodyError for unknown ids" do
    expect { described_class.find(:nope) }.to raise_error(Bipm::Data::Importer::Bodies::UnknownBodyError)
  end

  describe Bipm::Data::Importer::Body do
    let(:body) { Bipm::Data::Importer::Bodies[:cipm] }

    it "builds symmetric URLs across languages" do
      expect(body.url(:en)).to eq("https://www.bipm.org/en/committees/ci/cipm")
      expect(body.url(:fr)).to eq("https://www.bipm.org/fr/committees/ci/cipm")
    end

    it "accepts Language instances too" do
      cgpm = Bipm::Data::Importer::Bodies[:cgpm]
      expect(cgpm.url(Bipm::Data::Importer::Language::FR))
        .to eq("https://www.bipm.org/fr/worldwide-metrology/cgpm/resolutions.html")
    end

    it "treats equality by id" do
      expect(Bipm::Data::Importer::Bodies[:cgpm]).to eq(Bipm::Data::Importer::Bodies[:cgpm])
    end
  end
end
