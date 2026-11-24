import Foundation
#if os(iOS)
import Security
#endif

extension KeyboardSettings {
    static var apiURL: String {
        get { defaults.string(forKey: prefix + "apiURL") ?? "" }
        set { defaults.set(newValue, forKey: prefix + "apiURL") }
    }
    // On iOS the existing application group is also a Keychain access group.
    // Never write new secrets to UserDefaults. Remove legacy values only after
    // successful migration, or an explicit delete. macOS script tests use an
    // isolated preference namespace rather than the device Keychain.
    static func secretQuery(_ name: String) -> [String: Any] {
        #if os(iOS)
        return [kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: "com.viepn.aikey.provider",
                kSecAttrAccount as String: name,
                kSecAttrAccessGroup as String: groupID]
        #else
        return [:]
        #endif
    }

    static func readSecret(_ name: String) -> String {
        #if os(iOS)
        var query = secretQuery(name)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecSuccess, let data = item as? Data,
           let value = String(data: data, encoding: .utf8) {
            defaults.removeObject(forKey: prefix + name)
            return value
        }
        if status == errSecItemNotFound,
           let old = defaults.string(forKey: prefix + name), !old.isEmpty,
           writeSecret(old, name: name) {
            return old
        }
        return ""
        #else
        return defaults.string(forKey: prefix + "testSecret." + name) ?? ""
        #endif
    }

    @discardableResult
    static func writeSecret(_ raw: String, name: String) -> Bool {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        #if os(iOS)
        let query = secretQuery(name)
        if value.isEmpty {
            defaults.removeObject(forKey: prefix + name)
            let status = SecItemDelete(query as CFDictionary)
            return status == errSecSuccess || status == errSecItemNotFound
        }
        let data = Data(value.utf8)
        var status = SecItemUpdate(query as CFDictionary,
            [kSecValueData as String: data] as CFDictionary)
        if status == errSecItemNotFound {
            var attributes = query
            attributes[kSecValueData as String] = data
            attributes[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            status = SecItemAdd(attributes as CFDictionary, nil)
        }
        guard status == errSecSuccess else { return false }
        defaults.removeObject(forKey: prefix + name)
        return true
        #else
        defaults.set(value, forKey: prefix + "testSecret." + name)
        return true
        #endif
    }

    @discardableResult
    static func saveProviderKey(_ value: String, provider: String) -> Bool {
        writeSecret(value, name: provider == "openai" ? "openAIAPIKey" : "geminiAPIKey")
    }
    static var provider: String {
        get { defaults.string(forKey: prefix + "provider") ?? "gemini" }
        set { defaults.set(newValue == "openai" ? "openai" : "gemini", forKey: prefix + "provider") }
    }
    static var openAIAPIKey: String {
        get { readSecret("openAIAPIKey") }
        set { writeSecret(newValue, name: "openAIAPIKey") }
    }
    static var openAIModel: String {
        get { defaults.string(forKey: prefix + "openAIModel") ?? "gpt-4o-mini" }
        set { defaults.set(newValue.trimmingCharacters(in: .whitespacesAndNewlines), forKey: prefix + "openAIModel") }
    }
    static var geminiAPIKey: String {
        get { readSecret("geminiAPIKey") }
        set { writeSecret(newValue, name: "geminiAPIKey") }
    }
    static var geminiModel: String {
        get {
            let stored = defaults.string(forKey: prefix + "geminiModel") ?? ""
            return stored.isEmpty ? "auto" : stored
        }
        set { defaults.set(newValue.trimmingCharacters(in: .whitespacesAndNewlines), forKey: prefix + "geminiModel") }
    }

    static var allowCloudAI: Bool {
        get { !privateTypingMode && defaults.bool(forKey: prefix + "allowCloudAI") }
        set { defaults.set(newValue, forKey: prefix + "allowCloudAI") }
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

    static var translationLanguage: String {
        get { defaults.string(forKey: prefix + "translationLanguage") ?? "English" }
        set { defaults.set(newValue, forKey: prefix + "translationLanguage") }
    }
}
