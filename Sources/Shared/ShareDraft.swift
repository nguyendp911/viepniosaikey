import Foundation

enum ShareDraft {
    private static let key = "viepnaikey.manualAssistantDraft"
    private static let group = "group.com.viepn.aikey"
    private static var defaults: UserDefaults? { UserDefaults(suiteName: group) }
    @discardableResult
    static func save(_ text: String) -> Bool {
        guard let defaults else { return false }
        defaults.set(String(text.prefix(3000)), forKey: key)
        return true
    }
    static var current: String { defaults?.string(forKey: key) ?? "" }
    static func clear() { defaults?.removeObject(forKey: key) }
}
