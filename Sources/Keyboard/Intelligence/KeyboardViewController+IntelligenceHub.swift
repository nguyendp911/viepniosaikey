import UIKit

extension KeyboardViewController {
    @objc func openIntelligenceHub() {
        closeIntelligenceHub()
        let palette = KeyboardThemePalette.resolve(currentTheme)
        let panel = UIView()
        panel.backgroundColor = palette.canvas
        panel.accessibilityViewIsModal = true
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
        label.textColor = palette.text
        let close = UIButton(type: .system)
        close.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        close.accessibilityLabel = "Đóng công cụ"
        close.addAction(UIAction { [weak self] _ in self?.closeIntelligenceHub() }, for: .touchUpInside)
        close.tintColor = palette.text
        close.widthAnchor.constraint(equalToConstant: 44).isActive = true
        close.heightAnchor.constraint(equalToConstant: 44).isActive = true
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
            ("Typing Premium", "keyboard", UIMenu(title:"Typing Premium",children:[pro6ToolsMenu(),everydayToolsMenu()]), nil),
            ("Keyboard Pro", "keyboard", proKeyboardMenu(), nil),
            ("Time Machine", "clock.arrow.circlepath", proHistoryMenu(), nil),
            ("Text Studio", "textformat", proTextMenu(), nil),
            ("Profiles", "person.crop.rectangle.stack", proProfilesMenu(), nil),
            ("Ký tự Pro", "character", proSymbolsMenu(), nil),
            ("Personal AI", "brain.head.profile", personalAIToolsMenu(), nil),
            ("Tone Mixer", "slider.horizontal.3", personalToneMenu(), nil),
            ("Arena", "square.split.2x1", nil, { [weak self] in self?.personalArena() }),
            ("Second Brain", "brain", personalMemoryMenu(), nil),
            ("Mini Apps", "square.grid.2x2", personalMiniAppsMenu(), nil),
            ("Command", "command", nil, { [weak self] in self?.openPremiumPalette() }),
            ("AI Premium", "brain", premiumAIMenu(), nil),
            ("Workflow", "arrow.triangle.branch", premiumWorkflowMenu(), nil),
            ("Macro", "bolt", premiumMacroMenu(), nil),
            ("Biến mẫu", "curlybraces", premiumVariablesMenu(), nil),
            ("Kho nháp", "archivebox", premiumVaultMenu(clipboard: false), nil),
            ("Bộ sưu tập", "folder", premiumVaultMenu(clipboard: true), nil),
            ("Máy tính", "calculator", nil, { [weak self] in self?.openPremiumCalculator() }),
            ("Định dạng", "textformat", premiumOfflineMenu(), nil),
            ("Văn bản", "selection.pin.in.out", premiumSelectionMenu(), nil),
            ("Bật/tắt Couple", "heart.fill", coupleHubMenu(), nil),
            ("Hội thoại", "bubble.left.and.bubble.right", studioMenu("Hội thoại"), nil),
            ("Tình cảm", "heart", studioMenu("Tình cảm"), nil),
            ("Công việc", "briefcase", studioMenu("Công việc"), nil),
            ("Viết lại", "wand.and.stars", studioMenu("Viết"), nil),
            ("Dịch", "globe", translatorMenu(), nil),
            ("Emoji", "face.smiling", emojiMenu(), nil),
            ("Prompt", "text.badge.plus", promptMenu(), nil),
            ("Đọc ảnh", "photo.text.rectangle", nil, { [weak self] in self?.recognizeRecipientFromCopiedScreenshot() }),
            ("Offline", "wifi.slash", offlineStudioMenu(), nil),
            ("Clipboard", "doc.on.clipboard", clipboardHubMenu(), nil),
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
        let sections: [(String, [String])] = [
            ("TYPING PREMIUM", ["Typing Premium"]),
            ("OFFLINE EDITION 4.0", ["Keyboard Pro", "Time Machine", "Text Studio", "Profiles", "Ký tự Pro"]),
            ("PERSONAL INTELLIGENCE 3.0", ["Personal AI", "Tone Mixer", "Arena", "Second Brain", "Mini Apps"]),
            ("PREMIUM 2.0", ["Command", "AI Premium", "Workflow", "Macro", "Biến mẫu", "Kho nháp", "Bộ sưu tập", "Máy tính", "Định dạng", "Văn bản"]),
            ("GIAO TIẾP THÔNG MINH", ["Hội thoại", "Tình cảm", "Bật/tắt Couple", "Công việc", "Dịch"]),
            ("SOẠN THẢO", ["Viết lại", "Mẫu câu", "Prompt", "Đọc ảnh", "Offline", "Bản nháp"]),
            ("TIỆN ÍCH", ["Emoji", "Clipboard", "Hoàn tác", "Làm lại", "Con trỏ", "Riêng tư", "Nhà cung cấp", "Văn phong"])
        ]
        let columns = view.bounds.width >= 420 ? 4 : (view.bounds.width < 300 ? 2 : 3)
        for (title, names) in sections {
            let section = UILabel()
            section.text = title
            section.font = .systemFont(ofSize: 10, weight: .semibold)
            section.textColor = palette.text.withAlphaComponent(0.75)
            section.accessibilityTraits = .header
            rows.addArrangedSubview(section)
            let items = names.compactMap { name in groups.first { $0.0 == name } }
            for start in stride(from: 0, to: items.count, by: columns) {
                let row = UIStackView()
                row.distribution = .fillEqually
                row.spacing = 6
                let end = min(start + columns, items.count)
                for spec in items[start..<end] {
                    let cell = IntelligenceToolCell(title: spec.0, symbol: spec.1, palette: palette)
                    if let menu = spec.2 { cell.menu = menu; cell.showsMenuAsPrimaryAction = true }
                    else if let action = spec.3 {
                        cell.addAction(UIAction { [weak self] _ in self?.closeIntelligenceHub(); action() }, for: .touchUpInside)
                    }
                    row.addArrangedSubview(cell)
                }
                for _ in (end-start)..<columns { row.addArrangedSubview(UIView()) }
                rows.addArrangedSubview(row)
            }
        }
        UIAccessibility.post(notification: .screenChanged, argument: label)
    }
    func closeIntelligenceHub() {
        guard intelligenceOverlay != nil else { return }
        intelligenceOverlay?.removeFromSuperview(); intelligenceOverlay = nil
        UIAccessibility.post(notification: .layoutChanged, argument: toolbarButtons[.tools])
    }
    func coupleHubMenu() -> UIMenu {
        let toggle = UIAction(title: KeyboardSettings.coupleEnabled ? "Tắt Couple" : "Bật Couple") { [weak self] _ in
            self?.closeIntelligenceHub(); self?.coupleTapped()
        }
        let styles = CoupleStyleCatalog.styles.map { style in
            UIAction(title: style.icon + " " + style.title, state: KeyboardSettings.coupleEnabled && KeyboardSettings.coupleStyle == style.id ? .on : .off) { [weak self] _ in
                KeyboardSettings.coupleEnabled = true
                KeyboardSettings.coupleStyle = style.id
                self?.closeIntelligenceHub()
                self?.updateCoupleTool()
                self?.showStatus("Couple: " + style.title)
            }
        }
        let quick=UIAction(title:"Couple Quick Mode",image:UIImage(systemName:"heart.text.square")){[weak self] _ in
            self?.openCoupleQuickMode()
        }
        return UIMenu(title: "Couple", children: [toggle,quick] + styles)
    }
    func clipboardHubMenu() -> UIMenu {
        let paste = UIAction(title: "Dán", image: UIImage(systemName: "doc.on.clipboard")) { [weak self] _ in
            self?.closeIntelligenceHub(); self?.pasteTapped()
        }
        let entries = ClipboardVault.items.map { value in
            UIAction(title: String(value.prefix(40))) { [weak self] _ in
                guard let self else { return }
                self.closeIntelligenceHub()
                self.cancelAIRequest()
                self.selectedText = value
                self.showStatus("Đã chọn clipboard · Nhấn AI")
            }
        }
        return UIMenu(title: "Clipboard", children: [paste] + entries)
    }
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
        let searchTerm = (textDocumentProxy.selectedText ?? recentWord).trimmingCharacters(in: .whitespacesAndNewlines)
        func makeAction(_ item: SymbolEntry) -> UIAction {
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
        }
        var menus: [UIMenuElement] = []
        if !searchTerm.isEmpty {
            let matches = SymbolCatalog.search(String(searchTerm.prefix(40)))
            menus.append(UIMenu(title: "Tìm theo từ đang gõ/chọn", children: matches.isEmpty
                ? [UIAction(title: "Không có kết quả", attributes: .disabled) { _ in }]
                : matches.map(makeAction)))
        }
        menus += SymbolCatalog.categories.dropFirst().map { category in
            UIMenu(title: category, children: SymbolCatalog.search("", category: category).map(makeAction))
        }
        return UIMenu(title: "Emoji & Symbol", children: menus)
    }
    func offlineStudioMenu() -> UIMenu {
        UIMenu(title: "Công cụ offline", children: [
            UIAction(title: "Trả lời theo mẫu") { [weak self] _ in self?.closeIntelligenceHub(); self?.offlineTapped() },
            UIAction(title: "Phân tích hội thoại trên máy") { [weak self] _ in
                guard let self else { return }
                self.closeIntelligenceHub()
                let source = self.selectedText.isEmpty ? (self.textDocumentProxy.selectedText ?? self.requestedInput()) : self.selectedText
                guard !source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { self.showStatus("Hãy nhập hoặc chọn nội dung trước."); return }
                let summary = ConversationLens.summary(ConversationLens.findings(in: source))
                let tone = ToneInspector.suggestions(for: source).joined(separator: "\n")
                self.show([ReplySuggestion(tone: "Phân tích offline", text: summary + (tone.isEmpty ? "" : "\n" + tone))])
            }
        ])
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
