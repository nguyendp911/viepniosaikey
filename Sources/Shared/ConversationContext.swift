import Foundation

/// The recipient is the person the user is replying TO, not the speaker
/// of the pasted message. This distinction is vital for Vietnamese pronouns.
enum ReplyRecipient: String, CaseIterable, Identifiable {
    case automatic = "auto"
    case uncle = "uncle"
    case aunt = "aunt"
    case elderUncle = "elderUncle"
    case elderAunt = "elderAunt"
    case grandfather = "grandfather"
    case grandmother = "grandmother"
    case father = "father"
    case mother = "mother"
    case olderBrother = "olderBrother"
    case olderSister = "olderSister"
    case younger = "younger"
    case teacher = "teacher"
    case friend = "friend"
    case coworker = "coworker"
    case customer = "customer"
    case partner = "partner"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .automatic: return "Tự nhận diện"
        case .uncle: return "Chú"
        case .aunt: return "Cô"
        case .elderUncle: return "Bác trai"
        case .elderAunt: return "Bác gái"
        case .grandfather: return "Ông"
        case .grandmother: return "Bà"
        case .father: return "Bố/Ba"
        case .mother: return "Mẹ"
        case .olderBrother: return "Anh"
        case .olderSister: return "Chị"
        case .younger: return "Em"
        case .teacher: return "Thầy/Cô giáo"
        case .friend: return "Bạn bè"
        case .coworker: return "Đồng nghiệp"
        case .customer: return "Khách hàng"
        case .partner: return "Người yêu"
        }
    }

    var addressInstruction: String {
        switch self {
        case .automatic:
            return "Relationship unknown: don't assume romance, gender or age. Avoid imposing anh/em. Prefer a respectful, neutral reply."
        case .uncle:
            return "Recipient is user's CHÚ (uncle / older family acquaintance). Address him as 'chú', user as 'cháu'. Use natural, respectful Vietnamese (e.g. 'Dạ chú...'). NEVER call recipient 'anh' or user 'em'."
        case .aunt:
            return "Recipient is user's CÔ (aunt / older woman). Address her as 'cô', user as 'cháu'. Don't use a romantic anh/em exchange."
        case .elderUncle:
            return "Recipient is user's BÁC (older male relative). Use 'bác' and 'cháu', politely and naturally."
        case .elderAunt:
            return "Recipient is user's BÁC (older female relative). Use 'bác' and 'cháu', politely and naturally."
        case .grandfather:
            return "Recipient is 'ông'. Address 'ông' and refer to self as 'cháu' or 'con' according to context; don't invent intimacy."
        case .grandmother:
            return "Recipient is 'bà'. Address 'bà' and self as 'cháu' or 'con' according to context."
        case .father:
            return "Recipient is user's father. Use 'bố/ba' and 'con', adapting to the original person's vocabulary."
        case .mother:
            return "Recipient is user's mother. Use 'mẹ' and 'con', warmly and respectfully."
        case .olderBrother:
            return "Recipient is an older male / older brother. Use 'anh' for recipient and 'em' for user; this is a familial or respectful form, NOT automatically romantic."
        case .olderSister:
            return "Recipient is an older female / older sister. Use 'chị' for recipient and 'em' for user; NOT romantic."
        case .younger:
            return "Recipient is younger than user. Address recipient as 'em', user as 'anh/chị' ONLY if user's self-address was given; otherwise prefer neutral wording."
        case .teacher:
            return "Recipient is a teacher. Address 'thầy/cô' and self as 'em' (or 'con' if explicitly shown); stay respectful."
        case .friend:
            return "Recipient is a friend. Prefer 'mình/bạn' or forms present in the message. Don't turn the exchange romantic."
        case .coworker:
            return "Recipient is a colleague. Use polite, natural professional pronouns; if roles are unknown, prefer neutral 'mình/bạn'."
        case .customer:
            return "Recipient is a customer. Use professional, respectful Vietnamese; do not imply romantic or close personal relationship."
        case .partner:
            return "Recipient is user's romantic partner. Adapt anh/em or chosen relationship preferences only when the pasted message supports them; don't assume gender."
        }
    }

    var nonRomantic: Bool {
        switch self {
        case .automatic, .partner: return false
        default: return true
        }
    }
}

struct ResolvedReplyContext {
    let recipient: ReplyRecipient
    let isExplicit: Bool
    let evidence: String

    var displayName: String {
        recipient.title + (isExplicit ? " (đã chọn)" : (recipient == .automatic ? "" : " (nhận diện)"))
    }

    var romanticInstructionsAllowed: Bool {
        recipient == .partner || recipient == .automatic
    }

    var instruction: String {
        """
        FIRST UNDERSTAND THE CONVERSATION BEFORE WRITING REPLIES:
        - The pasted message is FROM the other person. Replies are written BY the user TO that person.
        - Recipient: \(recipient.title). \(isExplicit ? "User explicitly selected this; it OVERRIDES all guesses." : "Detected from incoming wording, or unknown when unclear.")
        - \(recipient.addressInstruction)
        - Determine who is talking, intent, relationship and emotional tone before composing.
        - Words like 'chú đi...' can be the sender calling THEMSELVES 'chú'; user must answer as 'cháu' to 'chú'.
        - Mentioning a third person ('chú ấy', 'cô đó') does NOT mean the recipient is that person.
        - If relationship is unknown, do not invent one. Do not force 'anh/em' or affectionate terms.
        - Preserve appropriate form of address in ALL three replies; no romance when recipient is family, teacher, coworker or customer.
        - Only reply to the latest actual message. No explanation or repetition of incoming text.
        - Do not invent facts, actions or promises the user has not provided.
        - Responses should be ready to send, brief, and fit the sender's actual intent.
        FAMILY EXAMPLE:
        Recipient: CHÚ. Incoming: "Chưa, chú đi cv lát về kiếm mồi tối nhậu".
        Valid reply: "Dạ, chú xong việc rồi về nghỉ ngơi nha chú."
        Invalid reply: "Anh về nhớ nhắn em nhé" (wrong roles).
        """
    }

    /// Reject obviously wrong speaker/recipient pronouns rather than silently
    /// presenting a family reply as a romantic exchange.
    func accepts(_ text: String) -> Bool {
        guard [.uncle, .aunt, .elderUncle, .elderAunt,
               .grandfather, .grandmother, .father, .mother].contains(recipient)
        else { return true }
        let normalized = ConversationContextResolver.normalize(text)
        // These are the common erroneous patterns in generated romantic replies.
        let badStarts = [
            #"^\s*(anh|em)\s+(nho|thuong|yeu|doi|se|muon|ve|di|cam|hieu)\b"#,
            #"\b(anh\s+yeu\s+em|em\s+yeu\s+anh|anh\s+nho\s+em|em\s+nho\s+anh)\b"#
        ]
        return !badStarts.contains { normalized.range(of: $0, options: .regularExpression) != nil }
    }
}

enum ConversationContextResolver {
    static func normalize(_ value: String) -> String {
        value.folding(options: [.diacriticInsensitive, .caseInsensitive],
                      locale: Locale(identifier: "vi_VN")).lowercased()
    }

    static func resolve(_ incoming: String) -> ResolvedReplyContext {
        let chosen = ReplyRecipient(rawValue: KeyboardSettings.recipientMode) ?? .automatic
        if chosen != .automatic {
            return ResolvedReplyContext(recipient: chosen, isExplicit: true, evidence: "Lựa chọn của người dùng")
        }
        let value = normalize(incoming)
        let words = Set(incoming.lowercased().split(whereSeparator: { !$0.isLetter }).map(String.init))
        // Keep accents for disambiguating "cô" from "có", "bà" from "ba".
        // Guard common mentions of THIRD PARTIES and non-address phrases.
        let thirdParty = has(#"\b(chu|co|bac|ong|ba)\s+(ay|do|kia|nay|re|y|thich)\b"#, in: value)
        if !thirdParty {
            let patterns: [(ReplyRecipient, String)] = [
                (.uncle, #"\bchu\s+(oi|a|ah|di|ve|dang|moi|bao|noi|se|vua|con|co|chua|lam|duoc|nho|dinh|mai|hom|khong)\b"#),
                (.aunt, #"\bco\s+(oi|a|ah|di|ve|dang|moi|bao|noi|se|vua|con|co|chua|lam|duoc|nho|dinh|mai|hom|khong)\b"#),
                (.elderUncle, #"\bbac\s+(oi|a|ah|di|ve|dang|moi|bao|noi|se|vua|con|chua|lam|duoc|nho|mai|hom|khong)\b"#),
                (.grandfather, #"\bong\s+(oi|a|ve|di|dang|moi|bao|noi|se|vua|con|chua|lam|nho)\b"#),
                (.grandmother, #"\bba\s+(oi|a|ve|di|dang|moi|bao|noi|se|vua|con|chua|lam|nho)\b"#),
                (.father, #"\b(bo|ba|cha)\s+(oi|a|ve|di|dang|bao|noi|se|vua|chua|lam|nho)\b"#),
                (.mother, #"\bme\s+(oi|a|ve|di|dang|bao|noi|se|vua|chua|lam|nho)\b"#),
                (.teacher, #"\b(thay|co)\s+(giao|oi|a)\b"#)
            ]
            for (recipient, pattern) in patterns where has(pattern, in: value) {
                if recipient == .aunt && !words.contains("cô") { continue }
                if recipient == .grandmother && !words.contains("bà") { continue }
                if recipient == .father &&
                    !words.contains("bố") && !words.contains("ba") && !words.contains("cha") { continue }
                if recipient == .mother && !words.contains("mẹ") { continue }
                if recipient == .teacher &&
                    !words.contains("thầy") &&
                    !(words.contains("cô") && words.contains("giáo")) { continue }
                return ResolvedReplyContext(recipient: recipient, isExplicit: false, evidence: "Từ xưng hô trong tin nhắn")
            }
        }
        return ResolvedReplyContext(recipient: .automatic, isExplicit: false, evidence: "Chưa đủ căn cứ")
    }

    private static func has(_ regex: String, in text: String) -> Bool {
        text.range(of: regex, options: .regularExpression) != nil
    }

    static func offlineFamilyReplies(for text: String, context: ResolvedReplyContext) -> [ReplySuggestion]? {
        guard [.uncle, .aunt, .elderUncle, .elderAunt,
               .grandfather, .grandmother, .father, .mother].contains(context.recipient) else { return nil }
        let address = context.recipient.title.lowercased()
        let selfName: String = [.father, .mother].contains(context.recipient) ? "con" : "cháu"
        let lower = normalize(text)
        let messages: [String]
        if lower.contains("di") || lower.contains("ve") || lower.contains("nhau") || lower.contains("cong viec") {
            messages = [
                "Dạ, \(address) xong việc rồi về nghỉ ngơi nhé ạ.",
                "Dạ, \(selfName) hiểu rồi ạ. \(address.capitalized) nhớ đi đường cẩn thận nhé.",
                "Vâng ạ, \(address) cứ lo công việc trước, khi nào tiện mình nói chuyện sau ạ."
            ]
        } else {
            messages = [
                "Dạ, \(selfName) hiểu rồi ạ. \(address.capitalized) cứ thong thả nhé.",
                "Vâng ạ, \(address) cần gì cứ nhắn \(selfName) nhé.",
                "Dạ, cảm ơn \(address) đã nhắn ạ."
            ]
        }
        return zip(["Lịch sự", "Quan tâm", "Ngắn gọn"], messages)
            .map { ReplySuggestion(tone: $0.0, text: $0.1) }
    }
}
