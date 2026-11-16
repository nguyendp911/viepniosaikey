import Foundation

/// Turns casual Vietnamese date and time phrases ("mai 7h", "t6 tuần sau",
/// "7h tối mai", "cuối tuần") into an exact date. Offered as a tap-able chip;
/// nothing is replaced automatically.
enum DateTimePhrases {
    struct Match: Equatable {
        /// The typed words, exactly as they appear before the caret.
        let original: String
        /// For example "7:00, Thứ Ba 17/11".
        let formatted: String
    }

    private static let fillers: Set<String> = ["luc", "vao", "khoang", "ngay"]
    private static let weekdayNames = ["", "Chủ Nhật", "Thứ Hai", "Thứ Ba", "Thứ Tư",
                                       "Thứ Năm", "Thứ Sáu", "Thứ Bảy"]

    /// Lower case without accents ("Thứ" -> "thu", "đêm" -> "dem").
    private static func fold(_ word: String) -> String {
        word.lowercased()
            .folding(options: [.diacriticInsensitive], locale: Locale(identifier: "vi_VN"))
            .replacingOccurrences(of: "đ", with: "d")
    }

    // MARK: Time of day

    /// "7h", "7h30", "19:30" -> (hour, minute); `nil` if it is not a time.
    private static func clock(_ token: String) -> (hour: Int, minute: Int)? {
        let chars = Array(token)
        var index = 0
        var hourText = ""
        while index < chars.count, chars[index].isNumber, hourText.count < 2 {
            hourText.append(chars[index])
            index += 1
        }
        guard !hourText.isEmpty, index < chars.count,
              chars[index] == "h" || chars[index] == ":",
              let hour = Int(hourText) else { return nil }
        index += 1
        var minuteText = ""
        while index < chars.count, chars[index].isNumber, minuteText.count < 2 {
            minuteText.append(chars[index])
            index += 1
        }
        guard index == chars.count else { return nil }
        let minute = minuteText.isEmpty ? 0 : (Int(minuteText) ?? 99)
        // "7h5" would be ambiguous; "7:5" is not a clock time.
        if minuteText.count == 1 { return nil }
        guard (0...23).contains(hour), (0...59).contains(minute) else { return nil }
        return (hour: hour, minute: minute)
    }

    private static func applyPeriod(_ hour: Int, _ period: String?) -> Int {
        guard let period else { return hour }
        switch period {
        case "trua": return hour >= 1 && hour <= 4 ? hour + 12 : hour
        case "chieu": return hour < 12 ? hour + 12 : hour
        case "toi": return hour < 12 ? hour + 12 : (hour == 12 ? 0 : hour)
        case "dem": return hour == 12 ? 0 : hour
        default: return hour
        }
    }

    // MARK: Phrase

    private struct Parsed {
        var dayOffset: Int?
        var weekday: Int?        // Calendar weekday: 1 = Sunday ... 7 = Saturday
        var weekend = false
        var weekShift: Int?      // 0 = this week, 1 = next week
        var hour: Int?
        var minute = 0
        var period: String?
    }

    private static func weekdayNumber(_ words: [String], at index: Int) -> (weekday: Int, used: Int)? {
        let word = words[index]
        if word.count == 2, word.first == "t", let digit = Int(String(word.last!)),
           (2...7).contains(digit) {
            return (weekday: digit, used: 1)
        }
        if word == "cn" { return (weekday: 1, used: 1) }
        if word == "chu", index + 1 < words.count, words[index + 1] == "nhat" {
            return (weekday: 1, used: 2)
        }
        if word == "thu", index + 1 < words.count {
            let next = words[index + 1]
            let names: [String: Int] = ["hai": 2, "ba": 3, "tu": 4, "nam": 5, "sau": 6, "bay": 7,
                                        "2": 2, "3": 3, "4": 4, "5": 5, "6": 6, "7": 7]
            if let value = names[next] { return (weekday: value, used: 2) }
        }
        return nil
    }

    private static func parse(_ rawWords: [String]) -> Parsed? {
        let words = rawWords.map { fold($0) }
        var result = Parsed()
        var index = 0
        while index < words.count {
            let word = words[index]
            if word.isEmpty { return nil }
            if fillers.contains(word) { index += 1; continue }
            if word == "hom", index + 1 < words.count, words[index + 1] == "nay" {
                guard result.dayOffset == nil, result.weekday == nil, !result.weekend else { return nil }
                result.dayOffset = 0
                index += 2
                continue
            }
            if word == "mai" || word == "mot" {
                guard result.dayOffset == nil, result.weekday == nil, !result.weekend else { return nil }
                result.dayOffset = word == "mai" ? 1 : 2
                index += 1
                continue
            }
            if word == "cuoi", index + 1 < words.count, words[index + 1] == "tuan" {
                guard result.dayOffset == nil, result.weekday == nil, !result.weekend else { return nil }
                result.weekend = true
                index += 2
                continue
            }
            if word == "tuan", index + 1 < words.count {
                let next = words[index + 1]
                guard result.weekShift == nil else { return nil }
                if next == "sau" || next == "toi" { result.weekShift = 1 }
                else if next == "nay" { result.weekShift = 0 }
                else { return nil }
                index += 2
                continue
            }
            if let day = weekdayNumber(words, at: index) {
                guard result.dayOffset == nil, result.weekday == nil, !result.weekend else { return nil }
                result.weekday = day.weekday
                index += day.used
                continue
            }
            if ["sang", "trua", "chieu", "toi", "dem"].contains(word) {
                guard result.period == nil else { return nil }
                result.period = word
                index += 1
                continue
            }
            if let time = clock(word) {
                guard result.hour == nil else { return nil }
                result.hour = time.hour
                result.minute = time.minute
                index += 1
                continue
            }
            // "7 gio" / "7 gio 30"
            if let hour = Int(word), (0...23).contains(hour), index + 1 < words.count,
               words[index + 1] == "gio" {
                guard result.hour == nil else { return nil }
                result.hour = hour
                index += 2
                if index < words.count, let minute = Int(words[index]), (0...59).contains(minute),
                   words[index].count == 2 {
                    result.minute = minute
                    index += 1
                }
                continue
            }
            return nil
        }
        return result
    }

    // MARK: Public

    /// Looks at the last words before the caret for a date/time phrase.
    /// Returns the longest phrase that parses and is worth a suggestion.
    static func suggestion(inTail text: String, now: Date,
                           calendar: Calendar = .current) -> Match? {
        let tail = String(text.suffix(80))
        let tokens = tail.split(separator: " ", omittingEmptySubsequences: false).map { String($0) }
        guard let last = tokens.last, !last.isEmpty else { return nil }
        var count = min(6, tokens.count)
        while count >= 1 {
            let slice = Array(tokens.suffix(count))
            if !slice.contains(where: { $0.isEmpty }),
               let parsed = parse(slice),
               let formatted = format(parsed, now: now, calendar: calendar) {
                return Match(original: slice.joined(separator: " "), formatted: formatted)
            }
            count -= 1
        }
        return nil
    }

    private static func format(_ parsed: Parsed, now: Date, calendar: Calendar) -> String? {
        // A bare "mai" or "7h" is ordinary text; require a clear date.
        let hasDay = parsed.weekday != nil || parsed.weekend
        let hasRelativeDay = parsed.dayOffset != nil
        guard hasDay || (hasRelativeDay && parsed.hour != nil) else { return nil }
        // "7h" must not be left with a dangling period or week word alone.
        if parsed.hour == nil && parsed.period != nil { return nil }

        let today = calendar.startOfDay(for: now)
        let todayWeekday = calendar.component(.weekday, from: today)
        var target: Date?
        if let offset = parsed.dayOffset {
            target = calendar.date(byAdding: .day, value: offset, to: today)
        } else {
            let wanted = parsed.weekend ? 7 : (parsed.weekday ?? 7)
            if let shift = parsed.weekShift {
                // Weeks start on Monday.
                let sinceMonday = (todayWeekday + 5) % 7
                let wantedFromMonday = (wanted + 5) % 7
                let delta = -sinceMonday + wantedFromMonday + 7 * shift
                target = calendar.date(byAdding: .day, value: delta, to: today)
            } else {
                var ahead = (wanted - todayWeekday + 7) % 7
                // "cuối tuần" on a Saturday means today; a named weekday that
                // is today means the same day next week.
                if ahead == 0 && !parsed.weekend { ahead = 7 }
                target = calendar.date(byAdding: .day, value: ahead, to: today)
            }
        }
        guard let date = target else { return nil }
        let weekday = calendar.component(.weekday, from: date)
        let day = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        let dateText = weekdayNames[weekday] + " " + String(day) + "/" + String(month)
        guard let rawHour = parsed.hour else { return dateText }
        let hour = applyPeriod(rawHour, parsed.period)
        guard (0...23).contains(hour) else { return nil }
        let time = String(hour) + ":" + (parsed.minute < 10 ? "0" : "") + String(parsed.minute)
        return time + ", " + dateText
    }
}
