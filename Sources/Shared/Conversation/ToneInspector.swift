import Foundation

enum ToneInspector {
    static func suggestions(for text: String) -> [String] {
        let normal = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normal.isEmpty else { return [] }
        var issues: [String] = []
        if ["sao chưa", "làm ngay", "trả lời ngay", "im đi"].contains(where: normal.contains) {
            issues.append("Câu có thể gây áp lực; cân nhắc diễn đạt nhẹ nhàng hơn.")
        }
        if text.count < 12 && !text.contains("ạ") && !text.contains("nhé") {
            issues.append("Câu ngắn có thể hơi cộc tùy mối quan hệ.")
        }
        if text.filter({ $0 == "!" }).count >= 3 {
            issues.append("Nhiều dấu chấm than có thể khiến giọng điệu căng thẳng.")
        }
        return issues
    }
}
