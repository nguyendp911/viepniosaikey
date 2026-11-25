import Foundation

/// Bounded local n-grams; no raw keystroke log, host identifiers or timestamps
/// finer than a day. A suggestion requires two independently committed matches.
struct PersonalPhraseModel: Codable {
    struct Entry: Codable {
        var count:Int
        var day:Int
    }
    private(set) var entries:[String:Entry] = [:]
    static let maximum = 1000
    static func day(_ date:Date=Date())->Int { Int(date.timeIntervalSince1970/86400) }
    static func token(_ word:String)->String? {
        let value=word.precomposedStringWithCanonicalMapping.lowercased()
        guard (1...24).contains(value.count),value.allSatisfy({$0.isLetter}),
              !["otp","password","passcode","pin","token","secret","apikey","https","http","www"].contains(value),
              MessageSafety.warnings(in:value).isEmpty else{return nil}
        return value
    }
    static func safe(_ words:[String])->Bool {
        let joined=words.joined(separator:" ")
        guard words.count<=9,words.allSatisfy({token($0)==$0}),
              !["mật khẩu","mã pin","mã xác","mã đăng","số thẻ","tài khoản","số điện thoại","căn cước","api key","secret key"].contains(where:{joined.contains($0)}) else{return false}
        return MessageSafety.warnings(in:joined).isEmpty
    }
    mutating func observe(_ words:[String], day:Int=Self.day()) {
        let normalized=words.compactMap(Self.token)
        guard normalized.count==words.count,Self.safe(normalized),normalized.count>=2 else{return}
        // Each suffix is observed once per committed word.
        for n in 2...min(9,normalized.count) {
            let key=normalized.suffix(n).joined(separator:" ")
            let old=entries[key]
            entries[key]=Entry(count:min(999,(old?.count ?? 0)+1),day:day)
        }
        if entries.count>Self.maximum+20 { prune(day:day) }
    }
    mutating func prune(day:Int=Self.day()) {
        entries=Dictionary(uniqueKeysWithValues:entries.filter{day-$0.value.day<=90 && $0.value.count>0}.sorted {
            let a=$0.value.count*10-max(0,day-$0.value.day), b=$1.value.count*10-max(0,day-$1.value.day)
            return a==b ? $0.key<$1.key : a>b
        }.prefix(Self.maximum).map{($0.key,$0.value)})
    }
    /// Context is read only for ranking, never stored by this method.
    /// With a partial word, return a replacement for that word + continuation;
    /// at a space boundary return just the missing suffix.
    func suggestions(context:[String], partial:String="", day:Int=Self.day(),limit:Int=3)->[String] {
        let prior=context.suffix(8).compactMap(Self.token)
        guard !prior.isEmpty,prior.count==min(8,context.count),limit>0 else{return []}
        let typed=partial.isEmpty ? "" : (Self.token(partial) ?? "")
        guard partial.isEmpty || !typed.isEmpty else{return []}
        let prefixes=(1...prior.count).reversed().map { (length:$0,text:prior.suffix($0).joined(separator:" ")+" ") }
        var ranked:[String:Int]=[:]
        for (phrase,entry) in entries where entry.count>=2 && day-entry.day<=90 {
            for prefix in prefixes {
                guard phrase.hasPrefix(prefix.text) else{continue}
                let n=prefix.length
                let rest=phrase.dropFirst(prefix.text.count).split(separator:" ").map(String.init)
                guard !rest.isEmpty,typed.isEmpty || rest[0].hasPrefix(typed) else{continue}
                if !typed.isEmpty && rest.count==1 && rest[0]==typed {continue}
                let result=rest.joined(separator:" ")
                // Prefer longer exact context, then repeated use and recency;
                // length is only a small tie-breaker.
                let score=n*1000+min(entry.count,30)*35-min(90,max(0,day-entry.day))*3+rest.count*5
                ranked[result]=max(ranked[result] ?? 0,score)
                break
            }
        }
        return ranked.sorted{$0.value==$1.value ? $0.key<$1.key : $0.value>$1.value}.prefix(limit).map(\.key)
    }
    static func context(_ text:String)->[String] {
        let tail=String(text.suffix(180))
        let segment=tail.components(separatedBy:CharacterSet(charactersIn:".!?;:\n\r@/\\0123456789")).last ?? ""
        return segment.split(whereSeparator:{$0.isWhitespace}).suffix(8).map(String.init)
    }
}
enum PersonalPhraseStore {
    static var revision:String { KeyboardSettings.defaults.string(forKey:"viepnaikey.phrases.revision") ?? "initial" }
    private static let key="viepnaikey.phrases.model"
    private struct Envelope:Codable {let revision:String;let model:PersonalPhraseModel}
    #if os(iOS)
    private static var url:URL? { FileManager.default.containerURL(forSecurityApplicationGroupIdentifier:KeyboardSettings.groupID)?.appendingPathComponent("personal-phrases-v1.json") }
    #endif
    static func load()->PersonalPhraseModel {
        guard !KeyboardSettings.privateTypingMode,KeyboardSettings.autoLearnWords else{return .init()}
        #if os(iOS)
        guard let url,let data=try? Data(contentsOf:url),data.count<=500_000 else{return .init()}
        #else
        guard let data=KeyboardSettings.defaults.data(forKey:key) else{return .init()}
        #endif
        guard let decoded=try? JSONDecoder().decode(Envelope.self,from:data),decoded.revision==revision else{return .init()}
        var model=decoded.model;model.prune();return model
    }
    static func save(_ model:PersonalPhraseModel,revision expected:String) {
        guard expected==revision,!KeyboardSettings.privateTypingMode,KeyboardSettings.autoLearnWords else{return}
        var bounded=model;bounded.prune()
        guard let data=try? JSONEncoder().encode(Envelope(revision:expected,model:bounded)),data.count<=500_000 else{return}
        #if os(iOS)
        guard let url else{return}
        try? data.write(to:url,options:[.atomic,.completeFileProtection])
        #else
        KeyboardSettings.defaults.set(data,forKey:key)
        #endif
    }
    static func clear() {
        KeyboardSettings.defaults.set(UUID().uuidString,forKey:"viepnaikey.phrases.revision")
        #if os(iOS)
        if let url {try? FileManager.default.removeItem(at:url)}
        #else
        KeyboardSettings.defaults.removeObject(forKey:key)
        #endif
    }
}
