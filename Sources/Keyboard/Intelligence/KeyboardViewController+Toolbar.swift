import UIKit

extension KeyboardViewController {
    func applyToolbarOrder() {
        guard toolButtons.count == ToolbarPreferences.standard.count,
              let row = toolButtons.first?.superview as? UIStackView else { return }
        let ordered = ToolbarPreferences.order.compactMap { id in
            ToolbarPreferences.standard.firstIndex(of: id).map { toolButtons[$0] }
        }
        if row.arrangedSubviews.map(ObjectIdentifier.init) == ordered.map(ObjectIdentifier.init) { return }
        for button in toolButtons { row.removeArrangedSubview(button); button.removeFromSuperview() }
        for id in ToolbarPreferences.order {
            if let index = ToolbarPreferences.standard.firstIndex(of: id) { row.addArrangedSubview(toolButtons[index]) }
        }
    }
}
