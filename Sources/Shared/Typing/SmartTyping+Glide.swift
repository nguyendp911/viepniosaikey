import Foundation

extension SmartTyping {
    // Index immutable words by endpoints before any edit-distance work.
    static let glideBuckets: [String: [String]] = {
        var result: [String: [String]] = [:]
        for word in Set(englishWords + vietnameseWords).sorted() {
            guard let spelling = glideSpelling(word),
                  let first = spelling.first, let last = spelling.last else { continue }
            result[String(first) + String(last), default: []].append(word)
        }
        return result
    }()

    /// Reject incidental tiny finger movements on a normal key tap.
    /// Pan recognizers can begin after very little movement; treating two
    /// neighboring key hits as a word previously caused accidental inserts.
    static func isIntentionalGlide(trace: String, travelPoints: Double,
                                   keyHeight: Double) -> Bool {
        trace.count >= 2 && trace.count <= 140
            && travelPoints >= max(22, keyHeight * 0.85)
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
        guard trace.count >= 2, trace.count <= 140, limit > 0,
              trace.allSatisfy({ $0.isASCII && $0.isLetter }) else { return [] }
        // English-only mode must never insert an accented Vietnamese word.
        // Learned plain ASCII words are still eligible in that mode.
        let endpoint = String(trace.first!) + String(trace.last!)
        let builtIn = glideBuckets[endpoint] ?? []
        let dictionary = Array(Set(builtIn.filter { language != "en" || englishSet.contains($0) }
            + learned.keys.filter { word in
                guard let spelling = glideSpelling(word),
                      spelling.first == trace.first, spelling.last == trace.last else { return false }
                return language != "en" || word.allSatisfy { $0.isASCII && $0.isLetter }
            })).sorted()

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

    static func rankedGlideWords(
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

    static func collapseRepeats(_ input: String) -> String {
        var result = ""
        var last: Character?
        for ch in input {
            if ch != last { result.append(ch) }
            last = ch
        }
        return result
    }

    static func editDistance(_ a: [Character], _ b: [Character]) -> Int {
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
}
