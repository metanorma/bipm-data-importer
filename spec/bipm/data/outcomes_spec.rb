# frozen-string-literal: true

RSpec.describe Bipm::Data::Outcomes do
  it "acts like an array of Bodies" do
    expect(described_class.to_a.map(&:class)).to eq [described_class::Body] * 14
  end

  describe described_class::Body do
    let(:instance) { Bipm::Data::Outcomes.to_a.first }

    it "acts like an array of LocalizedBodies" do
      expect(instance.to_a.first.class).to be Bipm::Data::Outcomes::LocalizedBody
    end
  end

  describe described_class::LocalizedBody do
    let(:instance) { Bipm::Data::Outcomes.to_a.first.to_a.first }

    it "acts like an array of Meetings" do
      expect(instance.to_a.first.class).to be Bipm::Data::Outcomes::Meeting
    end
  end
end
