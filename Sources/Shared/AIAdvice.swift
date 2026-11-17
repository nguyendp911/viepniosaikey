import Foundation

/// What the AI returns for the "calm things down" coach. Parsed defensively:
/// a missing or odd field never crashes, it just leaves that part out.
struct MediationAdvice: Equatable {
    struct Reply: Equatable {
        let tone: String
        let text: String
    }
    let summary: String
    let escalation: String
    let theirFeeling: String
    let avoid: [String]
    let replies: [Reply]
    let timing: String

    /// One short line for the keyboard's status bar.
    var statusLine: String {
        var parts: [String] = []
        if !theirFeeling.isEmpty { parts.append("Người ấy: " + theirFeeling) }
        if let first = avoid.first { parts.append("Tránh: " + first) }
        if !timing.isEmpty { parts.append(timing) }
        let line = "🧭 " + parts.joined(separator: " · ")
        return line.count > 140 ? String(line.prefix(139)) + "…" : line
    }

    private static func text(_ value: Any?, limit: Int) -> String {
        guard let raw = value as? String else { return "" }
        return String(raw.trimmingCharacters(in: .whitespacesAndNewlines).prefix(limit))
    }

    static func parse(_ payload: [String: Any]) -> MediationAdvice? {
        var replies: [Reply] = []
        for item in (payload["replies"] as? [[String: Any]] ?? []).prefix(3) {
            let body = text(item["text"], limit: 400)
            if body.isEmpty { continue }
            let tone = text(item["tone"], limit: 30)
            replies.append(Reply(tone: tone.isEmpty ? "Hạ nhiệt" : tone, text: body))
        }
        guard !replies.isEmpty else { return nil }
        var avoid: [String] = []
        for value in (payload["avoid"] as? [Any] ?? []).prefix(3) {
            let phrase = text(value, limit: 60)
            if !phrase.isEmpty { avoid.append(phrase) }
        }
        return MediationAdvice(summary: text(payload["summary"], limit: 220),
                               escalation: text(payload["escalation"], limit: 160),
                               theirFeeling: text(payload["their_feeling"], limit: 80),
                               avoid: avoid, replies: replies,
                               timing: text(payload["timing"], limit: 80))
    }
}

/// Short, neutral facts the AI proposes to remember about a person. They are
/// only suggestions: the user approves each one in the app.
enum MemoryFacts {
    static let maxSuggestions = 3
    static let maxLength = 120

    static func parse(_ payload: [String: Any]) -> [String] {
        var facts: [String] = []
        var seen = Set<String>()
        for value in (payload["facts"] as? [Any] ?? []) {
            guard let raw = value as? String else { continue }
            let fact = String(raw.trimmingCharacters(in: .whitespacesAndNewlines).prefix(maxLength))
            let key = fact.lowercased()
            if fact.count >= 6, seen.insert(key).inserted { facts.append(fact) }
            if facts.count >= maxSuggestions { break }
        }
        return facts
    }

    /// New suggestions that are not already known (case-insensitive).
    static func fresh(_ candidates: [String], known: [String]) -> [String] {
        var seen = Set(known.map { $0.lowercased() })
        var result: [String] = []
        for candidate in candidates where seen.insert(candidate.lowercased()).inserted {
            result.append(candidate)
        }
        return result
    }
}
