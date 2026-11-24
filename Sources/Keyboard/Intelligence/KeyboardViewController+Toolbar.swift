import UIKit

extension KeyboardViewController {
    func buildToolbar() {
        for action in ToolbarAction.allCases {
            let button = ToolbarButton(action: action)
            button.addTarget(self, action: ToolbarActionRouter.selector(for: action), for: .touchUpInside)
            toolbarButtons[action] = button
        }
        container.addArrangedSubview(keyboardToolbar)
        refreshToolbarLayout(force: true)
        installWritingActions()
        installClipboardMenu()
        updateCoupleTool()
        refreshProfileIndicator()
    }
    func reloadToolbarConfiguration() {
        toolbarConfiguration = ToolbarPreferences.configuration
        refreshToolbarLayout(force: true)
    }
    func refreshToolbarLayout(force: Bool = false) {
        let width = Int(container.bounds.width > 0 ? container.bounds.width : max(0, view.bounds.width - 8))
        let result = ToolbarLayoutEngine.layout(width: width, configuration: toolbarConfiguration)
        guard force || result != lastToolbarLayout else { return }
        let oldHeight = lastToolbarLayout?.height
        lastToolbarLayout = result
        keyboardToolbar.apply(result, buttons: toolbarButtons)
        applyToolbarAppearance()
        if oldHeight != result.height { updateKeyboardHeight() }
    }
    func applyToolbarAppearance() {
        guard let layout = lastToolbarLayout else { return }
        let palette = KeyboardThemePalette.resolve(currentTheme)
        for item in layout.items {
            guard let button = toolbarButtons[item.action] else { continue }
            button.render(presentation: item.presentation, palette: palette,
                          radius: toolbarConfiguration.radius, coupleActive: KeyboardSettings.coupleEnabled)
        }
    }
}
