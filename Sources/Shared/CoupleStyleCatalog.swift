import Foundation

/// Curated opt-in reply styles for Vietnamese relationship chat.
/// This is prompt conditioning, not a fine-tuned Gemini/OpenAI model.
struct CoupleStyle: Identifiable {
    let id: String
    let title: String
    let icon: String
    let summary: String
    let guidance: String
    let variantNames: [String]
}

enum CoupleStyleCatalog {
    static let styles: [CoupleStyle] = [
        .init(id: "auto", title: "Tự động", icon: "✦", summary: "AI chọn theo tình huống",
              guidance: "Match the message's actual mood. Offer three balanced, distinct approaches; don't force romance into conflict or serious discussions.",
              variantNames: ["Dịu dàng", "Tự nhiên", "Tinh tế"]),
        .init(id: "sweet", title: "Ngọt ngào", icon: "💗", summary: "Ấm áp, dễ thương",
              guidance: "Be sweet and affectionate, but not clingy or exaggerated. One natural emoji at most.",
              variantNames: ["Ngọt ngào", "Nhẹ nhàng", "Dễ thương"]),
        .init(id: "romantic", title: "Lãng mạn", icon: "🌹", summary: "Chân thành, có cảm xúc",
              guidance: "Express romance with vivid, grounded Vietnamese language. Do not invent memories or promises.",
              variantNames: ["Lãng mạn", "Sâu lắng", "Ấm áp"]),
        .init(id: "flirty", title: "Thả thính nhẹ", icon: "✨", summary: "Tinh tế, không sến",
              guidance: "Playful respectful flirting with light banter, not sexual pressure or explicit content.",
              variantNames: ["Thả thính", "Duyên dáng", "Tự nhiên"]),
        .init(id: "playful", title: "Tinh nghịch", icon: "😜", summary: "Trêu yêu vừa đủ",
              guidance: "Cheeky gentle teasing. Never belittle the other person, provoke jealousy, or dismiss worries.",
              variantNames: ["Tinh nghịch", "Hóm hỉnh", "Dễ thương"]),
        .init(id: "funny", title: "Hài hước", icon: "😄", summary: "Vui tươi, dí dỏm",
              guidance: "Use everyday Vietnamese humor and warmth. Avoid jokes when the person is hurt or distressed.",
              variantNames: ["Hài hước", "Hóm hỉnh", "Vui vẻ"]),
        .init(id: "gentle", title: "Dịu dàng", icon: "🤍", summary: "Nhẹ nhàng, không gây áp lực",
              guidance: "Be calm, comforting, and emotionally considerate; avoid excessive reassurance or assumptions.",
              variantNames: ["Dịu dàng", "Lắng nghe", "Bình yên"]),
        .init(id: "caring", title: "Quan tâm", icon: "🌷", summary: "Hỏi han tinh tế",
              guidance: "Show care by listening, asking a relevant gentle question, and offering practical kindness.",
              variantNames: ["Quan tâm", "Thấu hiểu", "Đồng hành"]),
        .init(id: "deep", title: "Sâu sắc", icon: "🌙", summary: "Ít lời, nhiều ý nghĩa",
              guidance: "Write sincere, thoughtful, non-cliche replies, grounded in the incoming message.",
              variantNames: ["Sâu sắc", "Chân thành", "Tinh tế"]),
        .init(id: "mature", title: "Trưởng thành", icon: "🪴", summary: "Bình tĩnh, rõ ràng",
              guidance: "Communicate with emotional maturity, accountability, clarity, and respect.",
              variantNames: ["Trưởng thành", "Thẳng thắn", "Tôn trọng"]),
        .init(id: "honest", title: "Thẳng thắn", icon: "🗣️", summary: "Rõ ý nhưng không phũ",
              guidance: "Say what is meant plainly, without mixed signals or harsh judgments.",
              variantNames: ["Thẳng thắn", "Chân thật", "Nhẹ nhàng"]),
        .init(id: "apology", title: "Xin lỗi", icon: "🫶", summary: "Nhận lỗi, không đổ thừa",
              guidance: "If the user needs to apologize, take responsibility without inventing fault or demanding forgiveness.",
              variantNames: ["Chân thành", "Nhận lỗi", "Làm lành"]),
        .init(id: "reconcile", title: "Làm hòa", icon: "🕊️", summary: "Hạ nhiệt, xây dựng",
              guidance: "De-escalate conflict, acknowledge feelings, ask to talk when comfortable; no blame or manipulation.",
              variantNames: ["Làm hòa", "Lắng nghe", "Cùng giải quyết"]),
        .init(id: "encourage", title: "Động viên", icon: "🌟", summary: "Tiếp sức, đồng hành",
              guidance: "Validate effort without dismissing difficulty or offering unfounded reassurance.",
              variantNames: ["Động viên", "Tin tưởng", "Quan tâm"]),
        .init(id: "longdistance", title: "Yêu xa", icon: "🌍", summary: "Kết nối khi cách xa",
              guidance: "Acknowledge distance and suggest realistic contact without guilt, monitoring, or fake promises.",
              variantNames: ["Nhớ thương", "Kết nối", "Ấm áp"]),
        .init(id: "minimal", title: "Ngắn gọn", icon: "💬", summary: "Một câu dễ gửi",
              guidance: "Provide very short 1-2 sentence replies in natural spoken Vietnamese; no elaborate poetry.",
              variantNames: ["Ngắn gọn", "Tinh tế", "Tự nhiên"]),
        .init(id: "poetic", title: "Thơ mộng", icon: "🪻", summary: "Hình ảnh nhẹ, có chất thơ",
              guidance: "Use subtle poetic imagery in contemporary Vietnamese without archaic or overblown declarations.",
              variantNames: ["Thơ mộng", "Lãng mạn", "Sâu lắng"]),
        .init(id: "boundaries", title: "Ranh giới", icon: "🛡️", summary: "Tôn trọng và an toàn",
              guidance: "Communicate personal boundaries and consent politely and clearly; never imply agreement to pressure.",
              variantNames: ["Ranh giới", "Tôn trọng", "Rõ ràng"])
    ]

    static func selected(_ id: String) -> CoupleStyle {
        styles.first { $0.id == id } ?? styles[0]
    }

    static var active: CoupleStyle { selected(KeyboardSettings.coupleStyle) }
}
