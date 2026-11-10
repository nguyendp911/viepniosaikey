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
        assert(!SmartTyping.shouldKeepLiteral("thuong", adding: "w"), "Vietnamese end W is not blocked")
        assert(SmartTyping.predictions(prefix: "sto").contains("store"), "offline English suggestions")
        assert(SmartTyping.predictions(prefix: "thư").contains("thương"), "offline Vietnamese suggestions")
        assert(SmartTyping.predictions(prefix: "xyzz").isEmpty, "unknown prefixes return nothing")
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
