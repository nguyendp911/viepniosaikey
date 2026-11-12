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
        let minhPath = SmartTyping.glideCandidates(
            trace: "mkijnh", language: "vi", limit: 12)
        assert(minhPath.contains("mình"),
               "interpolated physical swipe from M through I N H returns Vietnamese")
        let minh = SmartTyping.glideCandidates(trace: "minh", language: "vi", limit: 12)
        let completeMinh = SmartTyping.glideOptions(minh, language: "vi", showAll: true)
        for tone in ["minh", "mình", "mính", "mĩnh", "mỉnh", "mịnh"] {
            assert(completeMinh.contains(tone), "six minh tone choices: " + tone)
        }
        assert(completeMinh.count >= 6, "all six visible before learning")
        let usage: [String: Int] = [
            SmartTyping.glideUsageKey("mình"): 9,
            SmartTyping.glideUsageKey("minh"): 3
        ]
        let preferred = SmartTyping.glideOptions(minh, language: "vi", usage: usage)
        assert(preferred.first == "mình", "most-used tone rises to first")
        assert(preferred.count == 2 && preferred.contains("minh"),
               "trained swipe hides unused tones")
        assert(SmartTyping.glideOptions(minh, language: "vi", usage: usage,
                                        showAll: true).count >= 6,
               "show all can restore every tone after learning")
        assert(SmartTyping.glideOptions(minh, language: "vi",
                                        usage: [SmartTyping.glideUsageKey("mình"): 2]).count >= 6,
               "early training retains every tone")
        let englishSwipe = SmartTyping.glideCandidates(
            trace: "store", language: "en", limit: 12)
        let englishChoices = SmartTyping.glideOptions(englishSwipe, language: "en")
        assert(englishChoices.contains("store"), "English choices remain literal")
        assert(!englishChoices.contains("stóre"), "English-only has no invented tones")
        assert(SmartTyping.glideToneVariants("mình") ==
                   ["minh", "mình", "mính", "mĩnh", "mỉnh", "mịnh"],
               "Vietnamese tone variants generated in clear order")
        assert(SmartTyping.glideCandidates(trace: "or") == ["or"],
               "two-letter English swipe inserts exact word")
        assert(SmartTyping.glideCandidates(trace: "or", language: "en") == ["or"],
               "English-only swipe keeps English")
        assert(SmartTyping.glideCandidates(trace: "chao", language: "vi").contains("chào"),
               "Vietnamese swipe restores tone in chào")
        assert(SmartTyping.glideCandidates(trace: "toi", language: "auto").contains("tôi"),
               "automatic swipe recognizes tôi without a Telex modifier")
        assert(SmartTyping.glideCandidates(trace: "thuong", language: "vi").contains("thương"),
               "Vietnamese swipe restores shaped vowel in thương")
        assert(SmartTyping.glideCandidates(trace: "ban", language: "vi").contains("bạn"),
               "Vietnamese swipe offers bạn")
        assert(SmartTyping.glideCandidates(trace: "ban", language: "vi").contains("bàn"),
               "Vietnamese swipe offers tone alternatives bàn")
        assert(SmartTyping.glideCandidates(trace: "co", language: "vi").contains("có"),
               "two-key Vietnamese swipe restores accent")
        assert(SmartTyping.glideCandidates(trace: "chao", language: "en").allSatisfy({
                   $0.unicodeScalars.allSatisfy({ $0.isASCII })
               }), "English-only mode never returns accented words")
        assert(SmartTyping.glideCandidates(trace: "cvghgfdsasdftgyuio", language: "vi")
                   .contains("chào"), "dense physical swipe recognizes chào")
        assert(SmartTyping.glideCandidates(trace: "tyghuiokjnbhg", language: "vi")
                   .contains("thương"), "dense physical swipe recognizes thương")
        assert(SmartTyping.glideCandidates(trace: "bvcdsasdfcvbn", language: "vi")
                   .contains("bạn"), "dense physical swipe recognizes bạn")
        assert(SmartTyping.glideCandidates(trace: "dftgyuioijhgvc", language: "vi")
                   .contains("được"), "dense physical swipe recognizes được")
        assert(SmartTyping.glideStartsWithPhysicalKey("được", key: "d"),
               "physical D gesture can insert Vietnamese Đ")
        assert(SmartTyping.glideStartsWithPhysicalKey("bạn", key: "b"),
               "Vietnamese tones do not invalidate physical initial key")
        assert(!SmartTyping.glideStartsWithPhysicalKey("tôi", key: "b"),
               "initial-key safety check prevents unrelated replacement")
        assert(SmartTyping.glideCandidates(trace: "oh").isEmpty,
               "two-letter swipe does not invent words")
        assert(SmartTyping.glideCandidates(trace: "hel o").isEmpty,
               "invalid traced words are not accepted as literal candidates")
        assert(SmartTyping.glideCandidates(trace: "bokk").contains("book"),
               "swipe recognizer tolerates one traced-key error")
        // Dense traces simulate real finger movement across intervening keys,
        // rather than idealized spelling where only target keys are recorded.
        assert(SmartTyping.glideCandidates(trace: "hgtfrertyhjklo").contains("hello"),
               "geometric glide path recognizes hello")
        assert(SmartTyping.glideCandidates(trace: "sdrtyuioiuytre").contains("store"),
               "geometric glide path recognizes store")
        assert(SmartTyping.glideCandidates(trace: "kjhygtrertyhbnjkoiuygtfdsaserd")
                   .contains("keyboard"), "geometric glide path recognizes keyboard")
        assert(SmartTyping.glideCandidates(trace: "helo", learned: ["hello": 9])
                   .contains("hello"), "personalized swipe word")
        assert(SmartTyping.nearbyKeyCorrections("storw").contains("store"),
               "near-key typo suggestions for store")
        assert(SmartTyping.nearbyKeyCorrections("hellp").contains("hello"),
               "near-key typo suggestions for hello")
        assert(SmartTyping.predictions(prefix: "storw").contains("store"),
               "typo correction available as a suggestion only")
        assert(SmartTyping.nearbyKeyCorrections("or").isEmpty,
               "short bilingual tokens must not be guessed")
        assert(SmartTyping.nearbyKeyCorrections("thương").isEmpty,
               "Vietnamese diacritics must not trigger English guesses")
        assert(SmartTyping.expandSnippet("Chào {recipient}", recipient: "Chú Tư")
                   == "Chào Chú Tư", "explicit recipient snippet")
        assert(SmartTyping.expandSnippet("Chào {recipient}") == "Chào {recipient}",
               "recipient is not guessed when no profile selected")
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
        let historyID = PersonaStore.activeID
        ConversationHistory.clear(for: historyID)
        let source = "Tôi: Hôm nay đi làm thế nào?\nBạn ấy: Hôm nay bận lắm.\nTôi: Cố lên nhé!"
        assert(ConversationHistory.parse(source).count == 3,
               "explicitly labeled chat history parses correct speakers")
        assert(ConversationHistory.parse("Chú Tư đang đi chơi").isEmpty,
               "unlabeled text never guesses message sender")
        assert(ConversationHistory.importExplicitly(source, for: historyID) == 3,
               "three manually supplied chat turns saved")
        assert(ConversationHistory.importExplicitly(source, for: historyID) == 0,
               "repeated import does not duplicate chat turns")
        let saved = ConversationHistory.turns(for: historyID)
        assert(saved.count == 3 && saved[0].speaker == .me
                   && saved[1].speaker == .other,
               "two-speaker history preserves labels and order")
        assert(ConversationHistory.prompt(for: historyID).contains("OTHER: Hôm nay bận lắm"),
               "AI sees only saved conversation of the selected profile")
        assert(ConversationHistory.prompt(for: "missing-persona-id").isEmpty,
               "unknown contact cannot access another contact history")
        let topicList = ConversationIntelligence.topics(for: historyID)
        assert(topicList.contains(where: { $0.name == "Công việc" }),
               "offline topic detection recognizes work without cloud AI")
        let matching = ConversationIntelligence.evidence(
            for: historyID, query: "bận làm công việc", limit: 3)
        assert(matching.contains(where: { $0.speaker == .other
            && $0.quote.contains("Hôm nay bận lắm") }),
            "relevance retrieval includes the right speaker and quote")
        assert(ConversationIntelligence.evidence(
            for: "missing-persona-id", query: "công việc").isEmpty,
            "relevance retrieval cannot cross contact profiles")
        assert(ConversationIntelligence.prompt(for: historyID, query: "bận")
                   .contains("OTHER: Hôm nay bận lắm"),
               "cloud prompt includes grounded retrieved evidence")
        KeyboardSettings.learnConversationStyleEnabled = true
        let chatStyle = ConversationIntelligence.stylePrompt(for: historyID)
        assert(chatStyle.contains("ME: Hôm nay đi làm thế nào?")
                   && chatStyle.contains("ME: Cố lên nhé!")
                   && !chatStyle.contains("OTHER: Hôm nay bận lắm."),
               "style learning uses only user-authored imported lines")
        KeyboardSettings.learnConversationStyleEnabled = false
        assert(ConversationIntelligence.stylePrompt(for: historyID).isEmpty,
               "style-learning opt-out immediately removes chat examples")
        KeyboardSettings.learnConversationStyleEnabled = true
        assert(ConversationIntelligence.offlineStarter(for: historyID)?
                   .contains("Công việc") == true,
               "offline idle starter uses explicit saved work discussion")
        assert(ConversationIntelligence.offlineStarter(for: "missing-persona-id") == nil,
               "no source history means no invented personal opener")
        assert(ConversationIntelligence.explanation(
            for: historyID, query: "bận", openingToday: true)
                   .contains("Người ấy: Hôm nay bận lắm"),
               "user-visible why-explanation quotes real source messages")
        // A manual correction to an imported message must be reflected in
        // future evidence retrieval, without changing who sent it.
        var changedTurns = ConversationHistory.all
        if let index = changedTurns.firstIndex(where: {
            $0.personaID == historyID && $0.text == "Cố lên nhé!"
        }) {
            changedTurns[index].text = "Cố gắng nhé!"
            ConversationHistory.all = changedTurns
        }
        assert(ConversationHistory.turns(for: historyID).contains(where: {
            $0.speaker == .me && $0.text == "Cố gắng nhé!"
        }), "editing a saved turn updates the same speaker's conversation")
        ConversationHistory.clear(for: historyID)
        assert(ConversationHistory.turns(for: historyID).isEmpty,
               "conversation deletion removes scoped history")
        let uninformative = "Tôi: Hôm nay bạn sao rồi?\nBạn ấy: Mình ổn."
        assert(ConversationHistory.importExplicitly(uninformative, for: historyID) == 2,
               "unrelated chat can be imported explicitly")
        assert(ConversationIntelligence.topics(for: historyID).isEmpty,
               "word-boundary classifier must not infer sickness from hôm or food from bạn")
        ConversationHistory.clear(for: historyID)
        ConversationMemory.notes = []
        PersonaStore.clearSelection()
        PersonaStore.all = []
        KeyboardStability.clear()
        KeyboardStability.note("paste", durationMs: 8)
        assert(KeyboardStability.report().contains("paste: 1 lần"),
               "local performance counters contain no text")
        KeyboardStability.clear()
        KeyboardSettings.learnedWords = [:]
        KeyboardSettings.frequentlyUsedEmoji = [:]
        KeyboardSettings.recordEmojiSelection("❤️")
        KeyboardSettings.recordEmojiSelection("❤️")
        KeyboardSettings.recordEmojiSelection("😊")
        assert(KeyboardSettings.frequentlyUsedEmoji["❤️"] == 2
               && KeyboardSettings.frequentlyUsedEmoji["😊"] == 1,
               "emoji usage counts explicit selections only")
        KeyboardSettings.frequentlyUsedEmoji = [:]
        assert(KeyboardSettings.frequentlyUsedEmoji.isEmpty,
               "emoji learning can be cleared independently of chat history")
        KeyboardSettings.writingSamples = ["Xin chào, cảm ơn bạn."]
        assert(KeyboardSettings.personalStylePrompt.contains("cảm ơn"),
               "explicit style examples included for AI")
        KeyboardSettings.writingSamples = []
        assert(KeyboardSettings.personalStylePrompt.isEmpty,
               "deleted style examples no longer enter AI context")
        KeyboardSettings.textSnippets = [";date":"{date}", ";time":"{time}"]
    }
}
