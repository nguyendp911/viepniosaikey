import Foundation

@main
struct VerifySendEffects {
    static func main() {
        var passed = 0
        func expect(_ text: String, _ mode: String, _ want: SendEffect?, roll: Int = 0) {
            let got = SendEffects.effect(forMessage: text, mode: mode, roll: roll)
            guard got == want else {
                fatalError("SendEffects: \"\(text)\" [\(mode)] -> \(String(describing: got)), expected \(String(describing: want))")
            }
            passed += 1
        }
        // Chosen from what the message says.
        expect("Chúc mừng sinh nhật em nhé", "auto", .balloons)
        expect("chuc mung sinh nhat", "auto", .balloons)
        expect("Happy birthday!", "auto", .balloons)
        expect("Chúc mừng năm mới", "auto", .fireworks)
        expect("Giao thừa này đi đâu", "auto", .fireworks)
        expect("Tết này anh về quê", "auto", .luckyMoney)
        expect("Lì xì cho em nha", "auto", .luckyMoney)
        expect("Giáng sinh vui vẻ", "auto", .snow)
        expect("Cảm ơn bạn nhiều", "auto", .flowers)
        expect("Chúc mừng 8/3", "auto", .flowers)
        expect("Chúc ngủ ngon", "auto", .stars)
        expect("Good night", "auto", .stars)
        expect("Chúc mừng em nhé", "auto", .confetti)
        expect("Thành công rồi", "auto", .confetti)
        expect("Yêu em nhiều", "auto", .hearts)
        expect("yeu em", "auto", .hearts)
        expect("Anh thương em", "auto", .hearts)
        expect("Nhớ anh quá", "auto", .hearts)
        expect("I love you", "auto", .hearts)
        expect("❤️", "auto", .hearts)
        expect("Thích quá 🎉", "auto", .confetti)
        // Words that only look alike must not trigger an effect.
        expect("Hôm nay tôi yếu lắm", "auto", nil)
        expect("Yêu cầu gửi báo giá", "auto", nil)
        expect("yeu cau gui bao gia", "auto", nil)
        expect("Thường xuyên đi làm", "auto", nil)
        expect("Gửi file test giúp mình", "auto", nil)
        expect("ok", "auto", nil)
        expect("", "auto", nil)
        // Other modes.
        expect("ok", "off", nil)
        expect("Chúc mừng sinh nhật", "off", nil)
        expect("ok", SendEffect.hearts.rawValue, .hearts)
        expect("ok", SendEffect.snow.rawValue, .snow)
        expect("ok", "unknown-mode", nil)
        expect("ok", "random", SendEffect.allCases[0], roll: 0)
        expect("ok", "random", SendEffect.allCases[3], roll: 3)
        expect("ok", "random", SendEffect.allCases[1], roll: 9)
        expect("ok", "random", SendEffect.allCases[1], roll: -9)
        for effect in SendEffect.allCases {
            precondition(!effect.title.isEmpty && !effect.icon.isEmpty && !effect.example.isEmpty)
        }
        print("PASS [SendEffects] \(passed) messages, \(SendEffect.allCases.count) effects")
    }
}
