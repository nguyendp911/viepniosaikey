import SwiftUI
import UIKit

struct IntelligenceWritingView: View {
    let group: String
    @State private var source = ""
    @State private var result = ""
    @State private var selected = ""
    @State private var language = "English"
    @State private var bilingual = false
    @State private var formal = false
    @State private var provider = KeyboardSettings.provider
    @State private var style = false
    @State private var busy = false
    @State private var status = ""
    @State private var task: Task<Void, Never>?
    var options: [IntelligenceTask] { IntelligenceTask.tasks.filter { $0.group == group } }
    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            Text("Nhập hoặc dán nội dung bạn muốn xử lý. Chỉ gửi AI khi bấm tạo; kết quả cần được kiểm tra trước khi sử dụng.")
                .font(.caption).foregroundStyle(.secondary)
            if group == "Dịch" {
                Picker("Dịch sang", selection: $language) { ForEach(IntelligenceTask.languages, id: \.self) { Text($0) } }
                Toggle("Song ngữ", isOn: $bilingual)
                Toggle("Trang trọng", isOn: $formal)
            } else {
                Picker("Tác vụ", selection: $selected) { ForEach(options) { Text($0.title).tag($0.id) } }
                    .onAppear { if selected.isEmpty { selected = options.first?.id ?? "" } }
            }
            Picker("Nhà cung cấp", selection: $provider) { Text("Gemini").tag("gemini"); Text("OpenAI").tag("openai") }
                .pickerStyle(.segmented)
            Toggle("Dùng văn phong đã lưu", isOn: $style)
            TextEditor(text: $source).frame(minHeight: 150).padding(6)
                .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
            HStack {
                Button("Dùng bản nháp") { source = ShareDraft.current }
                Button("Ẩn dữ liệu") { source = MessageSafety.redacted(source) }
            }.buttonStyle(.bordered)
            if !MessageSafety.warnings(in: source).isEmpty {
                Text(MessageSafety.warnings(in: source).joined(separator: " · ")).foregroundStyle(.orange).font(.caption)
            }
            HStack {
                Button(busy ? "Đang xử lý…" : "Tạo kết quả AI") { run() }
                    .buttonStyle(.borderedProminent).disabled(busy || source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                if busy { Button("Hủy") { task?.cancel(); task = nil; busy = false }.buttonStyle(.bordered) }
            }
            if group == "Hội thoại" {
                Button("Phân tích offline") { result = ConversationLens.summary(ConversationLens.findings(in: source)) + "\n" + ToneInspector.suggestions(for: source).joined(separator: "\n") }
                    .buttonStyle(.bordered)
            }
            if !status.isEmpty { Text(status).font(.caption).foregroundStyle(.orange) }
            if !result.isEmpty {
                Text("Kết quả").font(.headline)
                TextEditor(text: $result).frame(minHeight: 140)
                HStack {
                    Button("Sao chép") { UIPasteboard.general.string = result }
                    Button("Đưa sang bàn phím") { ShareDraft.save(result); status = "Đã lưu bản nháp để lấy trong bàn phím." }
                }.buttonStyle(.bordered)
            }
        }.onDisappear { task?.cancel() }
    }
    func run() {
        guard KeyboardSettings.allowCloudAI else { status = "Hãy bật AI online trong AI & API và tắt chế độ riêng tư."; return }
        let instruction = group == "Dịch" ? IntelligenceTask.translation(to: language, bilingual: bilingual, formal: formal) : options.first { $0.id == selected }?.instruction ?? ""
        let input = source
        let activeProvider = provider
        let includeStyle = style
        busy = true; status = ""; result = ""
        task = Task { @MainActor in
            defer { if !Task.isCancelled { busy = false } }
            do {
                let text = try await AIWritingService.studio(input, instruction: instruction, provider: activeProvider, includeStyle: includeStyle)
                guard !Task.isCancelled else { return }
                result = text
            } catch { if !Task.isCancelled { status = error.localizedDescription } }
        }
    }
}
