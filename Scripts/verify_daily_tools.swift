import Foundation

@main
struct VerifyDailyTools {
    static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else { fatalError("FAIL [DailyTools] \(message)") }
        print("PASS [DailyTools] \(message)")
    }

    static var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")!
        return calendar
    }()

    // Monday 16 November 2026, 10:00.
    static var now: Date {
        var parts = DateComponents()
        parts.year = 2026; parts.month = 11; parts.day = 16; parts.hour = 10
        return calendar.date(from: parts)!
    }

    static func parts(_ date: Date) -> (day: Int, hour: Int, minute: Int) {
        let c = calendar.dateComponents([.day, .hour, .minute], from: date)
        return (c.day ?? 0, c.hour ?? 0, c.minute ?? 0)
    }

    static func main() {
        verifyDates()
        verifyCommitments()
        verifyShop()
        verifyVoice()
        verifyAdvice()
    }

    // MARK: Dates anywhere in a message

    static func verifyDates() {
        let spread = DateTimePhrases.firstMatch(in: "Mai anh đón em lúc 7h nhé", now: now, calendar: calendar)
        expect(spread != nil && parts(spread!.date) == (day: 17, hour: 7, minute: 0),
               "a day and a time apart are joined: mai ... 7h")
        let near = DateTimePhrases.firstMatch(in: "ok mai 19h30 nhé", now: now, calendar: calendar)
        expect(near != nil && parts(near!.date) == (day: 17, hour: 19, minute: 30), "mai 19h30 inside a sentence")
        let weekday = DateTimePhrases.firstMatch(in: "Thứ 6 mình gặp nhau nha", now: now, calendar: calendar)
        expect(weekday != nil && parts(weekday!.date) == (day: 20, hour: 9, minute: 0), "a weekday alone is 9:00")
        let longer = DateTimePhrases.firstMatch(in: "t6 tuần sau mình gặp", now: now, calendar: calendar)
        expect(longer != nil && parts(longer!.date) == (day: 27, hour: 9, minute: 0), "the longest form wins: t6 tuần sau")
        let tonight = DateTimePhrases.firstMatch(in: "tối nay anh qua lúc 8h", now: now, calendar: calendar)
        expect(tonight != nil && parts(tonight!.date) == (day: 16, hour: 20, minute: 0), "tối nay 8h is today 20:00")
        expect(DateTimePhrases.firstMatch(in: "hôm nay trời đẹp", now: now, calendar: calendar) == nil,
               "no date in an ordinary sentence")
        expect(DateTimePhrases.firstMatch(in: "", now: now, calendar: calendar) == nil, "empty text")
        expect(DateTimePhrases.suggestion(inTail: "mai 7h", now: now, calendar: calendar)?.hasTime == true,
               "a clock time is flagged")
    }

    // MARK: Promises

    static func verifyCommitments() {
        func found(_ mine: Bool, _ text: String) -> [CommitmentDetector.Found] {
            CommitmentDetector.detect([(mine: mine, text: text)], now: now, calendar: calendar)
        }
        let one = found(true, "Mai anh đón em lúc 7h nhé")
        expect(one.count == 1 && one[0].mine && one[0].due.map { parts($0) == (day: 17, hour: 7, minute: 0) } == true,
               "a promise with a day and a time is found")
        let friday = found(false, "Thứ 6 mình gặp nhau nha")
        expect(friday.count == 1 && !friday[0].mine && friday[0].due.map { parts($0).day == 20 } == true,
               "the other person's promise is found")
        let nextWeek = found(true, "Tuần sau anh gửi file cho chị")
        expect(nextWeek.count == 1 && nextWeek[0].due == nil, "a future marker without a time has no due date")
        let swore = found(true, "Anh hứa sẽ gọi em")
        expect(swore.count == 1 && swore[0].due == nil, "a plain promise is found")
        expect(found(false, "Mai mấy giờ đi?").isEmpty, "a question without an action is ignored")
        expect(found(false, "Mai anh đón em được không?").isEmpty, "a request is not a promise")
        expect(found(false, "Hôm nay trời đẹp quá").isEmpty, "small talk is ignored")
        expect(found(false, "Mai trời mưa to lắm").isEmpty, "rain is not buying")
        expect(found(true, "ok").isEmpty, "very short text is ignored")

        let transcript = """
        Người trò chuyện: Mai
        Hội thoại trong ảnh chụp (Tôi = người dùng, Người ấy = người nhận):
        Người ấy: Mai anh đón em nhé
        Tôi: Ok em
        Tin nhắn cần trả lời: Mai anh đón em nhé
        """
        let lines = CommitmentDetector.messages(fromTranscript: transcript)
        expect(lines.count == 2 && !lines[0].mine && lines[1].mine && lines[1].text == "Ok em",
               "a labelled transcript is read line by line")
        let plain = CommitmentDetector.messages(fromTranscript: "Mai gặp nhé\n\nOk")
        expect(plain.count == 2 && !plain[0].mine, "plain text counts as the other person's")

        let existing = [Commitment(id: "1", profileID: "p", mine: true, text: "Mai anh đón em lúc 7h nhé",
                                   due: nil, confirmed: false, done: false, created: now)]
        expect(CommitmentDetector.newOnes(one, existing: existing).isEmpty, "a saved promise is not added twice")
        expect(CommitmentDetector.newOnes(friday, existing: existing).count == 1, "a new promise is added")
    }

    // MARK: Shop

    static var shop: ShopProfile {
        ShopProfile(shopName: "Shop Mây", shipFee: 20000, bankLine: "STK 0123456789 · Vietcombank",
                    products: [
                        ShopProduct(id: "1", name: "Áo thun", price: 150000, note: "size M L"),
                        ShopProduct(id: "2", name: "Quần jean", price: 250000, note: ""),
                        ShopProduct(id: "3", name: "Áo thun trắng", price: 160000, note: "")
                    ])
    }

    static func verifyShop() {
        expect(ShopTools.parsePrice("150k") == 150000, "150k")
        expect(ShopTools.parsePrice("150.000") == 150000, "150.000")
        expect(ShopTools.parsePrice("150000đ") == 150000, "150000đ")
        expect(ShopTools.parsePrice("1tr5") == 1500000, "1tr5")
        expect(ShopTools.parsePrice("150") == 150000, "a bare 150 means 150.000")
        expect(ShopTools.parsePrice("abc") == nil, "text is not a price")
        expect(ShopTools.parsePrice("0") == nil, "zero is not a price")
        expect(ShopTools.money(150000) == "150.000đ", "money format")

        let order = ShopTools.order(from: "áo thun x2, quần jean 1, ship 25k", profile: shop)
        expect(order?.lines.count == 2, "two products are found")
        expect(order?.lines[0].quantity == 2 && order?.lines[0].product.name == "Áo thun", "x2 is a quantity")
        expect(order?.shipping == 25000, "a ship line sets the shipping")
        expect(order?.total == 575000, "the total adds up")
        let long = ShopTools.order(from: "2 áo thun trắng và 1 quần jean", profile: shop)
        expect(long?.lines[0].product.name == "Áo thun trắng" && long?.lines[0].quantity == 2,
               "the longest product name wins")
        expect(long?.total == 590000, "the default shipping is added")
        let free = ShopTools.order(from: "áo thun, free ship", profile: shop)
        expect(free?.shipping == 0 && free?.total == 150000, "free ship is zero")
        let partly = ShopTools.order(from: "áo thun, váy xinh", profile: shop)
        expect(partly?.lines.count == 1 && partly?.unmatched == ["váy xinh"], "unknown items are listed")
        expect(ShopTools.order(from: "xin chào", profile: shop) == nil, "no product, no order")
        expect(ShopTools.order(from: "áo thun", profile: ShopProfile()) == nil, "an empty catalog gives no order")
        if let order = order {
            let text = ShopTools.summary(order, profile: shop)
            expect(text.contains("2 × Áo thun = 300.000đ") && text.contains("Tổng cộng: 575.000đ"),
                   "the summary lists lines and the total")
            expect(text.contains("Phí ship: 25.000đ"), "the summary shows shipping")
        }
        let templates = ShopTools.templates(for: shop)
        expect(templates.count >= 9, "there are enough ready-made messages")
        expect(templates.contains { $0.title == "Báo giá" && $0.text.contains("150.000đ") }, "the price list shows prices")
        expect(templates.contains { $0.title == "Thanh toán" && $0.text.contains("0123456789") }, "payment shows the bank line")
        expect(templates.allSatisfy { !$0.text.contains("{") }, "no placeholder is left")
        let round = ShopTools.decode(ShopTools.encode(shop))
        expect(round == shop, "the shop survives encode and decode")
        var bad = shop
        bad.products.append(ShopProduct(id: "9", name: " ", price: 0, note: ""))
        expect(ShopTools.decode(ShopTools.encode(bad)).products.count == 3, "invalid products are dropped")
    }

    // MARK: Voices

    static func verifyVoice() {
        expect(VoiceStyles.apply(.south, to: "Tôi không biết, mẹ nhé") == "Tui hông biết, má nghen", "giọng Nam")
        expect(VoiceStyles.apply(.north, to: "Tui hông biết nghen") == "Tôi không biết nhé", "giọng Bắc")
        expect(VoiceStyles.apply(.central, to: "Sao vậy này") == "Răng rứa ni", "giọng Trung")
        expect(VoiceStyles.apply(.genZ, to: "Hôm nay rất vui").contains("quá trời"), "giọng Gen Z")
        expect(VoiceStyles.apply(.south, to: "Anh ấy đi rồi") == "Ảnh đi rồi", "two words become one")
        expect(VoiceStyles.apply(.south, to: "Hà Nội") == "Hà Nội", "other words are left alone")
        expect(VoiceStyles.apply(.south, to: "Không!") == "Hông!", "punctuation and capitals are kept")
        expect(VoiceStyles.apply(.north, to: "") == "", "empty stays empty")
        for style in VoiceStyle.allCases {
            expect(!style.title.isEmpty, "every voice has a title: \(style.rawValue)")
        }
    }

    // MARK: AI answers

    static func verifyAdvice() {
        let payload: [String: Any] = [
            "summary": "Hai bên đang hiểu lầm về chuyện đi chơi.",
            "escalation": "Người ấy dùng từ nặng hơn.",
            "their_feeling": "thấy bị bỏ rơi",
            "avoid": ["Em lúc nào cũng vậy", "Kệ em", "Thôi khỏi"],
            "replies": [
                ["tone": "Hạ nhiệt", "text": "Anh xin lỗi vì chuyện lúc nãy."],
                ["tone": "Lắng nghe", "text": "Em kể anh nghe được không?"],
                ["text": "Mình nói chuyện sau nhé."],
                ["tone": "Thừa", "text": "Câu thứ tư bị bỏ"]
            ],
            "timing": "Nên nhắn ngay"
        ]
        let advice = MediationAdvice.parse(payload)
        expect(advice?.replies.count == 3, "at most three replies are kept")
        expect(advice?.replies[2].tone == "Hạ nhiệt", "a missing tone gets a default")
        expect(advice?.avoid.count == 3 && advice?.theirFeeling == "thấy bị bỏ rơi", "avoid list and feeling are read")
        expect(advice?.statusLine.hasPrefix("🧭 Người ấy: thấy bị bỏ rơi") == true, "the status line starts with the feeling")
        expect((advice?.statusLine.count ?? 999) <= 140, "the status line is short")
        expect(MediationAdvice.parse(["replies": []]) == nil, "no replies, no advice")
        expect(MediationAdvice.parse([:]) == nil, "an empty answer gives nothing")
        expect(MediationAdvice.parse(["replies": [["text": "  "]]]) == nil, "blank replies are dropped")

        let facts = MemoryFacts.parse(["facts": ["Thích cà phê sữa", "thích cà phê sữa", "ab", "Dị ứng hải sản",
                                                 "Có mèo tên Mun", "Sinh nhật 3/5", 42]])
        expect(facts == ["Thích cà phê sữa", "Dị ứng hải sản", "Có mèo tên Mun"],
               "facts are de-duplicated, short ones dropped and at most three kept")
        expect(MemoryFacts.parse([:]).isEmpty, "no facts gives an empty list")
        expect(MemoryFacts.fresh(["Thích cà phê", "Có mèo"], known: ["thích cà phê"]) == ["Có mèo"],
               "known facts are not suggested again")
    }
}
