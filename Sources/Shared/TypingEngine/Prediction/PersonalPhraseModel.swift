import Foundation
#if os(iOS)
import Darwin
#endif

/// Bounded local n-grams; no raw keystroke log, host identifiers or timestamps
/// finer than a day. A suggestion requires two independently committed matches.
struct PersonalPhraseModel: Codable {
    struct Entry: Codable {
        var count:Int
        var day:Int
        // Optional for backward-compatible decoding of the existing v1 file.
        var periods:[Int]? = nil
        var pinned:Bool? = nil
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
    static func period(_ date:Date=Date())->Int { Calendar.current.component(.hour,from:date)/6 }
    mutating func observe(_ words:[String], day:Int=Self.day(), period:Int=Self.period()) {
        let normalized=words.compactMap(Self.token)
        guard normalized.count==words.count,Self.safe(normalized),normalized.count>=2 else{return}
        // Each suffix is observed once per committed word.
        for n in 2...min(9,normalized.count) {
            let key=normalized.suffix(n).joined(separator:" ")
            let old=entries[key]
            var periods=old?.periods ?? [0,0,0,0]
            if periods.count != 4 { periods=[0,0,0,0] }
            if periods.indices.contains(period) { periods[period]=min(999,max(0,min(999,periods[period]))+1) }
            entries[key]=Entry(count:min(999,max(0,min(999,old?.count ?? 0))+1),day:day,periods:periods,pinned:old?.pinned)
        }
        if entries.count>Self.maximum+20 { prune(day:day) }
    }
    mutating func prune(day:Int=Self.day()) {
        let oldest = day > Int.min + 90 ? day - 90 : Int.min
        entries=Dictionary(uniqueKeysWithValues:entries.filter {
            (1...999).contains($0.value.count) && ($0.value.pinned == true || $0.value.day >= oldest) && $0.value.day <= day &&
            $0.key.count <= 224 && (2...9).contains($0.key.split(separator:" ").count) && Self.safe($0.key.split(separator:" ").map(String.init))
        }.sorted {
            if ($0.value.pinned == true) != ($1.value.pinned == true) {return $0.value.pinned == true}
            let a=Double($0.value.count*10)-Double(day)+Double($0.value.day), b=Double($1.value.count*10)-Double(day)+Double($1.value.day)
            return a==b ? $0.key<$1.key : a>b
        }.prefix(Self.maximum).map{($0.key,$0.value)})
    }
    /// Context is read only for ranking, never stored by this method.
    /// With a partial word, return a replacement for that word + continuation;
    /// at a space boundary return just the missing suffix.
    func suggestions(context:[String], partial:String="", day:Int=Self.day(),limit:Int=3,minimum:Int=2,period:Int=Self.period())->[String] {
        let prior=context.suffix(8).compactMap(Self.token)
        guard !prior.isEmpty,prior.count==min(8,context.count),limit>0 else{return []}
        let typed=partial.isEmpty ? "" : (Self.token(partial) ?? "")
        guard partial.isEmpty || !typed.isEmpty else{return []}
        let prefixes=(1...prior.count).reversed().map { (length:$0,text:prior.suffix($0).joined(separator:" ")+" ") }
        var ranked:[String:Int]=[:]
        for (phrase,entry) in entries where (entry.pinned == true || entry.count>=max(2,min(5,minimum))) && entry.day<=day && (entry.pinned == true || entry.day >= (day > Int.min+90 ? day-90 : Int.min)) {
            for prefix in prefixes {
                guard phrase.hasPrefix(prefix.text) else{continue}
                let n=prefix.length
                let rest=phrase.dropFirst(prefix.text.count).split(separator:" ").map(String.init)
                guard !rest.isEmpty,typed.isEmpty || rest[0].hasPrefix(typed) else{continue}
                if !typed.isEmpty && rest.count==1 && rest[0]==typed {continue}
                let result=rest.joined(separator:" ")
                // Prefer longer exact context, then repeated use and recency;
                // length is only a small tie-breaker.
                let timeWeight=entry.periods.flatMap{$0.indices.contains(period) ? max(0,min(8,$0[period])) : nil} ?? 0
                let score=n*1000+min(entry.count,30)*35-Int(min(90,max(0,Double(day)-Double(entry.day))))*3+rest.count*5+timeWeight*4+(entry.pinned == true ? 350 : 0)
                ranked[result]=max(ranked[result] ?? 0,score)
                break
            }
        }
        return ranked.sorted{$0.value==$1.value ? $0.key<$1.key : $0.value>$1.value}.prefix(limit).map(\.key)
    }
    static func phraseKey(_ input:String)->String? {
        let words=input.split(whereSeparator:{$0.isWhitespace}).compactMap { Self.token(String($0)) }
        guard words.count == input.split(whereSeparator:{$0.isWhitespace}).count,(2...9).contains(words.count),Self.safe(words) else{return nil}
        return words.joined(separator:" ")
    }
    mutating func setPinned(_ key:String,_ pinned:Bool)->Bool {
        guard var item=entries[key],!pinned || item.pinned==true || entries.values.filter({$0.pinned==true}).count<100 else{return false}
        item.pinned=pinned;entries[key]=item;return true
    }
    mutating func remove(_ key:String) { entries.removeValue(forKey:key) }
    mutating func edit(_ old:String?,to input:String,day:Int=Self.day())->Bool {
        guard let key=Self.phraseKey(input),old==nil || entries[old!] != nil else{return false}
        guard old==key || entries[key]==nil else{return false}
        let previous=old.flatMap{entries[$0]}
        if let old {entries.removeValue(forKey:old)}
        entries[key]=Entry(count:max(2,previous?.count ?? 2),day:day,periods:previous?.periods,pinned:previous?.pinned)
        prune(day:day);return entries[key] != nil
    }
    mutating func merge(_ incoming:Self,day:Int=Self.day()) {
        var other=incoming;other.prune(day:day)
        for (key,item) in other.entries {
            if let existing=entries[key] {
                let latest=existing.day>=item.day ? existing : item
                entries[key]=Entry(count:max(existing.count,item.count),day:latest.day,periods:latest.periods,pinned:existing.pinned==true || item.pinned==true)
            } else {entries[key]=item}
        }
        prune(day:day)
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
        guard KeyboardSettings.autoLearnWords else{return .init()}
        return readForManagement()
    }
    static func readForManagement()->PersonalPhraseModel {
        guard !KeyboardSettings.privateTypingMode else{return .init()}
        guard let data=readData(),let decoded=try? JSONDecoder().decode(Envelope.self,from:data),decoded.revision==revision else{return .init()}
        var model=decoded.model;model.prune();return model
    }
    private static func readData()->Data? {
        #if os(iOS)
        guard let url,let size=try? url.resourceValues(forKeys:[.fileSizeKey]).fileSize,size<=500_000 else{return nil}
        return try? Data(contentsOf:url)
        #else
        return KeyboardSettings.defaults.data(forKey:key)
        #endif
    }
    private static func locked(_ action:()->Bool)->Bool {
        #if os(iOS)
        guard let url else{return false}
        let path=url.appendingPathExtension("lock").path
        let fd=Darwin.open(path,O_CREAT | O_RDWR,mode_t(0o600))
        guard fd>=0 else{return false};defer{Darwin.close(fd)}
        guard flock(fd,LOCK_EX)==0 else{return false};defer{flock(fd,LOCK_UN)}
        return action()
        #else
        return action()
        #endif
    }
    private static func write(_ model:PersonalPhraseModel,revision:String)->Bool {
        var bounded=model;bounded.prune()
        guard let data=try? JSONEncoder().encode(Envelope(revision:revision,model:bounded)),data.count<=500_000 else{return false}
        #if os(iOS)
        guard let url else{return false}
        do {try data.write(to:url,options:[.atomic,.completeFileProtection]);return true}catch{return false}
        #else
        KeyboardSettings.defaults.set(data,forKey:key);return true
        #endif
    }
    static func save(_ model:PersonalPhraseModel,revision expected:String) {
        _ = locked {
            guard expected==revision,!KeyboardSettings.privateTypingMode,KeyboardSettings.autoLearnWords else{return false}
            if let data=readData() {
                guard let envelope=try? JSONDecoder().decode(Envelope.self,from:data),envelope.revision==expected else{return false}
            } else {
                #if os(iOS)
                if let url,FileManager.default.fileExists(atPath:url.path){return false}
                #endif
            }
            return write(model,revision:expected)
        }
    }
    /// A new revision invalidates queued writes from any older keyboard session.
    @discardableResult static func modify(_ change:(inout PersonalPhraseModel)->Bool)->Bool {
        locked {
            guard !KeyboardSettings.privateTypingMode else{return false}
            var model=PersonalPhraseModel()
            if let data=readData() {
                guard let stored=try? JSONDecoder().decode(Envelope.self,from:data),stored.revision==revision else{return false}
                model=stored.model;model.prune()
            } else {
                #if os(iOS)
                if let url,FileManager.default.fileExists(atPath:url.path){return false}
                #endif
            }
            guard change(&model) else{return false}
            let next=UUID().uuidString
            guard write(model,revision:next) else{return false}
            KeyboardSettings.defaults.set(next,forKey:"viepnaikey.phrases.revision")
            return true
        }
    }
    static func clear() {
        _ = locked {
            let next=UUID().uuidString
            guard write(.init(),revision:next) else{return false}
            KeyboardSettings.defaults.set(next,forKey:"viepnaikey.phrases.revision");return true
        }
    }
}
