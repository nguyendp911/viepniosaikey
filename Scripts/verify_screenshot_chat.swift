import Foundation

@main
struct VerifyScreenshotChat {
    static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else { fatalError("FAIL [ScreenshotChat] \(message)") }
        print("PASS [ScreenshotChat] \(message)")
    }

    typealias Line = ScreenshotTranscript.Line

    static func main() {
        verifyNoise()
        verifyConversation()
        verifyTitles()
        verifyFocus()
    }

    static func verifyNoise() {
        expect(ScreenshotTranscript.isNoise("10:32"), "a clock time is noise")
        expect(ScreenshotTranscript.isNoise("9:05 SA"), "a clock time with SA is noise")
        expect(ScreenshotTranscript.isNoise("21h30"), "21h30 is noise")
        expect(ScreenshotTranscript.isNoise("Hôm nay"), "a day separator is noise")
        expect(ScreenshotTranscript.isNoise("Hôm qua 21:10"), "a day separator with a time is noise")
        expect(ScreenshotTranscript.isNoise("Đã xem"), "a read receipt is noise")
        expect(ScreenshotTranscript.isNoise("Thứ Hai 10:32"), "a weekday with a time is noise")
        expect(ScreenshotTranscript.isNoise("12/11"), "a date is noise")
        expect(ScreenshotTranscript.isNoise("•"), "a lone symbol is noise")
        expect(!ScreenshotTranscript.isNoise("Hôm nay em mệt quá"), "a message starting with Hôm nay is kept")
        expect(!ScreenshotTranscript.isNoise("Đã xem rồi mà không trả lời"), "a message starting with Đã xem is kept")
        expect(!ScreenshotTranscript.isNoise("Tin nhắn của em đâu"), "a message starting with Tin nhắn is kept")
        expect(!ScreenshotTranscript.isNoise("50"), "a lone number is kept")
        expect(!ScreenshotTranscript.isNoise("Em nhớ anh lắm"), "a normal message is kept")
    }

    static func verifyConversation() {
        let lines: [Line] = [
            Line(text: "Mai Linh", minX: 0.35, maxX: 0.65, midY: 0.93),            // header
            Line(text: "Đang hoạt động", minX: 0.36, maxX: 0.64, midY: 0.905),      // header
            Line(text: "Hôm nay 10:32", minX: 0.38, maxX: 0.62, midY: 0.84),        // separator
            Line(text: "Em nhớ anh lắm", minX: 0.16, maxX: 0.50, midY: 0.78),       // other
            Line(text: "Anh cũng nhớ em", minX: 0.52, maxX: 0.90, midY: 0.70),      // mine
            Line(text: "Hôm nay em đi làm mệt quá", minX: 0.16, maxX: 0.78, midY: 0.60),
            Line(text: "không muốn nói chuyện", minX: 0.16, maxX: 0.60, midY: 0.575), // other, 2 lines
            Line(text: "Em nghỉ ngơi đi, tối anh gọi cho em", minX: 0.30, maxX: 0.90, midY: 0.48),
            Line(text: "nhé", minX: 0.30, maxX: 0.38, midY: 0.455),                  // mine, 2 lines
            Line(text: "Đã xem", minX: 0.80, maxX: 0.92, midY: 0.40),                // receipt
            Line(text: "Nhập tin nhắn", minX: 0.15, maxX: 0.50, midY: 0.05)         // input bar
        ]
        let messages = ScreenshotTranscript.messages(from: lines)
        expect(messages.count == 4, "four messages are found")
        expect(messages[0] == ScreenshotTranscript.Message(isMine: false, text: "Em nhớ anh lắm"),
               "left bubble is the other person")
        expect(messages[1] == ScreenshotTranscript.Message(isMine: true, text: "Anh cũng nhớ em"),
               "right bubble is the user")
        expect(!messages[2].isMine && messages[2].text == "Hôm nay em đi làm mệt quá không muốn nói chuyện",
               "a two-line left bubble is joined")
        expect(messages[3].isMine && messages[3].text == "Em nghỉ ngơi đi, tối anh gọi cho em nhé",
               "a two-line right bubble keeps its short last line")
        let text = ScreenshotTranscript.transcript(personName: "Mai Linh", messages: messages)
        expect(text?.hasPrefix("Người trò chuyện: Mai Linh") == true, "transcript starts with the person")
        expect(text?.contains("Người ấy: Em nhớ anh lắm") == true, "other person's line is labelled")
        expect(text?.contains("Tôi: Anh cũng nhớ em") == true, "user's line is labelled")
        expect(text?.hasSuffix("Tin nhắn cần trả lời: Hôm nay em đi làm mệt quá không muốn nói chuyện") == true,
               "the target is the other person's last message")
        expect(ScreenshotTranscript.transcript(personName: nil, messages: []) == nil, "no messages, no transcript")
        let noName = ScreenshotTranscript.transcript(personName: nil, messages: messages)
        expect(noName?.contains("Người trò chuyện:") == false, "no name, no title line")
        let many = (0..<30).map { ScreenshotTranscript.Message(isMine: $0 % 2 == 0, text: "tin \($0)") }
        let capped = ScreenshotTranscript.transcript(personName: nil, messages: many) ?? ""
        expect(!capped.contains("tin 0\n") && capped.contains("tin 29"), "only the latest messages are kept")
        expect(ScreenshotTranscript.messages(from: []).isEmpty, "no lines, no messages")
    }

    static func verifyTitles() {
        expect(ScreenshotTranscript.titleMatches(title: "Mai Linh ❤️", names: ["Mai Linh", "Nam"]) == [0],
               "emoji after the name is ignored")
        expect(ScreenshotTranscript.titleMatches(title: "mai linh", names: ["Mai Linh"]) == [0], "case is ignored")
        expect(ScreenshotTranscript.titleMatches(title: "Mai", names: ["Mai Linh", "Hoa"]) == [0],
               "a short title inside a saved name matches")
        expect(ScreenshotTranscript.titleMatches(title: "Mai Linh (Công ty)", names: ["Mai Linh", "Hoa"]) == [0],
               "a saved name inside the title matches")
        expect(ScreenshotTranscript.titleMatches(title: "Mai", names: ["Mai Linh", "Mai Anh"]) == [0, 1],
               "two candidates stay ambiguous")
        expect(ScreenshotTranscript.titleMatches(title: "Mai Linh", names: ["Mai Linh", "Mai Linh Anh"]) == [0],
               "an exact match beats a longer name")
        expect(ScreenshotTranscript.titleMatches(title: "Zalo", names: ["Mai Linh"]).isEmpty, "unrelated title")
        expect(ScreenshotTranscript.titleMatches(title: "Vợ", names: ["Vợ"]) == [0], "a short name matches exactly")
        expect(ScreenshotTranscript.titleMatches(title: "Vợ yêu", names: ["Vợ"]).isEmpty,
               "a very short name never matches loosely")
        expect(ScreenshotTranscript.titleMatches(title: "Nguyễn Đức", names: ["nguyen duc"]) == [0],
               "accents are ignored")
        expect(ScreenshotTranscript.titleMatches(title: "", names: ["Mai"]).isEmpty, "empty title")
    }

    static func verifyFocus() {
        let lines: [Line] = [
            Line(text: "Em nhớ anh lắm", minX: 0.16, maxX: 0.50, midY: 0.70),
            Line(text: "Anh cũng nhớ em", minX: 0.52, maxX: 0.90, midY: 0.60)
        ]
        let text = ScreenshotTranscript.transcript(
            personName: "Mai", messages: ScreenshotTranscript.messages(from: lines)) ?? ""
        expect(ScreenshotTranscript.focusMessage(text) == "Em nhớ anh lắm", "focus is the other person's message")
        expect(ScreenshotTranscript.focusMessage("Em nhớ anh") == "Em nhớ anh", "plain text is unchanged")
        let seen = CouplePronouns.senderForms(in: text)
        expect(seen?.sender == "em" && seen?.receiver == "anh", "pronouns are read from the other person's message")
        let me = CouplePronouns.resolved(address: "em/anh", incoming: text)
        expect(me.me == "anh" && me.you == "em", "the reply is written as anh")
    }
}
