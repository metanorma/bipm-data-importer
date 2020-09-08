require 'bundler/setup'
require 'rspec/matchers'
require 'yaml'
require 'pry'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

$all_files = Dir[__dir__+"/../meetings-*/*.yml"]
$all_data = $all_files.map(&YAML.method(:load_file))
$all_texts = $all_data.map do |i|
  i["resolutions"].map do |r|
    [ r["approvals"].map { |j| j["message"] } ] +
    [ r["considerations"].map { |j| j["message"] } ] +
    [ r["actions"].map { |j| j["message"] } ]
  end
end.flatten
$all_stems = $all_texts.map do |i|
  i.scan(/stem:\[([^\]]*)\]/)
end.flatten
