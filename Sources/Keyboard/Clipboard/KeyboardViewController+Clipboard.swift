import UIKit
import AudioToolbox
import Vision

extension KeyboardViewController {
    func installClipboardMenu() {
        guard let paste = toolbarButtons[.paste] else { return }
        let save = UIAction(title: "Lưu đoạn vừa Dán",
                            image: UIImage(systemName: "tray.and.arrow.down")) { [weak self] _ in
            guard let self else { return }
            guard !self.selectedText.isEmpty else {
                self.showStatus("Nhấn Dán trước, rồi giữ nút Dán để lưu")
                return
            }
            guard ClipboardVault.saveExplicitly(self.selectedText) else {
                self.showStatus("Không lưu clipboard có dữ liệu nhạy cảm hoặc đang gõ riêng tư.")
                return
            }
            self.installClipboardMenu()
            self.showStatus("Đã lưu bản sao do bạn chọn · tối đa 15 đoạn")
        }
        let items: [UIAction] = ClipboardVault.items.enumerated().map { index, text in
            UIAction(title: String(text.prefix(40)), image: UIImage(systemName: "doc.text")) {
                [weak self] _ in
                self?.selectedText = text
                self?.showStatus("Đã chọn đoạn \(index + 1) · Chạm AI để xử lý")
            }
        }
        let history = UIMenu(title: "Các đoạn đã lưu",
                             image: UIImage(systemName: "tray.full"),
                             children: items)
        let clear = UIAction(title: "Xóa tất cả đoạn đã lưu",
                             image: UIImage(systemName: "trash"),
                             attributes: .destructive) { [weak self] _ in
            ClipboardVault.clear()
            self?.installClipboardMenu()
            self?.showStatus("Đã xóa clipboard được lưu trong ViePN")
        }
        paste.menu = UIMenu(title: "Clipboard cá nhân",
                            children: [save, history, clear, UIAction(title:"Xem trước & dán",image:UIImage(systemName:"doc.on.clipboard")){[weak self] _ in self?.everydayPastePreview()}])
        paste.showsMenuAsPrimaryAction = false
        paste.accessibilityHint = "Chạm để Dán; nhấn giữ để lưu, chọn hoặc xóa clipboard."
    }

    @objc func pasteTapped() {
        let startedAt = CACurrentMediaTime()
        defer { KeyboardStability.note("paste", durationMs:
            (CACurrentMediaTime() - startedAt) * 1000) }
        // Always-visible, real UIButton. Never replace it with a system control
        // that can disappear when iOS marks the pasteboard as unavailable.
        guard hasFullAccess else {
            showStatus("Bật Cho phép truy cập đầy đủ để dùng nút Dán")
            return
        }
        let clipboard = UIPasteboard.general
        guard clipboard.hasStrings else {
            showStatus("Chưa có văn bản · Hãy sao chép tin nhắn cần phân tích")
            return
        }
        guard let text = clipboard.string,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showStatus("Không đọc được clipboard. Kiểm tra quyền Dán trong Cài đặt.")
            return
        }
        cancelAIRequest()
        selectedText = String(text.prefix(3000))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        clearSuggestions()
        let matchedPersona = PersonaStore.autoSelect(fromSharedTranscript: selectedText)
        if matchedPersona != nil {
            installWritingActions()
            refreshProfileIndicator()
            refreshIdleActions()
        }
        let context = ConversationContextResolver.resolve(selectedText)
        let matchLabel = matchedPersona.map { "✓ Đã khớp: " + $0.name } ??
            ("Người nhận: " + context.displayName)
        showStatus(matchLabel + " · Nhấn AI")
    }

    func requestedInput() -> String {
        let context = textDocumentProxy.documentContextBeforeInput ?? ""
        return selectedText.isEmpty ? String(context.suffix(3000)) : selectedText
    }
}
