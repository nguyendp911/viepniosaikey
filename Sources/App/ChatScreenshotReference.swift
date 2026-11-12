import Foundation
import UIKit
import Vision

/// An opt-in contact reference. We retain ONLY the small navigation-header
/// image, never the screenshot's chat bubbles or the device status bar.
/// Matching uses exact OCR title equality rather than face recognition or
/// surveillance of another app's screen.
enum ChatScreenshotReference {
    struct Reference: Codable {
        let personaID: String
        let headerTitle: String
        let headerPNG: Data
    }

    private static var storeURL: URL? {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: KeyboardSettings.groupID)?
            .appendingPathComponent("contact-header-references-v1.json")
    }

    static var all: [Reference] {
        guard let url = storeURL, let data = try? Data(contentsOf: url),
              let refs = try? JSONDecoder().decode([Reference].self, from: data)
        else { return [] }
        return refs
    }

    @discardableResult
    private static func persist(_ records: [Reference]) -> Bool {
        guard let url = storeURL,
              let bytes = try? JSONEncoder().encode(records) else { return false }
        do {
            try bytes.write(to: url, options: [
                .atomic, .completeFileProtectionUntilFirstUserAuthentication
            ])
            return true
        } catch {
            return false
        }
    }

    static func save(personaID: String, title: String, headerPNG: Data) -> Bool {
        guard PersonaStore.all.contains(where: { $0.id == personaID }),
              !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              title.count <= 60, !headerPNG.isEmpty,
              headerPNG.count < 300_000 else { return false }
        var refs = all.filter { $0.personaID != personaID }
        refs.append(Reference(personaID: personaID, headerTitle: title,
                              headerPNG: headerPNG))
        guard persist(refs) else { return false }
        return all.contains { $0.personaID == personaID
            && $0.headerTitle == title }
    }

    static func remove(personaID: String) -> Bool {
        guard persist(all.filter({ $0.personaID != personaID })) else { return false }
        return !all.contains { $0.personaID == personaID }
    }

    /// OCR text from a newly user-supplied screenshot is compared to the
    /// enrolled header for each profile. Duplicates are returned for user
    /// disambiguation; nothing is guessed from the message-body content.
    static func match(_ boxes: [PersonaStore.ScreenshotTextBox])
        -> PersonaStore.ScreenshotMatch? {
        let candidates = boxes.filter {
            $0.midY >= 0.77 && $0.midY <= 0.96
                && $0.midX >= 0.23 && $0.midX <= 0.77
        }
        for candidate in candidates {
            let title = candidate.text.trimmingCharacters(in: .whitespacesAndNewlines)
            let normalized = PersonaStore.normalizedName(title)
            guard normalized.count >= 2 else { continue }
            let ids = Set(all.filter {
                PersonaStore.normalizedName($0.headerTitle) == normalized
            }.map(\.personaID))
            let matches = PersonaStore.all.filter { ids.contains($0.id) }
            if !matches.isEmpty {
                return PersonaStore.ScreenshotMatch(
                    recognizedTitle: title, matches: matches)
            }
        }
        return nil
    }

    /// Vision runs only in the containing iOS app, on an image selected by
    /// the user. Returns a detected header and a cropped reference image.
    static func extract(from data: Data) async throws -> (title: String, png: Data)? {
        guard let image = UIImage(data: data), let cgImage = image.cgImage else {
            return nil
        }
        return try await Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["vi-VN", "en-US"]
            request.usesLanguageCorrection = true
            try VNImageRequestHandler(cgImage: cgImage).perform([request])
            let header = (request.results ?? []).compactMap {
                observation -> (String, Double, Double)? in
                guard let text = observation.topCandidates(1).first?.string else {
                    return nil
                }
                return (text, Double(observation.boundingBox.midX),
                        Double(observation.boundingBox.midY))
            }.filter { $0.2 >= 0.77 && $0.2 <= 0.96
                && $0.1 >= 0.23 && $0.1 <= 0.77 }
            guard let title = header.first?.0.trimmingCharacters(
                in: .whitespacesAndNewlines),
                  title.count >= 2 && title.count <= 60 else { return nil }
            // Keep just the app's top conversation header; not message text.
            let crop = CGRect(x: 0, y: CGFloat(cgImage.height) * 0.055,
                              width: CGFloat(cgImage.width),
                              height: CGFloat(cgImage.height) * 0.185).integral
            guard let cropped = cgImage.cropping(to: crop),
                  let png = UIImage(cgImage: cropped).pngData() else { return nil }
            return (title, png)
        }.value
    }
}
