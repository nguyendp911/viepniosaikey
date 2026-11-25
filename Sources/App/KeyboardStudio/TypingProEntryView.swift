import SwiftUI

/// One user-facing entry point for the existing Pro Input and Everyday engines.
/// The underlying settings and learned data stores retain their original keys.
struct TypingProEntryView: View {
    @State private var open=false
    var body: some View {
        Button{open=true}label:{
            HStack(spacing:14){
                ZStack {
                    RoundedRectangle(cornerRadius:14).fill(.mint.opacity(0.12))
                    Image(systemName:"keyboard").font(.system(size:25,weight:.medium)).foregroundStyle(.mint)
                }.frame(width:50,height:50)
                VStack(alignment:.leading,spacing:5){
                    Text("Typing Premium").font(.system(size:17,weight:.bold)).foregroundStyle(.white)
                    Text("Bộ gõ · Tự học · Cá nhân hóa").font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength:4)
                Image(systemName:"chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.mint)
            }.padding(16)
                .background(LinearGradient(colors:[Color(red:0.09,green:0.17,blue:0.23),Color(red:0.08,green:0.11,blue:0.16)],startPoint:.topLeading,endPoint:.bottomTrailing),in:RoundedRectangle(cornerRadius:18))
                .overlay{RoundedRectangle(cornerRadius:18).strokeBorder(.mint.opacity(0.25))}
        }.buttonStyle(.plain).accessibilityIdentifier("typingPremium.open")
            .sheet(isPresented:$open){
                NavigationStack{
                    TypingPremiumHomeView()
                        .toolbar{ToolbarItem(placement:.cancellationAction){Button("Đóng"){open=false}.accessibilityIdentifier("typingPremium.close")}}
                }.preferredColorScheme(.dark)
            }
    }
}

struct TypingPremiumHomeView: View {
    var body: some View {
        List{
            Section {
                VStack(alignment:.leading,spacing:8){
                    Text("VIETNAMESE FIRST").font(.system(size:10,weight:.bold)).tracking(2).foregroundStyle(.mint)
                    Text("Bộ gõ của bạn").font(.title2.bold())
                    Text("Một nơi để thiết lập sửa lỗi, dự đoán, thao tác phím và quản lý dữ liệu cá nhân. Xử lý offline.").font(.subheadline).foregroundStyle(.secondary)
                }.padding(.vertical,8)
            }
            Section("Ngôn ngữ & nhập liệu"){
                NavigationLink{EverydayLanguageSettings()}label:{
                    row("Gợi ý & chính tả","Tự thêm dấu, AutoCorrect, ngữ cảnh","text.bubble")
                }.accessibilityIdentifier("typingPremium.language")
                NavigationLink{TypingProStudioView()}label:{
                    row("Thao tác gõ & cử chỉ","Dấu câu, Shift, phím xóa, vuốt","hand.tap")
                }.accessibilityIdentifier("typingPremium.gestures")
                NavigationLink{EverydayGeometrySettings()}label:{
                    row("Bố cục & hồ sơ yên lặng","Một tay, màn hình ngang, khe phím","rectangle.split.3x3")
                }.accessibilityIdentifier("typingPremium.geometry")
                NavigationLink{ScrollView{TypingProCalibrationView().padding()}.navigationTitle("Hiệu chỉnh phím")}label:{
                    row("Hiệu chỉnh phím & thao tác riêng","Vùng chạm, phím tắt nhấn giữ","slider.horizontal.3")
                }.accessibilityIdentifier("typingPremium.calibration")
            }
            Section("Dữ liệu tự học"){
                NavigationLink{EverydayPhraseView()}label:{
                    row("Cụm từ đã học","Tìm kiếm, thêm, sửa, ghim, xóa","text.book.closed")
                }.accessibilityIdentifier("typingPremium.phrases")
                NavigationLink{ScrollView{TypingProDictionaryView().padding()}.navigationTitle("Từ điển cá nhân")}label:{
                    row("Từ điển cá nhân","Nhập và xuất TXT, CSV, JSON","book")
                }.accessibilityIdentifier("typingPremium.dictionary")
                NavigationLink{ScrollView{EverydayBackupView().padding()}.navigationTitle("Sao lưu dữ liệu")}label:{
                    row("Sao lưu dữ liệu học mã hóa","Gộp và khôi phục dữ liệu","lock.shield")
                }.accessibilityIdentifier("typingPremium.backup")
            }
            Section("Công cụ & chất lượng"){
                NavigationLink{ScrollView{TypingProRecoveryView().padding()}.navigationTitle("Khôi phục dấu")}label:{
                    row("Khôi phục dấu cả câu","Thử và lựa chọn kết quả","textformat")
                }.accessibilityIdentifier("typingPremium.recovery")
                NavigationLink{ScrollView{TypingProAnalyticsView().padding()}.navigationTitle("Typing Intelligence")}label:{
                    row("Typing Intelligence","Thống kê gõ và sửa lỗi đã học","chart.bar")
                }.accessibilityIdentifier("typingPremium.analytics")
                NavigationLink{ScrollView{EverydayDiagnosticsView().padding()}.navigationTitle("Heatmap & chẩn đoán")}label:{
                    row("Heatmap & chẩn đoán","Vùng chạm, độ trễ, báo cáo lỗi","waveform.path.ecg")
                }.accessibilityIdentifier("typingPremium.diagnostics")
            }
            Section("Trên bàn phím"){
                Text("Công cụ → Typing Premium: khôi phục dấu, dấu câu, định dạng số, hoàn tác, xem trước clipboard, phạm vi văn bản và hồ sơ yên lặng. Các công cụ cũ vẫn có sẵn.").font(.caption).foregroundStyle(.secondary)
                Text("Mở lại bàn phím sau khi thay đổi thiết lập.").font(.caption).foregroundStyle(.secondary)
            }
        }.navigationTitle("Typing Premium").navigationBarTitleDisplayMode(.inline)
    }
    private func row(_ title:String,_ subtitle:String,_ icon:String)->some View{
        HStack(spacing:12){
            Image(systemName:icon).font(.system(size:17,weight:.medium)).foregroundStyle(.mint)
                .frame(width:34,height:34).background(.mint.opacity(0.09),in:RoundedRectangle(cornerRadius:9))
            VStack(alignment:.leading,spacing:4){
                Text(title).font(.subheadline.weight(.semibold))
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
        }.padding(.vertical,3)
    }
}
