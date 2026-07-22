# frozen_string_literal: true

module Bipm
  module Data
    module Importer
      # Open/closed registry of all known BIPM bodies.
      # Adding a body = adding a row here, not editing CLI/scraper code.
      module Bodies
        ALL = {
          jcrb:  Body.new(id: :jcrb,  display_name: "JCRB",  path: "committees/jc/jcrb",                  strategy: :spa_meetings),
          jcgm:  Body.new(id: :jcgm,  display_name: "JCGM",  path: "committees/jc/jcgm",                  strategy: :spa_meetings),
          ccu:   Body.new(id: :ccu,   display_name: "CCU",   path: "committees/cc/ccu",                   strategy: :spa_meetings),
          cctf:  Body.new(id: :cctf,  display_name: "CCTF",  path: "committees/cc/cctf",                  strategy: :spa_meetings),
          cct:   Body.new(id: :cct,   display_name: "CCT",   path: "committees/cc/cct",                   strategy: :spa_meetings),
          ccri:  Body.new(id: :ccri,  display_name: "CCRI",  path: "committees/cc/ccri",                  strategy: :spa_meetings),
          ccpr:  Body.new(id: :ccpr,  display_name: "CCPR",  path: "committees/cc/ccpr",                  strategy: :spa_meetings),
          ccqm:  Body.new(id: :ccqm,  display_name: "CCQM",  path: "committees/cc/ccqm",                  strategy: :spa_meetings),
          ccm:   Body.new(id: :ccm,   display_name: "CCM",   path: "committees/cc/ccm",                   strategy: :spa_meetings),
          ccl:   Body.new(id: :ccl,   display_name: "CCL",   path: "committees/cc/ccl",                   strategy: :spa_meetings),
          ccem:  Body.new(id: :ccem,  display_name: "CCEM",  path: "committees/cc/ccem",                  strategy: :spa_meetings),
          ccauv: Body.new(id: :ccauv, display_name: "CCAUV", path: "committees/cc/ccauv",                 strategy: :spa_meetings),
          cipm:  Body.new(id: :cipm,  display_name: "CIPM",  path: "committees/ci/cipm",                  strategy: :spa_meetings),
          cgpm:  Body.new(id: :cgpm,  display_name: "CGPM",  path: "worldwide-metrology/cgpm/resolutions.html", strategy: :static_index),
        }.freeze

        UnknownBodyError = Class.new(ArgumentError)

        def self.all
          ALL.values
        end

        def self.find(id)
          key = id.to_sym
          ALL[key] || raise(UnknownBodyError, "unknown body: #{id.inspect} (known: #{ALL.keys.inspect})")
        end
        singleton_class.alias_method :[], :find

        def self.each(&block)
          ALL.values.each(&block)
        end
        singleton_class.include Enumerable
      end
    end
  end
end
