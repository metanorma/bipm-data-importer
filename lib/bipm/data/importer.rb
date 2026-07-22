# frozen_string_literal: true

# NOTE: This is the one internal require that does not use autoload.
# `autoload` only works for module/class constants — it cannot lazily
# resolve `Bipm::Data::Importer::VERSION` (a String) without eagerly
# defining it. version.rb is a minimal, dependency-free file that the
# gemspec also loads at gem-build time, before Bundler has installed
# mechanize/nokogiri/etc.
require "bipm/data/importer/version"

module Bipm
  module Data
    module Importer
      class Error < StandardError; end

      autoload :AsciiMath, "bipm/data/importer/asciimath"
      autoload :Body, "bipm/data/importer/body"
      autoload :Bodies, "bipm/data/importer/bodies"
      autoload :CGPM, "bipm/data/importer/cgpm"
      autoload :Clauses, "bipm/data/importer/clauses"
      autoload :CLI, "bipm/data/importer/cli"
      autoload :Common, "bipm/data/importer/common"
      autoload :Fetcher, "bipm/data/importer/fetcher"
      autoload :Language, "bipm/data/importer/language"
      autoload :Quirks, "bipm/data/importer/quirks"
      autoload :Strategies, "bipm/data/importer/strategies"
      autoload :Text, "bipm/data/importer/text"

      # Build a Fetcher for one body. Does not start any work — call .call on
      # the returned object, optionally passing an agent (defaults to a fresh
      # Mechanize instance).
      def self.fetch(body_id, languages: Language.all, base_dir: "data")
        Fetcher.new(body: body_id, languages: languages, base_dir: base_dir)
      end

      # Build a Fetcher for every known body.
      def self.fetch_all(languages: Language.all, base_dir: "data")
        Bodies.all.map { |b| Fetcher.new(body: b, languages: languages, base_dir: base_dir) }
      end
    end
  end
end
