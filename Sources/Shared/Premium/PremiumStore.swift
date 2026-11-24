import Foundation

struct PremiumWorkflow: Codable, Identifiable, Equatable {
    var id = UUID().uuidString
    var title: String
    var steps: [String]
}
struct PremiumMacro: Codable, Identifiable, Equatable {
    var id = UUID().uuidString
    var title: String
    var template: String
    var steps: [String] = []
}
struct PremiumNote: Codable, Identifiable, Equatable {
    var id = UUID().uuidString
    var title: String
    var text: String
    var category: String
    var created = Date()
}
struct PremiumPreferences: Codable, Equatable {
    var ghost = true
    var spaceGesture = "cursor"
    var dynamicTouch = false
    var feedback = 0.45
    var sound = "off"
}
enum PremiumStore {
    static let categories = ["Cá nhân","Công việc","Tình cảm"]
    private static func read<T: Decodable>(_ name:String, fallback:T) -> T {
        guard let data = KeyboardSettings.defaults.data(forKey:"viepnaikey.premium."+name),
              let value = try? JSONDecoder().decode(T.self,from:data) else { return fallback }
        return value
    }
    private static func write<T: Encodable>(_ value:T, _ name:String) {
        if let data = try? JSONEncoder().encode(value) { KeyboardSettings.defaults.set(data,forKey:"viepnaikey.premium."+name) }
    }
    static var preferences: PremiumPreferences {
        get { read("prefs",fallback:.init()) }
        set { var v = newValue; v.feedback = min(1,max(0.1,v.feedback)); write(v,"prefs") }
    }
    static var workflows: [PremiumWorkflow] {
        get { read("workflows",fallback:[]) }
        set { write(Array(newValue.prefix(20)).filter { !$0.title.isEmpty && !$0.steps.isEmpty && $0.steps.count <= 4 && $0.steps.allSatisfy { PremiumCommands.find($0)?.isAI == true } },"workflows") }
    }
    static var macros: [PremiumMacro] {
        get { read("macros",fallback:[]) }
        set { write(Array(newValue.prefix(30)).filter { !$0.title.isEmpty && $0.template.count <= 1500 && MessageSafety.warnings(in:$0.template).isEmpty && $0.steps.count <= 4 && $0.steps.allSatisfy { PremiumCommands.find($0)?.isAI == true } },"macros") }
    }
    static var variables: [String:String] {
        get { read("variables",fallback:[:]) }
        set { write(Dictionary(uniqueKeysWithValues:newValue.sorted { $0.key < $1.key }.prefix(20).filter { $0.key.range(of:#"^[a-zA-Z0-9_]{1,24}$"#,options:.regularExpression) != nil && MessageSafety.warnings(in:$0.value).isEmpty }.map { ($0.key,String($0.value.prefix(300))) }),"variables") }
    }
    static var drafts: [PremiumNote] {
        get { KeyboardSettings.privateTypingMode ? [] : read("drafts",fallback:[]) }
        set { if !KeyboardSettings.privateTypingMode { write(Array(newValue.prefix(30)).filter { $0.text.count <= 3000 && MessageSafety.warnings(in:$0.text).isEmpty },"drafts") } }
    }
    static var clipboard: [PremiumNote] {
        get {
            guard !KeyboardSettings.privateTypingMode else { return [] }
            let notes:[PremiumNote] = read("clipboard",fallback:[])
            let valid = notes.filter { Date().timeIntervalSince($0.created) >= 0 && Date().timeIntervalSince($0.created) < 7*86400 }
            if valid.count != notes.count { write(valid,"clipboard") }
            return valid
        }
        set { if !KeyboardSettings.privateTypingMode { write(Array(newValue.prefix(30)).filter { $0.text.count <= 1000 && MessageSafety.warnings(in:$0.text).isEmpty },"clipboard") } }
    }
    static func save(_ text:String, title:String, category:String, isClipboard:Bool) -> Bool {
        let value = text.trimmingCharacters(in:.whitespacesAndNewlines)
        guard !KeyboardSettings.privateTypingMode, !value.isEmpty, value.count <= (isClipboard ? 1000 : 3000), MessageSafety.warnings(in:value).isEmpty else { return false }
        let safeTitle = MessageSafety.warnings(in:title).isEmpty ? String(title.prefix(60)) : "Nội dung đã lưu"
        let note = PremiumNote(title:safeTitle,text:value,category:categories.contains(category) ? category : categories[0])
        if isClipboard { clipboard = [note] + clipboard } else { drafts = [note] + drafts }
        return true
    }
    static func clearNotes() { write([PremiumNote](),"drafts"); write([PremiumNote](),"clipboard") }
}
