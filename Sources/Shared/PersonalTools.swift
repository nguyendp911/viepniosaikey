import Foundation

struct RecipientPersona: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var recipient: String
    var selfAddress: String
    var tone: String
}

enum PersonaStore {
    private static var defaults: UserDefaults { KeyboardSettings.defaults }
    private static let key = "viepnaikey.recipientPersonas"
    private static let activeKey = "viepnaikey.activeRecipientPersona"

    static var all: [RecipientPersona] {
        get {
            guard let data = defaults.data(forKey: key),
                  let parsed = try? JSONDecoder().decode([RecipientPersona].self, from: data)
            else { return [] }
            return parsed
        }
        set {
            let trimmed = Array(newValue.prefix(20)).map {
                RecipientPersona(id: $0.id, name: String($0.name.prefix(36)),
                                 recipient: $0.recipient,
                                 selfAddress: String($0.selfAddress.prefix(30)),
                                 tone: String($0.tone.prefix(80)))
            }
            if let data = try? JSONEncoder().encode(trimmed) {
                defaults.set(data, forKey: key)
            }
        }
    }

    static var activeID: String {
        get { defaults.string(forKey: activeKey) ?? "" }
        set { defaults.set(newValue, forKey: activeKey) }
    }

    static var active: RecipientPersona? {
        all.first { $0.id == activeID }
    }

    static func add(name: String, role: String, selfAddress: String, tone: String) {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty,
              let relation = ReplyRecipient(rawValue: role),
              relation != .automatic else { return }
        var items = all
        let item = RecipientPersona(id: UUID().uuidString, name: clean, recipient: role,
                                    selfAddress: selfAddress, tone: tone)
        items.insert(item, at: 0)
        all = items
        activeID = item.id
        KeyboardSettings.recipientMode = role
    }

    static func select(_ id: String) {
        activeID = id
        if let selected = active {
            KeyboardSettings.recipientMode = selected.recipient
        }
    }

    static func clearSelection() {
        activeID = ""
        KeyboardSettings.recipientMode = "auto"
    }

    /// Personality is a user-provided preference, not evidence that a message
    /// actually came from that person. The user must select a profile manually.
    static var prompt: String {
        guard let person = active else { return "" }
        let role = ReplyRecipient(rawValue: person.recipient)?.title ?? "Tự nhận diện"
        return """
        USER-SELECTED CONVERSATION PROFILE: "\(person.name)", role \(role).
        The user calls themselves "\(person.selfAddress)" in this conversation.
        Desired tone: \(person.tone).
        This selection is not proof of the sender's identity. It only controls
        preferred addressing; do not invent facts, memories or prior messages.
        """
    }
}

enum ClipboardVault {
    private static let key = "viepnaikey.explicitClipboardEntries"
    private static var defaults: UserDefaults { KeyboardSettings.defaults }

    /// Nothing is read or saved automatically. The user must tap "Lưu Clipboard".
    static var items: [String] {
        get { defaults.stringArray(forKey: key) ?? [] }
        set { defaults.set(Array(newValue.prefix(15)), forKey: key) }
    }

    static func saveExplicitly(_ text: String) {
        let value = String(text.prefix(1000)).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        var list = items
        list.removeAll { $0 == value }
        list.insert(value, at: 0)
        items = list
    }

    static func clear() { items = [] }
}
