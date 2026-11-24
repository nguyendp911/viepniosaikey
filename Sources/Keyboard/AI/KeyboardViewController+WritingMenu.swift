import UIKit
import AudioToolbox
import Vision

extension KeyboardViewController {
    /// The paste target is the visible keyboard controller itself.
    /// No hidden UITextView, overlay, or direct UIPasteboard read is involved.
    /// The system control is enabled when compatible text exists on the pasteboard.
    func installWritingActions() {
        guard let aiButton = toolbarButtons[.ai] else { return }
        let actions = AIWritingAction.allCases.map { action in
            UIAction(title: action.rawValue, image: UIImage(systemName: "wand.and.stars")) { [weak self] _ in
                self?.performWritingAction(action)
            }
        }
        let selected = ReplyRecipient(rawValue: KeyboardSettings.recipientMode) ?? .automatic
        let receivers = ReplyRecipient.allCases.map { recipient -> UIAction in
            let action = UIAction(title: recipient.title) { [weak self] _ in
                self?.cancelAIRequest()
                PersonaStore.activeID = ""
                KeyboardSettings.recipientMode = recipient.rawValue
                self?.installWritingActions()
                self?.refreshProfileIndicator()
                let text = self?.selectedText ?? ""
                let resolved = ConversationContextResolver.resolve(text)
                self?.showStatus("Người nhận: " + resolved.displayName + " · Nhấn AI")
            }
            action.state = recipient == selected ? .on : .off
            return action
        }
        let receiverMenu = UIMenu(
            title: "Người nhận: " + selected.title,
            image: UIImage(systemName: "person.crop.circle"),
            children: receivers
        )
        let personaActions: [UIAction] = PersonaStore.all.map { person in
            let item = UIAction(title: person.name) { [weak self] _ in
                self?.cancelAIRequest()
                PersonaStore.select(person.id)
                self?.installWritingActions()
                self?.refreshIdleActions()
                self?.refreshProfileIndicator()
                self?.showStatus("Hồ sơ: " + person.name)
            }
            item.state = PersonaStore.activeID == person.id ? .on : .off
            return item
        }
        let profileMenu = UIMenu(
            title: "Hồ sơ người nhận",
            image: UIImage(systemName: "person.crop.rectangle.stack"),
            children: [UIAction(title: "Tắt hồ sơ") { [weak self] _ in
                self?.cancelAIRequest()
                PersonaStore.clearSelection()
                self?.installWritingActions()
                self?.refreshIdleActions()
                self?.refreshProfileIndicator()
                self?.showStatus("Đã tắt hồ sơ người nhận")
            }] + personaActions
        )
        let importDraft = UIAction(
            title: "Lấy bản nháp từ ứng dụng ViePN",
            image: UIImage(systemName: "square.and.arrow.down")
        ) { [weak self] _ in
            let draft = ShareDraft.current
            guard !draft.isEmpty else {
                self?.showStatus("Chưa có bản nháp · Mở tab Trợ lý để tạo.")
                return
            }
            self?.selectedText = draft
            self?.showStatus("Đã nhận bản nháp · Nhấn AI để tạo câu trả lời")
        }
        let privacyAction = UIAction(
            title: "Ẩn dữ liệu nhạy cảm rồi hỏi AI",
            image: UIImage(systemName: "hand.raised.slash")
        ) { [weak self] _ in
            guard let self else { return }
            let text = self.requestedInput()
            guard !text.isEmpty else {
                self.showStatus("Chưa có văn bản để xử lý.")
                return
            }
            self.selectedText = MessageSafety.redacted(text)
            self.cloudTapped()
        }
        let undoAction = UIAction(title: "Hoàn tác sửa từ",
                                  image: UIImage(systemName: "arrow.uturn.backward")) { [weak self] _ in
            self?.undoWordCorrection()
        }
        let variantsAction = UIAction(title: "Viết lại · 3 phiên bản",
                                      image: UIImage(systemName: "square.stack.3d.up")) { [weak self] _ in
            self?.performWritingVariants()
        }
        let screenshotAction = UIAction(
            title: "Nhận diện người từ ảnh đã sao chép",
            image: UIImage(systemName: "photo.text.rectangle")
        ) { [weak self] _ in
            self?.recognizeRecipientFromCopiedScreenshot()
        }
        let cancelAction = UIAction(title: "Hủy yêu cầu AI", image: UIImage(systemName: "xmark.circle")) { [weak self] _ in
            self?.cancelAIRequest()
            self?.showStatus("Đã hủy yêu cầu.")
        }
        let openingAction = UIAction(title: "Hôm nay nhắn gì? · Theo lịch sử",
                                     image: UIImage(systemName: "sun.max")) { [weak self] _ in
            self?.suggestDailyMessage()
        }
        aiButton.menu = UIMenu(
            title: "AI · Hội thoại và viết lại",
            children: [receiverMenu, profileMenu, screenshotAction, openingAction,
                       importDraft, privacyAction, undoAction, variantsAction, cancelAction] + actions
        )
        aiButton.showsMenuAsPrimaryAction = false
        aiButton.accessibilityHint =
            "Chạm AI để trả lời. Nhấn giữ để kiểm tra hồ sơ, nhận diện ảnh đã sao chép hoặc chọn người nhận."
    }

    @objc func coupleTapped() {
        let startedAt = CACurrentMediaTime()
        defer { KeyboardStability.note("couple", durationMs:
            (CACurrentMediaTime() - startedAt) * 1000) }
        KeyboardSettings.coupleEnabled.toggle()
        updateCoupleTool()
        showStatus(KeyboardSettings.coupleEnabled
            ? "💗 Couple đã bật · Dán tin nhắn rồi nhấn ✦ AI"
            : "Đã chuyển sang trợ lý nhắn tin thông thường")
        tactileFeedback()
    }

    func updateCoupleTool() {
        guard let button = toolbarButtons[.couple] else { return }
        let active = KeyboardSettings.coupleEnabled
        applyToolbarAppearance()
        button.accessibilityLabel = active
            ? "AI Couple: " + CoupleStyleCatalog.active.title : "Bật AI Couple"
        button.accessibilityHint = "Chạm để bật/tắt. Nhấn giữ để chọn một trong các phong cách."
        installCoupleStyleMenu()
    }

    func installCoupleStyleMenu() {
        guard let coupleButton = toolbarButtons[.couple] else { return }
        let selected = KeyboardSettings.coupleStyle
        let actions = CoupleStyleCatalog.styles.map { style -> UIAction in
            let action = UIAction(title: style.icon + " " + style.title) { [weak self] _ in
                KeyboardSettings.coupleEnabled = true
                KeyboardSettings.coupleStyle = style.id
                self?.updateCoupleTool()
                self?.showStatus("♥ Couple: " + style.title + " · Dán rồi nhấn ✦ AI")
            }
            action.state = style.id == selected ? .on : .off
            return action
        }
        coupleButton.menu = UIMenu(title: "Phong cách AI Couple", children: actions)
        coupleButton.showsMenuAsPrimaryAction = false
    }
}
