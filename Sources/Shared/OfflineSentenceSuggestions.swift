import Foundation

/// Small, deterministic phrase completions. No network, clipboard inspection,
/// conversation scraping, text persistence or AI provider calls.
enum OfflineSentenceSuggestions {
    private static let templates: [(trigger: String, sentence: String)] = [
        ("cam", "Cảm ơn bạn rất nhiều!"),
        ("chao", "Chào bạn, chúc bạn một ngày tốt lành!"),
        ("chieu", "Chiều nay bạn có rảnh không?"),
        ("hen", "Hẹn gặp bạn nhé!"),
        ("hom", "Hôm nay bạn thế nào?"),
        ("mai", "Mai mình trao đổi tiếp nhé!"),
        ("minh", "Mình sẽ phản hồi bạn sớm nhé."),
        ("nho", "Nhờ bạn kiểm tra giúp mình nhé."),
        ("xin", "Xin chào, mình có thể giúp gì cho bạn?"),
        ("toi", "Tôi sẽ kiểm tra và phản hồi sớm."),
        ("vui", "Vui lòng cho mình biết thêm thông tin nhé.")
    ]

    // Original curated local n-grams. Context is never stored or uploaded.
    private static let vi: [String: [String]] = [
        "xin": ["chào", "lỗi", "phép"], "xin chào": ["bạn", "anh", "chị"],
        "cảm": ["ơn", "thấy", "nhận"], "cảm ơn": ["bạn", "anh", "em"],
        "hôm": ["nay", "qua", "trước"], "hôm nay": ["bạn", "em", "mình"],
        "ngày": ["mai", "hôm", "mới"], "ngày mai": ["mình", "em", "anh"],
        "chúc": ["bạn", "em", "mừng"], "chúc bạn": ["vui", "một", "thành"],
        "anh": ["yêu", "nhớ", "đang"], "anh yêu": ["em", "thương"],
        "em": ["đang", "có", "ăn"], "em đang": ["làm", "ở", "đi"],
        "mình": ["sẽ", "đang", "có"], "mình sẽ": ["gửi", "kiểm", "liên"],
        "tôi": ["sẽ", "đã", "muốn"], "tôi sẽ": ["gửi", "kiểm", "phản"],
        "bạn": ["có", "đang", "muốn"], "bạn có": ["thể", "muốn", "rảnh"],
        "vui": ["lòng", "vẻ", "mừng"], "vui lòng": ["cho", "kiểm", "gửi"],
        "kiểm": ["tra", "soát"], "kiểm tra": ["lại", "giúp", "thông"],
        "ăn": ["cơm", "tối", "sáng"], "ăn cơm": ["chưa", "nhé", "rồi"],
        "ngủ": ["ngon", "sớm", "chưa"], "giữ": ["gìn", "sức", "liên"],
        "đi": ["làm", "chơi", "ngủ"], "đi làm": ["về", "chưa", "nhé"],
        "hẹn": ["gặp", "bạn", "lại"], "hẹn gặp": ["bạn", "lại", "em"],
        "rất": ["vui", "cảm", "mong"], "chưa": ["biết", "có", "được"],
        "không": ["có", "sao", "biết"], "được": ["rồi", "không", "ạ"],
        "có": ["thể", "gì", "không"], "cho": ["mình", "em", "anh"],
        "liên": ["hệ", "lạc"], "phản": ["hồi", "ánh"], "thông": ["tin", "báo"],
        "chào": ["bạn", "anh", "chị"], "buổi": ["sáng", "trưa", "tối"],
        "sức": ["khỏe", "mạnh"], "nhớ": ["em", "anh", "giữ"]
    ]
    private static let en: [String: [String]] = [
        "thank": ["you"], "thank you": ["for", "so", "very"],
        "good": ["morning", "night", "luck"], "how": ["are", "is", "can"],
        "how are": ["you"], "i": ["am", "will", "can"], "i am": ["sorry", "here", "ready"],
        "can": ["you", "we", "i"], "can you": ["help", "send", "check"],
        "see": ["you", "the"], "see you": ["soon", "later", "tomorrow"],
        "please": ["send", "check", "let"], "let me": ["know", "check", "see"],
        "have": ["a", "you", "been"], "have a": ["good", "great", "nice"]
    ]

    static func nextWords(after context: String, language: String = "auto", limit: Int = 3) -> [String] {
        guard limit > 0, context.last == " " else { return [] }
        let trimmed = String(context.suffix(80)).trimmingCharacters(in: .whitespaces)
        guard let last = trimmed.last, last.isLetter else { return [] }
        let fragment = trimmed.split(whereSeparator: { ".!?;:\n".contains($0) }).last ?? ""
        let words = fragment.lowercased().split(whereSeparator: { !$0.isLetter })
        guard let final = words.last else { return [] }
        let single = String(final)
        let pair = words.suffix(2).joined(separator: " ")
        let vietnamese = vi[pair] ?? vi[single] ?? []
        let english = en[pair] ?? en[single] ?? []
        let selected = language == "en" ? english : (language == "vi" ? vietnamese : (vietnamese.isEmpty ? english : vietnamese))
        return Array(selected.prefix(min(3, limit)))
    }

    /// A user-visible completion is offered only for an unambiguous, fully
    /// typed trigger. Prefix guesses cause accidental whole-sentence insertion.
    static func suggestions(for word: String, limit: Int = 2, tone: String = "Tự nhiên") -> [String] {
        guard (3...20).contains(word.count), limit > 0 else { return [] }
        let folded = word.lowercased()
            .folding(options: [.diacriticInsensitive], locale: Locale(identifier: "vi_VN"))
            .replacingOccurrences(of: "đ", with: "d")
        // Respect the selected writing tone without asking an online model
        // to analyze private conversation context during keypresses.
        if ["Lịch sự", "Trang trọng", "Chuyên nghiệp"].contains(tone) {
            let formal: [String: String] = [
                "cam": "Xin chân thành cảm ơn anh/chị!",
                "chao": "Xin chào anh/chị, rất vui được hỗ trợ!",
                "xin": "Xin chào anh/chị, tôi có thể hỗ trợ gì ạ?",
                "nho": "Kính nhờ anh/chị kiểm tra giúp ạ.",
                "toi": "Tôi sẽ kiểm tra và phản hồi sớm nhất có thể."
            ]
            if let phrase = formal[folded] { return [phrase] }
        }
        return Array(templates.filter { $0.trigger == folded }
            .prefix(min(limit, 3)).map { $0.sentence })
    }
}
