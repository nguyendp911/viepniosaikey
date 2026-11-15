import Foundation

@main
struct VerifySmartExtras {
    static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else { fatalError("FAIL [SmartExtras] \(message)") }
        print("PASS [SmartExtras] \(message)")
    }

    static func main() {
        verifyEmoji()
        verifyShorthand()
        verifyProperNouns()
        verifyDiacritics()
    }

    static func verifyEmoji() {
        expect(EmojiSuggestions.suggest(afterWords: ["em", "nhớ"]) == ["🥺", "❤️"],
               "'nhớ' suggests 🥺 ❤️")
        expect(EmojiSuggestions.suggest(afterWords: ["chúc", "ngủ", "ngon"]) == ["🌙", "😴"],
               "phrase 'ngủ ngon' wins over the single word")
        expect(EmojiSuggestions.suggest(afterWords: ["em", "bị", "bệnh"]).isEmpty,
               "no emoji after an illness word")
        expect(EmojiSuggestions.suggest(afterWords: ["nhớ", "mất"]).isEmpty,
               "no emoji after a loss word")
        expect(EmojiSuggestions.suggest(afterWords: ["xyz"]).isEmpty, "unknown word -> none")
        expect(EmojiSuggestions.suggest(afterWords: []).isEmpty, "no words -> none")
        expect(EmojiSuggestions.suggest(afterWords: ["cảm", "ơn"], limit: 1).count == 1,
               "limit is respected")
        expect(EmojiSuggestions.fold("Đường") == "duong", "folding removes accents and đ")
    }

    static func verifyShorthand() {
        expect(ChatShorthand.expansion(for: "ntn") == "như thế nào", "'ntn' expands")
        expect(ChatShorthand.expansion(for: "Mn") == "Mọi người", "leading capital is kept")
        expect(ChatShorthand.expansion(for: "NTN") == nil, "shouting is not expanded")
        expect(ChatShorthand.expansion(for: "j") == "gì", "'j' -> gì")
        expect(ChatShorthand.expansion(for: "hôm") == nil, "ordinary word is untouched")
        expect(ChatShorthand.expansion(for: "") == nil, "empty word -> nil")
    }

    static func verifyProperNouns() {
        var memory = ProperNounMemory()
        memory.learn(words: ["đi", "Hà", "Nội"], reachedSentenceStart: true)
        expect(memory.match(words: ["hà", "nội"]) == nil, "one sighting is not applied yet")
        memory.learn(words: ["đi", "Hà", "Nội"], reachedSentenceStart: true)
        let hit = memory.match(words: ["đi", "hà", "nội"])
        expect(hit?.wordCount == 2 && hit?.display == "Hà Nội", "'hà nội' -> 'Hà Nội' after two sightings")
        expect(memory.match(words: ["Hà", "Nội"]) == nil, "already correct -> no change")
        expect(memory.match(words: ["bà", "nội"]) == nil, "'nội' alone is not capitalised")

        var sentenceStart = ProperNounMemory()
        sentenceStart.learn(words: ["Hà"], reachedSentenceStart: true)
        sentenceStart.learn(words: ["Hôm", "Linh"], reachedSentenceStart: true)
        expect(sentenceStart.entries.isEmpty, "a capital at the start of a sentence is not learned")

        var single = ProperNounMemory()
        single.learn(words: ["gặp", "Linh"], reachedSentenceStart: false)
        single.learn(words: ["gặp", "Linh"], reachedSentenceStart: false)
        let linh = single.match(words: ["gặp", "linh"])
        expect(linh?.wordCount == 1 && linh?.display == "Linh", "single mid-sentence name is learned")

        var shouting = ProperNounMemory()
        shouting.learn(words: ["nói", "OK"], reachedSentenceStart: false)
        expect(shouting.entries.isEmpty, "all-caps words are not names")

        var big = ProperNounMemory()
        for index in 0..<500 {
            big.learn(words: ["gặp", "Ten\(index)"], reachedSentenceStart: false)
        }
        expect(big.entries.count <= ProperNounMemory.maxEntries, "learned names stay bounded")
        expect(ProperNounMemory.decode(memory.encoded()) == memory, "memory survives encode/decode")
        expect(ProperNounMemory.decode(nil) == ProperNounMemory(), "missing data -> empty memory")
    }

    static func verifyDiacritics() {
        expect(DiacriticRestorer.restore("toi di an com") == "tôi đi ăn cơm",
               "'toi di an com' -> 'tôi đi ăn cơm'")
        expect(DiacriticRestorer.restore("hom nay em an com chua") == "hôm nay em ăn cơm chưa",
               "word pairs pick the right accents")
        expect(DiacriticRestorer.restore("Toi di an") == "Tôi đi ăn", "capital letters are kept")
        expect(DiacriticRestorer.restore("tôi đi an com") == "tôi đi ăn cơm",
               "existing accents are untouched")
        expect(DiacriticRestorer.restore("toi di an com, nhe!") == "tôi đi ăn cơm, nhé!",
               "punctuation is preserved")
        expect(DiacriticRestorer.restore("me and you", isProtected: {
            ["me", "and", "you"].contains($0)
        }) == "me and you", "protected (English) words are untouched")

        var learned = NextWordModel()
        learned.bigrams["mua"] = ["bán": 3]
        expect(DiacriticRestorer.restore("mua ban", model: learned) == "mua bán",
               "learned word pairs outrank the default accent")

        expect(DiacriticRestorer.suggestion(for: "toi di an com") == "tôi đi ăn cơm",
               "an accent-free sentence gets a suggestion")
        expect(DiacriticRestorer.suggestion(for: "tôi đi ăn cơm") == nil,
               "an accented sentence gets no suggestion")
        expect(DiacriticRestorer.suggestion(for: "ok") == nil, "very short text gets no suggestion")
        expect(DiacriticRestorer.suggestion(for: "I love you so much") == nil,
               "English text gets no suggestion")

        expect(DiacriticRestorer.sentenceTail(of: "Xin chào. toi di an") == "toi di an",
               "sentence tail stops at a full stop")
        expect(DiacriticRestorer.sentenceTail(of: "toi di an") == "toi di an",
               "short text is returned whole")
        let long = String(repeating: "toi di an ", count: 40)
        let tail = DiacriticRestorer.sentenceTail(of: long)
        let allowed: Set<String> = ["toi", "di", "an"]
        expect(tail.count <= 160 && !tail.hasPrefix(" ")
               && tail.split(separator: " ").allSatisfy { allowed.contains(String($0)) },
               "long text is cut at a word boundary")
    }
}
