import SwiftUI
import PhotosUI
import Vision
import Speech
import AVFoundation
import EventKit
import UIKit
import LocalAuthentication

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
    @State private var transcriptDraft = ""
    @State private var savedChatTurns = ConversationHistory.turns(for: PersonaStore.activeID)
    @State private var chatPreview = ""
    @State private var generatedChatSuggestions: [ReplySuggestion] = []
    @State private var evidenceExplanation = ""
    @State private var showExplanation = false
    @State private var openingNote = ""
    @State private var historyLockEnabled = KeyboardSettings.historyScreenLockEnabled
    @State private var conversationStyleEnabled =
        KeyboardSettings.learnConversationStyleEnabled
    @State private var historyUnlocked = false
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

            section("Bảo vệ dữ liệu hội thoại", icon: "lock.shield") {
                Toggle("Yêu cầu Face ID hoặc mật mã khi xem lịch sử",
                       isOn: $historyLockEnabled)
                    .font(.caption)
                    .tint(.cyan)
                    .onChange(of: historyLockEnabled) { enabled in
                        KeyboardSettings.historyScreenLockEnabled = enabled
                        historyUnlocked = !enabled
                    }
                Text("Lịch sử trên iOS dùng tệp Data Protection trong App Group. Khóa màn hình này chỉ chặn giao diện trong ứng dụng; không phải mã hóa đầu-cuối hay khóa toàn bộ bàn phím.")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            if !historyLockEnabled || historyUnlocked {
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

            section("Hội thoại riêng cho từng người", icon: "bubble.left.and.bubble.right") {
                Text(PersonaStore.active.map { "Hồ sơ đang chọn: " + $0.name }
                     ?? "Hãy chọn hồ sơ người nhận ở mục AI & API trước khi nhập hội thoại.")
                    .font(.caption).foregroundStyle(.secondary)
                Text("Dán lịch sử đã được bạn chủ động sao chép. Mỗi dòng ghi rõ người nói, ví dụ: Tôi: Hôm nay em thế nào? / Bạn ấy: Em đang đi làm. Không tự đọc Zalo hay Messenger.")
                    .font(.caption).foregroundStyle(.secondary)
                TextEditor(text: $transcriptDraft)
                    .frame(minHeight: 100)
                    .scrollContentBackground(.hidden)
                    .padding(7)
                    .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
                    .accessibilityLabel("Lịch sử hội thoại được nhập thủ công")
                let parsedCount = ConversationHistory.parse(transcriptDraft).count
                Text("Nhận diện " + String(parsedCount) + " lượt nói có nhãn Tôi / Bạn ấy. Kiểm tra lại trước khi lưu.")
                    .font(.caption2).foregroundStyle(.secondary)
                if !MessageSafety.warnings(in: transcriptDraft).isEmpty {
                    Text("Đoạn nhập có thể chứa thông tin nhạy cảm. Hãy xóa hoặc ẩn trước khi lưu.")
                        .font(.caption2).foregroundStyle(.orange)
                }
                HStack {
                    Button {
                        guard let person = PersonaStore.active else {
                            feedback = "Hãy chọn hồ sơ trước khi lưu."
                            return
                        }
                        let count = ConversationHistory.importExplicitly(
                            transcriptDraft, for: person.id)
                        savedChatTurns = ConversationHistory.turns(for: person.id)
                        transcriptDraft = ""
                        feedback = "Đã lưu " + String(count) + " lượt mới cho " + person.name + "."
                    } label: {
                        Label("Lưu lịch sử", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(PersonaStore.active == nil || parsedCount == 0
                              || !MessageSafety.warnings(in: transcriptDraft).isEmpty)
                    Spacer()
                    Text(String(savedChatTurns.count) + " lượt đã lưu")
                        .font(.caption2).foregroundStyle(.secondary)
                }
                if !savedChatTurns.isEmpty {
                    ForEach(Array(savedChatTurns.suffix(6))) { turn in
                        HStack(alignment: .top, spacing: 8) {
                            Text(turn.speaker == .me ? "Tôi" : "Bạn ấy")
                                .font(.caption2).bold()
                                .foregroundStyle(turn.speaker == .me ? .cyan : .mint)
                                .frame(width: 51, alignment: .leading)
                            Text(turn.text).font(.caption2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    Button(role: .destructive) {
                        guard let person = PersonaStore.active else { return }
                        ConversationHistory.clear(for: person.id)
                        savedChatTurns = []
                        feedback = "Đã xóa lịch sử hội thoại của " + person.name + "."
                    } label: {
                        Label("Xóa toàn bộ lịch sử người này", systemImage: "trash")
                    }
                    .font(.caption)
                }
                if let person = PersonaStore.active {
                    let personTopics = ConversationIntelligence.topics(for: person.id)
                    HStack(spacing: 10) {
                        Label(String(savedChatTurns.filter { $0.speaker == .me }.count)
                              + " đã gửi", systemImage: "arrow.up.message")
                        Label(String(savedChatTurns.filter { $0.speaker == .other }.count)
                              + " đã nhận", systemImage: "arrow.down.message")
                    }
                    .font(.caption2).foregroundStyle(.secondary)
                    if !personTopics.isEmpty {
                        Text("Chủ đề trao đổi được nhận diện offline:")
                            .font(.caption2).foregroundStyle(.secondary)
                        HStack(spacing: 6) {
                            ForEach(personTopics, id: \.name) { topic in
                                Text(topic.name + " · " + String(topic.count))
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 5)
                                    .background(.white.opacity(0.08),
                                                in: Capsule())
                            }
                        }
                    }
                    if let recent = ConversationIntelligence.evidence(
                        for: person.id, query: openingNote, openingToday: true, limit: 2).last {
                        Button {
                            remindersTitle = "Hỏi thăm " + person.name + ": "
                                + String(recent.quote.prefix(60))
                            feedback = "Đã điền nội dung lời nhắc. Chọn ngày giờ rồi bấm Thêm vào Lịch."
                        } label: {
                            Label("Tạo nhắc hỏi thăm từ hội thoại",
                                  systemImage: "calendar.badge.plus")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                Toggle("Học cách xưng hô, giọng văn từ tin nhắn Tôi đã tự lưu",
                       isOn: $conversationStyleEnabled)
                    .font(.caption)
                    .tint(.cyan)
                    .onChange(of: conversationStyleEnabled) {
                        KeyboardSettings.learnConversationStyleEnabled = $0
                    }
                Text("Khi bật, các tin do bạn tự đánh dấu Tôi có thể được dùng làm ví dụ về văn phong trong những yêu cầu AI do bạn chủ động gửi. Không học từ tin nhắn của người kia.")
                    .font(.caption2).foregroundStyle(.secondary)
                TextField("Ghi chú tùy chọn: Hôm nay muốn hỏi chuyện gì?", text: $openingNote)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Button {
                        Task { await proposeFromHistory(openingToday: false) }
                    } label: {
                        Label("Gợi ý trả lời", systemImage: "arrowshape.turn.up.left")
                    }
                    .buttonStyle(.bordered)
                    Button {
                        Task { await proposeFromHistory(openingToday: true) }
                    } label: {
                        Label("Nhắn gì hôm nay?", systemImage: "sun.max")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(PersonaStore.active == nil || busy)
                }
                Text("Khi bạn nhấn AI online, ViePN chọn tối đa 6 đoạn hội thoại có liên quan; nếu bật học văn phong, có thể kèm tối đa 5 câu do bạn ghi nhãn Tôi và các ghi chú tự lưu. Không tự gửi tin nhắn.")
                    .font(.caption2).foregroundStyle(.secondary)
                if !generatedChatSuggestions.isEmpty {
                    Text("Ba phương án — chọn đúng một câu để chỉnh sửa hoặc dùng")
                        .font(.caption2).foregroundStyle(.secondary)
                    ForEach(Array(generatedChatSuggestions.enumerated()), id: \.offset) {
                        index, suggestion in
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Mẫu " + String(index + 1) + " · " + suggestion.tone)
                                .font(.caption2).foregroundStyle(.cyan)
                            Text(suggestion.text)
                                .font(.subheadline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            HStack {
                                Button("Chọn câu này") {
                                    chatPreview = suggestion.text
                                }
                                Button {
                                    let clean = String(suggestion.text.prefix(350))
                                        .trimmingCharacters(in: .whitespacesAndNewlines)
                                    var samples = KeyboardSettings.writingSamples
                                    guard samples.count < 8, !clean.isEmpty,
                                          MessageSafety.warnings(in: clean).isEmpty
                                    else {
                                        feedback = "Không thể học thêm: đủ 8 mẫu hoặc câu có dữ liệu nhạy cảm."
                                        return
                                    }
                                    if !samples.contains(clean) {
                                        samples.append(clean)
                                        KeyboardSettings.writingSamples = samples
                                    }
                                    feedback = "Đã lưu giọng văn này làm ví dụ do bạn chọn."
                                } label: {
                                    Label("Học giọng văn", systemImage: "brain")
                                }
                                Button {
                                    UIPasteboard.general.string = suggestion.text
                                    feedback = "Đã sao chép riêng mẫu "
                                        + String(index + 1) + "."
                                } label: {
                                    Label("Sao chép", systemImage: "doc.on.doc")
                                }
                            }
                            .font(.caption).buttonStyle(.bordered)
                        }
                        .padding(10)
                        .background(.white.opacity(0.07),
                                    in: RoundedRectangle(cornerRadius: 12))
                    }
                    Button {
                        showExplanation.toggle()
                    } label: {
                        Label("Vì sao AI đưa ra những gợi ý này?",
                              systemImage: "text.book.closed")
                    }
                    .buttonStyle(.bordered)
                    if showExplanation {
                        Text("Đoạn hội thoại đã lưu được chọn làm căn cứ (không khẳng định đây là lý do duy nhất mô hình chọn từng từ):")
                            .font(.caption2).foregroundStyle(.secondary)
                        Text(evidenceExplanation)
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(9)
                            .background(.white.opacity(0.07),
                                        in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                if !chatPreview.isEmpty {
                    Text("Bản nháp đã chọn — có thể sửa trước khi chèn")
                        .font(.caption2).foregroundStyle(.secondary)
                    TextEditor(text: $chatPreview)
                        .frame(height: 105)
                        .scrollContentBackground(.hidden)
                        .padding(7)
                        .background(.white.opacity(0.07),
                                    in: RoundedRectangle(cornerRadius: 12))
                    Button {
                        ShareDraft.save(chatPreview)
                        feedback = "Đã lưu câu đã chọn để đưa sang bàn phím."
                    } label: {
                        Label("Đưa câu đã chọn sang bàn phím", systemImage: "keyboard")
                    }
                    .buttonStyle(.bordered)
                }
            }

            } else {
                section("Hội thoại đã khóa", icon: "lock.fill") {
                    Text("Mở khóa bằng Face ID hoặc mật mã thiết bị để xem ghi chú và lịch sử.")
                        .font(.caption).foregroundStyle(.secondary)
                    Button {
                        unlockChatHistory()
                    } label: {
                        Label("Mở khóa lịch sử", systemImage: "faceid")
                    }
                    .buttonStyle(.borderedProminent)
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

            section("ViePN đã học được gì?", icon: "chart.bar.xaxis") {
                Text("Thống kê chỉ từ các lựa chọn bạn đã chủ động sử dụng. Không ghi lại toàn bộ những gì gõ trong ứng dụng khác.")
                    .font(.caption2).foregroundStyle(.secondary)
                let usage = KeyboardSettings.glideUsageCounts
                let emojiUsage = KeyboardSettings.frequentlyUsedEmoji
                let words = KeyboardSettings.learnedWords
                HStack(spacing: 12) {
                    VStack(alignment: .leading) {
                        Text(String(usage.values.reduce(0, +)))
                            .font(.title3).bold()
                        Text("lượt chọn từ vuốt").font(.caption2)
                    }
                    VStack(alignment: .leading) {
                        Text(String(emojiUsage.values.reduce(0, +)))
                            .font(.title3).bold()
                        Text("emoji đã chọn").font(.caption2)
                    }
                    VStack(alignment: .leading) {
                        Text(String(KeyboardSettings.writingSamples.count))
                            .font(.title3).bold()
                        Text("ví dụ văn phong").font(.caption2)
                    }
                }
                .foregroundStyle(.cyan)
                let popular = Array(usage.sorted { $0.value > $1.value }.prefix(5))
                if !popular.isEmpty {
                    Text("Những từ vuốt thường chọn")
                        .font(.caption).bold()
                    ForEach(Array(popular.enumerated()), id: \.offset) { _, item in
                        let key = item.key.components(separatedBy: "|").last ?? item.key
                        HStack {
                            Text(key).font(.caption)
                            Spacer()
                            Text(String(item.value) + " lần")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
                let popularEmoji = Array(emojiUsage.sorted { $0.value > $1.value }.prefix(6))
                if !popularEmoji.isEmpty {
                    Text("Emoji đã chọn nhiều").font(.caption).bold()
                    HStack {
                        ForEach(Array(popularEmoji.enumerated()), id: \.offset) {
                            _, item in
                            Text(item.key + " ×" + String(item.value))
                                .font(.caption)
                        }
                    }
                }
                HStack {
                    Button(role: .destructive) {
                        KeyboardSettings.glideUsageCounts = [:]
                        KeyboardSettings.frequentlyUsedEmoji = [:]
                        feedback = "Đã đặt lại lịch sử học từ vuốt và emoji."
                    } label: { Label("Xóa thống kê học", systemImage: "trash") }
                    Button {
                        feedback = "Từ cá nhân đã học: " + String(words.count)
                            + ". Quản lý tại phần Bàn phím."
                    } label: { Label("Từ điển cá nhân", systemImage: "book") }
                }
                .font(.caption).buttonStyle(.bordered)
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
        .onDisappear { historyUnlocked = false }
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

    private func unlockChatHistory() {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            feedback = "Chưa thiết lập Face ID hoặc mật mã thiết bị."
            return
        }
        context.evaluatePolicy(.deviceOwnerAuthentication,
            localizedReason: "Mở khóa lịch sử trò chuyện ViePN") { success, _ in
            DispatchQueue.main.async {
                if success {
                    historyUnlocked = true
                    savedChatTurns = ConversationHistory.turns(
                        for: PersonaStore.activeID)
                    savedMemories = ConversationMemory.forActivePersona()
                    feedback = "Đã mở khóa hội thoại."
                } else {
                    feedback = "Chưa xác thực. Lịch sử vẫn được khóa."
                }
            }
        }
    }

    @MainActor
    private func proposeFromHistory(openingToday: Bool) async {
        guard !busy else { return }
        guard PersonaStore.active != nil else {
            feedback = "Hãy chọn hồ sơ người nhận."
            return
        }
        let context = ConversationHistory.turns(for: PersonaStore.activeID)
        guard !context.isEmpty else {
            feedback = "Hãy nhập và lưu lịch sử hội thoại trước."
            return
        }
        if !openingToday && context.last?.speaker != .other {
            feedback = "Tin cuối đã lưu không phải của người ấy. Hãy bổ sung tin nhắn mới nhất trước khi gợi ý trả lời."
            return
        }
        busy = true
        defer { busy = false }
        let incoming = openingToday ? openingNote : (context.last?.text ?? "")
        do {
            let suggestions = try await AIService.reply(
                to: incoming, openingToday: openingToday)
            generatedChatSuggestions = suggestions
            chatPreview = suggestions.first?.text ?? ""
            showExplanation = false
            evidenceExplanation = ConversationIntelligence.explanation(
                for: PersonaStore.activeID, query: incoming,
                openingToday: openingToday)
            feedback = "Đã tạo " + String(suggestions.count)
                + " gợi ý. Chọn hoặc chỉnh lại trước khi sử dụng."
        } catch {
            feedback = "Không tạo được gợi ý: " + error.localizedDescription
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
