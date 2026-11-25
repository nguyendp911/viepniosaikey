import Foundation

enum VietnameseVNI {
    static func transformed(word:String,key:String)->String? {
        guard word.count<=40,key.count==1,let digit=key.first,"0123456789".contains(digit),!word.isEmpty else{return nil}
        var chars=Array(word)
        let rules=VietnameseOrthography.self
        if digit=="9",let first=chars.first,first.lowercased()=="d" {chars[0]=first.isUppercase ? "Đ":"đ";return String(chars)}
        if digit=="0"{return rules.removeTone(chars)}
        guard rules.plausible(chars) else{return nil}
        if let tone=digit.wholeNumberValue,(1...5).contains(tone) {
            guard let result=rules.applyingTone(chars,tone:tone),result != word else{return nil}
            return result
        }
        if digit=="7" {
            // VNI 7 shapes horns, never breve.
            let indices=rules.nucleus(chars)
            if indices.contains(where:{rules.lookup[chars[$0]]?.group==9 || rules.lookup[chars[$0]]?.group==6}) {return rules.horn(chars)}
        }
        if digit=="6" {
            for i in rules.nucleus(chars).reversed() {
                if let v=rules.lookup[chars[i]],let to=[0:2,3:4,6:7][v.group] {return rules.shape(chars,from:v.group,to:to)}
            }
        }
        if digit=="8"{return rules.shape(chars,from:0,to:1)}
        return nil
    }
}
