import Foundation

/// Light, optional emoji enrichment. Sensitive and formal messages are left unchanged.
enum EmojiEnhancer {
    static func decorate(_ text: String, tone: String) -> String {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard KeyboardSettings.emojiEnabled, !cleaned.isEmpty else { return cleaned }
        if cleaned.unicodeScalars.contains(where: { $0.properties.isEmojiPresentation }) {
            return cleaned
        }
        let normalized = cleaned.folding(options: [.caseInsensitive, .diacriticInsensitive],
                                         locale: Locale(identifier: "vi_VN"))
        let context = tone.folding(options: [.caseInsensitive, .diacriticInsensitive],
                                   locale: Locale(identifier: "vi_VN"))
        // Avoid inserting emoji into formal, distressing, or potentially unsafe contexts.
        let sensitive = ["benh", "mat", "qua doi", "tai nan", "khong an toan", "nguy hiem",
                         "khoc", "tu tu", "khong dong y", "ep buoc", "hop dong", "hoa don", "bao gia"]
        if sensitive.contains(where: normalized.contains) ||
            context.contains("chuyen nghiep") || context.contains("trang trong") {
            return cleaned
        }
        let emoji: String?
        if normalized.contains("ngu ngon") || normalized.contains("mo dep") { emoji = "🌙" }
        else if normalized.contains("cam on") { emoji = "😊" }
        else if normalized.contains("co len") || normalized.contains("chuc may man") { emoji = "💪" }
        else if normalized.contains("nho") || normalized.contains("thuong") { emoji = "💗" }
        else if context.contains("ngot") || context.contains("de thuong") { emoji = "🥰" }
        else if context.contains("vui") || context.contains("hai huoc") { emoji = "😄" }
        else if context.contains("quan tam") { emoji = "🤍" }
        else if context.contains("than thien") { emoji = "😊" }
        else { emoji = nil }
        guard let emoji else { return cleaned }
        return cleaned + " " + emoji
    }
}
