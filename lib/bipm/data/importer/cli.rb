# frozen_string_literal: true

require "optparse"

module Bipm
  module Data
    module Importer
      # Argument parsing and dispatch. The exe/bipm-fetch shim delegates here
      # so the executable stays a one-liner and the CLI is fully testable.
      class CLI
        Options = Struct.new(:body_id, :languages, :base_dir, :fork)

        def initialize(argv)
          @argv = argv
        end

        def run
          opts = parse(@argv)
          if opts.body_id
            run_one(opts)
          else
            run_all(opts)
          end
          0
        rescue Bodies::UnknownBodyError => e
          warn "error: #{e.message}"
          2
        rescue => e
          warn "fatal: #{e.class}: #{e.message}"
          warn e.backtrace.first(5).join("\n")
          1
        end

        def parse(argv)
          opts = Options.new(nil, nil, "data", false)
          parser = OptionParser.new do |p|
            p.banner = "Usage: bipm-fetch [options]"
            p.on("--body=ID", "Fetch a single body (e.g. cgpm, cipm)") { |v| opts.body_id = v.to_sym }
            p.on("--language=LANG", "Restrict to one language (en or fr)") do |v|
              opts.languages = [Language.find(v)]
            end
            p.on("--base-dir=DIR", "Output directory (default: data)") { |v| opts.base_dir = v }
            p.on("--fork", "Fork one process per body") { opts.fork = true }
          end
          parser.parse!(argv.dup)
          opts
        end

        private

        def run_one(opts)
          fetcher = Fetcher.new(
            body: opts.body_id,
            languages: opts.languages || Language.all,
            base_dir: opts.base_dir,
          )
          fetcher.call
        end

        def run_all(opts)
          languages = opts.languages || Language.all
          fetchers = Bodies.all.map do |body|
            Fetcher.new(body: body, languages: languages, base_dir: opts.base_dir)
          end
          if opts.fork
            run_forked(fetchers)
          else
            fetchers.each(&:call)
          end
        end

        def run_forked(fetchers)
          pids = []
          fetchers.each do |f|
            pid = fork { f.call; exit! }
            pids << pid if pid
          end
          pids.each { |pid| Process.wait(pid) }
        end
      end
    end
  end
end
