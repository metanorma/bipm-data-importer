# frozen_string_literal: true

require "fileutils"

module Bipm
  module Data
    module Importer
      module Strategies
        # Abstract strategy. Subclasses implement `call` and override
        # `recording_mode`. The Fetcher queries `recording_mode` to decide
        # whether to disable VCR/WebMock before invoking — the CLI never
        # touches VCR directly.
        class Base
          attr_reader :body, :base_dir, :languages

          def initialize(body:, base_dir:, languages: Language.all)
            @body = body
            @base_dir = base_dir
            @languages = languages.map { |l| l.is_a?(Language) ? l : Language.find(l) }
          end

          def call(agent:)
            raise NotImplementedError, "#{self.class}#call not implemented"
          end

          # :live  -> HTTP requests bypass VCR/WebMock entirely.
          # :cassette -> VCR replays recorded responses (records new
          #              episodes when BIPM_VCR_RECORD is set).
          def self.recording_mode
            :cassette
          end

          def recording_mode
            self.class.recording_mode
          end
        end
      end
    end
  end
end
