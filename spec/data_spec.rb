require_relative "spec_helpers"

RSpec.describe "data" do
  $all_files = Dir[__dir__+"/../meetings-*/*.yml"]
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
  end
end
