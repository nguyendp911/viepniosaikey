import SwiftUI

struct ProKeyboardPreview:View {
    let config:OfflineKeyboardConfig
    var theme=KeyboardSettings.theme
    var body:some View {
        let palette=KeyboardThemePalette.resolve(theme)
        VStack(spacing:5){
            if config.numberRow { row("1234567890",height:24,palette:palette) }
            ForEach(config.layout.rows(shift:false,custom:config.customRows),id:\.self){keys in row(keys,height:34,palette:palette)}
            HStack(spacing:5){
                cap("123",height:31,palette:palette)
                cap("🌐",height:31,palette:palette)
                Text("dấu cách").font(.caption).frame(maxWidth:.infinity,minHeight:31).background(Color(uiColor:palette.key),in:RoundedRectangle(cornerRadius:CGFloat(config.radius)))
                cap("↵",height:31,palette:palette)
            }
        }.foregroundStyle(Color(uiColor:palette.text)).padding(8).background(Color(uiColor:palette.canvas),in:RoundedRectangle(cornerRadius:14))
    }
    private func row(_ keys:String,height:CGFloat,palette:KeyboardThemePalette)->some View {
        HStack(spacing:4){ForEach(Array(keys.enumerated()),id:\.offset){_,char in cap(String(char),height:height,palette:palette)}}
    }
    private func cap(_ key:String,height:CGFloat,palette:KeyboardThemePalette)->some View {
        Text(key).font(.system(size:15,weight:.medium)).frame(maxWidth:.infinity,minHeight:height)
            .background(Color(uiColor:palette.key).opacity(config.keycap=="crystal" ? 0.65 : 1),in:RoundedRectangle(cornerRadius:CGFloat(config.radius)))
            .overlay{RoundedRectangle(cornerRadius:CGFloat(config.radius)).strokeBorder(config.keycap=="flat" ? Color.clear : Color(uiColor:palette.text).opacity(0.3))}
            .shadow(color:.black.opacity(config.keycap=="mechanical" ? 0.5 : 0),radius:1,y:3)
    }
}
struct ProLayoutStudioView:View{
    @State private var config=OfflineKeyboardConfig.current
    @State private var status=""
    var body:some View{
        VStack(alignment:.leading,spacing:14){
            Text("Layout Designer").font(.title.bold())
            Picker("Bố cục",selection:$config.layout){ForEach(ProLayout.allCases,id:\.self){Text($0.title).tag($0)}}
            ProKeyboardPreview(config:config)
            if config.layout == .custom {
                Text("Nhập 3 hàng 10 / 9 / 7 ký tự, đủ 26 chữ Latin không trùng.").font(.caption).foregroundStyle(.secondary)
                ForEach(0..<3){i in TextField("Hàng \(i+1)",text:$config.customRows[i]).textFieldStyle(.roundedBorder).textInputAutocapitalization(.never).autocorrectionDisabled()}
                Text(ProLayout.valid(config.customRows) ? "Bố cục hợp lệ" : "Bố cục chưa hợp lệ").font(.caption)
            }
            if !config.layout.latin { Text("Hangul ghép âm tiết Dubeolsik; Kana/Cyrillic nhập ký tự trực tiếp. Ký tự bổ sung trong Keyboard Pro. Không có bộ chuyển Kanji hoặc dự đoán từ riêng cho các ngôn ngữ này.").font(.caption).foregroundStyle(.secondary) }
            Toggle("Hàng số riêng",isOn:$config.numberRow)
            Toggle("Ưu tiên không gian dấu cách",isOn:$config.wideSpace)
            Toggle("Multi-Tap · nhấn giữ và vuốt phím",isOn:$config.multiTap)
            Text("Multi-Tap dùng chạm thả và tạm tắt Glide để tránh xung đột.").font(.caption).foregroundStyle(.secondary)
            Picker("Precision Trackpad",selection:$config.trackpad){Text("Theo ký tự").tag("character");Text("Theo từ").tag("word");Text("Tăng tốc").tag("accelerated")}
            Toggle("Text Time Machine · 30 bước",isOn:$config.history)
            Text("Chỉ lưu trong RAM phiên hiện tại; hoàn tác khi ngữ cảnh iOS còn khớp. Không ghi lại nội dung khi gõ riêng tư.").font(.caption).foregroundStyle(.secondary)
            Button("Lưu & áp dụng"){
                guard config.layout != .custom || ProLayout.valid(config.customRows) else{status="Hãy sửa 3 hàng trước.";return}
                OfflineKeyboardConfig.current=config;status="Đã lưu. Mở lại bàn phím."
            }.buttonStyle(.borderedProminent)
            Text(status).font(.caption).foregroundStyle(.cyan)
        }
    }
}
