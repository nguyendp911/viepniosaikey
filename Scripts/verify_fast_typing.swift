import Foundation

@main
struct VerifyFastTyping {
    static func check(_ old: String, _ new: String,
                      deletes: Int, insertion: String) {
        guard let edit = FastTyping.edit(from: old, to: new),
              edit.deleteCount == deletes,
              edit.insertion == insertion else {
            fatalError("Incorrect minimal Telex edit: \(old) => \(new)")
        }
        let prefix = Array(old).dropLast(edit.deleteCount)
        let recomposed = String(prefix) + edit.insertion
        guard recomposed == new else { fatalError("Edit did not produce desired text") }
        print("PASS [FastTyping] \(old) -> \(new): \(deletes) deletion(s)")
    }

    static func main() {
        check("thuong", "thương", deletes: 4, insertion: "ương")
        check("Thuong", "Thương", deletes: 4, insertion: "ương")
        check("a", "â", deletes: 1, insertion: "â")
        check("nguoif", "người", deletes: 4, insertion: "ười")
        check("abc", "abd", deletes: 1, insertion: "d")
        guard FastTyping.edit(from: "xin", to: "xin") == nil else {
            fatalError("Identical word must not rewrite anything")
        }
        for modifier in ["a", "e", "o", "d", "w", "s", "f", "r", "x", "j", "z", "W"] {
            guard FastTyping.isTelexModifier(modifier) else {
                fatalError("Missing Telex modifier \(modifier)")
            }
        }
        for letter in ["t", "h", "u", "n", "g", "m", "k", "i", "p", "b", "1", "!"] {
            guard !FastTyping.isTelexModifier(letter) else {
                fatalError("Ordinary key unexpectedly enters Telex slow path: \(letter)")
            }
        }
        print("PASS [FastTyping] Ordinary letters bypass Telex context lookup")
    }
}
