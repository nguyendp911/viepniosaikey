import SwiftUI

/// The input controls formerly displayed in the 6.0 studio.
struct TypingProStudioView: View {
    @State private var prefs=TypingProPreferences.current
    @State private var everyday=EverydayPreferences.current
    var body: some View {
        Form {
            Section("Nhập liệu"){
                Toggle("Tự đóng ngoặc/dấu nháy",isOn:$prefs.pairing)
                Toggle("Hai dấu cách thành dấu chấm",isOn:$prefs.doubleSpace)
                Toggle("Tránh lặp dấu cách",isOn:$everyday.preventSpaces)
                Text("Ngăn lặp dấu cách không thay thế thao tác hai dấu cách thành dấu chấm.").font(.caption).foregroundStyle(.secondary)
                Toggle("Shift một chạm, khóa hoa hai chạm",isOn:$prefs.smartShift)
                Toggle("Pop-up ký tự",isOn:$prefs.popup)
            }
            Section("Phím xóa"){
                Toggle("Kéo phím xóa để chọn phạm vi",isOn:$prefs.backspacePan)
                Toggle("Lặp phím xóa khi giữ",isOn:$prefs.repeatEnabled)
                if prefs.repeatEnabled {
                    Text("Khoảng lặp: \(Int(prefs.deleteRepeat*1000)) ms").font(.caption)
                    Slider(value:$prefs.deleteRepeat,in:0.08...0.5,step:0.02)
                }
            }
            Section("Cử chỉ"){
                Toggle("Vuốt lên dấu cách mở cụm từ",isOn:$prefs.spaceUp)
                Text("Vuốt lên chỉ dùng khi cử chỉ dấu cách hiện tại là con trỏ. Nếu tắt mục này, Live Text Completion có thể dùng cử chỉ vuốt lên để chèn câu. Giữ nguyên các cử chỉ cũ.").font(.caption).foregroundStyle(.secondary)
                Toggle("Swipe nhiều từ thử nghiệm",isOn:$prefs.sentenceGlide)
                Text("Chỉ đề xuất cụm đã học hoặc mẫu có đường vuốt khớp; vẫn giữ nhận diện từng từ.").font(.caption).foregroundStyle(.secondary)
            }
            Section("Vùng chạm"){
                Toggle("Hiệu chỉnh vùng chạm cá nhân",isOn:$prefs.touchCalibration)
                NavigationLink("Hiệu chỉnh phím & thao tác riêng"){
                    ScrollView{TypingProCalibrationView().padding()}.navigationTitle("Hiệu chỉnh phím")
                }
            }
        }.navigationTitle("Thao tác gõ & cử chỉ")
            .onChange(of:prefs){TypingProPreferences.current=$0}
            .onChange(of:everyday){EverydayPreferences.current=$0}
    }
}
