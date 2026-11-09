import Foundation

struct AIReplyRequest: Encodable {
    let message: String
    let language: String
    let tones: [String]
}
struct AIReplyResponse: Decodable {
    let replies: [AIReplyItem]
}
struct AIReplyItem: Decodable {
    let tone: String
    let text: String
}
enum AIServiceError: LocalizedError {
    case missingConsent, invalidURL, invalidResponse
    var errorDescription: String? {
        switch self {
        case .missingConsent: return "Chưa cho phép gửi nội dung đến AI."
        case .invalidURL: return "Chưa thiết lập địa chỉ API HTTPS hợp lệ."
        case .invalidResponse: return "Máy chủ AI trả dữ liệu không hợp lệ."
        }
    }
}
enum AIService {
    static func reply(to message: String) async throws -> [ReplySuggestion] {
        guard KeyboardSettings.allowCloudAI else { throw AIServiceError.missingConsent }
        guard let url = URL(string: KeyboardSettings.apiURL), url.scheme == "https",
              let host = url.host, !host.isEmpty, url.user == nil, url.password == nil
        else { throw AIServiceError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 18
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(AIReplyRequest(
            message: String(message.prefix(3000)), language: "vi",
            tones: ["Lịch sự", "Ngắn gọn", "Chuyên nghiệp"]))
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode),
              data.count < 100_000 else { throw AIServiceError.invalidResponse }
        let items = try JSONDecoder().decode(AIReplyResponse.self, from: data).replies
        return Array(items.prefix(5)).compactMap {
            let value = $0.text.trimmingCharacters(in: .whitespacesAndNewlines)
            return value.isEmpty ? nil : ReplySuggestion(tone: $0.tone, text: String(value.prefix(1500)))
        }
    }
}
