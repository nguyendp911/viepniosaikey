import Foundation

enum KeyboardSettings {
    static let groupID = "group.com.viepn.aikey"
    private static let prefix = "viepnaikey."
    static var defaults: UserDefaults {
        UserDefaults(suiteName: groupID) ?? .standard
    }
    static var apiURL: String {
        get { defaults.string(forKey: prefix + "apiURL") ?? "" }
        set { defaults.set(newValue, forKey: prefix + "apiURL") }
    }
    // BYOK key shared with our own keyboard extension through App Group.
    // This is stored in app-container preferences, not Keychain. For stronger
    // protection, a future version should use a shared Keychain access group.
    static var provider: String {
        get { defaults.string(forKey: prefix + "provider") ?? "gemini" }
        set { defaults.set(newValue == "openai" ? "openai" : "gemini", forKey: prefix + "provider") }
    }
    static var openAIAPIKey: String {
        get { defaults.string(forKey: prefix + "openAIAPIKey") ?? "" }
        set { defaults.set(newValue.trimmingCharacters(in: .whitespacesAndNewlines), forKey: prefix + "openAIAPIKey") }
    }
    static var openAIModel: String {
        get { defaults.string(forKey: prefix + "openAIModel") ?? "gpt-4o-mini" }
        set { defaults.set(newValue.trimmingCharacters(in: .whitespacesAndNewlines), forKey: prefix + "openAIModel") }
    }
    static var geminiAPIKey: String {
        get { defaults.string(forKey: prefix + "geminiAPIKey") ?? "" }
        set { defaults.set(newValue.trimmingCharacters(in: .whitespacesAndNewlines), forKey: prefix + "geminiAPIKey") }
    }
    static var geminiModel: String {
        get {
            let stored = defaults.string(forKey: prefix + "geminiModel") ?? ""
            // Upgrade the old hard-coded default without overriding models chosen later.
            let migrated = defaults.bool(forKey: prefix + "geminiModelMigrationV3")
            if !migrated {
                defaults.set(true, forKey: prefix + "geminiModelMigrationV3")
                if stored.isEmpty || stored == "gemini-2.5-flash" {
                    defaults.set("gemini-3.8-flash", forKey: prefix + "geminiModel")
                    return "gemini-3.8-flash"
                }
            }
            return stored.isEmpty ? "gemini-3.8-flash" : stored
        }
        set { defaults.set(newValue, forKey: prefix + "geminiModel") }
    }
    static var allowCloudAI: Bool {
        get { defaults.bool(forKey: prefix + "allowCloudAI") }
        set { defaults.set(newValue, forKey: prefix + "allowCloudAI") }
    }
    static var coupleEnabled: Bool {
        get { defaults.object(forKey: prefix + "coupleEnabled") as? Bool ?? false }
        set { defaults.set(newValue, forKey: prefix + "coupleEnabled") }
    }
    static var coupleStyle: String {
        get { defaults.string(forKey: prefix + "coupleStyle") ?? "auto" }
        set {
            let permitted = CoupleStyleCatalog.styles.contains { $0.id == newValue }
            defaults.set(permitted ? newValue : "auto", forKey: prefix + "coupleStyle")
        }
    }
    static var coupleStage: String {
        get { defaults.string(forKey: prefix + "coupleStage") ?? "Đang yêu" }
        set {
            let choices = ["Mới quen", "Đang tìm hiểu", "Đang yêu", "Yêu xa", "Đã kết hôn"]
            defaults.set(choices.contains(newValue) ? newValue : "Đang yêu", forKey: prefix + "coupleStage")
        }
    }
    static var coupleAddress: String {
        get { defaults.string(forKey: prefix + "coupleAddress") ?? "anh/em" }
        set {
            let choices = ["anh/em", "em/anh", "mình/cậu", "tớ/cậu", "bạn/mình"]
            defaults.set(choices.contains(newValue) ? newValue : "anh/em", forKey: prefix + "coupleAddress")
        }
    }
    static var emojiEnabled: Bool {
        get { defaults.object(forKey: prefix + "emojiEnabled") as? Bool ?? true }
        set { defaults.set(newValue, forKey: prefix + "emojiEnabled") }
    }
    static var telexEnabled: Bool {
        get { defaults.object(forKey: prefix + "telexEnabled") as? Bool ?? true }
        set { defaults.set(newValue, forKey: prefix + "telexEnabled") }
    }
    static var typingMode: String {
        get { defaults.string(forKey: prefix + "typingMode") ?? "telex" }
        set { defaults.set(["telex", "vni", "off"].contains(newValue) ? newValue : "telex", forKey: prefix + "typingMode") }
    }
    static var theme: String {
        get { defaults.string(forKey: prefix + "theme") ?? "system" }
        set { defaults.set(["system", "midnight", "ocean", "rose", "lavender", "mint", "sunset", "graphite", "sakura", "forest", "sand", "aurora"].contains(newValue) ? newValue : "system", forKey: prefix + "theme") }
    }
    static var autoCapitalize: Bool {
        get { defaults.object(forKey: prefix + "autoCapitalize") as? Bool ?? true }
        set { defaults.set(newValue, forKey: prefix + "autoCapitalize") }
    }
    static var hapticEnabled: Bool {
        get { defaults.object(forKey: prefix + "hapticEnabled") as? Bool ?? true }
        set { defaults.set(newValue, forKey: prefix + "hapticEnabled") }
    }
    static var preferredTone: String {
        get { defaults.string(forKey: prefix + "preferredTone") ?? "Tự nhiên" }
        set { defaults.set(newValue, forKey: prefix + "preferredTone") }
    }
    static var preferredLength: String {
        get { defaults.string(forKey: prefix + "preferredLength") ?? "Ngắn" }
        set { defaults.set(newValue, forKey: prefix + "preferredLength") }
    }
    static var fallbackModel: String {
        get { defaults.string(forKey: prefix + "fallbackModel") ?? "" }
        set { defaults.set(newValue.trimmingCharacters(in: .whitespacesAndNewlines), forKey: prefix + "fallbackModel") }
    }
    static var replacementDictionary: [String: String] {
        get { defaults.dictionary(forKey: prefix + "replacementDictionary") as? [String: String] ?? ["ko": "không", "dc": "được", "mk": "mình"] }
        set { defaults.set(Dictionary(uniqueKeysWithValues: Array(newValue.prefix(100)).map { ($0.key, $0.value) }), forKey: prefix + "replacementDictionary") }
    }
    static var favoriteReplies: [String] {
        get { defaults.stringArray(forKey: prefix + "favoriteReplies") ?? [] }
        set { defaults.set(Array(newValue.prefix(50)), forKey: prefix + "favoriteReplies") }
    }
    static var translationLanguage: String {
        get { defaults.string(forKey: prefix + "translationLanguage") ?? "English" }
        set { defaults.set(newValue, forKey: prefix + "translationLanguage") }
    }
    static var savedPhrases: [String] {
        get { defaults.stringArray(forKey: prefix + "phrases") ?? ["Xin chào, mình có thể hỗ trợ gì cho bạn?", "Cảm ơn bạn đã liên hệ!", "Mình sẽ phản hồi bạn sớm nhé."] }
        set { defaults.set(Array(newValue.prefix(30)), forKey: prefix + "phrases") }
    }
}
