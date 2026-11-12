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
        let candidates = PersonaStore.headerCandidates(boxes)
        for candidate in candidates {
            let title = candidate.text.trimmingCharacters(in: .whitespacesAndNewlines)
            let normalized = PersonaStore.normalizedName(title)
            guard normalized.count >= 2 else { continue }
            let ids = Set(all.filter {
                PersonaStore.normalizedName($0.headerTitle)
                    == PersonaStore.normalizedScreenshotTitle(title)
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
    /// Use the saved/contact name when possible; otherwise show a likely
    /// header for user editing. OCR keeps alternative candidates with their
    /// normalized coordinates. Never match arbitrary message-body text.
    static func extract(from data: Data, preferredName: String = "") async throws
        -> (title: String, png: Data)? {
        guard let image = UIImage(data: data), let cgImage = image.cgImage else {
            return nil
        }
        return try await Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["vi-VN", "en-US"]
            request.usesLanguageCorrection = false
            request.minimumTextHeight = 0.006
            try VNImageRequestHandler(cgImage: cgImage).perform([request])
            let recognized = (request.results ?? []).flatMap { observation
                -> [(text: String, box: CGRect)] in
                observation.topCandidates(3).map {
                    (text: $0.string, box: observation.boundingBox)
                }
            }
            let observed = recognized.map {
                PersonaStore.ScreenshotTextBox(
                    text: $0.text, midX: Double($0.box.midX),
                    midY: Double($0.box.midY))
            }
            let navigation = PersonaStore.headerCandidates(observed)
            let expected = PersonaStore.normalizedName(preferredName)
            // A known saved name is safer than guessing which of several
            // recognized lines is a person's name.
            let chosen = navigation.first {
                !expected.isEmpty
                    && PersonaStore.normalizedScreenshotTitle($0.text) == expected
            } ?? navigation.first
            guard let selected = chosen,
                  let nameBox = recognized.first(where: {
                      $0.text == selected.text
                          && abs(Double($0.box.midY) - selected.midY) < 0.002
                  })?.box else { return nil }
            let title = selected.text.trimmingCharacters(
                in: .whitespacesAndNewlines)
            let minX = max(0, nameBox.minX - 0.035)
            let maxX = min(1, nameBox.maxX + 0.035)
            let minY = max(0, 1 - nameBox.maxY - 0.018)
            let maxY = min(1, 1 - nameBox.minY + 0.018)
            let crop = CGRect(x: minX * CGFloat(cgImage.width),
                              y: minY * CGFloat(cgImage.height),
                              width: (maxX - minX) * CGFloat(cgImage.width),
                              height: (maxY - minY) * CGFloat(cgImage.height)).integral
            guard crop.width >= 3, crop.height >= 3,
                  let cropped = cgImage.cropping(to: crop) else { return nil }
            let aspect = CGFloat(cropped.height) / CGFloat(cropped.width)
            let target = CGSize(width: 480, height: 480 * aspect)
            let renderer = UIGraphicsImageRenderer(size: target)
            let png = renderer.pngData { _ in
                UIImage(cgImage: cropped).draw(
                    in: CGRect(origin: .zero, size: target))
            }
            guard png.count < 300_000 else { return nil }
            return (title, png)
        }.value
    }

}
