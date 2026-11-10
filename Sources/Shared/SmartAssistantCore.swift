import Foundation

/// All saved conversation notes are user-controlled and stay on the device.
/// No automatic monitoring or copying of conversations in other applications.
struct ConversationNote: Codable, Identifiable, Equatable {
    var id: String
    var personaID: String
    var text: String
    var createdAt: Date
}

enum ConversationMemory {
    private static let key = "viepnaikey.conversationNotes.v1"
    private static var defaults: UserDefaults { KeyboardSettings.defaults }

    static var notes: [ConversationNote] {
        get {
            guard let raw = defaults.data(forKey: key),
                  let items = try? JSONDecoder().decode([ConversationNote].self, from: raw)
            else { return [] }
            return items
        }
        set {
            let clipped = Array(newValue.prefix(100))
            if let raw = try? JSONEncoder().encode(clipped) {
                defaults.set(raw, forKey: key)
            }
        }
    }

    static func save(_ text: String, for personaID: String) {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty, !personaID.isEmpty else { return }
        var items = notes
        items.insert(ConversationNote(id: UUID().uuidString, personaID: personaID,
                                      text: String(cleaned.prefix(500)), createdAt: Date()), at: 0)
        notes = items
    }

    static func forActivePersona() -> [ConversationNote] {
        guard !PersonaStore.activeID.isEmpty else { return [] }
        return notes.filter { $0.personaID == PersonaStore.activeID }
    }

    static func prompt() -> String {
        let memories = forActivePersona().prefix(8)
        guard !memories.isEmpty else { return "" }
        return """
        USER-APPROVED NOTES FOR THIS CONTACT (not verified facts):
        \(memories.map { "• " + $0.text }.joined(separator: "\n"))
        Use only if relevant. Do not assume notes are always current.
        """
    }
}

/// Conservative local checks before sending conversation text to a cloud provider.
/// Always display an explicit preview and let the user decide what to share.
enum MessageSafety {
    static func warnings(in text: String) -> [String] {
        var result: [String] = []
        let lower = text.lowercased()
        if lower.contains("otp") || lower.contains("mã xác minh")
            || lower.contains("mã đăng nhập") || lower.contains("verification code") {
            result.append("Có thể chứa mã xác thực/OTP")
        }
        if matches(#"\b(?:\d[ -]?){12,19}\b"#, text) {
            result.append("Có thể chứa số thẻ hoặc tài khoản dài")
        }
        if lower.contains("mật khẩu:") || lower.contains("password:")
            || lower.contains("api_key") || lower.contains("secret_key") {
            result.append("Có thể chứa mật khẩu hoặc khóa bí mật")
        }
        if matches(#"\b(?:0|\+84)\d{9,10}\b"#, text) {
            result.append("Có thể chứa số điện thoại")
        }
        return result
    }

    static func redacted(_ text: String) -> String {
        var result = text
        let patterns = [
            #"\b(?:\d[ -]?){12,19}\b"#,
            #"\b(?:0|\+84)\d{9,10}\b"#,
            #"(?im)\b(?:password|mật khẩu|api_key|secret_key)\s*[:=]\s*\S+"#,
            #"(?im)\b(?:otp|mã xác minh|mã đăng nhập)\s*[:=]?\s*\d{4,8}\b"#
        ]
        for pattern in patterns {
            result = result.replacingOccurrences(of: pattern, with: "[ĐÃ ẨN]",
                                                 options: .regularExpression)
        }
        return result
    }

    private static func matches(_ pattern: String, _ text: String) -> Bool {
        text.range(of: pattern, options: .regularExpression) != nil
    }
}

enum ToneInspector {
    static func suggestions(for text: String) -> [String] {
        let normal = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normal.isEmpty else { return [] }
        var issues: [String] = []
        if ["sao chưa", "làm ngay", "trả lời ngay", "im đi"].contains(where: normal.contains) {
            issues.append("Câu có thể gây áp lực; cân nhắc diễn đạt nhẹ nhàng hơn.")
        }
        if text.count < 12 && !text.contains("ạ") && !text.contains("nhé") {
            issues.append("Câu ngắn có thể hơi cộc tùy mối quan hệ.")
        }
        if text.filter({ $0 == "!" }).count >= 3 {
            issues.append("Nhiều dấu chấm than có thể khiến giọng điệu căng thẳng.")
        }
        return issues
    }
}

/// No keystrokes are logged. Only anonymized, bounded counters and timings
/// for user-triggered actions are stored locally until explicitly cleared.
enum KeyboardStability {
    private static let prefix = "viepnaikey.diagnostics."
    private static var defaults: UserDefaults { KeyboardSettings.defaults }
    static func note(_ action: String, durationMs: Double) {
        let valid = ["paste", "couple", "offline", "ai", "phrases", "typing"]
        guard valid.contains(action) else { return }
        let key = prefix + action
        let samples = min(1000, defaults.integer(forKey: key + ".count") + 1)
        let previous = defaults.double(forKey: key + ".averageMs")
        defaults.set(samples, forKey: key + ".count")
        defaults.set((previous * Double(samples - 1) + max(0, min(60000, durationMs)))
                     / Double(samples), forKey: key + ".averageMs")
    }
    static func report() -> String {
        ["paste", "couple", "offline", "ai", "phrases", "typing"].map { name in
            let count = defaults.integer(forKey: prefix + name + ".count")
            return "\(name): \(count) lần, trung bình \(Int(defaults.double(forKey: prefix + name + ".averageMs")))ms"
        }.joined(separator: "\n")
    }
    static func clear() {
        for name in ["paste", "couple", "offline", "ai", "phrases", "typing"] {
            defaults.removeObject(forKey: prefix + name + ".count")
            defaults.removeObject(forKey: prefix + name + ".averageMs")
        }
    }
}
