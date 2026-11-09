import UIKit

final class KeyboardViewController: UIInputViewController {
    private let container = UIStackView()
    private let statusLabel = UILabel()
    private let previewLabel = UILabel()
    private var selectedText = ""
    private var isUppercase = false
    private var lastSuggestions: [ReplySuggestion] = []
    private var showingSuggestions = false

    override func viewDidLoad() {
        super.viewDidLoad()
        buildKeyboard()
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        if !showingSuggestions { statusLabel.text = "ViePN AI · Nội dung chỉ được đọc khi bạn yêu cầu" }
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
        statusLabel.font = .systemFont(ofSize: 11)
        statusLabel.textAlignment = .center
        statusLabel.text = "ViePN AI · Offline"
        container.addArrangedSubview(statusLabel)
        previewLabel.numberOfLines = 2
        previewLabel.font = .systemFont(ofSize: 11)
        previewLabel.textAlignment = .center
        previewLabel.isHidden = true
        container.addArrangedSubview(previewLabel)

        let commands = makeRow([("📋 Dán", #selector(pasteTapped)),
                                ("✨ Offline", #selector(offlineTapped)),
                                ("☁️ AI", #selector(cloudTapped)),
                                ("📝 Mẫu", #selector(phrasesTapped))], height: 38)
        container.addArrangedSubview(commands)
        for letters in ["qwertyuiop", "asdfghjkl", "zxcvbnm"] {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 3
            row.distribution = .fillEqually
            for letter in letters {
                let button = keyButton(String(letter), action: #selector(letterTapped(_:)))
                row.addArrangedSubview(button)
            }
            row.heightAnchor.constraint(equalToConstant: 43).isActive = true
            container.addArrangedSubview(row)
        }
        let bottom = makeRow([("⇧", #selector(shiftTapped)),
                              ("🌐", #selector(globeTapped)),
                              ("⌫", #selector(deleteTapped)),
                              ("dấu", #selector(accentTapped)),
                              ("space", #selector(spaceTapped)),
                              ("↵", #selector(returnTapped))], height: 43)
        container.addArrangedSubview(bottom)
    }

    private func keyButton(_ title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        button.backgroundColor = .systemBackground
        button.layer.cornerRadius = 5
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
        textDocumentProxy.insertText(isUppercase ? title.uppercased() : title)
    }
    @objc private func spaceTapped() { textDocumentProxy.insertText(" ") }
    @objc private func returnTapped() { textDocumentProxy.insertText("\n") }
    @objc private func deleteTapped() { textDocumentProxy.deleteBackward() }
    @objc private func shiftTapped() {
        isUppercase.toggle()
        statusLabel.text = isUppercase ? "CHỮ HOA" : "chữ thường"
    }
    @objc private func globeTapped() { advanceToNextInputMode() }

    @objc private func accentTapped() {
        // Minimal Vietnamese Telex conversion of the word before cursor.
        guard let before = textDocumentProxy.documentContextBeforeInput else { return }
        let word = String(before.split(whereSeparator: { !$0.isLetter }).last ?? "")
        guard !word.isEmpty, word.count <= 40 else { return }
        let converted = VietnameseInput.applyTone(to: word)
        guard converted != word else { return }
        for _ in word { textDocumentProxy.deleteBackward() }
        textDocumentProxy.insertText(converted)
    }

    @objc private func pasteTapped() {
        // Intentionally read the pasteboard only after explicit tap.
        guard hasFullAccess else {
            statusLabel.text = "Bật Full Access để dùng clipboard"
            return
        }
        guard let text = UIPasteboard.general.string, !text.isEmpty else {
            statusLabel.text = "Clipboard trống"
            return
        }
        selectedText = String(text.prefix(3000))
        previewLabel.text = selectedText
        previewLabel.isHidden = false
        statusLabel.text = "Đã chọn nội dung · Chạm Offline hoặc AI"
    }

    @objc private func offlineTapped() {
        let text = selectedText.isEmpty ? (textDocumentProxy.documentContextBeforeInput ?? "") : selectedText
        show(OfflineReplyEngine.suggest(for: text))
    }

    @objc private func cloudTapped() {
        guard hasFullAccess else { statusLabel.text = "Cần Full Access cho API"; return }
        let text = selectedText.isEmpty ? (textDocumentProxy.documentContextBeforeInput ?? "") : selectedText
        guard !text.isEmpty else { statusLabel.text = "Chưa có nội dung để phân tích"; return }
        statusLabel.text = "Đang lấy gợi ý AI…"
        Task { [weak self] in
            do {
                let items = try await AIService.reply(to: text)
                await MainActor.run { self?.show(items) }
            } catch {
                await MainActor.run {
                    self?.statusLabel.text = "AI lỗi · Dùng gợi ý offline"
                    self?.show(OfflineReplyEngine.suggest(for: text))
                }
            }
        }
    }

    @objc private func phrasesTapped() {
        show(KeyboardSettings.savedPhrases.map { ReplySuggestion(tone: "Mẫu câu", text: $0) })
    }

    private func show(_ items: [ReplySuggestion]) {
        lastSuggestions = items
        showingSuggestions = true
        guard !items.isEmpty else { statusLabel.text = "Chưa có nội dung"; return }
        statusLabel.text = "Chạm 1/2/3 để chèn câu trả lời"
        removeSuggestionBar()
        let row = UIStackView()
        row.tag = 9321
        row.axis = .horizontal
        row.spacing = 3
        row.distribution = .fillEqually
        for (index, item) in items.prefix(3).enumerated() {
            let button = keyButton("\(index + 1). \(item.tone)", action: #selector(suggestionTapped(_:)))
            button.tag = index
            button.titleLabel?.font = .systemFont(ofSize: 11)
            row.addArrangedSubview(button)
        }
        row.heightAnchor.constraint(equalToConstant: 36).isActive = true
        container.insertArrangedSubview(row, at: 2)
        previewLabel.text = items[0].text
        previewLabel.isHidden = false
    }

    private func removeSuggestionBar() {
        if let old = container.arrangedSubviews.first(where: { $0.tag == 9321 }) {
            container.removeArrangedSubview(old); old.removeFromSuperview()
        }
    }
    @objc private func suggestionTapped(_ sender: UIButton) {
        guard lastSuggestions.indices.contains(sender.tag) else { return }
        textDocumentProxy.insertText(lastSuggestions[sender.tag].text)
        statusLabel.text = "Đã chèn câu trả lời"
        showingSuggestions = false
        removeSuggestionBar()
    }
}

// Simple one-tap tonal mark helper. Full Vietnamese IME is a future enhancement.
enum VietnameseInput {
    static func applyTone(to word: String) -> String {
        let chars: [Character: String] = ["a":"á", "e":"é", "i":"í", "o":"ó", "u":"ú", "y":"ý",
                                          "A":"Á", "E":"É", "I":"Í", "O":"Ó", "U":"Ú", "Y":"Ý"]
        var result = Array(word)
        guard let index = result.lastIndex(where: { chars[$0] != nil }),
              let marked = chars[result[index]] else { return word }
        result[index] = Character(marked)
        return String(result)
    }
}
