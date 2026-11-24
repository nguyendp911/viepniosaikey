import Foundation
#if os(iOS)
import Security
#endif

extension KeyboardSettings {
    // Optional touch-area expansion into the gap between neighboring keys.
    // Only the emoji chosen from the idle keyboard strip are counted.
    // Do not scan messages, clipboard or text typed in other apps.
    static var frequentlyUsedEmoji: [String: Int] {
        get {
            defaults.dictionary(forKey: prefix + "frequentlyUsedEmoji") as? [String: Int] ?? [:]
        }
        set {
            let bounded = newValue.sorted { $0.value > $1.value }.prefix(32)
            defaults.set(Dictionary(uniqueKeysWithValues: bounded.map {
                (String($0.key.prefix(12)), min(10000, max(0, $0.value)))
            }), forKey: prefix + "frequentlyUsedEmoji")
        }
    }

    static func recordEmojiSelection(_ emoji: String) {
        guard !privateTypingMode, !emoji.isEmpty, emoji.count <= 8 else { return }
        var counts = frequentlyUsedEmoji
        counts[emoji] = min(10000, (counts[emoji] ?? 0) + 1)
        frequentlyUsedEmoji = counts
    }

    /// Private local counts for explicitly accepted swipe candidates. No raw
    /// swipe path or touch coordinates are stored or uploaded.
    static var glideLearningEnabled: Bool {
        get { defaults.object(forKey: prefix + "glideLearningEnabled") as? Bool ?? true }
        set { defaults.set(newValue, forKey: prefix + "glideLearningEnabled") }
    }
    static var glideUsageCounts: [String: Int] {
        get { defaults.dictionary(forKey: prefix + "glideUsageCounts") as? [String: Int] ?? [:] }
        set {
            let bounded = newValue.sorted { $0.value > $1.value }.prefix(600)
            defaults.set(Dictionary(uniqueKeysWithValues: bounded.map {
                (String($0.key.prefix(90)), min(10000, max(0, $0.value)))
            }), forKey: prefix + "glideUsageCounts")
        }
    }
    static func recordGlideChoice(_ word: String) {
        guard glideLearningEnabled, !privateTypingMode else { return }
        let plain = word.lowercased()
            .folding(options: [.diacriticInsensitive], locale: Locale(identifier: "vi_VN"))
            .replacingOccurrences(of: "đ", with: "d")
        let key = plain + "|" + word.lowercased()
        var counts = glideUsageCounts
        counts[key] = min(10000, (counts[key] ?? 0) + 1)
        glideUsageCounts = counts
    }

    static var autoLearnWords: Bool {
        get { defaults.bool(forKey: prefix + "autoLearnWords") }
        set { defaults.set(newValue, forKey: prefix + "autoLearnWords") }
    }
    static var learnedWords: [String: Int] {
        get { defaults.dictionary(forKey: prefix + "learnedWords") as? [String: Int] ?? [:] }
        set {
            let bounded = newValue.filter { !$0.key.isEmpty && $0.key.count <= 90 && $0.value > 0 }
                .sorted { $0.value == $1.value ? $0.key < $1.key : $0.value > $1.value }
                .prefix(300)
            defaults.set(Dictionary(uniqueKeysWithValues: bounded.map { ($0.key, min(10000, $0.value)) }),
                         forKey: prefix + "learnedWords")
        }
    }
}
