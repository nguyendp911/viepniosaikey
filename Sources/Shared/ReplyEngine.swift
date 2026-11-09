import Foundation

struct ReplySuggestion: Codable, Identifiable {
    var id = UUID()
    var tone: String
    var text: String
}

enum OfflineReplyEngine {
    static func suggest(for source: String) -> [ReplySuggestion] {
        let message = source.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return [] }
        let context = ConversationContextResolver.resolve(message)
        if let family = ConversationContextResolver.offlineFamilyReplies(for: message, context: context) {
            return family
        }
        if CoupleReplyGuide.isEnabled && context.romanticInstructionsAllowed {
            return CoupleReplyGuide.offlineSuggestions(for: message)
        }
        let lower = message.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "vi_VN"))
        let answers: [String]
        if lower.contains("bao gia") || lower.contains("gia bao nhieu") {
            answers = [
                "Dạ cảm ơn bạn. Mình sẽ kiểm tra và gửi báo giá chi tiết sớm nhé.",
                "Mình gửi thông tin giá cho bạn ngay khi xác nhận xong.",
                "Cảm ơn anh/chị đã quan tâm. Tôi sẽ gửi báo giá và thông tin liên quan trong thời gian sớm nhất."
            ]
        } else if lower.contains("cam on") || lower.contains("thank") {
            answers = [
                "Dạ không có gì ạ, rất vui được hỗ trợ bạn!",
                "Không có gì nhé!",
                "Cảm ơn bạn, mong tiếp tục được đồng hành cùng bạn."
            ]
        } else if lower.contains("hen") || lower.contains("may gio") || lower.contains("khi nao") {
            answers = [
                "Dạ để mình kiểm tra lịch rồi xác nhận lại với bạn nhé.",
                "Mình kiểm tra rồi báo bạn ngay nha.",
                "Cảm ơn bạn. Tôi sẽ xác nhận thời gian cụ thể sau khi kiểm tra lịch."
            ]
        } else {
            answers = [
                "Dạ mình đã nhận được thông tin, mình sẽ phản hồi sớm nhé.",
                "Mình nhận được rồi nhé!",
                "Cảm ơn bạn đã chia sẻ. Tôi đã ghi nhận thông tin và sẽ phản hồi sau khi kiểm tra."
            ]
        }
        return zip(["Lịch sự", "Ngắn gọn", "Chuyên nghiệp"], answers).map { ReplySuggestion(tone: $0.0, text: $0.1) }
    }
}
