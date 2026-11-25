import Foundation

// Dubeolsik composition with compound vowels/finals and final migration.
// Only operates on a previously inserted, verified syllable.
enum HangulComposer {
    static let initials=Array("ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ")
    static let vowels=Array("ㅏㅐㅑㅒㅓㅔㅕㅖㅗㅘㅙㅚㅛㅜㅝㅞㅟㅠㅡㅢㅣ")
    static let finals=Array(" ㄱㄲㄳㄴㄵㄶㄷㄹㄺㄻㄼㄽㄾㄿㅀㅁㅂㅄㅅㅆㅇㅈㅊㅋㅌㅍㅎ")
    private static let compoundVowels:[String:Character]=["ㅗㅏ":"ㅘ","ㅗㅐ":"ㅙ","ㅗㅣ":"ㅚ","ㅜㅓ":"ㅝ","ㅜㅔ":"ㅞ","ㅜㅣ":"ㅟ","ㅡㅣ":"ㅢ"]
    private static let compoundFinals:[String:Character]=["ㄱㅅ":"ㄳ","ㄴㅈ":"ㄵ","ㄴㅎ":"ㄶ","ㄹㄱ":"ㄺ","ㄹㅁ":"ㄻ","ㄹㅂ":"ㄼ","ㄹㅅ":"ㄽ","ㄹㅌ":"ㄾ","ㄹㅍ":"ㄿ","ㄹㅎ":"ㅀ","ㅂㅅ":"ㅄ"]
    private static func syllable(_ l:Int,_ v:Int,_ t:Int=0)->String {
        String(UnicodeScalar(0xAC00+(l*21+v)*28+t)!)
    }
    static func append(previous:Character?,key:Character)->(remove:Bool,text:String) {
        guard let previous else{return(false,String(key))}
        if let l=initials.firstIndex(of:previous),let v=vowels.firstIndex(of:key){return(true,syllable(l,v))}
        guard let scalar=previous.unicodeScalars.first,previous.unicodeScalars.count==1,(0xAC00...0xD7A3).contains(Int(scalar.value)) else{return(false,String(key))}
        let code=Int(scalar.value)-0xAC00,l=code/(21*28),v=(code/28)%21,t=code%28
        if let newV=vowels.firstIndex(of:key) {
            if t==0,let merged=compoundVowels[String(vowels[v])+String(key)],let index=vowels.firstIndex(of:merged){return(true,syllable(l,index))}
            if t>0 {
                let last=finals[t]
                if let split=compoundFinals.first(where:{$0.value==last})?.key,let first=split.first,let second=split.last,let left=finals.firstIndex(of:first),let right=initials.firstIndex(of:second){return(true,syllable(l,v,left)+syllable(right,newV))}
                if let right=initials.firstIndex(of:last){return(true,syllable(l,v)+syllable(right,newV))}
            }
        } else if let final=finals.firstIndex(of:key),final>0 {
            if t==0{return(true,syllable(l,v,final))}
            if let merged=compoundFinals[String(finals[t])+String(key)],let index=finals.firstIndex(of:merged){return(true,syllable(l,v,index))}
        }
        return(false,String(key))
    }
}
