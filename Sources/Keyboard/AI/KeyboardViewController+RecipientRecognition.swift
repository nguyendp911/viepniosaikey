import UIKit
import AudioToolbox
import Vision

extension KeyboardViewController {
    /// A keyboard extension cannot read Zalo/Messenger's chat title.
    /// This opt-in workflow looks ONLY at an image the user explicitly copied
    /// into the system clipboard, never at host app UI or conversation text.
    func recognizeRecipientFromCopiedScreenshot() {
        guard !isRequestRunning else { return }
        guard hasFullAccess else {
            showStatus("Cần Full Access để đọc ảnh được bạn sao chép")
            return
        }
        guard let picture = UIPasteboard.general.image else {
            showStatus("Chưa có ảnh trong bộ nhớ Dán. Sao chép ảnh chụp Zalo rồi thử lại.")
            return
        }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let bound = max(picture.size.width, picture.size.height)
        let factor = min(1, 1100 / max(1, bound))
        let target = CGSize(width: picture.size.width * factor,
                            height: picture.size.height * factor)
        guard target.width >= 100, target.height >= 100 else {
            showStatus("Ảnh quá nhỏ để đọc tiêu đề")
            return
        }
        let renderer = UIGraphicsImageRenderer(size: target, format: format)
        let png = renderer.pngData { _ in
            picture.draw(in: CGRect(origin: .zero, size: target))
        }
        // Never retain or upload the screenshot; process only a temporary,
        // downscaled image to minimize keyboard extension memory pressure.
        isRequestRunning = true
        showStatus("Đang đọc tiêu đề ảnh đã sao chép…")
        let ticket = UUID()
        requestID = ticket
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let found: PersonaStore.ScreenshotMatch?
            if let image = UIImage(data: png)?.cgImage {
                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate
                request.recognitionLanguages = ["vi-VN", "en-US"]
                request.usesLanguageCorrection = false
                do {
                    try VNImageRequestHandler(cgImage: image, options: [:])
                        .perform([request])
                    let boxes = (request.results ?? []).compactMap { observation
                        -> PersonaStore.ScreenshotTextBox? in
                        guard let label = observation.topCandidates(1).first?.string
                        else { return nil }
                        return PersonaStore.ScreenshotTextBox(
                            text: label, midX: Double(observation.boundingBox.midX),
                            midY: Double(observation.boundingBox.midY))
                    }
                    found = PersonaStore.matchScreenshotTitle(boxes)
                } catch {
                    found = nil
                }
            } else {
                found = nil
            }
            DispatchQueue.main.async {
                guard let self, self.requestID == ticket else { return }
                self.isRequestRunning = false
                guard let found else {
                    self.showStatus("Không khớp tên ở tiêu đề ảnh. Dùng ViePN → AI & API để chọn hồ sơ.")
                    return
                }
                guard let person = found.uniqueMatch else {
                    self.showStatus("Có nhiều hồ sơ trùng tên: " + found.recognizedTitle
                        + ". Giữ nút AI → Hồ sơ người nhận để chọn.")
                    return
                }
                guard PersonaStore.automaticNameMatch else {
                    self.showStatus("Đã thấy " + person.name
                        + ". Bật Tự khớp tên hoặc chọn trong menu Hồ sơ.")
                    return
                }
                PersonaStore.select(person.id)
                self.installWritingActions()
                self.refreshIdleActions()
                self.refreshProfileIndicator()
                self.showStatus("Đã nhận diện theo ảnh sao chép: " + person.name)
            }
        }
    }

    /// Show the effective persona in the toolbar, not only in an invisible
    /// App Group preference. This helps catch a stale profile before AI reply.
    func refreshProfileIndicator() {
        guard let button = toolbarButtons[.ai] else { return }
        let person = PersonaStore.active
        button.setPersonaIndicator(person != nil)
        button.accessibilityLabel = person.map { "AI, hồ sơ đang chọn: " + $0.name } ?? "AI, chưa chọn hồ sơ người nhận"
        button.accessibilityValue = person?.name
        // Keep a stable one-line title. The small dot indicates an active profile.
    }
}
