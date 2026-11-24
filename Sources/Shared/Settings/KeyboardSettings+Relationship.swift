import Foundation
#if os(iOS)
import Security
#endif

extension KeyboardSettings {
    // User-specified recipient overrides guesses from short chat messages.
    // This is a global preference, never an inferred contact identity.
    static var recipientMode: String {
        get { defaults.string(forKey: prefix + "recipientMode") ?? "auto" }
        set {
            let valid = ReplyRecipient.allCases.contains { $0.rawValue == newValue }
            defaults.set(valid ? newValue : "auto", forKey: prefix + "recipientMode")
        }
    }
    static var coupleEnabled: Bool {
        get { defaults.object(forKey: prefix + "coupleEnabled") as? Bool ?? false }
        set { defaults.set(newValue, forKey: prefix + "coupleEnabled") }
    }
    static var coupleStyle: String {
        get { defaults.string(forKey: prefix + "coupleStyle") ?? "auto" }
        set {
            let permitted = CoupleStyleCatalog.styles.contains { $0.id == newValue }
            defaults.set(permitted ? newValue : "auto", forKey: prefix + "coupleStyle")
        }
    }
    static var coupleStage: String {
        get { defaults.string(forKey: prefix + "coupleStage") ?? "Đang yêu" }
        set {
            let choices = ["Mới quen", "Đang tìm hiểu", "Đang yêu", "Yêu xa", "Đã kết hôn"]
            defaults.set(choices.contains(newValue) ? newValue : "Đang yêu", forKey: prefix + "coupleStage")
        }
    }
    static var coupleAddress: String {
        get { defaults.string(forKey: prefix + "coupleAddress") ?? "anh/em" }
        set {
            let choices = ["anh/em", "em/anh", "mình/cậu", "tớ/cậu", "bạn/mình"]
            defaults.set(choices.contains(newValue) ? newValue : "anh/em", forKey: prefix + "coupleAddress")
        }
    }
}
