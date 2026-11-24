import SwiftUI
import PhotosUI
import Vision
import UIKit

struct ScreenshotStudioView: View {
    @State private var item: PhotosPickerItem?
    @State private var lines: [OCRChatLine] = []
    @State private var transcript = ""
    @State private var status = ""
    @State private var busy = false
    @State private var ticket = UUID()
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("OCR trên thiết bị. Bạn tự xác nhận vai trò từng dòng; vị trí chỉ là gợi ý, không xác định danh tính.").font(.caption).foregroundStyle(.secondary)
            PhotosPicker("Chọn ảnh hội thoại", selection: $item, matching: .images)
                .buttonStyle(.borderedProminent)
                .onChange(of: item) { value in if let value { read(value) } }
            if busy { ProgressView() }
            Text(status).font(.caption)
            ForEach($lines) { $line in
                VStack(alignment: .leading, spacing: 4) {
                    Text(line.text).font(.subheadline)
                    Text("Vị trí OCR: " + line.alignment + " · không xác định người nói").font(.caption2).foregroundStyle(.secondary)
                    Picker("Người nói", selection: $line.speaker) {
                        Text("Bỏ qua").tag("skip"); Text("Tôi").tag("me"); Text("Bạn ấy").tag("other"); Text("Chưa rõ").tag("unknown")
                    }.pickerStyle(.segmented)
                }.padding(8).background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
            }
            if !lines.isEmpty {
                Button("Tạo bản hội thoại để kiểm tra") {
                    transcript = lines.filter { $0.speaker != "skip" }.map { line in
                        (line.speaker == "me" ? "Tôi: " : line.speaker == "other" ? "Bạn ấy: " : "Chưa rõ: ") + line.text
                    }.joined(separator: "\n")
                }.buttonStyle(.bordered)
            }
            if !transcript.isEmpty {
                TextEditor(text: $transcript).frame(minHeight: 150)
                Button("Ẩn dữ liệu nhạy cảm") { transcript = MessageSafety.redacted(transcript) }
                Button("Chuyển bản đã kiểm tra sang bàn phím") {
                    guard MessageSafety.warnings(in: transcript).isEmpty else { status = "Cần ẩn dữ liệu nhạy cảm."; return }
                    PersonaStore.clearSelection(); ShareDraft.save(transcript); status = "Đã lưu bản nháp. Mở Công cụ → Bản nháp."
                }.buttonStyle(.borderedProminent)
            }
        }
    }
    func read(_ picker: PhotosPickerItem) {
        let current = UUID(); ticket = current; busy = true; transcript = ""; lines = []
        Task { @MainActor in
            do {
                guard let data = try await picker.loadTransferable(type: Data.self) else { throw AIServiceError.invalidResponse }
                let found = try await ScreenshotStudioOCR.read(data)
                guard ticket == current else { return }
                lines = found; status = "Nhận diện \(found.count) dòng. Hãy kiểm tra vai trò."
            } catch { if ticket == current { status = error.localizedDescription } }
            if ticket == current { busy = false }
        }
    }
}
