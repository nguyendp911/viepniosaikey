import Foundation
#if os(iOS)
import Security
#endif

extension KeyboardSettings {
    static var privateTypingMode: Bool {
        get { defaults.bool(forKey: prefix + "privateTypingMode") }
        set { defaults.set(newValue, forKey: prefix + "privateTypingMode") }
    }
    /// Optional privacy gate for viewing personal chat history in the
    /// containing app. Face ID/passcode unlock is a UI guard, not encryption.
    static var learnConversationStyleEnabled: Bool {
        // Only messages explicitly imported to a named profile can be used.
        get { defaults.object(forKey: prefix + "learnConversationStyleEnabled")
                as? Bool ?? true }
        set { defaults.set(newValue, forKey: prefix + "learnConversationStyleEnabled") }
    }

    static var historyScreenLockEnabled: Bool {
        get { defaults.bool(forKey: prefix + "historyScreenLockEnabled") }
        set { defaults.set(newValue, forKey: prefix + "historyScreenLockEnabled") }
    }
}
