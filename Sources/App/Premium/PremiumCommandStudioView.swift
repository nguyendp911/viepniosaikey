import SwiftUI
import UIKit

struct PremiumCommandStudioView: View {
    @State private var source = ""
    @State private var query = ""
    @State private var selected = "hamy"
    @State private var result = ""
    @State private var status = ""
    @State private var busy = false
    @State private var task: Task<Void,Never>?
    var body: some View {
        VStack(alignment:.leading,spacing:14) {
            Text("ViePN Command").font(.largeTitle.bold())
            Text("AI phân tích nội dung bạn cung cấp; mô phỏng không phải dự đoán thực tế. Công cụ offline không gửi nội dung ra mạng.").font(.caption).foregroundStyle(.secondary)
            TextField("Tìm lệnh · /lanhlung, /tinh",text:$query).textFieldStyle(.roundedBorder)
            LazyVGrid(columns:[GridItem(.adaptive(minimum:140))],spacing:8) {
                ForEach(PremiumCommands.search(query)) { command in
                    Button { selected = command.id } label: {
                        VStack(alignment:.leading,spacing:5) {
                            Image(systemName:command.symbol).foregroundStyle(.cyan)
                            Text(command.title).font(.subheadline.bold()).lineLimit(2)
                            Text("/"+command.id+" · "+command.category).font(.caption2).foregroundStyle(.secondary)
                        }.frame(maxWidth:.infinity,alignment:.leading).padding(10)
                            .background(selected == command.id ? Color.indigo.opacity(0.4) : Color.white.opacity(0.07),in:RoundedRectangle(cornerRadius:12))
                    }.buttonStyle(.plain)
                }
            }
            Text("Nội dung · "+(PremiumCommands.find(selected)?.title ?? "")).font(.headline)
            TextEditor(text:$source).frame(minHeight:120).scrollContentBackground(.hidden).padding(6).background(.white.opacity(0.06),in:RoundedRectangle(cornerRadius:12))
            HStack {
                Button("Bản nháp") { source = ShareDraft.current }
                Button("Ẩn dữ liệu") { source = MessageSafety.redacted(source) }
            }.buttonStyle(.bordered)
            HStack {
                Button(busy ? "Đang xử lý…" : "Chạy lệnh") { run() }.buttonStyle(.borderedProminent).disabled(busy)
                if busy { Button("Hủy") { task?.cancel(); busy = false }.buttonStyle(.bordered) }
            }
            if !status.isEmpty { Text(status).font(.caption).foregroundStyle(.orange) }
            if !result.isEmpty {
                Text("Xem trước").font(.headline)
                TextEditor(text:$result).frame(minHeight:130)
                HStack {
                    Button("Sao chép") { UIPasteboard.general.string = result }
                    Button("Chuyển sang bàn phím") {
                        guard !KeyboardSettings.privateTypingMode, MessageSafety.warnings(in:result).isEmpty else { status = "Không lưu trong chế độ riêng tư hoặc khi có dữ liệu nhạy cảm."; return }
                        ShareDraft.save(result); status = "Đã lưu bản nháp."
                    }
                }.buttonStyle(.bordered)
            }
        }.onDisappear { task?.cancel() }
    }
    private func run() {
        guard let command = PremiumCommands.find(selected) else { return }
        status = ""; result = ""
        if !command.isAI {
            switch command.id {
            case "tinh":
                do { result = try PremiumCalculator.evaluate(source) } catch { status = "Biểu thức không hợp lệ. Dùng + − × ÷ và ngoặc." }
            case "canhbao": result = PremiumOffline.guardian(source)
            case "ngay","gio": result = PremiumOffline.variables("{{"+command.id+"}}",name:"",custom:[:])
            default: result = PremiumOffline.format(source,mode:command.id)
            }
            return
        }
        guard KeyboardSettings.allowCloudAI, !source.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty, MessageSafety.warnings(in:source).isEmpty else { status = "Cần bật AI online và nhập nội dung không nhạy cảm."; return }
        let input = source; let provider = KeyboardSettings.provider
        busy = true
        task = Task { @MainActor in
            defer { if !Task.isCancelled { busy = false } }
            do {
                let value = try await PremiumWorkflowService.run(input,steps:[command.id],provider:provider)
                if !Task.isCancelled { result = value }
            } catch { if !Task.isCancelled { status = error.localizedDescription } }
        }
    }
}
