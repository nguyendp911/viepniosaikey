import Foundation

@main
struct VerifyVNI {
    static func main() {
        func expect(_ word: String, _ digit: String, _ expected: String?) {
            let actual = VietnameseVNI.transformed(word: word, key: digit)
            precondition(actual == expected,
                "VNI: \(word)+\(digit) => \(actual ?? "nil"), expected \(expected ?? "nil")")
        }
        expect("da", "9", "đa")
        expect("Da", "9", "Đa")
        expect("d", "9", "đ")
        expect("abc", "9", nil)
        expect("ban", "2", "bàn")
        expect("bàn", "0", "ban")
        expect("ban", "1", "bán")
        expect("bán", "0", "ban")
        expect("a", "6", "â")
        expect("a", "8", "ă")
        expect("o", "6", "ô")
        expect("o", "7", "ơ")
        expect("u", "7", "ư")
        expect("duong", "7", "dương")
        expect("Duong", "7", "Dương")
        expect("thuong", "7", "thương")
        expect("dương", "7", nil)
        expect("hello", "0", nil)
        expect("hello", "9", nil)
        expect("abc", "2", "àbc")
        print("PASS [VNI] tones, shapes, end-position d9, undo tone with 0")
    }
}
