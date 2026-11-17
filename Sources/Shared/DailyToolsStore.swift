import Foundation

/// The shop catalog. Edited in the app, read by the keyboard. On device only.
enum ShopStore {
    static var profile: ShopProfile {
        get { ShopTools.decode(KeyboardSettings.shopData) }
        set { KeyboardSettings.shopData = ShopTools.encode(newValue) }
    }
}

/// Promises found in conversations. New ones wait for the user's review in the
/// app; only confirmed ones ever remind.
enum CommitmentStore {
    static let maxItems = 80

    static var all: [Commitment] {
        get {
            guard let data = KeyboardSettings.commitmentsData,
                  let list = try? JSONDecoder().decode([Commitment].self, from: data) else { return [] }
            return list
        }
        set {
            let clipped = Array(newValue.prefix(maxItems))
            KeyboardSettings.commitmentsData = try? JSONEncoder().encode(clipped)
        }
    }

    /// Returns how many new ones were saved.
    @discardableResult
    static func addFound(_ found: [CommitmentDetector.Found], profileID: String) -> Int {
        var items = all
        let fresh = CommitmentDetector.newOnes(found, existing: items)
        guard !fresh.isEmpty else { return 0 }
        for item in fresh.reversed() {
            items.insert(Commitment(id: UUID().uuidString, profileID: profileID, mine: item.mine,
                                    text: item.text, due: item.due, confirmed: false, done: false,
                                    created: Date()), at: 0)
        }
        all = items
        return fresh.count
    }

    static func update(_ item: Commitment) {
        var items = all
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
            all = items
        }
    }

    static func remove(id: String) {
        all = all.filter { $0.id != id }
    }

    static var unreviewedCount: Int {
        all.filter { !$0.confirmed && !$0.done }.count
    }
}

/// A fact the AI proposed to remember about a person. It becomes a real note
/// only when the user approves it.
struct MemorySuggestion: Codable, Identifiable, Equatable {
    var id: String
    var personaID: String
    var text: String
    var created: Date
}

enum MemorySuggestionStore {
    static let maxItems = 40

    static var all: [MemorySuggestion] {
        get {
            guard let data = KeyboardSettings.memorySuggestionsData,
                  let list = try? JSONDecoder().decode([MemorySuggestion].self, from: data) else { return [] }
            return list
        }
        set {
            KeyboardSettings.memorySuggestionsData = try? JSONEncoder().encode(Array(newValue.prefix(maxItems)))
        }
    }

    static func suggestions(for personaID: String) -> [MemorySuggestion] {
        all.filter { $0.personaID == personaID }
    }

    /// Returns how many were new (not already a note or a pending suggestion).
    @discardableResult
    static func add(_ facts: [String], for personaID: String) -> Int {
        guard !personaID.isEmpty else { return 0 }
        let notes = ConversationMemory.notes.filter { $0.personaID == personaID }.map { $0.text }
        let pending = suggestions(for: personaID).map { $0.text }
        let fresh = MemoryFacts.fresh(facts, known: notes + pending)
        guard !fresh.isEmpty else { return 0 }
        var items = all
        for fact in fresh.reversed() {
            items.insert(MemorySuggestion(id: UUID().uuidString, personaID: personaID,
                                          text: fact, created: Date()), at: 0)
        }
        all = items
        return fresh.count
    }

    @discardableResult
    static func approve(_ id: String) -> Bool {
        guard let item = all.first(where: { $0.id == id }) else { return false }
        guard ConversationMemory.saveVerified(item.text, for: item.personaID) else { return false }
        dismiss(id)
        return true
    }

    static func dismiss(_ id: String) {
        all = all.filter { $0.id != id }
    }
}
