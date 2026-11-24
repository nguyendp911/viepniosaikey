import SwiftUI
import PhotosUI
import Vision
import Speech
import AVFoundation
import EventKit
import UIKit
import LocalAuthentication

extension AdvancedAssistantView {
    var writingSection: some View {
            section("AI soạn tin & bảo vệ thông tin", icon: "wand.and.stars") {
                TextEditor(text: $sourceText)
                    .frame(minHeight: 110)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
                    .accessibilityLabel("Nội dung do bạn cung cấp")
                if !MessageSafety.warnings(in: sourceText).isEmpty {
                    ForEach(MessageSafety.warnings(in: sourceText), id: \.self) { warning in
                        Label(warning, systemImage: "exclamationmark.shield")
                            .font(.caption).foregroundStyle(.orange)
                    }
                }
                Toggle("Ẩn dữ liệu nhạy cảm trước khi gửi AI", isOn: $privatePreview)
                    .font(.caption)
                    .tint(.indigo)
                Picker("Chức năng", selection: $mode) {
                    ForEach(tools, id: \.self) { Text($0) }
                }
                .pickerStyle(.menu)
                Text("Nội dung sẽ được gửi khi chọn Xử lý bằng AI, dùng nhà cung cấp và API Key bạn đã cấu hình.")
                    .font(.caption2).foregroundStyle(.secondary)
                HStack {
                    Button {
                        Task { await processText() }
                    } label: {
                        Label("Xử lý bằng AI", systemImage: "sparkles")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                    .disabled(busy || sourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Button("Đưa sang bàn phím") {
                        ShareDraft.save(responseText.isEmpty ? sourceText : responseText)
                        feedback = "Đã lưu bản nháp trong ViePN. Nhấn giữ nút AI trên bàn phím → Lấy bản nháp."
                    }
                    .buttonStyle(.bordered)
                }
                if mode == "Gợi ý trả lời" && !replyChoices.isEmpty {
                    Text("Smart Reply 2.0 · Chọn một phương án, kiểm tra rồi chỉnh sửa")
                        .font(.caption).bold()
                    ForEach(Array(replyChoices.enumerated()), id: \.offset) { index, answer in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(answer.tone)
                                .font(.caption2).foregroundStyle(.cyan)
                            Text(answer.text)
                                .font(.subheadline)
                            HStack {
                                Button("Sử dụng câu này") {
                                    responseText = answer.text
                                }
                                Button("Sao chép") {
                                    UIPasteboard.general.string = answer.text
                                    feedback = "Đã sao chép phương án " + String(index + 1)
                                }
                            }
                            .buttonStyle(.bordered).font(.caption)
                        }
                        .padding(9)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.white.opacity(0.065),
                                    in: RoundedRectangle(cornerRadius: 11))
                    }
                }
                if !responseText.isEmpty {
                    Text("Kết quả (có thể sửa)").font(.caption).foregroundStyle(.secondary)
                    TextEditor(text: $responseText)
                        .frame(minHeight: 88)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
                    Button {
                        UIPasteboard.general.string = responseText
                        feedback = "Đã sao chép kết quả."
                    } label: { Label("Sao chép kết quả", systemImage: "doc.on.doc") }
                        .buttonStyle(.bordered)
                }
            }
    }

    @MainActor
    func processText() async {
        busy = true
        defer { busy = false }
        let source = privatePreview ? MessageSafety.redacted(sourceText) : sourceText
        replyChoices = []
        do {
            switch mode {
            case "Gợi ý trả lời":
                let replies = try await AIService.reply(to: source)
                replyChoices = replies
                responseText = replies.first?.text ?? ""
            case "Kiểm tra giọng điệu":
                let items = ToneInspector.suggestions(for: sourceText)
                let rewritten = try await AIWritingService.transform(source, action: .polite)
                responseText = (items.isEmpty ? "Không phát hiện vấn đề rõ ràng." :
                                items.joined(separator: "\n")) + "\n\nĐề xuất:\n" + rewritten
            case "Dịch song ngữ":
                let translation = try await AIWritingService.transform(source, action: .translate)
                responseText = "Gốc:\n" + source + "\n\nBản dịch:\n" + translation
            case "Sửa chính tả":
                responseText = try await AIWritingService.transform(source, action: .proofread)
            case "Rút gọn":
                responseText = try await AIWritingService.transform(source, action: .shorter)
            default:
                responseText = try await AIWritingService.transform(source, action: .rewrite)
            }
            feedback = "Đã tạo kết quả. Xem lại trước khi dùng."
            if remindersTitle.isEmpty {
                remindersTitle = String(sourceText.prefix(70))
            }
        } catch {
            feedback = "Không xử lý được: " + error.localizedDescription
        }
    }
}
