import SwiftUI
import UIKit

struct ContentView: View {
    @State private var apiURL = KeyboardSettings.apiURL
    @State private var cloudEnabled = KeyboardSettings.allowCloudAI
    @State private var phrases = KeyboardSettings.savedPhrases
    @State private var phraseDraft = ""
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
                Section("Chế độ AI kết hợp") {
                    Toggle("Cho phép gửi nội dung tôi chọn đến AI", isOn: $cloudEnabled)
                        .onChange(of: cloudEnabled) { KeyboardSettings.allowCloudAI = $0 }
                    TextField("https://your-server.example/reply", text: $apiURL)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                        .keyboardType(.URL)
                        .onChange(of: apiURL) { KeyboardSettings.apiURL = $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    Text("Offline luôn sẵn sàng. Chỉ khi bấm nút AI Online, nội dung đã chọn mới được gửi tới URL trên. Không đưa khóa API nhà cung cấp vào ứng dụng.")
                        .font(.footnote).foregroundStyle(.secondary)
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
