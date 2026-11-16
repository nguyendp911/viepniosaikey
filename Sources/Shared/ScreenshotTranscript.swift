import Foundation

/// Turns the text found in a chat screenshot (position of every line, from
/// on-device OCR) into a labelled conversation, and matches a chat title to
/// saved profiles. Pure logic: nothing here reads the screen or the network.
enum ScreenshotTranscript {
    /// One recognised line. Coordinates are normalised (0...1) and `midY`
    /// counts from the bottom, like Vision's bounding boxes.
    struct Line: Equatable {
        let text: String
        let minX: Double
        let maxX: Double
        let midY: Double
    }

    struct Message: Equatable {
        /// true: written by the user (right-hand bubble), false: by the other person.
        let isMine: Bool
        let text: String
    }

    // MARK: Text helpers

    /// Lower case, no accents, symbols and emoji replaced by single spaces.
    static func looseKey(_ text: String) -> String {
        var folded = text.lowercased()
            .folding(options: [.diacriticInsensitive], locale: Locale(identifier: "vi_VN"))
        folded = folded.replacingOccurrences(of: "đ", with: "d")
        var out = ""
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
        return out.trimmingCharacters(in: .whitespaces)
    }

    /// Clock times, dates, read receipts and other interface text.
    static func isNoise(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return true }
        if trimmed.count == 1, let only = trimmed.first, !only.isLetter, !only.isNumber { return true }
        let key = looseKey(trimmed)
        if key.isEmpty { return true }
        if key == "aa" { return true }
        let patterns = [
            // Read receipts and day separators, alone or followed by a time.
            #"^(da xem|da gui|da nhan|da doc|da chuyen|seen|delivered|sent|typing|hom nay|hom qua|today|yesterday|dang hoat dong|vua truy cap)( \d{1,2}( \d{2})?( ?(sa|ch|am|pm))?)?$"#,
            #"^\d{1,2}[:h.]\d{2}( ?(sa|ch|am|pm))?$"#,
            #"^\d{1,2} \d{2}( ?(sa|ch|am|pm))?$"#,
            #"^\d{1,2} \d{1,2}( \d{2,4})?$"#,
            #"^(thu (hai|ba|tu|nam|sau|bay)|chu nhat|cn|t[2-7]) .*\d{1,2} \d{2}"#
        ]
        for pattern in patterns where key.range(of: pattern, options: .regularExpression) != nil {
            return true
        }
        return false
    }

    // MARK: Conversation

    /// Messages from top to bottom. A right-hand bubble is the user's, a
    /// left-hand one the other person's; the header and the input bar are
    /// ignored.
    static func messages(from lines: [Line]) -> [Message] {
        let body = lines
            .filter { $0.midY > 0.10 && $0.midY < 0.88 && !isNoise($0.text) }
            .sorted { $0.midY > $1.midY }
        var groups: [[Line]] = []
        for line in body {
            if let group = groups.last, let previous = group.last,
               previous.midY - line.midY < 0.045,
               abs(line.minX - group[0].minX) < 0.045 {
                groups[groups.count - 1].append(line)
            } else {
                groups.append([line])
            }
        }
        var result: [Message] = []
        for group in groups {
            var minX = 1.0
            var maxX = 0.0
            for line in group {
                minX = min(minX, line.minX)
                maxX = max(maxX, line.maxX)
            }
            let rightMargin = 1 - maxX
            // Text that ends near the right edge and starts well away from the
            // left one is a right-hand bubble.
            let mine = rightMargin < 0.14 && minX > rightMargin + 0.08
            let text = group.map { $0.text }.joined(separator: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty { result.append(Message(isMine: mine, text: text)) }
        }
        return result
    }

    static let titleLabel = "Người trò chuyện:"
    static let targetLabel = "Tin nhắn cần trả lời:"

    /// A labelled transcript for the AI, or nil when there is nothing to read.
    static func transcript(personName: String?, messages: [Message],
                           maxMessages: Int = 14) -> String? {
        let recent = Array(messages.suffix(maxMessages))
        guard !recent.isEmpty else { return nil }
        var rows: [String] = []
        if let name = personName?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
            rows.append(titleLabel + " " + name)
        }
        rows.append("Hội thoại trong ảnh chụp (Tôi = người dùng, Người ấy = người nhận):")
        for message in recent {
            rows.append((message.isMine ? "Tôi: " : "Người ấy: ") + message.text)
        }
        if let target = recent.last(where: { !$0.isMine }) {
            rows.append(targetLabel + " " + target.text)
        }
        return rows.joined(separator: "\n")
    }

    /// The last message of the other person in a transcript, or the whole
    /// text when it is not a transcript.
    static func focusMessage(_ text: String) -> String {
        let rows = text.components(separatedBy: .newlines)
        if let target = rows.last(where: { $0.hasPrefix(targetLabel) }) {
            return String(target.dropFirst(targetLabel.count))
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let other = rows.last(where: { $0.hasPrefix("Người ấy:") }) {
            return String(other.dropFirst("Người ấy:".count))
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return text
    }

    // MARK: Chat title and profiles

    /// Indices of the saved names that fit a chat title. An exact match (ignoring
    /// accents, case, emoji and spacing) wins. Otherwise a name that appears as
    /// whole words in the title, or a title inside a longer saved name, counts
    /// ("Mai Linh ❤️" or "Mai" for the profile "Mai Linh"). Names shorter than
    /// three letters only ever match exactly.
    static func titleMatches(title: String, names: [String]) -> [Int] {
        let key = looseKey(title)
        guard key.count >= 2 else { return [] }
        let keys = names.map { looseKey($0) }
        var exact: [Int] = []
        for (index, name) in keys.enumerated() where name == key { exact.append(index) }
        if !exact.isEmpty { return exact }
        var loose: [Int] = []
        let paddedTitle = " " + key + " "
        for (index, name) in keys.enumerated() where name.count >= 3 || key.count >= 3 {
            guard !name.isEmpty else { continue }
            let paddedName = " " + name + " "
            let nameInTitle = name.count >= 3 && paddedTitle.contains(paddedName)
            let titleInName = key.count >= 3 && paddedName.contains(paddedTitle)
            if nameInTitle || titleInName { loose.append(index) }
        }
        return loose
    }
}
