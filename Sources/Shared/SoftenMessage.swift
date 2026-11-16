import Foundation

/// Offers a gentler wording for phrases that tend to start arguments
/// ("lúc nào cũng", "kệ em"). Only a tap-able suggestion: nothing is changed
/// automatically, and serious statements are never touched.
enum SoftenMessage {
    private static let selfPronouns = ["anh", "em", "tôi", "mình", "tao"]
    private static let addresseePronouns = ["anh", "em", "bạn", "cậu"]

    /// Lowercase NFC phrase (1-3 words) -> softer wording.
    static let phrases: [String: String] = {
        var table: [String: String] = [
            "lúc nào cũng": "dạo này hay",
            "không bao giờ": "hiếm khi",
            "chẳng bao giờ": "hiếm khi",
            "im đi": "cho mình xin chút yên tĩnh nhé",
            "phiền quá": "mình hơi mệt một chút",
            "đừng làm phiền": "cho mình chút thời gian riêng nhé",
            "thôi khỏi": "để lúc khác mình nói tiếp nhé",
            "đủ rồi": "mình cần dừng lại một chút",
            "khỏi giải thích": "để mình bình tĩnh lại rồi nghe giải thích sau nhé",
            "nói nhiều quá": "mình muốn yên tĩnh một chút",
            "vô lý": "mình thấy chưa hợp lý lắm",
            "vô lí": "mình thấy chưa hợp lý lắm",
            "mặc kệ": "mình cần bình tĩnh một chút",
            "không quan tâm": "mình chưa muốn bàn chuyện này lúc này"
        ]
        for me in selfPronouns {
            table["kệ " + me] = me + " đang hơi buồn, cho " + me + " bình tĩnh một lát nhé"
        }
        for you in addresseePronouns {
            table["tùy " + you] = "mình cùng chọn nhé, mình muốn nghe ý " + you
        }
        return table
    }()

    /// A softer wording for the last one to three words typed (`rawWords` as
    /// typed, last = the word just finished).
    static func suggestion(forRawWords rawWords: [String])
        -> (original: String, softer: String)? {
        var count = min(3, rawWords.count)
        while count >= 1 {
            let tail = Array(rawWords.suffix(count))
            var key = ""
            for (offset, word) in tail.enumerated() {
                if offset > 0 { key += " " }
                key += NextWordPredictor.normalize(word)
            }
            if let softer = phrases[key] {
                var text = softer
                if tail.first?.first?.isUppercase == true {
                    text = softer.prefix(1).uppercased() + softer.dropFirst()
                }
                return (original: tail.joined(separator: " "), softer: text)
            }
            count -= 1
        }
        return nil
    }
}
