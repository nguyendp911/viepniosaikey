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
        test("hofa", expected: "hòa")
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

        // Real words whose tone used to land on the wrong vowel or that could
        // not be typed at all.
        let words: [(String, String)] = [
            ("giups", "giúp"), ("giupj", "giụp"), ("giaos", "giáo"), ("giaf", "già"),
            ("gif", "gì"), ("ginf", "gìn"), ("gioir", "giỏi"), ("giuwx", "giữ"),
            ("quys", "quý"), ("quas", "quá"), ("quaan", "quân"), ("quoocs", "quốc"),
            ("quyeenf", "quyền"), ("quowr", "quở"),
            ("thuyr", "thủy"), ("hoaf", "hòa"), ("hoas", "hóa"), ("khoer", "khỏe"),
            ("toans", "toán"), ("hoangf", "hoàng"), ("huynhf", "huỳnh"), ("khoets", "khoét"),
            ("muaf", "mùa"), ("cuar", "của"), ("bias", "bía"), ("kiaf", "kìa"),
            ("saos", "sáo"), ("eos", "éo"),
            ("ddepj", "đẹp"), ("ddaaus", "đấu"), ("ddieeuf", "điều"),
            ("thuowr", "thuở"), ("huow", "huơ"), ("tuowi", "tươi"), ("tuoiw", "tươi"),
            ("thuowng", "thương"), ("nguoiwf", "người"), ("tuwowngr", "tưởng"),
            ("nhieeuf", "nhiều"), ("yeeu", "yêu"), ("chuyeenj", "chuyện"),
            ("nghieeng", "nghiêng"), ("tuyeenr", "tuyển"), ("luaatj", "luật"),
            ("vieetj", "việt"), ("nuwowcs", "nước"), ("dduwowcj", "được"),
            ("muoons", "muốn"), ("buoonf", "buồn"), ("ngoaif", "ngoài"),
            ("cuooir", "cuổi"), ("Giups", "Giúp"), ("QUYS", "QUÝ"), ("DDaay", "Đây"),
            ("thuww", "thuw"), ("tooo", "too"), ("ddd", "dd"), ("aaa", "aa"),
            ("hoasn", "hoán"), ("hosa", "hóa"), ("tosa", "tóa")
        ]
        for (typed, expected) in words { test(typed, expected: expected) }

        // Every syllable shape: onset x nucleus x final consonant x tone, with
        // the tone key typed after the word and straight after the vowels.
        struct Nucleus {
            let typed: [String]
            let shown: String
            let toneAt: Int
            let open: Bool?   // true: only without final consonant, false: only with
        }
        let nuclei: [Nucleus] = [
            Nucleus(typed: ["a"], shown: "a", toneAt: 0, open: nil),
            Nucleus(typed: ["aw"], shown: "ă", toneAt: 0, open: nil),
            Nucleus(typed: ["aa"], shown: "â", toneAt: 0, open: nil),
            Nucleus(typed: ["e"], shown: "e", toneAt: 0, open: nil),
            Nucleus(typed: ["ee"], shown: "ê", toneAt: 0, open: nil),
            Nucleus(typed: ["i"], shown: "i", toneAt: 0, open: nil),
            Nucleus(typed: ["o"], shown: "o", toneAt: 0, open: nil),
            Nucleus(typed: ["oo"], shown: "ô", toneAt: 0, open: nil),
            Nucleus(typed: ["ow"], shown: "ơ", toneAt: 0, open: nil),
            Nucleus(typed: ["u"], shown: "u", toneAt: 0, open: nil),
            Nucleus(typed: ["uw"], shown: "ư", toneAt: 0, open: nil),
            Nucleus(typed: ["y"], shown: "y", toneAt: 0, open: nil),
            Nucleus(typed: ["ai"], shown: "ai", toneAt: 0, open: nil),
            Nucleus(typed: ["ao"], shown: "ao", toneAt: 0, open: nil),
            Nucleus(typed: ["au"], shown: "au", toneAt: 0, open: nil),
            Nucleus(typed: ["ay"], shown: "ay", toneAt: 0, open: nil),
            Nucleus(typed: ["eo"], shown: "eo", toneAt: 0, open: nil),
            Nucleus(typed: ["iu"], shown: "iu", toneAt: 0, open: nil),
            Nucleus(typed: ["oi"], shown: "oi", toneAt: 0, open: nil),
            Nucleus(typed: ["ui"], shown: "ui", toneAt: 0, open: nil),
            Nucleus(typed: ["ia"], shown: "ia", toneAt: 0, open: nil),
            Nucleus(typed: ["ua"], shown: "ua", toneAt: 0, open: nil),
            Nucleus(typed: ["oa"], shown: "oa", toneAt: 0, open: true),
            Nucleus(typed: ["oa"], shown: "oa", toneAt: 1, open: false),
            Nucleus(typed: ["oe"], shown: "oe", toneAt: 0, open: true),
            Nucleus(typed: ["oe"], shown: "oe", toneAt: 1, open: false),
            Nucleus(typed: ["uy"], shown: "uy", toneAt: 0, open: true),
            Nucleus(typed: ["uy"], shown: "uy", toneAt: 1, open: false),
            Nucleus(typed: ["aau"], shown: "âu", toneAt: 0, open: nil),
            Nucleus(typed: ["aay"], shown: "ây", toneAt: 0, open: nil),
            Nucleus(typed: ["eeu"], shown: "êu", toneAt: 0, open: nil),
            Nucleus(typed: ["ooi"], shown: "ôi", toneAt: 0, open: nil),
            Nucleus(typed: ["owi"], shown: "ơi", toneAt: 0, open: nil),
            Nucleus(typed: ["oaw"], shown: "oă", toneAt: 1, open: nil),
            Nucleus(typed: ["uaa"], shown: "uâ", toneAt: 1, open: nil),
            Nucleus(typed: ["uee"], shown: "uê", toneAt: 1, open: nil),
            Nucleus(typed: ["uoo"], shown: "uô", toneAt: 1, open: nil),
            Nucleus(typed: ["iee"], shown: "iê", toneAt: 1, open: nil),
            Nucleus(typed: ["yee"], shown: "yê", toneAt: 1, open: nil),
            Nucleus(typed: ["uwa", "uaw"], shown: "ưa", toneAt: 0, open: nil),
            Nucleus(typed: ["uwi", "uiw"], shown: "ưi", toneAt: 0, open: nil),
            Nucleus(typed: ["uwu"], shown: "ưu", toneAt: 0, open: nil),
            Nucleus(typed: ["uwow"], shown: "ươ", toneAt: 1, open: nil),
            Nucleus(typed: ["uow"], shown: "ươ", toneAt: 1, open: false),
            Nucleus(typed: ["ieeu"], shown: "iêu", toneAt: 1, open: nil),
            Nucleus(typed: ["yeeu"], shown: "yêu", toneAt: 1, open: nil),
            Nucleus(typed: ["oai"], shown: "oai", toneAt: 1, open: nil),
            Nucleus(typed: ["oay"], shown: "oay", toneAt: 1, open: nil),
            Nucleus(typed: ["uaay"], shown: "uây", toneAt: 1, open: nil),
            Nucleus(typed: ["uooi"], shown: "uôi", toneAt: 1, open: nil),
            Nucleus(typed: ["uwowi", "uowi", "uoiw"], shown: "ươi", toneAt: 1, open: nil),
            Nucleus(typed: ["uwowu", "uowu", "uouw"], shown: "ươu", toneAt: 1, open: nil),
            Nucleus(typed: ["uyee"], shown: "uyê", toneAt: 2, open: nil),
            Nucleus(typed: ["uyu"], shown: "uyu", toneAt: 1, open: nil)
        ]
        let onsets: [(typed: String, shown: String)] = [
            ("", ""), ("b", "b"), ("ch", "ch"), ("dd", "đ"), ("d", "d"), ("gi", "gi"),
            ("h", "h"), ("kh", "kh"), ("l", "l"), ("ng", "ng"), ("nh", "nh"),
            ("qu", "qu"), ("th", "th"), ("tr", "tr"), ("x", "x"), ("g", "g")
        ]
        let codas = ["", "c", "ch", "m", "n", "ng", "nh", "p", "t"]
        let toneKeys = ["", "s", "f", "r", "x", "j"]
        let toneForms: [Character: [Character]] = [
            "a": Array("aáàảãạ"), "ă": Array("ăắằẳẵặ"), "â": Array("âấầẩẫậ"),
            "e": Array("eéèẻẽẹ"), "ê": Array("êếềểễệ"), "i": Array("iíìỉĩị"),
            "o": Array("oóòỏõọ"), "ô": Array("ôốồổỗộ"), "ơ": Array("ơớờởỡợ"),
            "u": Array("uúùủũụ"), "ư": Array("ưứừửữự"), "y": Array("yýỳỷỹỵ")
        ]
        func typeWord(_ typed: String) -> String {
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
            return word
        }
        func capitalised(_ text: String) -> String {
            guard let first = text.first else { return text }
            return String(first).uppercased() + text.dropFirst()
        }
        var failures: [String] = []
        var checked = 0
        for onset in onsets {
            for nucleus in nuclei {
                if onset.shown == "qu" && (nucleus.shown.hasPrefix("u") || nucleus.shown.hasPrefix("ư")) { continue }
                if onset.shown == "gi" && nucleus.shown.hasPrefix("i") { continue }
                // "g" + i alone is its own syllable ("gì", "gìn").
                if onset.shown == "g" && nucleus.shown != "i" { continue }
                for coda in codas {
                    if let open = nucleus.open, open != coda.isEmpty { continue }
                    for typedNucleus in nucleus.typed {
                        for (tone, key) in toneKeys.enumerated() {
                            var shown = Array(nucleus.shown)
                            if tone > 0, let forms = toneForms[shown[nucleus.toneAt]] {
                                shown[nucleus.toneAt] = forms[tone]
                            }
                            let expected = onset.shown + String(shown) + coda
                            var orders = [onset.typed + typedNucleus + coda + key]
                            if tone > 0 && !coda.isEmpty { orders.append(onset.typed + typedNucleus + key + coda) }
                            for typed in orders {
                                for capital in [false, true] {
                                    if capital && !(coda.isEmpty || coda == "ng") { continue }
                                    let input = capital ? capitalised(typed) : typed
                                    let want = capital ? capitalised(expected) : expected
                                    let got = typeWord(input)
                                    checked += 1
                                    if got != want { failures.append("\(input) -> \(got) (want \(want))") }
                                }
                            }
                        }
                    }
                }
            }
        }
        if !failures.isEmpty {
            for line in failures.prefix(120) { print("FAIL [Telex] \(line)") }
            fatalError("Telex: \(failures.count) of \(checked) generated syllables are wrong")
        }
        print("PASS [Telex] \(checked) generated syllables typed correctly")
    }
}
