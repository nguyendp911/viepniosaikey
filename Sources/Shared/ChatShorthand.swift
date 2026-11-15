import Foundation

/// Built-in Vietnamese chat shorthand ("ntn" -> "như thế nào"). Words the
/// user already maps in their own replacement dictionary keep their own rule.
/// The keyboard only offers the expansion as a tap-able suggestion.
enum ChatShorthand {
    /// Lowercase shorthand -> expansion. Ambiguous short forms (k, r, bt, ck,
    /// vk, nc, nt, kh...) are intentionally left out.
    static let expansions: [String: String] = [
        "vs": "với",
        "ntn": "như thế nào",
        "bn": "bao nhiêu",
        "trc": "trước",
        "sn": "sinh nhật",
        "mn": "mọi người",
        "cx": "cũng",
        "đc": "được",
        "hnay": "hôm nay",
        "bjo": "bây giờ",
        "bh": "bao giờ",
        "ngta": "người ta",
        "kq": "kết quả",
        "ae": "anh em",
        "tks": "cảm ơn",
        "thks": "cảm ơn",
        "đt": "điện thoại",
        "nma": "nhưng mà",
        "hok": "không",
        "j": "gì",
        "z": "vậy",
        "lm": "làm",
        "ns": "nói",
        "đg": "đang",
        "dg": "đang",
        "ng": "người",
        "ob": "ông bà",
        "ctrinh": "chương trình"
    ]

    /// Expansion for a word as typed, keeping a leading capital letter.
    /// Returns nil for words that are not shorthand, or are typed in an odd
    /// mix of upper and lower case.
    static func expansion(for word: String) -> String? {
        guard !word.isEmpty, word.count <= 6 else { return nil }
        let lower = word.lowercased().precomposedStringWithCanonicalMapping
        guard let base = expansions[lower] else { return nil }
        if word == word.lowercased() { return base }
        let rest = word.dropFirst()
        if word.first?.isUppercase == true, String(rest) == rest.lowercased() {
            return base.prefix(1).uppercased() + base.dropFirst()
        }
        return nil
    }
}
