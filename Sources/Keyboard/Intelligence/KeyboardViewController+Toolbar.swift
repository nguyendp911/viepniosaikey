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
        installInlineToolsMenu()
        installWritingActions()
        installClipboardMenu()
        updateCoupleTool()
        refreshProfileIndicator()
    }
    func installInlineToolsMenu() {
        guard let button = toolbarButtons[.tools] else { return }
        let groups = toolStudioGroups()
        let quickNames = ["Viết lại","Dịch","Tình cảm","Định dạng","Personal AI","Tone Mixer","AI Premium","Macro","Biến mẫu","Bộ sưu tập","Văn bản","Hoàn tác","Làm lại"]
        let quick: [UIMenuElement] = quickNames.compactMap { name in
            guard let spec = groups.first(where: { $0.0 == name }) else { return nil }
            if let menu = spec.2 { return menu }
            if let action = spec.3 {
                return UIAction(title: spec.0, image: UIImage(systemName: spec.1)) { _ in action() }
            }
            return nil
        }
        let all = UIAction(title: "Tất cả công cụ", image: UIImage(systemName: "square.grid.2x2")) { [weak self] _ in
            self?.openIntelligenceHub()
        }
        button.menu = UIMenu(title: "ViePN · công cụ trực tiếp", children: quick + [all])
        button.showsMenuAsPrimaryAction = true
        button.accessibilityHint = "Chọn công cụ để xử lý ngay nội dung đang nhập"
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
