import Foundation

/// Reads the mood of a pasted message with plain keyword rules, entirely on
/// the device, and suggests Couple styles that fit. It is a hint only: it can
/// be wrong, so the user always makes the final choice.
enum MessageTone {
    struct Result: Equatable {
        let id: String
        let label: String
        let emoji: String
        /// Ids from `CoupleStyleCatalog`, best fit first.
        let styles: [String]
    }

    private struct Rule {
        let id: String
        let label: String
        let emoji: String
        let styles: [String]
        let strong: [String]
        let weak: [String]
        let emojis: [Unicode.Scalar]
    }

    // Phrases are lower case, without accents, and matched as whole words.
    private static let rules: [Rule] = [
        Rule(id: "angry", label: "Đang giận hoặc khó chịu", emoji: "😤",
             styles: ["reconcile", "apology", "mature"],
             strong: ["gian", "buc", "buc minh", "tuc", "kho chiu", "ke anh", "ke em",
                      "khong muon noi", "dung noi nua", "thoi khoi", "luc nao cung",
                      "met voi"],
             weak: ["chan", "phien", "thoi di", "ghet", "khong bao gio", "mac ke"],
             emojis: ["😡", "😤", "🤬", "😠", "😒"]),
        Rule(id: "sad", label: "Đang buồn", emoji: "😢",
             styles: ["gentle", "caring", "encourage"],
             strong: ["buon", "khoc", "tui than", "that vong", "co don", "nuoc mat",
                      "chan nan", "te qua"],
             weak: ["met long", "nho nha", "that bai"],
             emojis: ["😢", "😭", "🥺", "😞", "💔", "😔"]),
        Rule(id: "tired", label: "Đang mệt", emoji: "😴",
             styles: ["caring", "encourage", "gentle"],
             strong: ["met", "met moi", "buon ngu", "kiet suc", "stress", "ap luc",
                      "tang ca", "dau dau", "dau bung", "bi om", "bi sot", "ngu khong duoc"],
             weak: ["chong mat", "het pin", "met xiu"],
             emojis: ["😴", "🥱", "😩", "🤒", "😫"]),
        Rule(id: "needy", label: "Cần được quan tâm", emoji: "🥺",
             styles: ["sweet", "caring", "longdistance"],
             strong: ["nho anh", "nho em", "nho ban", "nho qua", "it nhan tin",
                      "khong quan tam", "bo roi", "quen em", "quen anh",
                      "sao khong nhan tin", "sao khong tra loi", "khong tra loi",
                      "con thuong khong", "con yeu khong"],
             weak: ["dao nay", "dang lam gi", "co don"],
             emojis: []),
        Rule(id: "happy", label: "Đang vui", emoji: "😊",
             styles: ["playful", "sweet", "funny"],
             strong: ["vui", "hihi", "haha", "hehe", "hanh phuc", "tuyet voi",
                      "yeu anh", "yeu em", "thich qua", "gioi qua"],
             weak: ["yeu", "thuong", "cam on", "de thuong", "thich"],
             emojis: ["🥰", "😍", "😘", "❤", "😊", "😂", "🤣", "😄", "💗", "💕"])
    ]

    /// Lower case, no accents, punctuation replaced by single spaces and
    /// padded with a space on both ends so whole words can be matched.
    static func normalized(_ text: String) -> String {
        var folded = text.lowercased()
            .folding(options: [.diacriticInsensitive], locale: Locale(identifier: "vi_VN"))
        folded = folded.replacingOccurrences(of: "đ", with: "d")
        var out = " "
        var lastWasSpace = true
        for character in folded {
            if character.isLetter || character.isNumber {
                out.append(character)
                lastWasSpace = false
            } else if !lastWasSpace {
                out.append(" ")
                lastWasSpace = true
            }
        }
        if !lastWasSpace { out.append(" ") }
        return out
    }

    private static func score(_ rule: Rule, padded: String, original: String) -> Int {
        var total = 0
        for phrase in rule.strong where padded.contains(" " + phrase + " ") { total += 2 }
        for phrase in rule.weak where padded.contains(" " + phrase + " ") { total += 1 }
        for symbol in rule.emojis where original.unicodeScalars.contains(symbol) { total += 2 }
        return total
    }

    /// The most likely mood, or nil when the message gives too little to go on.
    static func detect(_ text: String) -> Result? {
        let trimmed = String(text.prefix(1500))
        guard !trimmed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        let padded = normalized(trimmed)
        var best: (rule: Rule, score: Int)?
        // Rules are listed by priority, so a tie goes to the earlier one.
        for rule in rules {
            let value = score(rule, padded: padded, original: trimmed)
            if value >= 2, value > (best?.score ?? 0) { best = (rule: rule, score: value) }
        }
        guard let found = best else { return nil }
        return Result(id: found.rule.id, label: found.rule.label,
                      emoji: found.rule.emoji, styles: found.rule.styles)
    }
}
