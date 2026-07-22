# frozen_string_literal: true

module Bipm
  module Data
    module Importer
      module Strategies
        autoload :Base, "bipm/data/importer/strategies/base"
        autoload :StaticIndex, "bipm/data/importer/strategies/static_index"
        autoload :SpaMeetings, "bipm/data/importer/strategies/spa_meetings"
      end
    end
  end
end
