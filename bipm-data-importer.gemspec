# frozen_string_literal: true

require_relative "lib/bipm/data/importer/version"

Gem::Specification.new do |spec|
  spec.name = "bipm-data-importer"
  spec.version = Bipm::Data::Importer::VERSION
  spec.authors = ["Ribose"]
  spec.email = ["open.source@ribose.com"]

  spec.summary = "Importer for BIPM CGPM and CIPM content"
  spec.description = "Importer for BIPM CGPM and CIPM content"
  spec.homepage = "https://github.com/metanorma/bipm-data-importer"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/metanorma/bipm-data-importer"
  spec.metadata["changelog_uri"] = "https://github.com/metanorma/bipm-data-importer"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      f == __FILE__ ||
        f.match(%r{\A(?:spec|features|\.git|\.circleci|\.github)/}) ||
        f.start_with?(".gitignore", ".rspec", ".rubocop")
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "nokogiri"
  spec.add_dependency "mechanize"
  # coradoc 2.0 removed `coradoc/input/html` (called in
  # lib/bipm/data/importer/common.rb) as part of a major refactor.
  # Pinned to 1.x until a follow-up ports the HTML input calls to the
  # coradoc 2.x API (or wherever that functionality has been extracted).
  spec.add_dependency "coradoc", "~> 1.1"
  spec.add_dependency "vcr"

  spec.add_development_dependency "pry"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.21"
  spec.add_development_dependency "rdoc"
end
