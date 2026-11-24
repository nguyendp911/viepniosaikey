import UIKit

enum SuggestionChipView {
    static func style(_ button: UIButton, palette: KeyboardThemePalette) {
        button.setTitleColor(palette.text, for: .normal)
        button.backgroundColor = palette.key
        button.layer.cornerRadius = 10
        button.titleLabel?.numberOfLines = 1
        button.titleLabel?.lineBreakMode = .byTruncatingTail
    }
}
extension KeyboardViewController {
    func refreshSuggestionAppearance() {
        let palette = KeyboardThemePalette.resolve(currentTheme)
        for case let button as UIButton in idleBar.arrangedSubviews + candidateBar.arrangedSubviews {
            SuggestionChipView.style(button, palette: palette)
        }
    }
}
