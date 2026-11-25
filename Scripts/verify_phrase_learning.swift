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
        print("PASS personal phrase learning: repeated prefix, partial, recency, privacy and persistence")
        let start=Date()
        for _ in 0..<10000 {_=model.suggestions(context:["em","ăn"],day:100)}
        print("Phrase lookup (small fixture) mean ms:",Date().timeIntervalSince(start)*1000/10000)
    }
}
