import UIKit

extension KeyboardViewController {
    func premiumSource() -> String {
        String((selectedText.isEmpty ? (textDocumentProxy.selectedText ?? requestedInput()) : selectedText).prefix(3000))
    }
    func executePremium(_ command: PremiumCommand, source: String? = nil) {
        closeIntelligenceHub()
        let value = source ?? premiumSource()
        if command.isAI { runPremiumAI(title:command.title,source:value,steps:[command.id]); return }
        let result:String
        switch command.id {
        case "tinh": openPremiumCalculator(); return
        case "canhbao": result = PremiumOffline.guardian(value)
        case "ngay","gio": result = PremiumOffline.variables("{{"+command.id+"}}",name:"",custom:[:])
        default: result = PremiumOffline.format(value,mode:command.id)
        }
        guard !result.isEmpty else { showStatus("Chưa có văn bản."); return }
        show([ReplySuggestion(tone:command.title,text:result)])
    }
    func runPremiumAI(title:String, source:String, steps:[String]) {
        guard !isRequestRunning, hasFullAccess, KeyboardSettings.allowCloudAI,
              !source.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty, MessageSafety.warnings(in:source).isEmpty else {
            showStatus("Cần văn bản an toàn, Full Access và AI online."); return
        }
        let ticket = UUID(); requestID = ticket; isRequestRunning = true
        let document = textDocumentProxy.documentIdentifier
        let persona = PersonaStore.activeID
        let provider = KeyboardSettings.provider
        showStatus("Đang xử lý · "+title)
        aiTask = Task { [weak self] in
            do {
                let result = try await PremiumWorkflowService.run(source,steps:steps,provider:provider)
                guard let self, self.requestID == ticket else { return }
                self.isRequestRunning = false
                guard self.textDocumentProxy.documentIdentifier == document, PersonaStore.activeID == persona else { return }
                self.show([ReplySuggestion(tone:title,text:result)])
            } catch {
                guard let self, self.requestID == ticket else { return }
                self.isRequestRunning = false; self.showStatus(error.localizedDescription)
            }
        }
    }
    func premiumAIMenu() -> UIMenu {
        let personalities = UIMenu(title:"Personality Switch",children:PremiumCommands.personalities.compactMap(PremiumCommands.find).map { command in
            UIAction(title:command.title) { [weak self] _ in self?.executePremium(command) }
        })
        let entries = PremiumCommands.all.filter { $0.isAI && !PremiumCommands.personalities.contains($0.id) }.map { command in
            UIAction(title:command.title,image:UIImage(systemName:command.symbol)) { [weak self] _ in self?.executePremium(command) }
        }
        return UIMenu(title:"AI Premium",children:[personalities]+entries)
    }
    func premiumOfflineMenu() -> UIMenu {
        UIMenu(title:"Offline",children:PremiumCommands.all.filter { !$0.isAI }.map { command in
            UIAction(title:command.title) { [weak self] _ in self?.executePremium(command) }
        })
    }
    func premiumWorkflowMenu() -> UIMenu {
        let items = PremiumStore.workflows.map { flow in
            UIAction(title:flow.title+" · "+String(flow.steps.count)+" bước") { [weak self] _ in
                guard let self else { return }; self.closeIntelligenceHub()
                self.runPremiumAI(title:flow.title,source:self.premiumSource(),steps:flow.steps)
            }
        }
        return UIMenu(title:"Workflow · tạo trong app ViePN",children:items.isEmpty ? [UIAction(title:"Chưa có workflow",attributes:.disabled){_ in}] : items)
    }
    func premiumMacroMenu() -> UIMenu {
        let items = PremiumStore.macros.map { macro in
            UIAction(title:macro.title) { [weak self] _ in
                guard let self else { return }; self.closeIntelligenceHub()
                guard !KeyboardSettings.privateTypingMode else { self.showStatus("Tắt gõ riêng tư để dùng macro cá nhân."); return }
                let value = PremiumOffline.variables(macro.template,name:PersonaStore.active?.name ?? "",custom:PremiumStore.variables)
                if macro.steps.isEmpty { self.show([ReplySuggestion(tone:macro.title,text:value)]) }
                else { self.runPremiumAI(title:macro.title,source:value,steps:macro.steps) }
            }
        }
        return UIMenu(title:"Macro · tạo trong app ViePN",children:items.isEmpty ? [UIAction(title:"Chưa có macro",attributes:.disabled){_ in}] : items)
    }
    func premiumVariablesMenu() -> UIMenu {
        let keys = ["ngay","gio","ten"] + PremiumStore.variables.keys.sorted().filter { !["ngay","gio","ten"].contains($0) }
        return UIMenu(title:"Biến mẫu",children:keys.map { key in
            UIAction(title:"{{"+key+"}}") { [weak self] _ in
                guard let self else { return }; self.closeIntelligenceHub()
                guard !KeyboardSettings.privateTypingMode || ["ngay","gio"].contains(key) else { self.showStatus("Đang gõ riêng tư."); return }
                let text = PremiumOffline.variables("{{"+key+"}}",name:PersonaStore.active?.name ?? "",custom:PremiumStore.variables)
                self.show([ReplySuggestion(tone:"Biến mẫu",text:text)])
            }
        })
    }
    func premiumVaultMenu(clipboard:Bool) -> UIMenu {
        let notes = clipboard ? PremiumStore.clipboard : PremiumStore.drafts
        let folders = PremiumStore.categories.map { category in
            UIMenu(title:category,children:[UIAction(title:"Lưu nội dung hiện tại") { [weak self] _ in
                guard let self else { return }; self.closeIntelligenceHub()
                let text = self.premiumSource()
                let saved = PremiumStore.save(text,title:String(text.prefix(40)),category:category,isClipboard:clipboard)
                self.showStatus(saved ? "Đã lưu vào "+category : "Không lưu: riêng tư, nhạy cảm, trống hoặc quá dài.")
            }] + notes.filter { $0.category == category }.map { note in
                UIAction(title:note.title) { [weak self] _ in
                    guard let self else { return }; self.closeIntelligenceHub(); self.show([ReplySuggestion(tone:category,text:note.text)])
                }
            })
        }
        return UIMenu(title:clipboard ? "Clipboard Collections" : "Draft Vault",children:folders)
    }
}
