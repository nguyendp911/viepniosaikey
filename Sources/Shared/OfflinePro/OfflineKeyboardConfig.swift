import Foundation

enum ProLayout: String, Codable, CaseIterable {
    case qwerty, azerty, qwertz, hangul, kana, cyrillic, custom, developer
    var title: String { rawValue.capitalized }
    var latin: Bool { [.qwerty,.azerty,.qwertz,.custom,.developer].contains(self) }
    func rows(shift: Bool, custom: [String]) -> [String] {
        switch self {
        case .qwerty, .developer: return ["qwertyuiop","asdfghjkl","zxcvbnm"]
        case .azerty: return ["azertyuiop","qsdfghjkl","wxcvbnm"]
        case .qwertz: return ["qwertzuiop","asdfghjkl","yxcvbnm"]
        case .hangul: return shift ? ["ㅃㅉㄸㄲㅆㅛㅕㅑㅒㅖ","ㅁㄴㅇㄹㅎㅗㅓㅏㅣ","ㅋㅌㅊㅍㅠㅜㅡ"] : ["ㅂㅈㄷㄱㅅㅛㅕㅑㅐㅔ","ㅁㄴㅇㄹㅎㅗㅓㅏㅣ","ㅋㅌㅊㅍㅠㅜㅡ"]
        case .kana: return shift ? ["がぎぐげござじずぜぞ","だぢづでどばびぶべ","ぱぴぷぺぽゃゅ"] : ["あいうえおかきくけこ","さしすせそたちつて","なにぬねのはひ"]
        case .cyrillic: return shift ? ["йцукенгшщз","фывапролд","жэячсмъ"] : ["йцукенгшщз","фывапролд","ячсмить"]
        case .custom: return Self.valid(custom) ? custom : ["qwertyuiop","asdfghjkl","zxcvbnm"]
        }
    }
    static func valid(_ rows:[String])->Bool {
        rows.map(\.count)==[10,9,7] && Set(rows.joined())==Set("abcdefghijklmnopqrstuvwxyz")
    }
    var extra: String {
        switch self {
        case .kana: return "とふへほまみむめもやゆよらりるれろわをんっょぁぃぅぇぉー"
        case .cyrillic: return "бюёхъ"
        case .developer: return "{}[]()<>_:=;\\/|&+-*#@"
        default: return ""
        }
    }
}
struct OfflineKeyboardConfig: Codable, Equatable {
    var layout:ProLayout = .qwerty
    var customRows=["qwertyuiop","asdfghjkl","zxcvbnm"]
    var numberRow=false
    var wideSpace=false
    var multiTap=false
    var trackpad="character"
    var history=false
    var analytics=false
    var keycap="flat"
    var radius=8
    var particles="off"
    var wallpaper="off"
    var sound="off"
    var volume=0.4
    var feedback=0.45
    var profile="Daily"
    var normalized:Self {
        var v=self
        if !ProLayout.valid(v.customRows) { v.customRows=["qwertyuiop","asdfghjkl","zxcvbnm"] }
        if !["character","word","accelerated"].contains(v.trackpad) { v.trackpad="character" }
        if !["flat","mechanical","crystal","heritage"].contains(v.keycap) { v.keycap="flat" }
        if !["off","spark","heart","petal","rgb"].contains(v.particles) { v.particles="off" }
        if !["off","aurora","stars","lotus"].contains(v.wallpaper) { v.wallpaper="off" }
        if !["off","click","soft","custom"].contains(v.sound) { v.sound="off" }
        v.radius=min(18,max(3,v.radius));v.volume=min(1,max(0,v.volume));v.feedback=min(1,max(0.1,v.feedback))
        v.profile=String(v.profile.prefix(40))
        return v
    }
    static var current:Self {
        get {
            guard let data=KeyboardSettings.defaults.data(forKey:"viepnaikey.offline4.config"),let decoded=try? JSONDecoder().decode(Self.self,from:data) else { return .init() }
            return decoded.normalized
        }
        set { if let data=try? JSONEncoder().encode(newValue.normalized) { KeyboardSettings.defaults.set(data,forKey:"viepnaikey.offline4.config") } }
    }
}
struct ProSnippet: Codable, Identifiable, Equatable {
    var id=UUID().uuidString
    var trigger:String
    var value:String
    var folder:String
    var profile:String="All"
    var valid:Bool {
        trigger.range(of:#"^;[A-Za-z0-9_]{1,24}$"#,options:.regularExpression) != nil && !value.isEmpty && value.count<=1500 && folder.count<=40 && MessageSafety.warnings(in:value).isEmpty
    }
}
struct ProKeyboardProfile: Codable, Identifiable, Equatable {
    var id=UUID().uuidString
    var name:String
    var config:OfflineKeyboardConfig
    var theme:String
    var toolbarOrder:[String]
    var privateMode:Bool
}
enum OfflineProStore {
    static func read<T:Decodable>(_ key:String, _ fallback:T)->T {
        guard let data=KeyboardSettings.defaults.data(forKey:"viepnaikey.offline4."+key) else{return fallback}
        return (try? JSONDecoder().decode(T.self,from:data)) ?? fallback
    }
    static func write<T:Encodable>(_ value:T,_ key:String) {
        if let data=try? JSONEncoder().encode(value){KeyboardSettings.defaults.set(data,forKey:"viepnaikey.offline4."+key)}
    }
    static var snippets:[ProSnippet] {
        get { read("snippets",[]) }
        set { write(Array(newValue.filter(\.valid).prefix(80)),"snippets") }
    }
    static var profiles:[ProKeyboardProfile] {
        get { read("profiles",[]) }
        set { write(Array(newValue.filter{ !$0.name.isEmpty && $0.name.count<=40 }.prefix(20)),"profiles") }
    }
    static var favorites:[String] {
        get { read("favorites",[]) }
        set { var seen=Set<String>();write(Array(newValue.filter{!$0.isEmpty && $0.count<=20 && seen.insert($0).inserted}.prefix(100)),"favorites") }
    }
    static var signatures:[String] {
        get { read("signatures",[]) }
        set {write(Array(newValue.filter{!$0.isEmpty && $0.count<=500 && MessageSafety.warnings(in:$0).isEmpty}.prefix(20)),"signatures")}
    }
    static func expansion(token:String,profile:String,items:[ProSnippet])->String? {
        items.first{$0.trigger==token && $0.profile==profile && $0.valid}?.value ??
        items.first{$0.trigger==token && $0.profile=="All" && $0.valid}?.value
    }
}
