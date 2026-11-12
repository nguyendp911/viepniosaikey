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

    /// Explanation about how a user-supplied screenshot matched a saved
    /// conversation. On-device Vision image features are not face recognition
    /// or a claim of the person's real-world identity.
    struct Recognition {
        enum Method {
            case titleOCR
            case imageReference
        }
        let title: String
        let matches: [RecipientPersona]
        let method: Method
        let visualDistance: Float?
        var uniqueMatch: RecipientPersona? {
            matches.count == 1 ? matches.first : nil
        }
        var mayAutoSelect: Bool {
            method == .titleOCR && matches.count == 1
        }
    }

    private static func imageFeature(_ data: Data)
        -> VNFeaturePrintObservation? {
        guard let cgImage = UIImage(data: data)?.cgImage else { return nil }
        let request = VNGenerateImageFeaturePrintRequest()
        do {
            try VNImageRequestHandler(cgImage: cgImage, options: [:])
                .perform([request])
            return request.results?.first
        } catch {
            return nil
        }
    }

    /// Compare only OCR-confirmed navigation names or a deliberately saved
    /// cropped title image, never chat bubbles, faces or full-screen images.
    /// The visual result MUST be confirmed: similar-looking names and UI can
    /// have a small feature distance without identifying the same person.
    /// Resolve all OCR title matches before returning. A match in a later
    /// candidate must not be ignored because an earlier OCR line resembles
    /// another saved contact. Conflicts are explicitly ambiguous.
    static func textMatches(
        _ observations: [(text: String, midY: Double)],
        profiles: [RecipientPersona],
        references: [Reference]
    ) -> [RecipientPersona] {
        var ids = Set<String>()
        for observation in observations where observation.midY >= 0.77
            && observation.midY <= 0.967 {
            let title = PersonaStore.normalizedScreenshotTitle(observation.text)
            guard title.count >= 2,
                  PersonaStore.isPlausibleHeaderTitle(observation.text) else { continue }
            for person in profiles
                where PersonaStore.normalizedName(person.name) == title {
                ids.insert(person.id)
            }
            for ref in references
                where PersonaStore.normalizedName(ref.headerTitle) == title
                && profiles.contains(where: { $0.id == ref.personaID }) {
                ids.insert(ref.personaID)
            }
        }
        return profiles.filter { ids.contains($0.id) }
    }

    static func recognize(_ scan: ScanResult) async -> Recognition? {
        let references = all
        let profiles = PersonaStore.all
        // Only OCR candidates in the actual navigation-title band may
        // identify a person. Chat bubbles below it are not evidence.
        let headerItems = scan.candidates.filter {
            $0.midY >= 0.77 && $0.midY <= 0.967
        }
        let matches = textMatches(
            headerItems.map { (text: $0.title, midY: $0.midY) },
            profiles: profiles, references: references)
        if !matches.isEmpty {
            let title = headerItems.first(where: { item in
                matches.contains {
                    PersonaStore.normalizedName($0.name)
                        == PersonaStore.normalizedScreenshotTitle(item.title)
                } || references.contains { ref in
                    matches.contains(where: { $0.id == ref.personaID })
                        && PersonaStore.normalizedName(ref.headerTitle)
                            == PersonaStore.normalizedScreenshotTitle(item.title)
                }
            })?.title ?? "Tiêu đề cuộc trò chuyện"
            return Recognition(title: title, matches: matches,
                               method: .titleOCR, visualDistance: nil)
        }
        // Similar typography, button icons, colors, and cropped regions
        // make Vision feature-print distance unsuitable for identifying a
        // person. Ranking below is ONLY a user-selectable shortlist, never
        // an automatic match and never proof of the recipient.
        guard !references.isEmpty, !headerItems.isEmpty else { return nil }
        return await Task.detached(priority: .userInitiated) {
            var referencePrints: [(id: String, feature: VNFeaturePrintObservation)] = []
            for record in references {
                if let feature = imageFeature(record.headerPNG) {
                    referencePrints.append((record.personaID, feature))
                }
            }
            var results: [(id: String, title: String, distance: Float)] = []
            for candidate in headerItems.prefix(8) {
                guard let feature = imageFeature(candidate.png) else { continue }
                for stored in referencePrints {
                    var distance: Float = .greatestFiniteMagnitude
                    guard (try? feature.computeDistance(
                        &distance, to: stored.feature)) != nil,
                        distance.isFinite else { continue }
                    results.append((stored.id, candidate.title, distance))
                }
            }
            let bestByProfile = Dictionary(grouping: results, by: \.id)
                .compactMap { _, items in
                    items.min { $0.distance < $1.distance }
                }.sorted { $0.distance < $1.distance }
            // Suppress weak visual matches and single-profile bias. A single
            // reference can be shown for manual confirmation, but an image
            // alone must never activate a persona.
            let shortlist = Array(bestByProfile.filter {
                $0.distance < 0.20
            }.prefix(3))
            guard !shortlist.isEmpty else { return nil }
            let suggestions = shortlist.compactMap { result in
                profiles.first(where: { $0.id == result.id })
            }
            guard !suggestions.isEmpty else { return nil }
            return Recognition(title: shortlist[0].title,
                               matches: suggestions,
                               method: .imageReference,
                               visualDistance: shortlist[0].distance)
        }.value
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

    /// Normalize UIImage orientation before running Vision or cropping.
    /// Screenshots from Photos may have an orientation transform, and using
    /// raw cgImage pixels can move the title outside of our expected band.
    private static func uprightImage(_ data: Data) -> UIImage? {
        guard let source = UIImage(data: data) else { return nil }
        let targetSize = source.size
        guard targetSize.width >= 60 && targetSize.height >= 60 else { return nil }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return UIImage(data: renderer.pngData { _ in
            source.draw(in: CGRect(origin: .zero, size: targetSize))
        })
    }

    struct ScannedTitle {
        let title: String
        let png: Data
        let midY: Double
    }

    struct ScanResult {
        let candidates: [ScannedTitle]
        let totalOCRLines: Int
        let headerPreviewPNG: Data?
    }

    private static func pngCrop(_ box: CGRect, image: CGImage) -> Data? {
        let minX = max(0, box.minX - 0.025)
        let maxX = min(1, box.maxX + 0.025)
        let minY = max(0, 1 - box.maxY - 0.015)
        let maxY = min(1, 1 - box.minY + 0.015)
        let rect = CGRect(x: minX * CGFloat(image.width),
                          y: minY * CGFloat(image.height),
                          width: (maxX - minX) * CGFloat(image.width),
                          height: (maxY - minY) * CGFloat(image.height)).integral
        guard rect.width >= 3 && rect.height >= 3,
              let cropped = image.cropping(to: rect) else { return nil }
        let width: CGFloat = min(420, CGFloat(cropped.width))
        let height = width * CGFloat(cropped.height) / CGFloat(cropped.width)
        guard height >= 3 else { return nil }
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        let data = renderer.pngData { _ in
            UIImage(cgImage: cropped).draw(
                in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        return data.count < 300_000 ? data : nil
    }

    /// Manual fallback: user chooses a vertical position of the chat title
    /// from a screenshot provided through PhotosPicker. Only a narrow band is
    /// returned; the complete screenshot is never persisted.
    static func manualHeaderCrop(_ data: Data, topFraction: Double) -> Data? {
        guard let image = uprightImage(data), let cgImage = image.cgImage else {
            return nil
        }
        let top = max(0.035, min(0.34, topFraction))
        let bandHeight = 0.06
        let visionBox = CGRect(x: 0.06,
                               y: 1 - top - bandHeight,
                               width: 0.88, height: bandHeight)
        return pngCrop(visionBox, image: cgImage)
    }

    /// Expose candidate title lines for explicit correction when OCR cannot
    /// confidently identify the header. No screenshot or OCR is uploaded.
    static func scan(_ data: Data, preferredName: String = "") async throws -> ScanResult {
        guard let normalized = uprightImage(data), let cgImage = normalized.cgImage
        else { return ScanResult(candidates: [], totalOCRLines: 0,
                                 headerPreviewPNG: nil) }
        return try await Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["vi-VN", "en-US"]
            request.usesLanguageCorrection = false
            request.minimumTextHeight = 0.004
            try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
            let observations = request.results ?? []
            var entries: [(title: String, box: CGRect)] = []
            var seen = Set<String>()
            func appendText(_ text: String, _ box: CGRect) {
                let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard PersonaStore.isPlausibleHeaderTitle(value),
                      box.midY >= 0.54, box.midY <= 0.975 else { return }
                let key = PersonaStore.normalizedScreenshotTitle(value)
                guard seen.insert(key).inserted else { return }
                entries.append((title: value, box: box))
            }
            for observation in observations {
                for candidate in observation.topCandidates(3) {
                    appendText(candidate.string, observation.boundingBox)
                }
            }
            // Re-run OCR on just the top quarter of the screenshot.
            // In a full Zalo screenshot, the small navigation title may be
            // missed when Vision gives precedence to large chat bubbles.
            let headerFraction: CGFloat = 0.30
            let topRect = CGRect(
                x: 0, y: 0, width: CGFloat(cgImage.width),
                height: CGFloat(cgImage.height) * headerFraction).integral
            if let topImage = cgImage.cropping(to: topRect) {
                let headerRequest = VNRecognizeTextRequest()
                headerRequest.recognitionLevel = .accurate
                headerRequest.recognitionLanguages = ["vi-VN", "en-US"]
                headerRequest.usesLanguageCorrection = false
                headerRequest.minimumTextHeight = 0.005
                try VNImageRequestHandler(cgImage: topImage, options: [:])
                    .perform([headerRequest])
                for observation in headerRequest.results ?? [] {
                    let b = observation.boundingBox
                    let mapped = CGRect(
                        x: b.minX,
                        y: 1 - headerFraction + b.minY * headerFraction,
                        width: b.width, height: b.height * headerFraction)
                    for candidate in observation.topCandidates(3) {
                        appendText(candidate.string, mapped)
                    }
                }
            }
            let expected = PersonaStore.normalizedName(preferredName)
            entries.sort { lhs, rhs in
                let lm = !expected.isEmpty
                    && PersonaStore.normalizedScreenshotTitle(lhs.title) == expected
                let rm = !expected.isEmpty
                    && PersonaStore.normalizedScreenshotTitle(rhs.title) == expected
                if lm != rm { return lm }
                return lhs.box.midY > rhs.box.midY
            }
            let candidates = entries.prefix(15).compactMap { entry
                -> ScannedTitle? in
                guard let png = pngCrop(entry.box, image: cgImage) else { return nil }
                return ScannedTitle(title: entry.title, png: png,
                                    midY: Double(entry.box.midY))
            }
            // Diagnostic preview is transient only; never persist a band
            // that may contain private message contents.
            let band = CGRect(x: 0, y: 0, width: 1, height: 0.23)
            return ScanResult(candidates: candidates,
                              totalOCRLines: observations.count + entries.count,
                              headerPreviewPNG: pngCrop(bandToVisionBox(band),
                                                        image: cgImage))
        }.value
    }

    private static func bandToVisionBox(_ topBand: CGRect) -> CGRect {
        CGRect(x: topBand.minX, y: 1 - topBand.maxY,
               width: topBand.width, height: topBand.height)
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
