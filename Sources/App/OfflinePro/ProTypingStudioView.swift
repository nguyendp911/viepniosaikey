import SwiftUI

struct ProTypingStudioView:View{
    @State private var config=OfflineKeyboardConfig.current
    @State private var stats=ProTypingStats.current
    @State private var language="VI"
    @State private var typed=""
    @State private var started:Date?
    @State private var finished:Date?
    @State private var result=""
    private var target:String{language=="VI" ? "Mỗi ngày là một cơ hội để học điều mới và hoàn thiện bản thân." : "Practice a little every day to build confidence and improve your typing."}
    var body:some View{
        VStack(alignment:.leading,spacing:14){
            Text("Typing Challenge").font(.title.bold())
            Picker("Ngôn ngữ",selection:$language){Text("Tiếng Việt").tag("VI");Text("English").tag("EN")}.pickerStyle(.segmented).onChange(of:language){_ in reset()}
            Text(target).font(.title3).padding(12).background(.white.opacity(0.07),in:RoundedRectangle(cornerRadius:12))
            Button("Bắt đầu / đặt lại"){reset();started=Date()}.buttonStyle(.borderedProminent)
            TextEditor(text:$typed).frame(minHeight:120).disabled(started==nil || finished != nil).autocorrectionDisabled()
            Button("Kết thúc"){
                guard let started else{return};let end=Date();finished=end
                let seconds=max(1,end.timeIntervalSince(started))
                let matches=zip(typed,target).filter{$0.0==$0.1}.count
                let accuracy=Double(matches)/Double(max(1,max(typed.count,target.count)))
                let wpm=Double(typed.count)/5/(seconds/60)
                result=String(format:"%.1f WPM · %.0f%% chính xác · %.1f giây",wpm,accuracy*100,seconds)
            }.buttonStyle(.bordered).disabled(started==nil || finished != nil)
            Text(result).font(.headline).foregroundStyle(.cyan)
            Divider()
            Text("Typing Analytics").font(.title2.bold())
            Toggle("Thống kê phiên bàn phím (chỉ số tổng hợp)",isOn:$config.analytics)
                .onChange(of:config){OfflineKeyboardConfig.current=$0}
            LabeledContent("Lượt chạm chữ",value:"\(stats.taps)")
            LabeledContent("Phiên gõ",value:"\(stats.sessions)")
            LabeledContent("WPM xấp xỉ",value:String(format:"%.1f",stats.approximateWPM))
            Text("WPM bàn phím là ước tính theo lượt chạm và thời gian mở, không phải tốc độ từ thực tế. Không lưu chuỗi phím; tắt trong riêng tư.").font(.caption).foregroundStyle(.secondary)
            Button("Làm mới"){stats=ProTypingStats.current}.buttonStyle(.bordered)
            Button("Xóa thống kê",role:.destructive){OfflineProStore.write(ProTypingStats(),"stats");stats=ProTypingStats.current}.buttonStyle(.bordered)
        }
    }
    private func reset(){typed="";started=nil;finished=nil;result=""}
}
