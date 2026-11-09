import UIKit

/// ViePN keyboard: composing a suggested reply never writes the source message
/// to the host chat field. All host-field modifications are explicit user taps.
final class KeyboardViewController: UIInputViewController {
    private let container = UIStackView()
    private let statusLabel = UILabel()
    private let previewLabel = UILabel()
    private var selectedText = ""
    private var isUppercase = false
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

    override func viewDidLoad() {
        super.viewDidLoad()
        buildKeyboard()
        haptic.prepare()
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        // Avoid erasing the reply when the host app changes text focus.
    }

    private func buildKeyboard() {
        view.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.11, green: 0.13, blue: 0.20, alpha: 1)
                : UIColor(red: 0.89, green: 0.92, blue: 0.97, alpha: 1)
        }
        heightConstraint = view.heightAnchor.constraint(equalToConstant: 315)
        heightConstraint?.priority = .defaultHigh
        heightConstraint?.isActive = true
        container.axis = .vertical
        container.spacing = 6
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            container.topAnchor.constraint(equalTo: view.topAnchor, constant: 5),
            container.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -4)
        ])

        statusLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        statusLabel.textColor = .secondaryLabel
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 2
        statusLabel.text = "✦ ViePN AI · Viết hay hơn, gửi nhanh hơn"
        statusLabel.heightAnchor.constraint(equalToConstant: 21).isActive = true
        container.addArrangedSubview(statusLabel)

        // A compact command strip leaves the usual iPhone letter keyboard intact.
        let commands = makeRow([
            ("📋 Dán", #selector(pasteTapped)),
            ("✨ Offline", #selector(offlineTapped)),
            ("✦ AI", #selector(cloudTapped)),
            ("📝 Mẫu", #selector(phrasesTapped)),
            ("😊", #selector(emojiTapped))
        ], height: 39)
        if let bar = commands as? UIStackView {
            toolButtons = bar.arrangedSubviews.compactMap { $0 as? UIButton }
            for (index, button) in toolButtons.enumerated() {
                button.layer.cornerRadius = 12
                button.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
                if index == 2 {
                    button.backgroundColor = aiColor
                    button.setTitleColor(.white, for: .normal)
                } else if index == 4 {
                    button.backgroundColor = UIColor(red: 1, green: 0.89, blue: 0.94, alpha: 1)
                }
            }
        }
        container.addArrangedSubview(commands)
        updateEmojiTool()

        previewLabel.numberOfLines = 3
        previewLabel.font = .systemFont(ofSize: 14, weight: .medium)
        previewLabel.textColor = .label
        previewLabel.textAlignment = .left
        previewLabel.backgroundColor = .secondarySystemBackground
        previewLabel.layer.cornerRadius = 13
        previewLabel.layer.borderWidth = 1
        previewLabel.layer.borderColor = cyanColor.withAlphaComponent(0.35).cgColor
        previewLabel.clipsToBounds = true
        previewLabel.isHidden = true
        previewLabel.heightAnchor.constraint(lessThanOrEqualToConstant: 56).isActive = true
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
                let shift = keyButton("⇧", action: #selector(shiftTapped))
                styleModifier(shift)
                row.addArrangedSubview(shift)
            }
            for letter in letters {
                let key = keyButton(String(letter), action: #selector(letterTapped(_:)))
                letterButtons.append(key)
                row.addArrangedSubview(key)
            }
            if rowIndex == 2 {
                let delete = keyButton("⌫", action: #selector(deleteTapped))
                styleModifier(delete)
                row.addArrangedSubview(delete)
            }
            row.heightAnchor.constraint(equalToConstant: 46).isActive = true
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
        let globe = keyButton("🌐", action: #selector(globeTapped))
        let comma = keyButton(",", action: #selector(punctuationTapped(_:)))
        let space = keyButton("dấu cách", action: #selector(spaceTapped))
        let period = keyButton(".", action: #selector(punctuationTapped(_:)))
        let enter = keyButton("↵", action: #selector(returnTapped))
        for key in [numeric, globe, comma, period] { styleModifier(key) }
        enter.backgroundColor = UIColor(red: 0.29, green: 0.54, blue: 0.98, alpha: 1)
        enter.setTitleColor(.white, for: .normal)
        for key in [numeric, globe, comma, space, period, enter] { bottom.addArrangedSubview(key) }
        numeric.widthAnchor.constraint(equalToConstant: 44).isActive = true
        globe.widthAnchor.constraint(equalToConstant: 40).isActive = true
        comma.widthAnchor.constraint(equalToConstant: 34).isActive = true
        period.widthAnchor.constraint(equalToConstant: 34).isActive = true
        enter.widthAnchor.constraint(equalToConstant: 48).isActive = true
        bottom.heightAnchor.constraint(equalToConstant: 45).isActive = true
        secondaryRow = bottom
        container.addArrangedSubview(bottom)
        updateKeys()
    }

    private func keyButton(_ title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 21, weight: .regular)
        button.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(white: 0.31, alpha: 1) : .white
        }
        button.layer.cornerRadius = 9
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.13
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.layer.shadowRadius = 0.5
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.7
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
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

    @objc private func punctuationTapped(_ sender: UIButton) {
        guard let character = sender.title(for: .normal) else { return }
        textDocumentProxy.insertText(character)
    }

    @objc private func letterTapped(_ sender: UIButton) {
        guard let title = sender.title(for: .normal) else { return }
        let key = isUppercase && !isNumbers ? title.uppercased() : title
        if !isNumbers && KeyboardSettings.telexEnabled,
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
        textDocumentProxy.insertText(key)
        if isUppercase && !isShiftLocked {
            isUppercase = false
            updateKeys()
        }
    }

    @objc private func spaceTapped() { textDocumentProxy.insertText(" ") }
    @objc private func returnTapped() { textDocumentProxy.insertText("\n") }
    @objc private func deleteTapped() { textDocumentProxy.deleteBackward() }

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
                shift.setTitle(isShiftLocked ? "⇧⇧" : "⇧", for: .normal)
            }
        }
        if let bottom = secondaryRow, let numeric = bottom.arrangedSubviews.first as? UIButton {
            numeric.setTitle(isNumbers ? "ABC" : "123", for: .normal)
        }
    }

    @objc private func globeTapped() { advanceToNextInputMode() }

    @objc private func pasteTapped() {
        guard hasFullAccess else {
            statusLabel.text = "Hãy bật Full Access để đọc clipboard theo yêu cầu"
            return
        }
        guard let text = UIPasteboard.general.string,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            statusLabel.text = "Clipboard trống"
            return
        }
        // IMPORTANT: reading the source is not inserting it into the chat draft.
        selectedText = String(text.prefix(3000)).trimmingCharacters(in: .whitespacesAndNewlines)
        clearSuggestions()
        statusLabel.text = "Đã chọn tin nhắn để phân tích (KHÔNG chèn vào ô soạn)"
    }

    private func requestedInput() -> String {
        let context = textDocumentProxy.documentContextBeforeInput ?? ""
        return selectedText.isEmpty ? String(context.suffix(3000)) : selectedText
    }

    @objc private func offlineTapped() {
        let text = requestedInput()
        guard !text.isEmpty else {
            statusLabel.text = "Dán tin nhắn cần trả lời trước"
            return
        }
        show(OfflineReplyEngine.suggest(for: text))
    }

    @objc private func cloudTapped() {
        guard !isRequestRunning else { return }
        guard hasFullAccess else {
            statusLabel.text = "Cần bật Full Access để gọi AI"
            return
        }
        let source = requestedInput().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !source.isEmpty else {
            statusLabel.text = "Chưa có tin nhắn để phân tích · Chạm Dán"
            return
        }
        isRequestRunning = true
        requestID = UUID()
        let currentRequestID = requestID
        statusLabel.text = "AI đang gợi ý câu trả lời..."
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
                    self.statusLabel.text = "AI lỗi: \(error.localizedDescription)"
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
        previewLabel.text = nil
        previewLabel.isHidden = true
        heightConstraint?.constant = 315
    }

    private func show(_ items: [ReplySuggestion]) {
        clearSuggestions()
        lastSuggestions = Array(items.prefix(3))
        guard !lastSuggestions.isEmpty else {
            statusLabel.text = "Không tìm được câu trả lời"
            return
        }
        chosenIndex = 0
        statusLabel.text = "Chỉ dùng câu trả lời bên dưới · KHÔNG kèm tin gốc"
        let bar = UIStackView()
        bar.axis = .vertical
        bar.spacing = 3
        bar.tag = 9321
        let tones = UIStackView()
        tones.axis = .horizontal
        tones.distribution = .fillEqually
        tones.spacing = 3
        for (index, item) in lastSuggestions.enumerated() {
            let button = keyButton("\(index+1) · \(item.tone)", action: #selector(selectSuggestion(_:)))
            button.tag = index
            button.titleLabel?.font = .systemFont(ofSize: 11)
            tones.addArrangedSubview(button)
        }
        tones.heightAnchor.constraint(equalToConstant: 32).isActive = true
        bar.addArrangedSubview(tones)
        let actions = makeRow([
            ("📋 Sao chép", #selector(copySuggestion)),
            ("↻ Thay bản nháp", #selector(replaceDraft)),
            ("➕ Chèn", #selector(insertSuggestion))
        ], height: 33)
        bar.addArrangedSubview(actions)
        suggestionContainer = bar
        heightConstraint?.constant = 410
        // Only a preview of the answer appears above the keys. No source text.
        container.insertArrangedSubview(bar, at: 3)
        updatePreview()
    }

    private func updatePreview() {
        guard lastSuggestions.indices.contains(chosenIndex) else { return }
        previewLabel.text = "  " + lastSuggestions[chosenIndex].text
        previewLabel.isHidden = false
    }

    @objc private func selectSuggestion(_ sender: UIButton) {
        guard lastSuggestions.indices.contains(sender.tag) else { return }
        chosenIndex = sender.tag
        updatePreview()
        statusLabel.text = "Chọn Sao chép / Thay bản nháp / Chèn"
    }

    private func selectedReply() -> String? {
        guard lastSuggestions.indices.contains(chosenIndex) else { return nil }
        let text = lastSuggestions[chosenIndex].text.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : text
    }

    @objc private func copySuggestion() {
        guard let answer = selectedReply() else { return }
        guard hasFullAccess else {
            statusLabel.text = "Bật Full Access để sao chép"
            return
        }
        UIPasteboard.general.string = answer
        statusLabel.text = "Đã sao chép CHỈ câu trả lời, không kèm tin gốc"
    }

    @objc private func replaceDraft() {
        guard let answer = selectedReply() else { return }
        // Prevent deleting unrelated content after the caret, or deleting
        // incomplete context exposed by secure/restricted third-party fields.
        guard textDocumentProxy.selectedText == nil,
              let before = textDocumentProxy.documentContextBeforeInput,
              (textDocumentProxy.documentContextAfterInput ?? "").isEmpty,
              before.count <= 2000 else {
            statusLabel.text = "Không thể thay an toàn · Chọn Sao chép rồi tự dán"
            return
        }
        for _ in before { textDocumentProxy.deleteBackward() }
        textDocumentProxy.insertText(answer)
        statusLabel.text = "Đã thay bản nháp bằng CHỈ câu trả lời"
    }

    @objc private func insertSuggestion() {
        guard let answer = selectedReply() else { return }
        textDocumentProxy.insertText(answer)
        statusLabel.text = "Đã chèn câu trả lời tại con trỏ (không kèm tin gốc)"
    }
}
