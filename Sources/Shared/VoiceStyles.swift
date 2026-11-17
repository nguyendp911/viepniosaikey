import Foundation

/// Rewrites a sentence in a regional or Gen Z voice with word lists only
/// (offline, instant). It changes common words, keeps everything else and
/// keeps capital letters. It is a light, playful touch, not a translation.
enum VoiceStyle: String, CaseIterable {
    case north, south, central, genZ

    var title: String {
        switch self {
        case .north: return "Giọng Bắc"
        case .south: return "Giọng Nam"
        case .central: return "Giọng Trung"
        case .genZ: return "Giọng Gen Z"
        }
    }
}

enum VoiceStyles {
    // Keys are lower case. Two-word keys are tried before one-word keys.
    private static let south: [String: String] = [
        "không": "hông", "tôi": "tui", "mẹ": "má", "bố": "ba", "quả": "trái", "thìa": "muỗng",
        "vậy": "dzậy", "nhé": "nghen", "nhỉ": "hen", "này": "nè", "anh ấy": "ảnh", "chị ấy": "chỉ",
        "cô ấy": "cổ", "ông ấy": "ổng", "bà ấy": "bả", "em ấy": "em nó", "thế nào": "sao",
        "đẹp quá": "đẹp quá trời"
    ]
    private static let north: [String: String] = [
        "hông": "không", "tui": "tôi", "má": "mẹ", "ba": "bố", "trái": "quả", "muỗng": "thìa",
        "dzậy": "vậy", "nghen": "nhé", "hen": "nhé", "nè": "này", "ảnh": "anh ấy", "ổng": "ông ấy",
        "bả": "bà ấy", "rứa": "vậy", "răng": "sao", "ni": "này", "nớ": "đó", "tê": "kia", "mô": "đâu"
    ]
    private static let central: [String: String] = [
        "vậy": "rứa", "sao": "răng", "thế nào": "răng", "này": "ni", "đây": "ni", "đó": "nớ",
        "ấy": "nớ", "kia": "tê", "đâu": "mô", "tôi": "tui", "nhé": "nghe", "bây giờ": "bi giờ"
    ]
    private static let genZ: [String: String] = [
        "không": "hông", "rất": "quá trời", "đẹp": "xinh xỉu", "ngon": "ngon xỉu", "mệt": "mệt xỉu",
        "thích": "mê", "tuyệt vời": "đỉnh của chóp", "buồn cười": "xỉu", "bạn bè": "hội bạn",
        "xin chào": "hello", "cảm ơn": "cảm ơn nha", "đúng": "chuẩn", "thật": "thiệt",
        "giỏi": "đỉnh", "chán": "chán xỉu", "xấu hổ": "quê xỉu", "nhớ": "nhớ xỉu"
    ]

    private static func table(_ style: VoiceStyle) -> [String: String] {
        switch style {
        case .north: return north
        case .south: return south
        case .central: return central
        case .genZ: return genZ
        }
    }

    /// Splits into words and the text between them, so nothing is lost.
    private static func pieces(_ text: String) -> [(text: String, isWord: Bool)] {
        var result: [(text: String, isWord: Bool)] = []
        var current = ""
        var currentIsWord = false
        for character in text {
            let isWord = character.isLetter || character.isNumber
            if current.isEmpty {
                current = String(character)
                currentIsWord = isWord
            } else if isWord == currentIsWord {
                current.append(character)
            } else {
                result.append((text: current, isWord: currentIsWord))
                current = String(character)
                currentIsWord = isWord
            }
        }
        if !current.isEmpty { result.append((text: current, isWord: currentIsWord)) }
        return result
    }

    private static func matchCase(_ replacement: String, like original: String) -> String {
        guard let first = original.first, first.isUppercase else { return replacement }
        return replacement.prefix(1).uppercased() + replacement.dropFirst()
    }

    static func apply(_ style: VoiceStyle, to text: String) -> String {
        let words = table(style)
        let parts = pieces(text.precomposedStringWithCanonicalMapping)
        var output = ""
        var index = 0
        while index < parts.count {
            let part = parts[index]
            guard part.isWord else {
                output += part.text
                index += 1
                continue
            }
            // Two words separated by a single space ("anh ấy", "thế nào").
            if index + 2 < parts.count, parts[index + 1].text == " ", parts[index + 2].isWord {
                let pair = (part.text + " " + parts[index + 2].text).lowercased()
                if let swap = words[pair] {
                    output += matchCase(swap, like: part.text)
                    index += 3
                    continue
                }
            }
            if let swap = words[part.text.lowercased()] {
                output += matchCase(swap, like: part.text)
            } else {
                output += part.text
            }
            index += 1
        }
        return output
    }
}
