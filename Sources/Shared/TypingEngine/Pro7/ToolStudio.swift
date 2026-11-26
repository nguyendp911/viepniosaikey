import Foundation

enum ToolStudioCatalog {
    static let sections:[(String,[String])]=[
        ("NHẬP LIỆU",["Typing Premium","Keyboard Pro","Con trỏ","Time Machine","Hoàn tác","Làm lại"]),
        ("VĂN BẢN",["Smart Text Editor","Text Studio","Định dạng","Văn bản","Viết lại","Mẫu câu","Biến mẫu"]),
        ("GIAO TIẾP",["Hội thoại","Bật/tắt Couple","Tình cảm","Công việc","Dịch","Tone Mixer"]),
        ("CLIPBOARD & BẢN NHÁP",["Clipboard Studio","Clipboard","Bộ sưu tập","Kho nháp","Bản nháp"]),
        ("TỰ ĐỘNG HÓA & AI",["Command","Macro","Workflow","AI Premium","Personal AI","Arena","Second Brain","Prompt","Nhà cung cấp","Văn phong"]),
        ("TIỆN ÍCH",["Máy tính","Đọc ảnh","Emoji","Ký tự Pro","Mini Apps","Offline","Profiles","Riêng tư"])
    ]
    static var names:[String]{sections.flatMap{$0.1}}
    static let aliases:[String:String]=[
        "Smart Text Editor":"van ban text editor chinh sua bo dau chu hoa thuong",
        "Clipboard Studio":"clipboard tim kiem ghim lich su sao chep paste",
        "Typing Premium":"go tieng viet chinh ta tu them dau autocorrect du doan",
        "Bật/tắt Couple":"couple tinh cam quick mode lanh lung",
        "Dịch":"translate translation dich thuat",
        "Đọc ảnh":"ocr screenshot anh chup",
        "Máy tính":"calculator tinh toan",
        "Con trỏ":"cursor selection",
        "Kho nháp":"draft vault",
        "Bộ sưu tập":"collections clipboard",
        "Ký tự Pro":"font symbol ky tu",
        "Command":"search tim kiem lenh"
    ]
    static func matches(_ name:String,query:String)->Bool{
        let haystack=TypingProText.fold(name+" "+(aliases[name] ?? ""))
        let tokens=TypingProText.fold(query).split(whereSeparator:{$0.isWhitespace})
        return tokens.allSatisfy{haystack.contains($0)}
    }
    static func defaults(for workspace:String)->[String]{
        switch workspace{
        case "work":return ["Smart Text Editor","Dịch","Mẫu câu","Máy tính"]
        case "couple":return ["Bật/tắt Couple","Hội thoại","Viết lại","Tone Mixer"]
        default:return ["Smart Text Editor","Clipboard Studio","Typing Premium","Dịch"]
        }
    }
}
struct ToolStudioPreferences:Codable,Equatable{
    var workspace="personal"
    var pins:[String:[String]]=[:]
    var contextual=true
    var normalized:Self{
        var value=self
        if !["personal","work","couple"].contains(workspace){value.workspace="personal"}
        value.pins=Dictionary(uniqueKeysWithValues:pins.filter{["personal","work","couple"].contains($0.key)}.map{key,items in
            var seen=Set<String>()
            return (key,Array(items.filter{ToolStudioCatalog.names.contains($0) && seen.insert($0).inserted}.prefix(6)))
        })
        return value
    }
    var favorites:[String]{pins[workspace] ?? ToolStudioCatalog.defaults(for:workspace)}
    func quick(hasSelection:Bool,hasDraft:Bool)->[String]{
        var result=favorites
        if contextual,hasSelection,!result.contains("Smart Text Editor"){result.insert("Smart Text Editor",at:0)}
        if contextual,hasDraft,!hasSelection,!result.contains("Viết lại"){result.append("Viết lại")}
        return Array(result.prefix(6))
    }
    static var current:Self{
        get{
            guard let data=KeyboardSettings.defaults.data(forKey:"viepnaikey.toolstudio.v1"),data.count<=16000,
                  let value=try? JSONDecoder().decode(Self.self,from:data) else{return .init()}
            return value.normalized
        }
        set{if let data=try? JSONEncoder().encode(newValue.normalized){KeyboardSettings.defaults.set(data,forKey:"viepnaikey.toolstudio.v1")}}
    }
}
enum ToolTextTransform:String,CaseIterable{
    case upper,lower,unaccent,spaces,bullet,numbered,unique,trim
    var title:String{
        switch self{
        case .upper:return "IN HOA"
        case .lower:return "chữ thường"
        case .unaccent:return "Bỏ dấu"
        case .spaces:return "Chuẩn hóa khoảng trắng"
        case .bullet:return "Gạch đầu dòng"
        case .numbered:return "Đánh số dòng"
        case .unique:return "Bỏ dòng trùng"
        case .trim:return "Xóa khoảng trắng đầu cuối"
        }
    }
    func apply(_ source:String)->String?{
        guard source.count<=3000 else{return nil}
        let result:String
        let lines=source.components(separatedBy:"\n")
        switch self{
        case .upper:result=source.uppercased()
        case .lower:result=source.lowercased()
        case .unaccent:result=source.folding(options:.diacriticInsensitive,locale:Locale(identifier:"vi_VN")).replacingOccurrences(of:"đ",with:"d").replacingOccurrences(of:"Đ",with:"D")
        case .spaces:result=lines.map{$0.split(whereSeparator:{$0.isWhitespace}).joined(separator:" ")}.joined(separator:"\n")
        case .bullet:result=lines.map{$0.trimmingCharacters(in:.whitespaces)}.filter{!$0.isEmpty}.map{"• "+$0}.joined(separator:"\n")
        case .numbered:result=lines.map{$0.trimmingCharacters(in:.whitespaces)}.filter{!$0.isEmpty}.enumerated().map{"\($0.offset+1). "+$0.element}.joined(separator:"\n")
        case .unique:var seen=Set<String>();result=lines.filter{seen.insert($0).inserted}.joined(separator:"\n")
        case .trim:result=source.trimmingCharacters(in:.whitespacesAndNewlines)
        }
        return result.count<=6000 ? result:nil
    }
}
