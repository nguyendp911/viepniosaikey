import SwiftUI

struct TypingProStudioView:View {
    @State private var prefs=TypingProPreferences.current
    @State private var route:String?
    var body:some View {
        VStack(alignment:.leading,spacing:16){
            Text("Pro Input Experience").font(.title.bold())
            Text("OFFLINE · VIETNAMESE FIRST").font(.caption.bold()).tracking(2).foregroundStyle(.cyan)
            Text("Tùy chọn mới mặc định tắt; không thay đổi các chế độ đã lưu. Mở lại bàn phím để áp dụng. Không có AI hay yêu cầu mạng.").font(.caption).foregroundStyle(.secondary)
            card("Gợi ý và tự học","text.bubble"){
                Toggle("Khôi phục dấu cho từ không dấu",isOn:$prefs.accentRecovery)
                Toggle("Học sửa từ và viết tắt từ lựa chọn",isOn:$prefs.corrections)
                Toggle("Emoji theo ngữ cảnh",isOn:$prefs.contextualEmoji)
                Toggle("Bảo vệ token tiếng Anh/URL",isOn:$prefs.contextualLanguage)
                Stepper("Số lần xác nhận tối thiểu: \(prefs.confidence)",value:$prefs.confidence,in:2...5)
                Text("Cụm từ cũ giữ nguyên, bổ sung trọng số nhẹ theo khung giờ 6 tiếng. Học sửa lỗi chỉ từ thao tác chọn và hoàn tác; không tự thay văn bản.").font(.caption).foregroundStyle(.secondary)
                Toggle("Swipe nhiều từ thử nghiệm",isOn:$prefs.sentenceGlide)
                Text("Chỉ đề xuất cụm đã học hoặc mẫu có đường vuốt khớp; vẫn giữ nhận diện từng từ.").font(.caption).foregroundStyle(.secondary)
            }
            card("Thao tác nhập liệu","hand.tap"){
                Toggle("Tự đóng ngoặc/dấu nháy",isOn:$prefs.pairing)
                Toggle("Hai dấu cách thành dấu chấm",isOn:$prefs.doubleSpace)
                Toggle("Shift một chạm, khóa hoa hai chạm",isOn:$prefs.smartShift)
                Toggle("Pop-up ký tự",isOn:$prefs.popup)
                Toggle("Kéo phím xóa để chọn phạm vi",isOn:$prefs.backspacePan)
                Toggle("Lặp phím xóa khi giữ",isOn:$prefs.repeatEnabled)
                if prefs.repeatEnabled {
                    Text("Khoảng lặp: \(Int(prefs.deleteRepeat*1000)) ms").font(.caption)
                    Slider(value:$prefs.deleteRepeat,in:0.08...0.5,step:0.02)
                }
                Toggle("Vuốt lên dấu cách mở cụm từ",isOn:$prefs.spaceUp)
                Text("Vuốt lên chỉ dùng khi cử chỉ dấu cách hiện tại là con trỏ. Giữ nguyên các cử chỉ cũ.").font(.caption).foregroundStyle(.secondary)
            }
            card("Cá nhân hóa","slider.horizontal.3"){
                Toggle("Hiệu chỉnh vùng chạm cá nhân",isOn:$prefs.touchCalibration)
                Button("Hiệu chỉnh phím & thao tác riêng"){route="touch"}.buttonStyle(.bordered)
                Button("Nhập/xuất từ điển cá nhân"){route="dictionary"}.buttonStyle(.bordered)
                Button("Khôi phục dấu · thử nghiệm"){route="accent"}.buttonStyle(.bordered)
                Button("Typing Intelligence Dashboard"){route="analytics"}.buttonStyle(.bordered)
            }
            Text("Khôi phục dấu cả câu, dấu câu, định dạng số và kiểm tra sửa từ cũng có trong Công cụ → Typing Pro.").font(.caption).foregroundStyle(.secondary)
        }.onChange(of:prefs){TypingProPreferences.current=$0}
            .sheet(isPresented:Binding(get:{route != nil},set:{if !$0{route=nil}})){
                NavigationStack{
                    ScrollView{
                        VStack(alignment:.leading,spacing:14){
                            switch route {
                            case "touch": TypingProCalibrationView()
                            case "dictionary": TypingProDictionaryView()
                            case "accent": TypingProRecoveryView()
                            case "analytics": TypingProAnalyticsView()
                            default: EmptyView()
                            }
                        }.padding()
                    }.navigationTitle("Typing Pro").navigationBarTitleDisplayMode(.inline)
                        .toolbar{ToolbarItem(placement:.cancellationAction){Button("Đóng"){route=nil}}}
                }.preferredColorScheme(.dark)
            }
    }
    private func card<C:View>(_ title:String,_ symbol:String,@ViewBuilder content:()->C)->some View{
        VStack(alignment:.leading,spacing:12){
            Label(title,systemImage:symbol).font(.headline).foregroundStyle(.cyan)
            content()
        }.padding(14).frame(maxWidth:.infinity,alignment:.leading)
            .background(.white.opacity(0.055),in:RoundedRectangle(cornerRadius:15))
    }
}
