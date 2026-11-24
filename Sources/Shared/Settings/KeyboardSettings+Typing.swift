import Foundation
#if os(iOS)
import Security
#endif

extension KeyboardSettings {
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
    /// Lightweight typing mode avoids costly optional effects while keeping
    /// the underlying Telex/VNI engine and key layout unchanged.
    static var performanceMode: Bool {
        get { defaults.bool(forKey: prefix + "performanceMode") }
        set { defaults.set(newValue, forKey: prefix + "performanceMode") }
    }

    static var predictionsEnabled: Bool {
        get { defaults.object(forKey: prefix + "predictionsEnabled") as? Bool ?? true }
        set { defaults.set(newValue, forKey: prefix + "predictionsEnabled") }
    }
    /// Entirely on-device phrase suggestions, independently switchable.
    static var sentenceSuggestionsEnabled: Bool {
        get { defaults.object(forKey: prefix + "sentenceSuggestionsEnabled") as? Bool ?? true }
        set { defaults.set(newValue, forKey: prefix + "sentenceSuggestionsEnabled") }
    }
    static var glideEnabled: Bool {
        // Swipe typing is available by default; preserve an explicit opt-out
        // from existing users rather than forcing their setting back on.
        get { defaults.object(forKey: prefix + "glideEnabled") as? Bool ?? true }
        set { defaults.set(newValue, forKey: prefix + "glideEnabled") }
    }

    static var glideTrailEnabled: Bool {
        get { defaults.object(forKey: prefix + "glideTrailEnabled") as? Bool ?? true }
        set { defaults.set(newValue, forKey: prefix + "glideTrailEnabled") }
    }

    static var adaptiveTouchEnabled: Bool {
        get { defaults.object(forKey: prefix + "adaptiveTouchEnabled") as? Bool ?? true }
        set { defaults.set(newValue, forKey: prefix + "adaptiveTouchEnabled") }
    }

    static var typingMode: String {
        get { defaults.string(forKey: prefix + "typingMode") ?? "telex" }
        set { defaults.set(["telex", "vni", "off"].contains(newValue) ? newValue : "telex", forKey: prefix + "typingMode") }
    }

    static var autoCapitalize: Bool {
        get { defaults.object(forKey: prefix + "autoCapitalize") as? Bool ?? true }
        set { defaults.set(newValue, forKey: prefix + "autoCapitalize") }
    }
}
