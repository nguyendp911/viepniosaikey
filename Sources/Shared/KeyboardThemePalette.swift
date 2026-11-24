import UIKit

/// Shared palette: the app preview and the real extension use identical colors.
struct KeyboardThemePalette {
    let canvas: UIColor
    let key: UIColor
    let text: UIColor
    let modifier: UIColor

    static func resolve(_ id: String) -> KeyboardThemePalette {
        let canvas: UIColor
        let keyColor: UIColor
        let primary: UIColor
        let modifier: UIColor
        switch id {
        case "custom":
            let design = KeyboardDesign.current
            canvas = KeyboardDesign.color(design.canvas)
            keyColor = KeyboardDesign.color(design.key).withAlphaComponent(CGFloat(max(0.45, min(1, design.opacity))))
            primary = KeyboardDesign.color(design.text)
            modifier = KeyboardDesign.color(design.modifier)
        case "titanium":
            canvas = UIColor(red: 0.067, green: 0.075, blue: 0.094, alpha: 1)
            keyColor = UIColor(red: 0.19, green: 0.205, blue: 0.235, alpha: 1)
            primary = UIColor(red: 0.98, green: 0.98, blue: 1, alpha: 1)
            modifier = UIColor(red: 0.3, green: 0.34, blue: 0.4, alpha: 1)
        case "purewhite":
            canvas = UIColor(red: 0.9, green: 0.92, blue: 0.95, alpha: 1)
            keyColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
            primary = UIColor(red: 0.12, green: 0.15, blue: 0.2, alpha: 1)
            modifier = UIColor(red: 0.75, green: 0.8, blue: 0.87, alpha: 1)
        case "cyberneon":
            canvas = UIColor(red: 0.04, green: 0.067, blue: 0.14, alpha: 1)
            keyColor = UIColor(red: 0.12, green: 0.17, blue: 0.28, alpha: 1)
            primary = UIColor(red: 0.61, green: 0.94, blue: 1, alpha: 1)
            modifier = UIColor(red: 0.18, green: 0.33, blue: 0.45, alpha: 1)
        case "rosegold":
            canvas = UIColor(red: 0.92, green: 0.81, blue: 0.77, alpha: 1)
            keyColor = UIColor(red: 1, green: 0.94, blue: 0.9, alpha: 1)
            primary = UIColor(red: 0.42, green: 0.23, blue: 0.2, alpha: 1)
            modifier = UIColor(red: 0.83, green: 0.64, blue: 0.59, alpha: 1)
        case "jade":
            canvas = UIColor(red: 0.06, green: 0.18, blue: 0.15, alpha: 1)
            keyColor = UIColor(red: 0.14, green: 0.31, blue: 0.26, alpha: 1)
            primary = UIColor(red: 0.85, green: 0.98, blue: 0.88, alpha: 1)
            modifier = UIColor(red: 0.22, green: 0.43, blue: 0.35, alpha: 1)
        case "heritage":
            canvas = UIColor(red: 0.3, green: 0.07, blue: 0.08, alpha: 1)
            keyColor = UIColor(red: 0.48, green: 0.13, blue: 0.15, alpha: 1)
            primary = UIColor(red: 0.99, green: 0.86, blue: 0.59, alpha: 1)
            modifier = UIColor(red: 0.62, green: 0.23, blue: 0.22, alpha: 1)
        case "midnight":
            canvas = UIColor(red: 0.09, green: 0.11, blue: 0.19, alpha: 1)
            keyColor = UIColor(red: 0.18, green: 0.22, blue: 0.33, alpha: 1)
            primary = .white
            modifier = UIColor(red: 0.26, green: 0.30, blue: 0.43, alpha: 1)
        case "ocean":
            canvas = UIColor(red: 0.73, green: 0.87, blue: 0.94, alpha: 1)
            keyColor = UIColor(red: 0.96, green: 0.99, blue: 1, alpha: 1)
            primary = UIColor(red: 0.10, green: 0.18, blue: 0.28, alpha: 1)
            modifier = UIColor(red: 0.56, green: 0.74, blue: 0.85, alpha: 1)
        case "rose":
            canvas = UIColor(red: 0.95, green: 0.84, blue: 0.89, alpha: 1)
            keyColor = UIColor(red: 1, green: 0.97, blue: 0.98, alpha: 1)
            primary = UIColor(red: 0.25, green: 0.14, blue: 0.24, alpha: 1)
            modifier = UIColor(red: 0.86, green: 0.66, blue: 0.77, alpha: 1)
        case "lavender":
            canvas = UIColor(red: 0.83, green: 0.80, blue: 0.96, alpha: 1)
            keyColor = UIColor(red: 0.98, green: 0.97, blue: 1, alpha: 1)
            primary = UIColor(red: 0.20, green: 0.17, blue: 0.35, alpha: 1)
            modifier = UIColor(red: 0.68, green: 0.62, blue: 0.86, alpha: 1)
        case "mint":
            canvas = UIColor(red: 0.77, green: 0.92, blue: 0.86, alpha: 1)
            keyColor = UIColor(red: 0.97, green: 1, blue: 0.99, alpha: 1)
            primary = UIColor(red: 0.11, green: 0.28, blue: 0.25, alpha: 1)
            modifier = UIColor(red: 0.54, green: 0.78, blue: 0.70, alpha: 1)
        case "sunset":
            canvas = UIColor(red: 0.94, green: 0.78, blue: 0.72, alpha: 1)
            keyColor = UIColor(red: 1, green: 0.97, blue: 0.94, alpha: 1)
            primary = UIColor(red: 0.35, green: 0.19, blue: 0.20, alpha: 1)
            modifier = UIColor(red: 0.86, green: 0.62, blue: 0.57, alpha: 1)
        case "graphite":
            canvas = UIColor(red: 0.14, green: 0.15, blue: 0.17, alpha: 1)
            keyColor = UIColor(red: 0.28, green: 0.29, blue: 0.32, alpha: 1)
            primary = .white
            modifier = UIColor(red: 0.37, green: 0.39, blue: 0.43, alpha: 1)
        case "sakura":
            canvas = UIColor(red: 0.98, green: 0.88, blue: 0.92, alpha: 1)
            keyColor = UIColor(red: 1, green: 0.98, blue: 0.99, alpha: 1)
            primary = UIColor(red: 0.37, green: 0.20, blue: 0.31, alpha: 1)
            modifier = UIColor(red: 0.91, green: 0.73, blue: 0.80, alpha: 1)
        case "forest":
            canvas = UIColor(red: 0.15, green: 0.25, blue: 0.22, alpha: 1)
            keyColor = UIColor(red: 0.23, green: 0.38, blue: 0.31, alpha: 1)
            primary = .white
            modifier = UIColor(red: 0.32, green: 0.47, blue: 0.40, alpha: 1)
        case "sand":
            canvas = UIColor(red: 0.92, green: 0.88, blue: 0.79, alpha: 1)
            keyColor = UIColor(red: 1, green: 0.99, blue: 0.95, alpha: 1)
            primary = UIColor(red: 0.29, green: 0.24, blue: 0.20, alpha: 1)
            modifier = UIColor(red: 0.78, green: 0.72, blue: 0.62, alpha: 1)
        case "aurora":
            canvas = UIColor(red: 0.08, green: 0.20, blue: 0.26, alpha: 1)
            keyColor = UIColor(red: 0.14, green: 0.32, blue: 0.38, alpha: 1)
            primary = .white
            modifier = UIColor(red: 0.22, green: 0.45, blue: 0.47, alpha: 1)
        case "amoled":
            canvas = .black
            keyColor = UIColor(white: 0.09, alpha: 1)
            primary = .white
            modifier = UIColor(white: 0.19, alpha: 1)
        case "neon":
            canvas = UIColor(red: 0.035, green: 0.045, blue: 0.10, alpha: 1)
            keyColor = UIColor(red: 0.12, green: 0.13, blue: 0.24, alpha: 1)
            primary = UIColor(red: 0.49, green: 0.99, blue: 0.94, alpha: 1)
            modifier = UIColor(red: 0.20, green: 0.19, blue: 0.36, alpha: 1)
        case "cyberpunk":
            canvas = UIColor(red: 0.13, green: 0.055, blue: 0.18, alpha: 1)
            keyColor = UIColor(red: 0.25, green: 0.10, blue: 0.30, alpha: 1)
            primary = UIColor(red: 0.99, green: 0.92, blue: 0.39, alpha: 1)
            modifier = UIColor(red: 0.39, green: 0.16, blue: 0.40, alpha: 1)
        case "coffee":
            canvas = UIColor(red: 0.26, green: 0.19, blue: 0.16, alpha: 1)
            keyColor = UIColor(red: 0.39, green: 0.28, blue: 0.22, alpha: 1)
            primary = UIColor(red: 1, green: 0.94, blue: 0.83, alpha: 1)
            modifier = UIColor(red: 0.49, green: 0.36, blue: 0.29, alpha: 1)
        case "ice":
            canvas = UIColor(red: 0.82, green: 0.92, blue: 0.98, alpha: 1)
            keyColor = UIColor(red: 0.98, green: 1, blue: 1, alpha: 1)
            primary = UIColor(red: 0.10, green: 0.24, blue: 0.40, alpha: 1)
            modifier = UIColor(red: 0.63, green: 0.79, blue: 0.89, alpha: 1)
        case "gold":
            canvas = UIColor(red: 0.14, green: 0.12, blue: 0.10, alpha: 1)
            keyColor = UIColor(red: 0.25, green: 0.22, blue: 0.17, alpha: 1)
            primary = UIColor(red: 0.98, green: 0.87, blue: 0.57, alpha: 1)
            modifier = UIColor(red: 0.39, green: 0.32, blue: 0.23, alpha: 1)
        default:
            canvas = UIColor { trait in
                trait.userInterfaceStyle == .dark
                    ? UIColor(red: 0.12, green: 0.14, blue: 0.20, alpha: 1)
                    : UIColor(red: 0.89, green: 0.91, blue: 0.96, alpha: 1)
            }
            keyColor = .systemBackground
            primary = .label
            modifier = UIColor { trait in
                trait.userInterfaceStyle == .dark ? UIColor(white: 0.24, alpha: 1)
                    : UIColor(red: 0.72, green: 0.76, blue: 0.82, alpha: 1)
            }
        }
        return KeyboardThemePalette(canvas: canvas, key: keyColor, text: primary, modifier: modifier)
    }
}
