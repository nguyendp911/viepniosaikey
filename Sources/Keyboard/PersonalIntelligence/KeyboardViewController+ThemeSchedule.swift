import UIKit

extension KeyboardViewController {
    func refreshScheduledTheme(force:Bool=false) {
        let next = ThemeSchedule.effective()
        if force || next != currentTheme || scheduledBaseTheme != KeyboardSettings.theme { applyTheme() }
    }
    func applyPersonalThemeBackdrop() {
        view.layer.sublayers?.filter { $0.name == "viepn.aurora" }.forEach { $0.removeFromSuperlayer() }
        guard currentTheme == "auroralive" || currentTheme == "holographic" else { return }
        let gradient = CAGradientLayer()
        gradient.name = "viepn.aurora"
        gradient.frame = view.bounds
        gradient.colors = [UIColor(red:0.13,green:0.14,blue:0.34,alpha:1).cgColor,UIColor(red:0.04,green:0.27,blue:0.29,alpha:1).cgColor,UIColor(red:0.12,green:0.08,blue:0.24,alpha:1).cgColor]
        gradient.startPoint = CGPoint(x:0,y:0); gradient.endPoint = CGPoint(x:1,y:1)
        view.layer.insertSublayer(gradient,at:0)
        if currentTheme == "auroralive", !performanceMode, !UIAccessibility.isReduceMotionEnabled {
            let animation = CABasicAnimation(keyPath:"locations")
            animation.fromValue = [0,0.25,1]; animation.toValue = [0,0.75,1]
            animation.duration = 6; animation.autoreverses = true; animation.repeatCount = .infinity
            gradient.add(animation,forKey:"aurora")
        }
    }
}
