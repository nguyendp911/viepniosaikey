import Foundation

/// All saved conversation notes are user-controlled and stay on the device.
/// No automatic monitoring or copying of conversations in other applications.
struct ConversationNote: Codable, Identifiable, Equatable {
    var id: String
    var personaID: String
    var text: String
    var createdAt: Date
}

enum ConversationMemory {
    private static let key = "viepnaikey.conversationNotes.v1"
    private static var defaults: UserDefaults { KeyboardSettings.defaults }

    #if os(iOS)
    private static var protectedURL: URL? {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: KeyboardSettings.groupID)?
            .appendingPathComponent("conversation-notes-v2.json")
    }
    #endif

    static var notes: [ConversationNote] {
        get {
            #if os(iOS)
            if let url = protectedURL {
                if FileManager.default.fileExists(atPath: url.path) {
                    guard let bytes = try? Data(contentsOf: url),
                          let saved = try? JSONDecoder().decode(
                            [ConversationNote].self, from: bytes)
                    else { return [] }
                    return saved
                }
                if let bytes = defaults.data(forKey: key),
                   let saved = try? JSONDecoder().decode(
                    [ConversationNote].self, from: bytes) {
                    notes = saved
                    return saved
                }
                return []
            }
            #endif
            guard let bytes = defaults.data(forKey: key),
                  let saved = try? JSONDecoder().decode(
                    [ConversationNote].self, from: bytes)
            else { return [] }
            return saved
        }
        set {
            let clipped = Array(newValue.prefix(100))
            guard let bytes = try? JSONEncoder().encode(clipped) else { return }
            #if os(iOS)
            if let url = protectedURL {
                do {
                    try bytes.write(to: url, options: [
                        .atomic, .completeFileProtectionUntilFirstUserAuthentication
                    ])
                    try FileManager.default.setAttributes([
                        .protectionKey:
                            FileProtectionType.completeUntilFirstUserAuthentication
                    ], ofItemAtPath: url.path)
                    defaults.removeObject(forKey: key)
                } catch {
                    // Do not downgrade back to unprotected preferences.
                }
                return
            }
            #else
            defaults.set(bytes, forKey: key)
            #endif
        }
    }

    static func save(_ text: String, for personaID: String) {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty, !personaID.isEmpty else { return }
        var items = notes
        items.insert(ConversationNote(id: UUID().uuidString, personaID: personaID,
                                      text: String(cleaned.prefix(500)), createdAt: Date()), at: 0)
        notes = items
    }

    /// A note is acknowledged only after verifying it survived persistence.
    /// Returns false if the shared protected container is unavailable.
    @discardableResult
    static func saveVerified(_ text: String, for personaID: String) -> Bool {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty, !personaID.isEmpty else { return false }
        let id = UUID().uuidString
        var items = notes
        items.insert(ConversationNote(id: id, personaID: personaID,
            text: String(cleaned.prefix(500)), createdAt: Date()), at: 0)
        notes = items
        return notes.contains(where: { $0.id == id && $0.personaID == personaID })
    }

    static func forActivePersona() -> [ConversationNote] {
        guard !PersonaStore.activeID.isEmpty else { return [] }
        return notes.filter { $0.personaID == PersonaStore.activeID }
    }

    static func prompt() -> String {
        let memories = forActivePersona().prefix(8)
        guard !memories.isEmpty else { return "" }
        return """
        USER-APPROVED NOTES FOR THIS CONTACT (not verified facts):
        \(memories.map { "• " + $0.text }.joined(separator: "\n"))
        Use only if relevant. Do not assume notes are always current.
        """
    }
}
