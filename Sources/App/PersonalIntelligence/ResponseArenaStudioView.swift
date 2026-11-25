import SwiftUI

struct ResponseArenaStudioView:View {
    @State private var source=""
    @State private var original=""
    @State private var candidates:[ArenaResult]=[]
    @State private var result=""
    @State private var status=""
    @State private var busy=false
    @State private var work:Task<Void,Never>?
    var body:some View {
        VStack(alignment:.leading,spacing:12){
            Text("Response Arena").font(.title.bold())
            Text("Cùng một văn bản sẽ gửi đến cả Gemini và OpenAI khi bấm So sánh. Cần hai API key; mỗi lần dùng hai yêu cầu, kết hợp dùng thêm một yêu cầu.").font(.caption).foregroundStyle(.secondary)
            TextEditor(text:$source).frame(minHeight:140)
            HStack{Button("Bản nháp"){source=ShareDraft.current};Button("Ẩn dữ liệu"){source=MessageSafety.redacted(source)}}.buttonStyle(.bordered)
            HStack{Button(busy ? "Đang xử lý…" : "So sánh hai AI"){run()}.buttonStyle(.borderedProminent).disabled(busy);if busy{Button("Hủy"){work?.cancel();busy=false}}}
            if !candidates.isEmpty{
                LazyVGrid(columns:[GridItem(.adaptive(minimum:140),spacing:8)],spacing:8){
                    ForEach(candidates){candidate in
                        VStack(alignment:.leading,spacing:8){
                            Text(candidate.id=="gemini" ? "Gemini" : "OpenAI").font(.headline).foregroundStyle(.cyan)
                            Text(candidate.text ?? candidate.error ?? "Không có kết quả").font(.subheadline).frame(maxWidth:.infinity,alignment:.leading).textSelection(.enabled)
                            if let text=candidate.text{Button("Chọn"){result=text}.buttonStyle(.bordered)}
                        }.padding(10).background(.white.opacity(0.06),in:RoundedRectangle(cornerRadius:12))
                    }
                }
                if candidates.compactMap(\.text).count==2{Button("Kết hợp hai phương án"){combine()}.buttonStyle(.bordered).disabled(busy)}
            }
            if !status.isEmpty{Text(status).font(.caption).foregroundStyle(.orange)}
            if !result.isEmpty{TextEditor(text:$result).frame(minHeight:140);PersonalResultActions(text:result,status:$status)}
        }.onDisappear{work?.cancel()}
    }
    private func run(){
        guard KeyboardSettings.allowCloudAI,!source.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty,MessageSafety.warnings(in:source).isEmpty else{status="Cần AI online và nội dung không nhạy cảm.";return}
        original=source;let input=source
        busy=true;candidates=[];result="";status=""
        work=Task{@MainActor in
            let values=await PersonalAIService.arena(input)
            if !Task.isCancelled{candidates=values;busy=false}
        }
    }
    private func combine(){
        guard KeyboardSettings.allowCloudAI else{status="AI online đang tắt.";return}
        let values=candidates;let input=original;let provider=KeyboardSettings.provider
        busy=true;status=""
        work=Task{@MainActor in
            defer{if !Task.isCancelled{busy=false}}
            do{let value=try await PersonalAIService.combine(values,original:input,provider:provider);if !Task.isCancelled{result=value}}
            catch{if !Task.isCancelled{status=error.localizedDescription}}
        }
    }
}
