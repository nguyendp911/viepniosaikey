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
    static var allowCloudAI: Bool {
        get { defaults.bool(forKey: prefix + "allowCloudAI") }
        set { defaults.set(newValue, forKey: prefix + "allowCloudAI") }
    }
    static var savedPhrases: [String] {
        get { defaults.stringArray(forKey: prefix + "phrases") ?? ["Xin chào, mình có thể hỗ trợ gì cho bạn?", "Cảm ơn bạn đã liên hệ!", "Mình sẽ phản hồi bạn sớm nhé."] }
        set { defaults.set(Array(newValue.prefix(30)), forKey: prefix + "phrases") }
    }
}
