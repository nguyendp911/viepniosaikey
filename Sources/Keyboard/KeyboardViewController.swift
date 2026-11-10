import UIKit
import AudioToolbox

/// Compact preview with real internal padding; do not prepend spaces/emoji to text.
private final class KeyboardPreviewLabel: UILabel {
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.insetBy(dx: 12, dy: 5))
    }
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + 24, height: size.height + 10)
    }
}

/// ViePN keyboard: composing a suggested reply never writes the source message
/// to the host chat field. All host-field modifications are explicit user taps.
final class KeyboardViewController: UIInputViewController {
    private let container = UIStackView()
    private let statusLabel = UILabel()
    private let previewLabel = KeyboardPreviewLabel()
    private var selectedText = ""
    private var isUppercase = KeyboardSettings.autoCapitalize
    private var isNumbers = false
    private var isShiftLocked = false
    private var lastSuggestions: [ReplySuggestion] = []
    private var chosenIndex = 0
    private var suggestionContainer: UIStackView?
    private var isRequestRunning = false
    private var requestID = UUID()
    private var letterButtons: [UIButton] = []
    private var letterRows: [UIStackView] = []
    private var secondaryRow: UIStackView?
    private var heightConstraint: NSLayoutConstraint?
    private var toneButtons: [UIButton] = []
    private var toolButtons: [UIButton] = []
    private let aiColor = UIColor(red: 0.32, green: 0.36, blue: 0.93, alpha: 1)
    private let cyanColor = UIColor(red: 0.07, green: 0.65, blue: 0.86, alpha: 1)
    private let haptic = UIImpactFeedbackGenerator(style: .light)
    private var lastVibrationAt: CFTimeInterval = 0
    // Read App Group preferences when the keyboard opens rather than on each key.
    private var typingMode = KeyboardSettings.typingMode
    private var telexEnabled = KeyboardSettings.telexEnabled
    private var hapticsEnabled = KeyboardSettings.hapticEnabled
    private var hapticsStyle = KeyboardSettings.hapticStyle
    private var useSmartBilingual = KeyboardSettings.smartBilingual
    private var useSuggestions = KeyboardSettings.predictionsEnabled
    private var useGlide = KeyboardSettings.glideEnabled
    private var learnedWords: [String: Int] = [:]
    private var recentWord = ""
    private let candidateBar = UIStackView()
    private var candidateButtons: [UIButton] = []
    private var candidateWords: [String] = []
    private var keyboardLeadingConstraint: NSLayoutConstraint?
    private var keyboardTrailingConstraint: NSLayoutConstraint?
    private var keyHeightConstraints: [NSLayoutConstraint] = []
    private var glidePath = ""
    private var glideLastKey = ""
    private var glideIsActive = false
    private var cursorSteps = 0

    private func refreshTypingPreferences() {
        typingMode = KeyboardSettings.typingMode
        telexEnabled = KeyboardSettings.telexEnabled
        hapticsEnabled = KeyboardSettings.hapticEnabled
        hapticsStyle = KeyboardSettings.hapticStyle
        useSmartBilingual = KeyboardSettings.smartBilingual
        useSuggestions = KeyboardSettings.predictionsEnabled
        useGlide = KeyboardSettings.glideEnabled
        learnedWords = KeyboardSettings.learnedWords
    }
    private var currentTheme: String = ""
    // Consistent solid material replaces the previous oversized multicolor gradient.

    override func viewDidLoad() {
        super.viewDidLoad()
        refreshTypingPreferences()
        buildKeyboard()
        applyTheme()
        if hapticsEnabled && hapticsStyle == "light" { haptic.prepare() }
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        if currentTheme != KeyboardSettings.theme { applyTheme() }
        // Avoid erasing the reply when the host app changes text focus.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshTypingPreferences()
        applyTheme()
        updateAdaptiveLayout()
        updateCoupleTool()
        installWritingActions()
        installClipboardMenu()
        updateCandidates()
    }

    private func buildKeyboard() {
        view.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.11, green: 0.13, blue: 0.20, alpha: 1)
                : UIColor(red: 0.89, green: 0.92, blue: 0.97, alpha: 1)
        }
        heightConstraint = view.heightAnchor.constraint(equalToConstant: 240)
        heightConstraint?.priority = .defaultHigh
        heightConstraint?.isActive = true
        container.axis = .vertical
        container.spacing = 6
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)
        keyboardLeadingConstraint = container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4)
        keyboardTrailingConstraint = container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4)
        NSLayoutConstraint.activate([
            keyboardLeadingConstraint!,
            keyboardTrailingConstraint!,
            container.topAnchor.constraint(equalTo: view.topAnchor, constant: 5),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -4)
        ])

        statusLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        statusLabel.textColor = .secondaryLabel
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 1
        statusLabel.lineBreakMode = .byTruncatingTail
        statusLabel.text = "✦ ViePN AI · Viết hay hơn, gửi nhanh hơn"
        statusLabel.isHidden = true
        container.addArrangedSubview(statusLabel)

        // All AI controls live in one slim strip. Expand only for suggestions.
        // SF Symbols only: crisp vector icons, consistent weight, no emoji in toolbar.
        // Keep a real always-visible UIButton for Paste; do not use UIPasteControl here.
        let commands = UIStackView()
        commands.axis = .horizontal
        commands.spacing = 6
        commands.distribution = .fillEqually
        commands.alignment = .fill
        let tools: [(String, String, Selector)] = [
            ("Dán", "doc.on.clipboard", #selector(pasteTapped)),
            ("Couple", "heart", #selector(coupleTapped)),
            ("AI", "sparkles", #selector(cloudTapped)),
            ("Offline", "wifi.slash", #selector(offlineTapped)),
            ("Mẫu", "text.quote", #selector(phrasesTapped))
        ]
        for (index, spec) in tools.enumerated() {
            let button = UIButton(type: .system)
            configureSymbolButton(button, title: spec.0, symbol: spec.1,
                                  foreground: .label, background: .secondarySystemBackground)
            button.tag = index
            button.addTarget(self, action: spec.2, for: .touchUpInside)
            toolButtons.append(button)
            commands.addArrangedSubview(button)
        }
        commands.heightAnchor.constraint(equalToConstant: 39).isActive = true
        container.addArrangedSubview(commands)
        installWritingActions()
        installClipboardMenu()
        updateCoupleTool()

        previewLabel.numberOfLines = 2
        previewLabel.font = .systemFont(ofSize: 13, weight: .medium)
        previewLabel.textColor = .label
        previewLabel.textAlignment = .left
        previewLabel.layer.cornerRadius = 12
        previewLabel.layer.cornerCurve = .continuous
        previewLabel.layer.borderWidth = 1
        previewLabel.clipsToBounds = true
        previewLabel.isHidden = true
        previewLabel.heightAnchor.constraint(equalToConstant: 43).isActive = true
        container.addArrangedSubview(previewLabel)

        candidateBar.axis = .horizontal
        candidateBar.spacing = 5
        candidateBar.distribution = .fillEqually
        candidateBar.isHidden = true
        candidateBar.heightAnchor.constraint(equalToConstant: 31).isActive = true
        for index in 0..<3 {
            let button = UIButton(type: .system)
            button.tag = index
            button.layer.cornerRadius = 9
            button.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.8)
            button.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
            button.titleLabel?.lineBreakMode = .byTruncatingTail
            button.setTitleColor(.label, for: .normal)
            button.addTarget(self, action: #selector(candidateTapped(_:)), for: .touchUpInside)
            candidateButtons.append(button)
            candidateBar.addArrangedSubview(button)
        }
        container.addArrangedSubview(candidateBar)

        let rows = ["qwertyuiop", "asdfghjkl", "zxcvbnm"]
        for (rowIndex, letters) in rows.enumerated() {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = CGFloat(KeyboardSettings.keySpacing)
            row.alignment = .fill
            row.distribution = .fillEqually
            if rowIndex == 1 {
                row.layoutMargins = UIEdgeInsets(top: 0, left: 19, bottom: 0, right: 19)
                row.isLayoutMarginsRelativeArrangement = true
            }
            if rowIndex == 2 {
                let shift = keyButton("", action: #selector(shiftTapped))
                configureIconOnly(shift, symbol: "shift.fill")
                styleModifier(shift)
                row.addArrangedSubview(shift)
            }
            for letter in letters {
                let key = keyButton(String(letter), action: #selector(letterTapped(_:)))
                // Register on first touch, not touch-up, for immediate visual
                // text feedback when typing quickly.
                key.removeTarget(self, action: #selector(letterTapped(_:)), for: .touchUpInside)
                key.addTarget(self, action: #selector(letterTapped(_:)), for: .touchDown)
                letterButtons.append(key)
                row.addArrangedSubview(key)
            }
            if rowIndex == 2 {
                let delete = keyButton("", action: #selector(deleteTapped))
                configureIconOnly(delete, symbol: "delete.left")
                styleModifier(delete)
                let gesture = UILongPressGestureRecognizer(target: self, action: #selector(deleteWordGesture(_:)))
                gesture.minimumPressDuration = 0.45
                delete.addGestureRecognizer(gesture)
                delete.accessibilityHint = "Nhấn giữ để xóa từ"
                row.addArrangedSubview(delete)
            }
            let height = row.heightAnchor.constraint(equalToConstant: CGFloat(KeyboardSettings.keyHeight))
            height.isActive = true
            keyHeightConstraints.append(height)
            letterRows.append(row)
            container.addArrangedSubview(row)
        }

        // Large spacebar, separate punctuation, globe and return as in iOS.
        let bottom = UIStackView()
        bottom.axis = .horizontal
        bottom.spacing = CGFloat(KeyboardSettings.keySpacing)
        bottom.distribution = .fill
        bottom.alignment = .fill

        let numeric = keyButton("123", action: #selector(numbersTapped))
        let globe = keyButton("", action: #selector(globeTapped))
        configureIconOnly(globe, symbol: "globe", size: 20)
        let comma = keyButton(",", action: #selector(punctuationTapped(_:)))
        let space = keyButton("dấu cách", action: #selector(spaceTapped))
        let cursorPan = UIPanGestureRecognizer(target: self, action: #selector(spaceCursorPanned(_:)))
        cursorPan.cancelsTouchesInView = true
        space.addGestureRecognizer(cursorPan)
        space.accessibilityHint = "Vuốt ngang để di chuyển con trỏ"
        let period = keyButton(".", action: #selector(punctuationTapped(_:)))
        let enter = keyButton("", action: #selector(returnTapped))
        configureIconOnly(enter, symbol: "return.left", size: 20)
        for key in [numeric, globe, comma, period] { styleModifier(key) }
        enter.backgroundColor = UIColor(red: 0.29, green: 0.54, blue: 0.98, alpha: 1)
        enter.setTitleColor(.white, for: .normal)
        enter.tintColor = .white
        for key in [numeric, globe, comma, space, period, enter] { bottom.addArrangedSubview(key) }
        numeric.widthAnchor.constraint(equalToConstant: 44).isActive = true
        globe.widthAnchor.constraint(equalToConstant: 40).isActive = true
        comma.widthAnchor.constraint(equalToConstant: 34).isActive = true
        period.widthAnchor.constraint(equalToConstant: 34).isActive = true
        enter.widthAnchor.constraint(equalToConstant: 48).isActive = true
        let bottomHeight = bottom.heightAnchor.constraint(equalToConstant: CGFloat(KeyboardSettings.keyHeight))
        bottomHeight.isActive = true
        keyHeightConstraints.append(bottomHeight)
        secondaryRow = bottom
        container.addArrangedSubview(bottom)
        if useGlide {
            let pan = UIPanGestureRecognizer(target: self, action: #selector(glidePanned(_:)))
            pan.cancelsTouchesInView = false
            view.addGestureRecognizer(pan)
        }
        updateKeys()
        updateAdaptiveLayout()
        updateKeyboardHeight()
    }

    /// The paste target is the visible keyboard controller itself.
    /// No hidden UITextView, overlay, or direct UIPasteboard read is involved.
    /// The system control is enabled when compatible text exists on the pasteboard.
    private func installWritingActions() {
        guard toolButtons.count > 2 else { return }
        let actions = AIWritingAction.allCases.map { action in
            UIAction(title: action.rawValue, image: UIImage(systemName: "wand.and.stars")) { [weak self] _ in
                self?.performWritingAction(action)
            }
        }
        let selected = ReplyRecipient(rawValue: KeyboardSettings.recipientMode) ?? .automatic
        let receivers = ReplyRecipient.allCases.map { recipient -> UIAction in
            let action = UIAction(title: recipient.title) { [weak self] _ in
                PersonaStore.activeID = ""
                KeyboardSettings.recipientMode = recipient.rawValue
                self?.installWritingActions()
                let text = self?.selectedText ?? ""
                let resolved = ConversationContextResolver.resolve(text)
                self?.showStatus("Người nhận: " + resolved.displayName + " · Nhấn AI")
            }
            action.state = recipient == selected ? .on : .off
            return action
        }
        let receiverMenu = UIMenu(
            title: "Người nhận: " + selected.title,
            image: UIImage(systemName: "person.crop.circle"),
            children: receivers
        )
        let personaActions: [UIAction] = PersonaStore.all.map { person in
            let item = UIAction(title: person.name) { [weak self] _ in
                PersonaStore.select(person.id)
                self?.installWritingActions()
                self?.showStatus("Hồ sơ: " + person.name)
            }
            item.state = PersonaStore.activeID == person.id ? .on : .off
            return item
        }
        let profileMenu = UIMenu(
            title: "Hồ sơ người nhận",
            image: UIImage(systemName: "person.crop.rectangle.stack"),
            children: [UIAction(title: "Tắt hồ sơ") { [weak self] _ in
                PersonaStore.clearSelection()
                self?.installWritingActions()
                self?.showStatus("Đã tắt hồ sơ người nhận")
            }] + personaActions
        )
        toolButtons[2].menu = UIMenu(
            title: "AI · Vai xưng hô và viết lại",
            children: [receiverMenu, profileMenu] + actions
        )
        toolButtons[2].showsMenuAsPrimaryAction = false
        toolButtons[2].accessibilityHint = "Chạm AI để trả lời. Nhấn giữ để chọn người nhận như chú, cô, bác hoặc sửa câu."
    }

    private func installClipboardMenu() {
        guard let paste = toolButtons.first else { return }
        let save = UIAction(title: "Lưu đoạn vừa Dán",
                            image: UIImage(systemName: "tray.and.arrow.down")) { [weak self] _ in
            guard let self else { return }
            guard !self.selectedText.isEmpty else {
                self.showStatus("Nhấn Dán trước, rồi giữ nút Dán để lưu")
                return
            }
            ClipboardVault.saveExplicitly(self.selectedText)
            self.installClipboardMenu()
            self.showStatus("Đã lưu bản sao do bạn chọn · tối đa 15 đoạn")
        }
        let items: [UIAction] = ClipboardVault.items.enumerated().map { index, text in
            UIAction(title: String(text.prefix(40)), image: UIImage(systemName: "doc.text")) {
                [weak self] _ in
                self?.selectedText = text
                self?.showStatus("Đã chọn đoạn \(index + 1) · Chạm AI để xử lý")
            }
        }
        let history = UIMenu(title: "Các đoạn đã lưu",
                             image: UIImage(systemName: "tray.full"),
                             children: items)
        let clear = UIAction(title: "Xóa tất cả đoạn đã lưu",
                             image: UIImage(systemName: "trash"),
                             attributes: .destructive) { [weak self] _ in
            ClipboardVault.clear()
            self?.installClipboardMenu()
            self?.showStatus("Đã xóa clipboard được lưu trong ViePN")
        }
        paste.menu = UIMenu(title: "Clipboard cá nhân",
                            children: [save, history, clear])
        paste.showsMenuAsPrimaryAction = false
        paste.accessibilityHint = "Chạm để Dán; nhấn giữ để lưu, chọn hoặc xóa clipboard."
    }

    private func performWritingAction(_ action: AIWritingAction) {
        guard !isRequestRunning else { return }
        guard hasFullAccess else { showStatus("Cần Full Access để dùng AI"); return }
        let source = selectedText.isEmpty
            ? (textDocumentProxy.documentContextBeforeInput ?? "") : selectedText
        guard !source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showStatus("Dán hoặc soạn nội dung trước khi dùng AI")
            return
        }
        isRequestRunning = true
        showStatus("AI đang xử lý: " + action.rawValue)
        let activeID = UUID()
        requestID = activeID
        Task { [weak self] in
            do {
                let transformed = try await AIWritingService.transform(source, action: action)
                await MainActor.run {
                    guard let self, self.requestID == activeID else { return }
                    self.isRequestRunning = false
                    self.show([ReplySuggestion(tone: action.rawValue, text: transformed)])
                }
            } catch {
                await MainActor.run {
                    guard let self, self.requestID == activeID else { return }
                    self.isRequestRunning = false
                    self.showStatus("AI lỗi: " + error.localizedDescription)
                }
            }
        }
    }

    private func keyButton(_ title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 21, weight: .regular)
        button.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(white: 0.31, alpha: 1) : .white
        }
        button.layer.cornerRadius = 10
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.08
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.layer.shadowRadius = 1
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.7
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    /// Symbol + label typography is controlled through UIKit button configuration.
    /// This keeps the icon inside the actual tappable button (no overlay hit testing).
    // A consistent restrained palette keeps the toolbar readable on every
    // keyboard theme. Only the AI action receives a strong accent fill.
    private var chromeIsDark: Bool {
        switch currentTheme {
        case "midnight", "graphite", "forest", "aurora": return true
        case "system", "": return traitCollection.userInterfaceStyle == .dark
        default: return false
        }
    }

    private var chromeInk: UIColor {
        chromeIsDark ? UIColor(white: 0.96, alpha: 1)
                     : UIColor(red: 0.15, green: 0.22, blue: 0.26, alpha: 1)
    }

    private var chromeSurface: UIColor {
        chromeIsDark ? UIColor(red: 0.23, green: 0.31, blue: 0.32, alpha: 1)
                     : UIColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1)
    }

    private var chromeStroke: UIColor {
        chromeIsDark ? UIColor.white.withAlphaComponent(0.10)
                     : UIColor.black.withAlphaComponent(0.08)
    }

    private var chromePrimary: UIColor {
        UIColor(red: 0.34, green: 0.37, blue: 0.80, alpha: 1)
    }

    private func configureSymbolButton(_ button: UIButton, title: String, symbol: String,
                                       foreground: UIColor, background: UIColor,
                                       fontSize: CGFloat = 11.5, iconSize: CGFloat = 13,
                                       padding: CGFloat = 4) {
        var config = UIButton.Configuration.plain()
        config.title = title
        config.image = UIImage(
            systemName: symbol,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: iconSize, weight: .semibold)
        )
        config.imagePlacement = .leading
        config.imagePadding = 5
        config.contentInsets = NSDirectionalEdgeInsets(
            top: 5, leading: padding, bottom: 5, trailing: padding
        )
        config.baseForegroundColor = foreground
        config.background.backgroundColor = background
        config.cornerStyle = .medium
        config.titleLineBreakMode = .byTruncatingTail
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var attributes = incoming
            attributes.font = .systemFont(ofSize: fontSize, weight: .semibold)
            return attributes
        }
        button.configuration = config
        button.layer.cornerRadius = 12
        button.layer.cornerCurve = .continuous
        button.layer.borderWidth = 0.75
        button.layer.borderColor = chromeStroke.cgColor
        button.layer.shadowOpacity = 0
        button.clipsToBounds = true
        button.accessibilityLabel = title
    }

    private func styleToolbar() {
        let names = ["Dán", "Couple", "AI", "Offline", "Mẫu"]
        let symbols = ["doc.on.clipboard", KeyboardSettings.coupleEnabled ? "heart.fill" : "heart",
                       "sparkles", "wifi.slash", "text.quote"]
        for (index, button) in toolButtons.enumerated() where index < names.count {
            let foreground: UIColor
            let background: UIColor
            switch index {
            case 1 where KeyboardSettings.coupleEnabled:
                foreground = chromeIsDark ? UIColor(red: 1, green: 0.79, blue: 0.87, alpha: 1)
                                          : UIColor(red: 0.60, green: 0.20, blue: 0.41, alpha: 1)
                background = chromeIsDark ? UIColor(red: 0.36, green: 0.24, blue: 0.34, alpha: 1)
                                          : UIColor(red: 0.97, green: 0.88, blue: 0.92, alpha: 1)
            case 2:
                foreground = .white
                background = chromePrimary
            default:
                foreground = chromeInk
                background = chromeSurface
            }
            configureSymbolButton(button, title: names[index], symbol: symbols[index],
                                  foreground: foreground, background: background)
            if index == 2 { button.layer.borderWidth = 0 }
        }
    }

    private func configureIconOnly(_ button: UIButton, symbol: String, size: CGFloat = 19) {
        button.setTitle(nil, for: .normal)
        let image = UIImage(systemName: symbol, withConfiguration:
            UIImage.SymbolConfiguration(pointSize: size, weight: .medium))
        button.setImage(image, for: .normal)
        button.tintColor = .label
        button.imageView?.contentMode = .scaleAspectFit
    }

    private func styleModifier(_ button: UIButton) {
        button.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(white: 0.24, alpha: 1)
                : UIColor(red: 0.66, green: 0.70, blue: 0.76, alpha: 1)
        }
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
    }

    private func makeRow(_ actions: [(String, Selector)], height: CGFloat) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.distribution = .fillEqually
        row.spacing = 4
        for (title, action) in actions {
            let button = keyButton(title, action: action)
            button.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
            row.addArrangedSubview(button)
        }
        row.heightAnchor.constraint(equalToConstant: height).isActive = true
        return row
    }

    private func applyTheme() {
        currentTheme = KeyboardSettings.theme
        let canvas: UIColor
        let keyColor: UIColor
        let primary: UIColor
        let modifier: UIColor
        switch currentTheme {
        case "midnight":
            canvas = UIColor(red: 0.09, green: 0.11, blue: 0.19, alpha: 1)
            keyColor = UIColor(red: 0.18, green: 0.22, blue: 0.33, alpha: 1)
            primary = .white
            modifier = UIColor(red: 0.26, green: 0.30, blue: 0.43, alpha: 1)
        case "ocean":
            canvas = UIColor(red: 0.73, green: 0.87, blue: 0.94, alpha: 1)
            keyColor = UIColor(red: 0.96, green: 0.99, blue: 1, alpha: 1)
            primary = UIColor(red: 0.10, green: 0.18, blue: 0.28, alpha: 1)
            modifier = UIColor(red: 0.56, green: 0.74, blue: 0.85, alpha: 1)
        case "rose":
            canvas = UIColor(red: 0.95, green: 0.84, blue: 0.89, alpha: 1)
            keyColor = UIColor(red: 1, green: 0.97, blue: 0.98, alpha: 1)
            primary = UIColor(red: 0.25, green: 0.14, blue: 0.24, alpha: 1)
            modifier = UIColor(red: 0.86, green: 0.66, blue: 0.77, alpha: 1)
        case "lavender":
            canvas = UIColor(red: 0.83, green: 0.80, blue: 0.96, alpha: 1)
            keyColor = UIColor(red: 0.98, green: 0.97, blue: 1, alpha: 1)
            primary = UIColor(red: 0.20, green: 0.17, blue: 0.35, alpha: 1)
            modifier = UIColor(red: 0.68, green: 0.62, blue: 0.86, alpha: 1)
        case "mint":
            canvas = UIColor(red: 0.77, green: 0.92, blue: 0.86, alpha: 1)
            keyColor = UIColor(red: 0.97, green: 1, blue: 0.99, alpha: 1)
            primary = UIColor(red: 0.11, green: 0.28, blue: 0.25, alpha: 1)
            modifier = UIColor(red: 0.54, green: 0.78, blue: 0.70, alpha: 1)
        case "sunset":
            canvas = UIColor(red: 0.94, green: 0.78, blue: 0.72, alpha: 1)
            keyColor = UIColor(red: 1, green: 0.97, blue: 0.94, alpha: 1)
            primary = UIColor(red: 0.35, green: 0.19, blue: 0.20, alpha: 1)
            modifier = UIColor(red: 0.86, green: 0.62, blue: 0.57, alpha: 1)
        case "graphite":
            canvas = UIColor(red: 0.14, green: 0.15, blue: 0.17, alpha: 1)
            keyColor = UIColor(red: 0.28, green: 0.29, blue: 0.32, alpha: 1)
            primary = .white
            modifier = UIColor(red: 0.37, green: 0.39, blue: 0.43, alpha: 1)
        case "sakura":
            canvas = UIColor(red: 0.98, green: 0.88, blue: 0.92, alpha: 1)
            keyColor = UIColor(red: 1, green: 0.98, blue: 0.99, alpha: 1)
            primary = UIColor(red: 0.37, green: 0.20, blue: 0.31, alpha: 1)
            modifier = UIColor(red: 0.91, green: 0.73, blue: 0.80, alpha: 1)
        case "forest":
            canvas = UIColor(red: 0.15, green: 0.25, blue: 0.22, alpha: 1)
            keyColor = UIColor(red: 0.23, green: 0.38, blue: 0.31, alpha: 1)
            primary = .white
            modifier = UIColor(red: 0.32, green: 0.47, blue: 0.40, alpha: 1)
        case "sand":
            canvas = UIColor(red: 0.92, green: 0.88, blue: 0.79, alpha: 1)
            keyColor = UIColor(red: 1, green: 0.99, blue: 0.95, alpha: 1)
            primary = UIColor(red: 0.29, green: 0.24, blue: 0.20, alpha: 1)
            modifier = UIColor(red: 0.78, green: 0.72, blue: 0.62, alpha: 1)
        case "aurora":
            canvas = UIColor(red: 0.08, green: 0.20, blue: 0.26, alpha: 1)
            keyColor = UIColor(red: 0.14, green: 0.32, blue: 0.38, alpha: 1)
            primary = .white
            modifier = UIColor(red: 0.22, green: 0.45, blue: 0.47, alpha: 1)
        default:
            canvas = UIColor { trait in
                trait.userInterfaceStyle == .dark
                    ? UIColor(red: 0.12, green: 0.14, blue: 0.20, alpha: 1)
                    : UIColor(red: 0.89, green: 0.91, blue: 0.96, alpha: 1)
            }
            keyColor = .systemBackground
            primary = .label
            modifier = UIColor { trait in
                trait.userInterfaceStyle == .dark ? UIColor(white: 0.24, alpha: 1)
                    : UIColor(red: 0.72, green: 0.76, blue: 0.82, alpha: 1)
            }
        }
        view.backgroundColor = canvas
        for button in letterButtons {
            button.backgroundColor = keyColor
            button.setTitleColor(primary, for: .normal)
        }
        for row in letterRows {
            for case let button as UIButton in row.arrangedSubviews where !letterButtons.contains(button) {
                button.backgroundColor = modifier
                button.setTitleColor(primary, for: .normal)
                button.tintColor = primary
            }
        }
        if let bottom = secondaryRow {
            for (index, item) in bottom.arrangedSubviews.enumerated() {
                guard let button = item as? UIButton, index != bottom.arrangedSubviews.count - 1 else { continue }
                button.backgroundColor = index == 3 ? keyColor : modifier
                button.setTitleColor(primary, for: .normal)
                button.tintColor = primary
            }
        }
        styleToolbar()
        previewLabel.backgroundColor = chromeSurface
        previewLabel.textColor = chromeInk
        previewLabel.layer.borderColor = chromeStroke.cgColor
        for button in candidateButtons {
            button.backgroundColor = chromeSurface
            button.setTitleColor(chromeInk, for: .normal)
        }
        if !lastSuggestions.isEmpty { updateToneStyles() }
        statusLabel.textColor = primary
    }

    private func tactileFeedback() {
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

    @objc private func punctuationTapped(_ sender: UIButton) {
        beginTyping()
        guard let character = sender.title(for: .normal) else { return }
        tactileFeedback()
        textDocumentProxy.insertText(character)
        recentWord = ""
        updateCandidates()
    }

    @objc private func letterTapped(_ sender: UIButton) {
        guard let title = sender.title(for: .normal) else { return }
        beginTyping()
        let key = isUppercase && !isNumbers ? title.uppercased() : title

        if !isNumbers && typingMode == "telex" && telexEnabled,
           FastTyping.isTelexModifier(key),
           let before = textDocumentProxy.documentContextBeforeInput {
            let word = String(before.reversed().prefix(while: { $0.isLetter }).reversed())
            // A small offline English lexicon protects overlapping Telex keys
            // such as car, book, for and stress. No model/API call per key.
            if !word.isEmpty,
               !(useSmartBilingual && SmartTyping.shouldKeepLiteral(word, adding: key)),
               let converted = VietnameseTelex.transformed(word: word, key: key),
               let edit = FastTyping.edit(from: word, to: converted) {
                for _ in 0..<edit.deleteCount { textDocumentProxy.deleteBackward() }
                if !edit.insertion.isEmpty { textDocumentProxy.insertText(edit.insertion) }
                recentWord = converted
                if isUppercase && !isShiftLocked {
                    isUppercase = false
                    updateKeys()
                }
                updateCandidates()
                tactileFeedback()
                return
            }
        }
        if isNumbers && typingMode == "vni",
           let before = textDocumentProxy.documentContextBeforeInput {
            let word = String(before.reversed().prefix(while: { $0.isLetter }).reversed())
            if !word.isEmpty,
               let converted = VietnameseVNI.transformed(word: word, key: key),
               let edit = FastTyping.edit(from: word, to: converted) {
                for _ in 0..<edit.deleteCount { textDocumentProxy.deleteBackward() }
                if !edit.insertion.isEmpty { textDocumentProxy.insertText(edit.insertion) }
                recentWord = converted
                updateCandidates()
                tactileFeedback()
                return
            }
        }
        textDocumentProxy.insertText(key)
        if key.first?.isLetter == true {
            recentWord = String((recentWord + key).suffix(32))
        } else {
            recentWord = ""
        }
        if isUppercase && !isShiftLocked {
            isUppercase = false
            updateKeys()
        }
        updateCandidates()
        tactileFeedback()
    }

    @objc private func spaceTapped() {
        beginTyping()
        tactileFeedback()
        if let context = textDocumentProxy.documentContextBeforeInput {
            let token = String(context.reversed().prefix(while: {
                $0.isLetter || $0.isNumber || $0 == ";" || $0 == "_"
            }).reversed())
            let word = String(context.reversed().prefix(while: { $0.isLetter }).reversed())
            if let snippet = KeyboardSettings.textSnippets[token], !token.isEmpty {
                for _ in token { textDocumentProxy.deleteBackward() }
                textDocumentProxy.insertText(SmartTyping.expandSnippet(snippet))
            } else if let replacement = KeyboardSettings.replacementDictionary[word.lowercased()],
                      !word.isEmpty, word.count <= 30 {
                for _ in word { textDocumentProxy.deleteBackward() }
                textDocumentProxy.insertText(replacement)
            } else if KeyboardSettings.autoLearnWords && word.count >= 3 && word.count <= 24 {
                let normalized = word.lowercased()
                learnedWords[normalized, default: 0] += 1
                KeyboardSettings.learnedWords = learnedWords
            }
        }
        textDocumentProxy.insertText(" ")
        recentWord = ""
        updateCandidates()
        if KeyboardSettings.autoCapitalize && !isShiftLocked {
            let before = textDocumentProxy.documentContextBeforeInput ?? ""
            let trimmed = before.trimmingCharacters(in: .whitespacesAndNewlines)
            let nextUppercase = trimmed.isEmpty || [".", "!", "?"].contains(String(trimmed.suffix(1)))
            if nextUppercase != isUppercase {
                isUppercase = nextUppercase
                updateKeys()
            }
        }
    }
    @objc private func returnTapped() {
        beginTyping()
        tactileFeedback()
        textDocumentProxy.insertText("\n")
        recentWord = ""
        updateCandidates()
        if KeyboardSettings.autoCapitalize {
            isUppercase = true
            updateKeys()
        }
    }
    @objc private func deleteTapped() {
        beginTyping()
        tactileFeedback()
        textDocumentProxy.deleteBackward()
        if !recentWord.isEmpty { recentWord.removeLast() }
        updateCandidates()
    }

    @objc private func deleteWordGesture(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        beginTyping()
        tactileFeedback()
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        let reversed = before.reversed()
        let spaces = reversed.prefix(while: { $0.isWhitespace }).count
        let letters = reversed.dropFirst(spaces).prefix(while: { $0.isLetter || $0.isNumber }).count
        for _ in 0..<(spaces + max(1, letters)) { textDocumentProxy.deleteBackward() }
        recentWord = ""
        updateCandidates()
    }

    @objc private func shiftTapped() {
        tactileFeedback()
        if isUppercase { isShiftLocked.toggle() } else { isUppercase = true }
        if !isUppercase { isShiftLocked = false }
        updateKeys()
    }

    @objc private func numbersTapped() {
        tactileFeedback()
        isNumbers.toggle()
        recentWord = ""
        updateCandidates()
        updateKeys()
    }

    private func updateKeys() {
        let rows = isNumbers
            ? ["1234567890", "@#$%&*()-", "/:;!?.,"] : ["qwertyuiop", "asdfghjkl", "zxcvbnm"]
        for (rowIndex, row) in letterRows.enumerated() {
            let arranged = row.arrangedSubviews.compactMap { $0 as? UIButton }
            // Row 3 reserves first and last keys for Shift and Delete.
            let letterKeys = rowIndex == 2 ? Array(arranged.dropFirst().dropLast()) : arranged
            let characters = Array(rows[rowIndex]).map(String.init)
            for (index, button) in letterKeys.enumerated() {
                if index < characters.count {
                    let ch = characters[index]
                    button.setTitle(isNumbers ? ch : (isUppercase ? ch.uppercased() : ch), for: .normal)
                    button.isHidden = false
                } else {
                    button.isHidden = true
                }
            }
            if rowIndex == 2, let shift = arranged.first {
                configureIconOnly(shift, symbol: isShiftLocked ? "capslock.fill" : "shift.fill")
            }
        }
        if let bottom = secondaryRow, let numeric = bottom.arrangedSubviews.first as? UIButton {
            numeric.setTitle(isNumbers ? "ABC" : "123", for: .normal)
        }
    }

    @objc private func globeTapped() {
        tactileFeedback()
        advanceToNextInputMode()
    }

    @objc private func coupleTapped() {
        KeyboardSettings.coupleEnabled.toggle()
        updateCoupleTool()
        showStatus(KeyboardSettings.coupleEnabled
            ? "💗 Couple đã bật · Dán tin nhắn rồi nhấn ✦ AI"
            : "Đã chuyển sang trợ lý nhắn tin thông thường")
        tactileFeedback()
    }

    private func updateCoupleTool() {
        guard toolButtons.count > 1 else { return }
        styleToolbar()
        let button = toolButtons[1]
        button.accessibilityLabel = KeyboardSettings.coupleEnabled
            ? "AI Couple: " + CoupleStyleCatalog.active.title : "Bật AI Couple"
        button.accessibilityHint = "Chạm để bật/tắt. Nhấn giữ để chọn phong cách."
        installCoupleStyleMenu()
    }

    private func installCoupleStyleMenu() {
        guard toolButtons.count > 1 else { return }
        let selected = KeyboardSettings.coupleStyle
        let actions = CoupleStyleCatalog.styles.map { style -> UIAction in
            let action = UIAction(title: style.icon + " " + style.title) { [weak self] _ in
                KeyboardSettings.coupleEnabled = true
                KeyboardSettings.coupleStyle = style.id
                self?.updateCoupleTool()
                self?.showStatus("♥ Couple: " + style.title + " · Dán rồi nhấn ✦ AI")
            }
            action.state = style.id == selected ? .on : .off
            return action
        }
        toolButtons[1].menu = UIMenu(title: "Phong cách AI Couple", children: actions)
        toolButtons[1].showsMenuAsPrimaryAction = false
    }

    private func showStatus(_ message: String) {
        statusLabel.text = message
        statusLabel.isHidden = false
        updateKeyboardHeight()
    }

    private func updateAdaptiveLayout() {
        let spacing = CGFloat(KeyboardSettings.keySpacing)
        let height = CGFloat(KeyboardSettings.keyHeight)
        for row in letterRows { row.spacing = spacing }
        secondaryRow?.spacing = spacing
        for constraint in keyHeightConstraints { constraint.constant = height }
        let side = min(56, max(38, view.bounds.width * 0.12))
        switch KeyboardSettings.oneHandMode {
        case "left":
            keyboardLeadingConstraint?.constant = 4
            keyboardTrailingConstraint?.constant = -side
        case "right":
            keyboardLeadingConstraint?.constant = side
            keyboardTrailingConstraint?.constant = -4
        default:
            keyboardLeadingConstraint?.constant = 4
            keyboardTrailingConstraint?.constant = -4
        }
        updateKeyboardHeight()
    }

    private func updateCandidates(_ override: [String]? = nil) {
        let results = override ?? (useSuggestions
            ? SmartTyping.predictions(prefix: recentWord, learned: learnedWords) : [])
        let visible = !results.isEmpty
        candidateWords = results
        if candidateBar.isHidden == visible {
            candidateBar.isHidden = !visible
            updateKeyboardHeight()
        }
        for (index, button) in candidateButtons.enumerated() {
            button.setTitle(index < results.count ? results[index] : "", for: .normal)
            button.isEnabled = index < results.count
        }
    }

    @objc private func candidateTapped(_ sender: UIButton) {
        guard candidateWords.indices.contains(sender.tag) else { return }
        replaceCurrentWord(candidateWords[sender.tag])
        tactileFeedback()
    }

    private func replaceCurrentWord(_ replacement: String) {
        guard let before = textDocumentProxy.documentContextBeforeInput else { return }
        let current = String(before.reversed().prefix(while: { $0.isLetter }).reversed())
        guard current.count <= 40 else { return }
        if let edit = FastTyping.edit(from: current, to: replacement) {
            for _ in 0..<edit.deleteCount { textDocumentProxy.deleteBackward() }
            if !edit.insertion.isEmpty { textDocumentProxy.insertText(edit.insertion) }
        } else if current.isEmpty {
            textDocumentProxy.insertText(replacement)
        }
        recentWord = replacement
        updateCandidates()
    }

    @objc private func spaceCursorPanned(_ recognizer: UIPanGestureRecognizer) {
        let space = recognizer.view
        switch recognizer.state {
        case .began:
            cursorSteps = 0
        case .changed:
            let translation = recognizer.translation(in: space)
            let steps = Int(translation.x / 13)
            let move = steps - cursorSteps
            if move != 0 {
                textDocumentProxy.adjustTextPosition(byCharacterOffset: move)
                cursorSteps = steps
                tactileFeedback()
            }
        default:
            cursorSteps = 0
            recentWord = ""
            updateCandidates()
        }
    }

    private func letterUnder(_ position: CGPoint) -> String? {
        for key in letterButtons where !key.isHidden {
            if key.convert(key.bounds, to: view).contains(position),
               let name = key.title(for: .normal), name.count == 1 {
                return name.lowercased()
            }
        }
        return nil
    }

    private func captureGlidePoint(_ position: CGPoint) {
        guard let key = letterUnder(position), key != glideLastKey else { return }
        glideLastKey = key
        glidePath += key
    }

    @objc private func glidePanned(_ recognizer: UIPanGestureRecognizer) {
        guard useGlide, !isNumbers else { return }
        let point = recognizer.location(in: view)
        switch recognizer.state {
        case .began:
            glidePath = ""
            glideLastKey = ""
            glideIsActive = false
            let delta = recognizer.translation(in: view)
            let origin = CGPoint(x: point.x - delta.x, y: point.y - delta.y)
            captureGlidePoint(origin)
            captureGlidePoint(point)
        case .changed:
            captureGlidePoint(point)
            if glidePath.count >= 3 { glideIsActive = true }
        case .ended:
            captureGlidePoint(point)
            guard glideIsActive, glidePath.count >= 3 else { return }
            let suggestions = SmartTyping.glideCandidates(trace: glidePath)
            if !suggestions.isEmpty {
                // A swipe beginning on a character can have inserted that
                // initial character via touchDown. Only auto-replace a
                // one-character word, never overwrite an existing draft.
                let before = textDocumentProxy.documentContextBeforeInput ?? ""
                let current = String(before.reversed().prefix(while: { $0.isLetter }).reversed())
                if current.count == 1, suggestions[0].lowercased().hasPrefix(current.lowercased()) {
                    replaceCurrentWord(suggestions[0])
                } else {
                    updateCandidates(suggestions)
                }
            }
            glidePath = ""
            glideLastKey = ""
            glideIsActive = false
        default:
            glidePath = ""
            glideLastKey = ""
            glideIsActive = false
        }
    }

    private func updateKeyboardHeight() {
        // No permanently reserved blank AI area.
        let base: CGFloat = 240 + CGFloat(KeyboardSettings.keyHeight - 43) * 4
        heightConstraint?.constant = base +
            (candidateBar.isHidden ? 0 : 36) +
            (statusLabel.isHidden ? 0 : 22) +
            (suggestionContainer == nil ? 0 : 119)
        view.setNeedsLayout()
    }

    private func beginTyping() {
        // Once the user starts composing, do not analyze stale clipboard text.
        selectedText = ""
        if suggestionContainer != nil { clearSuggestions() }
        if !statusLabel.isHidden {
            statusLabel.isHidden = true
            updateKeyboardHeight()
        }
    }

    @objc private func dismissSuggestions() {
        clearSuggestions()
        statusLabel.isHidden = true
        updateKeyboardHeight()
    }

    @objc private func pasteTapped() {
        // Always-visible, real UIButton. Never replace it with a system control
        // that can disappear when iOS marks the pasteboard as unavailable.
        guard hasFullAccess else {
            showStatus("Bật Cho phép truy cập đầy đủ để dùng nút Dán")
            return
        }
        let clipboard = UIPasteboard.general
        guard clipboard.hasStrings else {
            showStatus("Chưa có văn bản · Hãy sao chép tin nhắn cần phân tích")
            return
        }
        guard let text = clipboard.string,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showStatus("Không đọc được clipboard. Kiểm tra quyền Dán trong Cài đặt.")
            return
        }
        selectedText = String(text.prefix(3000))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        clearSuggestions()
        let context = ConversationContextResolver.resolve(selectedText)
        showStatus("✓ Người nhận: " + context.displayName + " · Nhấn AI (giữ AI để đổi)")
    }

    private func requestedInput() -> String {
        let context = textDocumentProxy.documentContextBeforeInput ?? ""
        return selectedText.isEmpty ? String(context.suffix(3000)) : selectedText
    }

    @objc private func offlineTapped() {
        let text = requestedInput()
        guard !text.isEmpty else {
            showStatus("Dán tin nhắn cần trả lời trước")
            return
        }
        show(OfflineReplyEngine.suggest(for: text))
    }

    @objc private func cloudTapped() {
        guard !isRequestRunning else { return }
        guard hasFullAccess else {
            showStatus("Cần bật Full Access để gọi AI")
            return
        }
        let source = requestedInput().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !source.isEmpty else {
            showStatus("Chưa có tin nhắn để phân tích · Chạm Dán")
            return
        }
        isRequestRunning = true
        requestID = UUID()
        let currentRequestID = requestID
        let context = ConversationContextResolver.resolve(source)
        showStatus("AI đang phân tích · Người nhận: " + context.displayName)
        Task { [weak self] in
            do {
                let suggestions = try await AIService.reply(to: source)
                await MainActor.run {
                    guard let self, self.requestID == currentRequestID else { return }
                    self.isRequestRunning = false
                    self.show(suggestions)
                }
            } catch {
                await MainActor.run {
                    guard let self, self.requestID == currentRequestID else { return }
                    self.isRequestRunning = false
                    self.showStatus("AI lỗi: \(error.localizedDescription)")
                    // Do NOT silently replace an API error with offline suggestions.
                }
            }
        }
    }

    @objc private func phrasesTapped() {
        show(KeyboardSettings.savedPhrases.map { ReplySuggestion(tone: "Mẫu câu", text: $0) })
    }

    private func clearSuggestions() {
        if let old = suggestionContainer {
            container.removeArrangedSubview(old)
            old.removeFromSuperview()
            suggestionContainer = nil
        }
        lastSuggestions = []
        toneButtons = []
        previewLabel.text = nil
        previewLabel.isHidden = true
        updateKeyboardHeight()
    }

    private func coupleSymbol(_ tone: String, index: Int) -> String {
        let name = tone.folding(options: [.caseInsensitive, .diacriticInsensitive],
                                locale: Locale(identifier: "vi_VN"))
        if name.contains("ranh gioi") { return "hand.raised.fill" }
        if name.contains("lang nghe") { return "ear" }
        if name.contains("diu dang") || name.contains("ngot") { return "heart.fill" }
        if name.contains("quan tam") { return "leaf.fill" }
        if name.contains("de thuong") || name.contains("vui") { return "sparkles" }
        return ["sparkles", "heart", "bubble.left.fill"][index % 3]
    }

    private func show(_ items: [ReplySuggestion]) {
        clearSuggestions()
        lastSuggestions = Array(items.prefix(3))
        guard !lastSuggestions.isEmpty else {
            showStatus("Không có gợi ý. Thử tin nhắn khác.")
            return
        }
        chosenIndex = 0
        statusLabel.isHidden = true

        let panel = UIStackView()
        panel.axis = .vertical
        panel.spacing = 7
        panel.distribution = .fill
        panel.backgroundColor = .clear

        // All suggestions are compact chips. For saved phrases we display
        // "Mẫu 1 / 2 / 3" rather than three indistinguishable "Mẫu câu" buttons.
        let tones = UIStackView()
        tones.axis = .horizontal
        tones.alignment = .fill
        tones.spacing = 6
        tones.distribution = .fill
        toneButtons.removeAll()
        for (index, item) in lastSuggestions.enumerated() {
            let duplicate = lastSuggestions.filter { $0.tone == item.tone }.count > 1
            let shortTitle = item.tone == "Mẫu câu" ? "Mẫu" : item.tone
            let label = duplicate ? "\(shortTitle) \(index + 1)" : shortTitle
            let button = UIButton(type: .system)
            configureSymbolButton(button, title: label,
                                  symbol: coupleSymbol(item.tone, index: index),
                                  foreground: chromeInk, background: chromeSurface,
                                  fontSize: 11.5, iconSize: 11.5, padding: 5)
            button.tag = index
            button.addTarget(self, action: #selector(selectSuggestion(_:)), for: .touchUpInside)
            button.accessibilityLabel = "Chọn câu trả lời \(label)"
            button.setContentHuggingPriority(.defaultLow, for: .horizontal)
            button.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            if let first = toneButtons.first {
                button.widthAnchor.constraint(equalTo: first.widthAnchor).isActive = true
            }
            toneButtons.append(button)
            tones.addArrangedSubview(button)
        }

        let close = UIButton(type: .system)
        var closeConfig = UIButton.Configuration.plain()
        closeConfig.image = UIImage(
            systemName: "xmark",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        )
        closeConfig.contentInsets = NSDirectionalEdgeInsets(
            top: 7, leading: 7, bottom: 7, trailing: 7
        )
        closeConfig.baseForegroundColor = chromeInk
        closeConfig.background.backgroundColor = chromeSurface
        closeConfig.cornerStyle = .medium
        close.configuration = closeConfig
        close.layer.cornerRadius = 11
        close.layer.cornerCurve = .continuous
        close.layer.borderWidth = 0.75
        close.layer.borderColor = chromeStroke.cgColor
        close.clipsToBounds = true
        close.accessibilityLabel = "Đóng gợi ý"
        close.addTarget(self, action: #selector(dismissSuggestions), for: .touchUpInside)
        close.widthAnchor.constraint(equalToConstant: 34).isActive = true
        tones.addArrangedSubview(close)
        tones.heightAnchor.constraint(equalToConstant: 32).isActive = true
        panel.addArrangedSubview(tones)

        // Restrained secondary actions; only "Chèn" has a primary fill.
        let actions = UIStackView()
        actions.axis = .horizontal
        actions.spacing = 6
        actions.distribution = .fillEqually
        let specs: [(String, String, Selector)] = [
            ("Sao chép", "doc.on.doc", #selector(copySuggestion)),
            ("Lưu", "bookmark", #selector(saveSuggestion)),
            ("Thay", "arrow.triangle.2.circlepath", #selector(replaceDraft)),
            ("Chèn", "plus", #selector(insertSuggestion))
        ]
        for (index, spec) in specs.enumerated() {
            let button = UIButton(type: .system)
            configureSymbolButton(button, title: spec.0, symbol: spec.1,
                                  foreground: index == 3 ? .white : chromeInk,
                                  background: index == 3 ? chromePrimary : chromeSurface,
                                  fontSize: 11, iconSize: 12, padding: 3)
            if index == 3 { button.layer.borderWidth = 0 }
            button.addTarget(self, action: spec.2, for: .touchUpInside)
            actions.addArrangedSubview(button)
        }
        actions.heightAnchor.constraint(equalToConstant: 36).isActive = true
        panel.addArrangedSubview(actions)

        suggestionContainer = panel
        container.insertArrangedSubview(panel, at: 3)
        updatePreview()
        updateToneStyles()
        updateKeyboardHeight()
    }

    private func updatePreview() {
        guard lastSuggestions.indices.contains(chosenIndex) else { return }
        // InsetLabel handles real padding, avoiding a large emoji badge and
        // preventing text from touching the edges of the preview surface.
        previewLabel.text = lastSuggestions[chosenIndex].text
        previewLabel.isHidden = false
    }

    private func updateToneStyles() {
        for (index, button) in toneButtons.enumerated() {
            guard var config = button.configuration else { continue }
            let selected = index == chosenIndex
            config.baseForegroundColor = selected ? .white : chromeInk
            config.background.backgroundColor = selected ? chromePrimary : chromeSurface
            button.configuration = config
            button.layer.borderColor = selected
                ? UIColor.clear.cgColor : chromeStroke.cgColor
            button.layer.borderWidth = selected ? 0 : 0.75
        }
    }

    @objc private func selectSuggestion(_ sender: UIButton) {
        guard lastSuggestions.indices.contains(sender.tag) else { return }
        chosenIndex = sender.tag
        haptic.impactOccurred(intensity: 0.55)
        updatePreview()
        updateToneStyles()
    }

    private func selectedReply() -> String? {
        guard lastSuggestions.indices.contains(chosenIndex) else { return nil }
        let text = lastSuggestions[chosenIndex].text.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : text
    }

    @objc private func copySuggestion() {
        guard let answer = selectedReply() else { return }
        guard hasFullAccess else {
            showStatus("Bật Full Access để sao chép")
            return
        }
        UIPasteboard.general.string = answer
        showStatus("Đã sao chép CHỈ câu trả lời, không kèm tin gốc")
    }

    @objc private func saveSuggestion() {
        guard let answer = selectedReply() else { return }
        var items = KeyboardSettings.favoriteReplies
        if !items.contains(answer) {
            items.insert(answer, at: 0)
            KeyboardSettings.favoriteReplies = items
        }
        showStatus("✓ Đã lưu vào thư viện câu trả lời")
    }

    @objc private func replaceDraft() {
        guard let answer = selectedReply() else { return }
        // Prevent deleting unrelated content after the caret, or deleting
        // incomplete context exposed by secure/restricted third-party fields.
        guard textDocumentProxy.selectedText == nil,
              let before = textDocumentProxy.documentContextBeforeInput,
              (textDocumentProxy.documentContextAfterInput ?? "").isEmpty,
              before.count <= 2000 else {
            showStatus("Không thể thay an toàn · Chọn Sao chép rồi tự dán")
            return
        }
        for _ in before { textDocumentProxy.deleteBackward() }
        textDocumentProxy.insertText(answer)
        dismissSuggestions()
        showStatus("Đã thay bản nháp bằng CHỈ câu trả lời")
    }

    @objc private func insertSuggestion() {
        guard let answer = selectedReply() else { return }
        textDocumentProxy.insertText(answer)
        dismissSuggestions()
        showStatus("Đã chèn chỉ câu trả lời vào ô soạn")
    }
}
