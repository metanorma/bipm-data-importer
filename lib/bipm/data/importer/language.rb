# frozen_string_literal: true

module Bipm
  module Data
    module Importer
      # First-class language value object. English and French are equal
      # citizens — neither is the canonical form, neither is a translation
      # of the other. Both directions of any linguistic operation must be
      # expressible through this type without one being the "default".
      class Language
        attr_reader :code

        def initialize(code)
          @code = code
        end

        EN = new(:en)
        FR = new(:fr)
        ALL = [EN, FR].freeze

        def self.find(name)
          sym = name.to_sym
          ALL.find { |l| l.code == sym } ||
            raise(ArgumentError, "unknown language: #{name.inspect} (supported: #{ALL.map(&:to_s).inspect})")
        end

        def self.all
          ALL
        end

        def to_s
          @code.to_s
        end

        def to_sym
          @code
        end

        def suffix
          case @code
          when :en then ""
          when :fr then "-fr"
          else raise(ArgumentError, "no suffix defined for #{@code}")
          end
        end

        def directory_suffix
          case @code
          when :en then "-en"
          when :fr then "-fr"
          else raise(ArgumentError, "no directory suffix for #{@code}")
          end
        end

        def eql?(other)
          other.is_a?(Language) && @code == other.code
        end
        alias == eql?

        def hash
          @code.hash
        end
      end
    end
  end
end
