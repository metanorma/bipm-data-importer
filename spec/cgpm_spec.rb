require_relative "spec_helpers"

RSpec.describe "data" do
  $all_files = Dir[__dir__+"/../cgpm/meetings-*/*.yml"]
  $all_data = $all_files.map(&YAML.method(:load_file))
  $all_resolutions = $all_data.map do |i|
    i["resolutions"]
  end.flatten
  $all_texts = $all_resolutions.map do |r|
    [ r["approvals"].map { |j| j["message"] } ] +
    [ r["considerations"].map { |j| j["message"] } ] +
    [ r["actions"].map { |j| j["message"] } ]
  end.flatten
  $all_stems = $all_texts.map do |i|
    i.scan(/stem:\[([^\]]*)\]/)
  end.flatten

  describe "stems" do
    it "has no nested stems" do
      expect($all_stems.any? { |i| i =~ /stem:/ }).to be(false)
    end

    it "has no stems prefixed with words" do
      expect($all_texts.any? { |i| i =~ /\wstem:/ }).to be(false)
    end

    it "has no stems prefixed with numbers" do
      expect($all_texts.any? { |i| i =~ /\dstem:/ }).to be(false)
    end

    it "has all stems terminated correctly" do
      expect($all_stems.any? { |i| i.count('"') % 2 == 1 }).to be(false)
      expect($all_stems.any? { |i| i.count('(') != i.count(')') }).to be(false)
    end
  end
end
