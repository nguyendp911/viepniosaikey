import UIKit
import AudioToolbox
import Vision

extension KeyboardViewController {
    func suggestDailyMessage() {
        guard !isRequestRunning else { return }
        guard hasFullAccess else {
            showStatus("Cần Full Access để sử dụng AI")
            return
        }
        guard let person = PersonaStore.active,
              !ConversationHistory.turns(for: person.id).isEmpty else {
            showStatus("Mở ViePN → Trợ lý để lưu hội thoại cho người nhận")
            return
        }
        let history = ConversationHistory.prompt(for: person.id)
        guard MessageSafety.warnings(in: history).isEmpty else {
            showStatus("Lịch sử có dữ liệu nhạy cảm · Hãy kiểm tra trong ứng dụng")
            return
        }
        isRequestRunning = true
        let activeID = UUID()
        requestID = activeID
        showStatus("Đang gợi ý lời nhắn hôm nay cho " + person.name)
        let documentID = textDocumentProxy.documentIdentifier
        aiTask = Task { [weak self] in
            do {
                let suggestions = try await AIService.reply(
                    to: "", openingToday: true)
                await MainActor.run {
                    guard let self, self.requestID == activeID else { return }
                    self.isRequestRunning = false
                    guard PersonaStore.activeID == person.id,
                          self.textDocumentProxy.documentIdentifier == documentID else { return }
                    self.show(suggestions)
                }
            } catch {
                await MainActor.run {
                    guard let self, self.requestID == activeID else { return }
                    self.isRequestRunning = false
                    self.showStatus("Không tạo được gợi ý: " + error.localizedDescription)
                }
            }
        }
    }

    func performWritingAction(_ action: AIWritingAction) {
        guard !isRequestRunning else { return }
        guard hasFullAccess else { showStatus("Cần Full Access để dùng AI"); return }
        let source = selectedText.isEmpty
            ? (textDocumentProxy.documentContextBeforeInput ?? "") : selectedText
        if !MessageSafety.warnings(in: source).isEmpty {
            showStatus("Có dữ liệu nhạy cảm · Mở tab Trợ lý để ẩn rồi xử lý.")
            return
        }
        guard !source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showStatus("Dán hoặc soạn nội dung trước khi dùng AI")
            return
        }
        isRequestRunning = true
        showStatus("AI đang xử lý: " + action.rawValue)
        let activeID = UUID()
        requestID = activeID
        let documentID = textDocumentProxy.documentIdentifier
        aiTask = Task { [weak self] in
            do {
                let transformed = try await AIWritingService.transform(source, action: action)
                await MainActor.run {
                    guard let self, self.requestID == activeID else { return }
                    self.isRequestRunning = false
                    guard self.textDocumentProxy.documentIdentifier == documentID else { return }
                    self.show([ReplySuggestion(tone: action.rawValue, text: transformed)])
                }
            } catch {
                await MainActor.run {
                    guard let self, self.requestID == activeID else { return }
                    self.isRequestRunning = false
                    self.showStatus("AI lỗi: " + error.localizedDescription)
                }
            }
        }
    }

    func performWritingVariants() {
        guard !isRequestRunning else { return }
        guard hasFullAccess else { showStatus("Cần Full Access để dùng AI"); return }
        let source = selectedText.isEmpty
            ? (textDocumentProxy.documentContextBeforeInput ?? "") : selectedText
        guard !source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showStatus("Hãy nhập hoặc Dán nội dung trước khi dùng AI")
            return
        }
        guard MessageSafety.warnings(in: source).isEmpty else {
            showStatus("Có dữ liệu nhạy cảm · Hãy ẩn thông tin trước khi gửi AI")
            return
        }
        isRequestRunning = true
        let activeID = UUID()
        requestID = activeID
        showStatus("Đang tạo 3 phiên bản để bạn chọn")
        let documentID = textDocumentProxy.documentIdentifier
        aiTask = Task { [weak self] in
            do {
                let texts = try await AIWritingService.transformVariants(source)
                await MainActor.run {
                    guard let self, self.requestID == activeID else { return }
                    self.isRequestRunning = false
                    guard self.textDocumentProxy.documentIdentifier == documentID else { return }
                    let labels = ["Tự nhiên", "Lịch sự", "Ngắn gọn"]
                    self.show(texts.enumerated().map {
                        ReplySuggestion(tone: labels[$0.offset], text: $0.element)
                    })
                }
            } catch {
                await MainActor.run {
                    guard let self, self.requestID == activeID else { return }
                    self.isRequestRunning = false
                    self.showStatus("AI lỗi: " + error.localizedDescription)
                }
            }
        }
    }

    @objc func offlineTapped() {
        let startedAt = CACurrentMediaTime()
        defer { KeyboardStability.note("offline", durationMs:
            (CACurrentMediaTime() - startedAt) * 1000) }
        let text = requestedInput()
        guard !text.isEmpty else {
            showStatus("Dán tin nhắn cần trả lời trước")
            return
        }
        show(OfflineReplyEngine.suggest(for: text))
    }

    @objc func cloudTapped() {
        let startedAt = CACurrentMediaTime()
        defer { KeyboardStability.note("ai", durationMs:
            (CACurrentMediaTime() - startedAt) * 1000) }
        guard !isRequestRunning else { return }
        guard hasFullAccess else {
            showStatus("Cần bật Full Access để gọi AI")
            return
        }
        let source = requestedInput().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !source.isEmpty else {
            showStatus("Chưa có tin nhắn để phân tích · Chạm Dán")
            return
        }
        if !MessageSafety.warnings(in: source).isEmpty {
            showStatus("Có dữ liệu nhạy cảm · Giữ nút AI → Ẩn dữ liệu rồi hỏi AI")
            return
        }
        isRequestRunning = true
        requestID = UUID()
        let currentRequestID = requestID
        let originalPersonaID = PersonaStore.activeID
        let context = ConversationContextResolver.resolve(source)
        showStatus("AI đang phân tích · Người nhận: " + context.displayName)
        let documentID = textDocumentProxy.documentIdentifier
        aiTask = Task { [weak self] in
            do {
                let suggestions = try await AIService.reply(to: source)
                await MainActor.run {
                    guard let self, self.requestID == currentRequestID else { return }
                    self.isRequestRunning = false
                    guard PersonaStore.activeID == originalPersonaID,
                          self.textDocumentProxy.documentIdentifier == documentID else {
                        self.showStatus("Đã đổi hồ sơ người nhận · Bỏ kết quả AI cũ.")
                        return
                    }
                    self.show(suggestions)
                }
            } catch {
                await MainActor.run {
                    guard let self, self.requestID == currentRequestID else { return }
                    self.isRequestRunning = false
                    self.showStatus("AI lỗi: \(error.localizedDescription)")
                    // Do NOT silently replace an API error with offline suggestions.
                }
            }
        }
    }

    @objc func phrasesTapped() {
        let startedAt = CACurrentMediaTime()
        defer { KeyboardStability.note("phrases", durationMs:
            (CACurrentMediaTime() - startedAt) * 1000) }
        show(KeyboardSettings.savedPhrases.map { ReplySuggestion(tone: "Mẫu câu", text: $0) })
    }
}
