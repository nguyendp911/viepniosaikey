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

    static var automaticNameMatch: Bool {
        get { defaults.object(forKey: "viepnaikey.automaticNameMatch") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "viepnaikey.automaticNameMatch") }
    }

    /// The keyboard cannot see the title of a Zalo/Messenger conversation.
    /// Only accept a sender name when the user has actually supplied it in
    /// a labeled chat transcript. Never match names mentioned in message body.
    static func nameFromSharedTranscript(_ text: String) -> String? {
        let rows = text.components(separatedBy: .newlines)
        for line in rows.prefix(5) {
            let entry = line.trimmingCharacters(in: .whitespacesAndNewlines)
            let labels = ["Người gửi:", "Tên người gửi:", "Người nhận:",
                          "Người trò chuyện:", "Sender:", "From:", "Chat with:"]
            for label in labels where entry.lowercased().hasPrefix(label.lowercased()) {
                let value = String(entry.dropFirst(label.count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !value.isEmpty && value.count <= 80 { return value }
            }
        }
        return nil
    }

    static func normalizedName(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive],
                     locale: Locale(identifier: "vi_VN"))
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
    }

    /// Exact unique normalized match; do not choose based on partial names
    /// such as "Nhân" when several saved contacts share that component.
    static func matchingProfile(named name: String) -> RecipientPersona? {
        let expected = normalizedName(name)
        guard expected.count >= 2 else { return nil }
        let matches = all.filter { normalizedName($0.name) == expected }
        return matches.count == 1 ? matches.first : nil
    }

    /// A screenshot supplied through the app's photo picker may contain a
    /// chat title in its top navigation bar. Only evaluate OCR boxes in that
    /// region; never infer the recipient from a chat bubble's text.
    /// Vision's bounding boxes are normalized, origin at bottom left.
    struct ScreenshotTextBox {
        let text: String
        let midX: Double
        let midY: Double
    }

    struct ScreenshotMatch {
        let recognizedTitle: String
        let matches: [RecipientPersona]
        var uniqueMatch: RecipientPersona? {
            matches.count == 1 ? matches[0] : nil
        }
    }

    /// UI layouts vary by iPhone, app version and screenshot crop. Prefer
    /// the upper navigation band, but never treat a message-body match as
    /// proof of identity. Candidates can be reviewed by the user.
    /// Vision occasionally merges the chat title with the online indicator.
    /// Strip only known status suffixes, never arbitrary portions of a name.
    static func normalizedScreenshotTitle(_ value: String) -> String {
        let normalized = normalizedName(value).replacingOccurrences(of: "đ", with: "d")
        let statuses = ["dang hoat dong", "vua truy cap", "hoat dong",
                        "online", "active now", "truy cap gan day"]
        for suffix in statuses {
            for delimiter in [" · ", " • ", " - ", "  ", " ", "\n"] {
                let ending = delimiter + suffix
                if normalized.hasSuffix(ending) {
                    return String(normalized.dropLast(ending.count))
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        return normalized
    }

    static func headerCandidates(_ boxes: [ScreenshotTextBox]) -> [ScreenshotTextBox] {
        boxes.filter {
            $0.midY >= 0.66 && $0.midY <= 0.967
                && $0.midX >= 0.075 && $0.midX <= 0.925
                && isPlausibleHeaderTitle($0.text)
        }.sorted {
            // Higher titles take priority; names may be left-aligned in Zalo.
            if abs($0.midY - $1.midY) > 0.015 { return $0.midY > $1.midY }
            return abs($0.midX - 0.5) < abs($1.midX - 0.5)
        }
    }

    static func isPlausibleHeaderTitle(_ input: String) -> Bool {
        let value = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let folded = normalizedName(value)
        let ignored: Set<String> = [
            "zalo", "messenger", "facebook", "tin nhan", "cuoc tro chuyen",
            "chat", "tim kiem", "search", "online", "hoat dong",
            "goi dien", "tro ve", "them", "chinh sua", "nhom",
            "ket noi", "vua truy cap", "vua moi", "dang hoat dong",
            "video", "anh", "cuoc goi", "call", "menu", "back"
        ]
        guard value.count >= 2 && value.count <= 60,
              !ignored.contains(folded),
              !value.contains(":"),
              value.rangeOfCharacter(from: .letters) != nil,
              !(value.count > 22 && value.contains("?")) else { return false }
        return true
    }

    static func matchScreenshotTitle(_ boxes: [ScreenshotTextBox]) -> ScreenshotMatch? {
        // Compare only top-of-screen candidates against full names. A
        // distinctive name outside the old center-only region now works.
        for box in headerCandidates(boxes) {
            let title = box.text.trimmingCharacters(in: .whitespacesAndNewlines)
            let matches = all.filter {
                normalizedName($0.name) == normalizedScreenshotTitle(title)
            }
            if !matches.isEmpty {
                return ScreenshotMatch(recognizedTitle: title, matches: matches)
            }
        }
        return nil
    }

    @discardableResult
    static func autoSelect(fromSharedTranscript text: String) -> RecipientPersona? {
        guard automaticNameMatch,
              let name = nameFromSharedTranscript(text),
              let matched = matchingProfile(named: name) else { return nil }
        select(matched.id)
        return matched
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
