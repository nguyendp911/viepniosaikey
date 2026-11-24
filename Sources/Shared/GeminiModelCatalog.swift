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
    // Automatic mode uses the key's actual catalog, not an invented model ID.
    static func resolve(_ configured: String, apiKey: String) async throws -> String {
        guard configured.isEmpty || configured == "auto" else { return configured }
        return try await GeminiAutoModelCache.shared.resolve(apiKey: apiKey)
    }

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
            let (data, response) = try await AITransport.data(for: req, maximumBytes: 1_000_000)
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
        return unique.sorted { $0.id < $1.id }
    }
}

private actor GeminiAutoModelCache {
    static let shared = GeminiAutoModelCache()
    private var entry: (key: String, model: String, expiry: Date)?
    func resolve(apiKey: String) async throws -> String {
        if let entry, entry.key == apiKey, entry.expiry > Date() { return entry.model }
        let models = try await GeminiModelCatalog.fetch(apiKey: apiKey)
        let textModels = models.filter { option in
            let name = option.id.lowercased()
            return !["image", "audio", "tts", "live", "embedding", "robotics", "computer-use"].contains { name.contains($0) }
        }
        let stable = textModels.filter { !$0.id.contains("preview") && !$0.id.contains("experimental") && !$0.id.contains("-exp") }
        let pool = stable.isEmpty ? textModels : stable
        guard let model = (pool.filter { $0.id.contains("flash") && !$0.id.contains("lite") }.last ?? pool.last)?.id else {
            throw AIServiceError.invalidModel
        }
        entry = (apiKey, model, Date().addingTimeInterval(600))
        return model
    }
}
