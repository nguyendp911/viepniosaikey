import UIKit

/// Enlarge the effective touch area into the space between neighboring keys.
/// The visible key geometry stays unchanged. The extension is deliberately
/// capped at half the inter-key gap, so adjacent keys never overlap.
/// This is a deterministic, offline hit-area improvement; it does not guess
/// or silently replace the user's intended character.
final class AdaptiveKeyButton: UIButton {
    var horizontalHitExpansion: CGFloat = 0
    private var lastShadowBounds: CGRect = .zero

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
