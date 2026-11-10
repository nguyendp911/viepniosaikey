import SwiftUI
import PhotosUI
import Vision
import Speech
import AVFoundation
import EventKit
import UIKit

/// Photo OCR and speech recognition must run in the containing app; third-party
/// keyboard extensions cannot inspect other apps' conversations or use microphone.
struct AdvancedAssistantView: View {
    @State private var chosenImage: PhotosPickerItem?
    @State private var sourceText = ""
    @State private var responseText = ""
    @State private var feedback = ""
    @State private var busy = false
    @State private var privatePreview = true
    @State private var mode = "Viết tự nhiên"
    @State private var memoryText = ""
    @State private var remindersTitle = ""
    @State private var reminderDate = Date().addingTimeInterval(3600)
    @State private var savedMemories = ConversationMemory.forActivePersona()
    @State private var diagnostics = KeyboardStability.report()
    @StateObject private var voice = VoiceTranscriber()

    private let tools = ["Viết tự nhiên", "Kiểm tra giọng điệu", "Dịch song ngữ",
                         "Gợi ý trả lời", "Sửa chính tả", "Rút gọn"]

    var body: some View {
        VStack(spacing: 12) {
            section("Ảnh chụp hội thoại", icon: "text.viewfinder") {
                Text("Chọn ảnh chụp màn hình Zalo, Messenger hoặc đoạn chat do bạn cung cấp. OCR thực hiện trên máy; không tự đọc app khác.")
                    .font(.caption).foregroundStyle(.secondary)
                PhotosPicker(selection: $chosenImage, matching: .images) {
                    Label("Chọn ảnh để nhận diện chữ", systemImage: "photo.on.rectangle.angled")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .onChange(of: chosenImage) { item in
                    guard let item else { return }
                    Task { await readScreenshot(item) }
                }
            }

            section("Giọng nói thành văn bản", icon: "waveform") {
                Text("Thu âm trong ứng dụng chính. Nội dung nhận dạng được đưa vào ô soạn để bạn kiểm tra trước khi gửi AI.")
                    .font(.caption).foregroundStyle(.secondary)
                HStack {
                    Button {
                        if voice.recording {
                            Task {
                                if let value = await voice.finish() {
                                    sourceText = value
                                    feedback = "Đã nhận diện giọng nói; hãy kiểm tra văn bản."
                                } else { feedback = voice.errorText }
                            }
                        } else {
                            Task { await voice.begin() }
                        }
                    } label: {
                        Label(voice.recording ? "Dừng & nhận dạng" : "Bắt đầu thu âm",
                              systemImage: voice.recording ? "stop.circle" : "mic.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(voice.recording ? .red : .indigo)
                    if !voice.errorText.isEmpty {
                        Text(voice.errorText).font(.caption2).foregroundStyle(.orange)
                    }
                }
            }

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

            section("Trí nhớ người nhận", icon: "brain.head.profile") {
                Text("Chỉ lưu ghi chú khi bạn bấm Lưu. Gắn với hồ sơ người nhận đang chọn; có thể xóa bất cứ lúc nào.")
                    .font(.caption).foregroundStyle(.secondary)
                Text(PersonaStore.active.map { "Đang chọn: " + $0.name }
                     ?? "Chưa chọn hồ sơ. Vào AI & API để chọn người nhận.")
                    .font(.caption)
                TextField("Ghi nhớ: Chú thích xưng cháu – chú", text: $memoryText)
                    .textFieldStyle(.roundedBorder)
                Button {
                    guard PersonaStore.active != nil else {
                        feedback = "Chọn hồ sơ người nhận trước khi lưu."
                        return
                    }
                    ConversationMemory.save(memoryText, for: PersonaStore.activeID)
                    memoryText = ""
                    savedMemories = ConversationMemory.forActivePersona()
                } label: { Label("Lưu ghi chú", systemImage: "square.and.arrow.down") }
                    .buttonStyle(.bordered)
                ForEach(savedMemories) { note in
                    HStack {
                        Text(note.text).font(.caption).frame(maxWidth: .infinity, alignment: .leading)
                        Button(role: .destructive) {
                            ConversationMemory.notes.removeAll { $0.id == note.id }
                            savedMemories = ConversationMemory.forActivePersona()
                        } label: { Image(systemName: "trash") }
                    }
                }
            }

            section("Lịch hẹn & lời nhắc", icon: "calendar.badge.plus") {
                Text("Đề xuất tác vụ từ văn bản đã nhận. Bạn xác nhận tiêu đề và giờ trước khi lưu vào Lịch iPhone.")
                    .font(.caption).foregroundStyle(.secondary)
                TextField("Tên sự kiện", text: $remindersTitle)
                    .textFieldStyle(.roundedBorder)
                DatePicker("Thời gian", selection: $reminderDate, in: Date()...)
                    .datePickerStyle(.compact)
                Button {
                    Task { await addCalendarEvent() }
                } label: { Label("Thêm vào Lịch", systemImage: "calendar.badge.plus") }
                    .buttonStyle(.bordered)
                    .disabled(remindersTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            section("Chẩn đoán bàn phím", icon: "waveform.path.ecg") {
                Text("Chỉ đếm thời gian thao tác; không lưu ký tự, nội dung hội thoại hay mật khẩu.")
                    .font(.caption).foregroundStyle(.secondary)
                Text(diagnostics).font(.system(size: 11, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack {
                    Button("Làm mới") { diagnostics = KeyboardStability.report() }
                    Button("Sao chép báo cáo") {
                        UIPasteboard.general.string = KeyboardStability.report()
                    }
                    Button("Xóa", role: .destructive) {
                        KeyboardStability.clear()
                        diagnostics = KeyboardStability.report()
                    }
                }
                .font(.caption)
                .buttonStyle(.bordered)
            }
            if !feedback.isEmpty {
                Text(feedback)
                    .font(.caption)
                    .foregroundStyle(.cyan)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .foregroundStyle(.white)
    }

    private func section<Content: View>(_ heading: String, icon: String,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(heading, systemImage: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.cyan)
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
    }

    @MainActor
    private func readScreenshot(_ item: PhotosPickerItem) async {
        busy = true
        defer { busy = false }
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data)?.cgImage else {
                feedback = "Không đọc được ảnh. Hãy chọn ảnh chụp màn hình khác."
                return
            }
            let recognized = try await Task.detached(priority: .userInitiated) {
                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate
                request.recognitionLanguages = ["vi-VN", "en-US"]
                request.usesLanguageCorrection = true
                try VNImageRequestHandler(cgImage: image).perform([request])
                return (request.results ?? [])
                    .sorted { a, b in
                        if abs(a.boundingBox.midY - b.boundingBox.midY) > 0.04 {
                            return a.boundingBox.midY > b.boundingBox.midY
                        }
                        return a.boundingBox.minX < b.boundingBox.minX
                    }
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")
            }.value
            sourceText = String(recognized.prefix(3000))
            feedback = recognized.isEmpty ? "Ảnh không có chữ nhận diện được."
                                          : "Đã nhận dạng chữ trên máy. Hãy kiểm tra thứ tự người gửi trước khi xử lý."
        } catch {
            feedback = "Lỗi đọc ảnh: " + error.localizedDescription
        }
    }

    @MainActor
    private func processText() async {
        busy = true
        defer { busy = false }
        let source = privatePreview ? MessageSafety.redacted(sourceText) : sourceText
        do {
            switch mode {
            case "Gợi ý trả lời":
                let replies = try await AIService.reply(to: source)
                responseText = replies.map { $0.text }.joined(separator: "\n\n")
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

    @MainActor
    private func addCalendarEvent() async {
        let store = EKEventStore()
        let granted: Bool
        if #available(iOS 17.0, *) {
            granted = (try? await store.requestWriteOnlyAccessToEvents()) ?? false
        } else {
            granted = (try? await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
                store.requestAccess(to: .event) { allowed, error in
                    if let error { continuation.resume(throwing: error) }
                    else { continuation.resume(returning: allowed) }
                }
            }) ?? false
        }
        guard granted else { feedback = "Chưa có quyền ghi vào Lịch iPhone."; return }
        let event = EKEvent(eventStore: store)
        event.title = String(remindersTitle.prefix(130))
        event.startDate = reminderDate
        event.endDate = reminderDate.addingTimeInterval(3600)
        event.calendar = store.defaultCalendarForNewEvents
        guard event.calendar != nil else {
            feedback = "Không có lịch mặc định để lưu sự kiện."; return
        }
        do {
            try store.save(event, span: .thisEvent)
            feedback = "Đã lưu sự kiện trong Lịch iPhone."
        } catch {
            feedback = "Không lưu được sự kiện: " + error.localizedDescription
        }
    }
}

/// Recording is explicit, and transient audio is deleted when transcription ends.
@MainActor
final class VoiceTranscriber: ObservableObject {
    @Published var recording = false
    @Published var errorText = ""
    private var recorder: AVAudioRecorder?
    private let file = FileManager.default.temporaryDirectory
        .appendingPathComponent("viepnaikey-voice.m4a")

    func begin() async {
        errorText = ""
        let auth = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            AVAudioSession.sharedInstance().requestRecordPermission {
                continuation.resume(returning: $0)
            }
        }
        guard auth else { errorText = "Chưa cấp quyền microphone."; return }
        guard SFSpeechRecognizer.authorizationStatus() != .denied else {
            errorText = "Chưa cấp quyền nhận dạng giọng nói."; return
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .default, options: [])
            try session.setActive(true)
            recorder = try AVAudioRecorder(url: file, settings: [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 16000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
            ])
            recording = recorder?.record() ?? false
            if !recording { errorText = "Không thể bắt đầu thu âm." }
        } catch {
            errorText = error.localizedDescription
        }
    }

    func finish() async -> String? {
        recorder?.stop()
        recorder = nil
        recording = false
        defer {
            try? FileManager.default.removeItem(at: file)
            try? AVAudioSession.sharedInstance().setActive(false)
        }
        let allowed = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
        guard allowed else { errorText = "Bạn chưa cấp quyền nhận dạng giọng nói."; return nil }
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "vi-VN")),
              recognizer.isAvailable else {
            errorText = "Nhận dạng giọng nói không khả dụng."; return nil
        }
        let request = SFSpeechURLRecognitionRequest(url: file)
        request.shouldReportPartialResults = false
        return await withCheckedContinuation { (continuation: CheckedContinuation<String?, Never>) in
            var completed = false
            _ = recognizer.recognitionTask(with: request) { [weak self] result, error in
                if completed { return }
                if error != nil || result?.isFinal == true {
                    completed = true
                    let transcription = result?.bestTranscription.formattedString
                    if let error {
                        Task { @MainActor in self?.errorText = error.localizedDescription }
                    }
                    continuation.resume(returning: transcription)
                }
            }
        }
    }
}
