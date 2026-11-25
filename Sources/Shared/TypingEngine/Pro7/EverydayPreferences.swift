import Foundation

struct EverydayPreferences: Codable, Equatable {
    var liveCompletion=false
    var expandedBar=false
    var spellCheck=false
    var regional="all"
    var abbreviations=false
    var accentStyle="existing"
    var preventSpaces=false
    var smartPaste=false
    var geometry=false
    var portraitWidth=85
    var landscapeWidth=85
    var landscapeHeight=40
    var rowSpacing=[6,6,6,6]
    var heatmap=false
    var silent=false
    var diagnostics=false
    static var current:Self {
        get {
            guard let data=KeyboardSettings.defaults.data(forKey:"viepnaikey.everyday7"),
                  let value=try? JSONDecoder().decode(Self.self,from:data) else{return .init()}
            return value.normalized
        }
        set {if let data=try? JSONEncoder().encode(newValue.normalized){KeyboardSettings.defaults.set(data,forKey:"viepnaikey.everyday7")}}
    }
    var normalized:Self {
        var v=self
        if !["all","north","central","south"].contains(v.regional){v.regional="all"}
        if !["existing","modern","traditional"].contains(v.accentStyle){v.accentStyle="existing"}
        v.portraitWidth=min(100,max(80,v.portraitWidth));v.landscapeWidth=min(100,max(75,v.landscapeWidth))
        v.landscapeHeight=min(49,max(34,v.landscapeHeight))
        v.rowSpacing=v.rowSpacing.count==4 ? v.rowSpacing.map{min(9,max(3,$0))} : [6,6,6,6]
        return v
    }
}
enum EverydayLanguage {
    static let abbreviations:[String:String]=["ko":"không","k":"không","hk":"không","dc":"được","đc":"được","iu":"yêu","nt":"nhắn tin","rep":"trả lời","vs":"với","mn":"mọi người","mk":"mình","bn":"bạn"]
    static let regionWords:[String:[String]]=["north":["vâng","nhỉ","thế","chả","bảo","bát","ngõ"],"central":["răng","rứa","mô","tê","ri","chi","nỏ"],"south":["nè","hen","hén","hông","bển","tui","nghen","quẹo","chén"]]
    static let mistakes:[String:[String]]=["sữ":["sửa"],"xữa":["sữa","sửa"],"chãi":["trải"],"trãi":["trải"],"giử":["giữ"],"nghĩa":["nghĩa"],"xắp":["sắp"],"chắc":["chắc"],"dỡ":["dỡ","giỡ"],"lẩn":["lẫn"],"nghỉ":["nghĩ","nghỉ"],"ngĩ":["nghĩ"],"chuyễn":["chuyển"],"chuyễn":["chuyển"],"nhiểu":["nhiều"],"khoẻ":["khỏe"]]
    static func spell(_ word:String,known:Set<String>)->[String] {
        let w=word.lowercased();guard (2...24).contains(w.count),w.allSatisfy(\.isLetter) else{return []}
        var options=mistakes[w] ?? []
        // Known valid alternatives are not called errors. Offer explicitly.
        if !known.contains(w) {
            let pairs=[("s","x"),("ch","tr"),("d","gi"),("r","d"),("r","gi"),("n","ng")]
            for (a,b) in pairs {
                for (from,to) in [(a,b),(b,a)] where w.hasPrefix(from) {
                    let candidate=to+w.dropFirst(from.count)
                    if known.contains(candidate){options.append(candidate)}
                }
            }
            if let index=w.firstIndex(where:{VietnameseOrthography.lookup[$0]?.tone==3 || VietnameseOrthography.lookup[$0]?.tone==4}),
               let tone=VietnameseOrthography.lookup[w[index]]?.tone,
               let candidate=VietnameseOrthography.applyingTone(Array(w),tone:tone==3 ? 4 : 3),known.contains(candidate){options.append(candidate)}
        }
        var seen=Set<String>();return Array(options.filter{$0 != w && known.contains($0) && seen.insert($0).inserted}.prefix(3))
    }
    static func accent(_ word:String,style:String)->String {
        guard style != "existing" else{return word}
        let chars=Array(word),indices=VietnameseOrthography.nucleus(chars)
        guard VietnameseOrthography.plausible(chars),indices.count==2,indices.last==chars.count-1,
              let first=indices.first,let last=indices.last,
              ["oa","oe","uy"].contains(String(indices.compactMap{VietnameseOrthography.base(chars[$0])})),
              let v=VietnameseOrthography.lookup[chars[first]],let u=VietnameseOrthography.lookup[chars[last]],
              [v.tone,u.tone].filter({$0>0}).count==1 else{return word}
        let tone=max(v.tone,u.tone)
        var result=chars
        result[first]=VietnameseOrthography.form(chars[first],group:v.group,tone:style=="traditional" ? tone : 0)
        result[last]=VietnameseOrthography.form(chars[last],group:u.group,tone:style=="modern" ? tone : 0)
        return String(result)
    }
    static func candidates(word:String,preferences:EverydayPreferences,known:Set<String>)->[String] {
        var result:[String]=[]
        if preferences.abbreviations,let full=abbreviations[word.lowercased()]{result.append(full)}
        if preferences.spellCheck {result += spell(word,known:known)}
        if preferences.regional != "all",word.count>=2 {
            result += (regionWords[preferences.regional] ?? []).filter{$0 != word && $0.hasPrefix(word.lowercased())}
        }
        var seen=Set<String>();return result.filter{seen.insert($0).inserted}
    }
}
struct EverydayTouchMap:Codable {
    // Normalized 5×10 positional grid; no keys, labels, messages or timestamps.
    var bins=Array(repeating:0,count:50)
    mutating func record(x:Double,y:Double) {
        guard x.isFinite,y.isFinite,(0...1).contains(x),(0...1).contains(y) else{return}
        if bins.count != 50{bins=Array(repeating:0,count:50)}
        let index=min(4,Int(y*5))*10+min(9,Int(x*10))
        bins[index]=min(100000,max(0,min(100000,bins[index]))+1)
    }
    static var current:Self {
        get {
            guard !KeyboardSettings.privateTypingMode,let data=KeyboardSettings.defaults.data(forKey:"viepnaikey.everyday7.heatmap"),let result=try? JSONDecoder().decode(Self.self,from:data),result.bins.count==50 else{return .init()}
            return result
        }
        set {if !KeyboardSettings.privateTypingMode,let data=try? JSONEncoder().encode(newValue){KeyboardSettings.defaults.set(data,forKey:"viepnaikey.everyday7.heatmap")}}
    }
    static func clear(){KeyboardSettings.defaults.removeObject(forKey:"viepnaikey.everyday7.heatmap")}
}
