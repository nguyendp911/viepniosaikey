import Foundation

enum PersonalDictionary {
    private static let key = "viepnaikey.customDictionary.v1"
    static var words: [String] {
        get { KeyboardSettings.defaults.stringArray(forKey: key) ?? [] }
        set { KeyboardSettings.defaults.set(normalize(newValue.joined(separator: "\n")), forKey: key) }
    }
    static func normalize(_ source: String) -> [String] {
        var seen = Set<String>()
        return Array(source.components(separatedBy: .newlines).lazy.map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().precomposedStringWithCanonicalMapping
        }.filter { $0.count >= 2 && $0.count <= 24 && $0.allSatisfy(\.isLetter) && seen.insert($0).inserted }.prefix(500))
    }
    static func merge(with learned: [String: Int]) -> [String: Int] {
        var merged = learned
        for word in words { merged[word] = max(merged[word] ?? 0, 1) }
        return merged
    }
}
