import UIKit
import AudioToolbox
import Vision

extension KeyboardViewController {
    /// Key animations use a single Core Animation object on the existing
    /// key layer. No overlays, Auto Layout changes, timers or image assets.
    @objc func keypressAnimationTapped(_ sender: UIButton) {
        animateKeypress(sender)
    }

    func animateKeypress(_ key: UIButton) {
        guard !performanceMode, keypressEffect != "off",
              !UIAccessibility.isReduceMotionEnabled else { return }
        let layer = key.layer
        let animation: CAAnimation
        switch keypressEffect {
        case "pop":
            let pulse = CABasicAnimation(keyPath: "transform.scale")
            pulse.fromValue = 0.91
            pulse.toValue = 1
            pulse.duration = 0.13
            animation = pulse
        case "bounce":
            let bounce = CAKeyframeAnimation(keyPath: "transform.scale")
            bounce.values = [1, 0.90, 1.06, 1]
            bounce.keyTimes = [0, 0.22, 0.62, 1]
            bounce.duration = 0.21
            animation = bounce
        case "glow":
            let glow = CABasicAnimation(keyPath: "shadowOpacity")
            glow.fromValue = 0.80
            glow.toValue = layer.shadowOpacity
            glow.duration = 0.18
            animation = glow
        case "flash":
            let flash = CABasicAnimation(keyPath: "opacity")
            flash.fromValue = 0.57
            flash.toValue = 1
            flash.duration = 0.16
            animation = flash
        default:
            return
        }
        animation.isRemovedOnCompletion = true
        layer.add(animation, forKey: "viepn.keypress")
    }

    func tactileFeedback() {
        guard hapticsEnabled else { return }
        if hapticsStyle == "vibrate" {
            // System vibration is much heavier than Taptic feedback.
            // Never make the main typing thread wait for AudioServices.
            let now = CACurrentMediaTime()
            guard now - lastVibrationAt >= 0.25 else { return }
            lastVibrationAt = now
            DispatchQueue.global(qos: .utility).async {
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            }
        } else {
            haptic.impactOccurred(intensity: 0.45)
        }
    }
}
