import Foundation

enum ToolbarPreferences {
    static let standard = ["paste", "couple", "ai", "offline", "phrases", "tools"]
    static func title(_ id: String) -> String {
        ["paste":"Dán", "couple":"Couple", "ai":"AI", "offline":"Offline", "phrases":"Mẫu", "tools":"Công cụ"][id] ?? id
    }
    static var order: [String] {
        get {
            let saved = KeyboardSettings.defaults.stringArray(forKey: "viepnaikey.toolbarOrder") ?? standard
            return saved.count == standard.count && Set(saved) == Set(standard) ? saved : standard
        }
        set {
            if newValue.count == standard.count && Set(newValue) == Set(standard) {
                KeyboardSettings.defaults.set(newValue, forKey: "viepnaikey.toolbarOrder")
            }
        }
    }
}
