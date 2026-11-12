import UIKit

/// Enlarge the effective touch area into the space between neighboring keys.
/// The visible key geometry stays unchanged. The extension is deliberately
/// capped at half the inter-key gap, so adjacent keys never overlap.
/// This is a deterministic, offline hit-area improvement; it does not guess
/// or silently replace the user's intended character.
final class AdaptiveKeyButton: UIButton {
    var horizontalHitExpansion: CGFloat = 0

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard !isHidden, isEnabled, alpha > 0.01 else { return false }
        let expansion = max(0, min(4, horizontalHitExpansion))
        return bounds.insetBy(dx: -expansion, dy: 0).contains(point)
    }
}
