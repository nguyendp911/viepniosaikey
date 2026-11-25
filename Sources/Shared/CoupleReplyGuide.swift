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
        let matched = scenes.filter { scene in scene.keywords.contains { CoupleLocalEngine.hasPhrase(input, $0) } }
        return Array(matched.prefix(2))
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
        \(CoupleStudioPreferences.current.prompt)
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
        return CoupleLocalEngine.suggest(incoming,style:KeyboardSettings.coupleStyle,address:KeyboardSettings.coupleAddress,preferences:CoupleStudioPreferences.current)
    }
}


/// Separate store; no automatic import of chats or changes to legacy settings.
struct CoupleStudioPreferences: Codable, Equatable {
    var customEmotion=false
    var cold=35
    var hurt=20
    var warmth=55
    var length="medium"
    var emoji=false
    var nickname=""
    var learnFromSaved=false
    static var current:Self {
        get {
            guard let data=KeyboardSettings.defaults.data(forKey:"viepnaikey.couple.studio"),
                  var value=try? JSONDecoder().decode(Self.self,from:data) else{return .init()}
            value.cold=min(100,max(0,value.cold));value.hurt=min(100,max(0,value.hurt));value.warmth=min(100,max(0,value.warmth))
            if !["short","medium","long"].contains(value.length){value.length="medium"}
            return value
        }
        set{if let data=try? JSONEncoder().encode(newValue){KeyboardSettings.defaults.set(data,forKey:"viepnaikey.couple.studio")}}
    }
    var prompt:String {
        guard customEmotion else{return ""}
        return "User explicitly selected emotional tone: reserve \(cold)/100, hurt \(hurt)/100, warmth \(warmth)/100, length \(length), emoji \(emoji ? "allowed":"none"). These are writing preferences, not facts about their emotions. Respect boundaries and incoming context."
    }
}
enum CoupleLocalEngine {
    struct Reading:Equatable {let topic:String;let evidence:String;let caution:String}
    static func normalize(_ text:String)->String {
        text.lowercased().folding(options:[.diacriticInsensitive],locale:Locale(identifier:"vi_VN")).replacingOccurrences(of:"đ",with:"d")
            .components(separatedBy:CharacterSet.letters.inverted).filter{!$0.isEmpty}.joined(separator:" ")
    }
    static func hasPhrase(_ text:String,_ phrase:String)->Bool {
        func tokens(_ value:String)->[String] {
            value.lowercased().precomposedStringWithCanonicalMapping.components(separatedBy:CharacterSet.letters.inverted).filter{!$0.isEmpty}
        }
        let source=tokens(text),pattern=tokens(phrase)
        guard !pattern.isEmpty,source.count>=pattern.count else{return false}
        for start in 0...(source.count-pattern.count) {
            let matched=zip(source[start..<(start+pattern.count)],pattern).allSatisfy { actual, expected in
                if actual==expected{return true}
                // Accept missing marks, never confuse explicitly marked words
                // such as bạn/bận, nghỉ/nghĩ, or yêu/yếu.
                return (actual.unicodeScalars.allSatisfy{$0.value<128} || expected.unicodeScalars.allSatisfy{$0.value<128}) && normalize(actual)==normalize(expected)
            }
            if matched{return true}
        }
        return false
    }
    // Last explicitly labeled incoming message is the target. Unlabeled text
    // uses the last nonempty line. Earlier context never overrides a clear target.
    static func incoming(_ conversation:String)->String {
        let lines=conversation.components(separatedBy:.newlines).map{$0.trimmingCharacters(in:.whitespacesAndNewlines)}.filter{!$0.isEmpty}
        if let line=lines.reversed().first(where:{let n=normalize($0);return $0.contains(":") && (n.hasPrefix("doi phuong ") || n.hasPrefix("nguoi ay ") || n.hasPrefix("ban ay "))}),let colon=line.firstIndex(of:":"){return String(line[line.index(after:colon)...]).trimmingCharacters(in:.whitespaces)}
        return lines.last ?? ""
    }
    static let topics:[(String,[String])]=[
        ("Ranh giới",["không muốn","đừng nhắn","chia tay","cần không gian","ép","dừng lại","không đồng ý"]),
        ("Lời mời ở lại",["ngủ lại","qua đêm","ở lại qua đêm","khách sạn"]),
        ("Xin lỗi",["xin lỗi","tha lỗi","lỗi của"]),
        ("Mâu thuẫn",["giận","cãi nhau","thất vọng","tổn thương","hiểu lầm"]),
        ("Mệt mỏi",["mệt","áp lực","stress","kiệt sức","khó khăn"]),
        ("Buồn",["buồn","khóc","cô đơn","tủi thân"]),
        ("Bận",["bận","không rảnh","hẹn sau","deadline"]),
        ("Nhớ thương",["nhớ anh","nhớ em","nhớ nhau","yêu xa","muốn gặp"]),
        ("Ăn uống",["ăn cơm","ăn gì","ăn chưa","đói"]),
        ("Ngủ nghỉ",["ngủ ngon","đi ngủ","buồn ngủ"]),
        ("Đi lại",["về nhà","tới nhà","đang đi","đến nơi"]),
        ("Tin vui",["chúc mừng","tin tốt","thi đỗ","thành công"]),
        ("Hẹn gặp",["đi chơi","cuối tuần","hẹn gặp","gặp nhau"]),
        ("Ghen tuông",["ghen","người yêu cũ","bạn nam","bạn nữ"]),
        ("Tình cảm",["yêu","thương","thích"]),
        ("Chào hỏi",["chào","hello","hi","buổi sáng"])
    ]
    static func reading(_ conversation:String)->Reading {
        let last=incoming(conversation)
        let match=topics.lazy.compactMap{topic,keys in keys.first(where:{hasPhrase(last,$0)}).map{(topic,$0)}}.first
        if let match{return Reading(topic:match.0,evidence:match.1,caution:"Từ khóa gợi ý sắc thái, không xác định chắc chắn cảm xúc hoặc ý định.")}
        // Only earlier explicitly labeled incoming turns provide a tentative
        // topic for an ambiguous acknowledgment. No claim about actual mood.
        if ["ừ","ừm","vâng","dạ","ok","được","thế à","vậy à"].contains(where:{normalize(last)==normalize($0)}) {
            let prior=conversation.components(separatedBy:.newlines).dropLast().suffix(8).reversed()
            for line in prior {
                let n=normalize(line)
                guard n.hasPrefix("doi phuong ") || n.hasPrefix("nguoi ay ") || n.hasPrefix("ban ay ") else{continue}
                if let earlier=topics.lazy.compactMap({topic,keys in keys.first(where:{hasPhrase(line,$0)}).map{(topic,$0)}}).first {
                    return Reading(topic:"Tiếp nối · "+earlier.0,evidence:"Ngữ cảnh trước: "+earlier.1,caution:"Tin cuối chỉ là phản hồi ngắn; chủ đề trước đó có thể vẫn liên quan. Không suy đoán cảm xúc.")
                }
            }
        }
        return Reading(topic:"Chưa rõ",evidence:"Không đủ dấu hiệu trực tiếp",caution:"Không suy diễn từ một tin nhắn ngắn. Có thể hỏi lại nhẹ nhàng.")
    }
    static func address(_ value:String)->(String,String) {
        switch value {case "em/anh":return ("em","anh");case "mình/cậu":return ("mình","cậu");case "tớ/cậu":return ("tớ","cậu");case "bạn/mình":return ("bạn","mình");default:return ("anh","em")}
    }
    static func render(_ template:String,address value:String)->String {
        let (me,you)=address(value)
        let text=template.replacingOccurrences(of:"{me}",with:me).replacingOccurrences(of:"{you}",with:you)
        return text.prefix(1).uppercased()+text.dropFirst()
    }
    static func suggest(_ conversation:String,style:String,address:String,preferences:CoupleStudioPreferences)->[ReplySuggestion] {
        let last=incoming(conversation);guard !last.isEmpty else{return []}
        let info=reading(conversation)
        let effective=preferences.customEmotion ? (preferences.cold>=65 ? "cold":preferences.hurt>=55 ? "hurt":preferences.warmth>=65 ? "sweet":style) : style
        var samples:[String]
        switch info.topic {
        case "Ranh giới":samples=["{me} hiểu. {me} tôn trọng điều {you} vừa nói.","Ừ, {me} sẽ để {you} có không gian riêng.","Cảm ơn {you} đã nói rõ. {me} sẽ không gây áp lực."]
        case "Lời mời ở lại":samples=["{you} thấy sao về lời mời đó? Điều quan trọng là {you} thoải mái và an toàn.","Nếu không muốn, {you} có thể từ chối rõ ràng nhé.","{you} muốn {me} lắng nghe hay cùng nghĩ cách trả lời?"]
        case "Xin lỗi":samples=["Cảm ơn {you} đã nói vậy. Mình cùng bình tĩnh nhé.","{me} trân trọng lời xin lỗi của {you}.","Mình nói tiếp khi cả hai thấy thoải mái nhé."]
        case "Mâu thuẫn":samples=["{me} muốn nghe điều làm {you} không vui.","Mình nói chuyện rõ hơn khi cả hai bình tĩnh nhé.","{me} không muốn đôi mình hiểu lầm thêm."]
        case "Mệt mỏi","Buồn":samples=["{you} cứ nghỉ ngơi nhé, khi nào muốn kể thì {me} nghe.","{you} muốn {me} lắng nghe hay giúp gì không?","Không cần cố vui đâu, cứ từ từ nhé."]
        case "Bận":samples=["Ừ, {you} cứ lo việc trước nhé.","Khi nào rảnh mình nói chuyện sau.","{me} hiểu. Chúc {you} làm việc suôn sẻ."]
        case "Nhớ thương":samples=["Nghe {you} nói vậy thấy ấm lòng quá.","Khi nào cả hai rảnh mình gặp nhau nhé.","{me} muốn nghe {you} kể hôm nay thế nào."]
        case "Ăn uống":samples=["Cảm ơn {you} hỏi thăm. {you} ăn gì rồi?","{you} cũng nhớ ăn đúng giờ nha.","Mình nói chuyện một chút về bữa hôm nay nhé?"]
        case "Ngủ nghỉ":samples=["Ngủ ngon nhé, mai mình nói chuyện tiếp.","{you} nghỉ sớm cho khỏe nha.","Chúc {you} có một giấc ngủ thật yên."]
        case "Đi lại":samples=["Cảm ơn {you} đã hỏi. {you} đi đường cẩn thận nhé.","Khi nào tiện mình cập nhật cho nhau nhé.","{you} cũng nhớ giữ an toàn nha."]
        case "Tin vui":samples=["Chúc mừng {you} nha! Kể {me} nghe thêm với.","Nghe tin vui thế này thật đáng mừng.","{you} muốn ăn mừng thế nào nè?"]
        case "Hẹn gặp":samples=["Mình cùng chọn thời gian cả hai thoải mái nhé.","{you} có địa điểm nào muốn đi không?","Mỗi người chọn một ý rồi mình quyết định nha."]
        case "Ghen tuông":samples=["Mình nói rõ điều khiến mỗi người băn khoăn nhé.","{me} muốn hiểu suy nghĩ của {you}, không muốn kiểm soát.","Điều quan trọng là hai đứa tôn trọng nhau."]
        case "Tình cảm":samples=["{me} trân trọng điều {you} vừa nói.","Mình nói thật lòng với nhau nha.","{you} muốn chia sẻ thêm với {me} không?"]
        case "Chào hỏi":samples=["Chào {you}, hôm nay thế nào?","{you} đang làm gì đó?","Hôm nay có chuyện gì vui không nè?"]
        default:samples=["{me} nghe đây, {you} nói thêm được không?","Ừ, {me} hiểu phần {you} vừa nói.","Mình nói rõ hơn một chút nhé?"]
        }
        // Serious boundaries and sensitive contexts take precedence over tone.
        let sensitive=["Ranh giới","Lời mời ở lại","Mâu thuẫn","Mệt mỏi","Buồn","Ghen tuông"].contains(info.topic)
        if !["Ranh giới","Lời mời ở lại"].contains(info.topic) {
            if ["cold","minimal","firm","honest","disappointed"].contains(effective) {
                samples = info.topic=="Bận" ? ["Ừ, khi nào rảnh thì nói chuyện.","{me} hiểu rồi.","{you} cứ lo việc trước."] : [samples[0],"Ừ, mình nói tiếp khi thuận tiện.","{me} muốn nghe rõ hơn trước khi trả lời."]
            } else if ["hurt","sulky","coldwarm","regret"].contains(effective) && ["Bận","Mâu thuẫn","Xin lỗi"].contains(info.topic) {
                samples=["{me} hơi chạnh lòng, nhưng vẫn muốn hiểu {you}.","{me} cần chút thời gian, khi nào thuận tiện mình nói nhé.","{me} muốn nói thật cảm xúc của mình, không phải trách {you}."]
            } else if ["sweet","romantic","caring","gentle","healing","maturelove","peace"].contains(effective) && ["Bận","Mệt mỏi","Buồn","Nhớ thương","Ngủ nghỉ"].contains(info.topic) {
                samples[0] += " {me} vẫn sẵn lòng lắng nghe."
            } else if !sensitive,["flirty","playful","funny"].contains(effective),["Chào hỏi","Nhớ thương","Hẹn gặp"].contains(info.topic) {
                samples[0] += " Kể {me} nghe thêm đi, {me} đang tò mò nè."
            } else if !sensitive,["deep","poetic","subtle","peace"].contains(effective) {
                samples[0] += " Mình cứ nói với nhau thật lòng, không cần vội."
            } else if ["apology","reconcile","mature"].contains(effective),info.topic=="Mâu thuẫn" {
                samples[0] = "Mình nói rõ chuyện vừa rồi nhé. {me} sẵn sàng nghe và xem lại phần của mình."
            } else if effective=="afterbreakup" {
                samples=["{me} tôn trọng lựa chọn của {you}.","Cảm ơn {you} đã nói rõ. Mình giữ ranh giới cho nhau nhé.","{me} mong cả hai có thời gian và không gian riêng."]
            }
        }
        let catalog=CoupleStyleCatalog.selected(effective)
        return samples.enumerated().map{index,sample in
            var text=render(sample,address:address)
            if preferences.customEmotion {
                if preferences.length=="short",let end=text.firstIndex(where:{".!?".contains($0)}){text=String(text[...end])}
                if preferences.length=="long",info.topic != "Ranh giới",text.count<125{text+=" "+render("Khi nào {you} thấy thoải mái, mình nói thêm nhé.",address:address)}
                if preferences.emoji && !sensitive && index==0{text+=" 🤍"}
            }
            let labels=sensitive ? ["Lắng nghe","Tôn trọng","Rõ ràng"] : catalog.variantNames
            return ReplySuggestion(tone:labels[index % labels.count],text:text)
        }
    }
    static func guardian(_ text:String)->[String] {
        var result:[String]=[]
        if ["nếu yêu","chứng minh","phải trả lời","không được gặp"].contains(where:{hasPhrase(text,$0)}){result.append("Câu có thể tạo áp lực hoặc kiểm soát. Nêu nhu cầu và để người kia lựa chọn.")}
        if ["lúc nào cũng","chẳng bao giờ","tại em","tại anh"].contains(where:{hasPhrase(text,$0)}){result.append("Câu có thể nghe như quy kết. Thử nói về sự việc cụ thể và cảm xúc của mình.")}
        return result
    }
    static func refine(_ draft:String,style:String,address:String)->String {
        let clean=draft.trimmingCharacters(in:.whitespacesAndNewlines)
        guard !clean.isEmpty else{return ""}
        // Preserve the user's actual proposition; only add a framing line.
        let prefix:String
        switch style {case "hurt","sulky":prefix="{me} muốn nói thật cảm xúc của mình: ";case "firm","honest","cold":prefix="{me} muốn nói rõ: ";case "gentle","reconcile","mature":prefix="{me} muốn mình hiểu nhau hơn: ";default:prefix=""}
        return render(prefix,address:address)+clean
    }
}

struct CouplePersonalDNA:Codable {
    var samples=0
    var totalLength=0
    var emojiSamples=0
    var styles:[String:Int]=[:]
    var meanLength:Int {samples>0 ? totalLength/max(1,samples):0}
    var favoriteStyle:String? {styles.sorted{$0.value==$1.value ? $0.key<$1.key : $0.value>$1.value}.first?.key}
    static var current:Self {
        guard !KeyboardSettings.privateTypingMode,let data=KeyboardSettings.defaults.data(forKey:"viepnaikey.couple.dna"),
              let value=try? JSONDecoder().decode(Self.self,from:data),(0...10000).contains(value.samples),
              (0...5_000_000).contains(value.totalLength),(0...value.samples).contains(value.emojiSamples) else{return .init()}
        return value
    }
    static func record(_ text:String,style:String){
        guard !KeyboardSettings.privateTypingMode,CoupleStudioPreferences.current.learnFromSaved else{return}
        var value=current;guard value.samples<10000 else{return}
        value.samples+=1;value.totalLength+=min(500,text.count)
        if text.unicodeScalars.contains(where:{$0.properties.isEmojiPresentation}){value.emojiSamples+=1}
        if CoupleStyleCatalog.styles.contains(where:{$0.id==style}){value.styles[style]=min(10000,max(0,min(10000,value.styles[style] ?? 0))+1)}
        if let data=try? JSONEncoder().encode(value){KeyboardSettings.defaults.set(data,forKey:"viepnaikey.couple.dna")}
    }
    static func clear(){KeyboardSettings.defaults.removeObject(forKey:"viepnaikey.couple.dna")}
}
