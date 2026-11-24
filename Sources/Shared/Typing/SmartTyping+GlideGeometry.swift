import Foundation

extension SmartTyping {
    static let qwertyCenters: [Character: (Double, Double)] = {
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

    static func strokePoints(_ text: String) -> [(Double, Double)]? {
        guard let plain = glideSpelling(text) else { return nil }
        var points: [(Double, Double)] = []
        for key in plain {
            guard let position = qwertyCenters[key] else { return nil }
            points.append(position)
        }
        return points.count >= 2 ? points : nil
    }

    static func resampleStroke(_ points: [(Double, Double)],
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

    /// Build the immutable stroke shapes once, not for every swipe. This
    /// removes repeated diacritic-folding, path resampling and allocations
    /// across the offline dictionary on each finger gesture.
    static let cachedGlideStrokes: [String: [(Double, Double)]] = {
        var entries: [String: [(Double, Double)]] = [:]
        for word in englishWords + vietnameseWords {
            guard entries[word] == nil, let points = strokePoints(word) else {
                continue
            }
            entries[word] = resampleStroke(points)
        }
        return entries
    }()

    static func geometryGlideCandidates(
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
                  wordSpelling.last == last else { continue }
            let ideal: [(Double, Double)]
            if let cached = cachedGlideStrokes[word] {
                ideal = cached
            } else if let points = strokePoints(word) {
                // Newly learned personal words are not part of the static
                // lexicon, and remain eligible without restarting the app.
                ideal = resampleStroke(points)
            } else {
                continue
            }
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
            // Quantized distance gives a strict, deterministic sort order.
            let bucketA = Int($0.cost / 0.12), bucketB = Int($1.cost / 0.12)
            if bucketA != bucketB { return bucketA < bucketB }
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
}
