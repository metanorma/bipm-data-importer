# frozen_string_literal: true

module Bipm
  module Data
    module Importer
      # Registry of upstream-data patches. Each quirk documents a specific
      # mistake on bipm.org (or in a cassette) and the transformation that
      # corrects it. Adding a new quirk = adding a method here, not editing
      # the scrape loop.
      #
      # Categories:
      #   - HREF_TRANSFORMS: URL path corrections applied unconditionally.
      #   - per-meeting predicates/rewrites that depend on (body, lang, id).
      module Quirks
        HREF_TRANSFORMS = [
          # Legacy URL typo: /jen/ should be /en/.
          ->(href) { href.gsub(%r{\A/jen/}, "/en/") },
          # Legacy CGPM document database path.
          ->(href) { href.gsub(%r{\A/en/CGPM/jsp/}, "/en/CGPM/db/") },
          # CIPM fr recommendation listing points to the wrong meeting URL
          # for two specific resolutions on the 106-2017 page.
          ->(href) do
            next href unless href =~ %r{/ci/cipm/106-2017/resolution-[12]\z}
            href.gsub("/106-2017/", "/104-_1-2015/")
          end,
          # CIPM 104-2015 actually lives at 104-_1-2015.
          ->(href) { href.gsub("/104-2015/", "/104-_1-2015/") },
          # Normalise the legacy Liferay /web/guest/ prefix to the locale.
          # (Caller supplies the language via Quirks.localize_guest_path.)
        ].freeze

        def self.fix_href(href, language: nil)
          href = href.gsub(%r{\Ahttps://www\.bipm\.org}, "")
          if language && href.include?("/web/guest/")
            href = href.gsub("/web/guest/", "/#{language}/")
          end
          HREF_TRANSFORMS.reduce(href) { |h, fn| fn.call(h) }
        end

        # CIPM 104-_2-2015 is a duplicate of 104-_1-2015; clear the year
        # so the scrape skips the recommendations branch for it.
        def self.skip_meeting_year?(body_id, meeting_id)
          [body_id, meeting_id] == [:cipm, "104-2"]
        end

        # CIPM fr/94-2005 lists resolution 2 twice on the website.
        def self.deduplicate_resolutions(body_id, language, meeting_id, resolutions)
          return resolutions unless [body_id, language.to_s, meeting_id] == [:cipm, "fr", "94"]
          return resolutions unless resolutions.sort.uniq != resolutions.sort

          (1..3).map do |i|
            "https://www.bipm.org/fr/committees/ci/cipm/94-2005/resolution-#{i}"
          end
        end

        # JCRB fr/43-2021 has duplicate identifiers for one action.
        def self.renumber_jcrb_43_fr(resolutions)
          ids = resolutions.map { |i| [i["type"], i["identifier"]] }.sort
          return resolutions unless ids != ids.uniq

          idx = 1
          resolutions.map do |i|
            next i unless i["identifier"] == "43-1" && i["type"] == "action"
            i = i.dup
            i["identifier"] = "#{i['identifier']}-xxx-#{idx}"
            idx += 1
            i
          end
        end
      end
    end
  end
end
