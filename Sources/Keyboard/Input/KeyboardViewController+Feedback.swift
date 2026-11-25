import UIKit
import AudioToolbox
import Vision

extension KeyboardViewController {
    /// Key animations use a single Core Animation object on the existing
    /// key layer. No overlays, Auto Layout changes, timers or image assets.
    @objc func keypressAnimationTapped(_ sender: UIButton) {
        animateKeypress(sender)
        animateProKey(sender)
        showPro6Popup(sender)
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
        case "wave", "rgb":
            let pulse = CAKeyframeAnimation(keyPath: "backgroundColor")
            let original = key.backgroundColor?.cgColor ?? UIColor.secondarySystemBackground.cgColor
            let accent = keypressEffect == "rgb"
                ? UIColor(hue: CGFloat(typingTouchCount % 24) / 24, saturation: 0.65, brightness: 0.85, alpha: 1).cgColor
                : UIColor(red: 0.48, green: 0.36, blue: 0.95, alpha: 1).cgColor
            pulse.values = [original, accent, original]
            pulse.keyTimes = [0, 0.25, 1]
            pulse.duration = 0.25
            animation = pulse
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
        if !performanceMode {
            if offlineConfig.sound == "custom" {
                proSoundPlayer?.currentTime = 0
                proSoundPlayer?.play()
            } else if offlineConfig.sound == "click" { AudioServicesPlaySystemSound(1104) }
            else if offlineConfig.sound == "soft" { AudioServicesPlaySystemSound(1123) }
            else if premiumPreferences.sound == "click" || customSound { AudioServicesPlaySystemSound(1104) }
            else if premiumPreferences.sound == "soft" { AudioServicesPlaySystemSound(1123) }
        }
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
            haptic.impactOccurred(intensity: CGFloat(offlineConfig.feedback == 0.45 ? premiumPreferences.feedback : offlineConfig.feedback))
        }
    }
}
