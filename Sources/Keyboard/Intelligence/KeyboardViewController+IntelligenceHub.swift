import UIKit

extension KeyboardViewController {
    @objc func openIntelligenceHub() {
        closeIntelligenceHub()
        let panel = UIView()
        panel.backgroundColor = .systemBackground
        panel.layer.cornerRadius = 14
        panel.clipsToBounds = true
        panel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(panel)
        NSLayoutConstraint.activate([
            panel.topAnchor.constraint(equalTo: view.topAnchor, constant: 3),
            panel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -3),
            panel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 3),
            panel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -3)
        ])
        intelligenceOverlay = panel
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 10),
            stack.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -10),
            stack.topAnchor.constraint(equalTo: panel.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: panel.bottomAnchor, constant: -8)
        ])
        let header = UIStackView()
        header.alignment = .center
        let label = UILabel()
        label.text = "ViePN Intelligence"
        label.font = .systemFont(ofSize: 17, weight: .bold)
        label.textColor = .label
        let close = UIButton(type: .system)
        close.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        close.accessibilityLabel = "Đóng công cụ"
        close.addAction(UIAction { [weak self] _ in self?.closeIntelligenceHub() }, for: .touchUpInside)
        close.widthAnchor.constraint(equalToConstant: 36).isActive = true
        header.addArrangedSubview(label)
        header.addArrangedSubview(close)
        stack.addArrangedSubview(header)
        let scroll = UIScrollView()
        let rows = UIStackView()
        rows.axis = .vertical
        rows.spacing = 6
        rows.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(rows)
        NSLayoutConstraint.activate([
            rows.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            rows.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            rows.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            rows.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            rows.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor)
        ])
        stack.addArrangedSubview(scroll)
        let groups: [(String, String, UIMenu?, (() -> Void)?)] = [
            ("Hội thoại", "bubble.left.and.bubble.right", studioMenu("Hội thoại"), nil),
            ("Tình cảm", "heart", studioMenu("Tình cảm"), nil),
            ("Công việc", "briefcase", studioMenu("Công việc"), nil),
            ("Viết lại", "wand.and.stars", studioMenu("Viết"), nil),
            ("Dịch", "globe", translatorMenu(), nil),
            ("Emoji", "face.smiling", emojiMenu(), nil),
            ("Prompt", "text.badge.plus", promptMenu(), nil),
            ("Đọc ảnh", "photo.text.rectangle", nil, { [weak self] in self?.recognizeRecipientFromCopiedScreenshot() }),
            ("Offline", "wifi.slash", nil, { [weak self] in self?.offlineTapped() }),
            ("Clipboard", "doc.on.clipboard", nil, { [weak self] in self?.pasteTapped() }),
            ("Bản nháp", "square.and.arrow.down", nil, { [weak self] in
                guard let self else { return }
                let draft = ShareDraft.current
                guard !draft.isEmpty else { self.showStatus("Chưa có bản nháp đã chia sẻ"); return }
                self.selectedText = draft; self.showStatus("Đã nạp bản nháp · Chọn AI")
            }),
            ("Riêng tư", "hand.raised", nil, { [weak self] in
                guard let self else { return }
                self.cancelAIRequest()
                self.flushLearnedWords()
                KeyboardSettings.privateTypingMode.toggle()
                self.selectedText = ""
                self.clearSuggestions()
                self.refreshTypingPreferences()
                self.showStatus(KeyboardSettings.privateTypingMode ? "Đã bật gõ riêng tư" : "Đã tắt gõ riêng tư")
            }),
            ("Hoàn tác", "arrow.uturn.backward", nil, { [weak self] in self?.undoStudioEdit() }),
            ("Làm lại", "arrow.uturn.forward", nil, { [weak self] in self?.redoStudioEdit() }),
            ("Con trỏ", "arrow.left.and.right", cursorMenu(), nil),
            ("Mẫu câu", "text.quote", nil, { [weak self] in self?.phrasesTapped() }),
            ("Nhà cung cấp", "server.rack", providerMenu(), nil),
            ("Văn phong", "person.text.rectangle", nil, { [weak self] in
                let metrics = PersonalStyleDNA.analyze(KeyboardSettings.writingSamples)
                self?.showStatus("DNA · \(metrics.count) mẫu · \(metrics.averageWords) từ/mẫu")
            })
        ]
        for start in stride(from: 0, to: groups.count, by: 3) {
            let row = UIStackView()
            row.distribution = .fillEqually
            row.spacing = 6
            for spec in groups[start..<min(start+3, groups.count)] {
                let button = UIButton(type: .system)
                var config = UIButton.Configuration.filled()
                config.title = spec.0
                config.image = UIImage(systemName: spec.1)
                config.imagePlacement = .top
                config.imagePadding = 4
                config.baseForegroundColor = .label
                config.baseBackgroundColor = .secondarySystemBackground
                config.cornerStyle = .medium
                config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 2, bottom: 8, trailing: 2)
                button.configuration = config
                button.heightAnchor.constraint(equalToConstant: 58).isActive = true
                if let menu = spec.2 { button.menu = menu; button.showsMenuAsPrimaryAction = true }
                else if let action = spec.3 { button.addAction(UIAction { [weak self] _ in self?.closeIntelligenceHub(); action() }, for: .touchUpInside) }
                row.addArrangedSubview(button)
            }
            rows.addArrangedSubview(row)
        }
        UIAccessibility.post(notification: .screenChanged, argument: label)
    }
    func closeIntelligenceHub() { intelligenceOverlay?.removeFromSuperview(); intelligenceOverlay = nil }
    func studioMenu(_ group: String) -> UIMenu {
        UIMenu(title: group, children: IntelligenceTask.tasks.filter { $0.group == group }.map { task in
            UIAction(title: task.title, image: UIImage(systemName: task.symbol)) { [weak self] _ in
                self?.closeIntelligenceHub()
                self?.runStudio(title: task.title, instruction: task.instruction)
            }
        })
    }
    func translatorMenu() -> UIMenu {
        UIMenu(title: "Dịch sang", children: IntelligenceTask.languages.map { lang in
            UIMenu(title: lang, children: [(false,false,"Tự nhiên"),(true,false,"Song ngữ"),(false,true,"Trang trọng")].map { bilingual,formal,title in
                UIAction(title: title) { [weak self] _ in
                    self?.closeIntelligenceHub()
                    self?.runStudio(title: "Dịch · " + lang, instruction: IntelligenceTask.translation(to: lang, bilingual: bilingual, formal: formal))
                }
            })
        })
    }
    func providerMenu() -> UIMenu {
        UIMenu(title: "Nhà cung cấp AI", children: ["gemini", "openai"].map { provider in
            UIAction(title: provider == "gemini" ? "Gemini" : "OpenAI", state: KeyboardSettings.provider == provider ? .on : .off) { [weak self] _ in
                self?.closeIntelligenceHub()
                self?.cancelAIRequest()
                KeyboardSettings.provider = provider
                self?.showStatus("Đã chọn " + provider)
            }
        })
    }
    func promptMenu() -> UIMenu {
        let items = PersonalPromptStore.items.map { prompt in
            UIAction(title: prompt.title) { [weak self] _ in
                self?.closeIntelligenceHub()
                self?.runStudio(title: prompt.title, instruction: prompt.instruction, style: true)
            }
        }
        return UIMenu(title: "Prompt cá nhân · tạo trong ViePN", children: items.isEmpty ? [UIAction(title: "Chưa có prompt", attributes: .disabled) { _ in }] : items)
    }
    func emojiMenu() -> UIMenu {
        UIMenu(title: "Emoji & Symbol", children: SymbolCatalog.categories.dropFirst().map { category in
            UIMenu(title: category, children: SymbolCatalog.search("", category: category).map { item in
                UIAction(title: item.value + "  " + item.keywords) { [weak self] _ in
                    guard let self else { return }
                    self.closeIntelligenceHub()
                    self.beginTyping()
                    self.textDocumentProxy.insertText(item.value)
                    self.resetBilingualComposition()
                    self.recentWord = ""
                    self.updateCandidates()
                    KeyboardSettings.recordEmojiSelection(item.value)
                }
            })
        })
    }
    func cursorMenu() -> UIMenu {
        UIMenu(title: "Di chuyển con trỏ", children: [(-5,"← 5 ký tự"),(-1,"← 1 ký tự"),(1,"1 ký tự →"),(5,"5 ký tự →")].map { offset,title in
            UIAction(title: title) { [weak self] _ in
                guard let self else { return }
                self.closeIntelligenceHub()
                self.beginTyping()
                self.resetBilingualComposition()
                self.textDocumentProxy.adjustTextPosition(byCharacterOffset: offset)
                self.recentWord = ""
                self.updateCandidates()
            }
        })
    }
    func runStudio(title: String, instruction: String, style: Bool = false) {
        guard !isRequestRunning, hasFullAccess, KeyboardSettings.allowCloudAI else {
            showStatus("Cần Full Access, bật AI online và tắt gõ riêng tư."); return
        }
        let source = (selectedText.isEmpty ? (textDocumentProxy.selectedText ?? requestedInput()) : selectedText)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !source.isEmpty, MessageSafety.warnings(in: source).isEmpty else {
            showStatus("Hãy nhập, chọn hoặc dán nội dung không nhạy cảm."); return
        }
        let ticket = UUID()
        requestID = ticket
        isRequestRunning = true
        let document = textDocumentProxy.documentIdentifier
        let persona = PersonaStore.activeID
        showStatus("Đang xử lý · " + title)
        aiTask = Task { [weak self] in
            do {
                let result = try await AIWritingService.studio(source, instruction: instruction, includeStyle: style)
                guard let self, self.requestID == ticket else { return }
                self.isRequestRunning = false
                guard self.textDocumentProxy.documentIdentifier == document, PersonaStore.activeID == persona else { return }
                self.show([ReplySuggestion(tone: title, text: result)])
            } catch {
                guard let self, self.requestID == ticket else { return }
                self.isRequestRunning = false
                self.showStatus(error.localizedDescription)
            }
        }
    }
}
