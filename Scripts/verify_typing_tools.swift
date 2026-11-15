import Foundation

@main
struct VerifyTypingTools {
    static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else { fatalError("FAIL [TypingTools] \(message)") }
        print("PASS [TypingTools] \(message)")
    }

    static func main() {
        verifyMoney()
        verifySpelling()
    }

    static func verifyMoney() {
        expect(MoneyShorthand.suggestion(for: "50k") == "50.000đ", "50k -> 50.000đ")
        expect(MoneyShorthand.suggestion(for: "50K") == "50.000đ", "capital K works")
        expect(MoneyShorthand.suggestion(for: "1tr5") == "1.500.000đ", "1tr5 -> 1.500.000đ")
        expect(MoneyShorthand.suggestion(for: "1tr25") == "1.250.000đ", "1tr25 -> 1.250.000đ")
        expect(MoneyShorthand.suggestion(for: "1tr05") == "1.050.000đ", "1tr05 -> 1.050.000đ")
        expect(MoneyShorthand.suggestion(for: "10tr") == "10.000.000đ", "10tr -> 10.000.000đ")
        expect(MoneyShorthand.suggestion(for: "2ty") == "2.000.000.000đ", "2ty -> 2.000.000.000đ")
        expect(MoneyShorthand.suggestion(for: "2ty5") == "2.500.000.000đ", "2ty5 -> 2.500.000.000đ")
        expect(MoneyShorthand.suggestion(for: "1,5tr") == "1.500.000đ", "1,5tr -> 1.500.000đ")
        expect(MoneyShorthand.suggestion(for: "2.5k") == "2.500đ", "2.5k -> 2.500đ")
        expect(MoneyShorthand.suggestion(for: "1k5") == "1.500đ", "1k5 -> 1.500đ")
        expect(MoneyShorthand.suggestion(for: "10m") == nil, "'m' is ambiguous and left alone")
        expect(MoneyShorthand.suggestion(for: "3km") == nil, "km is not money")
        expect(MoneyShorthand.suggestion(for: "5kg") == nil, "kg is not money")
        expect(MoneyShorthand.suggestion(for: "50") == nil, "a bare number is left alone")
        expect(MoneyShorthand.suggestion(for: "k") == nil, "a unit alone is left alone")
        expect(MoneyShorthand.suggestion(for: "1tr1234567") == nil, "too many decimals -> nil")
        expect(MoneyShorthand.lastToken(of: "giá 50k") == "50k", "last token is found")
        expect(MoneyShorthand.lastToken(of: "(50k") == "50k", "opening bracket is ignored")
        expect(MoneyShorthand.lastToken(of: "xin chào") == nil, "a word is not an amount token")
        expect(MoneyShorthand.format(1_234_567) == "1.234.567", "thousands separators")
        expect(MoneyShorthand.format(999) == "999", "no separator below 1000")
    }

    static func verifySpelling() {
        let two = Misspellings.correction(forRawWords: ["Sắp", "sếp"])
        expect(two?.original == "Sắp sếp" && two?.corrected == "Sắp xếp",
               "two-word mistake is fixed and the capital kept")
        let spaced = Misspellings.correction(forRawWords: ["em", "xử", "dụng"])
        expect(spaced?.original == "xử dụng" && spaced?.corrected == "sử dụng",
               "only the mistaken words are replaced")
        let single = Misspellings.correction(forRawWords: ["tôi", "lổi"])
        expect(single?.original == "lổi" && single?.corrected == "lỗi",
               "single-word mistake is fixed")
        let longer = Misspellings.correction(forRawWords: ["xin", "lổi"])
        expect(longer?.corrected == "xin lỗi", "the longer phrase wins")
        expect(Misspellings.correction(forRawWords: ["sử", "dụng"]) == nil,
               "correct spelling gives no suggestion")
        expect(Misspellings.correction(forRawWords: []) == nil, "no words -> none")
        for (wrong, right) in Misspellings.corrections {
            expect(wrong != right, "table entry changes something: \(wrong)")
            expect(wrong == NextWordPredictor.normalize(wrong),
                   "table key is normalised: \(wrong)")
        }
    }
}
