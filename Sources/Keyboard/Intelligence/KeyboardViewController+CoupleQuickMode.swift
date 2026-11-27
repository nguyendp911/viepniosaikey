import UIKit

extension KeyboardViewController {
    /// No automatic clipboard read or host rewrite. User explicitly chooses
    /// an incoming message and previews the reply in the existing reply panel.
    func openCoupleQuickMode(){
        let (stack,palette)=premiumPanel(title:"Couple Quick Mode")
        let draft=premiumKey("Dùng nội dung đang soạn",palette:palette){[weak self] in
            guard let self else{return}
            let value=self.inlineHostSource()
            guard !value.isEmpty,value.count<=2700 else{self.showStatus("Cần nội dung tối đa 2.700 ký tự.");return}
            self.coupleQuickStyles(source:value)
        }
        draft.heightAnchor.constraint(equalToConstant:44).isActive=true;stack.addArrangedSubview(draft)
        let info=UILabel();info.text="Chọn nội dung nhận được. Không tự gửi hay thay văn bản.";info.font = .systemFont(ofSize:12);info.textColor=palette.text;info.numberOfLines=2;stack.addArrangedSubview(info)
        let selected=premiumKey("Dùng đoạn đang chọn",palette:palette){[weak self] in
            guard let self,let value=self.textDocumentProxy.selectedText,!value.isEmpty,value.count<=2700 else{self?.showStatus("Hãy chọn đoạn tin nhắn tối đa 2.700 ký tự.");return}
            self.coupleQuickStyles(source:value)
        }
        selected.heightAnchor.constraint(equalToConstant:44).isActive=true;stack.addArrangedSubview(selected)
        let pasted=premiumKey("Đọc clipboard đã sao chép",palette:palette){[weak self] in
            guard let self,self.hasFullAccess else{self?.showStatus("Cần quyền truy cập đầy đủ để đọc clipboard.");return}
            guard let value=UIPasteboard.general.string,!value.isEmpty,value.count<=2700 else{self.showStatus("Clipboard trống hoặc dài quá 2.700 ký tự.");return}
            self.coupleQuickStyles(source:value)
        };pasted.heightAnchor.constraint(equalToConstant:44).isActive=true;stack.addArrangedSubview(pasted)
        stack.addArrangedSubview(UIView())
    }
    private func coupleQuickStyles(source:String){
        guard let target=CoupleTranscript.target(source) else{showStatus("Chọn tin nhắn nhận được, không chọn lời của chính bạn.");return}
        let document=textDocumentProxy.documentIdentifier,before=textDocumentProxy.documentContextBeforeInput,after=textDocumentProxy.documentContextAfterInput,selection=textDocumentProxy.selectedText
        let (stack,palette)=premiumPanel(title:"Chọn giọng Couple")
        let preview=UITextView();preview.isEditable=false;preview.text=target.text;preview.textColor=palette.text;preview.backgroundColor=palette.key;preview.font = .systemFont(ofSize:13)
        stack.addArrangedSubview(preview)
        let ids=["cold","hurt","sulky","coldwarm","gentle","mature"]
        for start in stride(from:0,to:ids.count,by:2){
            let row=UIStackView();row.axis = .horizontal;row.spacing=5;row.distribution = .fillEqually
            for id in ids[start..<min(start+2,ids.count)]{
                let style=CoupleStyleCatalog.selected(id)
                let key=premiumKey(style.title,palette:palette){[weak self] in
                    guard let self else{return}
                    self.closeIntelligenceHub()
                    guard self.textDocumentProxy.documentIdentifier==document,self.textDocumentProxy.documentContextBeforeInput==before,self.textDocumentProxy.documentContextAfterInput==after,self.textDocumentProxy.selectedText==selection else{self.showStatus("Vị trí nhập đã thay đổi.");return}
                    let context=ConversationContextResolver.resolve(target.text)
                    var replies:[ReplySuggestion]
                    if let family=ConversationContextResolver.offlineFamilyReplies(for:target.text,context:context){replies=family}
                    else if !context.romanticInstructionsAllowed{replies=OfflineReplyEngine.suggest(for:target.text)}
                    else{
                        var prefs=CoupleStudioPreferences.current;prefs.customEmotion=false
                        replies=CoupleLocalEngine.suggest(source,style:id,address:KeyboardSettings.coupleAddress,preferences:prefs)
                        if CoupleSignature.enabled && !KeyboardSettings.privateTypingMode && !self.proPrivate{
                            let signature=CoupleSignature.current
                            replies=replies.map{.init(tone:$0.tone,text:signature.personalize($0.text))}
                        }
                    }
                    self.show(replies)
                };row.addArrangedSubview(key)
            }
            row.heightAnchor.constraint(equalToConstant:36).isActive=true;stack.addArrangedSubview(row)
        }
    }
}
