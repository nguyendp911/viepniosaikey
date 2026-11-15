import Foundation

/// Turns chat-style amounts into written money: "50k" -> "50.000đ",
/// "1tr5" -> "1.500.000đ", "2ty" -> "2.000.000.000đ". Only the units that are
/// unambiguous in Vietnamese chat are supported (k, tr, ty/tỷ); "m", "kg",
/// "km" and similar are left alone. Offered as a tap-able suggestion only.
enum MoneyShorthand {
    /// The amount token at the very end of `text` (digits, ".", "," and
    /// letters), or nil when the text does not end in such a token.
    static func lastToken(of text: String) -> String? {
        var chars: [Character] = []
        for ch in text.reversed() {
            if ch.isLetter || ch.isNumber || ch == "." || ch == "," {
                chars.append(ch)
                if chars.count > 16 { return nil }
            } else {
                break
            }
        }
        var token = String(chars.reversed())
        while let first = token.first, first == "." || first == "," { token.removeFirst() }
        guard let first = token.first, first.isASCII, first.isNumber else { return nil }
        return token
    }

    /// The written amount for `rawToken`, or nil if it is not a recognised
    /// shorthand (so "50", "3km" and "10m" give nil).
    static func suggestion(for rawToken: String) -> String? {
        let token = rawToken.lowercased().precomposedStringWithCanonicalMapping
        let chars = Array(token)
        var index = 0
        var lead = ""
        while index < chars.count, chars[index].isASCII, chars[index].isNumber {
            lead.append(chars[index])
            index += 1
        }
        guard !lead.isEmpty, lead.count <= 6 else { return nil }

        // Decimal form: "1,5tr" / "2.5k".
        var fraction = ""
        if index < chars.count, chars[index] == "," || chars[index] == "." {
            var probe = index + 1
            var digits = ""
            while probe < chars.count, chars[probe].isASCII, chars[probe].isNumber {
                digits.append(chars[probe])
                probe += 1
            }
            guard !digits.isEmpty else { return nil }
            fraction = digits
            index = probe
        }

        let rest = String(chars[index...])
        var multiplier = 0
        var fractionDigits = 0
        var unitLength = 0
        if rest.hasPrefix("tr") {
            multiplier = 1_000_000
            fractionDigits = 6
            unitLength = 2
        } else if rest.hasPrefix("ty") || rest.hasPrefix("tỷ") {
            multiplier = 1_000_000_000
            fractionDigits = 9
            unitLength = 2
        } else if rest.hasPrefix("k") {
            multiplier = 1_000
            fractionDigits = 3
            unitLength = 1
        } else {
            return nil
        }

        // Compact form: "1tr5" = 1.5 triệu, "1k5" = 1.5 nghìn.
        let trailing = String(rest.dropFirst(unitLength))
        if !trailing.isEmpty {
            guard fraction.isEmpty else { return nil }
            for ch in trailing where !(ch.isASCII && ch.isNumber) { return nil }
            fraction = trailing
        }
        guard fraction.count <= fractionDigits else { return nil }
        let padded = fraction + String(repeating: "0", count: fractionDigits - fraction.count)
        guard let leadValue = Int(lead), let fractionValue = Int(padded) else { return nil }
        return format(leadValue * multiplier + fractionValue) + "đ"
    }

    /// 1500000 -> "1.500.000"
    static func format(_ value: Int) -> String {
        let digits = Array(String(value))
        var result = ""
        for (offset, digit) in digits.enumerated() {
            if offset > 0 && (digits.count - offset) % 3 == 0 { result.append(".") }
            result.append(digit)
        }
        return result
    }
}
