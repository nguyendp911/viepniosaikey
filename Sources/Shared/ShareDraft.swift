import Foundation

enum ShareDraft {
    private static let key = "viepnaikey.manualAssistantDraft"
    static func save(_ text: String) {
        KeyboardSettings.defaults.set(String(text.prefix(3000)), forKey: key)
    }
    static var current: String {
        KeyboardSettings.defaults.string(forKey: key) ?? ""
    }
    static func clear() { KeyboardSettings.defaults.removeObject(forKey: key) }
}

