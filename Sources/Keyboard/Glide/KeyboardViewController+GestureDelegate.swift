import UIKit
import AudioToolbox
import Vision

extension KeyboardViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldReceive touch: UITouch) -> Bool {
        guard gestureRecognizer === glideRecognizer, useGlide, !isNumbers,
              let target = touch.view else { return false }
        // Do not intercept toolbars, delete, return, spacebar or suggestion taps.
        guard letterButtons.contains(where: { target.isDescendant(of: $0) }) else {
            return false
        }
        glideTouchOrigin = touch.location(in: view)
        return true
    }
}
