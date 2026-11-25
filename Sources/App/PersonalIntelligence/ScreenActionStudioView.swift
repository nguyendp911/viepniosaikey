import SwiftUI
import PhotosUI
import UIKit

struct ScreenActionStudioView:View {
    @State private var photo:PhotosPickerItem?
    @State private var transcript=""
    @State private var result=""
    @State private var status=""
    @State private var busy=false
    @State private var generation=UUID()
    @State private var action="screen"
    @State private var work:Task<Void,Never>?
    var body:some View {
        VStack(alignment:.leading,spacing:12){
            Text("Screen to Action").font(.title.bold())
            Text("OCR xử lý trên máy. Kiểm tra văn bản trước khi lưu hoặc gửi AI. Không tự tạo lịch, gửi tin nhắn hoặc suy đoán người nói.").font(.caption).foregroundStyle(.secondary)
            PhotosPicker("Chọn ảnh",selection:$photo,matching:.images).buttonStyle(.borderedProminent)
                .onChange(of:photo){if let item=$0{read(item)}}
            TextEditor(text:$transcript).frame(minHeight:150)
            HStack{
                Button("Ẩn dữ liệu"){transcript=MessageSafety.redacted(transcript)}
                Button("Lưu bản nháp"){guard !KeyboardSettings.privateTypingMode,MessageSafety.warnings(in:transcript).isEmpty,!transcript.isEmpty else{status="Không lưu được.";return};ShareDraft.save(transcript);status="Đã chuyển vào bản nháp."}
            }.buttonStyle(.bordered)
            Picker("Tác vụ",selection:$action){
                Text("Đề xuất tác vụ").tag("screen")
                Text("Ghi chú").tag("notes")
                Text("Trích xuất").tag("extract")
                Text("Dịch tiếng Việt").tag("translate")
            }
            HStack{Button(busy ? "Đang xử lý…" : "Chạy AI trên văn bản"){run()}.buttonStyle(.borderedProminent).disabled(busy);if busy{Button("Hủy"){generation=UUID();work?.cancel();busy=false}}}
            if !status.isEmpty{Text(status).font(.caption).foregroundStyle(.orange)}
            if !result.isEmpty{TextEditor(text:$result).frame(minHeight:150);PersonalResultActions(text:result,status:$status)}
            if !transcript.isEmpty {
                Divider()
                Text("Tạo nhắc hẹn từ văn bản đã xác nhận").font(.headline)
                SmartReminderStudioView(source:transcript)
            }
        }.onDisappear{generation=UUID();work?.cancel()}
    }
    private func read(_ item:PhotosPickerItem){
        work?.cancel();let ticket=UUID();generation=ticket;busy=true;transcript="";result="";status=""
        work=Task{@MainActor in
            do{guard let data=try await item.loadTransferable(type:Data.self)else{throw AIServiceError.invalidResponse}
                let rows=try await ScreenshotStudioOCR.read(data)
                if generation==ticket,!Task.isCancelled{transcript=String(rows.map(\.text).joined(separator:"\n").prefix(3000));status="OCR: \(rows.count) dòng. Hãy kiểm tra lại."}
            }catch{if generation==ticket,!Task.isCancelled{status="Không đọc được ảnh."}}
            if generation==ticket{busy=false}
        }
    }
    private func run(){
        guard KeyboardSettings.allowCloudAI,!transcript.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty,MessageSafety.warnings(in:transcript).isEmpty else{status="Cần AI online và văn bản không nhạy cảm.";return}
        let input=transcript;let instruction=action=="translate" ? "Dịch văn bản sang tiếng Việt trung thành, giữ dữ kiện." : PersonalIntelligenceCatalog.task(action)?.instruction ?? ""
        let provider=KeyboardSettings.provider
        let ticket=UUID();generation=ticket;busy=true;result="";status=""
        work=Task{@MainActor in
            defer{if generation==ticket{busy=false}}
            do{let value=try await AIWritingService.studio(input,instruction:instruction,provider:provider);if generation==ticket,!Task.isCancelled{result=value}}
            catch{if generation==ticket,!Task.isCancelled{status=error.localizedDescription}}
        }
    }
}
