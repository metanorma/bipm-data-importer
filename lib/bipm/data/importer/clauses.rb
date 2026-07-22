# frozen_string_literal: true

# Single source of truth for the clause taxonomy used by every scraping
# strategy. Replaces the previously-duplicated CONSIDERATIONS/ACTIONS hashes
# in common.rb and the VERB_TO_TYPE/FR_VERB_TO_EN/CONSIDERATION_VERBS/
# ACTION_VERBS constants in cgpm.rb.
#
# Design principle: French and English are first-class citizens. The VERBS
# table is keyed by either language's verb form and maps directly to a
# (type, category) pair — there is no "translate FR → EN then look up"
# step. Adding a new language means adding new keys to the same table.
module Bipm
  module Data
    module Importer
      module Clauses
        CATEGORY_CONSIDERATION = :consideration
        CATEGORY_ACTION = :action

        # Phrase-level regex patterns. Order matters: tried top-to-bottom,
        # first match wins. Two hashes preserved (rather than one merged
        # table) so that consumers can ask "is this text a consideration?"
        # without scanning action patterns. Patterns themselves freely mix
        # English and French alternatives — no language is canonical.
        CONSIDERATIONS = {
          /(?:having(?: regard)?|ayant|concerne|vu la|agissant conformément|sachant|de porter)/i => "having / having regard",
          /(?:noting|to note|took note|note[sd]?|taking note|takes note|constatant|constate|that|notant|notant que|note également|(?:prend|prenant) (?:acte|note))/i => "noting",
          /(?:recognizing|recognizes|reconnaissant|reconnaît)/i => "recognizing",
          /(?:acknowledging|admet|entendu|(?:and |)aware that|anticipa(?:ting|nt))/i => "acknowledging",
          /(?:(?:further )?recall(?:ing|s|ed)|rappelant|rappelle|rappelantla)/i => "recalling / further recalling",
          /(?:re-?affirm(?:ing|s)|réaffirme)/i => "reaffirming",
          /(?:consid(?:er(?:ing|)|érant|ère|ers|ered|érantque|érantle)|après examen|estime|is of the opinion|examinera|en raison|by reason)/i => "considering",
          /(?:The Consultative Committee for Time and Frequency \(CCTF\), at|Le Comité consultatif du temps et des fréquences \(CCTF\), à)/i => "considering",
          /(?:taking into account|(prend|prenant) en considération|taking into consideration|tenant compte|envisager)/i => "taking into account",
          "pursuant to" => "pursuant to",
          /(?:bearing in mind)/i => "bearing in mind",
          /(?:emphasizing|soulignant)/i => "emphasizing",
          "concerned" => "concerned",
          /(?:accept(?:s|ed|ing|e)|acceptant)/i => "accepts",
          /(?:observing|observant que|r[ée]ali(?:zing|sant))/i => "observing",
          /(?:referring|se référant)/i => "referring",
          /(?:acting in accordance|agissant conformément|conformément)/i => "acting",
          /(?:empowered by|habilité par)/i => "empowers",
        }.freeze

        ACTIONS = {
          /(?:adopts|adopt[eé]d?|convient d'adopter)/ => "adopts",
          /(?:thanks|thanked|expresse[sd](?:[ -]| its )appreciation|appréciant|pays tribute|rend hommage|remercie|support(?:ed|s))/i => "thanks / expresses-appreciation",
          /(?:approu?v[eé][ds]?|approuv[ae]nt|approving|entérine|(?:It was )?agree[sd]?|soutient|exprime son accord|n'est pas d'accord|convient)/i => "approves",
          /(?:d[eé]cid(?:e[ds]?|é)|ratifies?|r[eé]vised?)/i => "decides",
          /(?:d[ée]clares?|d[ée]finition)/i => "declares",
          /(?:The unit of length is|Supplementary units|Derived units|Principl?es|Les Délégués des États|Les v(?:œ|\u{9C})ux ou propositions)/i => "declares",
          /(?:L'unité de longueur|Unités supplémentaires|Unités dérivées|(?:\*_)?New candle|(?:\*_)?New lumen|(?:A\) )?D[ée]finitions (?:of|des)|Cubic decimetre|Clarification of|Revision of)/i => "declares",
          /(?:Unit of force|Définitions des|Décimètre cube|Étalons secondaires|Unité spéciale|Efficacités lumineuses|From three names|Entre les trois termes)/i => "declares",
          /(?:Unité de force|(?:Joule|Watt|Volt|Ohm|Amp[eè]re|Coulomb|Farad|Henry|Weber) \(unité?|Bougie nouvelle|Lumen nouveau|announces that|annonce que)/i => "declares",
          /(?:Les unités photométriques|\(A\) D[eé]finitions|The photometric units|will (?:provide|circulate|issue|identify|notify|contact|review))/i => "declares",
          /(?:Appendix 1 of the|L'Annexe 1 de la|increased|a (?:examiné|préparé)|transmettra|fournira|increased|developed a document|prendra contact)/i => "declares",
          /(?:Le Temps Atomique International |International Atomic Time \(TAI\) |will meet )/i => "declares",
          /(?:ask[s ]|asked|souhaite|souhaiterait)/i => "asks",
          /(?:(?:further |et )?invit(?:[ée][ds]?|era)|renouvelle en conséquence|convient d'inviter)/i => "invites / further invites",
          /(?:resolve[sd]?)/i => "resolves",
          /(?:confirms|confirmed?|confirme que|committed|s'engageant)/i => "confirms",
          /(?:welcom(?:e[sd]?|ing)|accueille favorablement(?:les)?|salu(?:e|ant))/i => "welcomes",
          /(?:recomm(?:ends?|ande(?:nt|)|ended)|endorsed|LISTE DES RADIATIONS|1 Radiations recommandées|LIST OF RECOMMENDED|1 Recommended radiations|aim(?:s|ing)|a pour objectif|should)/i => "recommends",
          /(?:requests?|requested|demande(?:ra)?|requi[eè]r(?:en|)t|must)|l'intention d’examiner/ => "requests",
          /(?:(?:is |are |)(?:to |)(?:re-?|)(?:amend|investigate|delete|help|present|develop|create|refer|add|formalise|update|collaborate|ensure|modify|prepare|look|report|consider|continue|make|bring|post|request|draw|raise|draft|circulate|arrange|provide|send|write|check|amend|forward|distribute|pursue|inform|coordinate|discuss|submit|ask|inquire|put)|will)/i => "requests",
          /(?:congratulate[sd]?|félicite)/i => "congratulates",
          /(?:instructs|instructed|inform[es]|intends to)/i => "instructs",
          /(?:(?:strongly |)urges|prie instamment)/i => "urges",
          /(?:appoints|(?:re)?appointed|granted|reconduit|commended|accorde)/i => "appoints",
          /(?:donn(?:e|ées)|Pendant la période|voted|established a \w+ task group)/i => "appoints",
          /(?:convient d'éablir|transfère|confie|établit|Étant donné que trois sièges|As there will be three vacancies)/i => "appoints",
          /(?:La Recommandation 1 du Groupe|Recommendation 1 of the ad hoc)/i => "appoints",
          /(?:élit|nomme|elected|nominated)/ => "elects",
          /(?:gave the \w+ \w+ the authority|autorise|authorized)/ => "authorizes",
          /(?:charged?)/ => "charges",
          /(?:resolve[sd]? further)/i => "resolves further",
          /(?:calls upon|draws the attention|attire l'attention|lance un appel|called upon)/i => "calls upon",
          /(?:encourages?d?|espère|propose[ds]?)/i => "encourages",
          /(?:affirms|reaffirming|réaffirmant|concurs)/i => "affirms / reaffirming",
          /(?:states)/i => "states",
          /(?:remarks|remarques)/i => "remarks",
          /(?:judges)/i => "judges",
          /(?:sanction(?:s|né?e))/i => "sanctions",
          /(?:abrogates|abroge)/i => "abrogates",
          /(?:empowers|habilite)/i => "empowers",
        }.freeze

        # Verb → (type, category). Symmetric across English and French —
        # both languages are first-class keys, no canonical form.
        VERBS = {
          # consideration verbs
          "having"         => ["having / having regard", CATEGORY_CONSIDERATION],
          "ayant"          => ["having / having regard", CATEGORY_CONSIDERATION],
          "vu"             => ["having / having regard", CATEGORY_CONSIDERATION],
          "considering"    => ["considering",            CATEGORY_CONSIDERATION],
          "considérant"    => ["considering",            CATEGORY_CONSIDERATION],
          "noting"         => ["noting",                 CATEGORY_CONSIDERATION],
          "notant"         => ["noting",                 CATEGORY_CONSIDERATION],
          "notes"          => ["notes",                  CATEGORY_CONSIDERATION],
          "note"           => ["notes",                  CATEGORY_CONSIDERATION],
          "recognizing"    => ["recognizing",            CATEGORY_CONSIDERATION],
          "reconnaissant"  => ["recognizing",            CATEGORY_CONSIDERATION],
          "reconnaît"      => ["recognizing",            CATEGORY_CONSIDERATION],
          "reaffirming"    => ["reaffirming",            CATEGORY_CONSIDERATION],
          "réaffirmant"    => ["reaffirming",            CATEGORY_CONSIDERATION],
          "recalling"      => ["recalling / further recalling", CATEGORY_CONSIDERATION],
          "rappelant"      => ["recalling / further recalling", CATEGORY_CONSIDERATION],
          "rappelle"       => ["recalling / further recalling", CATEGORY_CONSIDERATION],
          "acknowledging"  => ["acknowledging",          CATEGORY_CONSIDERATION],
          "taking"         => ["taking into account",    CATEGORY_CONSIDERATION],
          "tenant"         => ["taking into account",    CATEGORY_CONSIDERATION],
          "pursuant"       => ["pursuant to",            CATEGORY_CONSIDERATION],
          "bearing"        => ["bearing in mind",        CATEGORY_CONSIDERATION],
          "emphasizing"    => ["emphasizing",            CATEGORY_CONSIDERATION],
          "soulignant"     => ["emphasizing",            CATEGORY_CONSIDERATION],
          "concerned"      => ["concerned",              CATEGORY_CONSIDERATION],
          "concerné"       => ["concerned",              CATEGORY_CONSIDERATION],
          "accepts"        => ["accepts",                CATEGORY_CONSIDERATION],
          "accepte"        => ["accepts",                CATEGORY_CONSIDERATION],
          "observing"      => ["observing",              CATEGORY_CONSIDERATION],
          "observant"      => ["observing",              CATEGORY_CONSIDERATION],
          "réalise"        => ["observing",              CATEGORY_CONSIDERATION],
          "referring"      => ["referring",              CATEGORY_CONSIDERATION],
          "se référant"    => ["referring",              CATEGORY_CONSIDERATION],
          "acting"         => ["acting",                 CATEGORY_CONSIDERATION],
          "agissant"       => ["acting",                 CATEGORY_CONSIDERATION],
          "empowers"       => ["empowers",               CATEGORY_CONSIDERATION],
          "habilité"       => ["empowers",               CATEGORY_CONSIDERATION],
          "habilite"       => ["empowers",               CATEGORY_CONSIDERATION],
          # action verbs
          "decides"        => ["decides",                CATEGORY_ACTION],
          "décide"         => ["decides",                CATEGORY_ACTION],
          "declares"       => ["declares",               CATEGORY_ACTION],
          "déclare"        => ["declares",               CATEGORY_ACTION],
          "invites"        => ["invites / further invites", CATEGORY_ACTION],
          "invite"         => ["invites / further invites", CATEGORY_ACTION],
          "resolves"       => ["resolves",               CATEGORY_ACTION],
          "résout"         => ["resolves",               CATEGORY_ACTION],
          "confirms"       => ["confirms",               CATEGORY_ACTION],
          "confirme"       => ["confirms",               CATEGORY_ACTION],
          "welcomes"       => ["welcomes",               CATEGORY_ACTION],
          "accueille"      => ["welcomes",               CATEGORY_ACTION],
          "recommends"     => ["recommends",             CATEGORY_ACTION],
          "recommande"     => ["recommends",             CATEGORY_ACTION],
          "requests"       => ["requests",               CATEGORY_ACTION],
          "demande"        => ["requests",               CATEGORY_ACTION],
          "appoints"       => ["appoints",               CATEGORY_ACTION],
          "nomme"          => ["appoints",               CATEGORY_ACTION],
          "encourages"     => ["encourages",             CATEGORY_ACTION],
          "encourage"      => ["encourages",             CATEGORY_ACTION],
          "affirms"        => ["affirms / reaffirming",  CATEGORY_ACTION],
          "affirme"        => ["affirms / reaffirming",  CATEGORY_ACTION],
          "calls"          => ["calls upon",             CATEGORY_ACTION],
          "lance un appel" => ["calls upon",             CATEGORY_ACTION],
          "states"         => ["states",                 CATEGORY_ACTION],
          "indique"        => ["states",                 CATEGORY_ACTION],
          "remarks"        => ["remarks",                CATEGORY_ACTION],
          "remarques"      => ["remarks",                CATEGORY_ACTION],
          "urges"          => ["urges",                  CATEGORY_ACTION],
          "prie"           => ["urges",                  CATEGORY_ACTION],
          "instructs"      => ["instructs",              CATEGORY_ACTION],
          "informe"        => ["instructs",              CATEGORY_ACTION],
          "adopts"         => ["adopts",                 CATEGORY_ACTION],
          "adopte"         => ["adopts",                 CATEGORY_ACTION],
          "thanks"         => ["thanks / expresses-appreciation", CATEGORY_ACTION],
          "remercie"       => ["thanks / expresses-appreciation", CATEGORY_ACTION],
          "approves"       => ["approves",               CATEGORY_ACTION],
          "approuve"       => ["approves",               CATEGORY_ACTION],
          "asks"           => ["asks",                   CATEGORY_ACTION],
          "souhaite"       => ["asks",                   CATEGORY_ACTION],
          "congratulates"  => ["congratulates",          CATEGORY_ACTION],
          "félicite"       => ["congratulates",          CATEGORY_ACTION],
          "elects"         => ["elects",                 CATEGORY_ACTION],
          "élit"           => ["elects",                 CATEGORY_ACTION],
          "authorizes"     => ["authorizes",             CATEGORY_ACTION],
          "autorise"       => ["authorizes",             CATEGORY_ACTION],
          "charges"        => ["charges",                CATEGORY_ACTION],
          "judges"         => ["judges",                 CATEGORY_ACTION],
          "juge"           => ["judges",                 CATEGORY_ACTION],
          "sanctions"      => ["sanctions",              CATEGORY_ACTION],
          "sanctionne"     => ["sanctions",              CATEGORY_ACTION],
          "abrogates"      => ["abrogates",              CATEGORY_ACTION],
          "abroge"         => ["abrogates",              CATEGORY_ACTION],
        }.freeze

        CONSIDERATION_TYPES = CONSIDERATIONS.values.uniq.freeze
        ACTION_TYPES = ACTIONS.values.uniq.freeze

        PREFIX1 = /(?:The|Le) CIPM |La Conférence |M. Volterra |M. le Président |unanimously |would |a |sont |will |were |did not |strongly |(?:La|The) (?:\d+(?:e|th)|Quinzième) Conférence Générale des Poids et Mesures(?: a |,\s+)?/i
        PREFIX2 = /The \d+th Conférence Générale des Poids et Mesures |The Conference |and |et (?:en |)|has |renouvelle sa |renews its |further |and further |En ce qui |après avoir |\.\.\.\n+\t*/i
        PREFIX3 = /Sur la proposition de M. le Président, la convocation de cette Conférence de Thermométrie est |Le texte corrigé, finalement |(?:The|Le) Comité International(?: des Poids et Mesures)?(?: \(CIPM\))?(?: a |,)?\s*/i
        PREFIX4 = /(?:The |Le |)(?:JCRB|JCGM|CCU|CCTF|CCT|CCRI|CCPR|CCQM|CCM|CCL|CCEM|CCAUV|KCDB),? (?:also |)|Each RMO |fully |The JCRB Rules of Procedure are |Bob Watters and Claudine Thomas /
        PREFIX5 = /(?:The |Le |All |)(?:incoming |)(?:JCRB |KCDB |)(?:documents|(?:Consultative |)Committees?|Office|Chairman(?: and Secretary|)|Joint BIPM[\/-]ILAC Working Group(?: \(see Action 22\))|RMO(?:[- ]JCRB|) Representatives(?: to the JRCB|)|(?:BIPM |)Director(?: of BIPM|)|SIM|(?:Exec(?:utive|) |)Secretary(?:\(ies\)|)|RMOs, except SIM,|RMOs|APMP|\(?(?:[MD]r|Prof) [A-Z][a-zR-]+\)?|CMCs|EUR[AO]MET|COOMET|GULFMET) |It was /
        PREFIX6 = /“|"|« à |All RMO documents related to review procedures |Mr Lam and Dr Kühne |The Prof. Kühne, Mr Jones and the Executive Secretary |Ajchara Charoensook, from APMP, /

        PREFIX = /(?:#{PREFIX1}|#{PREFIX2}|#{PREFIX3}|#{PREFIX4}|#{PREFIX5}|#{PREFIX6})?/i

        SUFFIX = / (?:that|que)\b|(?: (?:the |that |le |que les )?((?:[A-Z]|national|laboratoires).{0,80}?)(?: to)?\b|)/

        LEADING_CONJUNCTIONS = /\A(?:et|and|further|de plus|puis|also)\s+/.freeze
        TRAILING_PUNCTUATION = /[.:,;]\z/.freeze

        # Strip leading conjunctions and trailing punctuation from a verb token.
        # Returns the verb in whichever language it was supplied — does NOT
        # translate between French and English. Use lookup_verb to find the
        # canonical (type, category) for either language's verb.
        def self.normalize_verb(raw)
          raw.to_s.downcase.strip
             .sub(TRAILING_PUNCTUATION, "")
             .strip
             .sub(LEADING_CONJUNCTIONS, "")
             .strip
        end

        # Lookup a normalized verb's (type, category). Verb may be in either
        # English or French — VERBS table has both as first-class keys.
        def self.lookup_verb(verb)
          VERBS.fetch(verb) { [fallback_type(verb), fallback_category(verb)] }
        end

        def self.category_for_type(type)
          return CATEGORY_CONSIDERATION if CONSIDERATION_TYPES.include?(type)
          return CATEGORY_ACTION if ACTION_TYPES.include?(type)
          CATEGORY_ACTION
        end

        def self.fallback_type(verb)
          return "considering" if verb == "having" || verb == "ayant" || verb == "vu"
          "decides"
        end

        def self.fallback_category(verb)
          return CATEGORY_CONSIDERATION if verb == "having" || verb == "ayant" || verb == "vu"
          CATEGORY_ACTION
        end
      end
    end
  end
end
