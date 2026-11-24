import UIKit

struct KeyboardDesign: Codable {
    var canvas = "172033"
    var key = "35425A"
    var text = "FFFFFF"
    var modifier = "50617B"
    var opacity = 0.94
    var radius = 8.0
    var font = "rounded"
    var sound = false
    static var current: Self {
        get {
            guard let data = KeyboardSettings.defaults.data(forKey: "viepnaikey.customDesign"),
                  let decoded = try? JSONDecoder().decode(Self.self, from: data) else { return .init() }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) { KeyboardSettings.defaults.set(data, forKey: "viepnaikey.customDesign") }
        }
    }
    static func color(_ hex: String, fallback: UIColor = .white) -> UIColor {
        guard hex.count == 6, let value = UInt32(hex, radix: 16) else { return fallback }
        return UIColor(red: CGFloat((value >> 16) & 255)/255, green: CGFloat((value >> 8) & 255)/255,
                       blue: CGFloat(value & 255)/255, alpha: 1)
    }
    static var wallpaperURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: KeyboardSettings.groupID)?
            .appendingPathComponent("keyboard-wallpaper.jpg")
    }
    static func wallpaper() -> UIImage? {
        guard let url = wallpaperURL else { return nil }
        return UIImage(contentsOfFile: url.path)
    }
    static func font(_ size: CGFloat, design: String) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: .medium)
        let style: UIFontDescriptor.SystemDesign = design == "mono" ? .monospaced : design == "serif" ? .serif : design == "rounded" ? .rounded : .default
        return UIFont(descriptor: base.fontDescriptor.withDesign(style) ?? base.fontDescriptor, size: size)
    }
}
