import UIKit

extension KeyboardViewController {
    func clearPro6Transient() {
        pro6PopupWork?.cancel();pro6Popup?.removeFromSuperview();pro6Popup=nil
        pro6RepeatWork?.cancel();pro6RepeatWork=nil
        pro6DeleteAnchor=nil;pro6DeleteDocument=nil;pro6DeleteAfter=nil;pro6DeleteCount=0
        pro6LastSpace=nil;pro6Language=nil;pro6LastCorrectionAnchor=nil;pro6LastCorrectionDocument=nil
    }
    func showPro6Popup(_ sender:UIButton) {
        guard typingPro6.popup,!performanceMode,letterButtons.contains(sender),let title=sender.title(for:.normal),!title.isEmpty else{return}
        pro6PopupWork?.cancel();pro6Popup?.removeFromSuperview()
        let palette=KeyboardThemePalette.resolve(currentTheme)
        let label=UILabel();label.text=title;label.textAlignment = .center
        label.font = .systemFont(ofSize:30,weight:.medium);label.textColor=palette.text;label.backgroundColor=palette.modifier
        label.layer.cornerRadius=10;label.clipsToBounds=true;label.isUserInteractionEnabled=false;label.isAccessibilityElement=false
        let rect=sender.convert(sender.bounds,to:view)
        label.frame=CGRect(x:max(0,min(view.bounds.width-48,rect.midX-24)),y:max(0,rect.minY-45),width:48,height:48)
        view.addSubview(label);pro6Popup=label
        let job=DispatchWorkItem{[weak self,weak label] in label?.removeFromSuperview();self?.pro6Popup=nil}
        pro6PopupWork=job;DispatchQueue.main.asyncAfter(deadline:.now() + .milliseconds(160),execute:job)
    }
    func insertPro6Pair(_ key:String)->Bool {
        guard let closing=TypingProText.pair(key),(textDocumentProxy.selectedText?.isEmpty ?? true),
              textDocumentProxy.documentContextAfterInput?.first?.isLetter != true else{return false}
        resetPhraseContext();textDocumentProxy.insertText(key+closing)
        textDocumentProxy.adjustTextPosition(byCharacterOffset:-closing.count);return true
    }
    func applyPro6DoubleSpace()->Bool {
        defer{pro6LastSpace=nil}
        guard let last=pro6LastSpace,last.document==textDocumentProxy.documentIdentifier,
              Date().timeIntervalSince(last.time)<0.65,(textDocumentProxy.selectedText?.isEmpty ?? true),
              let context=textDocumentProxy.documentContextBeforeInput,context==last.before,
              context.last==" ",context.dropLast().last?.isLetter==true else{return false}
        resetPhraseContext();textDocumentProxy.deleteBackward();textDocumentProxy.insertText(". ")
        knownWordBoundary=true;recentWord="";updateCandidates()
        if autocapitalizeEnabled && !isShiftLocked {isUppercase=true;updateKeys()}
        return true
    }
    func contextualPro6Language()->BilingualComposer.Preference? {
        guard useSmartBilingual,bilingualPreference == .automatic,let context=textDocumentProxy.documentContextBeforeInput else{return nil}
        let words=PersonalPhraseModel.context(context).suffix(3)
        // Explicit technical/English surroundings do not override a Vietnamese
        // choice in ordinary mixed chat. Protect URL/email/code-like tokens.
        if let tail=context.split(whereSeparator:{$0.isWhitespace}).last,!context.hasSuffix(" "),
           tail.contains("@") || tail.contains("://") || tail.contains("_") {return .english}
        // A previous English phrase alone is not evidence that the next
        // word is English; never lock the composer out of Vietnamese.
        _ = words
        return nil
    }
    func recordPro6Feedback(source:String,target:String,accepted:Bool) {
        guard (typingPro6.corrections || vietnameseAutoCorrect.mode != "off"),learnWordsEnabled,!proPrivate,!KeyboardSettings.privateTypingMode else{return}
        if pro6FeedbackRevision != TypingProFeedback.revision {pro6Feedback=TypingProFeedback.current;pro6FeedbackRevision=TypingProFeedback.revision}
        pro6Feedback.record(source:source,target:target,accept:accepted)
        TypingProFeedback.current=pro6Feedback
    }
    @objc func pro6DeletePanned(_ gesture:UIPanGestureRecognizer) {
        guard typingPro6.backspacePan else{return}
        let proxy=textDocumentProxy
        switch gesture.state {
        case .began:
            guard (proxy.selectedText?.isEmpty ?? true),let before=proxy.documentContextBeforeInput,let after=proxy.documentContextAfterInput else{return}
            pro6DeleteAnchor=before;pro6DeleteAfter=after;pro6DeleteDocument=proxy.documentIdentifier;pro6DeleteCount=0
        case .changed:
            guard let before=pro6DeleteAnchor else{return}
            let dx=gesture.translation(in:gesture.view).x
            let words=dx < -25 ? min(5,Int(-dx/35)+1) : 0
            pro6DeleteCount=TypingProText.deletionCount(before,words:words)
            showStatus(pro6DeleteCount==0 ? "Hủy xóa" : "Thả để xóa \(words) từ")
        case .ended:
            defer{pro6DeleteAnchor=nil;pro6DeleteAfter=nil;pro6DeleteDocument=nil;pro6DeleteCount=0}
            guard pro6DeleteCount>0,proxy.documentIdentifier==pro6DeleteDocument,proxy.documentContextBeforeInput==pro6DeleteAnchor,proxy.documentContextAfterInput==pro6DeleteAfter,(proxy.selectedText?.isEmpty ?? true) else{return}
            let snapshot=proSnapshot();defer{recordProEdit(snapshot)}
            beginTyping();resetPhraseContext();resetBilingualComposition();resetProHangul()
            for _ in 0..<pro6DeleteCount{proxy.deleteBackward()}
            recentWord="";updateCandidates();tactileFeedback()
        default:
            pro6DeleteAnchor=nil;pro6DeleteAfter=nil;pro6DeleteDocument=nil;pro6DeleteCount=0
        }
    }
    func schedulePro6Repeat(_ gesture:UILongPressGestureRecognizer) {
        guard typingPro6.repeatEnabled,gesture.state == .began || gesture.state == .changed else{return}
        let document=textDocumentProxy.documentIdentifier
        let anchor=textDocumentProxy.documentContextBeforeInput
        let job=DispatchWorkItem{[weak self,weak gesture] in
            guard let self,let gesture,gesture.state == .began || gesture.state == .changed,
                  self.textDocumentProxy.documentIdentifier==document,self.textDocumentProxy.documentContextBeforeInput==anchor,
                  !(anchor ?? "").isEmpty,(self.textDocumentProxy.selectedText?.isEmpty ?? true) else{return}
            self.deleteTapped();self.schedulePro6Repeat(gesture)
        }
        pro6RepeatWork=job;DispatchQueue.main.asyncAfter(deadline:.now()+max(0.08,min(0.5,typingPro6.deleteRepeat)),execute:job)
    }
    func openPro6Continuation() {
        let context=textDocumentProxy.documentContextBeforeInput ?? ""
        let choices=personalPhraseSuggestions(context:context)
        guard !choices.isEmpty else{showStatus("Chưa có cụm từ đã học phù hợp.");return}
        show(choices.map{ReplySuggestion(tone:"Tiếp nối",text:$0)})
    }
    func pro6ToolsMenu()->UIMenu {
        let recovery=UIAction(title:"Khôi phục dấu tiếng Việt"){[weak self] _ in
            guard let self else{return};self.closeIntelligenceHub()
            let source=self.premiumSource()
            let document=self.textDocumentProxy.documentIdentifier
            let before=self.textDocumentProxy.documentContextBeforeInput
            let after=self.textDocumentProxy.documentContextAfterInput
            let selection=self.textDocumentProxy.selectedText
            let generation=self.candidateGeneration
            guard source.count<=180 else{self.showStatus("Chọn đoạn tối đa 180 ký tự.");return}
            let input=source,learned=self.proPrivate || !self.learnWordsEnabled ? [:] : self.learnedWords
            self.predictionQueue.async{[weak self] in
                let options=TypingProText.recover(input,vocabulary:SmartTyping.coreVietnameseWords+SmartTyping.vietnameseWords,learned:learned)
                DispatchQueue.main.async{[weak self] in
                    guard let self,self.textDocumentProxy.documentIdentifier==document,
                        self.candidateGeneration==generation,self.textDocumentProxy.documentContextBeforeInput==before,
                        self.textDocumentProxy.documentContextAfterInput==after,self.textDocumentProxy.selectedText==selection else{return}
                    if options.isEmpty{self.showStatus("Chọn văn bản không dấu trước.")}
                    else{self.show(options.map{ReplySuggestion(tone:"Khôi phục dấu",text:$0)})}
                }
            }
        }
        let punctuation=UIAction(title:"Gợi ý dấu câu"){[weak self] _ in
            guard let self else{return};self.closeIntelligenceHub()
            let options=TypingProText.punctuation(self.premiumSource())
            if options.isEmpty{self.showStatus("Chọn đoạn văn trước.")}else{self.show(options.map{ReplySuggestion(tone:"Dấu câu",text:$0)})}
        }
        let number=UIAction(title:"Định dạng số (nghìn)"){[weak self] _ in
            guard let self else{return};self.closeIntelligenceHub()
            guard let result=TypingProText.grouping(self.premiumSource()) else{self.showStatus("Chọn số nguyên 4–15 chữ số, không bắt đầu bằng 0.");return}
            self.show([ReplySuggestion(tone:"Định dạng số",text:result)])
        }
        let inspector=UIAction(title:"Kiểm tra sửa từ gần nhất"){[weak self] _ in
            guard let self else{return};self.closeIntelligenceHub()
            guard let change=self.lastWordReplacement else{self.showStatus("Chưa có sửa từ.");return}
            self.showStatus(change.original+" → "+change.corrected+" · gợi ý đã chọn")
        }
        let undo=UIAction(title:"Hoàn tác sửa từ"){[weak self] _ in self?.closeIntelligenceHub();self?.undoWordCorrection()}
        return UIMenu(title:"Ngôn ngữ & sửa lỗi",children:[recovery,punctuation,number,inspector,undo])
    }
}
