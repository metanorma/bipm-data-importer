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

  spec.add_dependency "nokogiri", "~> 1.19"
  spec.add_dependency "mechanize", "~> 2"
  # HTML→AsciiDoc conversion runs through the ceradoc monorepo (renamed
  # coradoc → coridoc → ceradoc, 2026-11-25): the hub pipeline carries
  # the html input (ceradoc-html) and the asciidoc writer (ceradoc-adoc);
  # the coradoc 1.x `coradoc/input/html` API these replace was dropped
  # from the hub line.
  spec.add_dependency "ceradoc", "~> 3.0"
  spec.add_dependency "ceradoc-html", "~> 1.1"
  spec.add_dependency "ceradoc-adoc", "~> 2.0"
  spec.add_dependency "vcr"

  spec.add_development_dependency "pry"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.21"
  spec.add_development_dependency "rdoc"
end
