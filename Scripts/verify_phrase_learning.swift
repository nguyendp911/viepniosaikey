import Foundation
@main struct VerifyPhraseLearning {
    static func main() throws {
        var model=PersonalPhraseModel()
        let phrase=["em","ăn","gì","chưa","nè"]
        for _ in 0..<2 {for i in 2...phrase.count {model.observe(Array(phrase.prefix(i)),day:100)}}
        precondition(model.suggestions(context:["em","ăn"],day:100).first=="gì chưa nè")
        precondition(model.suggestions(context:["em"],partial:"ăn",day:100).first=="ăn gì chưa nè")
        precondition(model.suggestions(context:["em","ăn"],partial:"g",day:100).first=="gì chưa nè")
        precondition(model.suggestions(context:["em","ăn"],day:191).isEmpty)
        precondition(PersonalPhraseModel.context("abc. em ăn ")==["em","ăn"])
        precondition(PersonalPhraseModel.token("123456")==nil)
        precondition(!PersonalPhraseModel.safe(["mật","khẩu","abc"]))
        let restored=try JSONDecoder().decode(PersonalPhraseModel.self,from:JSONEncoder().encode(model))
        precondition(restored.suggestions(context:["em","ăn"],day:100).first=="gì chưa nè")
        // A malformed counter/day from a previous file must never trap on load.
        let invalid = """
        {"entries":{"em ăn":{"count":9223372036854775807,"day":100},"gì chưa":{"count":2,"day":-9223372036854775808},"chưa nè":{"count":2,"day":100}}}
        """
        var repaired = try JSONDecoder().decode(PersonalPhraseModel.self, from: Data(invalid.utf8))
        repaired.prune(day:100)
        precondition(repaired.entries.count==1 && repaired.entries["chưa nè"]?.count==2)
        print("PASS personal phrase learning: repeated prefix, partial, recency, privacy, persistence and malformed store")
        var crowded=model
        let samples=["xin","chào","ngày","mai","vui","khỏe","mình","bạn","tôi","đi","làm","học","nhà","trường"]
        for i in samples.indices {for j in samples.indices {for z in 0..<6 {
            let words=[samples[i],samples[j],samples[(i+j+z)%samples.count]]
            crowded.observe(words,day:99)
        }}}
        crowded.prune(day:100)
        precondition(crowded.entries.count<=PersonalPhraseModel.maximum)
        let start=Date()
        for _ in 0..<10000 {_=crowded.suggestions(context:["em","ăn"],day:100)}
        print("Phrase lookup (\(crowded.entries.count) ngrams) mean ms:",Date().timeIntervalSince(start)*1000/10000)
    }
}
