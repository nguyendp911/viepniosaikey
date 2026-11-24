import UIKit
import AudioToolbox
import Vision

extension KeyboardViewController {
    /// Refresh when the keyboard becomes visible or the user taps an emoji.
    /// A contact's saved chat is never inspected or sent to AI in this idle
    /// path. Conversation starters are editable, optional local templates.
    func refreshIdleActions() {
        let defaults = ["❤️", "😂", "😊", "🥰", "👍", "🙏", "😍", "✨", "🎉", "😅"]
        let usage = KeyboardSettings.frequentlyUsedEmoji
        let emoji = defaults.sorted {
            let a = usage[$0] ?? 0, b = usage[$1] ?? 0
            if a != b { return a > b }
            return (defaults.firstIndex(of: $0) ?? 0)
                < (defaults.firstIndex(of: $1) ?? 0)
        }
        let person = PersonaStore.active
        let greeting = person.flatMap {
            ConversationIntelligence.offlineStarter(for: $0.id)
        } ?? (person == nil ? "Hôm nay bạn thế nào?"
            : "Hôm nay \(person!.name) thế nào?")
        let topEmoji = Array(emoji.prefix(4))
        idleActions = topEmoji.map { (title: $0, insert: $0, emoji: true) }
        // Keep a useful conversation starter in the visible portion of the
        // strip, rather than hiding it behind ten emoji on narrow screens.
        idleActions.append((title: "💬 Hỏi thăm", insert: greeting, emoji: false))
        idleActions.append(contentsOf: emoji.dropFirst(4).map {
            (title: $0, insert: $0, emoji: true)
        })
        idleActions.append(contentsOf: [
            (title: "☀️ Chào ngày mới", insert: "Chúc bạn một ngày tốt lành nhé!", emoji: false),
            (title: "✨ Gợi chuyện", insert: "Dạo này bạn có gì mới không?", emoji: false)
        ])
        // User-saved phrases are displayed only in the idle strip, and only
        // inserted after an explicit tap. Avoid loading large history or AI
        // context on the keyboard's keystroke path.
        for phrase in KeyboardSettings.savedPhrases.prefix(3) {
            let clean = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !clean.isEmpty, clean.count <= 240 else { continue }
            idleActions.append((title: "📌 " + String(clean.prefix(18)),
                                insert: clean, emoji: false))
        }
        for child in idleBar.arrangedSubviews {
            idleBar.removeArrangedSubview(child)
            child.removeFromSuperview()
        }
        for (index, item) in idleActions.enumerated() {
            let chip = UIButton(type: .system)
            chip.tag = index
            chip.setTitle(item.title, for: .normal)
            chip.titleLabel?.font = .systemFont(
                ofSize: item.emoji ? 23 : 12,
                weight: item.emoji ? .regular : .medium)
            chip.setTitleColor(.label, for: .normal)
            chip.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.8)
            chip.layer.cornerRadius = 13
            chip.contentEdgeInsets = UIEdgeInsets(
                top: 8, left: item.emoji ? 11 : 13,
                bottom: 8, right: item.emoji ? 11 : 13)
            chip.widthAnchor.constraint(greaterThanOrEqualToConstant:
                item.emoji ? 49 : 110).isActive = true
            chip.accessibilityLabel = item.emoji ? "Chèn emoji " + item.title
                : "Chèn câu gợi ý " + item.title
            chip.addTarget(self, action: #selector(idleActionTapped(_:)),
                           for: .touchUpInside)
            idleBar.addArrangedSubview(chip)
        }
    }

    @objc func idleActionTapped(_ sender: UIButton) {
        guard idleActions.indices.contains(sender.tag) else { return }
        let item = idleActions[sender.tag]
        // An explicit selection is the only action that inserts anything.
        // Never overwrite text already typed in the host application.
        resetBilingualComposition()
        textDocumentProxy.insertText(item.insert)
        if item.emoji {
            KeyboardSettings.recordEmojiSelection(item.insert)
            refreshIdleActions()
        }
        knownWordBoundary = true
        recentWord = ""
        tactileFeedback()
        updateCandidates()
    }

    func updateContextVisibility() {
        let showWords = isComposingInteraction
            && (useSuggestions || useSentenceSuggestions || isGlideSuggestionVisible)
        idleScroll.isHidden = showWords
        candidateScroll.isHidden = !showWords
        // Keep contextSlot permanently visible and fixed height.
        // Mode transitions must never cause row reflow.
    }
}
