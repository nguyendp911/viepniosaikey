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
        test("thuongws", expected: "thướng")
        test("nguoifw", expected: "người")
        test("thuwowng", expected: "thương")
        test("ddaay", expected: "đây")
        test("a", expected: "a")
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
