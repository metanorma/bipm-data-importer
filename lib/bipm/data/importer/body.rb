# frozen_string_literal: true

module Bipm
  module Data
    module Importer
      # A BIPM committee body (CIPM, CGPM, CCAUV, etc.).
      #
      # `path` is locale-agnostic — `url(:en)` and `url(:fr)` are constructed
      # symmetrically by inserting the language segment into the BIPM URL
      # template. Neither language is canonical; both are first-class.
      class Body
        BIPM_ORIGIN = "https://www.bipm.org".freeze

        attr_reader :id, :display_name, :path, :strategy

        def initialize(id:, display_name:, path:, strategy:)
          @id = id
          @display_name = display_name
          @path = path
          @strategy = strategy
        end

        def url(language)
          lang = language.is_a?(Language) ? language : Language.find(language)
          "#{BIPM_ORIGIN}/#{lang}/#{path}"
        end

        def eql?(other)
          other.is_a?(Body) && @id == other.id
        end
        alias == eql?

        def hash
          @id.hash
        end

        def to_s
          "#{display_name} (#{id})"
        end
      end
    end
  end
end
