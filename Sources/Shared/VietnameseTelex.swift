import Foundation

/// Simple inline Telex composition for Vietnamese text.
/// Converts only when a Telex suffix is typed; never sends keyboard input away.
enum VietnameseTelex {
    private static let toneIndex: [Character: Int] = ["s": 1, "f": 2, "r": 3, "x": 4, "j": 5]
    private static let vowels: [Character: String] = [
        "a":"aáàảãạ", "ă":"ăắằẳẵặ", "â":"âấầẩẫậ",
        "e":"eéèẻẽẹ", "ê":"êếềểễệ",
        "i":"iíìỉĩị",
        "o":"oóòỏõọ", "ô":"ôốồổỗộ", "ơ":"ơớờởỡợ",
        "u":"uúùủũụ", "ư":"ưứừửữự",
        "y":"yýỳỷỹỵ"
    ]
    private static let shape: [String: Character] = [
        "aa":"â", "ee":"ê", "oo":"ô", "dd":"đ",
        "aw":"ă", "ow":"ơ", "uw":"ư"
    ]

    private static func base(_ value: Character) -> Character? {
        let lower = Character(String(value).lowercased())
        for (vowel, sequence) in vowels where sequence.contains(lower) {
            return vowel
        }
        return nil
    }

    /// Change the shape while preserving any tone already applied.
    private static func restyle(_ original: Character, as newBase: Character) -> Character {
        let lower = Character(String(original).lowercased())
        let oldBase = base(lower) ?? newBase
        let oldForms = Array(vowels[oldBase] ?? "")
        let newForms = Array(vowels[newBase] ?? "")
        let tone = oldForms.firstIndex(of: lower) ?? 0
        let output = tone < newForms.count ? newForms[tone] : newBase
        return String(original).uppercased() == String(original)
            ? Character(String(output).uppercased()) : output
    }

    /// Users may type "thuongw", "truongw", "muaw" without placing W next to
    /// the vowel. Always prioritize the uo -> ươ syllable pattern.
    private static func shiftedW(in letters: [Character]) -> String? {
        guard !letters.isEmpty else { return nil }
        var output = letters
        if letters.count >= 2 {
            for index in 0..<(letters.count - 1) {
                if base(letters[index]) == "u", base(letters[index + 1]) == "o" {
                    output[index] = restyle(letters[index], as: "ư")
                    output[index + 1] = restyle(letters[index + 1], as: "ơ")
                    if output != letters { return String(output) }
                }
            }
            // For "mua" + w, the a is the vowel nucleus, while u becomes ư.
            for index in 0..<(letters.count - 1) {
                if base(letters[index]) == "u", base(letters[index + 1]) == "a" {
                    output[index] = restyle(letters[index], as: "ư")
                    if output != letters { return String(output) }
                }
            }
        }
        for index in letters.indices.reversed() {
            guard let oldBase = base(letters[index]) else { continue }
            let target: Character
            switch oldBase {
            case "u": target = "ư"
            case "o": target = "ơ"
            case "a": target = "ă"
            default: continue
            }
            output[index] = restyle(letters[index], as: target)
            if output != letters { return String(output) }
        }
        return nil
    }

    /// Returns nil when the typed key should be inserted literally.
    static func transformed(word: String, key: String) -> String? {
        guard word.count <= 40, let letter = key.first, key.count == 1 else { return nil }
        let code = Character(String(letter).lowercased())
        let chars = Array(word)
        guard !chars.isEmpty else { return nil }

        // Telex W can be typed at the end of the whole syllable, not just
        // immediately after the vowel: "thuongw" -> "thương".
        if code == "w", let shifted = shiftedW(in: chars) {
            return shifted
        }

        // Other Telex double-letter shape keys still work as before.
        let previous = String(chars[chars.count - 1]).lowercased()
        let pair = previous + String(code)
        if let replacement = shape[pair] {
            var result = chars
            let output = String(chars.last!).uppercased() == String(chars.last!)
                ? Character(String(replacement).uppercased()) : replacement
            result[result.count - 1] = output
            return String(result)
        }

        if code == "z" {
            // Remove the tone of the rightmost accented vowel without
            // removing its Telex shape. If no tone exists, insert z normally.
            for index in chars.indices.reversed() {
                guard let vowel = base(chars[index]), let sequence = vowels[vowel],
                      let offset = sequence.firstIndex(of: Character(String(chars[index]).lowercased()))
                else { continue }
                let tone = sequence.distance(from: sequence.startIndex, to: offset)
                if tone == 0 { continue }
                var output = chars
                let original = vowel
                output[index] = String(chars[index]).uppercased() == String(chars[index])
                    ? Character(String(original).uppercased()) : original
                return String(output)
            }
        }

        guard let targetTone = toneIndex[code] else { return nil }
        let indices = chars.indices.filter { base(chars[$0]) != nil }
        guard !indices.isEmpty else { return nil }

        // Favor shaped vowels, then central vowels. In e.g. "lai", the final i
        // is a glide so the tone belongs on a rather than i.
        let shaped = indices.filter { index in
            guard let vowel = base(chars[index]) else { return false }
            return "ăâêôơư".contains(vowel)
        }
        let chosen: Int
        if let marked = shaped.last {
            chosen = marked
        } else if indices.count > 1,
                  let last = indices.last,
                  "iuy".contains(Character(String(chars[last]).lowercased())),
                  let prior = indices.dropLast().last {
            chosen = prior
        } else {
            chosen = indices.last!
        }
        guard let vowel = base(chars[chosen]), let sequence = vowels[vowel] else { return nil }
        var output = chars
        let marked = Array(sequence)[targetTone]
        output[chosen] = String(chars[chosen]).uppercased() == String(chars[chosen])
            ? Character(String(marked).uppercased()) : marked
        if output[chosen] == chars[chosen] { return nil }
        return String(output)
    }
}
