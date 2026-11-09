import Foundation

/// Built-in, fictional Vietnamese couple examples. These are prompt references,
/// NOT private chat logs, model fine-tuning, or a data collection mechanism.
enum CoupleReplyGuide {
    struct Scene {
        let keywords: [String]
        let incoming: String
        let replies: [String]
    }

    private static let scenes: [Scene] = [
        .init(keywords: ["ngu ngon", "di ngu", "buon ngu", "mo dep", "chuc ngu"],
              incoming: "Em chuẩn bị đi ngủ rồi nè",
              replies: ["Ngủ ngon nha, mai thức dậy kể anh nghe giấc mơ nhé 🌙",
                        "Dạ, ngủ ngon nè. Mai mình nói chuyện tiếp nha.",
                        "Ngủ sớm cho khỏe nha, đừng thức khuya quá đó."]),
        .init(keywords: ["nho", "muon gap", "xa nhau", "nho anh", "nho em"],
              incoming: "Hôm nay tự nhiên nhớ anh ghê",
              replies: ["Anh cũng nhớ em. Khi nào rảnh mình gặp nhau nha 💗",
                        "Nghe vậy thấy ấm lòng ghê. Anh muốn nghe em kể hôm nay thế nào.",
                        "Anh gửi em một cái ôm từ xa nè 🤗"]),
        .init(keywords: ["met", "ap luc", "stress", "chay deadline", "bun ron"],
              incoming: "Hôm nay em mệt quá, không muốn làm gì hết",
              replies: ["Thương em, nghỉ ngơi chút nhé. Khi nào muốn kể thì anh nghe.",
                        "Hôm nay vất vả rồi. Em muốn anh lắng nghe hay giúp gì không?",
                        "Không cần cố vui đâu, cứ nghỉ ngơi cho lại sức nha 🤍"]),
        .init(keywords: ["gian", "gian nhau", "im lang", "khong noi chuyen", "cai nhau", "buon anh"],
              incoming: "Em đang giận anh thật đó",
              replies: ["Anh muốn hiểu điều gì làm em buồn. Em kể anh nghe được không?",
                        "Anh nghe đây, không vội cãi hay giải thích đâu.",
                        "Mình nói chuyện khi em thấy sẵn sàng nhé, anh tôn trọng cảm xúc của em."]),
        .init(keywords: ["xin loi", "loi cua", "tha loi", "bo qua"],
              incoming: "Em xin lỗi vì lúc nãy nóng tính",
              replies: ["Cảm ơn em đã nói vậy. Mình cùng bình tĩnh rồi nói chuyện nhé.",
                        "Anh biết em cũng đang mệt. Mình tìm cách hiểu nhau hơn nha.",
                        "Anh trân trọng lời xin lỗi của em. Khi nào thoải mái mình nói tiếp."]),
        .init(keywords: ["ghen", "nguoi khac", "ban trai", "ban gai", "nguoi yeu cu"],
              incoming: "Em đi chơi với bạn nam thì anh có ghen không?",
              replies: ["Anh tin mình có thể nói với nhau điều làm mỗi người thoải mái.",
                        "Quan trọng là hai đứa rõ ràng và tôn trọng nhau, em nghĩ sao?",
                        "Nếu có điều gì khiến anh băn khoăn, anh sẽ nói thẳng chứ không kiểm soát em."]),
        .init(keywords: ["ngu lai", "qua dem", "o lai", "sang ve", "khach san"],
              incoming: "Bạn rủ em ở lại qua đêm rồi sáng về",
              replies: ["Em thấy sao về lời rủ đó? Điều quan trọng nhất là em thoải mái và an toàn.",
                        "Nếu em không muốn thì mình cứ từ chối rõ ràng nhé, không cần ngại đâu.",
                        "Em muốn anh lắng nghe hay cùng em nghĩ cách trả lời lời rủ đó?"]),
        .init(keywords: ["hen ho", "di choi", "cuoi tuan", "gap nhau", "hen gap"],
              incoming: "Cuối tuần này mình đi đâu chơi nhỉ?",
              replies: ["Đi đâu cũng vui, miễn là được dành thời gian cho nhau 😊",
                        "Mình chọn chỗ yên tĩnh để nói chuyện nhé, em thấy sao?",
                        "Hay mỗi người chọn một địa điểm rồi cùng quyết định nè?"]),
        .init(keywords: ["an com", "an chua", "doi bung", "an gi"],
              incoming: "Anh ăn cơm chưa?",
              replies: ["Anh đang tính ăn nè. Còn em ăn gì rồi?",
                        "Em nhắc thế làm anh nhớ phải ăn đúng giờ 😊",
                        "Cảm ơn em hỏi thăm. Em cũng nhớ ăn đủ bữa nha."]),
        .init(keywords: ["ve nha", "ve chua", "toi nha", "di duong"],
              incoming: "Anh về tới nhà chưa?",
              replies: ["Anh về rồi, cảm ơn em hỏi thăm nha. Em ổn chứ?",
                        "Anh đang trên đường, tới nơi anh báo em nhé.",
                        "Thương em vì luôn quan tâm. Em nghỉ sớm nha."]),
        .init(keywords: ["yeu", "thuong", "cam tinh", "to tinh"],
              incoming: "Anh thương em nhiều không?",
              replies: ["Có chứ. Anh muốn thể hiện bằng cách quan tâm em mỗi ngày 💗",
                        "Thương theo kiểu muốn nghe em kể đủ chuyện nhỏ trong ngày đó.",
                        "Em muốn anh nói hay muốn anh làm gì để em cảm nhận rõ hơn nè?"]),
        .init(keywords: ["khong vui", "khoc", "tuoi than", "buon", "co don"],
              incoming: "Hôm nay em thấy buồn mà không biết nói với ai",
              replies: ["Anh ở đây nghe em nè. Không cần kể hết ngay nếu em chưa sẵn sàng.",
                        "Em có muốn kể điều gì làm em nặng lòng không? Anh nghe.",
                        "Cứ từ từ thôi, cảm xúc của em đáng được lắng nghe."]),
        .init(keywords: ["chuc mung", "thi do", "thanh cong", "tot nghiep", "diem cao"],
              incoming: "Em vừa nhận được tin tốt nè!",
              replies: ["Thật hả, kể anh nghe với! Anh vui lây luôn 🎉",
                        "Chúc mừng em nha, công sức của em được đền đáp rồi!",
                        "Phải ăn mừng thôi, em muốn tự thưởng cho mình gì nào?"]),
        .init(keywords: ["ban", "khong ranh", "hen sau", "de sau", "hom khac"],
              incoming: "Hôm nay em bận, mình hẹn hôm khác nha",
              replies: ["Ừ, em cứ lo việc trước nha. Khi nào rảnh mình hẹn lại 😊",
                        "Không sao đâu, mình chọn hôm nào cả hai thoải mái nhé.",
                        "Anh hiểu mà. Chúc em làm việc suôn sẻ nha."])
    ]

    private static func normalize(_ value: String) -> String {
        value.folding(options: [.diacriticInsensitive, .caseInsensitive],
                      locale: Locale(identifier: "vi_VN"))
    }

    private static func matchingScenes(for text: String) -> [Scene] {
        let input = normalize(text)
        let matched = scenes.filter { scene in scene.keywords.contains { input.contains($0) } }
        return Array((matched.isEmpty ? [scenes[0], scenes[2]] : matched).prefix(2))
    }

    static var isEnabled: Bool { KeyboardSettings.coupleEnabled }

    static var context: String {
        guard isEnabled else { return "" }
        let closeness = KeyboardSettings.coupleStage
        let pronouns = KeyboardSettings.coupleAddress
        let style = CoupleStyleCatalog.active
        let variants = style.variantNames.joined(separator: ", ")
        return """
        COUPLE MODE: Help the user compose Vietnamese relationship replies.
        Relationship context: \(closeness). Preferred forms of address: \(pronouns).
        SELECTED STYLE: \(style.title). Style directions: \(style.guidance).
        Name the three reply variants appropriately (suggested names: \(variants)).
        Keep every suggested reply consistent with the style, but with different phrasing and intensity.
        These preferences describe style only. Never assume anyone's gender, consent, relationship
        exclusivity or feelings. Match the actual incoming message rather than using a stock
        love confession; don't over-flirt, repeat the incoming text, or make up shared memories.
        Produce exactly THREE distinct natural, send-ready replies with at most one emoji each when appropriate.
        Distinct means separate alternatives, NOT three sequential messages. Don't concatenate replies.
        For sadness, conflict, jealousy, pressured intimacy or unsafe invitations,
        prioritize empathy, honest communication, boundaries and choice; labels may be
        "Lắng nghe", "Quan tâm", "Ranh giới". No guilt-tripping, possessiveness,
        sexual pressure, threats, manipulation or encouraging unsafe decisions.
        Don't sound like a therapist, lecture, or presume the user's answer is yes.
        Return concise Vietnamese replies, generally 12-45 words each. Each should be
        independent, not a continuation of the other two.
        """
    }

    /// Fictional few-shot demonstrations; only the most relevant two are sent.
    static func examples(for incoming: String) -> String {
        guard isEnabled else { return "" }
        let picks = matchingScenes(for: incoming)
        return picks.map { example in
            let variants = zip(["Dịu dàng", "Tự nhiên", "Quan tâm"], example.replies)
                .map { "\($0.0): \($0.1)" }.joined(separator: "\n")
            return "Ví dụ minh họa ngữ cảnh (không phải style bắt buộc): \(example.incoming)\nBa cách trả lời:\n\(variants)"
        }.joined(separator: "\n\n")
    }

    /// A small offline path, not a substitute for online model reasoning.
    static func offlineSuggestions(for incoming: String) -> [ReplySuggestion] {
        guard isEnabled, !incoming.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        guard let first = matchingScenes(for: incoming).first else { return [] }
        return zip(["Dịu dàng", "Tự nhiên", "Quan tâm"], first.replies)
            .map { ReplySuggestion(tone: $0.0, text: $0.1) }
    }
}
