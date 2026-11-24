import Foundation

/// Conservative local checks before sending conversation text to a cloud provider.
/// Always display an explicit preview and let the user decide what to share.
enum MessageSafety {
    static func warnings(in text: String) -> [String] {
        var result: [String] = []
        let lower = text.lowercased()
        if lower.contains("otp") || lower.contains("mã xác minh")
            || lower.contains("mã đăng nhập") || lower.contains("verification code") {
            result.append("Có thể chứa mã xác thực/OTP")
        }
        if matches(#"\b(?:\d[ -]?){12,19}\b"#, text) {
            result.append("Có thể chứa số thẻ hoặc tài khoản dài")
        }
        if lower.contains("mật khẩu:") || lower.contains("password:")
            || lower.contains("api_key") || lower.contains("secret_key") {
            result.append("Có thể chứa mật khẩu hoặc khóa bí mật")
        }
        if matches(#"\b(?:0|\+84)\d{9,10}\b"#, text) {
            result.append("Có thể chứa số điện thoại")
        }
        return result
    }

    static func redacted(_ text: String) -> String {
        var result = text
        let patterns = [
            #"\b(?:\d[ -]?){12,19}\b"#,
            #"\b(?:0|\+84)\d{9,10}\b"#,
            #"(?im)\b(?:password|mật khẩu|api_key|secret_key)\s*[:=]\s*\S+"#,
            #"(?im)\b(?:otp|mã xác minh|mã đăng nhập)\s*[:=]?\s*\d{4,8}\b"#
        ]
        for pattern in patterns {
            result = result.replacingOccurrences(of: pattern, with: "[ĐÃ ẨN]",
                                                 options: .regularExpression)
        }
        return result
    }

    private static func matches(_ pattern: String, _ text: String) -> Bool {
        text.range(of: pattern, options: .regularExpression) != nil
    }
}
