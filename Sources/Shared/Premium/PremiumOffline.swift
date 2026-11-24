import Foundation

enum PremiumOffline {
    static func format(_ source: String, mode: String) -> String {
        let text = String(source.prefix(3000))
        switch mode {
        case "hoachu": return text.uppercased()
        case "thuong": return text.lowercased()
        case "danhsach": return text.components(separatedBy:.newlines).map { $0.trimmingCharacters(in:.whitespaces) }.filter { !$0.isEmpty }.map { "• " + $0 }.joined(separator:"\n")
        default: return text.components(separatedBy:.newlines).map { $0.split(whereSeparator: { $0.isWhitespace }).joined(separator:" ") }.joined(separator:"\n").trimmingCharacters(in:.whitespacesAndNewlines)
        }
    }
    static func variables(_ text: String, name: String, custom: [String:String], now: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier:"vi_VN")
        formatter.dateFormat = "dd/MM/yyyy"
        let date = formatter.string(from: now)
        formatter.dateFormat = "HH:mm"
        let time = formatter.string(from: now)
        var values = custom
        values["ngay"] = date; values["gio"] = time; values["ten"] = name
        // Single pass: replacements are plain text, never recursively executed.
        let pattern = try! NSRegularExpression(pattern: #"\{\{([a-zA-Z0-9_]{1,24})\}\}"#)
        let source = String(text.prefix(3000))
        let ns = source as NSString
        let output = NSMutableString(string: source)
        for match in pattern.matches(in:source, range:NSRange(location:0,length:ns.length)).reversed() {
            let key = ns.substring(with:match.range(at:1))
            if let value = values[key] { output.replaceCharacters(in:match.range,with:String(value.prefix(300))) }
        }
        return String((output as String).prefix(3000))
    }
    static func guardian(_ text: String) -> String {
        var warnings = MessageSafety.warnings(in:text)
        if text.contains("!!!") || text.contains("???") { warnings.append("Nhiều dấu câu liên tiếp có thể tạo cảm giác gay gắt.") }
        let letters = text.filter(\.isLetter)
        if letters.count >= 8 && letters.filter(\.isUppercase).count * 4 > letters.count * 3 { warnings.append("Nhiều chữ in hoa; cân nhắc giọng điệu.") }
        return warnings.isEmpty ? "Chưa phát hiện dấu hiệu theo bộ quy tắc cục bộ. Không bảo đảm nội dung không gây hiểu lầm." : warnings.map { "• " + $0 }.joined(separator:"\n")
    }
}
enum PremiumCalculator {
    enum Failure: Error { case invalid }
    static func evaluate(_ input: String) throws -> String {
        guard input.count <= 120 else { throw Failure.invalid }
        var parser = Parser(chars:Array(input.replacingOccurrences(of:"×",with:"*").replacingOccurrences(of:"÷",with:"/").filter { !$0.isWhitespace }))
        let value = try parser.expression()
        guard parser.index == parser.chars.count, value.isFinite, abs(value) <= 1e15 else { throw Failure.invalid }
        return String(format:"%.12g", locale:Locale(identifier:"en_US_POSIX"), value == 0 ? 0 : value)
    }
    private struct Parser {
        let chars:[Character]
        var index = 0
        mutating func take(_ c:Character)->Bool {
            guard index < chars.count, chars[index] == c else { return false }
            index += 1; return true
        }
        mutating func expression() throws -> Double {
            var result = try term()
            while true { if take("+") { result += try term() } else if take("-") { result -= try term() } else { return result } }
        }
        mutating func term() throws -> Double {
            var result = try factor()
            while true { if take("*") { result *= try factor() } else if take("/") { let n = try factor(); guard n != 0 else { throw Failure.invalid }; result /= n } else { return result } }
        }
        mutating func factor() throws -> Double {
            if take("-") { return -(try factor()) }
            if take("+") { return try factor() }
            if take("(") { let value = try expression(); guard take(")") else { throw Failure.invalid }; return value }
            let start = index
            while index < chars.count && ("0123456789.".contains(chars[index])) { index += 1 }
            guard index > start, let value = Double(String(chars[start..<index])), value.isFinite else { throw Failure.invalid }
            return value
        }
    }
}
enum GhostCompletion {
    private static let phrases = ["hôm nay bạn có khỏe không?", "chúc bạn một ngày thật vui vẻ", "cảm ơn bạn đã luôn quan tâm", "mình hy vọng mọi chuyện sẽ tốt hơn", "anh chỉ muốn em biết rằng", "em có thể chia sẻ với anh", "chúc em ngủ ngon và mơ đẹp", "hẹn gặp lại bạn vào ngày mai", "tôi sẽ kiểm tra và phản hồi sớm", "cảm ơn quý khách đã liên hệ", "thank you for your help", "I hope you have a great day"]
    static func suffix(after context: String) -> String? {
        guard context.last?.isWhitespace == true else { return nil }
        let tail = String(context.suffix(160)).lowercased()
        for phrase in phrases {
            let chars = Array(phrase.lowercased())
            for n in stride(from:chars.count-1, through:4, by:-1) where chars[n-1].isWhitespace {
                let prefix = String(chars.prefix(n))
                if tail.hasSuffix(prefix) {
                    let preceding = tail.dropLast(prefix.count).last
                    if preceding?.isLetter == true { continue }
                    return String(phrase.dropFirst(n))
                }
            }
        }
        return nil
    }
}
