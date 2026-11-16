import Foundation

@main
struct VerifyCoupleTools {
    static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else { fatalError("FAIL [CoupleTools] \(message)") }
        print("PASS [CoupleTools] \(message)")
    }

    static var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")!
        return calendar
    }()

    static func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 10) -> Date {
        var parts = DateComponents()
        parts.year = y; parts.month = m; parts.day = d; parts.hour = h
        return calendar.date(from: parts)!
    }

    static func main() {
        verifyGreetings()
        verifySpecialDates()
        verifySoften()
        verifyTone()
        verifyDates()
        verifyPronouns()
    }

    // MARK: Greetings

    static func verifyGreetings() {
        expect(GreetingBank.slot(for: date(2026, 11, 16, 7), calendar: calendar) == .morning, "7h is morning")
        expect(GreetingBank.slot(for: date(2026, 11, 16, 12), calendar: calendar) == .noon, "12h is noon")
        expect(GreetingBank.slot(for: date(2026, 11, 16, 15), calendar: calendar) == .afternoon, "15h is afternoon")
        expect(GreetingBank.slot(for: date(2026, 11, 16, 20), calendar: calendar) == .evening, "20h is evening")
        expect(GreetingBank.slot(for: date(2026, 11, 16, 23), calendar: calendar) == .night, "23h is night")
        expect(GreetingBank.slot(for: date(2026, 11, 16, 3), calendar: calendar) == .night, "3h is night")
        let forms = GreetingBank.pronouns(from: "em/anh")
        expect(forms.me == "em" && forms.you == "anh", "pronouns are split")
        expect(GreetingBank.pronouns(from: "lạ").you == "em", "unknown form falls back")
        for slot in GreetingBank.Slot.allCases {
            let list = GreetingBank.templates[slot] ?? []
            expect(list.count >= 6, "enough greetings for \(slot.rawValue)")
            expect(Set(list).count == list.count, "greetings are distinct for \(slot.rawValue)")
            for template in list {
                let text = GreetingBank.filled(template, address: "anh/em")
                expect(!text.contains("{") && !text.contains("}"), "placeholders are filled: \(text)")
            }
            var last: Int?
            var seen = Set<Int>()
            for _ in 0..<list.count {
                let next = GreetingBank.pick(slot: slot, address: "anh/em", lastIndex: last)
                expect(next.index != last, "never repeats the previous line")
                seen.insert(next.index)
                last = next.index
            }
            expect(seen.count == list.count, "every greeting is used once per cycle")
        }
        let first = GreetingBank.pick(slot: .night, address: "anh/em", lastIndex: nil)
        expect(first.index == 0 && !first.text.isEmpty, "first pick is the first line")
    }

    // MARK: Special dates

    static func verifySpecialDates() {
        let now = date(2026, 11, 16)
        let anniversary = SpecialDate(id: "a", title: "Ngày yêu", kind: "anniversary",
                                      month: 11, day: 16, year: 2025)
        let birthday = SpecialDate(id: "b", title: "Mai", kind: "birthday",
                                   month: 11, day: 20, year: nil)
        let leap = SpecialDate(id: "c", title: "Lễ", kind: "other", month: 2, day: 29, year: nil)
        expect(SpecialDates.daysUntilNext(anniversary, from: now, calendar: calendar) == 0, "today is 0 days away")
        expect(SpecialDates.daysUntilNext(birthday, from: now, calendar: calendar) == 4, "birthday is 4 days away")
        let past = SpecialDate(id: "d", title: "Qua", kind: "other", month: 11, day: 15, year: nil)
        expect(SpecialDates.daysUntilNext(past, from: now, calendar: calendar) == 364, "a past date comes round next year")
        expect(SpecialDates.daysUntilNext(leap, from: now, calendar: calendar) == 104, "29 Feb falls on 28 Feb in 2027")
        let soon = SpecialDates.upcoming([birthday, anniversary, past], within: 7, now: now, calendar: calendar)
        expect(soon.count == 2 && soon[0].item.id == "a" && soon[1].item.id == "b", "upcoming is sorted and limited")
        expect(SpecialDates.daysTogether([anniversary], now: now, calendar: calendar) == 366, "day count includes the first day")
        let start = SpecialDate(id: "e", title: "Bắt đầu", kind: "anniversary", month: 11, day: 16, year: 2026)
        expect(SpecialDates.daysTogether([start], now: now, calendar: calendar) == 1, "first day is day 1")
        let future = SpecialDate(id: "f", title: "Sau", kind: "anniversary", month: 12, day: 1, year: 2027)
        expect(SpecialDates.daysTogether([future], now: now, calendar: calendar) == nil, "a start in the future gives nil")
        expect(SpecialDates.daysTogether([birthday], now: now, calendar: calendar) == nil, "no anniversary gives nil")
        expect(SpecialDates.togetherMessage(days: 100).contains("tròn 100"), "milestones say tròn")
        expect(SpecialDates.togetherMessage(days: 366).contains("ngày thứ 366"), "other days say ngày thứ")
        expect(SpecialDates.message(for: birthday, daysAway: 0, now: now, calendar: calendar).contains("sinh nhật Mai"), "birthday wish")
        expect(SpecialDates.message(for: birthday, daysAway: 4, now: now, calendar: calendar).contains("Còn 4 ngày"), "countdown")
        expect(SpecialDates.message(for: anniversary, daysAway: 0, now: now, calendar: calendar).contains("tròn 1 năm"), "years are counted")
        expect(SpecialDates.menuTitle(for: birthday, daysAway: 0).hasSuffix("hôm nay"), "menu title says today")
        let data = SpecialDates.encode([anniversary, birthday])
        expect(SpecialDates.decode(data) == [anniversary, birthday], "dates survive encode and decode")
        expect(SpecialDates.decode(nil).isEmpty, "no data gives an empty list")
        let bad = SpecialDate(id: "x", title: " ", kind: "other", month: 13, day: 1, year: nil)
        expect(!SpecialDates.isValid(bad), "an invalid date is rejected")
        expect(SpecialDates.decode(SpecialDates.encode([bad, birthday])) == [birthday], "invalid dates are dropped")
    }

    // MARK: Softer wording

    static func verifySoften() {
        let one = SoftenMessage.suggestion(forRawWords: ["anh", "lúc", "nào", "cũng"])
        expect(one?.original == "lúc nào cũng" && one?.softer == "dạo này hay", "lúc nào cũng is softened")
        let keEm = SoftenMessage.suggestion(forRawWords: ["Kệ", "em"])
        expect(keEm?.original == "Kệ em" && keEm?.softer.hasPrefix("Em đang hơi buồn") == true,
               "kệ em keeps the capital and the speaker's own pronoun")
        let tuyAnh = SoftenMessage.suggestion(forRawWords: ["tùy", "anh"])
        expect(tuyAnh?.softer == "mình cùng chọn nhé, mình muốn nghe ý anh", "tùy anh is softened")
        expect(SoftenMessage.suggestion(forRawWords: ["xin", "chào"]) == nil, "normal words are left alone")
        expect(SoftenMessage.suggestion(forRawWords: []) == nil, "no words, no suggestion")
        expect(SoftenMessage.suggestion(forRawWords: ["chia", "tay"]) == nil, "serious statements are never touched")
        for (key, value) in SoftenMessage.phrases {
            expect(key == NextWordPredictor.normalize(key), "key is normalised: \(key)")
            expect(!value.isEmpty && value != key, "entry changes something: \(key)")
            expect(key.split(separator: " ").count <= 3, "key has at most three words: \(key)")
        }
    }

    // MARK: Tone

    static func verifyTone() {
        expect(MessageTone.detect("Em giận anh rồi, kệ em")?.id == "angry", "angry message")
        expect(MessageTone.detect("Hôm nay em mệt quá, đau đầu nữa")?.id == "tired", "tired message")
        expect(MessageTone.detect("Em buồn lắm, thấy thất vọng quá")?.id == "sad", "sad message")
        expect(MessageTone.detect("Anh ơi nhớ anh quá, sao không nhắn tin cho em")?.id == "needy", "needy message")
        expect(MessageTone.detect("Hôm nay vui quá, yêu anh nhiều 😍")?.id == "happy", "happy message")
        expect(MessageTone.detect("😢")?.id == "sad", "a sad emoji alone is enough")
        expect(MessageTone.detect("Chiều nay ăn gì?") == nil, "a neutral message gives nothing")
        expect(MessageTone.detect("   ") == nil, "blank gives nothing")
        expect(MessageTone.detect("Em hơi chán") == nil, "one weak word is not enough")
        let angry = MessageTone.detect("em bực quá")
        expect(angry?.styles.first == "reconcile", "angry leads with the reconcile style")
        let ids = ["reconcile", "apology", "mature", "gentle", "caring", "encourage",
                   "sweet", "longdistance", "playful", "funny"]
        for text in ["em giận", "em buồn", "em mệt", "nhớ anh quá", "vui quá"] {
            for style in MessageTone.detect(text)?.styles ?? [] {
                expect(ids.contains(style), "style id is known: \(style)")
            }
        }
    }

    // MARK: Dates and times

    static func verifyDates() {
        // Monday 16 November 2026.
        let now = date(2026, 11, 16)
        func parse(_ text: String) -> DateTimePhrases.Match? {
            DateTimePhrases.suggestion(inTail: text, now: now, calendar: calendar)
        }
        expect(parse("mai 7h")?.formatted == "7:00, Thứ Ba 17/11", "mai 7h")
        expect(parse("hẹn mai 7h")?.original == "mai 7h", "only the phrase is replaced")
        expect(parse("mai 19h30")?.formatted == "19:30, Thứ Ba 17/11", "mai 19h30")
        expect(parse("7h tối mai")?.formatted == "19:00, Thứ Ba 17/11", "7h tối mai")
        expect(parse("t6")?.formatted == "Thứ Sáu 20/11", "t6")
        expect(parse("t6 tuần sau")?.formatted == "Thứ Sáu 27/11", "t6 tuần sau")
        expect(parse("thứ 2")?.formatted == "Thứ Hai 23/11", "today's weekday means next week")
        expect(parse("thứ 2 tuần này")?.formatted == "Thứ Hai 16/11", "thứ 2 tuần này is today")
        expect(parse("cuối tuần")?.formatted == "Thứ Bảy 21/11", "cuối tuần")
        expect(parse("chủ nhật 8h sáng")?.formatted == "8:00, Chủ Nhật 22/11", "chủ nhật 8h sáng")
        expect(parse("mốt 20h")?.formatted == "20:00, Thứ Tư 18/11", "mốt 20h")
        expect(parse("hôm nay 5h chiều")?.formatted == "17:00, Thứ Hai 16/11", "hôm nay 5h chiều")
        expect(parse("ngày mai lúc 9h")?.original == "ngày mai lúc 9h", "filler words are accepted")
        expect(parse("mai 7 giờ")?.formatted == "7:00, Thứ Ba 17/11", "7 giờ")
        expect(parse("mai 7 giờ 30")?.formatted == "7:30, Thứ Ba 17/11", "7 giờ 30")
        expect(parse("mai 12h trưa")?.formatted == "12:00, Thứ Ba 17/11", "12h trưa stays noon")
        expect(parse("mai 1h trưa")?.formatted == "13:00, Thứ Ba 17/11", "1h trưa is 13:00")
        expect(parse("mai") == nil, "a bare mai is ordinary text")
        expect(parse("7h") == nil, "a bare time is not enough")
        expect(parse("xin chào") == nil, "normal words give nothing")
        expect(parse("mai 25h") == nil, "an impossible hour gives nothing")
        expect(parse("mai 7h.") == nil, "trailing punctuation gives nothing")
        expect(parse("") == nil, "empty gives nothing")
        expect(parse("mai  7h") == nil, "double spaces are left alone")
    }

    // MARK: Who is who

    static func verifyPronouns() {
        expect(CouplePronouns.forms(from: "anh/em").me == "anh", "anh/em: user is anh")
        expect(CouplePronouns.forms(from: "em/anh").me == "em", "em/anh: user is em")
        expect(CouplePronouns.forms(from: "bạn/mình").me == "mình" && CouplePronouns.forms(from: "bạn/mình").you == "bạn",
               "bạn/mình lists the partner first")
        expect(CouplePronouns.forms(from: "tớ/cậu").you == "cậu", "tớ/cậu")
        expect(GreetingBank.pronouns(from: "bạn/mình").me == "mình", "greetings use the same forms")
        let a = CouplePronouns.senderForms(in: "Em nhớ anh lắm")
        expect(a?.sender == "em" && a?.receiver == "anh", "Em nhớ anh lắm: sender em, user anh")
        let b = CouplePronouns.senderForms(in: "Anh ơi, em nhớ anh quá")
        expect(b?.sender == "em" && b?.receiver == "anh", "a calling-out Anh ơi is not the sender")
        let c = CouplePronouns.senderForms(in: "Anh nhớ em nhiều")
        expect(c?.sender == "anh" && c?.receiver == "em", "Anh nhớ em: sender anh, user em")
        let d = CouplePronouns.senderForms(in: "Em nhớ chị")
        expect(d?.sender == "em" && d?.receiver == "chị", "Em nhớ chị")
        expect(CouplePronouns.senderForms(in: "Hôm nay em mệt quá") == nil, "unclear opening gives nil")
        expect(CouplePronouns.senderForms(in: "Em mệt quá") == nil, "one pronoun gives nil")
        let forms = CouplePronouns.resolved(address: "em/anh", incoming: "Em nhớ anh lắm")
        expect(forms.me == "anh" && forms.you == "em", "the message overrides a wrong saved choice")
        let saved = CouplePronouns.resolved(address: "em/anh", incoming: "Hôm nay mệt quá")
        expect(saved.me == "em" && saved.you == "anh", "the saved choice is used when the message is unclear")
        let rule = CouplePronouns.rule(address: "anh/em", incoming: "Em nhớ anh lắm")
        expect(rule.contains("written by my partner"), "rule says the partner wrote the message")
        expect(rule.contains("Anh cũng nhớ em lắm"), "rule shows the correct reply")
        expect(rule.contains("calls themselves \"em\" and calls me \"anh\""), "rule names this message's pronouns")
        expect(!CouplePronouns.rule(address: "anh/em", incoming: "Hôm nay mệt quá").contains("For THIS message"),
               "no message-specific line when it is unclear")
        expect(CouplePronouns.adapt("Anh cũng nhớ em. Anh gửi em một cái ôm", me: "em", you: "anh")
               == "Em cũng nhớ anh. Em gửi anh một cái ôm", "examples are swapped for an em/anh user")
        expect(CouplePronouns.adapt("Anh nhớ em", me: "mình", you: "cậu") == "Mình nhớ cậu", "mình/cậu")
        expect(CouplePronouns.adapt("Anh nhớ em", me: "anh", you: "em") == "Anh nhớ em", "anh/em is unchanged")
        expect(CouplePronouns.adapt("tem anh emoji", me: "em", you: "anh") == "tem em emoji",
               "only whole words are changed")
    }
}
