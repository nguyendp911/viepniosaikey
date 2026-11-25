import Foundation

@main
struct VerifyVietnameseConversationRoles {
    static func main() {
        KeyboardSettings.coupleEnabled = false
        KeyboardSettings.recipientMode = ReplyRecipient.automatic.rawValue

        func check(_ message: String, expected: ReplyRecipient) {
            let actual = ConversationContextResolver.resolve(message)
            guard actual.recipient == expected else {
                fatalError("Wrong recipient for '\(message)': got \(actual.recipient.title), expected \(expected.title)")
            }
            print("PASS [\(expected.title)] \(message)")
        }

        check("Chưa, chú đi cv lát về kiếm mồi tối nhậu", expected: .uncle)
        check("Chú về nhà chưa?", expected: .uncle)
        check("Dạ chú ơi, chú có ở nhà không?", expected: .uncle)
        check("Cô đi công tác à?", expected: .aunt)
        check("Có đi chơi không?", expected: .automatic)
        check("Chú ấy bận công việc", expected: .automatic)
        check("Chú ý đường trơn", expected: .automatic)
        check("Bà về chưa?", expected: .grandmother)
        check("Ba về chưa?", expected: .father)
        check("Hôm nay vui không?", expected: .automatic)

        KeyboardSettings.coupleEnabled = true
        let uncle = ConversationContextResolver.resolve("Chưa, chú đi cv lát về kiếm mồi tối nhậu")
        guard !uncle.romanticInstructionsAllowed else {
            fatalError("Couple mode incorrectly overrode uncle relationship")
        }
        let offline = OfflineReplyEngine.suggest(for: "Chưa, chú đi cv lát về kiếm mồi tối nhậu")
        guard offline.count == 3,
              offline.allSatisfy({ $0.text.lowercased().contains("chú") }),
              offline.allSatisfy({ uncle.accepts($0.text) }) else {
            fatalError("Offline suggestions did not retain chú/cháu politeness")
        }
        print("PASS [Couple override] Family messages are not romanticized")

        KeyboardSettings.recipientMode = ReplyRecipient.uncle.rawValue
        check("Ừ, lát chú nhắn", expected: .uncle)
        check("Tí nữa về", expected: .uncle)
        KeyboardSettings.recipientMode = ReplyRecipient.friend.rawValue
        check("Tí nữa về", expected: .friend)
        KeyboardSettings.recipientMode = ReplyRecipient.automatic.rawValue
        check("Tí nữa về", expected: .automatic)
        precondition(CoupleStyleCatalog.styles.count==32)
        precondition(Set(CoupleStyleCatalog.styles.map(\.id)).count==32)
        precondition(CoupleLocalEngine.reading("Em bận hôm nay").topic=="Bận")
        precondition(CoupleLocalEngine.reading("Bạn rủ đi chơi").topic=="Hẹn gặp")
        precondition(CoupleLocalEngine.reading("Đối phương: em bận\nTôi: ừ\nĐối phương: em mệt").topic=="Mệt mỏi")
        precondition(CoupleLocalEngine.reading("Em cần không gian").topic=="Ranh giới")
        precondition(CoupleLocalEngine.reading("Đối phương: em bận\nTôi: hiểu rồi\nĐối phương: ừ").topic=="Tiếp nối · Bận")
        precondition(CoupleLocalEngine.reading("Bạn rủ em ngủ lại qua đêm").topic=="Lời mời ở lại")
        let local=CoupleLocalEngine.suggest("Em bận",style:"cold",address:"em/anh",preferences:CoupleStudioPreferences())
        precondition(local.count==3 && local[2].text.contains("Anh"))
        precondition(CoupleLocalEngine.guardian("Nếu yêu anh thì phải trả lời").count>0)
        print("PASS Couple Studio local scene, address, styles and guardian")
        KeyboardSettings.coupleEnabled = false

        guard !uncle.accepts("Anh nhớ em, em về sớm nhé"),
              uncle.accepts("Dạ, chú cứ thong thả nhé ạ.") else {
            fatalError("Wrong family-reply quality filter")
        }
        print("PASS [Guard] Romantic pronoun mixups are rejected for elders")
    }
}
