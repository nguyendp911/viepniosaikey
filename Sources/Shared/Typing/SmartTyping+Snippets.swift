import Foundation

extension SmartTyping {
    static func expandSnippet(_ text: String, now: Date = Date(),
                              recipient: String? = nil) -> String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "vi_VN")
        fmt.dateFormat = "dd/MM/yyyy"
        let date = fmt.string(from: now)
        fmt.dateFormat = "HH:mm"
        let time = fmt.string(from: now)
        var result = text.replacingOccurrences(of: "{date}", with: date)
            .replacingOccurrences(of: "{time}", with: time)
        // Never guess the recipient from another app. Only an explicitly
        // selected profile can fill the recipient placeholder.
        if let recipient, !recipient.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            result = result.replacingOccurrences(of: "{recipient}",
                with: String(recipient.prefix(80)))
        }
        return result
    }
}
