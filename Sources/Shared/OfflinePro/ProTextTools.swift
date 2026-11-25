import Foundation

enum ProTextTools {
    static let modes=["Bold","Script","Gothic","Double Stroke","Monospace","Circled","Full Width","Reverse","Strike","Decorative"]
    static func stylize(_ source:String,mode:String)->String {
        let text=String(source.prefix(3000))
        if mode=="Reverse"{return String(text.reversed())}
        if mode=="Strike"{return text.map{String($0)+"\u{0336}"}.joined()}
        if mode=="Decorative"{return "꧁༺ "+text+" ༻꧂"}
        let bases:[String:(UInt32,UInt32,UInt32)]=["Bold":(0x1D400,0x1D41A,0x1D7CE),"Script":(0x1D4D0,0x1D4EA,0),"Gothic":(0x1D56C,0x1D586,0),"Double Stroke":(0x1D538,0x1D552,0x1D7D8),"Monospace":(0x1D670,0x1D68A,0x1D7F6),"Circled":(0x24B6,0x24D0,0),"Full Width":(0xFF21,0xFF41,0xFF10)]
        guard let (upper,lower,digit)=bases[mode] else{return text}
        let doubleExceptions:[Character:String]=["C":"ℂ","H":"ℍ","N":"ℕ","P":"ℙ","Q":"ℚ","R":"ℝ","Z":"ℤ"]
        return text.map{ch -> String in
            if mode=="Double Stroke",let special=doubleExceptions[ch]{return special}
            guard ch.unicodeScalars.count==1,let scalar=ch.unicodeScalars.first else{return String(ch)}
            let n=scalar.value
            let mapped:UInt32
            if (65...90).contains(n){mapped=upper+n-65}
            else if (97...122).contains(n){mapped=lower+n-97}
            else if (48...57).contains(n),digit>0{mapped=digit+n-48}
            else{return String(ch)}
            return UnicodeScalar(mapped).map(String.init) ?? String(ch)
        }.joined()
    }
    static func clean(_ text:String)->String {
        var seen=Set<String>()
        return String(text.prefix(6000)).components(separatedBy:.newlines).map{$0.split(whereSeparator:{$0.isWhitespace}).joined(separator:" ")}.filter{!$0.isEmpty && seen.insert($0).inserted}.joined(separator:"\n")
    }
    static func stats(_ text:String)->String {
        let words=text.split(whereSeparator:{$0.isWhitespace}).count
        return "\(words) từ · \(text.count) ký tự · \(text.components(separatedBy:.newlines).count) dòng · ~\(Int(ceil(Double(words)/200))) phút đọc"
    }
    static func table(_ input:String)->String {
        let rows=String(input.prefix(6000)).components(separatedBy:.newlines).prefix(30).map{line in line.split(separator:"|",omittingEmptySubsequences:false).prefix(8).map{$0.trimmingCharacters(in:.whitespaces)}}
        guard let first=rows.first,!first.isEmpty else{return ""}
        let width=first.count
        func line(_ row:[String])->String{"| "+(row+Array(repeating:"",count:max(0,width-row.count))).prefix(width).joined(separator:" | ")+" |"}
        return ([line(first),line(Array(repeating:"---",count:width))]+rows.dropFirst().map(line)).joined(separator:"\n")
    }
    static func encode(_ text:String,mode:String)->String? {
        let bytes=Data(text.prefix(6000).utf8)
        switch mode {
        case "Base64":return bytes.base64EncodedString()
        case "Decode Base64":return Data(base64Encoded:String(text.prefix(8000))).flatMap{String(data:$0,encoding:.utf8)}
        case "URL":return text.addingPercentEncoding(withAllowedCharacters:CharacterSet.alphanumerics.union(CharacterSet(charactersIn:"-._~")))
        case "Decode URL":return text.removingPercentEncoding
        case "Hex":return bytes.map{String(format:"%02X",$0)}.joined(separator:" ")
        case "Binary":return bytes.map{let v=String($0,radix:2);return String(repeating:"0",count:8-v.count)+v}.joined(separator:" ")
        case "Morse":
            let letters=Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
            let codes=[".-","-...","-.-.","-..",".","..-.","--.","....","..",".---","-.-",".-..","--","-.","---",".--.","--.-",".-.","...","-","..-","...-",".--","-..-","-.--","--..","-----",".----","..---","...--","....-",".....","-....","--...","---..","----."]
            let map=Dictionary(uniqueKeysWithValues:zip(letters,codes))
            return text.uppercased().map{$0.isWhitespace ? "/" : map[$0] ?? "?"}.joined(separator:" ")
        default:return nil
        }
    }
    static func link(_ input:String,utm:String,remove:Bool)->String? {
        guard var c=URLComponents(string:input),["https","http"].contains(c.scheme?.lowercased() ?? ""),c.host != nil else{return nil}
        var items=c.queryItems ?? []
        if remove{items.removeAll{$0.name.lowercased().hasPrefix("utm_") || ["fbclid","gclid","igshid","mc_cid","mc_eid"].contains($0.name.lowercased())}}
        if !utm.isEmpty{items.removeAll{$0.name=="utm_source"};items.append(URLQueryItem(name:"utm_source",value:utm))}
        c.queryItems=items.isEmpty ? nil : items
        return c.url?.absoluteString
    }
    static func replace(_ source:String,find:String,replacement:String)->String {
        guard !find.isEmpty else{return source}
        return String(String(source.prefix(6000)).replacingOccurrences(of:find,with:replacement).prefix(12000))
    }
}
struct ProTypingStats: Codable, Equatable {
    var taps=0
    var seconds=0.0
    var sessions=0
    var approximateWPM:Double { seconds>0 ? Double(taps)/5/(seconds/60) : 0 }
    static var current:Self { OfflineProStore.read("stats",.init()) }
    static func add(taps:Int,seconds:Double) {
        guard taps>0,seconds>0 else{return}
        var s=current;s.taps+=taps;s.seconds+=seconds;s.sessions+=1;OfflineProStore.write(s,"stats")
    }
}
