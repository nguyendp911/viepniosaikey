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
        precondition(!CoupleLocalEngine.hasPhrase("bạn","bận"))
        precondition(CoupleLocalEngine.hasPhrase("em ban","bận"))
        precondition(!CoupleLocalEngine.hasPhrase("yếu","yêu"))
        precondition(CoupleLocalEngine.reading("Đối phương: em bận\nTôi: ừ\nĐối phương: em mệt").topic=="Mệt mỏi")
        precondition(CoupleLocalEngine.reading("Em cần không gian").topic=="Ranh giới")
        precondition(CoupleLocalEngine.reading("Đối phương: em bận\nTôi: hiểu rồi\nĐối phương: ừ").topic=="Tiếp nối · Bận")
        precondition(CoupleLocalEngine.reading("Bạn rủ em ngủ lại qua đêm").topic=="Lời mời ở lại")
        let local=CoupleLocalEngine.suggest("Em bận",style:"cold",address:"em/anh",preferences:CoupleStudioPreferences())
        precondition(local.count==3 && local[2].text.contains("Anh"))
        precondition(CoupleLocalEngine.guardian("Nếu yêu anh thì phải trả lời").count>0)
        let transcript="Đối phương: Em bận\nTôi: Anh hiểu"
        precondition(CoupleTranscript.target(transcript)==nil)
        precondition(CoupleTranscript.excerpt(transcript,selected:0)=="Đối phương: Em bận")
        precondition(CoupleTranscript.excerpt("Em bận")=="Đối phương: Em bận")
        precondition(CoupleTranscript.target("Chưa rõ: Ừ")==nil)
        precondition(CoupleTranscript.excerpt("Tôi: Anh hiểu\nĐối phương: Em mệt\nTôi: Ừ",selected:1)=="Tôi: Anh hiểu\nĐối phương: Em mệt")
        let multiline="Đối phương: Em bận\nmai nói tiếp nhé"
        precondition(CoupleTranscript.target(multiline)?.text=="Em bận\nmai nói tiếp nhé")
        let first=CoupleLocalEngine.replyPool("Em bận",style:"natural",address:"anh/em",preferences:.init(),goal:.natural)
        let second=CoupleLocalEngine.replyPool("Em bận",style:"natural",address:"anh/em",preferences:.init(),goal:.natural,round:1)
        precondition(first.count==3 && second.count==3 && Set(first.map(\.text)).isDisjoint(with:Set(second.map(\.text))))
        let refuse=CoupleLocalEngine.replyPool("Cuối tuần đi chơi không?",style:"natural",address:"anh/em",preferences:.init(),goal:.decline)
        precondition(refuse.count==3 && refuse[0].text.contains("không"))
        let boundary=CoupleLocalEngine.replyPool("Em không muốn",style:"sweet",address:"anh/em",preferences:.init(),goal:.agree)
        precondition(boundary.count==3 && boundary[0].text.contains("tôn trọng"))
        var signature=CoupleSignature()
        for _ in 0..<3{signature.observe("Ngủ ngon nha")}
        precondition(signature.samples==3 && signature.preferredEnding=="nha")
        precondition(signature.personalize("Ngủ ngon nhé.")=="Ngủ ngon nha.")
        precondition(signature.preferredWords.contains("ngủ ngon"))
        precondition(signature.applying(to:.init()).length=="short")
        var layered=CoupleStudioPreferences();layered.customEmotion=true;layered.cold=80;layered.warmth=80;layered.hurt=70
        let layers=CoupleSignatureTools.layered("Em bận",address:"anh/em",preferences:layered)
        precondition(layers.count==3 && layers[0].text.contains("chạnh lòng") && layers[0].text.contains("nghỉ ngơi"))
        precondition(CoupleSignatureTools.compare("Anh xin lỗi nhé.").first?.detail.contains("xin lỗi")==true)
        precondition(CoupleSignatureTools.humanize("Anh muốn bày tỏ rằng anh nhớ em.")=="Anh muốn nói rằng anh nhớ em.")
        precondition(CoupleSignatureTools.spectrum("Em bận",address:"anh/em").count==6)
        precondition(CoupleSignatureTools.spectrum("Em cần không gian",address:"anh/em").count==3)
        precondition(CoupleSignatureTools.write(.story,facts:"",address:"anh/em").isEmpty)
        precondition(CoupleSignatureTools.write(.story,facts:"Gặp ở Đà Lạt",address:"anh/em").allSatisfy{$0.text.contains("Gặp ở Đà Lạt")})
        precondition(CoupleSignatureTools.review("Nếu yêu anh thì phải trả lời!!!").count>=2)
        precondition(CoupleSignatureTools.betweenLines("Tùy anh").count==4)
        precondition(CoupleSignatureTools.forecast("Anh cần không gian").count==3)
        print("PASS Couple Signature: approved aggregate style, layered tone, spectrum, review and factual writing")
        print("PASS Couple Studio local scene, address, styles, transcript selection, reply goals and guardian")
        KeyboardSettings.coupleEnabled = false

        guard !uncle.accepts("Anh nhớ em, em về sớm nhé"),
              uncle.accepts("Dạ, chú cứ thong thả nhé ạ.") else {
            fatalError("Wrong family-reply quality filter")
        }
        print("PASS [Guard] Romantic pronoun mixups are rejected for elders")
    }
}
