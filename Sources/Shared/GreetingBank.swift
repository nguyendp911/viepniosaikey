import Foundation

/// Time-of-day greetings for a partner, rotated so the same line is not
/// offered twice in a row. Pure text: nothing is sent anywhere.
enum GreetingBank {
    enum Slot: String, CaseIterable {
        case morning, noon, afternoon, evening, night
    }

    static func slot(for date: Date, calendar: Calendar = .current) -> Slot {
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case 5..<10: return .morning
        case 10..<13: return .noon
        case 13..<18: return .afternoon
        case 18..<22: return .evening
        default: return .night
        }
    }

    static func title(for slot: Slot) -> String {
        switch slot {
        case .morning: return "Chào buổi sáng"
        case .noon: return "Nhắc ăn trưa"
        case .afternoon: return "Hỏi thăm buổi chiều"
        case .evening: return "Chào buổi tối"
        case .night: return "Chúc ngủ ngon"
        }
    }

    /// "anh/em" -> (me: "anh", you: "em"). The first word is how the user
    /// refers to themselves, the second how they address their partner.
    static func pronouns(from address: String) -> (me: String, you: String) {
        let parts = address.split(separator: "/").map { String($0) }
        if parts.count == 2, !parts[0].isEmpty, !parts[1].isEmpty {
            return (me: parts[0], you: parts[1])
        }
        return (me: "anh", you: "em")
    }

    /// `{me}` and `{you}` are filled from the chosen forms of address.
    static let templates: [Slot: [String]] = [
        .morning: [
            "Chào buổi sáng {you} ☀️ Hôm nay {you} có kế hoạch gì vui không?",
            "Buổi sáng tốt lành nhé {you} 🌼 Nhớ ăn sáng đầy đủ nha.",
            "Dậy chưa {you} ơi? Chúc {you} một ngày thật nhiều năng lượng ✨",
            "Sáng nay trời đẹp ghê, chúc {you} một ngày nhẹ nhàng và suôn sẻ 🌤️",
            "Chào ngày mới {you} nhé, có gì cần {me} giúp cứ nói {me} nha 💛",
            "Một ngày mới rồi, chúc {you} làm gì cũng thuận lợi nhé 🍀",
            "Dậy sớm thế {you}? Nhớ uống nước và ăn sáng nha ☕",
            "Chúc {you} buổi sáng bình yên, {me} luôn ở đây nếu {you} cần 🤍"
        ],
        .noon: [
            "Trưa rồi, {you} nhớ ăn cơm đầy đủ nha 🍚",
            "Giờ nghỉ trưa rồi đó {you}, ăn gì chưa kể {me} nghe với 😋",
            "Đừng bỏ bữa trưa nhé {you}, {me} lo lắm đó 🥢",
            "Nghỉ ngơi một chút cho đỡ mệt nha {you}, chiều còn nhiều việc 🌿",
            "Trưa nay {you} ăn món gì thế? Nhớ ăn no để có sức nha 🍜",
            "Ăn trưa ngon miệng nhé {you} 💛 Nhớ nghỉ ngơi một lát.",
            "Cố lên {you}, qua buổi trưa là hết nửa ngày rồi nè 🌞",
            "Nhớ uống đủ nước và ăn trưa đúng giờ nha {you} 💧"
        ],
        .afternoon: [
            "Chiều rồi, {you} làm việc có mệt không? Nhớ nghỉ tay một chút nha 🌤️",
            "Buổi chiều của {you} thế nào rồi? Kể {me} nghe với nhé 💬",
            "Cố lên {you}, sắp hết ngày rồi nè 💪",
            "Chiều nay {you} có dự định gì không? Tối mình nói chuyện nhé 🌇",
            "Nghỉ ngơi một chút, uống nước rồi làm tiếp nha {you} 💧",
            "Nhắn hỏi thăm {you} một chút, hôm nay của {you} ổn chứ? 🤍",
            "Trời chiều dễ mệt lắm, {you} nhớ giữ sức nhé ☕",
            "Chiều rồi, nhớ ăn nhẹ gì đó cho đỡ đói nha {you} 🍪"
        ],
        .evening: [
            "Tối rồi, {you} ăn tối chưa? Hôm nay của {you} thế nào? 🌙",
            "Một ngày vất vả rồi, tối nay {you} nghỉ ngơi thật thoải mái nhé 💛",
            "Hôm nay {you} đã làm tốt lắm rồi, giờ thư giãn một chút nha ✨",
            "Tối nay mình trò chuyện một lát được không {you}? 💬",
            "Ăn tối ngon miệng nha {you}, nhớ ăn đủ bữa 🍲",
            "Kể {me} nghe hôm nay của {you} có gì vui không nào 😊",
            "Tối rồi, {you} đừng thức khuya quá nhé 🌃",
            "Nghỉ ngơi cho thật thoải mái đi {you}, {me} luôn ở đây 🤍"
        ],
        .night: [
            "Khuya rồi, {you} ngủ sớm nhé. Chúc {you} ngủ thật ngon 🌙",
            "Chúc {you} ngủ ngon và mơ thật đẹp nha 💤",
            "Ngủ sớm đi {you}, mai còn nhiều việc nữa. Ngủ ngon nhé 🤍",
            "Đừng thức khuya quá nha {you}, giữ sức khỏe nhé. Ngủ ngon 🌛",
            "Một ngày dài rồi, nghỉ ngơi thôi {you}. Chúc {you} đêm bình yên ✨",
            "Ngủ ngon nha {you}, mai {me} lại nhắn {you} sớm 💛",
            "Đi ngủ thôi {you} ơi, chúc {you} một giấc ngủ thật sâu 😴",
            "Tạm biệt một ngày nhé, ngủ ngon {you} 🌙"
        ]
    ]

    static func filled(_ template: String, address: String) -> String {
        let forms = pronouns(from: address)
        return template.replacingOccurrences(of: "{me}", with: forms.me)
            .replacingOccurrences(of: "{you}", with: forms.you)
    }

    /// The line after `lastIndex` for this part of the day (round robin).
    static func pick(slot: Slot, address: String, lastIndex: Int?)
        -> (text: String, index: Int) {
        let list = templates[slot] ?? []
        guard !list.isEmpty else { return (text: "", index: 0) }
        let previous = lastIndex ?? -1
        let index = (previous + 1 + list.count) % list.count
        return (text: filled(list[index], address: address), index: index)
    }
}
