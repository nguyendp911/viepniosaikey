import UIKit

extension KeyboardViewController {
    func applyToolbarOrder() {
        guard toolButtons.count == ToolbarPreferences.standard.count,
              let row = toolButtons.first?.superview as? UIStackView else { return }
        for button in toolButtons { row.removeArrangedSubview(button); button.removeFromSuperview() }
        for id in ToolbarPreferences.order {
            if let index = ToolbarPreferences.standard.firstIndex(of: id) { row.addArrangedSubview(toolButtons[index]) }
        }
    }
}
