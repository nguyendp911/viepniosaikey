import UIKit

enum ToolbarAppearance {
    static let accent = UIColor(red: 0.36, green: 0.30, blue: 0.85, alpha: 1)
    static let rose = UIColor(red: 0.89, green: 0.39, blue: 0.61, alpha: 1)
    static func colors(_ action: ToolbarAction, palette: KeyboardThemePalette, coupleActive: Bool) -> (UIColor, UIColor) {
        if action == .ai { return (.white, accent) }
        if action == .couple && coupleActive { return (.white, UIColor(red: 0.70, green: 0.21, blue: 0.43, alpha: 1)) }
        return (palette.text, palette.key)
    }
}
