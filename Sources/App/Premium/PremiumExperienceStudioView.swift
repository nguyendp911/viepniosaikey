import SwiftUI

struct PremiumExperienceStudioView: View {
    @State private var prefs = PremiumStore.preferences
    @State private var theme = KeyboardSettings.theme
    @State private var effect = KeyboardSettings.keypressEffect
    private let themes = [("titaniumpro","Titanium Pro"),("liquidglass","Liquid Glass"),("rgbpro","Dynamic RGB"),("jadesignature","Jade Signature")]
    var body: some View {
        VStack(alignment:.leading,spacing:14) {
            Text("Premium Experience").font(.title.bold())
            Text("Giao diện, nhập liệu và phản hồi tùy chỉnh. Mở lại bàn phím để áp dụng. Hiệu ứng tôn trọng chế độ hiệu năng và Reduce Motion.").font(.caption).foregroundStyle(.secondary)
            ForEach(themes,id:\.0) { item in
                Button {
                    theme = item.0; KeyboardSettings.theme = theme
                    if theme == "rgbpro" { effect = "rgb"; KeyboardSettings.keypressEffect = effect }
                } label:{
                    VStack(alignment:.leading,spacing:7) {
                        HStack { Text(item.1).font(.headline); Spacer(); if theme == item.0 { Image(systemName:"checkmark.circle.fill").foregroundStyle(.cyan) } }
                        KeyboardThemePreview(theme:item.0,spacing:KeyboardSettings.keySpacing,height:KeyboardSettings.keyHeight)
                    }.padding(10).background(.white.opacity(0.05),in:RoundedRectangle(cornerRadius:12))
                }.buttonStyle(.plain)
            }
            Picker("Hiệu ứng phím",selection:$effect) { ForEach(KeyboardSettings.availableKeyEffects,id:\.self) { Text($0).tag($0) } }
                .onChange(of:effect){ KeyboardSettings.keypressEffect = $0 }
            Toggle("Ghost Typing · gợi ý phần câu còn lại",isOn:$prefs.ghost)
            Toggle("Dynamic Keyboard · vùng chạm thích ứng phiên gõ",isOn:$prefs.dynamicTouch)
            Text("Dynamic Keyboard không đổi ký tự hoặc vị trí phím; chỉ mở rộng vào nửa khe phím. Cần bật chạm thích ứng.").font(.caption).foregroundStyle(.secondary)
            Picker("Vuốt trên dấu cách",selection:$prefs.spaceGesture) {
                Text("Con trỏ").tag("cursor"); Text("Mở Command").tag("command"); Text("Vuốt trái xóa từ").tag("delete")
            }
            Picker("Âm thanh",selection:$prefs.sound) { Text("Tắt").tag("off"); Text("Click").tag("click"); Text("Nhẹ").tag("soft") }
            Text("Mức rung nhẹ: \(Int(prefs.feedback*100))%")
            Slider(value:$prefs.feedback,in:0.1...1,step:0.05)
            Button("Khôi phục tùy chọn Pro") { prefs = PremiumPreferences() }.buttonStyle(.bordered)
        }.onChange(of:prefs){ PremiumStore.preferences = $0 }
    }
}
