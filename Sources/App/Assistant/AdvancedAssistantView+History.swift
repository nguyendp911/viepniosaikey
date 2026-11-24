import SwiftUI
import PhotosUI
import Vision
import Speech
import AVFoundation
import EventKit
import UIKit
import LocalAuthentication

extension AdvancedAssistantView {
    var historyPrivacySection: some View {
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
    }

    var memorySection: some View {
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
                    if ConversationMemory.saveVerified(
                        memoryText, for: PersonaStore.activeID) {
                        memoryText = ""
                        savedMemories = ConversationMemory.forActivePersona()
                        feedback = "Đã lưu ghi chú vào bộ nhớ được bảo vệ."
                    } else {
                        feedback = "Không thể lưu ghi chú. Kiểm tra App Group và trạng thái khóa iPhone."
                    }
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
    }

    var historySection: some View {
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
                        if count > 0 {
                            transcriptDraft = ""
                            feedback = "Đã lưu " + String(count) + " lượt mới cho " + person.name + "."
                        } else {
                            let alreadySaved = ConversationHistory.parse(transcriptDraft)
                                .allSatisfy { item in
                                    savedChatTurns.contains {
                                        $0.speaker == item.0 && $0.text == item.1
                                    }
                                }
                            feedback = alreadySaved
                                ? "Các tin nhắn này đã có trong lịch sử."
                                : "Không thể lưu lịch sử. Kiểm tra App Group hoặc trạng thái khóa iPhone."
                        }
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
                    TextField("Tìm trong lịch sử đã lưu", text: $chatSearch)
                        .textFieldStyle(.roundedBorder)
                    let filtered = savedChatTurns.filter {
                        chatSearch.isEmpty || $0.text.localizedCaseInsensitiveContains(chatSearch)
                    }
                    ForEach(Array(filtered.suffix(10))) { turn in
                        VStack(alignment: .leading, spacing: 5) {
                            HStack(alignment: .top, spacing: 8) {
                                Text(turn.speaker == .me ? "Tôi" : "Bạn ấy")
                                    .font(.caption2).bold()
                                    .foregroundStyle(turn.speaker == .me ? .cyan : .mint)
                                    .frame(width: 51, alignment: .leading)
                                Text(turn.text).font(.caption2)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Button {
                                    editingChatTurnID = turn.id
                                    editingChatText = turn.text
                                } label: {
                                    Image(systemName: "pencil")
                                }.accessibilityLabel("Sửa tin nhắn")
                                Button(role: .destructive) {
                                    ConversationHistory.all.removeAll { $0.id == turn.id }
                                    savedChatTurns = ConversationHistory.turns(
                                        for: PersonaStore.activeID)
                                    feedback = "Đã xóa tin nhắn được chọn."
                                } label: {
                                    Image(systemName: "trash")
                                }.accessibilityLabel("Xóa tin nhắn")
                            }
                            if editingChatTurnID == turn.id {
                                TextField("Chỉnh lại nội dung tin nhắn", text: $editingChatText)
                                    .textFieldStyle(.roundedBorder)
                                HStack {
                                    Button("Lưu sửa") {
                                        let value = String(editingChatText
                                            .trimmingCharacters(in: .whitespacesAndNewlines)
                                            .prefix(800))
                                        guard !value.isEmpty,
                                              MessageSafety.warnings(in: value).isEmpty else {
                                            feedback = "Nội dung trống hoặc có dữ liệu nhạy cảm."
                                            return
                                        }
                                        var all = ConversationHistory.all
                                        if let index = all.firstIndex(where: {
                                            $0.id == turn.id && $0.personaID == PersonaStore.activeID
                                        }) {
                                            all[index].text = value
                                            ConversationHistory.all = all
                                        }
                                        savedChatTurns = ConversationHistory.turns(
                                            for: PersonaStore.activeID)
                                        editingChatTurnID = nil
                                        feedback = "Đã sửa nội dung trong lịch sử."
                                    }
                                    Button("Hủy") { editingChatTurnID = nil }
                                }
                                .font(.caption).buttonStyle(.bordered)
                            }
                        }
                        .padding(7)
                        .background(.white.opacity(0.045),
                                    in: RoundedRectangle(cornerRadius: 9))
                    }
                    // Export is opt-in and scoped to the selected person.
                    // The system share sheet is invoked only by a real tap;
                    // sharing a transcript as plain text is NOT encrypted.
                    if let person = PersonaStore.active {
                        ShareLink(item: conversationExport(for: person.id),
                                  subject: Text("Hội thoại của " + person.name),
                                  message: Text("Bản sao lịch sử do tôi chủ động xuất từ ViePN")) {
                            Label("Xuất hội thoại người này", systemImage: "square.and.arrow.up")
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                        Text("Bản xuất là văn bản thường, không mã hóa. Chỉ chia sẻ với nơi bạn tin cậy; không gửi công khai.")
                            .font(.caption2).foregroundStyle(.orange)
                    }
                    Button(role: .destructive) {
                        showClearChatConfirmation = true
                    } label: {
                        Label("Xóa toàn bộ lịch sử người này", systemImage: "trash")
                    }
                    .font(.caption)
                    .confirmationDialog(
                        "Xóa vĩnh viễn mọi tin nhắn đã lưu của hồ sơ này?",
                        isPresented: $showClearChatConfirmation,
                        titleVisibility: .visible) {
                        Button("Xóa vĩnh viễn", role: .destructive) {
                            guard let person = PersonaStore.active else { return }
                            ConversationHistory.clear(for: person.id)
                            savedChatTurns = ConversationHistory.turns(for: person.id)
                            chatPreview = ""
                            generatedChatSuggestions = []
                            evidenceExplanation = ""
                            feedback = savedChatTurns.isEmpty
                                ? "Đã xóa lịch sử của " + person.name + "."
                                : "Xóa chưa hoàn tất. Kiểm tra vùng lưu trữ của iOS."
                        }
                        Button("Hủy", role: .cancel) {}
                    }
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
    }

    var lockedHistorySection: some View {
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

    func conversationExport(for personaID: String) -> String {
        ConversationHistory.exportText(for: personaID)
    }

    func refreshActiveChatProfile() {
        savedChatTurns = ConversationHistory.turns(for: PersonaStore.activeID)
        savedMemories = ConversationMemory.forActivePersona()
        generatedChatSuggestions = []
        chatPreview = ""
        evidenceExplanation = ""
        editingChatTurnID = nil
    }

    func unlockChatHistory() {
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
    func proposeFromHistory(openingToday: Bool) async {
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
}
