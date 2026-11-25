import UIKit

extension KeyboardViewController {
    func personalAIToolsMenu()->UIMenu {
        UIMenu(title:"Personal AI",children:PersonalIntelligenceCatalog.tasks.filter{$0.id != "memory"}.map{task in
            UIAction(title:task.title,image:UIImage(systemName:task.symbol)){[weak self] _ in
                guard let self else{return};self.closeIntelligenceHub()
                self.runPersonalAI(title:task.title,source:self.premiumSource(),instruction:task.instruction)
            }
        })
    }
    func personalToneMenu()->UIMenu {
        let presets=PersonalIntelligenceSettings.presets
        let list=[TonePreset(title:"Cân bằng",mix:ToneMix())]+presets
        return UIMenu(title:"Tone Mixer · tạo preset trong app",children:list.map{preset in
            UIAction(title:preset.title){[weak self] _ in
                guard let self else{return};self.closeIntelligenceHub()
                self.runPersonalAI(title:preset.title,source:self.premiumSource(),instruction:preset.mix.instruction)
            }
        })
    }
    func personalMemoryMenu()->UIMenu {
        // Use only current recipient; user explicitly picks one record each time.
        let scoped=PersonalMemoryStore.scoped(PersonalMemoryStore.all,personaID:PersonaStore.activeID)
        let actions=scoped.prefix(20).map{item in
            UIAction(title:item.kind+" · "+item.title){[weak self] _ in
                guard let self else{return}
                self.closeIntelligenceHub()
                guard !KeyboardSettings.privateTypingMode,PersonaStore.activeID==item.personaID else{self.showStatus("Hồ sơ đã đổi hoặc đang gõ riêng tư.");return}
                let context=PersonalMemoryStore.context(PersonalMemoryStore.all,selected:[item.id],personaID:item.personaID)
                let source=self.premiumSource()
                guard !context.isEmpty,!source.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty else{self.showStatus("Cần nội dung và bộ nhớ hợp lệ.");return}
                self.confirmPersonalMemory(source:source,context:context,persona:item.personaID)
            }
        }
        return UIMenu(title:"Second Brain · chọn dữ kiện",children:actions.isEmpty ? [UIAction(title:"Chưa có bộ nhớ cho hồ sơ",attributes:.disabled){_ in}] : actions)
    }
    func confirmPersonalMemory(source:String,context:String,persona:String){
        let (stack,palette)=premiumPanel(title:"Xác nhận bối cảnh AI")
        let text=UILabel();text.text=String(context.prefix(1000));text.numberOfLines=0;text.font=.systemFont(ofSize:13);text.textColor=palette.text
        let scroll=UIScrollView();text.translatesAutoresizingMaskIntoConstraints=false;scroll.addSubview(text)
        NSLayoutConstraint.activate([text.leadingAnchor.constraint(equalTo:scroll.contentLayoutGuide.leadingAnchor),text.trailingAnchor.constraint(equalTo:scroll.contentLayoutGuide.trailingAnchor),text.topAnchor.constraint(equalTo:scroll.contentLayoutGuide.topAnchor),text.bottomAnchor.constraint(equalTo:scroll.contentLayoutGuide.bottomAnchor),text.widthAnchor.constraint(equalTo:scroll.frameLayoutGuide.widthAnchor)])
        stack.addArrangedSubview(scroll)
        let doc=textDocumentProxy.documentIdentifier
        stack.addArrangedSubview(premiumKey("Gửi dữ kiện này cùng nội dung",palette:palette){[weak self] in
            guard let self else{return};self.closeIntelligenceHub()
            guard self.textDocumentProxy.documentIdentifier==doc,PersonaStore.activeID==persona else{self.showStatus("Ngữ cảnh đã thay đổi.");return}
            self.runPersonalAI(title:"Second Brain",source:"Tin nhắn:\n"+String(source.prefix(1800))+"\nDữ kiện đã chọn:\n"+context,instruction:PersonalIntelligenceCatalog.task("memory")!.instruction)
        })
    }
    func runPersonalAI(title:String,source:String,instruction:String){
        guard !isRequestRunning,hasFullAccess,KeyboardSettings.allowCloudAI,!source.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty,MessageSafety.warnings(in:source).isEmpty else{showStatus("Cần Full Access, AI online và dữ liệu không nhạy cảm.");return}
        let ticket=UUID();requestID=ticket;isRequestRunning=true
        let document=textDocumentProxy.documentIdentifier;let persona=PersonaStore.activeID;let provider=KeyboardSettings.provider
        showStatus("Đang xử lý · "+title)
        aiTask = Task{[weak self] in
            do{
                let value=try await AIWritingService.studio(source,instruction:instruction,provider:provider)
                guard let self,self.requestID==ticket else{return};self.isRequestRunning=false
                guard self.textDocumentProxy.documentIdentifier==document,PersonaStore.activeID==persona else{return}
                self.show([ReplySuggestion(tone:title,text:value)])
            }catch{guard let self,self.requestID==ticket else{return};self.isRequestRunning=false;self.showStatus(error.localizedDescription)}
        }
    }
    func personalArena(){
        let source=premiumSource()
        guard !isRequestRunning,hasFullAccess,KeyboardSettings.allowCloudAI,!source.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty,MessageSafety.warnings(in:source).isEmpty else{showStatus("Cần Full Access, AI online và dữ liệu không nhạy cảm.");return}
        let (stack,palette)=premiumPanel(title:"Response Arena")
        let label=UILabel();label.text="Gửi cùng nội dung đến Gemini và OpenAI. Hai yêu cầu API; cần hai khóa. Kết quả chỉ để xem trước.";label.numberOfLines=0;label.textColor=palette.text;label.font=.systemFont(ofSize:14)
        stack.addArrangedSubview(label)
        let document=textDocumentProxy.documentIdentifier;let persona=PersonaStore.activeID
        stack.addArrangedSubview(premiumKey("Xác nhận so sánh",palette:palette){[weak self] in
            guard let self else{return};self.closeIntelligenceHub()
            guard self.textDocumentProxy.documentIdentifier==document,PersonaStore.activeID==persona,self.hasFullAccess,KeyboardSettings.allowCloudAI,!self.isRequestRunning else{return}
            let ticket=UUID();self.requestID=ticket;self.isRequestRunning=true;self.showStatus("Đang so sánh hai AI…")
            self.aiTask = Task{[weak self] in
                let results=await PersonalAIService.arena(source)
                guard let self,self.requestID==ticket else{return};self.isRequestRunning=false
                guard self.textDocumentProxy.documentIdentifier==document,PersonaStore.activeID==persona else{return}
                let suggestions=results.compactMap{item in item.text.map{ReplySuggestion(tone:item.id=="gemini" ? "Gemini" : "OpenAI",text:$0)}}
                if suggestions.isEmpty{self.showStatus("Cả hai AI không trả kết quả. Kiểm tra khóa và hạn mức.")}
                else{self.show(suggestions);if suggestions.count==1{self.showStatus("Một nhà cung cấp không trả kết quả.")}}
            }
        })
    }
}
