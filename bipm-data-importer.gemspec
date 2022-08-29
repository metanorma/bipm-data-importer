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
  spec.required_ruby_version = ">= 2.5.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/metanorma/bipm-data-importer"
  spec.metadata["changelog_uri"] = "https://github.com/metanorma/bipm-data-importer"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "nokogiri"
  spec.add_dependency "mechanize"
  spec.add_dependency "reverse_adoc"

  spec.add_dependency "vcr"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.21"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rdoc"
end
