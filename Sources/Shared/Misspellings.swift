import Foundation

/// Common Vietnamese spelling mistakes ("sắp sếp" -> "sắp xếp"). Only phrases
/// that are essentially never correct are listed, so a suggestion is rarely
/// wrong. Offered as a tap-able chip; nothing is changed automatically.
enum Misspellings {
    /// Lowercase NFC wrong phrase (1-2 words) -> correct phrase.
    static let corrections: [String: String] = [
        "sắp sếp": "sắp xếp",
        "xử dụng": "sử dụng",
        "sử lý": "xử lý",
        "bổ xung": "bổ sung",
        "bỏ xung": "bổ sung",
        "suất sắc": "xuất sắc",
        "xin lổi": "xin lỗi",
        "xin lõi": "xin lỗi",
        "lổi": "lỗi",
        "chia sẽ": "chia sẻ",
        "chân trọng": "trân trọng",
        "nghĩ ngơi": "nghỉ ngơi",
        "chỉnh chu": "chỉn chu",
        "cũng cố": "củng cố",
        "ngặc nhiên": "ngạc nhiên",
        "gữi": "gửi",
        "ngày lập tức": "ngay lập tức",
        "phát triễn": "phát triển",
        "triễn khai": "triển khai",
        "hiễn thị": "hiển thị",
        "hòan toàn": "hoàn toàn"
    ]

    /// A correction for the last one or two words typed (`rawWords` as typed,
    /// last = the word just finished). Capitalisation of the first word is kept.
    static func correction(forRawWords rawWords: [String])
        -> (original: String, corrected: String)? {
        var count = min(2, rawWords.count)
        while count >= 1 {
            let tail = Array(rawWords.suffix(count))
            var key = ""
            for (offset, word) in tail.enumerated() {
                if offset > 0 { key += " " }
                key += NextWordPredictor.normalize(word)
            }
            if let right = corrections[key], right != key {
                var corrected = right
                if tail.first?.first?.isUppercase == true {
                    corrected = right.prefix(1).uppercased() + right.dropFirst()
                }
                return (original: tail.joined(separator: " "), corrected: corrected)
            }
            count -= 1
        }
        return nil
    }
}
