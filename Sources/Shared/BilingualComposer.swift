import Foundation

/// A deterministic local composer for one word. It keeps the original keys
/// separate from what is displayed so decisions can change as new letters
/// arrive (e.g. "too" -> "tooi" -> "tôi"; "boo" -> "book").
/// No cloud model is queried while typing.
enum BilingualComposer {
    enum Preference: String {
        case automatic = "auto"
        case vietnamese = "vi"
        case english = "en"
    }

    struct Decision: Equatable {
        let rendered: String
        let language: String
    }

    static func compose(_ raw: String, preference: Preference = .automatic) -> Decision {
        guard !raw.isEmpty, raw.count <= 40 else {
            return Decision(rendered: raw, language: "literal")
        }
        if preference == .english {
            return Decision(rendered: raw, language: "en")
        }
        let vi = VietnameseTelex.composeKeys(raw)
        if preference == .vietnamese {
            return Decision(rendered: vi, language: "vi")
        }
        let lower = raw.lowercased()
        let vietnamese = vi.lowercased()
        let englishWord = SmartTyping.isEnglishWord(lower)
        let englishPrefix = SmartTyping.isEnglishPrefix(lower)
        let vietnameseWord = SmartTyping.isVietnameseWord(vietnamese)

        // An English word already complete has priority over a speculative
        // Telex conversion, except when the user types an explicit diacritic
        // marker that is not a valid English continuation.
        if englishWord {
            return Decision(rendered: raw, language: "en")
        }
        // A complete Vietnamese word wins over an unfinished English prefix:
        // "too" -> maybe "tool" but "tooi" -> definitely "tôi".
        if vietnameseWord && vi != raw {
            return Decision(rendered: vi, language: "vi")
        }
        // English prefixes remain literal until additional keys disambiguate.
        if englishPrefix {
            return Decision(rendered: raw, language: "en-prefix")
        }
        // A word that cannot plausibly be English takes the usual Telex path.
        return Decision(rendered: vi, language: vi == raw ? "literal" : "vi")
    }

    static func append(_ raw: String, key: String,
                       preference: Preference = .automatic) -> Decision {
        compose(raw + key, preference: preference)
    }
}
