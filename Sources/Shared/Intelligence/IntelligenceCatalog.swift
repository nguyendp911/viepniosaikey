import Foundation

struct IntelligenceTask: Identifiable, Equatable {
    let id: String
    let title: String
    let symbol: String
    let instruction: String
    let group: String

    static let tasks: [Self] = [
        .init(id: "conversation", title: "Phân tích hội thoại", symbol: "bubble.left.and.bubble.right", instruction: "Analyze the supplied Vietnamese chat. Summarize only explicit facts, identify the last question and possible misunderstandings, offer a tactful next step. Clearly distinguish observations from uncertainties. Never claim to know feelings, motives or identities. Respond in Vietnamese.", group: "Hội thoại"),
        .init(id: "reply", title: "Gợi ý trả lời", symbol: "message", instruction: "Draft one natural, respectful Vietnamese reply to the last incoming message. Preserve facts and avoid assumptions about identity.", group: "Hội thoại"),
        .init(id: "starter", title: "Mở đầu trò chuyện", symbol: "sun.max", instruction: "Write one low-pressure conversation opener in Vietnamese based only on the provided context. Do not invent shared history.", group: "Tình cảm"),
        .init(id: "comfort", title: "An ủi, quan tâm", symbol: "heart", instruction: "Write a warm Vietnamese reply acknowledging what was actually said. Ask gently if help is wanted; do not diagnose or pressure.", group: "Tình cảm"),
        .init(id: "apology", title: "Xin lỗi, làm hòa", symbol: "heart.circle", instruction: "Draft a sincere Vietnamese apology or repair message appropriate to the facts. Take responsibility only for what the user states; no coercion or guilt.", group: "Tình cảm"),
        .init(id: "flirt", title: "Làm quen, tán tỉnh", symbol: "sparkles", instruction: "Write one playful, respectful Vietnamese message. Avoid sexual pressure, manipulation or invented familiarity; preserve boundaries.", group: "Tình cảm"),
        .init(id: "boundary", title: "Đặt ranh giới", symbol: "hand.raised", instruction: "Draft a calm Vietnamese message communicating a clear boundary without insults or threats.", group: "Tình cảm"),
        .init(id: "customer", title: "Chăm sóc khách hàng", symbol: "person.2", instruction: "Compose a concise Vietnamese customer support response based on supplied facts. Ask for missing information; never invent policies or prices.", group: "Công việc"),
        .init(id: "sales", title: "Tư vấn & chốt đơn", symbol: "cart", instruction: "Draft a Vietnamese sales response based on supplied product facts. Be helpful, transparent and non-pressuring; no invented discounts or availability.", group: "Công việc"),
        .init(id: "quote", title: "Báo giá", symbol: "doc.text", instruction: "Format the supplied quotation details in professional Vietnamese. If price or terms are absent, label them as needing confirmation. Never invent amounts.", group: "Công việc"),
        .init(id: "complaint", title: "Xử lý khiếu nại", symbol: "exclamationmark.bubble", instruction: "Draft a respectful Vietnamese complaint response. Acknowledge the reported issue, ask for needed evidence, propose a next step without promising refunds or outcomes not supplied.", group: "Công việc"),
        .init(id: "expand", title: "Mở rộng nội dung", symbol: "text.append", instruction: "Expand the supplied text naturally in Vietnamese, preserving every known fact and not inventing facts.", group: "Viết"),
        .init(id: "proofread", title: "Sửa chính tả", symbol: "checkmark.seal", instruction: "Correct spelling and punctuation without changing meaning, names or numbers.", group: "Viết")
    ]
    static let languages = ["English", "Vietnamese", "Korean", "Japanese", "Chinese (Simplified)", "French", "German", "Spanish", "Thai"]
    static func translation(to language: String, bilingual: Bool, formal: Bool) -> String {
        let target = languages.contains(language) ? language : "English"
        return "Translate faithfully into \(target). Use \(formal ? "formal" : "natural conversational") language. "
            + (bilingual ? "Return the original text, then a newline and the translation." : "Return only the translation.")
    }
}

struct PersonalPrompt: Codable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    var title: String
    var instruction: String
}

enum PersonalPromptStore {
    private static let key = "viepnaikey.studio.prompts.v1"
    static var items: [PersonalPrompt] {
        get {
            guard let data = KeyboardSettings.defaults.data(forKey: key),
                  let entries = try? JSONDecoder().decode([PersonalPrompt].self, from: data) else { return [] }
            return entries
        }
        set {
            let entries = newValue.prefix(20).filter { !$0.title.isEmpty && !$0.instruction.isEmpty }
                .map { PersonalPrompt(id: $0.id, title: String($0.title.prefix(40)), instruction: String($0.instruction.prefix(600))) }
            if let data = try? JSONEncoder().encode(entries) { KeyboardSettings.defaults.set(data, forKey: key) }
        }
    }
}

enum PersonalStyleDNA {
    struct Metrics {
        let count: Int
        let averageWords: Int
        let questions: Int
        let exclamations: Int
        let commonWords: [String]
    }
    static func analyze(_ examples: [String]) -> Metrics {
        let clean = examples.prefix(8).map { String($0.prefix(350)) }
        let words = clean.flatMap { $0.lowercased().split(whereSeparator: { !$0.isLetter }).map(String.init) }
        var counts: [String: Int] = [:]
        for word in words where word.count > 1 { counts[word, default: 0] += 1 }
        let frequent = counts.sorted { $0.value == $1.value ? $0.key < $1.key : $0.value > $1.value }.prefix(6).map(\.key)
        return .init(count: clean.count, averageWords: words.count / max(1, clean.count),
                     questions: clean.filter { $0.contains("?") }.count,
                     exclamations: clean.filter { $0.contains("!") }.count, commonWords: frequent)
    }
}
