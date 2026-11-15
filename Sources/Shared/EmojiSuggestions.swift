import Foundation

/// Offline emoji suggestions for the word the user just finished
/// ("nhớ em" -> 🥺 ❤️). Tables are keyed by accent-folded words so the
/// suggestion works whether or not the text has diacritics. Suggestions are
/// only offered after a tap-able strip chip; nothing is inserted automatically.
enum EmojiSuggestions {
    /// Lowercase, accent-free form used as the table key ("Nhớ" -> "nho").
    static func fold(_ text: String) -> String {
        text.lowercased()
            .folding(options: [.diacriticInsensitive], locale: Locale(identifier: "vi_VN"))
            .replacingOccurrences(of: "đ", with: "d")
    }

    /// Words that signal illness, loss or similar. Emoji would be tone-deaf,
    /// so no suggestion is made when one appears in the last few words.
    private static let sensitive: Set<String> = [
        "benh", "om", "dau", "chet", "mat", "tang", "nan", "vien", "tu", "khoc"
    ]

    /// At most `limit` emoji for the end of `words` (lowercased words, last =
    /// the word just completed). Longest phrase match wins.
    static func suggest(afterWords words: [String], limit: Int = 2) -> [String] {
        guard limit > 0, !words.isEmpty else { return [] }
        let folded = words.suffix(3).map { fold($0) }
        for word in folded where sensitive.contains(word) { return [] }
        var results: [String] = []
        func add(_ list: [String]?) {
            guard let list = list else { return }
            for emoji in list where !results.contains(emoji) { results.append(emoji) }
        }
        if folded.count >= 2 {
            add(phrases[folded[folded.count - 2] + " " + folded[folded.count - 1]])
        }
        if let last = folded.last { add(singles[last]) }
        return Array(results.prefix(limit))
    }

    /// Two-word phrases (accent-folded).
    static let phrases: [String: [String]] = [
        "ngu ngon": ["🌙", "😴"],
        "chuc ngu": ["🌙", "😴"],
        "cam on": ["🙏", "😊"],
        "xin loi": ["🙏", "🥺"],
        "chuc mung": ["🎉", "🥳"],
        "sinh nhat": ["🎂", "🎁"],
        "co len": ["💪", "🔥"],
        "tam biet": ["👋", "😊"],
        "hen gap": ["👋", "😊"],
        "gap lai": ["👋", "😊"],
        "nam moi": ["🎆", "🥳"],
        "ve nha": ["🏠", "😊"],
        "o nha": ["🏠", "😊"],
        "den nha": ["🏠", "😊"],
        "bong da": ["⚽", "🏟️"],
        "du lich": ["✈️", "🏖️"],
        "may bay": ["✈️", "🛫"],
        "di bien": ["🏖️", "🌊"],
        "bai tap": ["📚", "✏️"],
        "cong viec": ["💼", "💪"],
        "yeu em": ["❤️", "😘"],
        "yeu anh": ["❤️", "😘"],
        "nho em": ["🥺", "❤️"],
        "nho anh": ["🥺", "❤️"],
        "thuong em": ["🥰", "❤️"],
        "thuong anh": ["🥰", "❤️"],
        "em yeu": ["❤️", "😘"],
        "anh yeu": ["❤️", "😘"],
        "dang yeu": ["🥰", "❤️"],
        "ca phe": ["☕", "😋"],
        "an com": ["🍚", "😋"],
        "an sang": ["🥖", "😋"],
        "an toi": ["🍽️", "😋"],
        "an trua": ["🍱", "😋"],
        "tra sua": ["🧋", "😋"],
        "con meo": ["🐱", "😻"],
        "con cho": ["🐶", "🐕"]
    ]

    /// Single words (accent-folded). Ambiguous syllables are left out on
    /// purpose; a wrong emoji is worse than none.
    static let singles: [String: [String]] = [
        "nho": ["🥺", "❤️"],
        "yeu": ["❤️", "😘"],
        "thuong": ["🥰", "❤️"],
        "ngu": ["😴", "💤"],
        "ngon": ["😋", "👍"],
        "vui": ["😄", "🎉"],
        "buon": ["😢", "🥺"],
        "met": ["😩", "🥱"],
        "com": ["🍚", "😋"],
        "pho": ["🍜", "😋"],
        "bun": ["🍜", "😋"],
        "cafe": ["☕", "😋"],
        "caphe": ["☕", "😋"],
        "coffee": ["☕", "😋"],
        "bia": ["🍺", "🍻"],
        "nong": ["🥵", "☀️"],
        "dep": ["😍", "✨"],
        "xinh": ["😍", "💖"],
        "haha": ["😂", "🤣"],
        "hihi": ["😆", "🥰"],
        "hehe": ["😄", "😏"],
        "ok": ["👍", "😊"],
        "oke": ["👍", "😊"],
        "okie": ["👍", "😊"],
        "tuyet": ["🤩", "👍"],
        "gioi": ["👏", "💪"],
        "chao": ["👋", "😊"],
        "khuya": ["🌙", "😴"],
        "phim": ["🎬", "🍿"],
        "nhac": ["🎵", "🎧"],
        "game": ["🎮", "🕹️"],
        "hoc": ["📚", "✏️"],
        "viec": ["💼", "💪"],
        "xe": ["🚗", "🛵"],
        "noel": ["🎄", "🎅"],
        "tet": ["🧧", "🎆"],
        "meo": ["🐱", "😻"],
        "cuoi": ["😄", "😂"],
        "sop": ["😨"],
        "gian": ["😠", "😤"],
        "buc": ["😤", "😠"],
        "om": ["🤗", "🥰"],
        "hon": ["😘", "💋"],
        "qua": ["🎁"],
        "hoa": ["🌹", "💐"]
    ]
}
