import Vision
import UIKit
import ImageIO

struct OCRChatLine: Identifiable {
    let id = UUID()
    let text: String
    var speaker: String = "unknown"
}
enum ScreenshotStudioOCR {
    static func read(_ data: Data) async throws -> [OCRChatLine] {
        try await Task.detached(priority: .userInitiated) {
            guard data.count <= 30_000_000,
                  let source = CGImageSourceCreateWithData(data as CFData, nil),
                  let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceCreateThumbnailWithTransform: true,
                    kCGImageSourceThumbnailMaxPixelSize: 2200
                  ] as CFDictionary) else { throw AIServiceError.invalidResponse }
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["vi-VN", "en-US"]
            request.usesLanguageCorrection = true
            try VNImageRequestHandler(cgImage: image).perform([request])
            return (request.results ?? []).sorted {
                let a = Int($0.boundingBox.midY * 100), b = Int($1.boundingBox.midY * 100)
                return a == b ? $0.boundingBox.minX < $1.boundingBox.minX : a > b
            }.prefix(100).compactMap { row in
                guard let text = row.topCandidates(1).first?.string, !text.isEmpty else { return nil }
                // Never assign speakers based on alignment alone.
                return OCRChatLine(text: text)
            }
        }.value
    }
}
