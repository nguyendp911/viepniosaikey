import SwiftUI
import UIKit
import AudioToolbox
import PhotosUI

extension ContentView {
    var aiConfiguration: some View {
        card(title: "AI & API", subtitle: "Chọn nhà cung cấp và kết nối model", icon: "sparkles") {
            VStack(alignment: .leading, spacing: 13) {
                Picker("Nhà cung cấp AI", selection: $provider) {
                    Text("Google Gemini").tag("gemini")
                    Text("OpenAI").tag("openai")
                }
                .pickerStyle(.segmented)
                .onChange(of: provider) { newValue in
                    KeyboardSettings.provider = newValue
                    apiFeedback = ""
                    suggestions = []
                }

                keyboardMenuRow("Người nhận tin nhắn", symbol: "person.crop.circle",
                                value: $recipientMode,
                                options: ReplyRecipient.allCases.map { ($0.rawValue, $0.title) })
                    .onChange(of: recipientMode) {
                        PersonaStore.activeID = ""
                        activePersonaID = ""
                        KeyboardSettings.recipientMode = $0
                    }
                Text("Tự nhận diện từ tin được dán. Nếu AI xưng hô sai, hãy chọn Chú, Cô, Bác, Thầy/Cô, Bạn bè…; chế độ đã chọn dùng cho các tin tiếp theo tới khi đổi lại.")
                    .font(.system(size: 11))
                    .foregroundStyle(muted)
                    .fixedSize(horizontal: false, vertical: true)

                Toggle(isOn: $cloudEnabled) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Cho phép AI online")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Chỉ gửi nội dung khi bạn chủ động yêu cầu")
                            .font(.system(size: 11))
                            .foregroundStyle(muted)
                    }
                }
                .tint(violet)
                .onChange(of: cloudEnabled) { KeyboardSettings.allowCloudAI = $0 }

                if provider == "gemini" {
                    keyField("Gemini API Key", text: $geminiAPIKey, revealed: $showGeminiKey)
                        .onChange(of: geminiAPIKey) {
                            if !KeyboardSettings.saveProviderKey($0, provider: "gemini") {
                                apiFeedback = "Không lưu được Keychain. Kiểm tra quyền App Group và ký IPA."
                            }
                        }
                    modelField("Model Gemini (auto hoặc ID)", text: $geminiModel)
                        .onChange(of: geminiModel) { KeyboardSettings.geminiModel = $0 }
                    modelField("Model dự phòng (429/503)", text: $fallbackModel)
                        .onChange(of: fallbackModel) { KeyboardSettings.fallbackModel = $0 }

                    if !availableModels.isEmpty {
                        Picker("Model được Google cung cấp", selection: $geminiModel) {
                            Text("Tự động chọn model").tag("auto")
                            if geminiModel != "auto", !availableModels.contains(where: { $0.id == geminiModel }) {
                                Text("Model đang nhập: \(geminiModel)").tag(geminiModel)
                            }
                            ForEach(availableModels) { item in
                                Text(item.id).tag(item.id)
                            }
                        }
                        .tint(cyan)
                        .onChange(of: geminiModel) { KeyboardSettings.geminiModel = $0 }
                    }

                    HStack(spacing: 9) {
                        actionButton(loadingModels ? "Đang tải…" : "Lấy model", symbol: "arrow.clockwise",
                                     disabled: loadingModels || geminiAPIKey.isEmpty) {
                            fetchModels()
                        }
                        actionButton(testingAPI ? "Đang thử…" : "Kiểm tra API", symbol: "checkmark.circle",
                                     prominent: true,
                                     disabled: testingAPI || !cloudEnabled || geminiAPIKey.isEmpty) {
                            testConnection()
                        }
                    }
                } else {
                    keyField("OpenAI API Key", text: $openAIAPIKey, revealed: $showOpenAIKey)
                        .onChange(of: openAIAPIKey) {
                            if !KeyboardSettings.saveProviderKey($0, provider: "openai") {
                                apiFeedback = "Không lưu được Keychain. Kiểm tra quyền App Group và ký IPA."
                            }
                        }
                    modelField("Model OpenAI", text: $openAIModel)
                        .onChange(of: openAIModel) { KeyboardSettings.openAIModel = $0 }

                    actionButton(testingAPI ? "Đang thử kết nối…" : "Kiểm tra OpenAI API",
                                 symbol: "checkmark.circle", prominent: true,
                                 disabled: testingAPI || !cloudEnabled || openAIAPIKey.isEmpty) {
                        testConnection()
                    }
                }

                if !apiFeedback.isEmpty {
                    Text(apiFeedback)
                        .font(.system(size: 12))
                        .foregroundStyle(apiFeedback.hasPrefix("✓") ? Color.mint : Color.orange)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack {
                    Label("Khóa lưu trong Keychain dùng chung App Group",
                          systemImage: "lock.shield")
                        .font(.system(size: 11))
                        .foregroundStyle(muted)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Button("Xóa khóa", role: .destructive) {
                        if provider == "gemini" {
                            geminiAPIKey = ""
                            KeyboardSettings.geminiAPIKey = ""
                        } else {
                            openAIAPIKey = ""
                            KeyboardSettings.openAIAPIKey = ""
                        }
                        apiFeedback = "Đã xóa API Key của nhà cung cấp hiện tại."
                    }
                    .font(.system(size: 12))
                }
            }
        }
    }

    func fetchModels() {
        guard !loadingModels else { return }
        loadingModels = true
        apiFeedback = ""
        Task {
            do {
                let models = try await GeminiModelCatalog.fetch(apiKey: geminiAPIKey)
                availableModels = models
                if models.isEmpty {
                    apiFeedback = "Danh sách không có model hỗ trợ generateContent cho API Key này."
                } else {
                    if geminiModel != "auto", !models.contains(where: { $0.id == geminiModel }) {
                        geminiModel = "auto"
                        KeyboardSettings.geminiModel = "auto"
                    }
                    apiFeedback = "✓ Đã tải \(models.count) model từ Google."
                }
            } catch {
                apiFeedback = error.localizedDescription
            }
            loadingModels = false
        }
    }

    func testConnection() {
        guard !testingAPI else { return }
        testingAPI = true
        apiFeedback = ""
        Task {
            do {
                let items = try await AIService.reply(to: "Xin chào, bạn có khỏe không?")
                apiFeedback = "✓ API hoạt động, nhận \(items.count) gợi ý."
            } catch {
                apiFeedback = error.localizedDescription
            }
            testingAPI = false
        }
    }
}
