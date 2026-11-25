import SwiftUI

struct ProUnicodeStudioView:View{
    @State private var query=""
    @State private var favorites=OfflineProStore.favorites
    @State private var composed=""
    @State private var status=""
    private let groups:[(String,String)]=[
        ("Emoji","😀 😍 🥰 😂 😭 😎 ❤️ 💗 ✨ 🔥 👍 🙏 🌸 🌙 ☀️ 🎉 🎁 💎 🫶 🐱 🐶"),
        ("Kaomoji","(•‿•)|(づ｡◕‿‿◕｡)づ|(◕‿◕)|(╯°□°）╯|(⌒‿⌒)|(｡♥‿♥｡)"),
        ("Toán","∞ ∑ ∫ √ ≠ ≈ ≤ ≥ ± π θ λ ∆ ∂ ∀ ∃"),
        ("Mũi tên","→ ← ↑ ↓ ↔ ↕ ⇢ ⇠ ⇒ ⇐ ↗ ↘"),
        ("Trang trí","♡ ♥ ✦ ✧ ✿ ❀ ❁ ★ ☆ ☾ ☽ ❖ ︵ ꧁ ꧂ ༺ ༻"),
        ("Lập trình","⌘ ⌥ ⌃ ⌫ ⏎ {} [] () <> # @ & |"),
        ("ASCII Art","[=^.^=]|<3|:-)|¯\\_(ツ)_/¯")
    ]
    private var symbols:[String]{
        let q=query.trimmingCharacters(in:.whitespacesAndNewlines)
        var values=groups.flatMap{group,raw -> [String] in
            let entries=raw.split(separator:raw.contains("|") && (group=="Kaomoji" || group=="ASCII Art") ? "|" : " ").map(String.init)
            return q.isEmpty || group.localizedCaseInsensitiveContains(q) ? entries : entries.filter{$0.contains(q)}
        }
        if q.uppercased().hasPrefix("U+"),let number=UInt32(q.dropFirst(2),radix:16),let scalar=UnicodeScalar(number),!CharacterSet.controlCharacters.contains(scalar){values.insert(String(scalar),at:0)}
        if q.isEmpty{values=favorites+values}
        var seen=Set<String>();return values.filter{seen.insert($0).inserted}
    }
    var body:some View{
        VStack(alignment:.leading,spacing:12){
            Text("Emoji & Unicode Explorer").font(.title.bold())
            TextField("Tìm nhóm, ký tự hoặc U+1F600",text:$query).textFieldStyle(.roundedBorder)
            Text("Chạm để ghép chuỗi; nhấn giữ để thêm / bỏ yêu thích.").font(.caption).foregroundStyle(.secondary)
            LazyVGrid(columns:[GridItem(.adaptive(minimum:60))],spacing:6){
                ForEach(symbols,id:\.self){value in
                    Button{if composed.count<200{composed+=value}}label:{
                        VStack(spacing:3){Text(value).font(.title3).lineLimit(1).minimumScaleFactor(0.5);if favorites.contains(value){Image(systemName:"star.fill").font(.caption2).foregroundStyle(.yellow)}}
                            .frame(maxWidth:.infinity,minHeight:42).background(.white.opacity(0.07),in:RoundedRectangle(cornerRadius:8))
                    }.buttonStyle(.plain).contextMenu{
                        Button(favorites.contains(value) ? "Bỏ yêu thích" : "Thêm yêu thích"){
                            if favorites.contains(value){favorites.removeAll{$0==value}}else{favorites.insert(value,at:0)}
                            OfflineProStore.favorites=favorites;favorites=OfflineProStore.favorites
                        }
                        Button("Xem mã Unicode"){status=value.unicodeScalars.map{String(format:"U+%04X",$0.value)}.joined(separator:" ")}
                    }
                }
            }
            Text("Emoji Composer").font(.headline)
            TextEditor(text:$composed).frame(minHeight:80)
            PersonalResultActions(text:composed,status:$status)
            Button("Xóa chuỗi"){composed=""}.buttonStyle(.bordered)
            Text(status).font(.caption).foregroundStyle(.secondary)
        }
    }
}
