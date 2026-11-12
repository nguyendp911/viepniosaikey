import Foundation

/// Offline suggestions and bilingual protection. Never reads the network, the
/// clipboard, other apps' conversations, or remote dictionaries.
enum SmartTyping {
    static let englishWords: [String] = [
        "about","account","after","again","air","all","amazing","and","android","app",
        "apple","are","art","ask","auto","awesome","back","bad","bank","beautiful",
        "because","before","best","better","big","birthday","black","blue","book",
        "booking","boss","boy","brand","business","buy","call","camera","can","car",
        "card","care","cat","chat","check","child","class","click","close","cloud",
        "coffee","cold","come","computer","cool","copy","could","customer","cute",
        "data","day","design","device","did","different","digital","do","doctor",
        "does","done","download","drive","easy","edit","email","end","english",
        "enjoy","error","even","every","example","facebook","family","fast","feel",
        "file","find","fine","first","fix","food","for","friend","from","full",
        "game","get","girl","give","go","good","google","great","green","group",
        "happy","hard","has","have","health","hello","help","her","here","hi",
        "high","home","hope","hot","how","idea","image","import","info","instagram",
        "internet","ios","iphone","is","issue","it","job","just","keep","key",
        "keyboard","kind","know","laptop","last","later","learn","leave","let",
        "like","link","little","live","login","long","look","love","low","lunch",
        "make","manager","market","maybe","media","meeting","message","mind",
        "miss","mobile","model","money","more","morning","most","mother","move",
        "music","my","name","need","network","new","next","nice","night","no",
        "not","note","now","number","of","offline","ok","okay","old","on","one",
        "online","only","open","or","order","other","our","out","over","page",
        "password","pay","people","person","phone","photo","picture","place","plan",
        "play","please","post","power","price","problem","product","profile",
        "project","quick","quite","read","ready","really","reply","report","reset",
        "right","room","run","sale","save","school","screen","search","see",
        "send","server","service","share","she","shop","short","show","sign",
        "simple","site","smart","social","some","sorry","sound","space","speed",
        "spring","start","status","stay","stop","store","story","straight",
        "street","stress","strong","study","style","sun","support","sure","system",
        "take","talk","team","technology","tell","test","text","thank","thanks",
        "that","the","their","them","there","these","they","thing","think",
        "this","time","today","tomorrow","tool","top","touch","trade","travel",
        "tree","try","turn","two","type","typing","under","update","upload",
        "use","user","video","view","voice","wait","want","was","water","way",
        "we","web","website","week","well","were","what","when","where","which",
        "white","who","why","wifi","will","win","windows","with","word","work",
        "world","would","write","wrong","year","yes","you","young","your",
        "youtube","zalo","zoom"
    ]

    static let vietnameseWords: [String] = [
        "anh","bạn","bàn","bán","bảo","bao","bây","bây giờ","biết","buồn","bữa",
        "bình","bình thường","cả","cảm","cảm ơn","cần","có","con","còn","cô",
        "công","của","cũng","chào","cháu","chắc","chưa","chị","cho","chú",
        "chuyện","chúng","chúc","đã","đang","đây","đâu","đến","để","đi",
        "điều","được","đúng","em","gặp","gửi","giúp","giờ","gì","hẹn","hiểu",
        "học","hôm","hỏi","không","khỏe","khi","là","làm","lại","lần",
        "lâu","lên","lời","luôn","mà","mai","mình","mọi","muốn","mua",
        "mưa","mới","này","năm","nên","ngày","nghe","nghĩ","người",
        "nhắn","nhanh","nhà","nhé","nhớ","như","nhiều","nói","nữa",
        "ở","phải","phần","rất","rồi","sao","sẽ","sớm","tại","tâm",
        "thấy","thật","thế","thêm","thích","thôi","thời","thương","thường",
        "thử","tiếng","tin","tình","tôi","trong","trước","trường",
        "từ","và","vậy","vẫn","về","việc","vì","với","vui","xin",
        "yêu","ý"
    ]

    private static let englishSet = Set(englishWords)
    private static let englishPrefixes: Set<String> = {
        Set(englishWords.flatMap { word in
            (3...max(3,word.count)).filter { $0 <= word.count }.map { String(word.prefix($0)) }
        })
    }()

    private static let vietnameseSet: Set<String> = Set(vietnameseWords.map { $0.lowercased() })

    // Group built-in words by their first two characters once. The hot
    // prediction path only visits a small bucket instead of both dictionaries
    // for every keystroke. Dictionary contents stay entirely on-device.
    private static let predictionBuckets: [String: [String]] = {
        var result: [String: [String]] = [:]
        for word in englishWords + vietnameseWords where word.count >= 2 {
            result[String(word.prefix(2)), default: []].append(word)
        }
        return result
    }()



    static func isEnglishWord(_ word: String) -> Bool {
        englishSet.contains(word.lowercased())
    }

    static func isEnglishPrefix(_ word: String) -> Bool {
        englishPrefixes.contains(word.lowercased())
    }

    static func isVietnameseWord(_ word: String) -> Bool {
        vietnameseSet.contains(word.lowercased())
    }

    /// Suppress Telex when the currently typed Latin sequence is a known
    /// English word/prefix. User can turn this off when typing Vietnamese.
    static func shouldKeepLiteral(_ word: String, adding key: String) -> Bool {
        let combined = (word + key).lowercased()
        guard combined.count >= 3, combined.allSatisfy({ $0.isASCII && $0.isLetter }) else {
            return false
        }
        return englishSet.contains(combined) || englishPrefixes.contains(combined)
    }

    /// Restore a Vietnamese Telex composition that was deferred because the
    /// intermediate letters overlap an English word prefix. For example:
    /// "too" is a prefix of English "tool", so the bilingual guard keeps it
    /// literal. When the next key is "i", the completed "tooi" unambiguously
    /// matches the Vietnamese dictionary entry "tôi".
    ///
    /// This only rewrites a whole word when the completed result is in the
    /// offline Vietnamese lexicon. "tool" consequently remains "tool".
    static func resolveDeferredVietnamese(word: String, adding key: String) -> String? {
        guard key.count == 1, key.first?.isLetter == true,
              word.count >= 3, word.count <= 32 else { return nil }
        let lower = word.lowercased()
        guard lower.hasSuffix("oo") || lower.hasSuffix("aa") || lower.hasSuffix("ee") else {
            return nil
        }
        let stem = String(word.dropLast())
        guard let transformed = VietnameseTelex.transformed(
            word: stem, key: String(word.last!)
        ) else { return nil }
        let candidate = transformed + key
        guard vietnameseWords.contains(where: { $0.lowercased() == candidate.lowercased() }) else {
            return nil
        }
        return candidate
    }

    static func predictions(prefix raw: String, learned: [String: Int] = [:],
                            limit: Int = 3) -> [String] {
        let prefix = raw.lowercased()
        guard prefix.count >= 2, prefix.count <= 24, limit > 0 else { return [] }
        var seen = Set<String>()
        var candidates: [String] = []
        for word in learned.keys where word.lowercased().hasPrefix(prefix) {
            if seen.insert(word).inserted { candidates.append(word) }
        }
        let bucket = predictionBuckets[String(prefix.prefix(2))] ?? []
        for word in bucket where word.hasPrefix(prefix) {
            if seen.insert(word).inserted { candidates.append(word) }
        }
        // Plain `<` instead of localizedStandardCompare: the locale-aware
        // comparison is very slow and ran for every candidate on every key.
        return Array(candidates.sorted {
            let a = learned[$0] ?? 0, b = learned[$1] ?? 0
            if a != b { return a > b }
            if $0 == prefix { return true }
            if $1 == prefix { return false }
            if $0.count != $1.count { return $0.count < $1.count }
            return $0 < $1
        }.prefix(limit))
    }

    /// Touch the lazily built lookup tables so the first key press does not
    /// pay for creating them. Safe to call from a background queue.
    static func warmUp() {
        _ = isEnglishPrefix("abc")
        _ = isVietnameseWord("anh")
        _ = predictions(prefix: "th")
        _ = VietnameseTelex.composeKeys("tooi")
    }

    /// A small local glide recognizer. The traced key sequence is compressed
    /// and scored against the dictionary; it is deliberately never sent to AI.
    static func glideCandidates(trace raw: String, limit: Int = 3) -> [String] {
        let trace = collapseRepeats(raw.lowercased())
        guard trace.count >= 3 else { return [] }
        let matches = (englishWords + vietnameseWords).compactMap { word -> (String, Int)? in
            let letters = collapseRepeats(word.lowercased())
            guard letters.first == trace.first, letters.last == trace.last else { return nil }
            let distance = editDistance(Array(letters), Array(trace))
            guard distance <= max(2, trace.count/2) else { return nil }
            return (word, distance)
        }
        return Array(matches.sorted {
            if $0.1 != $1.1 { return $0.1 < $1.1 }
            return abs($0.0.count - trace.count) < abs($1.0.count - trace.count)
        }.prefix(limit).map(\.0))
    }

    private static func collapseRepeats(_ input: String) -> String {
        var result = ""
        var last: Character?
        for ch in input {
            if ch != last { result.append(ch) }
            last = ch
        }
        return result
    }

    private static func editDistance(_ a: [Character], _ b: [Character]) -> Int {
        var previous = Array(0...b.count)
        for (i, ca) in a.enumerated() {
            var row = [i + 1] + Array(repeating: 0, count: b.count)
            for (j, cb) in b.enumerated() {
                row[j+1] = min(row[j] + 1, previous[j+1] + 1,
                               previous[j] + (ca == cb ? 0 : 1))
            }
            previous = row
        }
        return previous[b.count]
    }

    static func expandSnippet(_ text: String, now: Date = Date()) -> String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "vi_VN")
        fmt.dateFormat = "dd/MM/yyyy"
        let date = fmt.string(from: now)
        fmt.dateFormat = "HH:mm"
        let time = fmt.string(from: now)
        return text.replacingOccurrences(of: "{date}", with: date)
            .replacingOccurrences(of: "{time}", with: time)
    }
}
