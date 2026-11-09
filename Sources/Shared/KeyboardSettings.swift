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
    static var savedPhrases: [String] {
        get { defaults.stringArray(forKey: prefix + "phrases") ?? ["Xin chào, mình có thể hỗ trợ gì cho bạn?", "Cảm ơn bạn đã liên hệ!", "Mình sẽ phản hồi bạn sớm nhé."] }
        set { defaults.set(Array(newValue.prefix(30)), forKey: prefix + "phrases") }
    }
}
