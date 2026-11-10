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
        KeyboardSettings.learnedWords = [:]
        KeyboardSettings.textSnippets = [";date":"{date}", ";time":"{time}"]
    }
}
