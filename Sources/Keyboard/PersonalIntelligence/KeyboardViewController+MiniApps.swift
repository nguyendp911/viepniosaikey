import UIKit

extension KeyboardViewController {
    func personalMiniAppsMenu()->UIMenu {
        let calc=UIAction(title:"Máy tính",image:UIImage(systemName:"calculator")){[weak self] _ in self?.closeIntelligenceHub();self?.openPremiumCalculator()}
        let date=UIAction(title:"Ngày giờ",image:UIImage(systemName:"clock")){[weak self] _ in
            guard let self else{return};self.closeIntelligenceHub()
            self.insertInlineTool(PremiumOffline.variables("{{ngay}} {{gio}}",name:"",custom:[:]))
        }
        let note=UIAction(title:"Ghi chú AI",image:UIImage(systemName:"note.text")){[weak self] _ in
            guard let self else{return};self.closeIntelligenceHub();self.runPersonalAI(title:"Smart Notes",source:self.premiumSource(),instruction:PersonalIntelligenceCatalog.task("notes")!.instruction)
        }
        let diff=UIAction(title:"So sánh nội dung với bản nháp",image:UIImage(systemName:"arrow.left.arrow.right")){[weak self] _ in
            guard let self else{return};self.closeIntelligenceHub()
            guard !KeyboardSettings.privateTypingMode,!ShareDraft.current.isEmpty else{self.showStatus("Cần bản nháp và tắt riêng tư.");return}
            let source=self.premiumSource()
            guard !source.isEmpty else{self.showStatus("Chọn hoặc dán văn bản trước.");return}
            let rows=PersonalDiff.compare(source,ShareDraft.current)
            let summary=rows.filter{$0.kind != "same"}.map{($0.kind=="add" ? "+ " : "− ")+$0.text}.joined(separator:"\n")
            self.show([ReplySuggestion(tone:"So sánh",text:summary.isEmpty ? "Không thấy khác biệt theo từ trong phạm vi kiểm tra." : String(summary.prefix(1500)))])
        }
        let units=UIMenu(title:"Đổi đơn vị · chọn số trước",image:UIImage(systemName:"ruler"),children:[
            ("km → m","Chiều dài","km","m"),("m → cm","Chiều dài","m","cm"),("kg → g","Khối lượng","kg","g"),("lb → kg","Khối lượng","lb","kg"),("Giờ → phút","Thời gian","h","min"),("°C → °F","Nhiệt độ","c","f"),("L → mL","Thể tích","l","ml")
        ].map{label,group,from,to in
            UIAction(title:label){[weak self] _ in
                guard let self else{return};self.closeIntelligenceHub()
                let source=self.premiumSource().trimmingCharacters(in:.whitespacesAndNewlines).replacingOccurrences(of:",",with:".")
                guard let number=Double(source),let value=PersonalUnits.convert(number,group:group,from:from,to:to)else{self.showStatus("Chọn hoặc dán một số hợp lệ.");return}
                self.showInlineResult([ReplySuggestion(tone:label,text:String(format:"%.10g",value))],source:self.premiumSource())
            }
        })
        let notes=UIMenu(title:"Ghi chú đã lưu",children:PersonalMemoryStore.all.filter{$0.kind=="Ghi chú" && $0.personaID.isEmpty}.prefix(15).map{record in
            UIAction(title:record.title){[weak self] _ in
                guard let self else{return};self.closeIntelligenceHub()
                guard !KeyboardSettings.privateTypingMode else{return}
                self.insertInlineTool(record.detail)
            }
        })
        let help=UIAction(title:"QR, nhắc hẹn, mật khẩu · mở app ViePN",attributes:.disabled){_ in}
        return UIMenu(title:"ViePN Mini Apps",children:[calc,date,units,note,notes,diff,help])
    }
}
