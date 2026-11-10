import Foundation

enum KeyboardSettings {
    static let groupID = "group.com.viepn.aikey"
    private static let prefix = "viepnaikey."
    // Created once: building a UserDefaults(suiteName:) on every access is
    // expensive and was hit on every keystroke (textDidChange, space, layout).
    static let defaults: UserDefaults = UserDefaults(suiteName: groupID) ?? .standard
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
    // User-specified recipient overrides guesses from short chat messages.
    // This is a global preference, never an inferred contact identity.
    static var recipientMode: String {
        get { defaults.string(forKey: prefix + "recipientMode") ?? "auto" }
        set {
            let valid = ReplyRecipient.allCases.contains { $0.rawValue == newValue }
            defaults.set(valid ? newValue : "auto", forKey: prefix + "recipientMode")
        }
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
    // Local-first typing controls. All are opt-in and stored in App Group.
    /// Automatic VN/EN, explicit Vietnamese Telex, or literal English.
    static var bilingualPreference: String {
        get { defaults.string(forKey: prefix + "bilingualPreference") ?? "auto" }
        set {
            defaults.set(["auto", "vi", "en"].contains(newValue) ? newValue : "auto",
                         forKey: prefix + "bilingualPreference")
        }
    }

    static var smartBilingual: Bool {
        get { defaults.object(forKey: prefix + "smartBilingual") as? Bool ?? true }
        set { defaults.set(newValue, forKey: prefix + "smartBilingual") }
    }
    static var predictionsEnabled: Bool {
        get { defaults.object(forKey: prefix + "predictionsEnabled") as? Bool ?? true }
        set { defaults.set(newValue, forKey: prefix + "predictionsEnabled") }
    }
    static var glideEnabled: Bool {
        get { defaults.bool(forKey: prefix + "glideEnabled") }
        set { defaults.set(newValue, forKey: prefix + "glideEnabled") }
    }
    static var autoLearnWords: Bool {
        get { defaults.bool(forKey: prefix + "autoLearnWords") }
        set { defaults.set(newValue, forKey: prefix + "autoLearnWords") }
    }
    static var learnedWords: [String: Int] {
        get { defaults.dictionary(forKey: prefix + "learnedWords") as? [String: Int] ?? [:] }
        set { defaults.set(Dictionary(uniqueKeysWithValues: Array(newValue.prefix(300))
                        .map { ($0.key, $0.value) }), forKey: prefix + "learnedWords") }
    }
    static var keyHeight: Int {
        get { defaults.object(forKey: prefix + "keyHeight") as? Int ?? 43 }
        set { defaults.set(min(49, max(40, newValue)), forKey: prefix + "keyHeight") }
    }
    static var keySpacing: Int {
        get { defaults.object(forKey: prefix + "keySpacing") as? Int ?? 6 }
        set { defaults.set(min(9, max(3, newValue)), forKey: prefix + "keySpacing") }
    }
    static var oneHandMode: String {
        get { defaults.string(forKey: prefix + "oneHandMode") ?? "off" }
        set { defaults.set(["off", "left", "right"].contains(newValue) ? newValue : "off",
                           forKey: prefix + "oneHandMode") }
    }
    static var textSnippets: [String: String] {
        get { defaults.dictionary(forKey: prefix + "textSnippets") as? [String: String]
                  ?? [";date": "{date}", ";time": "{time}"] }
        set { defaults.set(Dictionary(uniqueKeysWithValues: Array(newValue.prefix(70))
                         .map { (String($0.key.prefix(30)), String($0.value.prefix(500))) }),
                       forKey: prefix + "textSnippets") }
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
    // Some iOS keyboard extensions cannot use UIFeedbackGenerator reliably.
    // "vibrate" uses Apple's public AudioToolbox vibration as an alternative.
    static var hapticStyle: String {
        get { defaults.string(forKey: prefix + "hapticStyle") ?? "light" }
        set { defaults.set(["light", "vibrate"].contains(newValue) ? newValue : "vibrate",
                           forKey: prefix + "hapticStyle") }
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
