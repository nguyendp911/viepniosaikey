import Foundation

@main
struct VerifyVietnameseTelex {
    static func main() {
        func test(_ typed: String, expected: String) {
            var word = ""
            for key in typed {
                let input = String(key)
                if let output = VietnameseTelex.transformed(word: word, key: input) {
                    word = output
                } else {
                    word += input
                    word = VietnameseTelex.normalizedTonePosition(word) ?? word
                }
            }
            guard word == expected else {
                fatalError("Telex: \(typed) -> \(word), expected \(expected)")
            }
            print("PASS [Telex] \(typed) -> \(word)")
        }
        test("thuongw", expected: "thương")
        test("Thuongw", expected: "Thương")
        test("truongw", expected: "trương")
        test("duongw", expected: "dương")
        test("muaw", expected: "mưa")
        test("thuw", expected: "thư")
        test("cow", expected: "cơ")
        test("banw", expected: "băn")
        test("thuongwf", expected: "thường")
        test("thuongfw", expected: "thường")
        test("thuowngf", expected: "thường")
        test("thuowfng", expected: "thường")
        test("hof a".replacingOccurrences(of: " ", with: ""), expected: "hòa")
        test("thuongws", expected: "thướng")
        test("nguoifw", expected: "người")
        test("thuwowng", expected: "thương")
        test("ddaay", expected: "đây")
        test("a", expected: "a")
        // In Vietnamese-only mode a tone key may produce a single accented
        // vowel, but pressing the same key again must escape to literal text.
        test("or", expected: "ỏ")
        test("orr", expected: "or")
        test("ỏr", expected: "or")
        test("Or", expected: "Ỏ")
        test("Orr", expected: "Or")
        test("banrr", expected: "banr")
        test("banff", expected: "banf")
        test("vietnam", expected: "vietnam")
        // Regressions: Telex tone letters are literal in English-looking
        // consonant clusters or final consonants that Vietnamese cannot have.
        test("store", expected: "store")
        test("Store", expected: "Store")
        test("story", expected: "story")
        test("stress", expected: "stress")
        test("street", expected: "street")
        test("spring", expected: "spring")
        test("strong", expected: "strong")
        test("thanks", expected: "thanks")
        test("start", expected: "start")
        test("stop", expected: "stop")
        test("thos", expected: "thó")
        test("mafr", expected: "mả")
    }
}
