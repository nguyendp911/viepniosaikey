import Foundation

extension SmartTyping {
    // Only suggest, never auto-insert: a single nearby-key typo should not
    // force English spelling on someone composing Vietnamese via Telex.
    // These 2D neighbors are generated once, without tracking touch locations.
    static let nearbyKeys: [Character: Set<Character>] = {
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
            if $0 == $1 { return false }
            if $0 == prefix { return true }
            if $1 == prefix { return false }
            // Keep common vocabulary ahead of obscure extended syllables.
            let coreA = coreVietnameseSet.contains($0) || englishSet.contains($0)
            let coreB = coreVietnameseSet.contains($1) || englishSet.contains($1)
            if coreA != coreB { return coreA }
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
        _ = glideBuckets["ai"]
    }
}
