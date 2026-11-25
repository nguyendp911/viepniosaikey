import UIKit

extension KeyboardViewController {
    func proKeyboardMenu()->UIMenu {
        let layouts=ProLayout.allCases.map{layout in
            UIAction(title:layout.title,state:layout==offlineConfig.layout ? .on : .off){[weak self] _ in
                guard let self else{return};self.closeIntelligenceHub()
                var config=OfflineKeyboardConfig.current;config.layout=layout;OfflineKeyboardConfig.current=config
                self.refreshTypingPreferences();self.updateProLayout();self.configureGlideRecognizer();self.updateCandidates()
            }
        }
        let extra=UIMenu(title:"Ký tự bổ sung",children:Array(offlineConfig.layout.extra).map{char in
            UIAction(title:String(char)){[weak self] _ in self?.closeIntelligenceHub();self?.insertProExplicit(String(char))}
        })
        return UIMenu(title:"Keyboard Pro",children:[UIMenu(title:"Bố cục",children:layouts),extra])
    }
    func proHistoryMenu()->UIMenu {
        UIMenu(title:"Text Time Machine · phiên hiện tại",children:[
            UIAction(title:"Hoàn tác",attributes:proHistory.undo.isEmpty ? .disabled : []){[weak self] _ in self?.closeIntelligenceHub();self?.applyProHistory(forward:false)},
            UIAction(title:"Làm lại",attributes:proHistory.redo.isEmpty ? .disabled : []){[weak self] _ in self?.closeIntelligenceHub();self?.applyProHistory(forward:true)},
            UIAction(title:"Xóa lịch sử phiên",attributes:.destructive){[weak self] _ in self?.closeIntelligenceHub();self?.proHistory.clear()}
        ])
    }
    func proTextMenu()->UIMenu {
        let styles=ProTextTools.modes.map{mode in
            UIAction(title:mode){[weak self] _ in guard let self else{return};self.closeIntelligenceHub();self.show([ReplySuggestion(tone:mode,text:ProTextTools.stylize(self.premiumSource(),mode:mode))])}
        }
        let signatures=OfflineProStore.signatures.map{signature in UIAction(title:String(signature.prefix(40))){[weak self] _ in guard let self else{return};self.closeIntelligenceHub();guard !self.proPrivate else{return};self.show([ReplySuggestion(tone:"Chữ ký",text:signature)])}}
        let utilities=[UIAction(title:"Thống kê"){[weak self] _ in guard let self else{return};self.closeIntelligenceHub();self.show([ReplySuggestion(tone:"Thống kê",text:ProTextTools.stats(self.premiumSource()))])},
                       UIAction(title:"Dọn văn bản"){[weak self] _ in guard let self else{return};self.closeIntelligenceHub();self.show([ReplySuggestion(tone:"Dọn văn bản",text:ProTextTools.clean(self.premiumSource()))])},
                       UIAction(title:"Bảng Markdown"){[weak self] _ in guard let self else{return};self.closeIntelligenceHub();self.show([ReplySuggestion(tone:"Bảng",text:ProTextTools.table(self.premiumSource()))])}]
        let encoders=["Base64","Decode Base64","URL","Decode URL","Hex","Binary","Morse"].map{mode in
            UIAction(title:mode){[weak self] _ in guard let self else{return};self.closeIntelligenceHub();if let text=ProTextTools.encode(self.premiumSource(),mode:mode){self.show([ReplySuggestion(tone:mode,text:text)])}else{self.showStatus("Dữ liệu không hợp lệ.")}}
        }
        return UIMenu(title:"Text Studio",children:[UIMenu(title:"Font Unicode",children:styles),UIMenu(title:"Chữ ký",children:signatures),UIMenu(title:"Encoder",children:encoders)]+utilities)
    }
    func proProfilesMenu()->UIMenu {
        let profiles=OfflineProStore.profiles.map{profile in UIAction(title:profile.name){[weak self] _ in
            guard let self else{return};self.closeIntelligenceHub()
            self.finishProSession();self.cancelAIRequest();self.proHistory.clear()
            var config=profile.config;config.profile=profile.name;OfflineKeyboardConfig.current=config
            KeyboardSettings.theme=profile.theme;ToolbarPreferences.order=profile.toolbarOrder;KeyboardSettings.privateTypingMode=profile.privateMode
            self.refreshTypingPreferences();self.startProSession();self.updateProLayout();self.applyTheme();self.reloadToolbarConfiguration();self.configureGlideRecognizer();self.refreshIdleActions();self.updateCandidates()
        }}
        return UIMenu(title:"Profiles · tạo trong app",children:profiles.isEmpty ? [UIAction(title:"Chưa có profile",attributes:.disabled){_ in}] : profiles)
    }
    func proSymbolsMenu()->UIMenu {
        let symbols=OfflineProStore.favorites+["(•‿•)","(づ｡◕‿‿◕｡)づ","♡","✦","→","∞","✓","∑","⌘","{}","[]"]
        return UIMenu(title:"Ký tự Pro",children:symbols.prefix(50).map{symbol in UIAction(title:symbol){[weak self] _ in self?.closeIntelligenceHub();self?.insertProExplicit(symbol)}})
    }
}
