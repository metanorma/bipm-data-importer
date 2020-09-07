module AsciiMath
  MATH=/[a-zA-Z0-9µ-]/
  DIGIT=/-?[0-9][0-9 .,]*[0-9]|[0-9]/
  STEM=/[^\]]*?/
  SPACE=/[\s\b^$,()]/

  def asciidoc_extract_math str
    str.gsub(/\b_(#{MATH}{1,3})_/, 'stem:[\1]')
       .gsub("_,_", ',') # Some mistake in formatting
       .gsub("^er^", 'ESCUPerESCUP') # French specialities
       .gsub(/\^(e|re)\^( |&nbsp;|)(session|Conférence|réunion|CGPM|édition)/, 'ESCUP\1ESCUP\2\3')
       .gsub("\u{96}", '-')
       .gsub(%r"image::/utils/special/14/ital/(\w*?)_maj.gif\[#{STEM}\]") { "stem:[ #{$1.capitalize} ]" }
       .gsub(%r"image::/utils/special/14/ital/(\w*?).gif\[#{STEM}\]") { "stem:[ #{$1} ]" }
       .gsub(%r"image::/utils/special/14/(\w*?)_maj.gif\[#{STEM}\]") { "stem:[ sf #{$1.capitalize} ]" }
       .gsub(%r"image::/utils/special/14/(\w*?).gif\[#{STEM}\]") { "stem:[ sf #{$1} ]" }
       .gsub(%r"image::/utils/special/Math/plusminus.gif\[#{STEM}\]", 'stem:[ +- ]')
       #.gsub(/(?<=#{SPACE})(m|m\/s|mol|s|kg|W|cd|J|K)\^(#{DIGIT})\^(?>=#{SPACE})/, 'stem:[\1^(\2)]') # Basic units with powers
       #.gsub(/(?<=#{SPACE})(m|m\/s|mol|s|kg|W|cd|J|K)(?>=#{SPACE})/, 'stem:[\1]') # Basic units without powers
       .gsub(/stem:\[(#{STEM})\]~(#{MATH}{1,4})~/, 'stem:[\1_(\2)]')
       .gsub(        /(#{DIGIT})~(#{MATH}{1,4})~/, 'stem:[\1_(\2)]')
       .gsub(/stem:\[(#{STEM})\]\^(#{MATH}{1,4})\^/, 'stem:[\1^(\2)]')
       .gsub(        /(#{DIGIT})\^(#{MATH}{1,4})\^/, 'stem:[\1^(\2)]')
       .gsub(/stem:\[(#{STEM})\] ?[´x×·] ?stem:\[(#{STEM})\]/, 'stem:[\1 * \2]')
       .gsub(        /(#{DIGIT}) ?[´x×·] ?stem:\[(#{STEM})\]/, 'stem:[\1 * \2]')
       .gsub(        /(#{DIGIT})( ?| ?[=\/+] ?)stem:\[(#{STEM})\]/, 'stem:[\1\2\3]')
       .gsub(/stem:\[(#{STEM})\]( ?| ?[=\/+] ?)(#{DIGIT})/,         'stem:[\1\2\3]')
       .gsub(/stem:\[(#{STEM})\]( ?| ?[=\/+] ?)stem:\[(#{STEM})\]/, 'stem:[\1\2\3]')
       .gsub(/stem:\[(#{STEM})\]\(stem:\[(#{STEM})\]\)/, 'stem:[\1(\2)]') # Functions
       .gsub(/\(stem:\[(#{STEM})\]\)stem:\[(#{STEM})\]/, 'stem:[(\1)\2]')
       .gsub(/stem:\[(#{STEM})\]/) { "stem:[#{$1.gsub(",", '","')}]" } # French special case
       .gsub('ESCUP', '^') #Unescape French language
  end

  extend self
end
