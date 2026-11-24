import Foundation

enum ClipboardVault {
    private static let legacyKey = "viepnaikey.explicitClipboardEntries"
    private static let key = "viepnaikey.clipboardEntriesV2"
    private static var defaults: UserDefaults { KeyboardSettings.defaults }
    private struct Entry: Codable {
        let text: String
        let savedAt: Date
    }
    private static let expiry: TimeInterval = 7 * 24 * 3600

    private static func store(_ entries: [Entry]) {
        if let encoded = try? JSONEncoder().encode(Array(entries.prefix(15))) {
            defaults.set(encoded, forKey: key)
            defaults.removeObject(forKey: legacyKey)
        }
    }
    private static func entries(now: Date = Date()) -> [Entry] {
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode([Entry].self, from: data) {
            let valid = decoded.filter { now.timeIntervalSince($0.savedAt) < expiry && $0.savedAt <= now }
            if valid.count != decoded.count { store(valid) }
            return valid
        }
        let old = defaults.stringArray(forKey: legacyKey) ?? []
        let migrated = old.prefix(15).map { Entry(text: $0, savedAt: now) }
        if !old.isEmpty { store(migrated) }
        return migrated
    }

    /// Explicitly saved text only; expiration is applied on access.
    static var items: [String] {
        get { entries().map(\.text) }
        set {
            let now = Date()
            let old = entries(now: now)
            let new = newValue.prefix(15).map { text in
                old.first { $0.text == text } ?? Entry(text: text, savedAt: now)
            }
            store(new)
        }
    }

    @discardableResult
    static func saveExplicitly(_ text: String) -> Bool {
        let value = String(text.prefix(1000)).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !KeyboardSettings.privateTypingMode, !value.isEmpty else { return false }
        let lowered = value.lowercased()
        guard !["otp", "password", "mật khẩu", "api_key", "secret_key", "mã xác minh"].contains(where: { lowered.contains($0) }),
              value.range(of: #"\b(?:\d[ -]?){12,19}\b"#, options: .regularExpression) == nil else { return false }
        var list = entries()
        list.removeAll { $0.text == value }
        list.insert(Entry(text: value, savedAt: Date()), at: 0)
        store(list)
        return true
    }

    static func clear() { store([]) }
}
