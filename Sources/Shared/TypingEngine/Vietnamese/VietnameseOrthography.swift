import Foundation

/// Shared Vietnamese vowel/shape/tone rules for Telex and VNI.
enum VietnameseOrthography {
    static let groups = ["aáàảãạ","ăắằẳẵặ","âấầẩẫậ","eéèẻẽẹ","êếềểễệ","iíìỉĩị","oóòỏõọ","ôốồổỗộ","ơớờởỡợ","uúùủũụ","ưứừửữự","yýỳỷỹỵ"].map(Array.init)
    struct Vowel { let group:Int;let tone:Int }
    static let lookup:[Character:Vowel] = {
        var map:[Character:Vowel]=[:]
        for (g,forms) in groups.enumerated() {
            for (t,char) in forms.enumerated() {
                let value=Vowel(group:g,tone:t)
                map[char]=value
                if let upper=String(char).uppercased().first {map[upper]=value}
            }
        }
        return map
    }()
    static func base(_ ch:Character)->Character? { lookup[ch].map{groups[$0.group][0]} }
    static func form(_ original:Character,group:Int,tone:Int)->Character {
        let ch=groups[group][tone]
        return original.isUppercase ? Character(String(ch).uppercased()) : ch
    }
    static let onsets:Set<String>=["","b","c","ch","d","đ","g","gh","gi","h","k","kh","l","m","n","ng","ngh","nh","p","ph","q","qu","r","s","t","th","tr","v","x"]
    static let codas:Set<String>=["","c","ch","m","n","ng","nh","p","t"]
    static func nucleus(_ chars:[Character])->[Int] {
        var indices=chars.indices.filter{lookup[chars[$0]] != nil}
        guard indices.count>1 else{return indices}
        let prefix=String(chars.prefix(2)).lowercased()
        if (prefix=="qu" || prefix=="gi"),indices.first==1 {indices.removeFirst()}
        return indices
    }
    static func plausible(_ chars:[Character])->Bool {
        let indices=nucleus(chars)
        guard let first=indices.first,let last=indices.last,indices.count<=3 else{return false}
        let onset=String(chars[..<first]).lowercased()
        let coda=String(chars.dropFirst(last+1)).lowercased()
        return onsets.contains(onset) && codas.contains(coda) && last-first+1==indices.count
    }
    static func toneTarget(_ chars:[Character])->Int? {
        let indices=nucleus(chars)
        guard let first=indices.first,let last=indices.last else{return nil}
        if let shaped=indices.last(where:{i in
            guard let group=lookup[chars[i]]?.group else{return false}
            return [1,2,4,7,8,10].contains(group) && !(group==10 && i+1<chars.count && lookup[chars[i+1]]?.group==8)
        }){return shaped}
        if indices.count==1{return first}
        if indices.count==3{return indices[1]}
        // Closed syllable: tone on the second vowel. Open syllables use
        // modern oa/oe/uy placement, otherwise the first vowel for final glides.
        if last<chars.count-1{return last}
        let pair=String(indices.compactMap{base(chars[$0])})
        if ["oa","oe","uy"].contains(pair){return last}
        if "iouy".contains(base(chars[last]) ?? " "){return first}
        return last
    }
    static func applyingTone(_ chars:[Character],tone:Int)->String? {
        guard plausible(chars),let target=toneTarget(chars),let v=lookup[chars[target]],(0...5).contains(tone) else{return nil}
        var result=chars
        for i in chars.indices {
            if let item=lookup[chars[i]] {result[i]=form(chars[i],group:item.group,tone:0)}
        }
        result[target]=form(chars[target],group:v.group,tone:tone)
        return String(result)
    }
    static func normalize(_ word:String)->String? {
        let chars=Array(word)
        guard chars.count>1,chars.count<=40,plausible(chars) else{return nil}
        let tones=chars.compactMap{lookup[$0]?.tone}.filter{$0>0}
        guard tones.count==1,let result=applyingTone(chars,tone:tones[0]),result != word else{return nil}
        return result
    }
    static func removeTone(_ chars:[Character])->String? {
        var result=chars
        for i in chars.indices {
            if let v=lookup[chars[i]],v.tone>0 {result[i]=form(chars[i],group:v.group,tone:0)}
        }
        return result==chars ? nil : String(result)
    }
    /// A shape may be typed after the final consonant. Retain tone and case.
    static func shape(_ chars:[Character],from:Int,to:Int)->String? {
        guard plausible(chars),let index=nucleus(chars).last(where:{lookup[chars[$0]]?.group==from}),let v=lookup[chars[index]] else{return nil}
        var result=chars;result[index]=form(chars[index],group:to,tone:v.tone)
        let word=String(result)
        return normalize(word) ?? word
    }
    static func horn(_ chars:[Character])->String? {
        guard plausible(chars) else{return nil}
        let indices=nucleus(chars)
        if indices.count>=2 {
            for i in indices.dropLast() where indices.contains(i+1) {
                if let a=lookup[chars[i]],let b=lookup[chars[i+1]],
                   [9,10].contains(a.group),[6,8].contains(b.group),a.group != 10 || b.group != 8 {
                    var result=chars;result[i]=form(chars[i],group:10,tone:a.tone);result[i+1]=form(chars[i+1],group:8,tone:b.tone)
                    let word=String(result);return normalize(word) ?? word
                }
                if let a=lookup[chars[i]],let b=lookup[chars[i+1]],a.group==9,b.group==0 {
                    return shape(chars,from:9,to:10)
                }
            }
        }
        for i in indices.reversed() {
            if let v=lookup[chars[i]],let to=[0:1,6:8,9:10][v.group] {return shape(chars,from:v.group,to:to)}
        }
        return nil
    }
}
