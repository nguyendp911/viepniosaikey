import Foundation

/// Learned next-word statistics. Stored only on this device (App Group
/// preferences); never uploaded. Bounded so it stays small and fast to load.
struct NextWordModel: Codable, Equatable {
    /// "previous word" -> [next word: times used]
    var bigrams: [String: [String: Int]] = [:]
    /// "word1 word2" -> [next word: times used]
    var trigrams: [String: [String: Int]] = [:]

    static let maxContexts = 400
    static let maxNextPerContext = 6
    static let maxCount = 999

    static func decode(_ data: Data?) -> NextWordModel {
        guard let data = data,
              let model = try? JSONDecoder().decode(NextWordModel.self, from: data) else {
            return NextWordModel()
        }
        return model
    }

    func encoded() -> Data? { try? JSONEncoder().encode(self) }
}

/// Offline next-word prediction: after "em ăn " it suggests "cơm", "chưa",
/// "gì"... Learned habits (the user's own bigrams/trigrams) rank above the
/// built-in Vietnamese chat starter table. Lookups are dictionary reads, so
/// this is safe to call synchronously on the keyboard's typing path.
enum NextWordPredictor {
    private static let scanLimit = 120

    // MARK: Context extraction

    /// Last words (up to `maxWords`) of the current sentence in `text`,
    /// lowercased and NFC-normalised. Scans only the tail of the text, so it
    /// costs the same in a short field and in a very long chat.
    static func words(in text: String, maxWords: Int = 3) -> [String] {
        guard maxWords > 0 else { return [] }
        var collected: [String] = []
        var current: [Character] = []
        var scanned = 0
        var truncated = false
        scan: for ch in text.reversed() {
            scanned += 1
            if scanned > scanLimit { truncated = true; break scan }
            if ch.isLetter {
                current.append(ch)
                continue
            }
            if !current.isEmpty {
                collected.append(String(current.reversed()))
                current.removeAll(keepingCapacity: true)
                if collected.count == maxWords { break scan }
            }
            // A sentence boundary ends the context: no prediction across it.
            if ch == "." || ch == "!" || ch == "?" || ch == "…" || ch.isNewline {
                break scan
            }
        }
        if !current.isEmpty && !truncated && collected.count < maxWords {
            collected.append(String(current.reversed()))
        }
        return collected.reversed().map(normalize)
    }

    static func normalize(_ word: String) -> String {
        word.lowercased().precomposedStringWithCanonicalMapping
    }

    // MARK: Prediction

    /// Up to `limit` likely next words. `words` is the context from
    /// `words(in:)`; the last element is the word just completed.
    static func predict(after words: [String], model: NextWordModel,
                        limit: Int = 3) -> [String] {
        guard limit > 0, let last = words.last, !last.isEmpty else { return [] }
        var scores: [String: Int] = [:]
        func consider(_ word: String, _ score: Int) {
            guard word != last else { return }
            if score > (scores[word] ?? Int.min) { scores[word] = score }
        }
        if words.count >= 2 {
            let key = words[words.count - 2] + " " + last
            for (word, count) in model.trigrams[key] ?? [:] { consider(word, 2000 + count) }
            for (rank, word) in (seedTrigrams[key] ?? []).enumerated() {
                consider(word, 600 - rank * 10)
            }
        }
        for (word, count) in model.bigrams[last] ?? [:] {
            // A habit seen at least twice outranks the built-in phrase table;
            // a single sighting only ranks below the built-in trigram phrases.
            consider(word, count >= 2 ? 1000 + count : 450)
        }
        for (rank, word) in (seedBigrams[last] ?? []).enumerated() {
            consider(word, 300 - rank * 10)
        }
        return scores
            .sorted { $0.value != $1.value ? $0.value > $1.value : $0.key < $1.key }
            .prefix(limit)
            .map { $0.key }
    }

    /// Touch the lazily built tables so the first space press is not slower.
    static func warmUp() {
        _ = predict(after: ["em", "ăn"], model: NextWordModel())
    }

    // MARK: Learning

    /// Record that `words.last` followed the words before it. Call once per
    /// completed word, only when the user allowed on-device learning.
    static func learn(words: [String], into model: inout NextWordModel) {
        guard words.count >= 2, let next = words.last, isLearnable(next) else { return }
        let previous = words[words.count - 2]
        guard isLearnable(previous) else { return }
        bump(&model.bigrams, key: previous, next: next)
        if words.count >= 3 {
            bump(&model.trigrams, key: words[words.count - 3] + " " + previous, next: next)
        }
    }

    private static func isLearnable(_ word: String) -> Bool {
        !word.isEmpty && word.count <= 24
    }

    private static func bump(_ table: inout [String: [String: Int]],
                             key: String, next: String) {
        var entry = table[key] ?? [:]
        entry[next] = min(NextWordModel.maxCount, (entry[next] ?? 0) + 1)
        if entry.count > NextWordModel.maxNextPerContext {
            // Evict the least-used other word so a new word can still enter.
            let weakest = entry
                .filter { $0.key != next }
                .min { $0.value != $1.value ? $0.value < $1.value : $0.key > $1.key }
            if let weakest = weakest { entry.removeValue(forKey: weakest.key) }
        }
        table[key] = entry
        if table.count > NextWordModel.maxContexts { prune(&table) }
    }

    private static func prune(_ table: inout [String: [String: Int]]) {
        let ranked = table
            .map { (key: $0.key, total: $0.value.values.reduce(0, +)) }
            .sorted { $0.total != $1.total ? $0.total < $1.total : $0.key < $1.key }
        let excess = table.count - (NextWordModel.maxContexts - 40)
        for item in ranked.prefix(max(0, excess)) {
            table.removeValue(forKey: item.key)
        }
    }

    // MARK: Built-in starter phrases (Vietnamese chat)

    /// Phrases keyed by the last TWO words. Most specific, ranked first.
    static let seedTrigrams: [String: [String]] = [
        "em ăn": ["cơm", "chưa", "gì", "rồi"],
        "anh ăn": ["cơm", "chưa", "gì", "rồi"],
        "chị ăn": ["cơm", "chưa", "gì", "rồi"],
        "bạn ăn": ["cơm", "chưa", "gì", "rồi"],
        "mình ăn": ["gì", "cơm", "chưa", "thôi"],
        "ăn cơm": ["chưa", "rồi", "nhé", "với"],
        "ăn gì": ["vậy", "chưa", "thế", "nhỉ"],
        "ăn chưa": ["em", "anh", "vậy", "nhỉ"],
        "ăn sáng": ["chưa", "rồi", "nhé", "nha"],
        "ăn trưa": ["chưa", "rồi", "nhé", "nha"],
        "ăn tối": ["chưa", "rồi", "nhé", "nha"],
        "em ngủ": ["chưa", "ngon", "rồi", "đi"],
        "anh ngủ": ["chưa", "ngon", "rồi", "đi"],
        "ngủ chưa": ["em", "anh", "vậy", "nhỉ"],
        "ngủ ngon": ["nhé", "nha", "em", "anh"],
        "chúc ngủ": ["ngon"],
        "chúc em": ["ngủ", "một", "ngày", "luôn"],
        "chúc anh": ["ngủ", "một", "ngày", "luôn"],
        "chúc bạn": ["ngủ", "một", "ngày", "luôn"],
        "chúc mừng": ["sinh", "năm", "em", "anh"],
        "một ngày": ["tốt", "mới", "vui", "bình"],
        "em đang": ["làm", "ở", "ăn", "nghĩ", "ngủ"],
        "anh đang": ["làm", "ở", "ăn", "nghĩ", "ngủ"],
        "bạn đang": ["làm", "ở", "ăn", "nghĩ"],
        "đang làm": ["gì", "việc", "sao", "bài"],
        "làm gì": ["vậy", "đó", "thế", "đấy"],
        "đang ở": ["đâu", "nhà", "đây", "công"],
        "ở đâu": ["vậy", "thế", "đó", "rồi"],
        "ở nhà": ["không", "chưa", "à", "hả"],
        "em nhớ": ["anh", "nhiều", "lắm", "quá"],
        "anh nhớ": ["em", "nhiều", "lắm", "quá"],
        "nhớ em": ["nhiều", "lắm", "quá", "không"],
        "nhớ anh": ["nhiều", "lắm", "quá", "không"],
        "yêu em": ["nhiều", "lắm", "nhất", "nhé"],
        "yêu anh": ["nhiều", "lắm", "nhất", "nhé"],
        "em yêu": ["anh", "nhiều", "lắm", "quá"],
        "anh yêu": ["em", "nhiều", "lắm", "quá"],
        "cảm ơn": ["nhiều", "em", "anh", "bạn", "rất"],
        "xin lỗi": ["em", "anh", "bạn", "nhé", "vì"],
        "xin chào": ["bạn", "em", "anh", "mọi"],
        "ngày mai": ["em", "anh", "mình", "đi", "gặp"],
        "tối nay": ["em", "anh", "mình", "đi", "ăn"],
        "hôm nay": ["em", "anh", "thế", "trời", "bạn"],
        "có không": ["vậy", "nhỉ", "nha", "em"],
        "được không": ["em", "anh", "nhỉ", "nha"],
        "được chưa": ["em", "anh", "vậy", "nhỉ"],
        "xong chưa": ["em", "anh", "vậy", "nhỉ"],
        "về chưa": ["em", "anh", "vậy", "nhỉ"],
        "đến chưa": ["em", "anh", "vậy", "nhỉ"],
        "khỏe không": ["em", "anh", "bạn", "nhé", "nha"],
        "khoẻ không": ["em", "anh", "bạn", "nhé", "nha"],
        "thế nào": ["rồi", "em", "anh", "vậy"],
        "làm sao": ["vậy", "thế", "đây", "đó"],
        "sao rồi": ["em", "anh", "bạn", "nhỉ"],
        "đi đâu": ["vậy", "thế", "đó", "rồi"],
        "đi chơi": ["không", "đâu", "nhé", "nha"],
        "đi ngủ": ["sớm", "nhé", "đi", "thôi"],
        "đi ăn": ["gì", "không", "nhé", "nha"],
        "đi làm": ["chưa", "rồi", "không", "nhé"],
        "đi học": ["chưa", "rồi", "không", "nhé"],
        "không sao": ["đâu", "em", "anh", "nhé"],
        "không biết": ["nữa", "đâu", "sao", "làm"],
        "không có": ["gì", "chuyện", "đâu", "ai"],
        "tốt lành": ["nhé", "nha", "em", "anh"]
    ]

    /// Phrases keyed by the last word only.
    static let seedBigrams: [String: [String]] = [
        "em": ["ăn", "đang", "có", "nhớ", "yêu", "ơi"],
        "anh": ["ăn", "đang", "có", "nhớ", "yêu", "ơi"],
        "chị": ["ơi", "đang", "ăn", "khỏe"],
        "mẹ": ["ơi", "đang", "ăn", "khỏe"],
        "ba": ["ơi", "đang", "ăn", "khỏe"],
        "ông": ["ơi", "đang", "ăn", "khỏe"],
        "bà": ["ơi", "đang", "ăn", "khỏe"],
        "con": ["đang", "ăn", "về", "nhớ"],
        "cô": ["ơi", "giáo", "ấy", "đang"],
        "tôi": ["là", "muốn", "cần", "đang"],
        "tớ": ["là", "muốn", "cần", "đang"],
        "mình": ["đi", "ăn", "gặp", "cùng"],
        "bạn": ["ơi", "có", "đang", "khỏe", "thế"],
        "ăn": ["cơm", "chưa", "gì", "rồi", "sáng"],
        "cơm": ["chưa", "rồi", "nhé", "với"],
        "ngủ": ["chưa", "ngon", "đi", "sớm"],
        "đang": ["làm", "ở", "ăn", "ngủ", "nghĩ", "đợi"],
        "làm": ["gì", "việc", "sao", "xong"],
        "gì": ["vậy", "thế", "đó", "nè"],
        "sao": ["rồi", "vậy", "thế", "không"],
        "có": ["không", "chuyện", "gì", "nhớ"],
        "không": ["vậy", "nhỉ", "nha", "sao"],
        "chưa": ["vậy", "nhỉ", "em", "anh"],
        "rồi": ["nhé", "nha", "nè", "em"],
        "xin": ["chào", "lỗi", "phép"],
        "cảm": ["ơn", "thấy", "giác"],
        "ơn": ["nhiều", "em", "anh", "bạn"],
        "chào": ["buổi", "em", "anh", "bạn", "mọi"],
        "chúc": ["ngủ", "bạn", "em", "anh", "mừng"],
        "ngon": ["quá", "lắm", "không", "miệng"],
        "nhớ": ["em", "anh", "nhiều", "lắm"],
        "yêu": ["em", "anh", "nhiều", "thương", "lắm"],
        "thương": ["em", "anh", "nhiều", "lắm"],
        "hôm": ["nay", "qua", "kia"],
        "nay": ["em", "anh", "thế", "trời", "bạn"],
        "ngày": ["mai", "nay", "mới", "tốt"],
        "mai": ["em", "anh", "mình", "đi", "gặp"],
        "tối": ["nay", "qua", "mai", "nhé"],
        "sáng": ["nay", "mai", "nhé", "qua"],
        "trưa": ["nay", "mai", "nhé"],
        "chiều": ["nay", "mai", "qua", "nhé"],
        "đi": ["đâu", "chơi", "ăn", "làm", "ngủ"],
        "đâu": ["vậy", "rồi", "thế", "đó"],
        "ở": ["đâu", "nhà", "đây", "đó"],
        "nhà": ["chưa", "rồi", "em", "anh", "mình"],
        "về": ["nhà", "chưa", "rồi", "đến", "sớm"],
        "đến": ["chưa", "nơi", "rồi", "nhà"],
        "cùng": ["nhau", "đi", "ăn", "em"],
        "với": ["em", "anh", "nhau", "bạn", "mình"],
        "cũng": ["được", "vậy", "thế", "rất"],
        "được": ["rồi", "không", "chứ", "nha"],
        "rất": ["vui", "nhớ", "tốt", "đẹp", "thích"],
        "vui": ["lắm", "quá", "vẻ", "nha"],
        "quá": ["đi", "trời", "rồi", "nhỉ"],
        "lắm": ["rồi", "đó", "nha", "luôn"],
        "thật": ["sự", "là", "vậy", "đấy"],
        "ơi": ["đang", "cho", "giúp", "ở"],
        "khỏe": ["không", "hơn", "nha", "chứ"],
        "khoẻ": ["không", "hơn", "nha", "chứ"],
        "giúp": ["em", "anh", "mình", "tôi", "với"],
        "cho": ["em", "anh", "mình", "tôi", "hỏi"],
        "hỏi": ["chút", "thăm", "một", "em"],
        "một": ["chút", "lát", "lúc", "ngày"],
        "chút": ["nữa", "nhé", "nha", "đi"],
        "lát": ["nữa", "nhé", "nha", "gặp"],
        "đợi": ["chút", "em", "anh", "mình"],
        "chờ": ["chút", "em", "anh", "mình"],
        "xong": ["rồi", "chưa", "nhé", "việc"],
        "nghỉ": ["ngơi", "chút", "đi", "nhé"],
        "lo": ["lắng", "cho", "quá", "gì"],
        "đừng": ["lo", "buồn", "quên", "giận"],
        "quên": ["mất", "rồi", "nhé", "nha"],
        "biết": ["rồi", "không", "chưa", "đâu"],
        "hiểu": ["rồi", "không", "chưa", "ý"],
        "muốn": ["ăn", "đi", "gặp", "ngủ"],
        "thích": ["lắm", "quá", "không", "ăn"],
        "cần": ["gì", "giúp", "không", "nghỉ"],
        "alo": ["em", "anh", "bạn", "ơi"],
        "hi": ["em", "anh", "bạn"],
        "dạ": ["vâng", "được", "em", "anh", "ạ"],
        "vâng": ["ạ", "em", "anh", "được"],
        "ok": ["em", "anh", "nhé", "nha", "rồi"],
        "oke": ["em", "anh", "nhé", "nha", "rồi"],
        "thôi": ["được", "rồi", "nhé", "đi"],
        "vậy": ["à", "hả", "nhé", "thì"],
        "thế": ["nào", "à", "hả", "thì"],
        "nào": ["vậy", "thế", "đó", "nhỉ"],
        "bao": ["giờ", "nhiêu", "lâu", "xa"],
        "nhiêu": ["vậy", "thế", "tiền", "anh"],
        "mấy": ["giờ", "tuổi", "người", "hôm"],
        "giờ": ["này", "nào", "rồi", "nhé"],
        "này": ["em", "anh", "nhé", "thì"],
        "đó": ["em", "anh", "nhé", "rồi"],
        "đây": ["em", "anh", "nè", "rồi"],
        "lúc": ["nào", "nãy", "đó", "này"],
        "khi": ["nào", "nãy", "đó", "em"],
        "sắp": ["đến", "xong", "về", "tới"],
        "đã": ["ăn", "về", "xong", "đến", "biết"],
        "mới": ["về", "đến", "xong", "dậy"],
        "chắc": ["là", "chắn", "chưa", "vậy"],
        "phải": ["không", "là", "đi", "làm"],
        "nữa": ["không", "nhé", "nha", "rồi"],
        "lại": ["đây", "đi", "nhé", "nha"],
        "thấy": ["không", "sao", "thế", "ổn"],
        "ổn": ["không", "chứ", "rồi", "hơn"],
        "mệt": ["không", "lắm", "quá", "rồi"],
        "buồn": ["ngủ", "không", "lắm", "quá"],
        "đói": ["không", "bụng", "quá", "rồi"],
        "uống": ["nước", "gì", "cà", "thuốc"],
        "cà": ["phê"],
        "phê": ["không", "chưa", "nhé", "nè"],
        "nước": ["chưa", "nhé", "ngọt", "mát"],
        "xem": ["phim", "gì", "không", "tin"],
        "phim": ["gì", "không", "chưa", "hay"],
        "chơi": ["game", "đi", "không", "nhé"],
        "game": ["gì", "không", "nè", "nhé"],
        "đọc": ["sách", "tin", "truyện", "chưa"],
        "học": ["bài", "chưa", "gì", "xong"],
        "bài": ["tập", "viết", "chưa", "hát"],
        "công": ["việc", "ty", "nghệ", "ơn"],
        "việc": ["gì", "nhà", "chưa", "xong"],
        "họp": ["chưa", "lúc", "với", "xong"],
        "tiền": ["chưa", "nhé", "bạc", "nữa"],
        "giá": ["bao", "sao", "rẻ", "rồi"],
        "dậy": ["chưa", "rồi", "sớm", "đi"],
        "sớm": ["nhé", "nha", "nào", "thôi"],
        "thức": ["dậy", "khuya", "giấc", "ăn"],
        "khuya": ["rồi", "quá", "nhé", "không"],
        "tạm": ["biệt", "thời", "ổn", "dừng"],
        "hẹn": ["gặp", "lại", "em", "anh"],
        "gặp": ["lại", "nhau", "em", "anh"],
        "thành": ["công", "phố", "thật", "viên"],
        "may": ["mắn", "quá", "thay", "là"],
        "tuyệt": ["vời", "quá", "đẹp", "lắm"],
        "đẹp": ["quá", "lắm", "trai", "không"],
        "xinh": ["quá", "lắm", "đẹp", "thế"],
        "giỏi": ["quá", "lắm", "thật", "ghê"],
        "cố": ["gắng", "lên", "nhé", "nha"],
        "gắng": ["lên", "nhé", "nha", "nữa"],
        "mừng": ["sinh", "năm", "em", "anh"],
        "sinh": ["nhật", "viên", "hoạt", "ra"],
        "nhật": ["vui", "em", "anh", "nhé"],
        "vẻ": ["nhé", "nha", "em", "anh"],
        "bình": ["an", "thường", "tĩnh", "yên"],
        "an": ["toàn", "tâm", "lành", "nhé"],
        "sức": ["khỏe", "lực", "mạnh"],
        "tốt": ["lành", "nhất", "hơn", "lắm"],
        "lành": ["nhé", "nha", "em", "anh"]
    ]
}
