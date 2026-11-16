import Foundation

/// Remembers which chat (recipient profile) a text field belonged to. A chat
/// app normally gives every conversation its own input field, so once the user
/// has said who they are writing to, coming back to that field needs no
/// screenshot. The field is identified only by the opaque id iOS hands to the
/// keyboard; no text or app name is stored, and entries expire.
struct ChatFieldMemory: Codable, Equatable {
    struct Entry: Codable, Equatable {
        var profileID: String
        var stamp: Double
    }

    /// Stored instead of a profile when the user says "this is not a chat".
    static let ignored = "-"
    static let maxEntries = 30
    static let maxAge: TimeInterval = 48 * 3600

    var entries: [String: Entry] = [:]

    func profileID(for field: String, now: Date = Date()) -> String? {
        guard let entry = entries[field],
              now.timeIntervalSince1970 - entry.stamp <= ChatFieldMemory.maxAge else { return nil }
        return entry.profileID
    }

    mutating func remember(field: String, profileID: String, now: Date = Date()) {
        entries[field] = Entry(profileID: profileID, stamp: now.timeIntervalSince1970)
        guard entries.count > ChatFieldMemory.maxEntries else { return }
        let newest = entries.sorted { (a: (key: String, value: Entry), b: (key: String, value: Entry)) -> Bool in
            a.value.stamp > b.value.stamp
        }.prefix(ChatFieldMemory.maxEntries)
        var kept: [String: Entry] = [:]
        for item in newest { kept[item.key] = item.value }
        entries = kept
    }

    /// Drop everything that points at a profile (for example one that was deleted).
    mutating func forget(profileID: String) {
        var kept: [String: Entry] = [:]
        for (field, entry) in entries where entry.profileID != profileID { kept[field] = entry }
        entries = kept
    }

    static func decode(_ data: Data?) -> ChatFieldMemory {
        guard let data, let value = try? JSONDecoder().decode(ChatFieldMemory.self, from: data) else {
            return ChatFieldMemory()
        }
        return value
    }

    func encoded() -> Data? {
        try? JSONEncoder().encode(self)
    }
}
