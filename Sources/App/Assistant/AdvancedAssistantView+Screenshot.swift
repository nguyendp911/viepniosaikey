import SwiftUI
import PhotosUI
import Vision
import Speech
import AVFoundation
import EventKit
import UIKit
import LocalAuthentication

extension AdvancedAssistantView {
    var screenshotSection: some View {
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
                if let match = screenshotMatch {
                    Text("Chữ nhận diện trong ảnh: " + match.recognizedTitle)
                        .font(.caption).foregroundStyle(.cyan)
                    if !screenshotEvidence.isEmpty {
                        Text(screenshotEvidence)
                            .font(.caption2)
                            .foregroundStyle(screenshotVisualOnly ? .orange : .green)
                    }
                    if match.matches.count == 1, let person = match.uniqueMatch {
                        HStack {
                            Text("Đã tìm thấy hồ sơ: " + person.name)
                                .font(.caption)
                            Spacer()
                            Button("Chọn hồ sơ") {
                                selectScreenshotPersona(person)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    } else {
                        Text(screenshotVisualOnly
                             ? "Ảnh mẫu có nét tương tự. Đây không phải xác minh danh tính; hãy tự chọn đúng người:"
                             : "Có nhiều hồ sơ trùng tên. Hãy xác nhận đúng người:")
                            .font(.caption2).foregroundStyle(.orange)
                        ForEach(match.matches) { person in
                            Button {
                                selectScreenshotPersona(person)
                            } label: {
                                Label(person.name + " · " + person.recipient,
                                      systemImage: "person.crop.circle")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                if !screenshotMatchStatus.isEmpty {
                    Text(screenshotMatchStatus)
                        .font(.caption2).foregroundStyle(.secondary)
                }
                let lensFindings = ConversationLens.findings(in: sourceText)
                if !lensFindings.isEmpty {
                    Text("Conversation Lens · Phát hiện trực tiếp từ chữ OCR")
                        .font(.caption).bold()
                    ForEach(lensFindings) { finding in
                        VStack(alignment: .leading, spacing: 6) {
                            Label(finding.text,
                                  systemImage: finding.kind == .question
                                      ? "questionmark.bubble" : "calendar.badge.clock")
                                .font(.caption)
                            HStack {
                                Button("Dùng để gợi ý trả lời") {
                                    sourceText = finding.text
                                    mode = "Gợi ý trả lời"
                                    feedback = "Đã chọn câu từ ảnh. Kiểm tra văn bản, sau đó nhấn Xử lý bằng AI."
                                }
                                if finding.kind == .followUp {
                                    Button("Nhắc việc") {
                                        remindersTitle = String(finding.text.prefix(70))
                                        feedback = "Đã điền nội dung nhắc việc. Hãy tự xác nhận ngày giờ trước khi lưu."
                                    }
                                }
                            }
                            .font(.caption2).buttonStyle(.bordered)
                        }
                    }
                    Text("Đây là các câu nguyên văn cần xem lại, không xác nhận người gửi, thời điểm hoặc ý định.")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
    }

    @MainActor
    func readScreenshot(_ item: PhotosPickerItem) async {
        let ticket = UUID()
        screenshotRecognitionRequest = ticket
        busy = true
        screenshotMatch = nil
        screenshotEvidence = ""
        screenshotVisualOnly = false
        screenshotMatchStatus = "Đang đối chiếu ảnh với các hồ sơ đã lưu…"
        // A new screenshot represents a new conversation, not the old
        // previously selected recipient. Never silently reuse that person's
        // private history while we cannot verify the new one.
        PersonaStore.clearSelection()
        refreshActiveChatProfile()
        defer {
            if screenshotRecognitionRequest == ticket { busy = false }
        }
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data)?.cgImage else {
                feedback = "Không đọc được ảnh. Hãy chọn ảnh chụp màn hình khác."
                return
            }
            let observations = try await Task.detached(priority: .userInitiated) {
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
                    }.compactMap { observation
                        -> PersonaStore.ScreenshotTextBox? in
                        guard let string = observation.topCandidates(1).first?.string
                        else { return nil }
                        return PersonaStore.ScreenshotTextBox(
                            text: string, midX: Double(observation.boundingBox.midX),
                            midY: Double(observation.boundingBox.midY))
                    }
            }.value
            sourceText = String(
                observations.map(\.text).joined(separator: "\n").prefix(3000))
            // Enrolled navigation-title references take precedence over
            // contact display-name matching. A nickname in Zalo may differ
            // from the user's saved contact name.
            // Main-app AI recognition combines normalized screenshot title
            // OCR with on-device Vision comparison of saved header references.
            // Only a uniquely OCR-confirmed title can auto-select the
            // recipient; image-only evidence is a suggestion, not identity.
            let scan = try await ChatScreenshotReference.scan(data)
            let recognition = await ChatScreenshotReference.recognize(scan)
            guard screenshotRecognitionRequest == ticket else { return }
            screenshotVisualOnly = recognition?.method == .imageReference
            if let recognition {
                screenshotMatch = PersonaStore.ScreenshotMatch(
                    recognizedTitle: recognition.title,
                    matches: recognition.matches)
                screenshotEvidence = recognition.method == .titleOCR
                    ? (recognition.matches.count == 1
                        ? "Đã khớp duy nhất tên trên tiêu đề với hồ sơ đã lưu."
                        : "Có nhiều tên được phát hiện. Chưa tự chọn hồ sơ.")
                    : "Chỉ có tương đồng hình ảnh. Không đủ chứng cứ để xác định người nhận; phải chọn thủ công."
                if PersonaStore.automaticNameMatch,
                   recognition.mayAutoSelect,
                   let person = recognition.uniqueMatch {
                    selectScreenshotPersona(person)
                    screenshotMatchStatus = "AI nhận diện từ tiêu đề: "
                        + person.name + ". Đã áp dụng hồ sơ."
                    feedback = "Đã tự chọn hồ sơ từ tiêu đề ảnh bạn cung cấp."
                } else {
                    screenshotMatchStatus = recognition.matches.count > 1
                        ? "Có nhiều hồ sơ có thể phù hợp. Hãy xác nhận đúng người."
                        : "Chưa xác minh danh tính, hãy xác nhận người phù hợp."
                    feedback = screenshotMatchStatus
                }
            } else {
                screenshotMatch = nil
                screenshotEvidence = ""
                screenshotMatchStatus =
                    "Chưa xác định được hồ sơ từ ảnh mới. Hồ sơ cũ đã được bỏ chọn để tránh nhầm người."
                feedback = observations.isEmpty
                    ? "OCR chưa đọc được chữ. Kiểm tra ảnh và hồ sơ đã lưu."
                    : "Đã đọc nội dung ảnh nhưng chưa khớp hồ sơ đủ tin cậy."
            }
        } catch {
            guard screenshotRecognitionRequest == ticket else { return }
            feedback = "Lỗi đọc ảnh: " + error.localizedDescription
            screenshotMatch = nil
            screenshotMatchStatus = "Không thể nhận diện. Hồ sơ cũ đã bỏ chọn; hãy chọn thủ công."
        }
    }

    func selectScreenshotPersona(_ person: RecipientPersona) {
        guard PersonaStore.all.contains(where: { $0.id == person.id }) else { return }
        PersonaStore.select(person.id)
        refreshActiveChatProfile()
        screenshotMatchStatus = "Đã chọn hồ sơ " + person.name
            + ". ViePN sẽ sử dụng lịch sử riêng của người này."
        feedback = "Đã xác nhận đúng người nhận từ ảnh."
    }
}
