import Foundation

@main
struct VerifyBilingualComposer {
    static func main() {
        func check(_ raw: String, _ expected: String,
                   _ preference: BilingualComposer.Preference = .automatic) {
            let result = BilingualComposer.compose(raw, preference: preference)
            guard result.rendered == expected else {
                fatalError("Bilingual: \(raw) -> \(result.rendered), expected \(expected)")
            }
            print("PASS [Bilingual] \(raw) -> \(expected)")
        }
        // Whole-word disambiguation: these pairs share live prefixes.
        check("tooi", "tôi")
        check("Tooi", "Tôi")
        check("tool", "tool")
        check("too", "too")
        check("book", "book")
        check("boo", "boo")
        check("boos", "bố")
        check("coong", "công")
        check("store", "store")
        check("Store", "Store")
        check("story", "story")
        check("street", "street")
        check("stress", "stress")
        check("spring", "spring")
        check("thanks", "thanks")
        check("start", "start")
        check("stop", "stop")
        check("coffee", "coffee")
        check("facebook", "facebook")
        check("keyboard", "keyboard")
        check("hello", "hello")
        check("windows", "windows")
        check("vieets", "viết")
        check("tieengs", "tiếng")
        check("thuongw", "thương")
        check("thuongwf", "thường")
        check("truongw", "trương")
        check("ddaay", "đây")
        check("banf", "bàn")
        check("thos", "thó")
        check("car", "car")
        check("care", "care")
        // User overrides: explicit Vietnamese and literal English.
        check("tooi", "tôi", .vietnamese)
        check("tooi", "tooi", .english)
        check("book", "book", .english)
        // Ensure the per-key decisions can reverse without lost characters.
        func incremental(_ raw: String, expected: String) {
            var keys = ""
            var rendered = ""
            for character in raw {
                keys.append(character)
                let next = BilingualComposer.compose(keys).rendered
                if let edit = FastTyping.edit(from: rendered, to: next) {
                    let old = Array(rendered)
                    guard edit.deleteCount <= old.count else {
                        fatalError("Invalid edit size")
                    }
                    rendered = String(old.dropLast(edit.deleteCount)) + edit.insertion
                }
                guard rendered == next else { fatalError("Partial edit mismatch") }
            }
            guard rendered == expected else { fatalError("Wrong final value for \(raw)") }
            print("PASS [Bilingual] reversible \(raw)")
        }
        incremental("tooi", expected: "tôi")
        incremental("book", expected: "book")
        incremental("store", expected: "store")
        incremental("thuongwf", expected: "thường")
    }
}
