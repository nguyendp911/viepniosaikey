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
        return choose(raw: raw, vietnameseCandidate: vi)
    }

    /// Hot-path API: the UI already has the last Vietnamese candidate, so
    /// append one Telex key to it instead of replaying all previous keys.
    static func appendCandidate(_ candidate: String, key: String) -> String {
        guard FastTyping.isTelexModifier(key) else { return candidate + key }
        return VietnameseTelex.transformed(word: candidate, key: key) ?? (candidate + key)
    }

    static func choose(raw: String, vietnameseCandidate vi: String,
                       preference: Preference = .automatic) -> Decision {
        guard preference != .english else {
            return Decision(rendered: raw, language: "en")
        }
        if preference == .vietnamese {
            return Decision(rendered: vi, language: "vi")
        }
        let lower = raw.lowercased()
        if SmartTyping.isEnglishWord(lower) {
            return Decision(rendered: raw, language: "en")
        }
        // Vietnamese completed words beat ambiguous English prefixes,
        // e.g. too + i -> tôi, but too + l -> tool.
        if vi != raw && SmartTyping.isVietnameseWord(vi) {
            return Decision(rendered: vi, language: "vi")
        }
        if SmartTyping.isEnglishPrefix(lower) {
            return Decision(rendered: raw, language: "en-prefix")
        }
        return Decision(rendered: vi, language: vi == raw ? "literal" : "vi")
    }

    static func append(_ raw: String, key: String,
                       preference: Preference = .automatic) -> Decision {
        compose(raw + key, preference: preference)
    }
}
