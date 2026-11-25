import Foundation

struct TypingProPreferences: Codable, Equatable {
    var accentRecovery = false
    var corrections = false
    var pairing = false
    var doubleSpace = false
    var smartShift = false
    var popup = false
     var contextualEmoji = false
    var backspacePan = false
    var touchCalibration = false
    var contextualLanguage = false
    var sentenceGlide = false
    var confidence = 2
    var deleteRepeat = 0.12
    var repeatEnabled = false
    var spaceUp = false
    static var current: Self {
        get {
            guard let data = KeyboardSettings.defaults.data(forKey:"viepnaikey.typingPro6"),
                  let value = try? JSONDecoder().decode(Self.self,from:data) else { return .init() }
            var normalized=value
            normalized.confidence=max(2,min(5,normalized.confidence))
            normalized.deleteRepeat=normalized.deleteRepeat.isFinite ? max(0.08,min(0.5,normalized.deleteRepeat)) : 0.12
            return normalized
        }
        set { if let data = try? JSONEncoder().encode(newValue) { KeyboardSettings.defaults.set(data,forKey:"viepnaikey.typingPro6") } }
    }
}
struct TypingProFeedback: Codable, Equatable {
    struct Pair: Codable, Equatable {
        var source: String
        var target: String
        var accepted: Int = 0
        var rejected: Int = 0
    }
    private(set) var pairs: [Pair] = []
    private(set) var accepted = 0
    private(set) var rejected = 0
    private(set) var savedKeys = 0
    static let key = "viepnaikey.typingPro6.feedback"
    static var revision:String { KeyboardSettings.defaults.string(forKey:key+".revision") ?? "initial" }
    static var current: Self {
        get {
            guard !KeyboardSettings.privateTypingMode, let data = KeyboardSettings.defaults.data(forKey:key),
                  data.count <= 100_000, let result = try? JSONDecoder().decode(Self.self,from:data) else { return .init() }
            return result
        }
        set { if !KeyboardSettings.privateTypingMode, let data = try? JSONEncoder().encode(newValue) { KeyboardSettings.defaults.set(data,forKey:key) } }
    }
    static func clear() { KeyboardSettings.defaults.set(UUID().uuidString,forKey:key+".revision");KeyboardSettings.defaults.removeObject(forKey:key) }
    static func valid(_ word:String) -> Bool {
        (1...24).contains(word.count) && word.allSatisfy(\.isLetter) && PersonalPhraseModel.token(word) != nil
    }
    static func validTarget(_ text:String,source:String)->Bool {
        if valid(text){return true}
        let words=text.split(separator:" ").map(String.init)
        return source.count<=6 && (2...5).contains(words.count) && text.count<=80 && PersonalPhraseModel.safe(words)
    }
    mutating func record(source:String,target:String,accept:Bool) {
        let a=source.lowercased(), b=target.lowercased()
        guard a != b,Self.valid(a),Self.validTarget(b,source:a) else{return}
        let index=pairs.firstIndex{$0.source==a && $0.target==b}
        var pair=index.map{pairs.remove(at:$0)} ?? Pair(source:a,target:b)
        if accept {
            pair.accepted=min(1000,max(0,min(1000,pair.accepted))+1)
            accepted=min(1_000_000,max(0,min(1_000_000,accepted))+1)
            savedKeys=min(1_000_000,max(0,min(1_000_000,savedKeys))+max(0,b.count-a.count))
        } else {
            pair.rejected=min(1000,max(0,min(1000,pair.rejected))+1)
            rejected=min(1_000_000,max(0,min(1_000_000,rejected))+1)
        }
        pairs.insert(pair,at:0);pairs=Array(pairs.prefix(240))
    }
    func preferred(_ source:String,minimum:Int)->[String] {
        pairs.filter{$0.source==source.lowercased() && Self.validTarget($0.target,source:$0.source) && $0.accepted >= minimum && $0.accepted > $0.rejected}
            .sorted{(min(1000,max(0,$0.accepted))-min(1000,max(0,$0.rejected)))>(min(1000,max(0,$1.accepted))-min(1000,max(0,$1.rejected)))}.map(\.target)
    }
    func rejects(_ source:String,_ target:String)->Bool {
        pairs.contains{$0.source==source.lowercased() && $0.target==target.lowercased() && $0.rejected>0 && $0.rejected >= $0.accepted}
    }
}
