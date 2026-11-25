import SwiftUI
import UIKit

struct PersonalResultActions:View {
    let text:String
    @Binding var status:String
    var body:some View {
        HStack {
            Button("Sao chép"){UIPasteboard.general.string=text}
            Button("Đưa sang bàn phím"){
                guard !KeyboardSettings.privateTypingMode, MessageSafety.warnings(in:text).isEmpty else {status="Không lưu nội dung riêng tư/nhạy cảm.";return}
                ShareDraft.save(text);status="Đã lưu bản nháp."
            }
        }.buttonStyle(.bordered)
    }
}
struct PersonalAITaskView:View {
    let task:PersonalAITask
    @State var source=""
    @State private var result=""
    @State private var status=""
    @State private var busy=false
    @State private var work:Task<Void,Never>?
    var body:some View {
        VStack(alignment:.leading,spacing:12) {
            Label(task.title,systemImage:task.symbol).font(.title.bold())
            Text(task.instruction).font(.caption).foregroundStyle(.secondary)
            TextEditor(text:$source).frame(minHeight:145).scrollContentBackground(.hidden).padding(8).background(.white.opacity(0.06),in:RoundedRectangle(cornerRadius:12))
            HStack {Button("Bản nháp"){source=ShareDraft.current};Button("Ẩn dữ liệu"){source=MessageSafety.redacted(source)}}.buttonStyle(.bordered)
            HStack {
                Button(busy ? "Đang xử lý…" : "Chạy AI"){run()}.buttonStyle(.borderedProminent).disabled(busy)
                if busy {Button("Hủy"){work?.cancel();busy=false}}
            }
            if !status.isEmpty {Text(status).font(.caption).foregroundStyle(.orange)}
            if !result.isEmpty {
                Text("Xem trước").font(.headline)
                TextEditor(text:$result).frame(minHeight:160)
                PersonalResultActions(text:result,status:$status)
            }
        }.onDisappear{work?.cancel()}
    }
    private func run(){
        guard KeyboardSettings.allowCloudAI,!source.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty,MessageSafety.warnings(in:source).isEmpty else {status="Cần AI online và nội dung không nhạy cảm.";return}
        let input=source;let provider=KeyboardSettings.provider
        busy=true;status="";result=""
        work=Task{@MainActor in
            defer{if !Task.isCancelled{busy=false}}
            do{let value=try await AIWritingService.studio(input,instruction:task.instruction,provider:provider);if !Task.isCancelled{result=value}}
            catch{if !Task.isCancelled{status=error.localizedDescription}}
        }
    }
}
