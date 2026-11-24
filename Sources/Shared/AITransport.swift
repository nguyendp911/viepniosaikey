import Foundation

/// Shared cloud transport. Ephemeral sessions do not persist HTTP cache,
/// cookies or credentials; all callers retain their provider-specific parsing.
enum AITransport {
    private static let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.urlCache = nil
        config.httpCookieStorage = nil
        config.urlCredentialStorage = nil
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 45
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: config)
    }()

    static func data(for request: URLRequest, maximumBytes: Int = 200_000) async throws -> (Data, URLResponse) {
        try Task.checkCancellation()
        let (data, response) = try await session.data(for: request)
        try Task.checkCancellation()
        guard data.count <= maximumBytes else { throw AIServiceError.invalidResponse }
        return (data, response)
    }
}
