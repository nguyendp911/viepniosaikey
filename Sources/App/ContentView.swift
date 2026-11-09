import SwiftUI
import UIKit

struct ContentView: View {
    @State private var provider = KeyboardSettings.provider
    @State private var openAIAPIKey = KeyboardSettings.openAIAPIKey
    @State private var openAIModel = KeyboardSettings.openAIModel
    @State private var showOpenAIKey = false
    @State private var geminiAPIKey = KeyboardSettings.geminiAPIKey
    @State private var geminiModel = KeyboardSettings.geminiModel
    @State private var showAPIKey = false
    @State private var availableModels: [GeminiModelOption] = []
    @State private var loadingModels = false
    @State private var modelError = ""
    @State private var cloudEnabled = KeyboardSettings.allowCloudAI
    @State private var phrases = KeyboardSettings.savedPhrases
    @State private var phraseDraft = ""
    @State private var telexEnabled = KeyboardSettings.telexEnabled
    @State private var emojiEnabled = KeyboardSettings.emojiEnabled
    @State private var demoMessage = "Bạn gửi báo giá cho mình được không?"
    @State private var suggestions: [ReplySuggestion] = []
    @State private var feedback = ""
    @State private var loading = false
    @State private var keyboardDiagnosis = "Chạm Kiểm tra để xem tình trạng Keyboard Extension."

    var body: some View {
        NavigationStack {
            Form {
                Section("Kích hoạt bàn phím") {
                    Text("Cài đặt → Cài đặt chung → Bàn phím → Bàn phím → Thêm bàn phím mới → ViePN AI Keyboard.")
                    Text("Để sử dụng AI qua mạng, bật Cho phép truy cập đầy đủ cho ViePN AI Keyboard. Chỉ bật nếu bạn tin tưởng ứng dụng.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("Chẩn đoán Keyboard Extension") {
                    Text(keyboardDiagnosis).font(.footnote).textSelection(.enabled)
                    Button("Kiểm tra bàn phím đã được nhúng") {
                        keyboardDiagnosis = diagnoseKeyboard()
                    }
                    Button("Sao chép kết quả chẩn đoán") {
                        UIPasteboard.general.string = keyboardDiagnosis
                    }
                }
                Section("Nhà cung cấp AI") {
                    Picker("Dịch vụ AI", selection: $provider) {
                        Text("Google Gemini").tag("gemini")
                        Text("OpenAI").tag("openai")
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: provider) {
                        KeyboardSettings.provider = $0
                        feedback = ""
                    }
                    Toggle("Cho phép gửi nội dung tôi chọn đến AI", isOn: $cloudEnabled)
                        .onChange(of: cloudEnabled) { KeyboardSettings.allowCloudAI = $0 }
                }
                if provider == "gemini" {
                    Section("Gemini API - Nhập khóa trực tiếp") {
                    HStack {
                        Group {
                            if showAPIKey {
                                TextField("Nhập Gemini API Key", text: $geminiAPIKey)
                            } else {
                                SecureField("Nhập Gemini API Key", text: $geminiAPIKey)
                            }
                        }
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onChange(of: geminiAPIKey) {
                            KeyboardSettings.geminiAPIKey = $0
                        }
                        Button {
                            showAPIKey.toggle()
                        } label: {
                            Image(systemName: showAPIKey ? "eye.slash" : "eye")
                        }
                        .accessibilityLabel(showAPIKey ? "Ẩn API Key" : "Hiện API Key")
                    }
                    if availableModels.isEmpty {
                        HStack {
                            Text("Model")
                            Spacer()
                            TextField("gemini-3.8-flash", text: $geminiModel)
                                .multilineTextAlignment(.trailing)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .onChange(of: geminiModel) { KeyboardSettings.geminiModel = $0 }
                        }
                    } else {
                        Picker("Chọn Gemini model", selection: $geminiModel) {
                            ForEach(availableModels) { model in
                                Text("\(model.name) (\(model.id))").tag(model.id)
                            }
                            if !availableModels.contains(where: { $0.id == geminiModel }) {
                                Text("Đang chọn: \(geminiModel)").tag(geminiModel)
                            }
                        }
                        .onChange(of: geminiModel) { KeyboardSettings.geminiModel = $0 }
                    }
                    Button(loadingModels ? "Đang tải model…" : "Lấy danh sách model mới nhất") {
                        loadingModels = true
                        modelError = ""
                        Task {
                            do {
                                availableModels = try await GeminiModelCatalog.fetch(apiKey: geminiAPIKey)
                                if availableModels.isEmpty {
                                    modelError = "API Key này không có model hỗ trợ generateContent."
                                } else if !availableModels.contains(where: { $0.id == geminiModel }) {
                                    geminiModel = availableModels[0].id
                                    KeyboardSettings.geminiModel = geminiModel
                                }
                            } catch {
                                modelError = error.localizedDescription
                            }
                            loadingModels = false
                        }
                    }
                    .disabled(loadingModels || geminiAPIKey.isEmpty)
                    if !modelError.isEmpty {
                        Text(modelError).font(.footnote).foregroundStyle(.red)
                    }
                    Button(loading ? "Đang kiểm tra…" : "Kiểm tra Gemini API") {
                        loading = true
                        Task {
                            do {
                                let test = try await AIService.reply(to: "Xin chào, bạn có khỏe không?")
                                feedback = "✅ Gemini hoạt động: nhận được \\(test.count) gợi ý."
                            } catch {
                                feedback = "❌ " + error.localizedDescription
                            }
                            loading = false
                        }
                    }
                    .disabled(loading || !cloudEnabled || geminiAPIKey.isEmpty)
                    Button("Xóa API Key", role: .destructive) {
                        geminiAPIKey = ""
                        KeyboardSettings.geminiAPIKey = ""
                        feedback = "Đã xóa khóa API khỏi cấu hình ứng dụng."
                    }
                    Text("Khóa được lưu trong vùng dữ liệu chia sẻ App Group để bàn phím có thể sử dụng; chưa được bảo vệ bằng Keychain. Chỉ nhập khóa cá nhân có giới hạn quota, không chia sẻ IPA chứa dữ liệu đã cấu hình. Khi bấm AI, nội dung sẽ gửi trực tiếp tới Google Gemini.")
                        .font(.footnote).foregroundStyle(.secondary)
                    if !feedback.isEmpty {
                        Text(feedback).font(.footnote).textSelection(.enabled)
                    }
                }
                }
                if provider == "openai" {
                    Section("OpenAI API - Nhập khóa trực tiếp") {
                        HStack {
                            Group {
                                if showOpenAIKey {
                                    TextField("Nhập OpenAI API Key", text: $openAIAPIKey)
                                } else {
                                    SecureField("Nhập OpenAI API Key", text: $openAIAPIKey)
                                }
                            }
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .onChange(of: openAIAPIKey) { KeyboardSettings.openAIAPIKey = $0 }
                            Button {
                                showOpenAIKey.toggle()
                            } label: {
                                Image(systemName: showOpenAIKey ? "eye.slash" : "eye")
                            }
                            .accessibilityLabel(showOpenAIKey ? "Ẩn API Key" : "Hiện API Key")
                        }
                        HStack {
                            Text("Model OpenAI")
                            Spacer()
                            TextField("gpt-4o-mini", text: $openAIModel)
                                .multilineTextAlignment(.trailing)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .onChange(of: openAIModel) { KeyboardSettings.openAIModel = $0 }
                        }
                        Button(loading ? "Đang kiểm tra…" : "Kiểm tra OpenAI API") {
                            loading = true
                            Task {
                                do {
                                    let result = try await AIService.reply(to: "Xin chào!")
                                    feedback = "OpenAI hoạt động: nhận được \\(result.count) gợi ý."
                                } catch {
                                    feedback = error.localizedDescription
                                }
                                loading = false
                            }
                        }
                        .disabled(loading || !cloudEnabled || openAIAPIKey.isEmpty)
                        Button("Xóa OpenAI API Key", role: .destructive) {
                            openAIAPIKey = ""
                            KeyboardSettings.openAIAPIKey = ""
                            feedback = "Đã xóa OpenAI API Key."
                        }
                        Text("Chỉ các model hỗ trợ Chat Completions và JSON mode mới dùng được. API Key được lưu vào dữ liệu App Group để bàn phím truy cập, chưa được bảo vệ bằng Keychain. Chỉ sử dụng khóa cá nhân có giới hạn chi tiêu.")
                            .font(.footnote).foregroundStyle(.secondary)
                        if !feedback.isEmpty {
                            Text(feedback).font(.footnote).textSelection(.enabled)
                        }
                    }
                }
                Section("Thử câu trả lời") {
                    TextEditor(text: $demoMessage).frame(minHeight: 65)
                    HStack {
                        Button("Offline") { suggestions = OfflineReplyEngine.suggest(for: demoMessage); feedback = "" }
                        Spacer()
                        Button(loading ? "Đang tải…" : "AI Online") {
                            loading = true
                            Task {
                                do { suggestions = try await AIService.reply(to: demoMessage); feedback = "" }
                                catch { feedback = error.localizedDescription }
                                loading = false
                            }
                        }.disabled(loading || !cloudEnabled)
                    }
                    ForEach(suggestions) { item in
                        Button {
                            UIPasteboard.general.string = item.text
                            feedback = "Đã sao chép câu trả lời."
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.tone).font(.caption).bold()
                                Text(item.text)
                            }
                        }.buttonStyle(.plain)
                    }
                    if !feedback.isEmpty { Text(feedback).font(.footnote) }
                }
                Section("Cá nhân hóa AI") {
                    Toggle("Emoji thông minh theo ngữ cảnh", isOn: $emojiEnabled)
                        .onChange(of: emojiEnabled) { KeyboardSettings.emojiEnabled = $0 }
                    Text("Chỉ thêm emoji khi phù hợp với cảm xúc của câu trả lời. Không tự thêm trong tình huống nghiêm túc hoặc trang trọng.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("Gõ tiếng Việt") {
                    Toggle("Tự động gõ Telex", isOn: $telexEnabled)
                        .onChange(of: telexEnabled) { KeyboardSettings.telexEnabled = $0 }
                    Text("Hỗ trợ aa → â, aw → ă, ee → ê, oo → ô, ow → ơ, uw → ư, dd → đ và dấu s/f/r/x/j. Khi tắt, bàn phím nhập ký tự bình thường.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("Mẫu câu nhanh") {
                    ForEach(phrases, id: \.self) { phrase in
                        Text(phrase).textSelection(.enabled)
                    }.onDelete { indexes in
                        phrases.remove(atOffsets: indexes)
                        KeyboardSettings.savedPhrases = phrases
                    }
                    HStack {
                        TextField("Thêm mẫu câu", text: $phraseDraft)
                        Button("Thêm") {
                            let value = phraseDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !value.isEmpty {
                                phrases.append(String(value.prefix(500)))
                                KeyboardSettings.savedPhrases = phrases
                                phraseDraft = ""
                            }
                        }.disabled(phraseDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                Section("Quyền riêng tư") {
                    Text("Không tự thu thập nội dung các cuộc trò chuyện. Clipboard chỉ được đọc khi bạn chủ động chạm nút Dán/Phân tích. iOS có thể hiển thị lời nhắc cấp quyền dán.")
                }
            }
            .navigationTitle("ViePN AI Keyboard")
        }
    }
    private func diagnoseKeyboard() -> String {
        guard let plugins = Bundle.main.builtInPlugInsURL else {
            return "KHÔNG TÌM THẤY thư mục PlugIns trong ứng dụng. IPA thiếu extension."
        }
        let extensionURL = plugins.appendingPathComponent("ViePNKeyboardExtension.appex")
        guard FileManager.default.fileExists(atPath: extensionURL.path) else {
            let names = (try? FileManager.default.contentsOfDirectory(atPath: plugins.path)) ?? []
            return "THIẾU ViePNKeyboardExtension.appex. Các mục trong PlugIns: " + names.joined(separator: ", ")
        }
        guard let bundle = Bundle(url: extensionURL) else {
            return "Có .appex nhưng không đọc được bundle. Kiểm tra đóng gói IPA."
        }
        let point = (bundle.object(forInfoDictionaryKey: "NSExtension") as? [String: Any])?["NSExtensionPointIdentifier"] as? String ?? "(thiếu)"
        let principal = (bundle.object(forInfoDictionaryKey: "NSExtension") as? [String: Any])?["NSExtensionPrincipalClass"] as? String ?? "(thiếu)"
        let identifier = bundle.bundleIdentifier ?? "(thiếu)"
        let executable = bundle.executableURL.map { FileManager.default.fileExists(atPath: $0.path) } ?? false
        let valid = point == "com.apple.keyboard-service" && executable && principal.contains("KeyboardViewController")
        return """
        Trạng thái bundle: \(valid ? "HỢP LỆ VỀ CẤU TRÚC" : "CẤU TRÚC KHÔNG HỢP LỆ")
        Extension: \(identifier)
        Extension Point: \(point)
        Principal Class: \(principal)
        File thực thi: \(executable ? "Có" : "Thiếu")
        Lưu ý: Kiểm tra này KHÔNG xác nhận chữ ký Sideloadly hoặc việc iOS đã đăng ký bàn phím.
        """
    }
}
