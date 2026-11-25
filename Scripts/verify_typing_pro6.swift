import Foundation
@main struct VerifyTypingPro6 {
    static func main() throws {
        var model=PersonalPhraseModel()
        let words=["em","ăn","gì","chưa","nè"]
        for _ in 0..<2{for i in 2...words.count{model.observe(Array(words.prefix(i)),day:100,period:2)}}
        precondition(model.suggestions(context:["em","ăn"],day:100,period:2).first=="gì chưa nè")
        precondition(model.suggestions(context:["em","ăn"],day:100,minimum:3,period:2).isEmpty)
        let legacy=Data(#"{"entries":{"em ăn gì":{"count":2,"day":100}}}"#.utf8)
        let restored=try JSONDecoder().decode(PersonalPhraseModel.self,from:legacy)
        precondition(restored.suggestions(context:["em","ăn"],day:100).first=="gì")
        precondition(TypingProText.recover("em an gi chua ne",vocabulary:words).first=="em ăn gì chưa nè")
        precondition(TypingProText.punctuation("em ăn cơm chưa").first=="em ăn cơm chưa?")
        precondition(TypingProText.pair("(")==")")
        precondition(TypingProText.grouping("1234567")=="1.234.567")
        precondition(TypingProText.grouping("012345")==nil)
        precondition(TypingProText.deletionCount("em ăn gì ",words:2)==7)
        precondition(TypingProText.dictionary("Xin\nchào\nxin",format:"txt")==["xin","chào"])
        precondition(TypingProText.dictionary("[\"xin\",\"chào\"]",format:"json")==["xin","chào"])
        precondition(TypingProText.emoji("yêu").contains("❤️"))
        var feedback=TypingProFeedback()
        feedback.record(source:"storw",target:"store",accept:true)
        feedback.record(source:"storw",target:"store",accept:true)
        precondition(feedback.preferred("storw",minimum:2)==["store"])
        feedback.record(source:"storw",target:"store",accept:false)
        feedback.record(source:"storw",target:"store",accept:false)
        precondition(feedback.rejects("storw","store") && feedback.preferred("storw",minimum:2).isEmpty)
        feedback.record(source:"k",target:"không",accept:true)
        feedback.record(source:"k",target:"không",accept:true)
        precondition(feedback.preferred("k",minimum:2)==["không"])
        precondition(TypingProGlide.phrases(trace:"emangichuane",model:model).contains("em ăn gì chưa nè"))
        precondition(!TypingProPreferences().doubleSpace && !TypingProPreferences().corrections)
        let start=Date()
        for _ in 0..<1000{_ = TypingProText.recover("em an gi chua ne",vocabulary:words)}
        print("PASS Typing Pro 6.0 logic and v1 migration")
        print("Accent recovery fixture mean ms:",Date().timeIntervalSince(start)*1000/1000)
    }
}
