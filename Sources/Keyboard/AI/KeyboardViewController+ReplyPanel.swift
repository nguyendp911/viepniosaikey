import UIKit
import AudioToolbox
import Vision

extension KeyboardViewController {
    func showStatus(_ message: String) {
        statusLabel.text = message
        statusLabel.isHidden = false
        updateKeyboardHeight()
    }

    @objc func dismissSuggestions() {
        if isRequestRunning { cancelAIRequest() }
        clearSuggestions()
        statusLabel.isHidden = true
        updateKeyboardHeight()
    }

    func clearSuggestions() {
        if let old = suggestionContainer {
            container.removeArrangedSubview(old)
            old.removeFromSuperview()
            suggestionContainer = nil
        }
        lastSuggestions = []
        suggestionDocumentID = nil
        suggestionPersonaID = ""
        toneButtons = []
        previewLabel.text = nil
        previewLabel.isHidden = true
        updateKeyboardHeight()
    }

    func coupleSymbol(_ tone: String, index: Int) -> String {
        let name = tone.folding(options: [.caseInsensitive, .diacriticInsensitive],
                                locale: Locale(identifier: "vi_VN"))
        if name.contains("ranh gioi") { return "hand.raised.fill" }
        if name.contains("lang nghe") { return "ear" }
        if name.contains("diu dang") || name.contains("ngot") { return "heart.fill" }
        if name.contains("quan tam") { return "leaf.fill" }
        if name.contains("de thuong") || name.contains("vui") { return "sparkles" }
        return ["sparkles", "heart", "bubble.left.fill"][index % 3]
    }

    func show(_ items: [ReplySuggestion]) {
        clearSuggestions()
        lastSuggestions = Array(items.prefix(3))
        suggestionDocumentID = textDocumentProxy.documentIdentifier
        suggestionPersonaID = PersonaStore.activeID
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

    func updatePreview() {
        guard lastSuggestions.indices.contains(chosenIndex) else { return }
        previewLabel.text = "  " + lastSuggestions[chosenIndex].text
        previewLabel.isHidden = false
    }

    func updateToneStyles() {
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

    @objc func selectSuggestion(_ sender: UIButton) {
        guard lastSuggestions.indices.contains(sender.tag) else { return }
        chosenIndex = sender.tag
        haptic.impactOccurred(intensity: 0.55)
        updatePreview()
        updateToneStyles()
    }

    func selectedReply() -> String? {
        guard suggestionDocumentID == textDocumentProxy.documentIdentifier,
              suggestionPersonaID == PersonaStore.activeID else {
            clearSuggestions()
            showStatus("Hội thoại đã thay đổi · Tạo gợi ý mới")
            return nil
        }
        guard lastSuggestions.indices.contains(chosenIndex) else { return nil }
        let text = lastSuggestions[chosenIndex].text.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : text
    }

    @objc func copySuggestion() {
        guard let answer = selectedReply() else { return }
        guard hasFullAccess else {
            showStatus("Bật Full Access để sao chép")
            return
        }
        UIPasteboard.general.string = answer
        showStatus("Đã sao chép CHỈ câu trả lời, không kèm tin gốc")
    }

    @objc func saveSuggestion() {
        guard let answer = selectedReply() else { return }
        var items = KeyboardSettings.favoriteReplies
        if !items.contains(answer) {
            items.insert(answer, at: 0)
            KeyboardSettings.favoriteReplies = items
            if CoupleReplyGuide.isEnabled {
                CouplePersonalDNA.record(answer,style:KeyboardSettings.coupleStyle)
                CoupleSignature.record(answer)
            }
        }
        showStatus("✓ Đã lưu vào thư viện câu trả lời")
    }

    @objc func replaceDraft() {
        guard let answer = selectedReply() else { return }
        // Prevent deleting unrelated content after the caret, or deleting
        // incomplete context exposed by secure/restricted third-party fields.
        guard let selection = textDocumentProxy.selectedText, !selection.isEmpty else {
            showStatus("Hãy bôi đen đoạn cần thay, hoặc Sao chép rồi tự dán")
            return
        }
        // UIKit replaces the explicit selection; never loop over an unknown
        // documentContextBeforeInput (iOS may expose only a truncated suffix).
        insertTrackedStudioText(answer)
        dismissSuggestions()
        showStatus("Đã thay bản nháp bằng CHỈ câu trả lời")
    }

    @objc func insertSuggestion() {
        guard let answer = selectedReply() else { return }
        insertTrackedStudioText(answer)
        dismissSuggestions()
        showStatus("Đã chèn chỉ câu trả lời vào ô soạn")
    }
}
