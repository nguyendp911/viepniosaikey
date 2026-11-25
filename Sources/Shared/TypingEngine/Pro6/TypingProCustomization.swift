import Foundation

enum TypingProCustomization {
    static var offsets:[String:Double] {
        get { (KeyboardSettings.defaults.dictionary(forKey:"viepnaikey.pro6.offsets") as? [String:Double] ?? [:]).filter{$0.key.count==1 && $0.value.isFinite && abs($0.value)<=3} }
        set { KeyboardSettings.defaults.set(newValue.filter{$0.key.count==1 && $0.value.isFinite && abs($0.value)<=3},forKey:"viepnaikey.pro6.offsets") }
    }
    static var actions:[String:String] {
        get { KeyboardSettings.defaults.dictionary(forKey:"viepnaikey.pro6.actions") as? [String:String] ?? [:] }
        set { KeyboardSettings.defaults.set(newValue.filter{$0.key.count==1 && $0.value.count<=24 && MessageSafety.warnings(in:$0.value).isEmpty},forKey:"viepnaikey.pro6.actions") }
    }
}
enum TypingProGlide {
    static func phrases(trace:String,model:PersonalPhraseModel)->[String] {
        let normalized=collapse(TypingProText.fold(trace))
        guard (4...70).contains(normalized.count) else{return []}
        let matches=model.entries.filter { key,entry in
            entry.count>=2 && key.contains(" ") && collapse(TypingProText.fold(key.replacingOccurrences(of:" ",with:"")))==normalized
        }.sorted{$0.value.count==$1.value.count ? $0.key<$1.key : $0.value.count>$1.value.count}
        let known=TypingProText.examples.filter{collapse(TypingProText.fold($0.replacingOccurrences(of:" ",with:"")))==normalized}
        return Array((matches.map(\.key)+known).prefix(3))
    }
    private static func collapse(_ value:String)->String {
        var result="";for ch in value where result.last != ch {result.append(ch)};return result
    }
}
