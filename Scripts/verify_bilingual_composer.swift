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
        check("or", "or")
        check("Or", "Or")
        check("orr", "or", .vietnamese)
        check("ỏr", "or", .vietnamese)
        check("or", "ỏ", .vietnamese)
        check("or", "or", .english)
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
        // Regression: model the exact keyboard hot path, including the
        // no-diff branch. Every physical touch must result in a visible
        // insertion or a deliberate Telex transformation, never a lost key.
        func simulateTouches(_ raw: String,
                             preference: BilingualComposer.Preference = .automatic) -> String {
            var pressed = ""
            var candidate = ""
            var displayed = ""
            for letter in raw {
                let key = String(letter)
                pressed += key
                let nextCandidate = BilingualComposer.appendCandidate(candidate, key: key)
                let next = BilingualComposer.choose(
                    raw: pressed, vietnameseCandidate: nextCandidate,
                    preference: preference).rendered
                if let edit = FastTyping.edit(from: displayed, to: next) {
                    guard edit.deleteCount <= displayed.count else {
                        fatalError("Bad edit size for \\(pressed)")
                    }
                    displayed = String(displayed.dropLast(edit.deleteCount)) + edit.insertion
                    candidate = nextCandidate
                } else {
                    // Same behavior as the literal-touch fallback in the UI.
                    displayed += key
                    // A literal display does not change the independent
                    // Telex candidate a second time.
                    candidate = nextCandidate
                }
                guard !displayed.isEmpty else {
                    fatalError("Lost a key when typing \\(pressed)")
                }
            }
            return displayed
        }
        for (raw, expected) in [
            ("tooi", "tôi"), ("tool", "tool"), ("store", "store"),
            ("thuongw", "thương"), ("thuongwf", "thường"),
            ("vieets", "viết"), ("banf", "bàn"),
            ("book", "book"), ("thanks", "thanks")
        ] {
            let actual = simulateTouches(raw)
            guard actual == expected else {
                fatalError("Touch stream mismatch for \\(raw): \\(actual) != \\(expected)")
            }
        }
        print("PASS [Bilingual] keyboard touch stream regression")

        // Backspace removes one physical key, not merely one visible scalar.
        // This makes "tôi" -> "too" and "thương" -> "thuong" reversible.
        func testBackspace(_ raw: String, preference: BilingualComposer.Preference = .automatic) {
            var keys = raw
            var rendered = BilingualComposer.compose(keys, preference: preference).rendered
            while !keys.isEmpty {
                let prior = BilingualComposer.removingLastKey(
                    from: keys, preference: preference).rendered
                guard let edit = FastTyping.edit(from: rendered, to: prior) else {
                    fatalError("Backspace did not change rendered text for \\(keys)")
                }
                let actual = String(rendered.dropLast(edit.deleteCount)) + edit.insertion
                guard actual == prior else {
                    fatalError("Backspace edit mismatch: \\(keys)")
                }
                keys.removeLast()
                rendered = actual
                guard rendered == BilingualComposer.compose(
                    keys, preference: preference).rendered else {
                    fatalError("Backspace composition mismatch for \\(keys)")
                }
            }
            print("PASS [Bilingual] reversible backspace \\(raw)")
        }
        for raw in ["tooi", "thuongw", "thuongwf", "vieets", "banf",
                    "store", "book", "boos", "ddaay", "tool"] {
            testBackspace(raw)
        }
        testBackspace("tooi", preference: .vietnamese)
        testBackspace("store", preference: .english)

        // Fast path must be bit-for-bit identical to full composition on every
        // intermediate key, including Telex removal and language reversals.
        let samples = [
            "tooi", "Tooi", "tool", "book", "boos", "car", "care",
            "store", "street", "stress", "strong", "thanks",
            "vieets", "tieengs", "thuongw", "thuongwf",
            "nguoifw", "ddaw", "ddaay", "muaw", "thos", "mafr",
            "Hello", "Facebook", "Vietnam", "orange", "google",
            "xin", "chaof", "banf", "troi", "hieeur"
        ]
        for raw in samples {
            for pref: BilingualComposer.Preference in [.automatic, .vietnamese, .english] {
                var keys = ""
                var candidate = ""
                for letter in raw {
                    let key = String(letter)
                    keys += key
                    candidate = BilingualComposer.appendCandidate(candidate, key: key)
                    let optimized = BilingualComposer.choose(
                        raw: keys, vietnameseCandidate: candidate,
                        preference: pref).rendered
                    let reference = BilingualComposer.compose(keys, preference: pref).rendered
                    guard optimized == reference else {
                        fatalError("Incremental mismatch: \\(keys), pref \\(pref), \\(optimized) vs \\(reference)")
                    }
                }
            }
            print("PASS [Bilingual] fast-path parity \\(raw)")
        }

        // 1,200 reproducible touch streams with diacritic keys, ordinary
        // English letters and backspaces. Check actual incremental edits
        // against the reference composer on each physical key.
        var seed: UInt64 = 0x564945504E
        let alphabet = Array("abcdeghiklmnooprstuvwxyz")
        for caseNumber in 0..<1200 {
            let wordLength = 3 + (caseNumber % 10)
            var raw = ""
            var candidate = ""
            var visible = ""
            for _ in 0..<wordLength {
                seed = seed &* 6364136223846793005 &+ 1442695040888963407
                let key = String(alphabet[Int((seed >> 24) % UInt64(alphabet.count))])
                raw += key
                candidate = BilingualComposer.appendCandidate(candidate, key: key)
                let expected = BilingualComposer.compose(raw, preference: .vietnamese).rendered
                let next = BilingualComposer.choose(
                    raw: raw, vietnameseCandidate: candidate,
                    preference: .vietnamese).rendered
                guard expected == next else {
                    fatalError("Stress parity mismatch for \\(raw)")
                }
                if let edit = FastTyping.edit(from: visible, to: next) {
                    guard edit.deleteCount <= visible.count else {
                        fatalError("Invalid deletion count for \\(raw)")
                    }
                    visible = String(visible.dropLast(edit.deleteCount)) + edit.insertion
                } else {
                    // Correctly unchanged transformations are not missing keys.
                    // A physical key may be consumed by the composer.
                    visible = next
                }
                guard visible == expected else {
                    fatalError("Stress edit mismatch for \\(raw)")
                }
            }
            // Check that backspacing through every key restores exact states.
            while !raw.isEmpty {
                let restored = BilingualComposer.removingLastKey(from: raw,
                    preference: .vietnamese).rendered
                guard let edit = FastTyping.edit(from: visible, to: restored) else {
                    if visible != restored { fatalError("Stress backspace mismatch") }
                    raw.removeLast()
                    continue
                }
                visible = String(visible.dropLast(edit.deleteCount)) + edit.insertion
                raw.removeLast()
                guard visible == restored else { fatalError("Stress backspace mismatch") }
            }
        }
        print("PASS [Bilingual] 1,200 deterministic typing/backspace streams")
    }
}
