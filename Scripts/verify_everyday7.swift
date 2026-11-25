import Foundation
import CryptoKit

@main struct VerifyEveryday7 {
    static func main() throws {
        let legacy=Data(#"{"entries":{"em ăn gì":{"count":2,"day":100}}}"#.utf8)
        var model=try JSONDecoder().decode(PersonalPhraseModel.self,from:legacy)
        precondition(model.suggestions(context:["em","ăn"],day:100).first=="gì")
        precondition(model.setPinned("em ăn gì",true))
        model.prune(day:250)
        precondition(model.suggestions(context:["em","ăn"],day:250).first=="gì")
        precondition(model.edit("em ăn gì",to:"em ăn gì chưa nè",day:250))
        precondition(model.entries["em ăn gì"]==nil && model.entries["em ăn gì chưa nè"]?.pinned==true)
        precondition(!model.edit(nil,to:"mật khẩu bí mật",day:250))
        precondition(!model.edit(nil,to:"em ăn gì chưa nè",day:250))
        var incoming=PersonalPhraseModel()
        incoming.observe(["em","ăn","gì","chưa","nè"],day:250)
        incoming.observe(["em","ăn","gì","chưa","nè"],day:250)
        model.merge(incoming,day:250)
        precondition(model.entries["em ăn gì chưa nè"]?.count==2 && model.entries["em ăn gì chưa nè"]?.pinned==true)
        let copy=try JSONDecoder().decode(PersonalPhraseModel.self,from:JSONEncoder().encode(model))
        precondition(copy.entries["em ăn gì chưa nè"]?.pinned==true)
        model.remove("em ăn gì chưa nè")
        precondition(model.entries["em ăn gì chưa nè"]==nil)
        let known:Set<String>=["sửa","sữa","giữ","chuyển","nghĩ","nghỉ","nhiều","khỏe","sắp"]
        precondition(EverydayLanguage.spell("sữ",known:known)==["sửa"])
        precondition(EverydayLanguage.spell("giử",known:known)==["giữ"])
        precondition(EverydayLanguage.spell("muôn",known:["muông"]).contains("muông"))
        precondition(EverydayLanguage.accent("hoà",style:"traditional")=="hòa")
        precondition(EverydayLanguage.accent("Thủy",style:"modern")=="Thuỷ")
        precondition(EverydayLanguage.accent("quý",style:"traditional")=="quý")
        precondition(EverydayLanguage.accent("hoà",style:"existing")=="hoà")
        var prefs=EverydayPreferences();prefs.abbreviations=true;prefs.regional="south";prefs.rowSpacing=[0,100,6,7]
        precondition(EverydayLanguage.candidates(word:"ko",preferences:prefs,known:known).contains("không"))
        precondition(EverydayLanguage.candidates(word:"tu",preferences:prefs,known:known).contains("tui"))
        precondition(prefs.normalized.rowSpacing==[3,9,6,7])
        var map=EverydayTouchMap();map.record(x:1,y:1);map.record(x:0,y:0);map.record(x:-1,y:0)
        precondition(map.bins[0]==1 && map.bins[49]==1 && map.bins.reduce(0,+)==2)
        let key=EverydayEncryption.key(EverydayEncryption.makeKey())!
        let plaintext=try JSONEncoder().encode(copy)
        let ciphertext=try EverydayEncryption.seal(plaintext,using:key)
        precondition(ciphertext != plaintext)
        let opened=try EverydayEncryption.open(ciphertext,using:key)
        precondition(opened==plaintext)
        precondition((try? EverydayEncryption.open(ciphertext,using:SymmetricKey(size:.bits256)))==nil)
        var tampered=ciphertext;tampered[tampered.startIndex] ^= 1
        precondition((try? EverydayEncryption.open(tampered,using:key))==nil)
        var feedback=TypingProFeedback();feedback.record(source:"sữ",target:"sửa",accept:true)
        var other=feedback;other.record(source:"sữ",target:"sửa",accept:true)
        feedback.mergeBackup(other)
        precondition(feedback.preferred("sữ",minimum:2)==["sửa"])
        let start=Date()
        for _ in 0..<10000{_ = EverydayLanguage.spell("giử",known:known)}
        print("PASS Everyday 7: migration, pinned persistence, edits, merge, region, spelling, tone, heatmap and authenticated encryption")
        print("Everyday spell fixture mean ms:",Date().timeIntervalSince(start)*1000/10000)
    }
}
