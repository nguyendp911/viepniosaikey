import Foundation

/// Separate settings key: no migration/reset of Everyday 7 or earlier settings.
struct VietnameseAutoCorrectSettings: Codable, Equatable {
    var restoreAccents = true
    var mode = "careful"
    static var current: Self {
        get {
            guard let data=KeyboardSettings.defaults.data(forKey:"viepnaikey.autocorrect.vi"),
                  var value=try? JSONDecoder().decode(Self.self,from:data) else{return .init()}
            if !["off","suggest","careful","advanced"].contains(value.mode){value.mode="careful"}
            return value
        }
        set {if let data=try? JSONEncoder().encode(newValue){KeyboardSettings.defaults.set(data,forKey:"viepnaikey.autocorrect.vi")}}
    }
}
enum VietnameseAutoCorrect {
    struct Choice:Equatable {let text:String;let automatic:Bool}
    // Curated high-frequency forms with strong Vietnamese spelling evidence.
    static let frequent:[String:String]=[
        "khong":"không","nhieu":"nhiều","nhung":"những","duoc":"được","nguoi":"người","thuong":"thương",
        "tieng":"tiếng","viet":"việt","tiengviet":"tiếng việt","chuyen":"chuyện","chung":"chúng",
        "tuong":"tưởng","muon":"muốn","buon":"buồn","khoe":"khỏe","nghia":"nghĩa","nguyen":"nguyên",
        "nhan":"nhắn","thich":"thích","biet":"biết","tung":"từng","trong":"trong","xong":"xong",
        "dang":"đang","cung":"cũng","cua":"của","nhu":"như","truoc":"trước",
        "sau":"sau","luon":"luôn","nhat":"nhất","mot":"một",
        "chuc":"chúc","cam":"cảm","on":"ơn","toi":"tôi","minh":"mình",
        "hom":"hôm","ngay":"ngày","lam":"làm","chua":"chưa","ne":"nè","gi":"gì","nhe":"nhé",
        "qua":"quá","rat":"rất","met":"mệt","nho":"nhớ","nua":"nữa","vay":"vậy","dung":"đừng"
    ]
    // A smaller set is safe even at sentence start; ambiguous forms remain
    // suggestions unless supported by a phrase or the explicit advanced mode.
    static let strong:Set<String>=["khong","nhieu","duoc","nguoi","thuong","tieng","muon","khoe","thich","biet","truoc","luon","chuc","met","nhe"]
    static let fixed:[String:String]=["giử":"giữ","sữ":"sửa","xắp":"sắp","chuyễn":"chuyển","nhiểu":"nhiều","ngĩ":"nghĩ","iêu":"yêu","buồngg":"buồn"]
    static let phrases=TypingProText.examples+[
        "em ăn gì chưa nè","em ăn cơm chưa","em ăn gì chưa","em ăn","anh ăn cơm chưa","em chưa ăn cơm",
        "anh đang suy nghĩ","đang suy nghĩ","suy nghĩ","anh rất thương yêu em","thương yêu","anh sẽ luôn bên em",
        "em đừng buồn nữa","đừng buồn","buồn nữa","không dấu","gõ không dấu","tiếng việt có dấu","tự thêm dấu",
        "em đang làm gì","anh đang làm gì vậy","anh đang làm việc","em đang đi đâu","em ở đâu","em có khỏe không",
        "anh nhớ em","anh nhớ em nhiều lắm","em nhớ anh","anh yêu em nhiều","chúc em ngủ ngon",
        "anh về tới nhà rồi","em về nhà chưa","anh về nhà rồi","hôm nay em thế nào","hôm nay trời đẹp",
        "cảm ơn em","cảm ơn anh","cảm ơn bạn","xin chào bạn","xin lỗi em","không có gì","không sao đâu",
        "anh không biết","em không biết","tôi không biết","đi làm về","đi chơi không","đi ăn cơm",
        "đang ăn cơm","ăn cơm","ăn gì","gì chưa","chưa nè","gì vậy","gì đó","ngủ ngon","ngày mai",
        "rất nhiều","nhiều lắm","rất vui","rất thương","rất yêu","sẽ luôn","sẽ không","sẽ đi","sẽ đến",
        "anh sẽ","em sẽ","tôi sẽ","mình sẽ","bạn sẽ","anh đang","em đang","tôi đang","mình đang",
        "đừng lo","đừng khóc","đừng buồn","về nhà","ở nhà","tại sao","như thế nào","như vậy","thế nào",
        "bây giờ","bao giờ","bao nhiêu","có phải","có thể","có muốn","có gì","chưa biết","chưa ngủ",
        "một ngày","một chút","một mình","mọi người","người yêu","người bạn","bạn bè","gia đình",
        "công việc","làm việc","đi học","học tiếng việt","tiếng việt","tôi muốn","mình muốn","em muốn",
        "được không","đúng rồi","đúng không","thật không","thật lòng","thật sự","cố gắng","cẩn thận",
        "tốt lành","bình yên","hạnh phúc","sức khỏe","chúc mừng","sinh nhật","gặp lại","hẹn gặp",
        "hôm qua","ngày hôm nay","sáng nay","tối nay","chiều nay","buổi sáng","buổi tối","buổi chiều"
    ]
    struct Rule {let prefix:[String];let source:String;let target:String}
    static let rules:[String:[Rule]] = {
        var map:[String:[Rule]]=[:]
        for phrase in phrases {
            let words=phrase.split(separator:" ").map(String.init)
            for i in 1..<words.count {
                let source=TypingProText.fold(words[i])
                let prefix=Array(words[..<i].suffix(4))
                map[source,default:[]].append(Rule(prefix:prefix,source:source,target:words[i]))
            }
        }
        // Correct actual misspellings only in known contexts.
        for (prefix,source,target) in [("suy","nghỉ","nghĩ"),("ăn","cơn","cơm"),("thương","iêu","yêu"),("anh","sẻ","sẽ"),("em","sẻ","sẽ"),("tôi","sẻ","sẽ"),("đừng","buồng","buồn")] {
            map[source,default:[]].append(Rule(prefix:[prefix],source:source,target:target))
        }
        return map
    }()
    static func context(_ before:String)->[String] {
        PersonalPhraseModel.context(before).suffix(4).map{$0.lowercased()}
    }
    static func preserveCase(_ target:String,source:String)->String {
        if source.count>1 && source==source.uppercased(){return target.uppercased()}
        if source.first?.isUppercase==true{return target.prefix(1).uppercased()+target.dropFirst()}
        return target
    }
    static func choices(word:String,context prior:[String],settings:VietnameseAutoCorrectSettings,explicitVietnamese:Bool,english:Set<String>,known:Set<String>,protected:Set<String>=[],feedback:TypingProFeedback=TypingProFeedback(),includeTypos:Bool=false)->[Choice] {
        guard settings.mode != "off",(2...24).contains(word.count),word.allSatisfy(\.isLetter),
              word != word.uppercased() || word.count<2 else{return []}
        let w=word.lowercased(), ascii=w.allSatisfy(\.isASCII)
        guard !protected.contains(w) else{return []}
        let preceding=Array(prior.suffix(4)).map{$0.lowercased()}
        let viContext=explicitVietnamese || preceding.contains{!$0.allSatisfy(\.isASCII) || ["anh","em","minh","toi","ban","hom","ngay","xin"].contains($0)}
        var ranked:[String:Int]=[:]
        let matched=(rules[w] ?? []).filter{rule in
            guard preceding.count>=rule.prefix.count else{return false}
            let actual=Array(preceding.suffix(rule.prefix.count))
            return actual==rule.prefix || (ascii && actual.map(TypingProText.fold)==rule.prefix.map(TypingProText.fold))
        }
        for rule in matched where rule.target != w && (!ascii || settings.restoreAccents) {
            ranked[rule.target]=max(ranked[rule.target] ?? 0,90+rule.prefix.count*10)
        }
        if !ascii,let target=fixed[w]{ranked[target]=max(ranked[target] ?? 0,100)}
        if ascii,settings.restoreAccents,let target=frequent[w],target != w {
            let score=strong.contains(w) && !english.contains(w) ? 94 : viContext && settings.mode=="advanced" && !english.contains(w) ? 92 : 45
            ranked[target]=max(ranked[target] ?? 0,score)
        }
        if viContext || !english.contains(w) {
            for target in feedback.preferred(w,minimum:3) where !target.contains(" ") && (!ascii || settings.restoreAccents) {
                ranked[target]=max(ranked[target] ?? 0,105)
            }
        }
        if includeTypos {
            for target in EverydayLanguage.spell(w,known:known) {ranked[target]=max(ranked[target] ?? 0,40)}
            if !known.contains(w),!english.contains(w),w.count>=3,viContext {
                for target in typoVariants(w,known:known) {ranked[target]=max(ranked[target] ?? 0,30)}
            }
        }
        let sorted=ranked.filter{!feedback.rejects(w,$0.key) && $0.key != w}
            .sorted{$0.value==$1.value ? $0.key<$1.key : $0.value>$1.value}
        return Array(sorted.prefix(3).enumerated().map{index,item in
            let clear=sorted.count==1 || item.value-sorted[1].value>=10
            let safeLanguage=explicitVietnamese || !english.contains(w) || (viContext && item.value>=100)
            let automatic=index==0 && clear && safeLanguage && item.value>=90 && ["careful","advanced"].contains(settings.mode)
            return Choice(text:preserveCase(item.key,source:word),automatic:automatic)
        })
    }
    static func typoVariants(_ word:String,known:Set<String>)->[String] {
        let chars=Array(word);guard (3...24).contains(chars.count) else{return []}
        let rows=["qwertyuiop","asdfghjkl","zxcvbnm"]
        let positions=Dictionary(uniqueKeysWithValues:rows.enumerated().flatMap{r,row in row.enumerated().map{(ch:$0.element,x:Double($0.offset)+Double(r)*0.3,y:r)}}.map{($0.ch,($0.x,$0.y))})
        var options=Set<String>()
        func add(_ value:[Character]){let s=String(value);if s != word,known.contains(s){options.insert(s)}}
        for i in chars.indices {
            var deleted=chars;deleted.remove(at:i);add(deleted)
            if i+1<chars.count {var swapped=chars;swapped.swapAt(i,i+1);add(swapped)}
            if let here=positions[chars[i]] {
                for (ch,pos) in positions where abs(here.0-pos.0)<=1.1 && abs(here.1-pos.1)<=1 {
                    var variant=chars;variant[i]=ch;add(variant)
                }
            }
        }
        for i in 0...chars.count {for ch in "abcdefghijklmnopqrstuvwxyz"{var variant=chars;variant.insert(ch,at:i);add(variant)}}
        return Array(options.sorted().prefix(3))
    }
}
