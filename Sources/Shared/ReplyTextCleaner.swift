import Foundation

/// Keep the source message out of a generated reply, even if a model echoes it.
/// The keyboard never writes the source into the host field itself.
enum ReplyTextCleaner {
    static func answerOnly(_ candidate: String, source: String) -> String {
        let incoming = source.trimmingCharacters(in: .whitespacesAndNewlines)
        var result = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
        // Strip generic wrappers only at the start. Do not remove legitimate text.
        for label in ["Câu trả lời:", "Trả lời:", "Reply:", "Gợi ý:"] {
            if result.lowercased().hasPrefix(label.lowercased()) {
                result = String(result.dropFirst(label.count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                break
            }
        }
        guard !incoming.isEmpty else { return result }
        let sourceVariants = [
            incoming,
            "\"" + incoming + "\"",
            "“" + incoming + "”",
            "‘" + incoming + "’"
        ]
        for prefix in sourceVariants {
            if result.hasPrefix(prefix) {
                let tail = String(result.dropFirst(prefix.count))
                let separators = CharacterSet.whitespacesAndNewlines.union(
                    CharacterSet(charactersIn: ":;—–-\n")
                )
                let cleaned = tail.trimmingCharacters(in: separators)
                if !cleaned.isEmpty {
                    return cleaned
                }
            }
        }
        return result
    }
}
