import Foundation

enum VietnameseTelex {
    private static let tones:[Character:Int]=["s":1,"f":2,"r":3,"x":4,"j":5]
    static func composeKeys(_ raw:String)->String {
        var word=""
        for char in raw {
            if let result=transformed(word:word,key:String(char)){word=result}
            else {word.append(char);word=normalizedTonePosition(word) ?? word}
        }
        return word
    }
    static func normalizedTonePosition(_ word:String)->String? { VietnameseOrthography.normalize(word) }
    static func transformed(word:String,key:String)->String? {
        guard word.count<=40,key.count==1,let code=key.lowercased().first,!word.isEmpty else{return nil}
        let chars=Array(word)
        let rules=VietnameseOrthography.self
        if code=="d",let last=chars.last,last.lowercased()=="d" {
            return String(chars.dropLast())+(last.isUppercase ? "Đ":"đ")
        }
        if code=="d",let last=chars.last,last.lowercased()=="đ" {
            return String(chars.dropLast())+(last.isUppercase ? "D":"d")+key
        }
        if code=="w" {
            if let result=rules.horn(chars){return result}
            if let index=rules.nucleus(chars).last,let v=rules.lookup[chars[index]],let plain=[1:0,8:6,10:9][v.group],rules.plausible(chars){
                var output=chars;output[index]=rules.form(chars[index],group:plain,tone:v.tone);return String(output)+key
            }
        }
        if let pair:[Int]=["a":[0,2],"e":[3,4],"o":[6,7]][code] {
            // Immediate or end-of-syllable shape; avoid interpreting a normal
            // second nucleus vowel as a shape when the last key differs.
            if let last=chars.last,let v=rules.lookup[last],v.group==pair[0],let result=rules.shape(chars,from:pair[0],to:pair[1]){return result}
            if let last=chars.last,let v=rules.lookup[last],v.group==pair[1],rules.plausible(chars){
                return String(chars.dropLast())+String(rules.form(last,group:pair[0],tone:v.tone))+key
            }
            if chars.last.map({rules.lookup[$0]==nil})==true,let result=rules.shape(chars,from:pair[0],to:pair[1]){return result}
        }
        if code=="z" {return rules.removeTone(chars)}
        guard let tone=tones[code],rules.plausible(chars),let result=rules.applyingTone(chars,tone:tone) else{return nil}
        if result==word,let plain=rules.removeTone(chars){return plain+key}
        return result==word ? nil : result
    }
}
