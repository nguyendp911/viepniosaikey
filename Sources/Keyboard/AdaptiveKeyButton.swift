import UIKit

/// Enlarge the effective touch area into the space between neighboring keys.
/// The visible key geometry stays unchanged. The extension is deliberately
/// capped at half the inter-key gap, so adjacent keys never overlap.
/// This is a deterministic, offline hit-area improvement; it does not guess
/// or silently replace the user's intended character.
///
/// The key also shows a clear pressed state: while it is held its background
/// moves toward black (light keys) or white (dark keys). The colour the theme
/// sets stays the "resting" colour, so themes need no changes.
final class AdaptiveKeyButton: UIButton {
    var horizontalHitExpansion: CGFloat = 0
    private var lastShadowBounds: CGRect = .zero
    private var restingColor: UIColor?
    private var showsPressedColor = false

    /// The colour the key has when it is not pressed.
    var restingBackground: UIColor? { restingColor }

    override var backgroundColor: UIColor? {
        get { super.backgroundColor }
        set {
            restingColor = newValue
            super.backgroundColor = showsPressedColor
                ? AdaptiveKeyButton.pressed(newValue) : newValue
        }
    }

    override var isHighlighted: Bool {
        didSet {
            guard isHighlighted != oldValue else { return }
            showsPressedColor = isHighlighted
            super.backgroundColor = isHighlighted
                ? AdaptiveKeyButton.pressed(restingColor) : restingColor
        }
    }

    /// A visible but gentle change: light keys darken, dark keys lighten.
    static func pressed(_ base: UIColor?) -> UIColor? {
        guard let base = base else { return nil }
        return UIColor { trait in
            let resolved = base.resolvedColor(with: trait)
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            guard resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
                return resolved
            }
            let luminance = 0.299 * red + 0.587 * green + 0.114 * blue
            let target: CGFloat = luminance > 0.5 ? 0 : 1
            let amount: CGFloat = luminance > 0.5 ? 0.14 : 0.16
            return UIColor(red: red + (target - red) * amount,
                           green: green + (target - green) * amount,
                           blue: blue + (target - blue) * amount,
                           alpha: alpha)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Without an explicit shadowPath Core Animation derives the shadow from
        // the layer's alpha mask and re-renders it off-screen every frame, for
        // every key. With ~35 shadowed keys this is what makes the keyboard
        // stutter once it has been in use (animations, swipe trail, redraws).
        guard bounds != lastShadowBounds else { return }
        lastShadowBounds = bounds
        layer.shadowPath = UIBezierPath(
            roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard !isHidden, isEnabled, alpha > 0.01 else { return false }
        let expansion = max(0, min(4, horizontalHitExpansion))
        return bounds.insetBy(dx: -expansion, dy: 0).contains(point)
    }
}
