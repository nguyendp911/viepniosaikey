import Foundation

/// A date the user wants to remember (anniversary, birthday, other).
/// Stored on the device only.
struct SpecialDate: Codable, Equatable, Identifiable {
    var id: String
    var title: String
    /// "anniversary", "birthday" or "other".
    var kind: String
    var month: Int
    var day: Int
    /// Year of the first anniversary (the day the couple got together).
    /// Used to count days together; optional for other kinds.
    var year: Int?
}

enum SpecialDates {
    static let maxItems = 20

    static func decode(_ data: Data?) -> [SpecialDate] {
        guard let data, let list = try? JSONDecoder().decode([SpecialDate].self, from: data) else {
            return []
        }
        return Array(list.filter { isValid($0) }.prefix(maxItems))
    }

    static func encode(_ list: [SpecialDate]) -> Data? {
        try? JSONEncoder().encode(Array(list.filter { isValid($0) }.prefix(maxItems)))
    }

    static func isValid(_ item: SpecialDate) -> Bool {
        guard (1...12).contains(item.month), (1...31).contains(item.day) else { return false }
        let title = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return !title.isEmpty && title.count <= 40
    }

    private static func startOfDay(_ date: Date, _ calendar: Calendar) -> Date {
        calendar.startOfDay(for: date)
    }

    private static func isLeap(_ year: Int) -> Bool {
        (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
    }

    /// Days from today to the next time this date comes round (0 = today).
    static func daysUntilNext(_ item: SpecialDate, from now: Date,
                              calendar: Calendar = .current) -> Int {
        let today = startOfDay(now, calendar)
        let thisYear = calendar.component(.year, from: today)
        for year in [thisYear, thisYear + 1] {
            var day = item.day
            // 29 February falls on 28 February in years that are not leap years.
            if item.month == 2 && day == 29 && !isLeap(year) { day = 28 }
            var parts = DateComponents()
            parts.year = year
            parts.month = item.month
            parts.day = day
            guard let candidate = calendar.date(from: parts) else { continue }
            let distance = calendar.dateComponents([.day], from: today, to: startOfDay(candidate, calendar)).day ?? -1
            if distance >= 0 { return distance }
        }
        return 0
    }

    /// Dates happening within `days` days (including today), soonest first.
    static func upcoming(_ list: [SpecialDate], within days: Int, now: Date,
                         calendar: Calendar = .current) -> [(item: SpecialDate, daysAway: Int)] {
        var result: [(item: SpecialDate, daysAway: Int)] = []
        for item in list {
            let away = daysUntilNext(item, from: now, calendar: calendar)
            if away <= days { result.append((item: item, daysAway: away)) }
        }
        result.sort { (a: (item: SpecialDate, daysAway: Int), b: (item: SpecialDate, daysAway: Int)) -> Bool in
            if a.daysAway != b.daysAway { return a.daysAway < b.daysAway }
            return a.item.title < b.item.title
        }
        return result
    }

    /// Day number of the relationship: the first day counts as day 1.
    static func daysTogether(_ list: [SpecialDate], now: Date,
                             calendar: Calendar = .current) -> Int? {
        guard let start = list.first(where: { $0.kind == "anniversary" && $0.year != nil }),
              let year = start.year else { return nil }
        var parts = DateComponents()
        parts.year = year
        parts.month = start.month
        parts.day = start.day
        guard let began = calendar.date(from: parts) else { return nil }
        let diff = calendar.dateComponents([.day], from: startOfDay(began, calendar),
                                           to: startOfDay(now, calendar)).day ?? -1
        return diff >= 0 ? diff + 1 : nil
    }

    static func togetherMessage(days: Int) -> String {
        if days > 1 && (days % 100 == 0 || days % 365 == 0) {
            return "Hôm nay tròn \(days) ngày chúng mình bên nhau 💗"
        }
        return "Hôm nay là ngày thứ \(days) chúng mình bên nhau 💗"
    }

    /// A ready-to-send line for a date that is `daysAway` days from today.
    static func message(for item: SpecialDate, daysAway: Int, now: Date,
                        calendar: Calendar = .current) -> String {
        let title = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if daysAway > 0 {
            let icon = item.kind == "birthday" ? "🎂" : (item.kind == "anniversary" ? "💗" : "💫")
            let label = item.kind == "birthday" ? "sinh nhật " + title : title
            return "Còn \(daysAway) ngày nữa là \(label) rồi nè \(icon)"
        }
        switch item.kind {
        case "birthday":
            return "Chúc mừng sinh nhật \(title)! 🎂 Chúc luôn vui, khỏe và thật nhiều hạnh phúc."
        case "anniversary":
            if let year = item.year {
                let years = calendar.component(.year, from: now) - year
                if years > 0 {
                    return "Hôm nay là \(title), tròn \(years) năm rồi. Cảm ơn vì đã luôn bên nhau 💗"
                }
            }
            return "Hôm nay là \(title) của chúng mình 💗"
        default:
            return "Hôm nay là \(title) 💫"
        }
    }

    /// Short label for a menu row, e.g. "Sinh nhật Mai · hôm nay".
    static func menuTitle(for item: SpecialDate, daysAway: Int) -> String {
        let icon = item.kind == "birthday" ? "🎂" : (item.kind == "anniversary" ? "💗" : "💫")
        let name = item.kind == "birthday" ? "Sinh nhật " + item.title : item.title
        let when = daysAway == 0 ? "hôm nay" : (daysAway == 1 ? "ngày mai" : "còn \(daysAway) ngày")
        return icon + " " + name + " · " + when
    }
}
