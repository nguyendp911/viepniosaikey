import Foundation

/// Offline, source-grounded hints from OCR text explicitly supplied by the
/// user. No assumption about who wrote a line, when it was sent, or what the
/// other person intended. The user must review before using AI or Calendar.
enum ConversationLens {
    struct Finding: Equatable, Identifiable {
        enum Kind: String { case question, followUp }
        let kind: Kind
        let text: String
        var id: String { kind.rawValue + ":" + text }
    }

    static func findings(in text: String, limit: Int = 6) -> [Finding] {
        let lines = text.components(separatedBy: .newlines)
        var results: [Finding] = []
        var seen = Set<String>()
        let reminderWords = ["nhắc", "gửi", "hẹn", "lịch", "họp",
                             "ngày mai", "thứ hai", "thứ ba", "thứ tư",
                             "thứ năm", "thứ sáu", "thứ bảy", "chủ nhật",
                             "deadline", "tomorrow", "meeting"]
        guard limit > 0 else { return [] }
        for source in lines {
            let line = source.trimmingCharacters(in: .whitespacesAndNewlines)
            guard line.count >= 6, line.count <= 240 else { continue }
            let folded = ConversationIntelligence.normalized(line)
            guard seen.insert(folded).inserted else { continue }
            if line.contains("?") || line.contains("？") {
                results.append(Finding(kind: .question, text: line))
            } else if reminderWords.contains(where: {
                folded.contains(ConversationIntelligence.normalized($0))
            }) {
                results.append(Finding(kind: .followUp, text: line))
            }
            if results.count >= max(0, min(limit, 12)) { break }
        }
        return results
    }

    static func summary(_ findings: [Finding]) -> String {
        guard !findings.isEmpty else {
            return "Chưa nhận thấy câu hỏi hoặc việc cần theo dõi rõ ràng trong văn bản đã cung cấp."
        }
        return findings.map {
            ($0.kind == .question ? "Câu hỏi cần xem: " : "Có thể cần theo dõi: ")
                + $0.text
        }.joined(separator: "\n")
    }
}
