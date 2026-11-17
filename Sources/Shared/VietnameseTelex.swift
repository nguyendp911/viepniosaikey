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
    private static let vowelForms: [Character: [Character]] = {
        var result: [Character: [Character]] = [:]
        for (vowel, forms) in vowels { result[vowel] = Array(forms) }
        return result
    }()
    /// a -> â, e -> ê, o -> ô (the double-letter shapes) and back again.
    private static let doubled: [Character: Character] = ["a": "â", "e": "ê", "o": "ô"]
    private static let undoubled: [Character: Character] = ["â": "a", "ê": "e", "ô": "o"]
    private static let undoW: [Character: Character] = ["ă": "a", "ơ": "o", "ư": "u"]

    // The previous base() scanned 12 vowel tables and allocated a String on
    // every character for every key. Build a single immutable map instead.
    private static let vowelBase: [Character: Character] = {
        var result: [Character: Character] = [:]
        for (vowel, forms) in vowels {
            for character in forms {
                result[character] = vowel
                if let upper = String(character).uppercased().first {
                    result[upper] = vowel
                }
            }
        }
        return result
    }()

    private static func base(_ value: Character) -> Character? {
        vowelBase[value]
    }

    private static func isUpper(_ value: Character) -> Bool {
        let text = String(value)
        return text.uppercased() == text && text.lowercased() != text
    }

    /// Give `output` the same capitalisation as `original`.
    private static func caseLike(_ output: Character, _ original: Character) -> Character {
        isUpper(original) ? Character(String(output).uppercased()) : output
    }

    private static func lower(_ value: Character) -> Character {
        Character(String(value).lowercased())
    }

    /// 0 = no tone, 1...5 = sắc, huyền, hỏi, ngã, nặng.
    private static func toneOf(_ value: Character) -> Int {
        let small = lower(value)
        guard let vowel = vowelBase[small], let forms = vowelForms[vowel] else { return 0 }
        return forms.firstIndex(of: small) ?? 0
    }

    /// The vowel with a different tone, keeping its shape and capitalisation.
    private static func withTone(_ tone: Int, _ value: Character) -> Character {
        let small = lower(value)
        guard let vowel = vowelBase[small], let forms = vowelForms[vowel], tone < forms.count else {
            return value
        }
        return caseLike(forms[tone], value)
    }

    // Accent keys s/f/r/x/j are also ordinary Latin letters. Interpret them
    // as a Vietnamese tone only when the preceding characters can form a
    // Vietnamese syllable. This protects English words such as "store",
    // "stress", "spring", "thanks" from unwanted diacritics.
    private static let vietnameseOnsets: Set<String> = [
        "", "b", "c", "ch", "d", "đ", "g", "gh", "gi", "h", "k", "kh",
        "l", "m", "n", "ng", "ngh", "nh", "p", "ph", "q", "qu",
        "r", "s", "t", "th", "tr", "v", "x"
    ]

    private static let vietnameseCodas: Set<String> = [
        "", "c", "ch", "m", "n", "ng", "nh", "p", "t"
    ]

    private static func plausibleVietnameseSyllable(_ chars: [Character]) -> Bool {
        guard let firstVowel = chars.firstIndex(where: { base($0) != nil }),
              let lastVowel = chars.lastIndex(where: { base($0) != nil }) else {
            return false
        }
        // The vowels of one syllable sit side by side ("banana" is not one).
        if lastVowel > firstVowel {
            for index in firstVowel...lastVowel where base(chars[index]) == nil { return false }
        }
        let onset = String(chars[..<firstVowel]).lowercased()
        let coda = lastVowel + 1 < chars.count
            ? String(chars[(lastVowel + 1)...]).lowercased() : ""
        return vietnameseOnsets.contains(onset) && vietnameseCodas.contains(coda)
    }

    /// The index of the vowel that carries the tone mark, following the
    /// modern rules (hòa, khỏe, thủy, giúp, quý, mùa, sáo, thuở, người):
    /// - "qu" and "gi" are part of the consonant when another vowel follows;
    /// - a vowel with its own mark (ă â ê ô ơ ư) takes the tone, the last one
    ///   in "ươ" / "uyê";
    /// - ai ao au ay eo iu oi ui and ia ua take it on the first vowel, the
    ///   rest (ie, uo, ye...) on the second;
    /// - oa, oe, uy take it on the first vowel only when nothing follows them
    ///   (hòa, khỏe, thủy) and on the second otherwise (toán, khoét, huỳnh);
    /// - three vowels: the middle one (ngoài, khuỷu, oai).
    static func tonePosition(in chars: [Character]) -> Int? {
        var idx = chars.indices.filter { base(chars[$0]) != nil }
        guard let first = idx.first else { return nil }
        if idx.count > 1, first > 0 {
            let before = lower(chars[first - 1])
            let vowel = base(chars[first])
            if (before == "q" && vowel == "u") || (before == "g" && vowel == "i") {
                idx.removeFirst()
            }
        }
        if idx.count == 1 { return idx[0] }
        if let marked = idx.last(where: { "ăâêôơư".contains(base(chars[$0]) ?? " ") }) {
            return marked
        }
        let bases = idx.compactMap { base(chars[$0]) }
        switch idx.count {
        case 2:
            let pair = String(bases)
            if pair == "oa" || pair == "oe" || pair == "uy" {
                return idx[1] + 1 < chars.count ? idx[1] : idx[0]
            }
            if pair == "uo" { return idx[1] }
            if pair == "ia" || pair == "ua" { return idx[0] }
            if "iyuo".contains(bases[1]) { return idx[0] }
            return idx[1]
        case 3:
            return idx[1]
        default:
            return idx.last
        }
    }

    /// Change the shape while preserving any tone already applied.
    private static func restyle(_ original: Character, as newBase: Character) -> Character {
        let small = lower(original)
        let oldBase = base(small) ?? newBase
        let oldForms = vowelForms[oldBase] ?? []
        let newForms = vowelForms[newBase] ?? []
        let tone = oldForms.firstIndex(of: small) ?? 0
        let output = tone < newForms.count ? newForms[tone] : newBase
        return caseLike(output, original)
    }

    private static func followsQ(_ letters: [Character], _ index: Int) -> Bool {
        index > 0 && lower(letters[index - 1]) == "q"
    }

    /// Users may type "thuongw", "truongw", "muaw" without placing W next to
    /// the vowel. Always prioritize the uo -> ươ syllable pattern.
    private static func shiftedW(in letters: [Character]) -> String? {
        guard !letters.isEmpty else { return nil }
        var output = letters
        if letters.count >= 2 {
            for index in 0..<(letters.count - 1) where !followsQ(letters, index) {
                if base(letters[index]) == "u", base(letters[index + 1]) == "o" {
                    // A bare "uo" at the end is "uơ" (thuở, huơ); the u turns
                    // into ư later if i, u or a final consonant follows.
                    if index + 2 < letters.count {
                        output[index] = restyle(letters[index], as: "ư")
                    }
                    output[index + 1] = restyle(letters[index + 1], as: "ơ")
                    if output != letters { return String(output) }
                }
            }
            // For "mua" + w, the a is the vowel nucleus, while u becomes ư.
            for index in 0..<(letters.count - 1) where !followsQ(letters, index) {
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

    /// Rebuild the displayed word from its original key sequence. Unlike
    /// incremental edits this can revoke an earlier Telex conversion when the
    /// completed word is clearly English, without losing the original keys.
    static func composeKeys(_ raw: String) -> String {
        var rendered = ""
        for char in raw {
            let key = String(char)
            if let converted = transformed(word: rendered, key: key) {
                rendered = converted
            } else {
                rendered.append(char)
                rendered = normalizedTonePosition(rendered) ?? rendered
            }
        }
        return rendered
    }

    /// Keep a previously typed tone on the correct vowel when more letters
    /// are appended. This makes early and late Telex tone keys equivalent.
    /// Only touch a single existing tone in a plausible Vietnamese syllable.
    static func normalizedTonePosition(_ word: String) -> String? {
        var chars = Array(word)
        guard chars.count > 1, chars.count <= 40,
              plausibleVietnameseSyllable(chars) else { return nil }
        var changed = false
        // "uơ" followed by more letters is really "ươ": thuơ + ng, tuơ + i.
        if chars.count >= 3 {
            for index in 0..<(chars.count - 2)
            where base(chars[index]) == "u" && base(chars[index + 1]) == "ơ"
                && !followsQ(chars, index) {
                chars[index] = restyle(chars[index], as: "ư")
                changed = true
                break
            }
        }
        let vowelIndices = chars.indices.filter { base(chars[$0]) != nil }
        let marked = vowelIndices.filter { toneOf(chars[$0]) > 0 }
        guard marked.count == 1, let old = marked.first,
              let target = tonePosition(in: chars), target != old else {
            return changed ? String(chars) : nil
        }
        let tone = toneOf(chars[old])
        chars[old] = withTone(0, chars[old])
        chars[target] = withTone(tone, chars[target])
        return String(chars)
    }

    /// Undo the shape of the last ă / ơ / ư, so that a second W types a
    /// literal w: thuw + w -> thuw.
    private static func revertedW(_ chars: [Character]) -> String? {
        for index in chars.indices.reversed() {
            guard let vowel = base(chars[index]), let plain = undoW[vowel] else { continue }
            var output = chars
            output[index] = withTone(toneOf(chars[index]), caseLike(plain, chars[index]))
            return String(output)
        }
        return nil
    }

    /// Returns nil when the typed key should be inserted literally.
    static func transformed(word: String, key: String) -> String? {
        guard word.count <= 40, let letter = key.first, key.count == 1 else { return nil }
        let code = lower(letter)
        let chars = Array(word)
        guard !chars.isEmpty else { return nil }

        // Telex W can be typed at the end of the whole syllable, not just
        // immediately after the vowel: "thuongw" -> "thương".
        if code == "w" {
            let hasShape = chars.contains { "ăơư".contains(base($0) ?? " ") }
            let pendingO = chars.indices.dropLast().contains {
                base(chars[$0]) == "ư" && base(chars[$0 + 1]) == "o"
            }
            if !hasShape || pendingO, let shifted = shiftedW(in: chars) {
                return normalizedTonePosition(shifted) ?? shifted
            }
            // The word already has its ă/ơ/ư: a second w undoes it.
            if hasShape, let reverted = revertedW(chars) { return reverted + key }
            return nil
        }

        let last = chars[chars.count - 1]

        // dd -> đ, and a third d goes back to dd.
        if code == "d" {
            if lower(last) == "d" {
                var result = chars
                result[result.count - 1] = caseLike("đ", last)
                return String(result)
            }
            if lower(last) == "đ" {
                var result = chars
                result[result.count - 1] = caseLike("d", last)
                return String(result) + key
            }
        }

        // aa / ee / oo -> â ê ô, also right after a tone ("tos" + o), and a
        // third key goes back: oo + o -> oo.
        if let doubledShape = doubled[code], let vowel = base(last) {
            if vowel == code, plausibleVietnameseSyllable(chars) {
                var result = chars
                result[result.count - 1] = restyle(last, as: doubledShape)
                return String(result)
            }
            if let plain = undoubled[vowel], plain == code {
                var result = chars
                result[result.count - 1] = restyle(last, as: plain)
                return String(result) + key
            }
        }

        if code == "z" {
            // Remove the tone of the rightmost accented vowel without
            // removing its Telex shape. If no tone exists, insert z normally.
            for index in chars.indices.reversed() {
                guard base(chars[index]) != nil, toneOf(chars[index]) > 0 else { continue }
                var output = chars
                output[index] = withTone(0, chars[index])
                return String(output)
            }
        }

        guard let targetTone = toneIndex[code],
              plausibleVietnameseSyllable(chars),
              let chosen = tonePosition(in: chars) else { return nil }
        var output = chars
        // One tone per syllable: drop a tone left on any other vowel.
        for index in chars.indices where index != chosen && base(chars[index]) != nil
            && toneOf(chars[index]) > 0 {
            output[index] = withTone(0, chars[index])
        }
        // A repeated tone key escapes the previous tone, allowing literal
        // English text even in Vietnamese-only mode: o+r => ỏ, ỏ+r => or.
        // Keep the second physical key as the literal suffix; otherwise the
        // user cannot recover "or" by pressing r again.
        if toneOf(chars[chosen]) == targetTone {
            output[chosen] = withTone(0, chars[chosen])
            return String(output) + key
        }
        output[chosen] = withTone(targetTone, chars[chosen])
        return output == chars ? nil : String(output)
    }
}
