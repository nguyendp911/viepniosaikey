import Foundation
#if os(iOS)
import Security
#endif

extension KeyboardSettings {
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

    static let availableThemes = [
        "system", "midnight", "ocean", "rose", "lavender", "mint",
        "sunset", "graphite", "sakura", "forest", "sand", "aurora",
        "amoled", "neon", "cyberpunk", "coffee", "ice", "gold",
        "titanium", "purewhite", "cyberneon", "rosegold", "jade", "heritage"
    ]

    static var theme: String {
        get { defaults.string(forKey: prefix + "theme") ?? "system" }
        set {
            defaults.set(availableThemes.contains(newValue) ? newValue : "system",
                         forKey: prefix + "theme")
        }
    }

    /// Core Animation-only keypress animation. No text, touches or key
    /// coordinates are recorded, and all effects are disabled in light mode.
    static let availableKeyEffects = ["off", "pop", "glow", "bounce", "flash"]
    static var keypressEffect: String {
        get { defaults.string(forKey: prefix + "keypressEffect") ?? "off" }
        set {
            defaults.set(availableKeyEffects.contains(newValue) ? newValue : "off",
                         forKey: prefix + "keypressEffect")
        }
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
}
