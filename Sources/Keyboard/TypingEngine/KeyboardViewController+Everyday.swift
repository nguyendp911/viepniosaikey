import UIKit

extension KeyboardViewController {
    var isEverydayLandscape:Bool {
        view.window?.windowScene?.interfaceOrientation.isLandscape ?? (traitCollection.verticalSizeClass == .compact)
    }
    func recordEverydayTouch(_ point:CGPoint) {
        guard everyday7.heatmap,!proPrivate,view.bounds.width>0,view.bounds.height>0 else{return}
        if everydayHeatmapRevision != EverydayTouchMap.revision {
            everydayHeatmap=EverydayTouchMap.current;everydayHeatmapRevision=EverydayTouchMap.revision
        }
        everydayHeatmap.record(x:Double(point.x/view.bounds.width),y:Double(point.y/view.bounds.height))
        everydayHeatmapDirty=true
        if typingTouchCount%50==0{flushEverydayHeatmap()}
    }
    func flushEverydayHeatmap() {
        guard everydayHeatmapDirty,!proPrivate,everyday7.heatmap,everydayHeatmapRevision==EverydayTouchMap.revision else{return}
        everydayHeatmapDirty=false;EverydayTouchMap.current=everydayHeatmap
    }
    func acceptEverydayCompletion() {
        guard let label=everydayCompletionLabel,let index=candidateWords.firstIndex(of:label),
              (nextWordAnchor != nil || learnedPhraseChoices[label] != nil) else{showStatus("Chưa có câu tiếp nối phù hợp");return}
        let button=UIButton();button.tag=index;candidateTapped(button)
    }
    @objc func everydayExpandTapped() {
        guard !candidateWords.isEmpty else{showStatus("Chưa có gợi ý phù hợp");return}
        let generation=candidateGeneration,document=textDocumentProxy.documentIdentifier
        let before=textDocumentProxy.documentContextBeforeInput,after=textDocumentProxy.documentContextAfterInput
        let (stack,palette)=premiumPanel(title:"Gợi ý mở rộng")
        let scroll=UIScrollView();let list=UIStackView();list.axis = .vertical;list.spacing=5;list.translatesAutoresizingMaskIntoConstraints=false
        scroll.addSubview(list);stack.addArrangedSubview(scroll)
        NSLayoutConstraint.activate([list.leadingAnchor.constraint(equalTo:scroll.contentLayoutGuide.leadingAnchor),list.trailingAnchor.constraint(equalTo:scroll.contentLayoutGuide.trailingAnchor),list.topAnchor.constraint(equalTo:scroll.contentLayoutGuide.topAnchor),list.bottomAnchor.constraint(equalTo:scroll.contentLayoutGuide.bottomAnchor),list.widthAnchor.constraint(equalTo:scroll.frameLayoutGuide.widthAnchor)])
        // Preserve all original options; an expanded glide choice can use the existing handler.
        let options=pendingGlideWord == nil ? candidateWords+everydayExpandedChoices : fullGlideOptions
        for option in options.prefix(24) {
            let key=premiumKey(option,palette:palette){[weak self] in
                guard let self else{return};self.closeIntelligenceHub()
                guard self.candidateGeneration==generation,self.textDocumentProxy.documentIdentifier==document,
                      self.textDocumentProxy.documentContextBeforeInput==before,self.textDocumentProxy.documentContextAfterInput==after else{self.showStatus("Ngữ cảnh đã thay đổi");return}
                if !self.candidateWords.contains(option){
                    if self.pendingGlideWord != nil{self.renderCandidates(self.fullGlideOptions)}
                    else if self.everydayExpandedChoices.contains(option){self.renderCandidates(self.candidateWords+[option])}
                }
                guard let index=self.candidateWords.firstIndex(of:option)else{return}
                let button=UIButton();button.tag=index;self.candidateTapped(button)
            };key.heightAnchor.constraint(greaterThanOrEqualToConstant:38).isActive=true;list.addArrangedSubview(key)
        }
    }
    func everydayPastePreview() {
        guard hasFullAccess else{showStatus("Cần Cho phép truy cập đầy đủ để đọc clipboard");return}
        guard let value=UIPasteboard.general.string,!value.isEmpty,value.count<=6000 else{showStatus("Clipboard trống hoặc dài quá 6.000 ký tự");return}
        let document=textDocumentProxy.documentIdentifier,before=textDocumentProxy.documentContextBeforeInput,after=textDocumentProxy.documentContextAfterInput,selection=textDocumentProxy.selectedText
        let (stack,palette)=premiumPanel(title:"Xem trước clipboard")
        let preview=UITextView();preview.isEditable=false;preview.text=value;preview.textColor=palette.text;preview.backgroundColor=palette.key
        preview.font = .systemFont(ofSize:15);stack.addArrangedSubview(preview)
        let insert=premiumKey("Dán vào vị trí hiện tại",palette:palette){[weak self] in
            guard let self else{return};self.closeIntelligenceHub()
            guard self.textDocumentProxy.documentIdentifier==document,self.textDocumentProxy.documentContextBeforeInput==before,self.textDocumentProxy.documentContextAfterInput==after,self.textDocumentProxy.selectedText==selection else{self.showStatus("Vị trí nhập đã thay đổi");return}
            self.insertProExplicit(value)
        }
        insert.heightAnchor.constraint(equalToConstant:42).isActive=true;stack.addArrangedSubview(insert)
    }
    func everydaySelectionPanel() {
        guard let before=textDocumentProxy.documentContextBeforeInput,!before.isEmpty else{showStatus("Không có văn bản trước con trỏ");return}
        let proxy=textDocumentProxy,document=proxy.documentIdentifier,after=proxy.documentContextAfterInput
        let (stack,palette)=premiumPanel(title:"Phạm vi trước con trỏ")
        let label=UILabel();label.numberOfLines=3;label.textColor=palette.text;label.font = .systemFont(ofSize:14);stack.addArrangedSubview(label)
        let slider=UISlider();slider.minimumValue=1;slider.maximumValue=Float(min(80,before.count));slider.value=min(10,slider.maximumValue)
        let render={ label.text=String(before.suffix(Int(slider.value.rounded()))) }
        render();slider.addAction(UIAction{_ in render()},for:.valueChanged);stack.addArrangedSubview(slider)
        let copy=premiumKey("Sao chép phạm vi",palette:palette){[weak self] in
            guard let self,self.hasFullAccess else{self?.showStatus("Cần quyền truy cập đầy đủ để sao chép");return}
            guard self.textDocumentProxy.documentIdentifier==document,self.textDocumentProxy.documentContextBeforeInput==before,self.textDocumentProxy.documentContextAfterInput==after else{self.closeIntelligenceHub();return}
            UIPasteboard.general.string=String(before.suffix(Int(slider.value.rounded())));self.closeIntelligenceHub();self.showStatus("Đã sao chép")
        };stack.addArrangedSubview(copy)
        let move=premiumKey("Di chuyển con trỏ về đầu phạm vi",palette:palette){[weak self] in
            guard let self,self.textDocumentProxy.documentIdentifier==document,self.textDocumentProxy.documentContextBeforeInput==before,self.textDocumentProxy.documentContextAfterInput==after,(self.textDocumentProxy.selectedText?.isEmpty ?? true) else{self?.closeIntelligenceHub();return}
            self.closeIntelligenceHub();self.beginTyping();self.resetPhraseContext();self.resetBilingualComposition()
            self.textDocumentProxy.adjustTextPosition(byCharacterOffset:-Int(slider.value.rounded()));self.recentWord="";self.updateCandidates()
        };stack.addArrangedSubview(move)
        stack.addArrangedSubview(UIView())
    }
    func everydayToolsMenu()->UIMenu {
        UIMenu(title:"Everyday 7.0",children:[
            UIAction(title:"Gợi ý mở rộng"){[weak self] _ in self?.everydayExpandTapped()},
            UIAction(title:"Xem trước & dán"){[weak self] _ in self?.everydayPastePreview()},
            UIAction(title:"Phạm vi văn bản / con trỏ"){[weak self] _ in self?.everydaySelectionPanel()},
            UIAction(title:"Kiểm tra chính tả từ hiện tại"){[weak self] _ in
                guard let self else{return};self.closeIntelligenceHub()
                let word=String((self.textDocumentProxy.documentContextBeforeInput ?? "").reversed().prefix(while:{$0.isLetter}).reversed())
                let options=EverydayLanguage.spell(word,known:SmartTyping.vietnameseSet)
                guard !options.isEmpty else{self.showStatus("Không có phương án trong từ điển kiểm tra");return}
                self.show(options.map{ReplySuggestion(tone:"Chính tả · xem lại ngữ cảnh",text:$0)})
            },
            UIAction(title:everyday7.silent ? "Thoát hồ sơ yên lặng" : "Bật hồ sơ yên lặng"){[weak self] _ in
                guard let self else{return};self.everyday7.silent.toggle();EverydayPreferences.current=self.everyday7;self.closeIntelligenceHub()
                self.showStatus(self.everyday7.silent ? "Đã chọn hồ sơ yên lặng" : "Đã khôi phục âm thanh/rung cũ")
            }
        ])
    }
}
