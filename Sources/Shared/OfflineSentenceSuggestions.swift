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
