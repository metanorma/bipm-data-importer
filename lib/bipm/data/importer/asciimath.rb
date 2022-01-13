module Bipm
  module Data
    module Importer
      module AsciiMath
        MATH=/[a-zA-Z0-9µ-]/
        DIGIT=/-?[0-9][0-9 .,]*[0-9]|-?[0-9]/
        STEM=/[^\]]*?/
        SPACE_BEFORE=/(?:\A|(?<=&nbsp;|\s|[,()\/.~^]))/
        SPACE_AFTER=/(?:\Z|(?=&nbsp;|\s|[,()\/.~"^]))/

        PREFIXES = /m|c|d|k|M|G|T|/
        UNITS = /t|m|mol|cal|µ|s|g|W|cd|Hz|J|K|N|V|H|A|C|F|T|Wb|sr|lx|lm|bar|sb|h|rad|°C|°F|°K/

        def asciidoc_extract_math str
          str.gsub(/\b_(#{MATH}{1,3})_/, 'stem:[\1]')
            .gsub("_,_", ',') # Some mistake in formatting
            .gsub("^er^", 'ESCUPerESCUP') # French specialities
            .gsub(/(bar|A) (table|of|key|de|being|full|1)( |,)/, 'ESC\1 \2\3') # A is Ampere, but also a particle, bar is a bar but also a bar
            .gsub(/\b([TJWCFHA]\.)/, 'ESC\1') # J. is an initial
            .gsub(/\^(e|re)\^( |)(session|Conférence|réunion|CGPM|édition)/, 'ESCUP\1ESCUP\2\3')
            .gsub("\u{96}", '-')
            .gsub(%r"image::/utils/special/14/ital/(\w*?)_maj.gif\[#{STEM}\]") { "stem:[ #{$1.capitalize} ]" }
            .gsub(%r"image::/utils/special/14/ital/(\w*?).gif\[#{STEM}\]") { "stem:[ #{$1} ]" }
            .gsub(%r"image::/utils/special/14/(\w*?)_maj.gif\[#{STEM}\]") { "stem:[ sf #{$1.capitalize} ]" }
            .gsub(%r"image::/utils/special/14/(\w*?).gif\[#{STEM}\]") { "stem:[ sf #{$1} ]" }
            .gsub(%r"image::/utils/special/Math/plusminus.gif\[#{STEM}\]", 'stem:[ +- ]')
            .gsub(/#{SPACE_BEFORE}\^(#{DIGIT})\^(C|O|H|Cs|He)#{SPACE_AFTER}/, 'stem:[""_(\1) "\2"]') # Nucleus symbols
            .gsub(/#{SPACE_BEFORE}(#{PREFIXES})(#{UNITS})\^(#{DIGIT})\^#{SPACE_AFTER}/, 'stem:[ESCUN"\1\2"^(\3)ESCUN]') # Basic units with powers
            .gsub(/#{SPACE_BEFORE}(#{PREFIXES})(#{UNITS})#{SPACE_AFTER}/, 'stem:[ESCUN"\1\2"ESCUN]') # Basic units without powers
            .gsub(/stem:\[(#{STEM})\]~(#{MATH}{1,4})~/, 'stem:[\1_(\2)]')
            .gsub(/~stem:\[(#{STEM})\]~~(#{MATH}{1,4})~/, 'stem:[\1_(\2)]') # A mistake in formatting
            .gsub(        /(#{DIGIT})~(#{MATH}{1,4})~/, 'stem:[\1_(\2)]')
            .gsub(/stem:\[(#{STEM})\]\^(#{MATH}{1,4})\^/, 'stem:[\1^(\2)]')
            .gsub(        /(#{DIGIT})\^(#{MATH}{1,4})\^/, 'stem:[\1^(\2)]')
            .gsub("π", "stem:[ pi ]") # The following may be buggy - may escape twice
            .gsub("α", "stem:[ alpha ]")
            #.gsub("µ", "stem:[ mu ]")
            .gsub("Δ", "stem:[ sf Delta ]")
            .gsub("ν", "stem:[ nu ]")
            .gsub(/stem:\[(#{STEM})\]~stem:\[(#{STEM})\]~/, 'stem:[\1_(\2)]') # Connectors for sub stems
            .gsub(/stem:\[(#{STEM})\]\^stem:\[(#{STEM})\]\^/, 'stem:[\1^(\2)]') # Connectors for super stems
            .gsub(/stem:\[(#{STEM})\] ?[´x×·] ?stem:\[(#{STEM})\]/, 'stem:[\1 * \2]') # Connectors
            .gsub(        /(#{DIGIT}) ?[´x×·] ?stem:\[(#{STEM})\]/, 'stem:[\1 * \2]')
            .gsub(        /(#{DIGIT})( ?| ?[=\/+-] ?)stem:\[(#{STEM})\]/, 'stem:[\1\2\3]')
            .gsub(/stem:\[(#{STEM})\]( ?| ?[=\/+-] ?)(#{DIGIT})/,         'stem:[\1\2\3]')
            .gsub(/stem:\[(#{STEM})\]( ?| ?[=\/+-] ?)stem:\[(#{STEM})\]/, 'stem:[\1\2\3]') # End connectors
            .gsub(/stem:\[(#{STEM})\]\(stem:\[(#{STEM})\]\)/, 'stem:[\1(\2)]') # Functions
            .gsub(/\(stem:\[(#{STEM})\]\)stem:\[(#{STEM})\]/, 'stem:[(\1)\2]')
            .gsub(/\(stem:\[(#{STEM})\]\)/, 'stem:[(\1)]') # Capture parens inside
            .gsub(/stem:\[(#{STEM})\](TT|TCG)/, 'stem:[\1 "\2"]') # Stem extension for something I have no idea about
            .gsub(/stem:\[(#{STEM})\]~(hfs)~/, 'stem:[\1_("\2")]') # Stem extension for something I have no idea about
            .gsub(/(UTC)stem:\[(#{STEM})\]/, 'stem:["\1" \2]') # Stem extension for timezones
            .gsub(        /(#{DIGIT})( ?| ?[=\/+-] ?)stem:\[(#{STEM})\]/, 'stem:[\1\2\3]') # Connectors pass 2
            .gsub(/stem:\[(#{STEM})\]( ?| ?[=\/+-] ?)(#{DIGIT})/,         'stem:[\1\2\3]')
            .gsub(/stem:\[(#{STEM})\]( ?| ?[=\/+-] ?)stem:\[(#{STEM})\]/, 'stem:[\1\2\3]') # Try connecting two times more
            .gsub(/stem:\[(#{STEM})\]( ?| ?[=\/+-] ?)stem:\[(#{STEM})\]/, 'stem:[\1\2\3]') # Try connecting two times more
            .gsub(/stem:\[(#{STEM})\]/) { "stem:[#{$1.gsub(",", '","')}]" } # French special case
            .gsub(/ESCUN\s*ESCUN/, ' * ')
            .gsub(" sf pi ", " pi ") # serif pi looks ugly in AsciiMath. They probably mean italics pi
            .gsub('d "TT"/d "TCG"', '(d "TT")/(d "TCG")') # Fix handling of a derivative
            .gsub('ESCUP', '^') #Unescape French language
            .gsub('ESCUN', '') #Unescape units
            .gsub('ESCbar', 'bar') #Unescape bars
            .gsub(/ESC([TJWCFHA])/, '\1') #Unescape joules
        end

        extend self
      end
    end
  end
end