import Foundation

@main
struct VerifySmartKeyboard {
    static func main() {
        func assert(_ condition: @autoclosure () -> Bool, _ message: String) {
            guard condition() else { fatalError("Smart keyboard test failed: " + message) }
            print("PASS [Smart] " + message)
        }
        assert(SmartTyping.shouldKeepLiteral("st", adding: "o"), "English prefix protection")
        assert(SmartTyping.shouldKeepLiteral("ca", adding: "r"), "car stays English")
        assert(SmartTyping.shouldKeepLiteral("bo", adding: "o"), "book prevents oo shape")
        assert(SmartTyping.shouldKeepLiteral("to", adding: "o"), "English tool prefix is initially protected")
        assert(SmartTyping.resolveDeferredVietnamese(word: "too", adding: "i") == "tôi",
               "tooi resolves to tôi despite English prefix")
        assert(SmartTyping.resolveDeferredVietnamese(word: "Too", adding: "i") == "Tôi",
               "Tooi preserves initial capital letter")
        assert(SmartTyping.resolveDeferredVietnamese(word: "too", adding: "l") == nil,
               "tool stays an English word")
        assert(SmartTyping.resolveDeferredVietnamese(word: "sto", adding: "r") == nil,
               "store prefix not converted into Vietnamese")
        assert(!SmartTyping.shouldKeepLiteral("thuong", adding: "w"), "Vietnamese end W is not blocked")
        assert(SmartTyping.predictions(prefix: "sto").contains("store"), "offline English suggestions")
        assert(SmartTyping.predictions(prefix: "thư").contains("thương"), "offline Vietnamese suggestions")
        assert(SmartTyping.predictions(prefix: "xyzz").isEmpty, "unknown prefixes return nothing")
        // Compare indexed predictions with the reference full scan for
        // English, Vietnamese, personalized, and accented prefixes.
        let personal = ["thương mại": 7, "storefront": 4, "tôi": 2]
        func referencePredictions(_ raw: String, limit: Int = 3) -> [String] {
            let prefix = raw.lowercased()
            guard prefix.count >= 2, prefix.count <= 24, limit > 0 else { return [] }
            var seen = Set<String>()
            var words: [String] = []
            for word in personal.keys where word.lowercased().hasPrefix(prefix) {
                if seen.insert(word).inserted { words.append(word) }
            }
            for word in SmartTyping.englishWords + SmartTyping.vietnameseWords
                where word.hasPrefix(prefix) {
                if seen.insert(word).inserted { words.append(word) }
            }
            return Array(words.sorted {
                let a = personal[$0] ?? 0, b = personal[$1] ?? 0
                if a != b { return a > b }
                if $0 == prefix { return true }
                if $1 == prefix { return false }
                if $0.count != $1.count { return $0.count < $1.count }
                return $0 < $1
            }.prefix(limit))
        }
        for prefix in ["st", "sto", "th", "thư", "tô", "ng", "ngư", "ca",
                       "bo", "go", "zz", "ST", "Th", "tiếng", "tôi"] {
            let actual = SmartTyping.predictions(prefix: prefix, learned: personal)
            assert(actual == referencePredictions(prefix), "indexed predictions: " + prefix)
        }
        assert(SmartTyping.predictions(prefix: "th", learned: personal, limit: 0).isEmpty,
               "zero-limit predictions return nothing")

        assert(SmartTyping.glideCandidates(trace: "helo").contains("hello"), "offline swipe candidate")
        let expanded = SmartTyping.expandSnippet("Hôm nay {date}, giờ {time}")
        assert(!expanded.contains("{date}") && !expanded.contains("{time}"),
               "user-triggered snippet variables")
        PersonaStore.clearSelection()
        PersonaStore.all = []
        PersonaStore.add(name: "Chú Tư", role: "uncle",
                         selfAddress: "cháu", tone: "lịch sự")
        assert(PersonaStore.active?.name == "Chú Tư", "manual persona stored")
        PersonaStore.automaticNameMatch = true
        assert(PersonaStore.matchingProfile(named: "CHÚ TƯ")?.name == "Chú Tư",
               "case-insensitive unique matching")
        assert(PersonaStore.nameFromSharedTranscript("Người gửi: Chú Tư\nChú về chưa?") == "Chú Tư",
               "sender labeled transcript parsing")
        assert(PersonaStore.nameFromSharedTranscript("Chú Tư đang đi công tác") == nil,
               "never match names merely mentioned in message body")
        assert(PersonaStore.autoSelect(fromSharedTranscript: "From: Chú Tư\nHello")?.name == "Chú Tư",
               "auto selects uniquely matched sender")
        PersonaStore.automaticNameMatch = false
        assert(PersonaStore.autoSelect(fromSharedTranscript: "From: Chú Tư") == nil,
               "automatic name matching respects opt-out")
        PersonaStore.automaticNameMatch = true
        assert(ConversationContextResolver.resolve("Lát về nhé").recipient == .uncle,
               "manual persona priority on ambiguous message")
        PersonaStore.clearSelection()
        PersonaStore.all = []
        assert(ConversationContextResolver.resolve("Lát về nhé").recipient == .automatic,
               "clearing persona restores automatic addressing")
        ClipboardVault.clear()
        assert(ClipboardVault.items.isEmpty, "clipboard is empty by default")
        ClipboardVault.saveExplicitly("Một đoạn được tự chọn")
        assert(ClipboardVault.items == ["Một đoạn được tự chọn"], "explicit opt-in save")
        ClipboardVault.saveExplicitly("Một đoạn được tự chọn")
        assert(ClipboardVault.items.count == 1, "clipboard deduplication")
        ClipboardVault.clear()
        assert(ClipboardVault.items.isEmpty, "clipboard clearing")
        assert(MessageSafety.warnings(in: "OTP: 123456").count > 0,
               "privacy warning for OTP")
        assert(!MessageSafety.redacted("password: abc123").contains("abc123"),
               "privacy strips explicit passwords")
        assert(MessageSafety.warnings(in: "Chào chú nhé").isEmpty,
               "harmless messages are not blocked")
        assert(!ToneInspector.suggestions(for: "Sao chưa làm?").isEmpty,
               "tone check flags possible harsh wording")
        PersonaStore.add(name: "Chú Tư", role: "uncle",
                         selfAddress: "cháu", tone: "Lịch sự")
        ConversationMemory.save("Gọi người nhận là chú.", for: PersonaStore.activeID)
        assert(ConversationMemory.forActivePersona().count == 1,
               "user-approved per-contact memory")
        assert(ConversationMemory.prompt().contains("Gọi người nhận là chú."),
               "AI receives only selected-contact notes")
        ConversationMemory.notes = []
        PersonaStore.clearSelection()
        PersonaStore.all = []
        KeyboardStability.clear()
        KeyboardStability.note("paste", durationMs: 8)
        assert(KeyboardStability.report().contains("paste: 1 lần"),
               "local performance counters contain no text")
        KeyboardStability.clear()
        KeyboardSettings.learnedWords = [:]
        KeyboardSettings.textSnippets = [";date":"{date}", ";time":"{time}"]
    }
}
