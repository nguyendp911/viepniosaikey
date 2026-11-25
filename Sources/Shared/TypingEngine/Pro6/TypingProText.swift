import Foundation

enum TypingProText {
    static func fold(_ text:String)->String {
        text.lowercased().folding(options:[.diacriticInsensitive],locale:Locale(identifier:"vi_VN")).replacingOccurrences(of:"đ",with:"d")
    }
    static let examples = [
        "em ăn gì chưa nè","em ăn cơm chưa","anh đang làm gì","hôm nay em có mệt không","anh nhớ em nhiều lắm",
        "chúc em ngủ ngon","chúc bạn một ngày tốt lành","cảm ơn bạn rất nhiều","tôi đang đi làm","mình gặp nhau nhé",
        "bạn có khỏe không","xin chào mọi người","hẹn gặp lại ngày mai","tôi muốn học tiếng việt","em đang ở đâu",
        "anh về nhà chưa","hôm nay trời đẹp","mình đi ăn cơm nhé","em có muốn đi chơi không","anh yêu em",
        "công việc hôm nay thế nào","tôi cần giúp đỡ","tôi không biết","chúc mừng sinh nhật","rất vui được gặp bạn"
    ]
    static func recover(_ source:String, vocabulary:[String], learned:[String:Int]=[:],limit:Int=3)->[String] {
        let words=source.split(whereSeparator:{$0.isWhitespace}).map(String.init)
        guard (1...16).contains(words.count),source.count<=180,words.allSatisfy({$0.allSatisfy(\.isLetter)}) else{return []}
        let folded=words.map(fold)
        var results=examples.filter{$0.split(separator:" ").map{fold(String($0))}==folded}
        let wanted=Set(folded)
        var buckets:[String:[String]]=[:]
        for word in vocabulary + Array(learned.keys) {
            let key=fold(word)
            if wanted.contains(key),!buckets[key,default:[]].contains(word){buckets[key,default:[]].append(word)}
        }
        // Bounded beam: alternatives, not an automatic spelling replacement.
        var beam:[(String,Int)]=[("",0)]
        for (i,key) in folded.enumerated() {
            var options=buckets[key] ?? []
            if !options.contains(words[i]){options.append(words[i])}
            options.sort {
                let a=learned[$0] ?? 0,b=learned[$1] ?? 0
                if a != b{return a>b}
                if ($0==words[i]) != ($1==words[i]){return $0 != words[i]}
                return $0<$1
            }
            var next:[(String,Int)]=[]
            for (prefix,score) in beam {
                for (rank,word) in options.prefix(5).enumerated() {
                    let rendered=words[i].first?.isUppercase==true ? word.prefix(1).uppercased()+word.dropFirst() : word
                    next.append((prefix+(prefix.isEmpty ? "" : " ")+rendered,score-rank+min(10,learned[word] ?? 0)))
                }
            }
            beam=Array(next.sorted{$0.1==$1.1 ? $0.0<$1.0 : $0.1>$1.1}.prefix(6))
        }
        results+=beam.map(\.0)
        var seen=Set<String>()
        return Array(results.filter{$0 != source && seen.insert($0).inserted}.prefix(max(0,min(5,limit))))
    }
    static func punctuation(_ text:String)->[String] {
        let clean=text.trimmingCharacters(in:.whitespacesAndNewlines)
        guard !clean.isEmpty,clean.last?.isLetter==true else{return []}
        let last=clean.split(separator:" ").last.map(String.init)?.lowercased() ?? ""
        return ["không","chưa","hả","sao","gì","nào","đâu","nhỉ"].contains(last) ? [clean+"?",clean+"."] : [clean+".",clean+"!"]
    }
    static func pair(_ key:String)->String? { ["(":")","[":"]","{":"}","\"":"\"","“":"”","‘":"’"][key] }
    static func grouping(_ source:String)->String? {
        guard (4...15).contains(source.count),source.allSatisfy({$0.isASCII && $0.isNumber}),source.first != "0" else{return nil}
        return String(String(source.reversed().enumerated().map{($0.offset>0 && $0.offset%3==0 ? "." : "")+String($0.element)}.joined()).reversed())
    }
    static func deletionCount(_ text:String,words:Int)->Int {
        var remaining=Array(text.suffix(160).reversed()), count=0
        for _ in 0..<max(0,min(5,words)) {
            let spaces=remaining.prefix(while:{$0.isWhitespace}).count
            remaining.removeFirst(spaces);count+=spaces
            let length=remaining.prefix(while:{$0.isLetter || $0.isNumber}).count
            let n=length==0 && !remaining.isEmpty ? 1 : length
            remaining.removeFirst(n);count+=n
        }
        return count
    }
    static func emoji(_ word:String)->[String] {
        let map=["yêu":["❤️","🥰"],"nhớ":["💗","🥺"],"vui":["😊","🎉"],"buồn":["😢","💙"],"ngủ":["😴","🌙"],"cảm ơn":["🙏"],"chúc mừng":["🎉","🎂"],"ăn":["🍚","😋"]]
        return map[word.lowercased()] ?? []
    }
    static func dictionary(_ text:String,format:String)->[String] {
        guard text.utf8.count<=100_000 else{return []}
        let values:[String]
        if format=="json" {
            values=(try? JSONDecoder().decode([String].self,from:Data(text.utf8))) ?? []
        } else if format=="csv" {
            values=text.components(separatedBy:.newlines).compactMap{$0.split(separator:",",omittingEmptySubsequences:false).first.map{String($0).trimmingCharacters(in:CharacterSet(charactersIn:"\""))}}
        } else { values=text.components(separatedBy:.newlines) }
        var seen=Set<String>()
        return Array(values.map{$0.trimmingCharacters(in:.whitespacesAndNewlines).lowercased().precomposedStringWithCanonicalMapping}.filter{$0.count>=2 && $0.count<=24 && $0.allSatisfy(\.isLetter) && seen.insert($0).inserted}.prefix(500))
    }
}
