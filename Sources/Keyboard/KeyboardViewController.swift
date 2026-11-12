import UIKit
import AudioToolbox

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
    private var lastVibrationAt: CFTimeInterval = 0
    // Read App Group preferences when the keyboard opens rather than on each key.
    private var typingMode = KeyboardSettings.typingMode
    private var telexEnabled = KeyboardSettings.telexEnabled
    private var hapticsEnabled = KeyboardSettings.hapticEnabled
    private var hapticsStyle = KeyboardSettings.hapticStyle
    private var useSmartBilingual = KeyboardSettings.smartBilingual
    private var useSuggestions = KeyboardSettings.predictionsEnabled
    private var useGlide = KeyboardSettings.glideEnabled
    private var adaptiveTouchEnabled = KeyboardSettings.adaptiveTouchEnabled
    private var lastWordReplacement: (original: String, corrected: String)?
    private var learnedWords: [String: Int] = [:]
    private var recentWord = ""
    private var typingTouchCount: UInt64 = 0
    // Set only after this keyboard inserts a word boundary. The next letter
    // can start a new composition without asking the host for its text context.
    private var knownWordBoundary = false
    // Original physical keys and displayed word are tracked separately.
    // This allows a partial English prefix to become Vietnamese later,
    // or a Vietnamese-looking prefix to resolve back to English.
    private var rawComposingWord = ""
    private var displayedComposingWord = ""
    // Cached incremental candidate avoids reconstructing the word after
    // every touch (formerly replayed Telex over its entire history).
    private var telexCandidateWord = ""
    private var candidateUpdateWork: DispatchWorkItem?
    // A monotonically increasing generation prevents stale suggestions from
    // appearing after deletion or when the same prefix is typed again.
    private var candidateGeneration: UInt64 = 0
    private var cachedSnippets: [String: String] = [:]
    private var cachedReplacements: [String: String] = [:]
    private var autocapitalizeEnabled = true
    private var learnWordsEnabled = false
    private var bilingualPreference: BilingualComposer.Preference = .automatic

    private func resetBilingualComposition() {
        rawComposingWord = ""
        displayedComposingWord = ""
        telexCandidateWord = ""
    }
    private let candidateBar = UIStackView()
    private var candidateButtons: [UIButton] = []
    private var candidateWords: [String] = []
    private var keyboardLeadingConstraint: NSLayoutConstraint?
    private var keyboardTrailingConstraint: NSLayoutConstraint?
    private var keyHeightConstraints: [NSLayoutConstraint] = []
    private var glidePath = ""
    private var glideLastKey = ""
    private var glideIsActive = false
    private var glideRecognizer: UIPanGestureRecognizer?
    private var glideTouchOrigin: CGPoint?
    private var cursorSteps = 0

    private func refreshTypingPreferences() {
        typingMode = KeyboardSettings.typingMode
        telexEnabled = KeyboardSettings.telexEnabled
        hapticsEnabled = KeyboardSettings.hapticEnabled
        hapticsStyle = KeyboardSettings.hapticStyle
        useSmartBilingual = KeyboardSettings.smartBilingual
        bilingualPreference = BilingualComposer.Preference(
            rawValue: KeyboardSettings.bilingualPreference) ?? .automatic
        resetBilingualComposition()
        knownWordBoundary = false
        useSuggestions = KeyboardSettings.predictionsEnabled
        useGlide = KeyboardSettings.glideEnabled
        adaptiveTouchEnabled = KeyboardSettings.adaptiveTouchEnabled
        learnedWords = KeyboardSettings.learnedWords
        cachedSnippets = KeyboardSettings.textSnippets
        cachedReplacements = KeyboardSettings.replacementDictionary
        autocapitalizeEnabled = KeyboardSettings.autoCapitalize
        learnWordsEnabled = KeyboardSettings.autoLearnWords
    }
    private var currentTheme: String = ""
    private let aiGradient = CAGradientLayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        refreshTypingPreferences()
        buildKeyboard()
        applyTheme()
        if hapticsEnabled && hapticsStyle == "light" { haptic.prepare() }
        // Build dictionaries off the main thread so the first keys are not slow.
        DispatchQueue.global(qos: .userInitiated).async { SmartTyping.warmUp() }
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        if currentTheme != KeyboardSettings.theme { applyTheme() }
        // Do not reset composition here: iOS may call textDidChange for
        // normal inserts made by this keyboard, not only external edits.
        // Destructive rewrites are independently guarded by host suffix checks.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshTypingPreferences()
        candidateBar.isHidden = !useSuggestions
        applyTheme()
        updateAdaptiveLayout()
        updateAdaptiveTouchTargets()
        configureGlideRecognizer()
        updateCoupleTool()
        installWritingActions()
        installClipboardMenu()
        updateCandidates()
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
        installClipboardMenu()
        updateCoupleTool()

        previewLabel.numberOfLines = 2
        previewLabel.font = .systemFont(ofSize: 14, weight: .medium)
        previewLabel.textColor = .label
        previewLabel.textAlignment = .left
        previewLabel.backgroundColor = .secondarySystemBackground
        previewLabel.layer.cornerRadius = 12
        previewLabel.layer.borderWidth = 1
        previewLabel.layer.borderColor = UIColor.separator.withAlphaComponent(0.4).cgColor
        previewLabel.clipsToBounds = true
        previewLabel.isHidden = true
        previewLabel.heightAnchor.constraint(equalToConstant: 45).isActive = true
        container.addArrangedSubview(previewLabel)

        candidateBar.axis = .horizontal
        candidateBar.spacing = 5
        candidateBar.distribution = .fillEqually
        // A fixed suggestion row prevents keyboard geometry from jumping
        // while words are typed, and avoids expensive layout passes per key.
        candidateBar.isHidden = !useSuggestions
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
        // Install once regardless of the setting's initial value. A user
        // enabling swipe later must not need a fresh keyboard controller.
        configureGlideRecognizer()
        updateKeys()
        updateAdaptiveLayout()
        updateAdaptiveTouchTargets()
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
        let importDraft = UIAction(
            title: "Lấy bản nháp từ ứng dụng ViePN",
            image: UIImage(systemName: "square.and.arrow.down")
        ) { [weak self] _ in
            let draft = ShareDraft.current
            guard !draft.isEmpty else {
                self?.showStatus("Chưa có bản nháp · Mở tab Trợ lý để tạo.")
                return
            }
            self?.selectedText = draft
            self?.showStatus("Đã nhận bản nháp · Nhấn AI để tạo câu trả lời")
        }
        let privacyAction = UIAction(
            title: "Ẩn dữ liệu nhạy cảm rồi hỏi AI",
            image: UIImage(systemName: "hand.raised.slash")
        ) { [weak self] _ in
            guard let self else { return }
            let text = self.requestedInput()
            guard !text.isEmpty else {
                self.showStatus("Chưa có văn bản để xử lý.")
                return
            }
            self.selectedText = MessageSafety.redacted(text)
            self.cloudTapped()
        }
        let undoAction = UIAction(title: "Hoàn tác sửa từ",
                                  image: UIImage(systemName: "arrow.uturn.backward")) { [weak self] _ in
            self?.undoWordCorrection()
        }
        let variantsAction = UIAction(title: "Viết lại · 3 phiên bản",
                                      image: UIImage(systemName: "square.stack.3d.up")) { [weak self] _ in
            self?.performWritingVariants()
        }
        toolButtons[2].menu = UIMenu(
            title: "AI · Vai xưng hô và viết lại",
            children: [receiverMenu, profileMenu, importDraft, privacyAction,
                       undoAction, variantsAction] + actions
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
        if !MessageSafety.warnings(in: source).isEmpty {
            showStatus("Có dữ liệu nhạy cảm · Mở tab Trợ lý để ẩn rồi xử lý.")
            return
        }
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

    private func performWritingVariants() {
        guard !isRequestRunning else { return }
        guard hasFullAccess else { showStatus("Cần Full Access để dùng AI"); return }
        let source = selectedText.isEmpty
            ? (textDocumentProxy.documentContextBeforeInput ?? "") : selectedText
        guard !source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showStatus("Hãy nhập hoặc Dán nội dung trước khi dùng AI")
            return
        }
        guard MessageSafety.warnings(in: source).isEmpty else {
            showStatus("Có dữ liệu nhạy cảm · Hãy ẩn thông tin trước khi gửi AI")
            return
        }
        isRequestRunning = true
        let activeID = UUID()
        requestID = activeID
        showStatus("Đang tạo 3 phiên bản để bạn chọn")
        Task { [weak self] in
            do {
                let texts = try await AIWritingService.transformVariants(source)
                await MainActor.run {
                    guard let self, self.requestID == activeID else { return }
                    self.isRequestRunning = false
                    let labels = ["Tự nhiên", "Lịch sự", "Ngắn gọn"]
                    self.show(texts.enumerated().map {
                        ReplySuggestion(tone: labels[$0.offset], text: $0.element)
                    })
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
        let button = AdaptiveKeyButton(type: .system)
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
        resetBilingualComposition()
        textDocumentProxy.insertText(character)
        knownWordBoundary = true
        recentWord = ""
        updateCandidates()
    }

    @objc private func letterTapped(_ sender: UIButton) {
        guard let title = sender.title(for: .normal) else { return }
        // Sample every 50th touch without invoking a random-number generator
        // on the input latency-critical path.
        typingTouchCount &+= 1
        let sample = typingTouchCount % 50 == 0
        let startedAt = sample ? CACurrentMediaTime() : 0
        defer {
            if sample {
                KeyboardStability.note("typing", durationMs:
                    (CACurrentMediaTime() - startedAt) * 1000)
            }
        }
        beginTyping()
        let key = isUppercase && !isNumbers ? title.uppercased() : title

        if !isNumbers && typingMode == "telex" && telexEnabled,
           key.count == 1, key.first?.isLetter == true {
            // If another app edited or moved the caret, do not touch its
            // existing text. Check the host suffix before destructive edits.
            if rawComposingWord.isEmpty, !knownWordBoundary,
               let context = textDocumentProxy.documentContextBeforeInput {
                let existing = String(context.reversed()
                    .prefix(while: { $0.isLetter }).reversed())
                if !existing.isEmpty && existing.count <= 40 {
                    rawComposingWord = existing
                    displayedComposingWord = existing
                    telexCandidateWord = existing
                }
            }
            knownWordBoundary = false
            let rawNext = rawComposingWord + key
            if rawNext.count <= 40 {
                let preference: BilingualComposer.Preference =
                    useSmartBilingual ? bilingualPreference : .vietnamese
                // One transformation step, not O(word length²) replay.
                let nextTelex = BilingualComposer.appendCandidate(
                    telexCandidateWord, key: key)
                let newWord = BilingualComposer.choose(
                    raw: rawNext, vietnameseCandidate: nextTelex,
                    preference: preference).rendered
                if let edit = FastTyping.edit(from: displayedComposingWord, to: newWord) {
                    if edit.deleteCount > 0 {
                        let current = textDocumentProxy.documentContextBeforeInput ?? ""
                        // Never delete text that is no longer the composing word.
                        guard !displayedComposingWord.isEmpty,
                              current.hasSuffix(displayedComposingWord) else {
                            resetBilingualComposition()
                            textDocumentProxy.insertText(key)
                            recentWord = key
                            updateCandidates()
                            tactileFeedback()
                            return
                        }
                        for _ in 0..<edit.deleteCount {
                            textDocumentProxy.deleteBackward()
                        }
                    }
                    if !edit.insertion.isEmpty {
                        textDocumentProxy.insertText(edit.insertion)
                    }
                    rawComposingWord = rawNext
                    telexCandidateWord = nextTelex
                    displayedComposingWord = newWord
                    recentWord = newWord
                    if isUppercase && !isShiftLocked {
                        isUppercase = false
                        updateKeys()
                    }
                    updateCandidates()
                    tactileFeedback()
                    return
                }
                // A literal key must never disappear just because the
                // composer returned an unchanged rendering (for example,
                // repeated tone keys or an already-accented syllable).
                // This branch previously swallowed the touch entirely.
                textDocumentProxy.insertText(key)
                rawComposingWord = rawNext
                // Keep the internal Vietnamese candidate independent of the
                // literal display; adding the key a second time corrupts later
                // auto-language decisions (e.g. repeated tone modifiers).
                telexCandidateWord = nextTelex
                displayedComposingWord += key
                recentWord = displayedComposingWord
                if isUppercase && !isShiftLocked {
                    isUppercase = false
                    updateKeys()
                }
                updateCandidates()
                tactileFeedback()
                return
            }
            resetBilingualComposition()
        } else {
            resetBilingualComposition()
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
        knownWordBoundary = false
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
        resetBilingualComposition()
        beginTyping()
        tactileFeedback()
        if let context = textDocumentProxy.documentContextBeforeInput {
            let token = String(context.reversed().prefix(while: {
                $0.isLetter || $0.isNumber || $0 == ";" || $0 == "_"
            }).reversed())
            let word = String(context.reversed().prefix(while: { $0.isLetter }).reversed())
            if let snippet = cachedSnippets[token], !token.isEmpty {
                for _ in token { textDocumentProxy.deleteBackward() }
                textDocumentProxy.insertText(SmartTyping.expandSnippet(
                    snippet, recipient: PersonaStore.active?.name))
            } else if let replacement = cachedReplacements[word.lowercased()],
                      !word.isEmpty, word.count <= 30 {
                for _ in word { textDocumentProxy.deleteBackward() }
                textDocumentProxy.insertText(replacement)
            } else if learnWordsEnabled && word.count >= 3 && word.count <= 24 {
                let normalized = word.lowercased()
                learnedWords[normalized, default: 0] += 1
                KeyboardSettings.learnedWords = learnedWords
            }
        }
        textDocumentProxy.insertText(" ")
        knownWordBoundary = true
        recentWord = ""
        updateCandidates()
        if autocapitalizeEnabled && !isShiftLocked {
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
        resetBilingualComposition()
        beginTyping()
        tactileFeedback()
        textDocumentProxy.insertText("\n")
        knownWordBoundary = true
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
        knownWordBoundary = false
        if !rawComposingWord.isEmpty {
            let preference: BilingualComposer.Preference =
                useSmartBilingual ? bilingualPreference : .vietnamese
            let priorRaw = String(rawComposingWord.dropLast())
            let prior = BilingualComposer.removingLastKey(
                from: rawComposingWord, preference: preference).rendered
            if let edit = FastTyping.edit(from: displayedComposingWord, to: prior) {
                // A multi-character rewrite is only safe if the host still
                // ends with the exact word this keyboard previously inserted.
                // Plain single-character backspace keeps the native fast path.
                let plainDelete = edit.deleteCount == 1 && edit.insertion.isEmpty
                let safe = plainDelete || (
                    !displayedComposingWord.isEmpty
                    && (textDocumentProxy.documentContextBeforeInput ?? "")
                        .hasSuffix(displayedComposingWord))
                if safe {
                    for _ in 0..<edit.deleteCount { textDocumentProxy.deleteBackward() }
                    if !edit.insertion.isEmpty {
                        textDocumentProxy.insertText(edit.insertion)
                    }
                    rawComposingWord = priorRaw
                    displayedComposingWord = prior
                    telexCandidateWord = VietnameseTelex.composeKeys(priorRaw)
                    recentWord = prior
                    updateCandidates()
                    return
                }
            }
        }
        // Host context changed or no active composition: native deletion.
        resetBilingualComposition()
        textDocumentProxy.deleteBackward()
        if !recentWord.isEmpty { recentWord.removeLast() }
        updateCandidates()
    }

    @objc private func deleteWordGesture(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        resetBilingualComposition()
        knownWordBoundary = false
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
        resetBilingualComposition()
        knownWordBoundary = false
        tactileFeedback()
        isNumbers.toggle()
        configureGlideRecognizer()
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
        resetBilingualComposition()
        knownWordBoundary = false
        tactileFeedback()
        advanceToNextInputMode()
    }

    @objc private func coupleTapped() {
        let startedAt = CACurrentMediaTime()
        defer { KeyboardStability.note("couple", durationMs:
            (CACurrentMediaTime() - startedAt) * 1000) }
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
        // Prediction sorting and keyboard-height changes happen after a
        // short typing pause, not synchronously for every physical key.
        // A direct swipe prediction is shown immediately.
        candidateUpdateWork?.cancel()
        candidateGeneration &+= 1
        if let override {
            renderCandidates(override)
            return
        }
        guard useSuggestions, !recentWord.isEmpty else {
            renderCandidates([])
            return
        }
        let word = recentWord
        let generation = candidateGeneration
        // Keep dictionary scanning and sorting off the keyboard UI thread.
        // Debounce the background work, then return only the final 3 labels.
        let personalWords = learnedWords
        let job = DispatchWorkItem { [weak self] in
            let results = SmartTyping.predictions(
                prefix: word, learned: personalWords)
            DispatchQueue.main.async { [weak self] in
                guard let self, self.candidateGeneration == generation,
                      self.recentWord == word else { return }
                self.renderCandidates(results)
            }
        }
        candidateUpdateWork = job
        DispatchQueue.global(qos: .userInitiated).asyncAfter(
            deadline: .now() + .milliseconds(65), execute: job)
    }

    private func renderCandidates(_ results: [String]) {
        // Only a settings change may hide the row; predictions arriving
        // or disappearing must not resize the whole keyboard.
        let shouldHide = !useSuggestions
        if results == candidateWords && candidateBar.isHidden == shouldHide { return }
        candidateWords = results
        if candidateBar.isHidden != shouldHide {
            candidateBar.isHidden = shouldHide
            updateKeyboardHeight()
        }
        for (index, button) in candidateButtons.enumerated() {
            let title = index < results.count ? results[index] : ""
            if button.title(for: .normal) != title {
                button.setTitle(title, for: .normal)
            }
            let enabled = index < results.count
            if button.isEnabled != enabled { button.isEnabled = enabled }
        }
    }

    @objc private func candidateTapped(_ sender: UIButton) {
        resetBilingualComposition()
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
        if !current.isEmpty && current != replacement {
            lastWordReplacement = (original: current, corrected: replacement)
        }
        recentWord = replacement
        updateCandidates()
    }

    @objc private func undoWordCorrection() {
        guard let stored = lastWordReplacement else {
            showStatus("Chưa có sửa từ để hoàn tác")
            return
        }
        lastWordReplacement = nil
        guard let context = textDocumentProxy.documentContextBeforeInput,
              context.hasSuffix(stored.corrected),
              let edit = FastTyping.edit(from: stored.corrected, to: stored.original) else {
            showStatus("Văn bản đã thay đổi, không thể hoàn tác an toàn")
            return
        }
        for _ in 0..<edit.deleteCount { textDocumentProxy.deleteBackward() }
        if !edit.insertion.isEmpty { textDocumentProxy.insertText(edit.insertion) }
        resetBilingualComposition()
        recentWord = stored.original
        updateCandidates()
        showStatus("Đã hoàn tác sửa từ")
    }

    @objc private func spaceCursorPanned(_ recognizer: UIPanGestureRecognizer) {
        if recognizer.state == .began { resetBilingualComposition() }
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
        // Sample the nearest visible letter inside a small gutter around a
        // key. A finger rarely passes through exact button center points.
        var best: (distance: CGFloat, name: String)?
        for key in letterButtons where !key.isHidden {
            let rect = key.convert(key.bounds, to: view)
            guard rect.insetBy(dx: -7, dy: -7).contains(position),
                  let name = key.title(for: .normal), name.count == 1 else {
                continue
            }
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let dx = center.x - position.x
            let dy = center.y - position.y
            let distance = dx * dx + dy * dy
            if best == nil || distance < best!.distance {
                best = (distance, name.lowercased())
            }
        }
        return best?.name
    }

    private func captureGlidePoint(_ position: CGPoint) {
        guard let key = letterUnder(position), key != glideLastKey else { return }
        glideLastKey = key
        glidePath += key
    }

    private func configureGlideRecognizer() {
        if glideRecognizer == nil {
            let pan = UIPanGestureRecognizer(target: self,
                                             action: #selector(glidePanned(_:)))
            pan.minimumNumberOfTouches = 1
            pan.maximumNumberOfTouches = 1
            pan.cancelsTouchesInView = false
            pan.delaysTouchesBegan = false
            pan.delegate = self
            view.addGestureRecognizer(pan)
            glideRecognizer = pan
        }
        glideRecognizer?.isEnabled = useGlide && !isNumbers
    }

    @objc private func glidePanned(_ recognizer: UIPanGestureRecognizer) {
        guard useGlide, !isNumbers else { return }
        let point = recognizer.location(in: view)
        switch recognizer.state {
        case .began:
            glidePath = ""
            glideLastKey = ""
            glideIsActive = false
            let origin = glideTouchOrigin ?? point
            captureGlidePoint(origin)
            captureGlidePoint(point)
        case .changed:
            captureGlidePoint(point)
            if glidePath.count >= 3 { glideIsActive = true }
        case .ended:
            captureGlidePoint(point)
            let trace = glidePath
            let isWordSwipe = glideIsActive && trace.count >= 3
            glidePath = ""
            glideLastKey = ""
            glideIsActive = false
            glideTouchOrigin = nil
            guard isWordSwipe else { return }
            let personalWords = learnedWords
            let generation = candidateGeneration
            let touchCount = typingTouchCount
            // Edit-distance scoring runs off the touch-critical main thread.
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let suggestions = SmartTyping.glideCandidates(
                    trace: trace, learned: personalWords)
                DispatchQueue.main.async { [weak self] in
                    guard let self, !suggestions.isEmpty,
                          self.candidateGeneration == generation,
                          self.typingTouchCount == touchCount else { return }
                    let before = self.textDocumentProxy.documentContextBeforeInput ?? ""
                    let current = String(before.reversed()
                        .prefix(while: { $0.isLetter }).reversed())
                    let initial = String(trace.prefix(1))
                    if current.lowercased() == initial,
                       suggestions[0].lowercased().hasPrefix(initial) {
                        // touchDown already inserted the first letter.
                        // Replace just that letter with the recognized word.
                        self.replaceCurrentWord(suggestions[0])
                        self.textDocumentProxy.insertText(" ")
                        self.knownWordBoundary = true
                        self.resetBilingualComposition()
                        self.recentWord = ""
                        self.updateCandidates()
                    } else {
                        // Never overwrite an existing draft or a changed caret.
                        // Offer alternatives only; the user can tap to accept.
                        self.updateCandidates(suggestions)
                    }
                }
            }
        default:
            glidePath = ""
            glideLastKey = ""
            glideIsActive = false
            glideTouchOrigin = nil
        }
    }

    private func updateAdaptiveTouchTargets() {
        // Cover only the empty gutter between adjacent keys. No key changes
        // another key's label or steals touches from its visible bounds.
        let width = adaptiveTouchEnabled
            ? CGFloat(min(4, KeyboardSettings.keySpacing / 2)) : 0
        for button in letterButtons {
            (button as? AdaptiveKeyButton)?.horizontalHitExpansion = width
        }
    }

    private func updateKeyboardHeight() {
        // No permanently reserved blank AI area.
        let base: CGFloat = 240 + CGFloat(KeyboardSettings.keyHeight - 43) * 4
        heightConstraint?.constant = base +
            (candidateBar.isHidden ? 0 : 36) +
            (statusLabel.isHidden ? 0 : 22) +
            (suggestionContainer == nil ? 0 : 127)
        view.setNeedsLayout()
    }

    private func beginTyping() {
        lastWordReplacement = nil
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
        let startedAt = CACurrentMediaTime()
        defer { KeyboardStability.note("paste", durationMs:
            (CACurrentMediaTime() - startedAt) * 1000) }
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
        let matchedPersona = PersonaStore.autoSelect(fromSharedTranscript: selectedText)
        if matchedPersona != nil { installWritingActions() }
        let context = ConversationContextResolver.resolve(selectedText)
        let matchLabel = matchedPersona.map { "✓ Đã khớp: " + $0.name } ??
            ("Người nhận: " + context.displayName)
        showStatus(matchLabel + " · Nhấn AI")
    }

    private func requestedInput() -> String {
        let context = textDocumentProxy.documentContextBeforeInput ?? ""
        return selectedText.isEmpty ? String(context.suffix(3000)) : selectedText
    }

    @objc private func offlineTapped() {
        let startedAt = CACurrentMediaTime()
        defer { KeyboardStability.note("offline", durationMs:
            (CACurrentMediaTime() - startedAt) * 1000) }
        let text = requestedInput()
        guard !text.isEmpty else {
            showStatus("Dán tin nhắn cần trả lời trước")
            return
        }
        show(OfflineReplyEngine.suggest(for: text))
    }

    @objc private func cloudTapped() {
        let startedAt = CACurrentMediaTime()
        defer { KeyboardStability.note("ai", durationMs:
            (CACurrentMediaTime() - startedAt) * 1000) }
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
        if !MessageSafety.warnings(in: source).isEmpty {
            showStatus("Có dữ liệu nhạy cảm · Giữ nút AI → Ẩn dữ liệu rồi hỏi AI")
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
        let startedAt = CACurrentMediaTime()
        defer { KeyboardStability.note("phrases", durationMs:
            (CACurrentMediaTime() - startedAt) * 1000) }
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
        tones.spacing = 7
        tones.distribution = .fill
        toneButtons.removeAll()

        for (index, item) in lastSuggestions.enumerated() {
            let isSample = item.tone == "Mẫu câu"
            let duplicated = lastSuggestions.filter { $0.tone == item.tone }.count > 1
            let title = isSample ? String(format: "%02d  Mẫu", index + 1)
                : (duplicated ? "\(item.tone) \(index + 1)" : item.tone)
            let button = UIButton(type: .system)
            button.tag = index
            button.addTarget(self, action: #selector(selectSuggestion(_:)), for: .touchUpInside)
            var config = UIButton.Configuration.plain()
            config.title = title
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
                var updated = attributes
                updated.font = .systemFont(ofSize: 12, weight: .semibold)
                return updated
            }
            config.contentInsets = NSDirectionalEdgeInsets(top: 7, leading: 9, bottom: 7, trailing: 9)
            config.cornerStyle = .capsule
            if !isSample {
                config.image = UIImage(systemName: coupleSymbol(item.tone, index: index),
                                       withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .medium))
                config.imagePadding = 4
                config.imagePlacement = .leading
            }
            button.configuration = config
            button.accessibilityLabel = isSample ? "Chọn mẫu \(index + 1)" : "Chọn câu trả lời \(item.tone)"
            button.accessibilityTraits.insert(.button)
            button.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            button.setContentHuggingPriority(.defaultLow, for: .horizontal)
            toneButtons.append(button)
            tones.addArrangedSubview(button)
        }
        let close = UIButton(type: .system)
        var closeConfig = UIButton.Configuration.plain()
        closeConfig.image = UIImage(systemName: "xmark",
                                   withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold))
        closeConfig.baseForegroundColor = .secondaryLabel
        closeConfig.background.backgroundColor = .tertiarySystemFill
        closeConfig.cornerStyle = .capsule
        close.configuration = closeConfig
        close.accessibilityLabel = "Đóng các mẫu"
        close.addTarget(self, action: #selector(dismissSuggestions), for: .touchUpInside)
        close.widthAnchor.constraint(equalToConstant: 37).isActive = true
        tones.addArrangedSubview(close)
        tones.heightAnchor.constraint(equalToConstant: 38).isActive = true
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
                button.layer.cornerRadius = 12
                button.titleLabel?.font = .systemFont(ofSize: 11, weight: .semibold)
                let icons = ["doc.on.doc", "bookmark", "arrow.triangle.2.circlepath", "plus"]
                button.setImage(UIImage(systemName: icons[index],
                                        withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)),
                                for: .normal)
                button.tintColor = .label
                if index == 3 {
                    button.backgroundColor = aiColor
                    button.setTitleColor(.white, for: .normal)
                    button.tintColor = .white
                } else {
                    button.backgroundColor = UIColor.secondarySystemBackground
                    button.setTitleColor(.label, for: .normal)
                    button.tintColor = .secondaryLabel
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
        previewLabel.text = "  " + lastSuggestions[chosenIndex].text
        previewLabel.isHidden = false
    }

    private func updateToneStyles() {
        for (index, button) in toneButtons.enumerated() {
            let chosen = index == chosenIndex
            var config = button.configuration ?? UIButton.Configuration.plain()
            config.baseForegroundColor = chosen ? .white : .secondaryLabel
            config.background.backgroundColor = chosen ? aiColor : UIColor.secondarySystemBackground
            config.background.strokeColor = chosen ? aiColor : UIColor.separator.withAlphaComponent(0.20)
            config.background.strokeWidth = chosen ? 0 : 0.75
            config.cornerStyle = .capsule
            button.configuration = config
            button.layer.shadowColor = aiColor.cgColor
            button.layer.shadowOpacity = chosen ? 0.18 : 0
            button.layer.shadowRadius = chosen ? 4 : 0
            button.layer.shadowOffset = CGSize(width: 0, height: 2)
            button.isSelected = chosen
            button.accessibilityTraits = chosen ? [.button, .selected] : [.button]
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

extension KeyboardViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldReceive touch: UITouch) -> Bool {
        guard gestureRecognizer === glideRecognizer, useGlide, !isNumbers,
              let target = touch.view else { return false }
        // Do not intercept toolbars, delete, return, spacebar or suggestion taps.
        guard letterButtons.contains(where: { target.isDescendant(of: $0) }) else {
            return false
        }
        glideTouchOrigin = touch.location(in: view)
        return true
    }
}
