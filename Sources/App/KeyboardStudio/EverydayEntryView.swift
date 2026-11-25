import SwiftUI

struct EverydayEntryView:View {
    @State private var open=false
    var body:some View {
        Button{open=true}label:{
            HStack(spacing:12){
                Image(systemName:"text.cursor").font(.title2).foregroundStyle(.mint).frame(width:46,height:46)
                    .background(.mint.opacity(0.12),in:RoundedRectangle(cornerRadius:12))
                VStack(alignment:.leading,spacing:5){
                    Text("Typing Premium 7.0").font(.headline).foregroundStyle(.white)
                    Text("Everyday · Dữ liệu học · Chẩn đoán").font(.caption).foregroundStyle(.secondary)
                };Spacer();Image(systemName:"chevron.right").font(.caption).foregroundStyle(.secondary)
            }.padding(15).background(Color(red:0.09,green:0.15,blue:0.19),in:RoundedRectangle(cornerRadius:16))
        }.buttonStyle(.plain).accessibilityIdentifier("everyday7.open")
            .sheet(isPresented:$open){
                NavigationStack{
                    List{
                        NavigationLink("Cụm từ đã học"){EverydayPhraseView()}
                        NavigationLink("Sao lưu dữ liệu học mã hóa"){ScrollView{EverydayBackupView().padding()}}
                        NavigationLink("Gợi ý & chính tả"){EverydayLanguageSettings()}
                        NavigationLink("Bố cục & hồ sơ yên lặng"){EverydayGeometrySettings()}
                        NavigationLink("Heatmap & chẩn đoán"){ScrollView{EverydayDiagnosticsView().padding()}}
                        Section("Công cụ ngay trên bàn phím"){
                            Text("Công cụ → Everyday: xem trước clipboard, phạm vi văn bản, kiểm tra chính tả, hồ sơ yên lặng. Nhấn giữ nút Dán để xem trước và dán.").font(.caption)
                        }
                    }.navigationTitle("Everyday 7.0").navigationBarTitleDisplayMode(.inline)
                        .toolbar{ToolbarItem(placement:.cancellationAction){Button("Đóng"){open=false}.accessibilityIdentifier("everyday7.close")}}
                }.preferredColorScheme(.dark)
            }
    }
}
struct EverydayLanguageSettings:View {
    @State private var prefs=EverydayPreferences.current
    @State private var correction=VietnameseAutoCorrectSettings.current
    var body:some View {
        Form{
            Section("Vietnamese AutoCorrect Pro"){
                Picker("Chế độ sửa",selection:$correction.mode){
                    Text("Tắt").tag("off");Text("Chỉ gợi ý").tag("suggest");Text("Tự sửa thận trọng").tag("careful");Text("Tự sửa nâng cao").tag("advanced")
                }
                Toggle("Tự thêm dấu tiếng Việt",isOn:$correction.restoreAccents)
                Text("Tự sửa khi chốt từ bằng dấu cách, dấu câu hoặc xuống dòng nếu đủ ngữ cảnh. Nhấn xóa ngay sau khi tự sửa để khôi phục từ gốc. Từ mơ hồ chỉ gợi ý. Không tự sửa trong chế độ English hoặc riêng tư. Mở lại bàn phím để áp dụng.").font(.caption)
            }
            Section("Dự đoán"){
                Toggle("Live Text Completion",isOn:$prefs.liveCompletion)
                Toggle("Vuốt lên thanh gợi ý để mở rộng",isOn:$prefs.expandedBar)
                Text("Chữ mờ nằm trong thanh gợi ý, không phải trong ô nhập của ứng dụng khác. Chạm để chèn; vuốt lên dấu cách khi không dùng cử chỉ 6.0.").font(.caption)
            }
            Section("Tiếng Việt"){
                Toggle("Kiểm tra chính tả (chỉ đề xuất)",isOn:$prefs.spellCheck)
                Toggle("Gợi ý mở rộng viết tắt",isOn:$prefs.abbreviations)
                Picker("Từ ngữ vùng miền",selection:$prefs.regional){
                    Text("Không ưu tiên").tag("all");Text("Miền Bắc").tag("north");Text("Miền Trung").tag("central");Text("Miền Nam").tag("south")
                }
                Picker("Cách đặt dấu",selection:$prefs.accentStyle){
                    Text("Như trước").tag("existing");Text("hoà · thuỷ").tag("modern");Text("hòa · thủy").tag("traditional")
                }
                Toggle("Tránh lặp dấu cách",isOn:$prefs.preventSpaces)
                Text("Không sửa tự động các biến thể vùng miền. Ngăn lặp dấu cách không thay thế Double Space 6.0. Cách đặt dấu áp dụng cho oa/oe/uy mở.").font(.caption)
            }
        }.navigationTitle("Gợi ý & chính tả").onChange(of:prefs){EverydayPreferences.current=$0}
            .onChange(of:correction){VietnameseAutoCorrectSettings.current=$0}
    }
}
struct EverydayGeometrySettings:View {
    @State private var prefs=EverydayPreferences.current
    @State private var hand=KeyboardSettings.oneHandMode
    var body:some View {
        Form{
            Section("Bố cục nâng cao"){
                Toggle("Dùng bố cục Everyday",isOn:$prefs.geometry)
                Picker("Một tay",selection:$hand){
                    Text("Tắt").tag("off");Text("Trái").tag("left");Text("Phải").tag("right")
                }.onChange(of:hand){KeyboardSettings.oneHandMode=$0}
                Stepper("Rộng một tay dọc: \(prefs.portraitWidth)%",value:$prefs.portraitWidth,in:80...100)
                Stepper("Rộng ngang: \(prefs.landscapeWidth)%",value:$prefs.landscapeWidth,in:75...100)
                Stepper("Cao phím ngang: \(prefs.landscapeHeight) pt",value:$prefs.landscapeHeight,in:34...49)
                ForEach(0..<4){index in
                    Stepper("Khe hàng \(index+1): \(prefs.rowSpacing[index]) pt",value:$prefs.rowSpacing[index],in:3...9)
                }
                Text("Chiều rộng tối thiểu và khe chạm an toàn được giới hạn theo màn hình. Mở lại bàn phím để áp dụng.").font(.caption)
            }
            Section("Hồ sơ"){
                Toggle("Yên lặng",isOn:$prefs.silent)
                Text("Chỉ tạm bỏ âm/rung khi bạn chọn hồ sơ này. Thoát hồ sơ sẽ dùng lại thiết lập cũ.").font(.caption)
            }
        }.navigationTitle("Bố cục").onChange(of:prefs){EverydayPreferences.current=$0}
    }
}
