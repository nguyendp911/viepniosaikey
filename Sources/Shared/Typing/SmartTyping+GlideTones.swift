import Foundation

extension SmartTyping {
    // Tone alternatives use the vowel shape of the recognized Vietnamese
    // word. The finger never needs to enter an extra Telex tone key.
    static let toneForms: [String] = [
        "aáàảãạ", "ăắằẳẵặ", "âấầẩẫậ", "eéèẻẽẹ",
        "êếềểễệ", "iíìỉĩị", "oóòỏõọ", "ôốồổỗộ",
        "ơớờởỡợ", "uúùủũụ", "ưứừửữự", "yýỳỷỹỵ"
    ]
    static let toneLookup: [Character: [Character]] = {
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
            if x != y { return x > y }
            // Before any learning, preserve the lexicon's first recognized
            // candidate (e.g. mình) instead of auto-inserting bare "minh".
            if a.element == first { return true }
            if b.element == first { return false }
            return a.offset < b.offset
        }.map(\.element)
    }

    /// A Vietnamese word may begin with đ while the physical QWERTY swipe
    /// starts on d. Validate against the accent-free key spelling.
    static func glideStartsWithPhysicalKey(_ word: String, key: String) -> Bool {
        guard let first = glideSpelling(word)?.first else { return false }
        return String(first) == key.lowercased()
    }

    static func glideSpelling(_ word: String) -> String? {
        let plain = word.lowercased()
            .folding(options: [.diacriticInsensitive], locale: Locale(identifier: "vi_VN"))
            .replacingOccurrences(of: "đ", with: "d")
        guard !plain.isEmpty,
              plain.allSatisfy({ $0.isASCII && $0.isLetter }) else { return nil }
        return collapseRepeats(plain)
    }
}
