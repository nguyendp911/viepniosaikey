import SwiftUI

struct TypingProAnalyticsView:View{
    @State private var feedback=TypingProFeedback()
    @State private var stats=ProTypingStats()
    @State private var count:Int?
    @State private var confirm=false
    var body:some View{
        VStack(alignment:.leading,spacing:14){
            Text("Typing Intelligence").font(.title2.bold())
            Text("Số liệu thực tế trên máy. Không suy ra độ chính xác toàn bộ nội dung gõ từ số lần sửa. WPM là xấp xỉ theo lượt chạm và thời gian phiên nếu bật Analytics 4.0.").font(.caption).foregroundStyle(.secondary)
            LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible())],spacing:10){
                metric("Cụm từ",count.map(String.init) ?? "…")
                metric("Chấp nhận sửa",String(feedback.accepted))
                metric("Hoàn tác sửa",String(feedback.rejected))
                metric("Ký tự tiết kiệm",String(feedback.savedKeys))
                metric("WPM xấp xỉ",String(format:"%.1f",stats.approximateWPM))
                metric("Phiên thống kê",String(stats.sessions))
            }
            if KeyboardSettings.privateTypingMode{Text("Đang gõ riêng tư · không hiển thị dữ liệu học.").font(.caption)}
            else {
                Text("Các cặp sửa đã xác nhận").font(.headline)
                ForEach(Array(feedback.pairs.prefix(30).enumerated()),id:\.offset){_,pair in
                    VStack(alignment:.leading,spacing:4){
                        Text(pair.source+" → "+pair.target).font(.subheadline.bold())
                        Text("\(pair.accepted) chọn · \(pair.rejected) hoàn tác").font(.caption).foregroundStyle(.secondary)
                    }.frame(maxWidth:.infinity,alignment:.leading)
                }
            }
            Button("Xóa dữ liệu sửa từ 6.0",role:.destructive){confirm=true}.buttonStyle(.bordered)
        }.task{
            let data=await Task.detached(priority:.utility){
                (TypingProFeedback.current,ProTypingStats.current,PersonalPhraseStore.load().entries.count)
            }.value
            guard !Task.isCancelled else{return}
            feedback=data.0;stats=data.1;count=data.2
        }.alert("Xóa dữ liệu học sửa từ?",isPresented:$confirm){
            Button("Xóa",role:.destructive){TypingProFeedback.clear();feedback=TypingProFeedback()}
            Button("Hủy",role:.cancel){}
        }message:{Text("Không xóa cụm từ, từ điển hoặc thống kê cũ.")}
    }
    private func metric(_ name:String,_ value:String)->some View{
        VStack(alignment:.leading,spacing:6){
            Text(name).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title2.bold().monospacedDigit()).foregroundStyle(.cyan)
        }.frame(maxWidth:.infinity,alignment:.leading).padding(12).background(.white.opacity(0.06),in:RoundedRectangle(cornerRadius:12))
    }
}
