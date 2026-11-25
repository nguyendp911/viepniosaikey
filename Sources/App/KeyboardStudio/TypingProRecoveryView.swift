import SwiftUI

struct TypingProRecoveryView:View{
    @State private var source=""
    @State private var results:[String]=[]
    @State private var status=""
    @State private var busy=false
    @State private var work:Task<Void,Never>?
    var body:some View{
        VStack(alignment:.leading,spacing:12){
            Text("Vietnamese Accent Recovery").font(.title2.bold())
            Text("Gợi ý từ từ điển, mẫu câu và tần suất cá nhân nếu bật tự học. Không khẳng định duy nhất đúng; xem lại trước khi sử dụng. Tối đa 16 tiếng.").font(.caption).foregroundStyle(.secondary)
            TextEditor(text:$source).frame(minHeight:130)
            Button(busy ? "Đang xử lý…" : "Khôi phục dấu"){
                let input=source;busy=true
                work=Task{@MainActor in
                    let values=await Task.detached(priority:.userInitiated){
                        let learned=KeyboardSettings.privateTypingMode || !KeyboardSettings.autoLearnWords ? [:] : KeyboardSettings.learnedWords
                        return TypingProText.recover(input,vocabulary:SmartTyping.coreVietnameseWords+SmartTyping.vietnameseWords,learned:learned)
                    }.value
                    guard !Task.isCancelled else{return}
                    results=values;busy=false;status=values.isEmpty ? "Không tìm được phương án phù hợp." : ""
                }
            }.buttonStyle(.borderedProminent).disabled(busy)
            ForEach(results,id:\.self){value in
                VStack(alignment:.leading,spacing:8){Text(value).font(.headline);PersonalResultActions(text:value,status:$status)}
                    .padding(12).background(.white.opacity(0.06),in:RoundedRectangle(cornerRadius:12))
            }
            Text(status).font(.caption).foregroundStyle(.secondary)
        }.onDisappear{work?.cancel()}
    }
}
