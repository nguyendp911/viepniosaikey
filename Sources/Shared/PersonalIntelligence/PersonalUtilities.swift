import Foundation

enum PersonalUnits {
    struct Unit: Identifiable {
        let id:String
        let name:String
        let factor:Double
        let offset:Double
        init(_ id:String,_ name:String,_ factor:Double,_ offset:Double = 0) { self.id=id; self.name=name; self.factor=factor; self.offset=offset }
    }
    static let groups:[String:[Unit]] = [
        "Chiều dài":[.init("m","m",1),.init("km","km",1000),.init("cm","cm",0.01),.init("in","inch",0.0254),.init("ft","feet",0.3048)],
        "Khối lượng":[.init("kg","kg",1),.init("g","g",0.001),.init("lb","lb",0.45359237),.init("oz","oz",0.028349523125)],
        "Thời gian":[.init("s","Giây",1),.init("min","Phút",60),.init("h","Giờ",3600),.init("d","Ngày",86400)],
        "Thể tích":[.init("l","Lít",1),.init("ml","mL",0.001),.init("gal","US gallon",3.785411784)],
        "Nhiệt độ":[.init("c","°C",1),.init("f","°F",5.0/9,-32*5.0/9),.init("k","Kelvin",1,-273.15)]
    ]
    static func convert(_ value:Double, group:String, from:String, to:String) -> Double? {
        guard value.isFinite, let units=groups[group], let a=units.first(where:{$0.id==from}), let b=units.first(where:{$0.id==to}) else { return nil }
        let base = value*a.factor+a.offset
        guard group != "Nhiệt độ" || base >= -273.15-0.000001 else { return nil }
        let result = (base-b.offset)/b.factor
        return result.isFinite ? result : nil
    }
    static func currency(_ value:Double, rate:Double)->Double? {
        let result=value*rate
        return value.isFinite && rate.isFinite && rate>0 && result.isFinite ? result : nil
    }
}
enum SecureTextGenerator {
    static func password(length:Int, symbols:Bool)->String {
        let sets = ["abcdefghijkmnopqrstuvwxyz","ABCDEFGHJKLMNPQRSTUVWXYZ","23456789"] + (symbols ? ["!@#$%&*+-=?"] : [])
        var rng = SystemRandomNumberGenerator()
        let n = min(64,max(12,length))
        var chars = sets.compactMap { $0.randomElement(using:&rng) }
        let pool = sets.joined()
        while chars.count<n { if let char=pool.randomElement(using:&rng) { chars.append(char) } }
        return String(chars.shuffled(using:&rng))
    }
}
enum PersonalDiff {
    struct Row: Identifiable, Equatable {
        let id:Int
        let kind:String
        let text:String
    }
    static func compare(_ original:String,_ revised:String)->[Row] {
        let a=Array(original.prefix(3000).split(whereSeparator:{$0.isWhitespace}).prefix(240)).map(String.init)
        let b=Array(revised.prefix(3000).split(whereSeparator:{$0.isWhitespace}).prefix(240)).map(String.init)
        var dp=Array(repeating:Array(repeating:0,count:b.count+1),count:a.count+1)
        if !a.isEmpty && !b.isEmpty {
            for i in (0..<a.count).reversed() { for j in (0..<b.count).reversed() { dp[i][j]=a[i]==b[j] ? dp[i+1][j+1]+1 : max(dp[i+1][j],dp[i][j+1]) } }
        }
        var i=0,j=0
        var rows:[Row]=[]
        while i<a.count || j<b.count {
            if i<a.count && j<b.count && a[i]==b[j] { rows.append(.init(id:rows.count,kind:"same",text:a[i])); i+=1;j+=1 }
            else if i<a.count && (j==b.count || dp[i+1][j]>=dp[i][j+1]) { rows.append(.init(id:rows.count,kind:"remove",text:a[i]));i+=1 }
            else { rows.append(.init(id:rows.count,kind:"add",text:b[j]));j+=1 }
        }
        return rows
    }
}
enum ReminderDateHint {
    static func parse(_ text:String, calendar:Calendar = .current)->Date? {
        // Explicit full date and time only. Never guess missing year or timezone.
        let pattern = #"(?<!\d)(\d{1,2})/(\d{1,2})/(\d{4})\s+(\d{1,2}):(\d{2})(?!\d)"#
        guard let regex=try? NSRegularExpression(pattern:pattern),let match=regex.firstMatch(in:text,range:NSRange(text.startIndex...,in:text)) else { return nil }
        let ns=text as NSString
        let nums=(1...5).compactMap { Int(ns.substring(with:match.range(at:$0))) }
        guard nums.count==5,(1...31).contains(nums[0]),(1...12).contains(nums[1]),(2000...2100).contains(nums[2]),(0...23).contains(nums[3]),(0...59).contains(nums[4]) else { return nil }
        let components=DateComponents(year:nums[2],month:nums[1],day:nums[0],hour:nums[3],minute:nums[4])
        guard let date=calendar.date(from:components) else { return nil }
        let actual=calendar.dateComponents([.year,.month,.day,.hour,.minute],from:date)
        return actual.year==nums[2] && actual.month==nums[1] && actual.day==nums[0] && actual.hour==nums[3] && actual.minute==nums[4] ? date : nil
    }
}
