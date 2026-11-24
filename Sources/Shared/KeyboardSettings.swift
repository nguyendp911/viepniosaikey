import Foundation
#if os(iOS)
import Security
#endif

enum KeyboardSettings {
    static let groupID = "group.com.viepn.aikey"
    static let prefix = "viepnaikey."
    // Created once: building a UserDefaults(suiteName:) on every access is
    // expensive and was hit on every keystroke (textDidChange, space, layout).
    static let defaults: UserDefaults = UserDefaults(suiteName: groupID) ?? .standard
}
