import UIKit

/// ViePN keyboard: composing a suggested reply never writes the source message
/// to the host chat field. All host-field modifications are explicit user taps.
final class KeyboardViewController: UIInputViewController {
    private let container = UIStackView()
    private let statusLabel = UILabel()
    private let previewLabel = UILabel()
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
    private var currentTheme: String = ""
    private let aiGradient = CAGradientLayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        buildKeyboard()
        applyTheme()
        haptic.prepare()
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        if currentTheme != KeyboardSettings.theme { applyTheme() }
        // Avoid erasing the reply when the host app changes text focus.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyTheme()
        updateCoupleTool()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if toolButtons.count > 2 { aiGradient.frame = toolButtons[2].bounds }
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
        container.spacing = 5
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
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
        commands.spacing = 4
        commands.distribution = .fillEqually
        commands.alignment = .fill
        let tools: [(String, String, Selector)] = [
            ("Dán", "doc.on.clipboard", #selector(pasteTapped)),
            ("Couple", "heart.fill", #selector(coupleTapped)),
            ("AI", "sparkles", #selector(cloudTapped)),
            ("Offline", "wifi.slash", #selector(offlineTapped)),
            ("Mẫu", "text.quote", #selector(phrasesTapped))
        ]
        for (index, spec) in tools.enumerated() {
            let button = UIButton(type: .system)
            let foreground: UIColor = index == 0 ? aiColor :
                (index == 1 ? UIColor(red: 0.62, green: 0.18, blue: 0.44, alpha: 1) :
                    (index == 2 ? .white : UIColor(red: 0.19, green: 0.29, blue: 0.32, alpha: 1)))
            let background: UIColor = index == 0 ? .white :
                (index == 1 ? UIColor(red: 0.98, green: 0.89, blue: 0.93, alpha: 1) :
                    (index == 2 ? aiColor : UIColor(red: 0.89, green: 0.94, blue: 0.94, alpha: 1)))
            configureSymbolButton(button, title: spec.0, symbol: spec.1,
                                  foreground: foreground, background: background)
            button.addTarget(self, action: spec.2, for: .touchUpInside)
            button.layer.shadowColor = UIColor.black.cgColor
            button.layer.shadowOpacity = 0.08
            button.layer.shadowRadius = 2
            button.layer.shadowOffset = CGSize(width: 0, height: 1)
            if index == 2 {
                aiGradient.colors = [
                    UIColor(red: 0.28, green: 0.45, blue: 0.98, alpha: 1).cgColor,
                    UIColor(red: 0.64, green: 0.30, blue: 0.93, alpha: 1).cgColor
                ]
                aiGradient.startPoint = CGPoint(x: 0, y: 0)
                aiGradient.endPoint = CGPoint(x: 1, y: 1)
                aiGradient.cornerRadius = 11
                button.layer.insertSublayer(aiGradient, at: 0)
            }
            toolButtons.append(button)
            commands.addArrangedSubview(button)
        }
        commands.heightAnchor.constraint(equalToConstant: 37).isActive = true
        container.addArrangedSubview(commands)
        installWritingActions()
        updateCoupleTool()

        previewLabel.numberOfLines = 2
        previewLabel.font = .systemFont(ofSize: 14, weight: .medium)
        previewLabel.textColor = .label
        previewLabel.textAlignment = .left
        previewLabel.backgroundColor = .secondarySystemBackground
        previewLabel.layer.cornerRadius = 15
        previewLabel.layer.borderWidth = 1
        previewLabel.layer.borderColor = aiColor.withAlphaComponent(0.35).cgColor
        previewLabel.clipsToBounds = true
        previewLabel.isHidden = true
        previewLabel.heightAnchor.constraint(equalToConstant: 45).isActive = true
        container.addArrangedSubview(previewLabel)

        let rows = ["qwertyuiop", "asdfghjkl", "zxcvbnm"]
        for (rowIndex, letters) in rows.enumerated() {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 4
            row.alignment = .fill
            row.distribution = .fillEqually
            if rowIndex == 1 {
                row.layoutMargins = UIEdgeInsets(top: 0, left: 17, bottom: 0, right: 17)
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
            row.heightAnchor.constraint(equalToConstant: 43).isActive = true
            letterRows.append(row)
            container.addArrangedSubview(row)
        }

        // Large spacebar, separate punctuation, globe and return as in iOS.
        let bottom = UIStackView()
        bottom.axis = .horizontal
        bottom.spacing = 4
        bottom.distribution = .fill
        bottom.alignment = .fill

        let numeric = keyButton("123", action: #selector(numbersTapped))
        let globe = keyButton("", action: #selector(globeTapped))
        configureIconOnly(globe, symbol: "globe", size: 20)
        let comma = keyButton(",", action: #selector(punctuationTapped(_:)))
        let space = keyButton("dấu cách", action: #selector(spaceTapped))
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
        bottom.heightAnchor.constraint(equalToConstant: 43).isActive = true
        secondaryRow = bottom
        container.addArrangedSubview(bottom)
        updateKeys()
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
        toolButtons[2].menu = UIMenu(title: "AI viết lại & dịch", children: actions)
        toolButtons[2].showsMenuAsPrimaryAction = false
        toolButtons[2].accessibilityHint = "Chạm để trả lời; nhấn giữ để sửa câu, dịch hoặc viết lại."
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
    private func configureSymbolButton(_ button: UIButton, title: String, symbol: String,
                                       foreground: UIColor, background: UIColor) {
        var config = UIButton.Configuration.plain()
        config.title = title
        config.image = UIImage(systemName: symbol,
                               withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold))
                    ?? UIImage(systemName: "circle.fill")
        config.imagePlacement = .leading
        config.imagePadding = 5
        config.contentInsets = NSDirectionalEdgeInsets(top: 7, leading: 4, bottom: 7, trailing: 4)
        config.baseForegroundColor = foreground
        config.background.backgroundColor = background
        config.cornerStyle = .medium
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var result = incoming
            result.font = .systemFont(ofSize: 11, weight: .semibold)
            return result
        }
        button.configuration = config
        button.accessibilityLabel = title
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
        // Do not overwrite the colored Couple and AI buttons or the Paste selector.
        for index in [3, 4] where index < toolButtons.count {
            if var config = toolButtons[index].configuration {
                config.background.backgroundColor = keyColor
                config.baseForegroundColor = primary
                toolButtons[index].configuration = config
            }
        }
        previewLabel.backgroundColor = keyColor
        previewLabel.textColor = primary
        statusLabel.textColor = primary
    }

    private func tactileFeedback() {
        if KeyboardSettings.hapticEnabled { haptic.impactOccurred(intensity: 0.4) }
    }

    @objc private func punctuationTapped(_ sender: UIButton) {
        beginTyping()
        guard let character = sender.title(for: .normal) else { return }
        textDocumentProxy.insertText(character)
    }

    @objc private func letterTapped(_ sender: UIButton) {
        beginTyping()
        guard let title = sender.title(for: .normal) else { return }
        let key = isUppercase && !isNumbers ? title.uppercased() : title
        tactileFeedback()
        if !isNumbers && KeyboardSettings.typingMode == "telex" && KeyboardSettings.telexEnabled,
           let before = textDocumentProxy.documentContextBeforeInput {
            // A Telex suffix modifies only the last word before the caret.
            let word = String(before.reversed().prefix(while: { $0.isLetter }).reversed())
            if !word.isEmpty,
               let converted = VietnameseTelex.transformed(word: word, key: key),
               converted != word {
                for _ in word { textDocumentProxy.deleteBackward() }
                textDocumentProxy.insertText(converted)
                if isUppercase && !isShiftLocked {
                    isUppercase = false
                    updateKeys()
                }
                return
            }
        }
        if isNumbers && KeyboardSettings.typingMode == "vni",
           let before = textDocumentProxy.documentContextBeforeInput {
            let word = String(before.reversed().prefix(while: { $0.isLetter }).reversed())
            if !word.isEmpty,
               let result = VietnameseVNI.transformed(word: word, key: key),
               result != word {
                for _ in word { textDocumentProxy.deleteBackward() }
                textDocumentProxy.insertText(result)
                return
            }
        }
        textDocumentProxy.insertText(key)
        if isUppercase && !isShiftLocked {
            isUppercase = false
            updateKeys()
        }
    }

    @objc private func spaceTapped() {
        beginTyping()
        tactileFeedback()
        if let context = textDocumentProxy.documentContextBeforeInput {
            let word = String(context.reversed().prefix(while: { $0.isLetter }).reversed())
            if let replacement = KeyboardSettings.replacementDictionary[word.lowercased()],
               !word.isEmpty, word.count <= 30 {
                for _ in word { textDocumentProxy.deleteBackward() }
                textDocumentProxy.insertText(replacement)
            }
        }
        textDocumentProxy.insertText(" ")
        if KeyboardSettings.autoCapitalize && !isShiftLocked {
            let before = textDocumentProxy.documentContextBeforeInput ?? ""
            let trimmed = before.trimmingCharacters(in: .whitespacesAndNewlines)
            isUppercase = trimmed.isEmpty || [".", "!", "?"].contains(String(trimmed.suffix(1)))
            updateKeys()
        }
    }
    @objc private func returnTapped() {
        beginTyping()
        textDocumentProxy.insertText("\n")
        if KeyboardSettings.autoCapitalize {
            isUppercase = true
            updateKeys()
        }
    }
    @objc private func deleteTapped() { beginTyping(); tactileFeedback(); textDocumentProxy.deleteBackward() }

    @objc private func deleteWordGesture(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        beginTyping()
        tactileFeedback()
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        let reversed = before.reversed()
        let spaces = reversed.prefix(while: { $0.isWhitespace }).count
        let letters = reversed.dropFirst(spaces).prefix(while: { $0.isLetter || $0.isNumber }).count
        for _ in 0..<(spaces + max(1, letters)) { textDocumentProxy.deleteBackward() }
    }

    @objc private func shiftTapped() {
        if isUppercase { isShiftLocked.toggle() } else { isUppercase = true }
        if !isUppercase { isShiftLocked = false }
        updateKeys()
    }

    @objc private func numbersTapped() {
        isNumbers.toggle()
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

    @objc private func globeTapped() { advanceToNextInputMode() }

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
        let button = toolButtons[1]
        let active = KeyboardSettings.coupleEnabled
        if var config = button.configuration {
            config.title = "Couple"
            config.image = UIImage(systemName: active ? "heart.fill" : "heart",
                                   withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold))
            config.baseForegroundColor = active ? .white :
                UIColor(red: 0.62, green: 0.18, blue: 0.44, alpha: 1)
            config.background.backgroundColor = active
                ? UIColor(red: 0.85, green: 0.26, blue: 0.56, alpha: 1)
                : UIColor(red: 0.98, green: 0.89, blue: 0.93, alpha: 1)
            button.configuration = config
        }
        button.accessibilityLabel = active
            ? "AI Couple: " + CoupleStyleCatalog.active.title : "Bật AI Couple"
        button.accessibilityHint = "Chạm để bật/tắt. Nhấn giữ để chọn một trong các phong cách."
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

    private func updateKeyboardHeight() {
        // No permanently reserved blank AI area.
        let base: CGFloat = 240
        heightConstraint?.constant = base +
            (statusLabel.isHidden ? 0 : 22) +
            (suggestionContainer == nil ? 0 : 127)
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
        showStatus("✓ Đã nhận tin nhắn · Bấm ✦ AI để phân tích")
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
        showStatus("AI đang gợi ý câu trả lời...")
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
        panel.spacing = 5
        panel.distribution = .fill
        panel.backgroundColor = .clear

        let tones = UIStackView()
        tones.axis = .horizontal
        tones.spacing = 4
        tones.distribution = .fillEqually
        toneButtons.removeAll()

        for (index, item) in lastSuggestions.enumerated() {
            let button = keyButton(item.tone, action: #selector(selectSuggestion(_:)))
            let toneSymbol = coupleSymbol(item.tone, index: index)
            button.setImage(UIImage(systemName: toneSymbol,
                                   withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)),
                            for: .normal)
            button.tintColor = aiColor
            button.semanticContentAttribute = .forceLeftToRight
            button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 0)
            button.tag = index
            button.layer.cornerRadius = 10
            button.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
            button.accessibilityLabel = "Chọn câu trả lời \(item.tone)"
            toneButtons.append(button)
            tones.addArrangedSubview(button)
        }
        let close = keyButton("×", action: #selector(dismissSuggestions))
        close.titleLabel?.font = .systemFont(ofSize: 20, weight: .medium)
        close.backgroundColor = UIColor.systemGray4
        close.widthAnchor.constraint(equalToConstant: 33).isActive = true
        tones.distribution = .fill
        for button in toneButtons { button.setContentHuggingPriority(.defaultLow, for: .horizontal) }
        tones.addArrangedSubview(close)
        tones.heightAnchor.constraint(equalToConstant: 33).isActive = true
        panel.addArrangedSubview(tones)

        let actions = makeRow([
            ("Sao chép", #selector(copySuggestion)),
            ("Lưu", #selector(saveSuggestion)),
            ("Thay", #selector(replaceDraft)),
            ("Chèn", #selector(insertSuggestion))
        ], height: 34)
        if let row = actions as? UIStackView {
            for (index, item) in row.arrangedSubviews.enumerated() {
                guard let button = item as? UIButton else { continue }
                button.layer.cornerRadius = 10
                button.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
                let icons = ["doc.on.doc", "bookmark", "arrow.triangle.2.circlepath", "plus"]
                button.setImage(UIImage(systemName: icons[index],
                                        withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)),
                                for: .normal)
                button.tintColor = .label
                if index == 0 || index == 2 {
                    button.backgroundColor = index == 0 ? cyanColor : aiColor
                    button.setTitleColor(.white, for: .normal)
                    button.tintColor = .white
                }
            }
        }
        panel.addArrangedSubview(actions)

        suggestionContainer = panel
        container.insertArrangedSubview(panel, at: 3)
        updatePreview()
        updateToneStyles()
        updateKeyboardHeight()
    }

    private func updatePreview() {
        guard lastSuggestions.indices.contains(chosenIndex) else { return }
        previewLabel.text = "  " + (KeyboardSettings.coupleEnabled ? "♥" : "✦") + "  " + lastSuggestions[chosenIndex].text
        previewLabel.isHidden = false
    }

    private func updateToneStyles() {
        for (index, button) in toneButtons.enumerated() {
            let chosen = index == chosenIndex
            button.backgroundColor = chosen ? aiColor : UIColor { trait in
                trait.userInterfaceStyle == .dark ? UIColor(white: 0.24, alpha: 1) : .white
            }
            button.setTitleColor(chosen ? .white : .label, for: .normal)
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
