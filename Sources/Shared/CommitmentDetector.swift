import Foundation

/// A promise or task found in a conversation ("mai anh đón em lúc 7h").
struct Commitment: Codable, Identifiable, Equatable {
    var id: String
    var profileID: String
    /// true: the user promised it, false: the other person did.
    var mine: Bool
    var text: String
    var due: Date?
    /// The user has reviewed it in the app; only confirmed ones remind.
    var confirmed: Bool
    var done: Bool
    var created: Date
}

/// Finds likely promises with plain rules, on the device. It only suggests:
/// nothing is kept as a reminder until the user confirms it in the app.
enum CommitmentDetector {
    struct Found: Equatable {
        let mine: Bool
        let text: String
        let due: Date?
    }

    /// Verbs of doing something for or with someone, written with accents so
    /// that "mưa" (rain) is never read as "mua" (buy).
    private static let verbs = [
        "đón", "gặp", "gửi", "nộp", "gọi", "mang", "đưa", "trả", "mua", "hẹn",
        "chuyển khoản", "thanh toán", "liên hệ", "báo cáo", "ghé", "dọn", "nhắc"
    ]

    /// Words that put an action in the future even without a clock time.
    private static let futureMarkers = [
        "mai", "mốt", "tuần sau", "tuần tới", "tháng sau", "tháng tới", "cuối tuần",
        "lát nữa", "tối nay", "chiều nay", "sáng mai"
    ]

    private static func words(_ text: String) -> String {
        let lowered = text.lowercased().precomposedStringWithCanonicalMapping
        var out = " "
        var lastWasSpace = true
        for character in lowered {
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

    static func detect(_ messages: [(mine: Bool, text: String)], now: Date,
                       calendar: Calendar = .current) -> [Found] {
        var results: [Found] = []
        for message in messages {
            let text = message.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard text.count >= 6, text.count <= 400 else { continue }
            let key = words(text)
            guard verbs.contains(where: { key.contains(" " + $0 + " ") }) else { continue }
            let promised = key.contains(" hứa ")
            // A question is a request, not a promise.
            if text.hasSuffix("?") && !promised { continue }
            let match = DateTimePhrases.firstMatch(in: text, now: now, calendar: calendar)
            let inFuture = futureMarkers.contains(where: { key.contains(" " + $0 + " ") })
            guard match != nil || promised || inFuture else { continue }
            results.append(Found(mine: message.mine, text: String(text.prefix(140)), due: match?.date))
        }
        return results
    }

    /// Reads "Tôi: ..." and "Người ấy: ..." lines. Plain pasted text counts as
    /// the other person's messages.
    static func messages(fromTranscript text: String) -> [(mine: Bool, text: String)] {
        var out: [(mine: Bool, text: String)] = []
        let lines = text.components(separatedBy: .newlines)
        for line in lines {
            if line.hasPrefix("Tôi:") {
                out.append((mine: true, text: String(line.dropFirst(4))
                    .trimmingCharacters(in: .whitespacesAndNewlines)))
            } else if line.hasPrefix("Người ấy:") {
                out.append((mine: false, text: String(line.dropFirst("Người ấy:".count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)))
            }
        }
        if out.isEmpty {
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { out.append((mine: false, text: trimmed)) }
            }
        }
        return out
    }

    /// Drops ones that are already saved (same words, same side).
    static func newOnes(_ found: [Found], existing: [Commitment]) -> [Found] {
        var seen = Set<String>()
        for item in existing { seen.insert(key(mine: item.mine, text: item.text)) }
        var result: [Found] = []
        for item in found {
            let id = key(mine: item.mine, text: item.text)
            if seen.insert(id).inserted { result.append(item) }
        }
        return result
    }

    private static func key(mine: Bool, text: String) -> String {
        (mine ? "1|" : "0|") + words(text)
    }
}
