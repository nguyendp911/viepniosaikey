import Foundation

@main
struct VerifyNextWord {
    static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else { fatalError("FAIL [NextWord] \(message)") }
        print("PASS [NextWord] \(message)")
    }

    static func main() {
        let empty = NextWordModel()

        // Context extraction
        expect(NextWordPredictor.words(in: "Em ăn") == ["em", "ăn"], "context words are lowercased")
        expect(NextWordPredictor.words(in: "Xin chào. Em ăn") == ["em", "ăn"],
               "context stops at a sentence boundary")
        expect(NextWordPredictor.words(in: "Xong rồi.") == [], "nothing after a full stop")
        expect(NextWordPredictor.words(in: "a b c d e") == ["c", "d", "e"], "keeps the last three words")
        let longText = String(repeating: "lorem ipsum ", count: 5000) + "em ăn"
        expect(NextWordPredictor.words(in: longText) == ["ipsum", "em", "ăn"],
               "long text only scans the tail")
        // NFD input must match the NFC seed table
        expect(NextWordPredictor.words(in: "em \u{0103}n".decomposedStringWithCanonicalMapping)
               == ["em", "ăn"], "decomposed Vietnamese is normalised")

        // Built-in phrases: the example from the feature request
        let emAn = NextWordPredictor.predict(after: ["em", "ăn"], model: empty, limit: 4)
        expect(emAn == ["cơm", "chưa", "gì", "rồi"], "'em ăn' -> cơm / chưa / gì / rồi")
        let top3 = NextWordPredictor.predict(after: ["em", "ăn"], model: empty)
        expect(top3.count == 3, "default limit is three suggestions")
        expect(NextWordPredictor.predict(after: ["ăn", "cơm"], model: empty).first == "chưa",
               "'ăn cơm' -> chưa")
        expect(NextWordPredictor.predict(after: ["ngủ"], model: empty).contains("ngon"),
               "single-word context falls back to bigrams")
        expect(NextWordPredictor.predict(after: [], model: empty).isEmpty, "no context -> no suggestion")
        expect(NextWordPredictor.predict(after: ["zzzz"], model: empty).isEmpty, "unknown word -> none")

        // Learning: a habit seen repeatedly outranks the built-in table
        var model = NextWordModel()
        for _ in 0..<3 {
            NextWordPredictor.learn(words: ["em", "ăn", "phở"], into: &model)
        }
        expect(NextWordPredictor.predict(after: ["em", "ăn"], model: model).first == "phở",
               "learned trigram ranks first")
        expect(NextWordPredictor.predict(after: ["anh", "ăn"], model: model).first == "phở",
               "learned bigram generalises to another subject")
        expect(NextWordPredictor.predict(after: ["em", "ăn"], model: model).contains("cơm"),
               "built-in suggestions remain available")

        // One sighting does not push out the strong built-in phrases
        var once = NextWordModel()
        NextWordPredictor.learn(words: ["chào", "sếp"], into: &once)
        expect(NextWordPredictor.predict(after: ["xin", "chào"], model: once).first == "bạn",
               "a single learned word does not displace the built-in phrase")
        expect(NextWordPredictor.predict(after: ["xin", "chào"], model: once, limit: 8).contains("sếp"),
               "a single learned word is still offered")

        // Bounds
        var big = NextWordModel()
        for index in 0..<2000 {
            NextWordPredictor.learn(words: ["w\(index)", "x\(index)"], into: &big)
        }
        expect(big.bigrams.count <= NextWordModel.maxContexts, "learned contexts stay bounded")
        var fan = NextWordModel()
        for index in 0..<50 {
            NextWordPredictor.learn(words: ["a", "n\(index)"], into: &fan)
        }
        expect((fan.bigrams["a"]?.count ?? 0) <= NextWordModel.maxNextPerContext,
               "next words per context stay bounded")

        // Persistence round trip
        let restored = NextWordModel.decode(model.encoded())
        expect(restored == model, "model survives encode/decode")
        expect(NextWordModel.decode(nil) == NextWordModel(), "missing data -> empty model")

        // Seed tables are canonical (NFC, lowercase) so lookups can match
        for key in Array(NextWordPredictor.seedBigrams.keys) + Array(NextWordPredictor.seedTrigrams.keys) {
            expect(key == NextWordPredictor.normalize(key), "seed key is normalised: \(key)")
        }
    }
}
