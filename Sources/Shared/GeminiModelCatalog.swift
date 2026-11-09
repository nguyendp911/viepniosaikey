import Foundation

struct GeminiModelOption: Identifiable, Hashable {
    let id: String
    let name: String
}

private struct GeminiModelList: Decodable {
    struct Item: Decodable {
        let name: String
        let displayName: String?
        let supportedGenerationMethods: [String]?
    }
    let models: [Item]?
    let nextPageToken: String?
}

enum GeminiModelCatalog {
    static func fetch(apiKey: String) async throws -> [GeminiModelOption] {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AIServiceError.missingKey
        }
        var found: [GeminiModelOption] = []
        var cursor: String?
        for _ in 0..<10 {
            var components = URLComponents(string: "https://generativelanguage.googleapis.com/v1beta/models")!
            var query = [URLQueryItem(name: "pageSize", value: "100")]
            if let cursor, !cursor.isEmpty {
                query.append(URLQueryItem(name: "pageToken", value: cursor))
            }
            components.queryItems = query
            var req = URLRequest(url: components.url!)
            req.httpMethod = "GET"
            req.timeoutInterval = 20
            req.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
            let (data, response) = try await URLSession.shared.data(for: req)
            guard let http = response as? HTTPURLResponse else { throw AIServiceError.invalidResponse }
            guard (200...299).contains(http.statusCode) else {
                throw AIServiceError.provider(http.statusCode, "Không tải được danh sách model. Kiểm tra API Key.")
            }
            guard data.count < 1_000_000 else { throw AIServiceError.invalidResponse }
            let catalog: GeminiModelList
            do {
                catalog = try JSONDecoder().decode(GeminiModelList.self, from: data)
            } catch {
                throw AIServiceError.malformedResponse("Không đọc được danh sách model từ Google. Hãy tải lại.")
            }
            for model in catalog.models ?? [] {
                guard model.name.hasPrefix("models/gemini-"),
                      model.supportedGenerationMethods?.contains("generateContent") == true
                else { continue }
                let id = String(model.name.dropFirst("models/".count))
                found.append(.init(id: id, name: model.displayName ?? id))
            }
            cursor = catalog.nextPageToken
            if cursor == nil || cursor == "" { break }
        }
        let unique = Dictionary(grouping: found, by: \.id).compactMap { $0.value.first }
        return unique.sorted {
            let a = $0.id == "gemini-3.8-flash" ? "0" : $0.id
            let b = $1.id == "gemini-3.8-flash" ? "0" : $1.id
            return a < b
        }
    }
}
