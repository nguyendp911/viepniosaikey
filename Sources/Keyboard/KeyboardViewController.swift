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

    override func viewDidLoad() {
        super.viewDidLoad()
        buildKeyboard()
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        // Avoid erasing the reply when the host app changes text focus.
    }

    private func buildKeyboard() {
        view.backgroundColor = UIColor.systemGray5
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

        statusLabel.font = .systemFont(ofSize: 11, weight: .medium)
        statusLabel.textColor = .secondaryLabel
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 2
        statusLabel.text = "ViePN AI · Chọn Dán để phân tích nội dung clipboard"
        container.addArrangedSubview(statusLabel)

        let commands = makeRow([
            ("📋 Dán", #selector(pasteTapped)),
            ("✨ Offline", #selector(offlineTapped)),
            ("☁️ AI", #selector(cloudTapped)),
            ("📝 Mẫu", #selector(phrasesTapped))
        ], height: 39)
        container.addArrangedSubview(commands)

        previewLabel.numberOfLines = 3
        previewLabel.font = .systemFont(ofSize: 13)
        previewLabel.textColor = .label
        previewLabel.textAlignment = .left
        previewLabel.backgroundColor = .secondarySystemBackground
        previewLabel.layer.cornerRadius = 8
        previewLabel.clipsToBounds = true
        previewLabel.isHidden = true
        container.addArrangedSubview(previewLabel)

        for letters in ["qwertyuiop", "asdfghjkl", "zxcvbnm"] {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 3
            row.distribution = .fillEqually
            for letter in letters {
                let key = keyButton(String(letter), action: #selector(letterTapped(_:)))
                letterButtons.append(key)
                row.addArrangedSubview(key)
            }
            row.heightAnchor.constraint(equalToConstant: 43).isActive = true
            letterRows.append(row)
            container.addArrangedSubview(row)
        }

        let bottom = makeRow([
            ("⇧", #selector(shiftTapped)),
            ("🌐", #selector(globeTapped)),
            ("⌫", #selector(deleteTapped)),
            ("123", #selector(numbersTapped)),
            ("space", #selector(spaceTapped)),
            ("↵", #selector(returnTapped))
        ], height: 43)
        secondaryRow = bottom as? UIStackView
        container.addArrangedSubview(bottom)
    }

    private func keyButton(_ title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .systemBackground
        button.layer.cornerRadius = 7
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.7
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func makeRow(_ actions: [(String, Selector)], height: CGFloat) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.distribution = .fillEqually
        row.spacing = 3
        for (title, action) in actions { row.addArrangedSubview(keyButton(title, action: action)) }
        row.heightAnchor.constraint(equalToConstant: height).isActive = true
        return row
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
        let rows = isNumbers ? ["1234567890", "@#$%&*()-", ".,?!':;/"] : ["qwertyuiop", "asdfghjkl", "zxcvbnm"]
        for (rowIndex, row) in letterRows.enumerated() {
            let buttons = row.arrangedSubviews.compactMap { $0 as? UIButton }
            let characters = Array(rows[rowIndex]).map(String.init)
            for (index, button) in buttons.enumerated() {
                if index < characters.count {
                    let ch = characters[index]
                    button.setTitle(isNumbers ? ch : (isUppercase ? ch.uppercased() : ch), for: .normal)
                    button.isHidden = false
                } else {
                    button.isHidden = true
                }
            }
        }
        if let row = secondaryRow {
            let buttons = row.arrangedSubviews.compactMap { $0 as? UIButton }
            if buttons.count > 3 { buttons[3].setTitle(isNumbers ? "ABC" : "123", for: .normal) }
            if let shift = buttons.first { shift.setTitle(isShiftLocked ? "⇧⇧" : "⇧", for: .normal) }
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
