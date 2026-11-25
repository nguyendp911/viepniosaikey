import Foundation

struct PersonalMemory: Codable, Identifiable, Equatable {
    var id = UUID().uuidString
    var personaID: String
    var kind: String
    var title: String
    var detail: String
    var date: Date = Date()
}
enum PersonalMemoryStore {
    static let kinds = ["Sở thích", "Xưng hô", "Kỷ niệm", "Lời hứa", "Sự kiện", "Ghi chú"]
    private static let filename = "personal-intelligence-v1.json"
    #if os(iOS)
    private static var url: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: KeyboardSettings.groupID)?.appendingPathComponent(filename)
    }
    #endif
    private static func load() -> [PersonalMemory] {
        #if os(iOS)
        guard let url, let data = try? Data(contentsOf: url), data.count <= 400_000 else { return [] }
        #else
        guard let data = KeyboardSettings.defaults.data(forKey: filename) else { return [] }
        #endif
        return (try? JSONDecoder().decode([PersonalMemory].self, from: data)) ?? []
    }
    static var all: [PersonalMemory] { KeyboardSettings.privateTypingMode ? [] : load() }
    static func valid(_ item: PersonalMemory) -> Bool {
        kinds.contains(item.kind) && !item.title.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty
            && item.title.count <= 80 && item.detail.count <= 1000
            && MessageSafety.warnings(in:item.title + "\n" + item.detail).isEmpty
    }
    @discardableResult static func save(_ items: [PersonalMemory]) -> Bool {
        guard !KeyboardSettings.privateTypingMode, items.count <= 200, items.allSatisfy(valid),
              let data = try? JSONEncoder().encode(items), data.count <= 400_000 else { return false }
        #if os(iOS)
        guard let url else { return false }
        do { try data.write(to:url,options:[.atomic,.completeFileProtection]); return true } catch { return false }
        #else
        KeyboardSettings.defaults.set(data,forKey:filename); return true
        #endif
    }
    @discardableResult static func clear() -> Bool {
        #if os(iOS)
        guard let url else { return false }
        if !FileManager.default.fileExists(atPath:url.path) { return true }
        do { try FileManager.default.removeItem(at:url); return true } catch { return false }
        #else
        KeyboardSettings.defaults.removeObject(forKey:filename); return true
        #endif
    }
    static func scoped(_ items:[PersonalMemory], personaID:String) -> [PersonalMemory] {
        items.filter { $0.personaID == personaID }.sorted { $0.date > $1.date }
    }
    static func context(_ items:[PersonalMemory], selected:Set<String>, personaID:String) -> String {
        let values = scoped(items,personaID:personaID).filter { selected.contains($0.id) && valid($0) }.prefix(6)
        return String(values.map { "• "+$0.kind+": "+$0.title+" — "+$0.detail }.joined(separator:"\n").prefix(1000))
    }
}
