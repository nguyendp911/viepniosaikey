import UIKit

extension KeyboardViewController {
    func openToolSearch(){
        let (stack,palette)=premiumPanel(title:"Tìm công cụ")
        let label=UILabel();label.textColor=palette.text;label.font = .systemFont(ofSize:14);label.text="Tìm không dấu";stack.addArrangedSubview(label)
        let scroll=UIScrollView(), list=UIStackView();list.axis = .vertical;list.spacing=4;list.translatesAutoresizingMaskIntoConstraints=false
        scroll.addSubview(list);stack.addArrangedSubview(scroll)
        NSLayoutConstraint.activate([list.leadingAnchor.constraint(equalTo:scroll.contentLayoutGuide.leadingAnchor),list.trailingAnchor.constraint(equalTo:scroll.contentLayoutGuide.trailingAnchor),list.topAnchor.constraint(equalTo:scroll.contentLayoutGuide.topAnchor),list.bottomAnchor.constraint(equalTo:scroll.contentLayoutGuide.bottomAnchor),list.widthAnchor.constraint(equalTo:scroll.frameLayoutGuide.widthAnchor)])
        var query=""
        let groups=toolStudioGroups()
        let refresh:()->Void={ [weak self,weak list,weak label] in
            guard let self,let list else{return}
            label?.text=query.isEmpty ? "Tìm không dấu":query
            list.arrangedSubviews.forEach{list.removeArrangedSubview($0);$0.removeFromSuperview()}
            for spec in groups.filter({ToolStudioCatalog.matches($0.0,query:query)}){
                let cell=self.premiumKey(spec.0,palette:palette){[weak self] in
                    if let action=spec.3{self?.closeIntelligenceHub();action()}
                }
                if let menu=spec.2{cell.menu=menu;cell.showsMenuAsPrimaryAction=true}
                cell.heightAnchor.constraint(equalToConstant:34).isActive=true;list.addArrangedSubview(cell)
            }
        }
        for letters in ["qwertyuiop","asdfghjkl","zxcvbnm"]{
            let row=UIStackView();row.spacing=3;row.distribution = .fillEqually
            for letter in letters{row.addArrangedSubview(premiumKey(String(letter),palette:palette){if query.count<40{query.append(letter);refresh()}})}
            if letters=="zxcvbnm"{row.addArrangedSubview(premiumKey("⌫",palette:palette){if !query.isEmpty{query.removeLast();refresh()}})}
            row.heightAnchor.constraint(equalToConstant:28).isActive=true;stack.addArrangedSubview(row)
        }
        let controls=UIStackView();controls.distribution = .fillEqually;controls.spacing=4
        controls.addArrangedSubview(premiumKey("Cách",palette:palette){if query.count<40{query+=" ";refresh()}})
        controls.addArrangedSubview(premiumKey("Xóa tìm",palette:palette){query="";refresh()})
        controls.addArrangedSubview(premiumKey("Tất cả",palette:palette){[weak self] in self?.openIntelligenceHub()})
        controls.heightAnchor.constraint(equalToConstant:28).isActive=true;stack.addArrangedSubview(controls);refresh()
    }
    func openToolTextEditor(){
        let (stack,palette)=premiumPanel(title:"Smart Text Editor")
        let selected=premiumKey("Văn bản đang chọn",palette:palette){[weak self] in
            guard let self,let source=self.textDocumentProxy.selectedText,!source.isEmpty,source.count<=3000 else{self?.showStatus("Chọn văn bản tối đa 3.000 ký tự");return}
            self.toolTransformPreview(source,allowReplace:true)
        }
        let clipboard=premiumKey("Đọc clipboard",palette:palette){[weak self] in
            guard let self,self.hasFullAccess,let source=UIPasteboard.general.string,!source.isEmpty,source.count<=3000 else{self?.showStatus("Cần Full Access và clipboard tối đa 3.000 ký tự");return}
            self.toolTransformPreview(source,allowReplace:false)
        }
        let before=premiumKey("Xem phần văn bản trước con trỏ",palette:palette){[weak self] in
            guard let self,let source=self.textDocumentProxy.documentContextBeforeInput,!source.isEmpty,source.count<=3000 else{self?.showStatus("Không có ngữ cảnh phù hợp");return}
            self.toolTransformPreview(source,allowReplace:false)
        }
        for key in [selected,clipboard,before]{key.heightAnchor.constraint(equalToConstant:42).isActive=true;stack.addArrangedSubview(key)}
        let notice=UILabel();notice.text="Không tự sửa văn bản. Chỉ thay đoạn được chọn rõ ràng.";notice.numberOfLines=2;notice.font = .systemFont(ofSize:12);notice.textColor=palette.text;stack.addArrangedSubview(notice);stack.addArrangedSubview(UIView())
    }
    private func toolTransformPreview(_ source:String,allowReplace:Bool){
        let proxy=textDocumentProxy,doc=proxy.documentIdentifier,before=proxy.documentContextBeforeInput,after=proxy.documentContextAfterInput,selection=proxy.selectedText
        let (stack,palette)=premiumPanel(title:"Xem trước văn bản")
        let preview=UITextView();preview.isEditable=false;preview.text=source;preview.backgroundColor=palette.key;preview.textColor=palette.text;preview.font = .systemFont(ofSize:14);stack.addArrangedSubview(preview)
        var output=source
        let transform=UIButton(type:.system)
        transform.setTitle("Chọn định dạng",for:.normal);transform.tintColor=palette.text
        transform.menu=UIMenu(title:"Định dạng",children:ToolTextTransform.allCases.map{mode in
            UIAction(title:mode.title){[weak preview] _ in
                if let value=mode.apply(source){output=value;preview?.text=value}
            }
        }+[UIAction(title:"Khôi phục bản gốc"){[weak preview] _ in output=source;preview?.text=source}])
        transform.showsMenuAsPrimaryAction=true;transform.heightAnchor.constraint(equalToConstant:36).isActive=true;stack.addArrangedSubview(transform)
        let buttons=UIStackView();buttons.spacing=5;buttons.distribution = .fillEqually
        buttons.addArrangedSubview(premiumKey("Sao chép",palette:palette){[weak self] in
            guard let self,self.hasFullAccess else{self?.showStatus("Cần Full Access");return}
            UIPasteboard.general.string=output;self.closeIntelligenceHub();self.showStatus("Đã sao chép")
        })
        buttons.addArrangedSubview(premiumKey(allowReplace ? "Thay đoạn chọn":"Chèn",palette:palette){[weak self] in
            guard let self else{return};self.closeIntelligenceHub()
            let p=self.textDocumentProxy
            guard !output.isEmpty,p.documentIdentifier==doc,p.documentContextBeforeInput==before,p.documentContextAfterInput==after,p.selectedText==selection,
                  allowReplace ? selection==source : (selection?.isEmpty ?? true) else{self.showStatus("Vị trí nhập đã thay đổi hoặc đang chọn văn bản");return}
            self.resetPhraseContext();self.resetAutoWord();self.autoPreviousWord=nil
            self.insertProExplicit(output)
        })
        buttons.heightAnchor.constraint(equalToConstant:40).isActive=true;stack.addArrangedSubview(buttons)
    }
    func openToolClipboard(){
        guard !proPrivate,!KeyboardSettings.privateTypingMode else{showStatus("Không hiển thị dữ liệu clipboard trong gõ riêng tư");return}
        let (stack,palette)=premiumPanel(title:"Clipboard Studio")
        let actions=UIStackView();actions.distribution = .fillEqually;actions.spacing=4
        actions.addArrangedSubview(premiumKey("Xem clipboard",palette:palette){[weak self] in self?.everydayPastePreview()})
        actions.addArrangedSubview(premiumKey("Lưu clipboard",palette:palette){[weak self] in
            guard let self,self.hasFullAccess,!KeyboardSettings.privateTypingMode,let value=UIPasteboard.general.string,!value.isEmpty,value.count<=1000,MessageSafety.warnings(in:value).isEmpty else{self?.showStatus("Clipboard trống, nhạy cảm hoặc quá dài");return}
            if ClipboardVault.saveExplicitly(value){self.openToolClipboard()}else{self.showStatus("Không lưu được")}
        })
        actions.heightAnchor.constraint(equalToConstant:38).isActive=true;stack.addArrangedSubview(actions)
        let scroll=UIScrollView(),list=UIStackView();list.axis = .vertical;list.spacing=4;list.translatesAutoresizingMaskIntoConstraints=false
        scroll.addSubview(list);stack.addArrangedSubview(scroll)
        NSLayoutConstraint.activate([list.leadingAnchor.constraint(equalTo:scroll.contentLayoutGuide.leadingAnchor),list.trailingAnchor.constraint(equalTo:scroll.contentLayoutGuide.trailingAnchor),list.topAnchor.constraint(equalTo:scroll.contentLayoutGuide.topAnchor),list.bottomAnchor.constraint(equalTo:scroll.contentLayoutGuide.bottomAnchor),list.widthAnchor.constraint(equalTo:scroll.frameLayoutGuide.widthAnchor)])
        let items=ClipboardVault.items
        let notes=PremiumStore.clipboard
        if items.isEmpty && notes.isEmpty{let label=UILabel();label.text="Chưa có nội dung đã lưu";label.textColor=palette.text;list.addArrangedSubview(label)}
        for value in items{
            let key=premiumKey(String(value.prefix(60)),palette:palette){[weak self] in self?.toolTransformPreview(value,allowReplace:false)}
            key.heightAnchor.constraint(equalToConstant:38).isActive=true
            key.menu=UIMenu(children:[UIAction(title:"Xem trước"){[weak self] _ in self?.toolTransformPreview(value,allowReplace:false)},UIAction(title:"Xóa",attributes:.destructive){[weak self] _ in
                guard !KeyboardSettings.privateTypingMode else{return};ClipboardVault.items=ClipboardVault.items.filter{$0 != value};self?.openToolClipboard()
            }])
            list.addArrangedSubview(key)
        }
        for note in notes{
            let key=premiumKey(note.category+" · "+note.title,palette:palette){[weak self] in self?.toolTransformPreview(note.text,allowReplace:false)}
            key.heightAnchor.constraint(equalToConstant:38).isActive=true;list.addArrangedSubview(key)
        }
    }
}
