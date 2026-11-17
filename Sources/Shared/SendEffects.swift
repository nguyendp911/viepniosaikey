import Foundation

/// Animations shown over the keyboard when a message is sent.
enum SendEffect: String, CaseIterable {
    case confetti, hearts, fireworks, balloons, snow, flowers, stars, luckyMoney

    var title: String {
        switch self {
        case .confetti: return "Pháo giấy"
        case .hearts: return "Trái tim bay"
        case .fireworks: return "Pháo hoa"
        case .balloons: return "Bóng bay"
        case .snow: return "Tuyết rơi"
        case .flowers: return "Hoa rơi"
        case .stars: return "Sao lấp lánh"
        case .luckyMoney: return "Lì xì"
        }
    }

    var icon: String {
        switch self {
        case .confetti: return "🎉"
        case .hearts: return "💖"
        case .fireworks: return "🎆"
        case .balloons: return "🎈"
        case .snow: return "❄️"
        case .flowers: return "🌸"
        case .stars: return "✨"
        case .luckyMoney: return "🧧"
        }
    }

    /// Shown in the app next to the title.
    var example: String {
        switch self {
        case .confetti: return "Chúc mừng, giỏi quá, thành công"
        case .hearts: return "Yêu, thương em, nhớ anh, love you"
        case .fireworks: return "Năm mới, giao thừa"
        case .balloons: return "Sinh nhật, happy birthday"
        case .snow: return "Giáng sinh, Noel"
        case .flowers: return "Cảm ơn, 8/3, 20/10"
        case .stars: return "Ngủ ngon, good night"
        case .luckyMoney: return "Tết, lì xì"
        }
    }
}

/// Chooses an effect for a message. Everything happens on the device.
enum SendEffects {
    static let modeOff = "off"
    static let modeAuto = "auto"       // only when the message calls for one
    static let modeRandom = "random"   // a different effect for every message

    private struct Rule {
        let effect: SendEffect
        /// Whole-word phrases without accents. The second value is the accented
        /// spelling that must be present when the text is written with accents,
        /// so that "yếu" or "thường" do not count as "yêu" or "thương".
        let phrases: [(String, String?)]
        let symbols: [String]
        let blockers: [String]
    }

    // The first matching rule wins, most specific first.
    private static let rules: [Rule] = [
        Rule(effect: .balloons,
             phrases: [("sinh nhat", nil), ("happy birthday", nil), ("hpbd", nil),
                       ("hbd", nil), ("birthday", nil)],
             symbols: ["🎂", "🎈", "🥳"], blockers: []),
        Rule(effect: .fireworks,
             phrases: [("nam moi", nil), ("giao thua", nil), ("happy new year", nil),
                       ("countdown", nil)],
             symbols: ["🎆", "🎇"], blockers: []),
        Rule(effect: .luckyMoney,
             phrases: [("li xi", nil), ("tet", "tết"), ("mung tuoi", nil)],
             symbols: ["🧧"], blockers: []),
        Rule(effect: .snow,
             phrases: [("giang sinh", nil), ("noel", nil), ("merry christmas", nil),
                       ("christmas", nil)],
             symbols: ["🎄", "⛄", "❄"], blockers: []),
        Rule(effect: .flowers,
             phrases: [("8 3", nil), ("20 10", nil), ("20 11", nil), ("cam on", nil),
                       ("thank you", nil), ("thanks", nil), ("tang hoa", nil),
                       ("bo hoa", nil)],
             symbols: ["🌸", "🌹", "🌷", "💐", "🌺"], blockers: []),
        Rule(effect: .stars,
             phrases: [("ngu ngon", nil), ("good night", nil), ("goodnight", nil),
                       ("di ngu", nil), ("ngu di", nil)],
             symbols: ["🌙", "😴", "🌟"], blockers: []),
        Rule(effect: .confetti,
             phrases: [("chuc mung", nil), ("congrats", nil), ("congratulations", nil),
                       ("thanh cong", nil), ("tuyet voi", nil), ("gioi qua", nil),
                       ("do dai hoc", nil), ("trung tuyen", nil)],
             symbols: ["🎉", "🎊"], blockers: []),
        Rule(effect: .hearts,
             phrases: [("yeu", "yêu"), ("thuong em", nil), ("thuong anh", nil),
                       ("thuong ban", nil), ("thuong con", nil), ("thuong me", nil),
                       ("thuong ba", nil), ("thuong nhieu", nil), ("thuong lam", nil),
                       ("nho em", nil), ("nho anh", nil), ("nho ban", nil),
                       ("nho lam", nil), ("i love you", nil), ("love you", nil),
                       ("love u", nil), ("ilu", nil), ("iu", nil)],
             symbols: ["❤", "<3", "😘", "🥰", "😍", "💕", "💖", "💗"],
             blockers: ["yeu cau", "yeu to", "yeu ot"])
    ]

    /// Lower case, no accents, letters and digits separated by single spaces.
    static func fold(_ text: String) -> String {
        let plain = text.lowercased().replacingOccurrences(of: "đ", with: "d")
            .folding(options: .diacriticInsensitive, locale: nil)
        var output = ""
        var lastWasSpace = true
        for character in plain {
            if character.isLetter || character.isNumber {
                output.append(character)
                lastWasSpace = false
            } else if !lastWasSpace {
                output.append(" ")
                lastWasSpace = true
            }
        }
        return output.trimmingCharacters(in: .whitespaces)
    }

    private static func hasAccents(_ text: String) -> Bool {
        let lowered = text.lowercased()
        return lowered.contains("đ")
            || lowered != lowered.folding(options: .diacriticInsensitive, locale: nil)
    }

    /// The effect a message calls for, or nil.
    static func matchingEffect(in text: String) -> SendEffect? {
        let folded = " " + fold(text) + " "
        let lowered = text.lowercased()
        let accented = hasAccents(text)
        for rule in rules {
            if rule.blockers.contains(where: { folded.contains(" " + $0 + " ") }) { continue }
            for (phrase, exact) in rule.phrases where folded.contains(" " + phrase + " ") {
                if let exact = exact, accented, !lowered.contains(exact) { continue }
                return rule.effect
            }
            if rule.symbols.contains(where: { text.range(of: $0, options: .literal) != nil }) {
                return rule.effect
            }
        }
        return nil
    }

    /// `mode` is "off", "auto", "random" or the raw name of one effect.
    static func effect(forMessage text: String, mode: String,
                       roll: Int = Int.random(in: 0..<10_000)) -> SendEffect? {
        switch mode {
        case modeOff: return nil
        case modeAuto: return matchingEffect(in: text)
        case modeRandom:
            let all = SendEffect.allCases
            return all[abs(roll) % all.count]
        default: return SendEffect(rawValue: mode)
        }
    }
}
