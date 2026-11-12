import Foundation

/// Small, pure helpers for the hot typing path in the keyboard extension.
/// They allow ordinary letters to bypass expensive context reads and ensure
/// Telex corrections only rewrite the portion that actually changed.
enum FastTyping {
    struct Edit: Equatable {
        let deleteCount: Int
        let insertion: String
    }

    /// A Telex conversion only happens when typing a shape/tone/removal key.
    /// Ordinary text, including vowels in the middle of a word, goes directly
    /// to the host app without retrieving its full input context.
    static func isTelexModifier(_ key: String) -> Bool {
        guard key.count == 1, let letter = key.lowercased().first else { return false }
        return "aeodwsfrxjz".contains(letter)
    }

    /// For old="thuong", new="thương", keep "th", delete only "uong",
    /// then insert "ương", rather than deleting/reinserting the whole word.
    static func edit(from old: String, to new: String) -> Edit? {
        guard old != new else { return nil }
        // Most key presses append exactly one character. Avoid allocating two
        // Character arrays and scanning the whole word on this common path.
        if new.hasPrefix(old) {
            return Edit(deleteCount: 0,
                        insertion: String(new.dropFirst(old.count)))
        }
        let original = Array(old)
        let modified = Array(new)
        var prefix = 0
        while prefix < min(original.count, modified.count)
            && original[prefix] == modified[prefix] {
            prefix += 1
        }
        return Edit(deleteCount: original.count - prefix,
                    insertion: String(modified.dropFirst(prefix)))
    }
}
