import Foundation

enum PersonalDictionary {
    private static let key = "viepnaikey.customDictionary.v1"
    static var words: [String] {
        get { KeyboardSettings.defaults.stringArray(forKey: key) ?? [] }
        set { KeyboardSettings.defaults.set(normalize(newValue.joined(separator: "\n")), forKey: key) }
    }
    static func normalize(_ source: String) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for line in source.components(separatedBy: .newlines) {
            let word = line.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().precomposedStringWithCanonicalMapping
            guard word.count >= 2, word.count <= 24, word.allSatisfy(\.isLetter), seen.insert(word).inserted else { continue }
            result.append(word)
            if result.count == 500 { break }
        }
        return result
    }
    static func merge(with learned: [String: Int]) -> [String: Int] {
        var merged = learned
        for word in words { merged[word] = max(merged[word] ?? 0, 1) }
        return merged
    }
}
