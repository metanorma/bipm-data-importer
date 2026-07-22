# frozen_string_literal: true

require "date"

module Bipm
  module Data
    module Importer
      module Text
        # French-language text utilities shared by every scraping strategy.
        # Single source of truth for month-name translation and date parsing
        # (previously duplicated between Common.extract_date and CGPM.parse_date_text).
        module French
          MONTH_TRANSLATIONS = {
            /janvier/i    => "january",
            /f[eé]vrier/i => "february",
            /mars/i       => "march",
            /avril/i      => "april",
            /mai/i        => "may",
            /juin/i       => "june",
            /juillet/i    => "july",
            /ao[uû]t/i    => "august",
            /septembre/i  => "september",
            /octobre/i    => "october",
            /novembre/i   => "november",
            /d[ée]cembre/i => "december",
          }.freeze

          RANGE_SEPARATORS = /, | to | au | – | — /.freeze

          def self.translate_months(str)
            MONTH_TRANSLATIONS.reduce(str) { |s, (fr, en)| s.gsub(fr, en) }
          end

          def self.parse_date(str)
            return nil if str.nil? || str.to_s.strip.empty?

            translated = translate_months(str.strip.gsub(/\s+/, " "))
            last = translated.split(RANGE_SEPARATORS).map(&:strip).reject(&:empty?).last
            return nil unless last

            Date.parse(last)
          rescue Date::Error
            nil
          end
        end
      end
    end
  end
end
