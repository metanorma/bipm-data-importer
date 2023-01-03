require_relative "outcomes/body"
require_relative "outcomes/localized_body"
require_relative "outcomes/meeting"

module Bipm
  module Data
    module Outcomes
      def self.file_path
        @file_path ||= "#{__dir__}/../../../data/"
      end
      singleton_class.attr_writer :file_path

      def self.body(name)
        ensure_downloaded
        Body.new(name)
      end
      singleton_class.alias_method :[], :body

      def self.bodies
        %i[
          ccauv ccem ccl ccm ccpr ccqm ccri cct cctf ccu
          cgpm cipm jcgm jcrb
        ].to_h do |name|
          [name, body(name)]
        end
      end

      def self.each(&block)
        bodies.values.each(&block)
      end
      singleton_class.include Enumerable


      autoload :Body, "bipm/data/outcomes/body"
      autoload :LocalizedBody, "bipm/data/outcomes/localized_body"
      autoload :Meeting, "bipm/data/outcomes/meeting"
      autoload :Resolution, "bipm/data/outcomes/resolution"
      autoload :Approval, "bipm/data/outcomes/approval"
      autoload :Consideration, "bipm/data/outcomes/consideration"
      autoload :Action, "bipm/data/outcomes/action"

      # It may be possible, that we don't have the BIPM data loaded.
      def self.ensure_downloaded
        if File.exist?(file_path)
          return
        elsif !File.writable?(File.dirname(file_path))
          require "fileutils"
          self.file_path = "#{ENV["HOME"]}/.local/share/metanorma/bipm-data-importer/data/"
          FileUtils.mkdir_p(File.dirname(self.file_path))
        end
        git_path = "https://github.com/metanorma/bipm-data-outcomes"
        system "git", "clone", git_path, file_path or
          raise "Downloading bipm-data-outcomes failed: possibly git not available"
      end
    end
  end
end
