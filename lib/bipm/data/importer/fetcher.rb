# frozen_string_literal: true

require "mechanize"

module Bipm
  module Data
    module Importer
      # Orchestrates a single body's scrape. Picks the strategy declared
      # by the Body, configures VCR/WebMock for the strategy's recording
      # mode, then delegates the actual work. The CLI never touches VCR.
      class Fetcher
        attr_reader :body, :languages, :base_dir

        def initialize(body:, languages: Language.all, base_dir: "data")
          @body = body.is_a?(Body) ? body : Bodies.find(body)
          @languages = Array(languages).map { |l| l.is_a?(Language) ? l : Language.find(l) }
          @base_dir = base_dir
        end

        def call(agent: Mechanize.new)
          strategy = strategy_class.new(body: body, base_dir: base_dir, languages: languages)
          with_recording_mode(strategy.recording_mode) do
            strategy.call(agent: agent)
          end
        end

        private

        def strategy_class
          case body.strategy
          when :static_index then Strategies::StaticIndex
          when :spa_meetings then Strategies::SpaMeetings
          else raise ArgumentError, "unknown strategy #{body.strategy.inspect} for body #{body.id.inspect}"
          end
        end

        def with_recording_mode(mode)
          return yield if mode == :cassette

          disable_vcr_and_webmock!
          yield
        end

        def disable_vcr_and_webmock!
          begin
            require "vcr"
            VCR.eject_cassette
            VCR.turn_off!(ignore_cassettes: true)
          rescue LoadError, VCR::Errors::Error
            # VCR not loaded or already turned off.
          end
          begin
            require "webmock"
            WebMock.disable!
          rescue LoadError
            # webmock not loaded.
          end
        end
      end
    end
  end
end
