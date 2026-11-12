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
        "yêu","ý",
        // Additional common single-word Vietnamese vocabulary for swipe
        // recognition. Ambiguous accent variants remain selectable in the
        // candidate strip rather than inferred as a certainty.
        "ạ","ấm","ăn","ảnh","ba","bà","bác","bài","bánh","bắt",
        "bé","bên","biển","bỏ","bố","bốn","buổi","bút","cách","cái",
        "cảnh","câu","cây","cơ","cơm","cửa","cuối","cười","dạ","dài",
        "dạy","dần","dễ","đẹp","điện","địa","định","đọc","đổi","đợi",
        "đông","đủ","đưa","đừng","giá","giáo","giải","giống","giỏi","gần",
        "ghế","hai","hành","hay","hết","hiện","hình","hòa","hoàn","họ",
        "hướng","khác","khách","khó","khóa","khoảng","kỹ","lớp","lớn","lúc",
        "luyện","máy","mẹ","mệt","mèo","mỗi","mở","mùa","mức","ngắn",
        "ngon","ngồi","ngôn","ngoài","nguyên","ngữ","nhận","nhìn","nhỏ","những",
        "nóng","nước","phòng","phút","quá","quản","quan","quên","quyết","sách",
        "sáng","sẵn","sinh","số","sống","sửa","tặng","tập","tay","tên",
        "tết","tháng","thi","thầy","thức","thực","tiết","tiền","tìm","tốt",
        "toán","trả","trái","trên","trọng","trời","trợ","từng","tuần","tuyệt",
        "vâng","vật","vấn","vị","viên","viết","vừa","xe","xem","xinh",
        "xuống","yên","yếu"

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

    // Only suggest, never auto-insert: a single nearby-key typo should not
    // force English spelling on someone composing Vietnamese via Telex.
    // These 2D neighbors are generated once, without tracking touch locations.
    private static let nearbyKeys: [Character: Set<Character>] = {
        let rows = ["qwertyuiop", "asdfghjkl", "zxcvbnm"].map(Array.init)
        var result: [Character: Set<Character>] = [:]
        for rowIndex in rows.indices {
            for (column, key) in rows[rowIndex].enumerated() {
                for otherRow in rows.indices where abs(otherRow - rowIndex) <= 1 {
                    for (otherColumn, neighbor) in rows[otherRow].enumerated()
                        where neighbor != key && abs(otherColumn - column) <= 1 {
                        result[key, default: []].insert(neighbor)
                    }
                }
            }
        }
        return result
    }()

    static func nearbyKeyCorrections(_ raw: String, limit: Int = 3) -> [String] {
        let typed = Array(raw.lowercased())
        guard typed.count >= 3, typed.count <= 20, limit > 0,
              typed.allSatisfy({ $0.isASCII && $0.isLetter }) else { return [] }
        var matches: [String] = []
        for word in englishWords where word.count == typed.count {
            var mismatches = 0
            for (key, expected) in zip(typed, word) where key != expected {
                mismatches += 1
                if mismatches > 1 || !(nearbyKeys[key]?.contains(expected) ?? false) {
                    mismatches = 2
                    break
                }
            }
            if mismatches == 1 { matches.append(word) }
        }
        return Array(matches.sorted().prefix(limit))
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
        if candidates.isEmpty {
            // A miss such as "storw" can suggest "store" in the suggestion
            // strip; no automatic replacement or destructive text edit.
            for suggestion in nearbyKeyCorrections(prefix, limit: limit) {
                if seen.insert(suggestion).inserted { candidates.append(suggestion) }
            }
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
    /// Rank both English and Vietnamese candidates against the same physical
    /// QWERTY gesture. Diacritics are not separate keys: compare against an
    /// accent-free *stroke spelling*, then retain the actual accented word.
    /// 'language' is an explicit keyboard preference ("auto", "vi", "en").
    static func glideCandidates(trace raw: String, learned: [String: Int] = [:],
                                language: String = "auto", limit: Int = 3) -> [String] {
        let trace = collapseRepeats(raw.lowercased())
        guard trace.count >= 2, trace.count <= 65, limit > 0,
              trace.allSatisfy({ $0.isASCII && $0.isLetter }) else { return [] }
        // English-only mode must never insert an accented Vietnamese word.
        // Learned plain ASCII words are still eligible in that mode.
        let dictionary = language == "en"
            ? englishWords + learned.keys.filter {
                $0.allSatisfy({ $0.isASCII && $0.isLetter })
            }
            : englishWords + vietnameseWords + Array(learned.keys)

        // Two-character swipes require an exact unaccented match, so "or"
        // remains English but "co" can propose "có" and "cô".
        struct Match {
            let word: String
            let distance: Int
        }
        var matches: [Match] = []
        let threshold = trace.count == 2 ? 0 : max(2, trace.count / 2)
        for word in dictionary {
            guard let spelling = glideSpelling(word), !spelling.isEmpty,
                  spelling.first == trace.first,
                  spelling.last == trace.last,
                  abs(spelling.count - trace.count) <= threshold else { continue }
            let distance = editDistance(Array(spelling), Array(trace))
            if distance <= threshold {
                matches.append(Match(word: word, distance: distance))
            }
        }

        let closest = matches.map(\.distance).min()
        // Prefer exact spelling matches over fuzzy guesses. For a dense trace
        // passing through many unintended keys, use the geometric model.
        if closest == 0 || (closest != nil && closest! <= 1) {
            let nearest = matches.filter { $0.distance == closest! }
            return rankedGlideWords(nearest.map(\.word), trace: trace,
                                    learned: learned, language: language, limit: limit)
        }

        let geometric = geometryGlideCandidates(
            trace: trace, dictionary: dictionary,
            learned: learned, language: language, limit: limit)
        if !geometric.isEmpty { return geometric }
        guard let closest else { return [] }
        return rankedGlideWords(matches.filter { $0.distance == closest }.map(\.word),
                                trace: trace, learned: learned,
                                language: language, limit: limit)
    }

    // Tone alternatives use the vowel shape of the recognized Vietnamese
    // word. The finger never needs to enter an extra Telex tone key.
    private static let toneForms: [String] = [
        "aáàảãạ", "ăắằẳẵặ", "âấầẩẫậ", "eéèẻẽẹ",
        "êếềểễệ", "iíìỉĩị", "oóòỏõọ", "ôốồổỗộ",
        "ơớờởỡợ", "uúùủũụ", "ưứừửữự", "yýỳỷỹỵ"
    ]
    private static let toneLookup: [Character: [Character]] = {
        var result: [Character: [Character]] = [:]
        for sequence in toneForms {
            let forms = Array(sequence)
            for letter in forms { result[letter] = forms }
        }
        return result
    }()

    /// Returns all six tone choices for a single vowel nucleus. These can
    /// include uncommon spellings; we never silently autocorrect them.
    static func glideToneVariants(_ word: String) -> [String] {
        let original = Array(word)
        guard original.count >= 2, original.count <= 32,
              !word.contains(" ") else { return [word] }
        let vowelIndices = original.indices.filter {
            toneLookup[Character(String(original[$0]).lowercased())] != nil
        }
        guard !vowelIndices.isEmpty else { return [word] }
        // For multiple vowels keep a previously shaped/toned nucleus; for
        // single-vowel syllables (minh, bạn) the choice is unambiguous.
        let marked = vowelIndices.last(where: {
            let ch = Character(String(original[$0]).lowercased())
            guard let forms = toneLookup[ch] else { return false }
            return ch != forms[0]
        })
        let index = marked ?? vowelIndices.last!
        let current = Character(String(original[index]).lowercased())
        guard let forms = toneLookup[current] else { return [word] }
        let order = [0, 2, 1, 4, 3, 5] // no tone, huyền, sắc, ngã, hỏi, nặng
        return order.map { tone in
            var chars = original
            let replacement = forms[tone]
            chars[index] = String(original[index]).uppercased() == String(original[index])
                ? Character(String(replacement).uppercased()) : replacement
            return String(chars)
        }
    }

    /// Keys are scoped to the physical unaccented word. Thus usage of
    /// "mình" cannot promote that tone when swiping a different spelling.
    static func glideUsageKey(_ word: String) -> String {
        let plain = word.lowercased()
            .folding(options: [.diacriticInsensitive], locale: Locale(identifier: "vi_VN"))
            .replacingOccurrences(of: "đ", with: "d")
        return plain + "|" + word.lowercased()
    }

    /// Initially show all six choices. After the user has repeatedly
    /// selected a tone, keep only choices with meaningful local frequency.
    /// "showAll" always restores every option, even after training.
    static func glideOptions(_ candidates: [String], language: String = "auto",
                             usage: [String: Int] = [:],
                             showAll: Bool = false) -> [String] {
        guard let first = candidates.first else { return [] }
        var options: [String] = []
        var seen = Set<String>()
        let isVietnamese = language != "en"
            && candidates.contains(where: { vietnameseSet.contains($0.lowercased()) })
        if isVietnamese {
            // Seed from a Vietnamese dictionary word, rather than an English
            // spelling which may happen to share the gesture.
            let seed = candidates.first(where: {
                vietnameseSet.contains($0.lowercased())
            }) ?? first
            for candidate in glideToneVariants(seed) {
                if seen.insert(candidate).inserted { options.append(candidate) }
            }
        }
        for candidate in candidates where seen.insert(candidate).inserted {
            options.append(candidate)
        }

        let counts = options.map { usage[glideUsageKey($0)] ?? 0 }
        let total = counts.reduce(0, +)
        let highest = counts.max() ?? 0
        if total >= 5 && highest >= 3 && !showAll {
            let cutoff = max(2, highest / 3)
            let frequent = options.filter {
                (usage[glideUsageKey($0)] ?? 0) >= cutoff
            }
            if !frequent.isEmpty {
                return frequent.sorted {
                    let a = usage[glideUsageKey($0)] ?? 0
                    let b = usage[glideUsageKey($1)] ?? 0
                    return a > b
                }.prefix(3).map { $0 }
            }
        }
        // Recently used words sort first; unexplored options remain visible.
        return options.enumerated().sorted { a, b in
            let x = usage[glideUsageKey(a.element)] ?? 0
            let y = usage[glideUsageKey(b.element)] ?? 0
            return x == y ? a.offset < b.offset : x > y
        }.map(\.element)
    }

    /// A Vietnamese word may begin with đ while the physical QWERTY swipe
    /// starts on d. Validate against the accent-free key spelling.
    static func glideStartsWithPhysicalKey(_ word: String, key: String) -> Bool {
        guard let first = glideSpelling(word)?.first else { return false }
        return String(first) == key.lowercased()
    }

    private static func glideSpelling(_ word: String) -> String? {
        let plain = word.lowercased()
            .folding(options: [.diacriticInsensitive], locale: Locale(identifier: "vi_VN"))
            .replacingOccurrences(of: "đ", with: "d")
        guard !plain.isEmpty,
              plain.allSatisfy({ $0.isASCII && $0.isLetter }) else { return nil }
        return collapseRepeats(plain)
    }

    private static func rankedGlideWords(
        _ words: [String], trace: String, learned: [String: Int],
        language: String, limit: Int
    ) -> [String] {
        // Known Latin English words win only when the *whole trace* matches
        // them in automatic mode. Otherwise Vietnamese is preferred; users
        // can override this using the language preference.
        func languageRank(_ word: String) -> Int {
            let vi = vietnameseSet.contains(word.lowercased())
            let en = englishSet.contains(word.lowercased())
            switch language {
            case "vi": return vi ? 0 : 2
            case "en": return en ? 0 : 2
            default:
                if en && glideSpelling(word) == trace { return 0 }
                return vi ? 1 : 2
            }
        }
        var seen = Set<String>()
        return Array(words.sorted {
            let a = languageRank($0), b = languageRank($1)
            if a != b { return a < b }
            let fa = learned[$0] ?? 0, fb = learned[$1] ?? 0
            if fa != fb { return fa > fb }
            // Preserve the dictionary order for equally plausible tones:
            // common Vietnamese variants remain available for manual choice.
            return false
        }.filter { seen.insert($0).inserted }.prefix(limit))
    }

    private static let qwertyCenters: [Character: (Double, Double)] = {
        var result: [Character: (Double, Double)] = [:]
        let rows = ["qwertyuiop", "asdfghjkl", "zxcvbnm"]
        for (rowIndex, row) in rows.enumerated() {
            let offset: Double = rowIndex == 0 ? 0 : (rowIndex == 1 ? 0.5 : 1.5)
            for (index, key) in row.enumerated() {
                result[key] = (Double(index) + offset, Double(rowIndex))
            }
        }
        return result
    }()

    private static func strokePoints(_ text: String) -> [(Double, Double)]? {
        guard let plain = glideSpelling(text) else { return nil }
        var points: [(Double, Double)] = []
        for key in plain {
            guard let position = qwertyCenters[key] else { return nil }
            points.append(position)
        }
        return points.count >= 2 ? points : nil
    }

    private static func resampleStroke(_ points: [(Double, Double)],
                                       count: Int = 16) -> [(Double, Double)] {
        guard points.count >= 2 else { return points }
        var cumulative: [Double] = [0]
        for index in 1..<points.count {
            let dx = points[index].0 - points[index - 1].0
            let dy = points[index].1 - points[index - 1].1
            cumulative.append(cumulative[index - 1] + hypot(dx, dy))
        }
        guard let length = cumulative.last, length > 0 else {
            return Array(repeating: points[0], count: count)
        }
        var output: [(Double, Double)] = []
        var segment = 0
        for index in 0..<count {
            let distance = Double(index) * length / Double(count - 1)
            while segment + 1 < cumulative.count - 1
                    && cumulative[segment + 1] < distance {
                segment += 1
            }
            let span = max(0.00001, cumulative[segment + 1] - cumulative[segment])
            let t = min(1, max(0, (distance - cumulative[segment]) / span))
            output.append((
                points[segment].0 + t * (points[segment + 1].0 - points[segment].0),
                points[segment].1 + t * (points[segment + 1].1 - points[segment].1)
            ))
        }
        return output
    }

    private static func geometryGlideCandidates(
        trace: String, dictionary: [String], learned: [String: Int],
        language: String, limit: Int
    ) -> [String] {
        guard let points = strokePoints(trace) else { return [] }
        let observed = resampleStroke(points)
        let first = trace.first
        let last = trace.last
        var scores: [(word: String, cost: Double)] = []
        for word in dictionary {
            guard let wordSpelling = glideSpelling(word),
                  wordSpelling.first == first,
                  wordSpelling.last == last,
                  let wordPoints = strokePoints(word) else { continue }
            let ideal = resampleStroke(wordPoints)
            var squared: Double = 0
            for (a, b) in zip(observed, ideal) {
                let dx = a.0 - b.0
                let dy = a.1 - b.1
                squared += dx * dx + dy * dy
            }
            let rms = sqrt(squared / Double(observed.count))
            if rms < 1.25 { scores.append((word, rms)) }
        }
        let ordered = scores.sorted {
            if abs($0.cost - $1.cost) > 0.12 { return $0.cost < $1.cost }
            let a = learned[$0.word] ?? 0, b = learned[$1.word] ?? 0
            if a != b { return a > b }
            return $0.cost < $1.cost
        }
        guard let best = ordered.first?.cost else { return [] }
        // Prefer words with a similar path, then let the explicit language
        // preference order accented alternatives sharing the same stroke.
        return rankedGlideWords(
            ordered.filter { $0.cost <= best + 0.20 }.map(\.word),
            trace: trace, learned: learned, language: language, limit: limit)
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

    static func expandSnippet(_ text: String, now: Date = Date(),
                              recipient: String? = nil) -> String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "vi_VN")
        fmt.dateFormat = "dd/MM/yyyy"
        let date = fmt.string(from: now)
        fmt.dateFormat = "HH:mm"
        let time = fmt.string(from: now)
        var result = text.replacingOccurrences(of: "{date}", with: date)
            .replacingOccurrences(of: "{time}", with: time)
        // Never guess the recipient from another app. Only an explicitly
        // selected profile can fill the recipient placeholder.
        if let recipient, !recipient.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            result = result.replacingOccurrences(of: "{recipient}",
                with: String(recipient.prefix(80)))
        }
        return result
    }
}
