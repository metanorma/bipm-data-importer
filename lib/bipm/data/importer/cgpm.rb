# frozen_string_literal: true

module Bipm
  module Data
    module Importer
      # Backward-compatibility facade. The implementation lives in
      # Bipm::Data::Importer::Strategies::StaticIndex; this module exists
      # so that older code calling CGPM.run(agent, base_dir) keeps working.
      #
      # New code should go through Bipm::Data::Importer.fetch(:cgpm).
      module CGPM
        def self.run(agent, base_dir)
          Strategies::StaticIndex.new(
            body: Bodies[:cgpm],
            base_dir: base_dir,
          ).call(agent: agent)
        end
      end
    end
  end
end
