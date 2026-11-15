import Foundation

/// On-device memory of proper nouns the user capitalised mid-sentence
/// ("Hà Nội", "Linh"), so they can be capitalised automatically next time.
/// Stored only locally and only when "remember typed words" is enabled.
struct ProperNounMemory: Codable, Equatable {
    struct Entry: Codable, Equatable {
        var display: String
        var count: Int
    }

    /// lowercase phrase ("hà nội") -> how it should be written + times seen
    var entries: [String: Entry] = [:]

    static let maxEntries = 200
    /// A name must be capitalised this many times before it is applied.
    static let minCountToApply = 2
    static let maxWordsPerName = 3

    static func decode(_ data: Data?) -> ProperNounMemory {
        guard let data = data,
              let memory = try? JSONDecoder().decode(ProperNounMemory.self, from: data) else {
            return ProperNounMemory()
        }
        return memory
    }

    func encoded() -> Data? { try? JSONEncoder().encode(self) }

    /// A word written like a name: first letter upper case, the rest lower
    /// case ("Hà", not "OK" or "iPhone").
    static func isCapitalised(_ word: String) -> Bool {
        guard let first = word.first, first.isUppercase else { return false }
        return word.dropFirst().allSatisfy { !$0.isUppercase }
    }

    private static func key(_ words: [String]) -> String {
        words.map { $0.lowercased().precomposedStringWithCanonicalMapping }
            .joined(separator: " ")
    }

    /// Learn from the raw (as typed) words before the caret. `words.last` is
    /// the word just finished. `reachedSentenceStart` is true when
    /// `words.first` begins the sentence (so its capital letter proves
    /// nothing). Run of capitalised words -> one phrase; a lone capitalised
    /// word in mid-sentence -> a single name.
    mutating func learn(words: [String], reachedSentenceStart: Bool) {
        guard let last = words.last, ProperNounMemory.isCapitalised(last) else { return }
        var run: [String] = []
        for word in words.reversed() {
            guard ProperNounMemory.isCapitalised(word),
                  run.count < ProperNounMemory.maxWordsPerName else { break }
            run.insert(word, at: 0)
        }
        // A capital letter at the start of a sentence proves nothing, so a
        // run that includes the sentence's first word is not learned.
        if reachedSentenceStart && run.count == words.count { return }
        if run.count >= 2 {
            bump(run)
        } else {
            bump([last])
        }
    }

    private mutating func bump(_ words: [String]) {
        guard words.allSatisfy({ !$0.isEmpty && $0.count <= 24 }) else { return }
        let k = ProperNounMemory.key(words)
        let display = words.joined(separator: " ")
        var entry = entries[k] ?? Entry(display: display, count: 0)
        entry.display = display
        entry.count = min(999, entry.count + 1)
        entries[k] = entry
        if entries.count > ProperNounMemory.maxEntries { prune() }
    }

    private mutating func prune() {
        var ranked: [(key: String, count: Int)] = []
        for (key, entry) in entries { ranked.append((key: key, count: entry.count)) }
        ranked.sort { (a: (key: String, count: Int), b: (key: String, count: Int)) -> Bool in
            if a.count != b.count { return a.count < b.count }
            return a.key < b.key
        }
        let excess = entries.count - (ProperNounMemory.maxEntries - 20)
        if excess > 0 {
            for item in ranked.prefix(excess) { entries.removeValue(forKey: item.key) }
        }
    }

    /// If the last typed words match a learned name written differently,
    /// returns how many words to replace and the correct form.
    func match(words: [String]) -> (wordCount: Int, display: String)? {
        guard !entries.isEmpty, !words.isEmpty else { return nil }
        var n = min(ProperNounMemory.maxWordsPerName, words.count)
        while n >= 1 {
            let tail = Array(words.suffix(n))
            if let entry = entries[ProperNounMemory.key(tail)],
               entry.count >= ProperNounMemory.minCountToApply,
               entry.display != tail.joined(separator: " ") {
                return (wordCount: n, display: entry.display)
            }
            n -= 1
        }
        return nil
    }
}
