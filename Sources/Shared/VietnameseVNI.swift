import Foundation

/// Lightweight VNI typing complement to the existing Telex engine.
/// VNI follows numeric suffixes, preserving the word in the host app.
enum VietnameseVNI {
    private static let vowelGroups: [String] = [
        "aáàảãạ", "ăắằẳẵặ", "âấầẩẫậ",
        "eéèẻẽẹ", "êếềểễệ",
        "iíìỉĩị",
        "oóòỏõọ", "ôốồổỗộ", "ơớờởỡợ",
        "uúùủũụ", "ưứừửữự", "yýỳỷỹỵ"
    ]

    private static func base(_ ch: Character) -> (Int, Int)? {
        let lower = String(ch).lowercased()
        for (group, vowels) in vowelGroups.enumerated() {
            let chars = Array(vowels)
            if let position = chars.firstIndex(where: { String($0) == lower }) { return (group, position) }
        }
        return nil
    }

    static func transformed(word: String, key: String) -> String? {
        guard word.count <= 40, let digit = key.first, key.count == 1,
              "0123456789".contains(digit) else { return nil }
        var chars = Array(word)
        let vowelIndices = chars.indices.filter { base(chars[$0]) != nil }
        if digit == "9" {
            // VNI 9 can be entered after the complete word: da9 -> đa.
            // Only modify a leading d; never alter an arbitrary middle letter.
            if let index = chars.indices.first, String(chars[index]).lowercased() == "d" {
                chars[index] = String(chars[index]).uppercased() == String(chars[index]) ? "Đ" : "đ"
                return String(chars)
            }
            return nil
        }
        guard !vowelIndices.isEmpty else { return nil }
        if digit == "7" && chars.count >= 2 {
            // In VNI, a trailing 7 shapes the complete "uo" nucleus:
            // duong7 -> dương, thuong7 -> thương. A single trailing 7
            // should not be consumed a second time when already shaped.
            for index in 0..<(chars.count - 1) {
                guard let left = base(chars[index]),
                      let right = base(chars[index + 1]),
                      left.0 == 9, right.0 == 6 else { continue }
                let leftForm = Array(vowelGroups[10])[left.1]
                let rightForm = Array(vowelGroups[8])[right.1]
                chars[index] = String(chars[index]).uppercased() == String(chars[index])
                    ? Character(String(leftForm).uppercased()) : leftForm
                chars[index + 1] = String(chars[index + 1]).uppercased() == String(chars[index + 1])
                    ? Character(String(rightForm).uppercased()) : rightForm
                return String(chars)
            }
        }
        if digit == "0" {
            // 0 removes a tone while keeping its vowel shape (VNI convention).
            guard let index = vowelIndices.first(where: { (base(chars[$0])?.1 ?? 0) > 0 }),
                  let (group, _) = base(chars[index]) else { return nil }
            let plain = Array(vowelGroups[group])[0]
            chars[index] = String(chars[index]).uppercased() == String(chars[index])
                ? Character(String(plain).uppercased()) : plain
            return String(chars)
        }
        let index: Int
        let shaped = vowelIndices.filter { base(chars[$0]).map { [1, 2, 4, 7, 8, 10].contains($0.0) } ?? false }
        if let selected = shaped.last { index = selected }
        else if vowelIndices.count > 1,
                let last = vowelIndices.last,
                "iuy".contains(Character(String(chars[last]).lowercased())),
                let previous = vowelIndices.dropLast().last { index = previous }
        else { index = vowelIndices.last! }
        guard let pair = base(chars[index]) else { return nil }
        var group = pair.0
        var tone = pair.1
        if let value = digit.wholeNumberValue, (1...5).contains(value) {
            tone = value
        } else if digit == "6" {
            guard [0, 3, 6].contains(group) else { return nil }
            group = [0: 2, 3: 4, 6: 7][group]!
        } else if digit == "7" {
            guard [6, 9].contains(group) else { return nil }
            group = [6: 8, 9: 10][group]!
        } else if digit == "8" {
            guard group == 0 else { return nil }
            group = 1
        } else { return nil }
        let transformed = Array(vowelGroups[group])[tone]
        if String(chars[index]).uppercased() == String(chars[index]) {
            chars[index] = Character(String(transformed).uppercased())
        } else {
            chars[index] = transformed
        }
        return String(chars)
    }
}
