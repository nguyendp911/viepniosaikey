import UIKit
import AudioToolbox
import Vision

extension KeyboardViewController {
    @objc func punctuationTapped(_ sender: UIButton) {
        let snapshot = proSnapshot()
        defer { recordProEdit(snapshot) }
        beginTyping()
        resetProHangul()
        guard let character = sender.title(for: .normal) else { return }
        commitPhraseWord(boundary:character)
        tactileFeedback()
        resetBilingualComposition()
        if typingPro6.pairing, insertPro6Pair(character) {
            knownWordBoundary = true; recentWord = ""; updateCandidates(); return
        }
        textDocumentProxy.insertText(character)
        knownWordBoundary = true
        recentWord = ""
        updateCandidates()
    }

    @objc func letterTapped(_ sender: UIButton) {
        guard let title = sender.title(for: .normal) else { return }
        let snapshot = proSnapshot()
        defer { recordProEdit(snapshot) }
        if offlineConfig.analytics && !proPrivate { proSessionTaps += 1 }
        if !isNumbers && !offlineConfig.layout.latin {
            beginTyping()
            insertProLanguage(title)
            return
        }
        resetProHangul()
        // Sample every 50th touch without invoking a random-number generator
        // on the input latency-critical path.
        typingTouchCount &+= 1
        let sample = typingTouchCount % 50 == 0
        let startedAt = sample ? CACurrentMediaTime() : 0
        defer {
            if sample {
                let elapsed = (CACurrentMediaTime() - startedAt) * 1000
                // Writing diagnostic preferences can block the keyboard's main
                // thread. Store only aggregate timing from a serial queue.
                typingDiagnosticsQueue.async {
                    KeyboardStability.note("typing", durationMs: elapsed)
                }
            }
        }
        beginTyping()
        recordPremiumTouch(sender)
        let key = isUppercase && !isNumbers ? title.uppercased() : title
        beginPhraseKey(key)
        defer { stagePhraseWord() }
        if typingPro6.pairing, isNumbers, !(typingMode == "vni" && key.first?.isNumber == true), insertPro6Pair(key) {
            resetBilingualComposition();recentWord="";updateCandidates();tactileFeedback();return
        }
        if typingPro6.contextualLanguage && rawComposingWord.isEmpty {
            pro6Language = contextualPro6Language()
        }

        if !isNumbers && typingMode == "telex" && telexEnabled,
           key.count == 1, key.first?.isLetter == true {
            // If another app edited or moved the caret, do not touch its
            // existing text. Check the host suffix before destructive edits.
            if rawComposingWord.isEmpty, !knownWordBoundary,
               (textDocumentProxy.documentContextAfterInput?.first?.isLetter != true),
               (textDocumentProxy.selectedText?.isEmpty ?? true),
               let context = textDocumentProxy.documentContextBeforeInput {
                // A moved caret inside another word or a selected text range
                // must not be silently adopted as this keyboard's composing
                // syllable: doing so can rewrite unrelated host text.
                let existing = String(context.reversed()
                    .prefix(while: { $0.isLetter }).reversed())
                if !existing.isEmpty && existing.count <= 40 {
                    rawComposingWord = existing
                    displayedComposingWord = existing
                    telexCandidateWord = existing
                }
            }
            knownWordBoundary = false
            let rawNext = rawComposingWord + key
            if rawNext.count <= 40 {
                let preference: BilingualComposer.Preference =
                    useSmartBilingual ? (pro6Language ?? bilingualPreference) : .vietnamese
                // One transformation step, not O(word length²) replay.
                let nextTelex = BilingualComposer.appendCandidate(
                    telexCandidateWord, key: key)
                let newWord = BilingualComposer.choose(
                    raw: rawNext, vietnameseCandidate: nextTelex,
                    preference: preference).rendered
                if let edit = FastTyping.edit(from: displayedComposingWord, to: newWord) {
                    if edit.deleteCount > 0 {
                        let current = textDocumentProxy.documentContextBeforeInput ?? ""
                        // Never delete text that is no longer the composing word.
                        guard !displayedComposingWord.isEmpty,
                              (textDocumentProxy.selectedText?.isEmpty ?? true),
                              textDocumentProxy.documentContextAfterInput?.first?.isLetter != true,
                              current.hasSuffix(displayedComposingWord) else {
                            resetBilingualComposition()
                            textDocumentProxy.insertText(key)
                            recentWord = key
                            updateCandidates()
                            tactileFeedback()
                            return
                        }
                        for _ in 0..<edit.deleteCount {
                            textDocumentProxy.deleteBackward()
                        }
                    }
                    if !edit.insertion.isEmpty {
                        textDocumentProxy.insertText(edit.insertion)
                    }
                    rawComposingWord = rawNext
                    telexCandidateWord = nextTelex
                    displayedComposingWord = newWord
                    recentWord = newWord
                    if isUppercase && !isShiftLocked {
                        isUppercase = false
                        updateKeys()
                    }
                    updateCandidates()
                    tactileFeedback()
                    return
                }
                // A literal key must never disappear just because the
                // composer returned an unchanged rendering (for example,
                // repeated tone keys or an already-accented syllable).
                // This branch previously swallowed the touch entirely.
                textDocumentProxy.insertText(key)
                rawComposingWord = rawNext
                // Keep the internal Vietnamese candidate independent of the
                // literal display; adding the key a second time corrupts later
                // auto-language decisions (e.g. repeated tone modifiers).
                telexCandidateWord = nextTelex
                displayedComposingWord += key
                recentWord = displayedComposingWord
                if isUppercase && !isShiftLocked {
                    isUppercase = false
                    updateKeys()
                }
                updateCandidates()
                tactileFeedback()
                return
            }
            resetBilingualComposition()
        } else {
            resetBilingualComposition()
        }
        if isNumbers && typingMode == "vni",
           (textDocumentProxy.selectedText?.isEmpty ?? true),
           textDocumentProxy.documentContextAfterInput?.first?.isLetter != true,
           let before = textDocumentProxy.documentContextBeforeInput {
            let word = String(before.reversed().prefix(while: { $0.isLetter }).reversed())
            if !word.isEmpty,
               let converted = VietnameseVNI.transformed(word: word, key: key),
               let edit = FastTyping.edit(from: word, to: converted) {
                for _ in 0..<edit.deleteCount { textDocumentProxy.deleteBackward() }
                if !edit.insertion.isEmpty { textDocumentProxy.insertText(edit.insertion) }
                recentWord = converted
                updateCandidates()
                tactileFeedback()
                return
            }
        }
        textDocumentProxy.insertText(key)
        knownWordBoundary = false
        if key.first?.isLetter == true {
            recentWord = String((recentWord + key).suffix(32))
        } else {
            recentWord = ""
        }
        if isUppercase && !isShiftLocked {
            isUppercase = false
            updateKeys()
        }
        updateCandidates()
        tactileFeedback()
    }

    @objc func spaceTapped() {
        commitPhraseWord(boundary:" ")
        let snapshot = proSnapshot()
        defer { recordProEdit(snapshot) }
        resetProHangul()
        resetBilingualComposition()
        beginTyping()
        tactileFeedback()
        if typingPro6.doubleSpace, applyPro6DoubleSpace() { return }
        // Space-triggered text expansions must never rewrite text when a
        // selection is active or the insertion point lies inside another word.
        if (textDocumentProxy.selectedText?.isEmpty ?? true),
           textDocumentProxy.documentContextAfterInput?.first?.isLetter != true,
           let context = textDocumentProxy.documentContextBeforeInput {
            let token = String(context.reversed().prefix(while: {
                $0.isLetter || $0.isNumber || $0 == ";" || $0 == "_" || $0 == "/"
            }).reversed())
            let word = String(context.reversed().prefix(while: { $0.isLetter }).reversed())
            if !proPrivate, let template = OfflineProStore.expansion(token: token, profile: offlineConfig.profile, items: offlineSnippets) {
                for _ in token { textDocumentProxy.deleteBackward() }
                textDocumentProxy.insertText(PremiumOffline.variables(template, name: PersonaStore.active?.name ?? "", custom: PremiumStore.variables))
            } else if offlineConfig.layout.latin, let snippet = cachedSnippets[token], !token.isEmpty {
                for _ in token { textDocumentProxy.deleteBackward() }
                textDocumentProxy.insertText(SmartTyping.expandSnippet(
                    snippet, recipient: PersonaStore.active?.name))
            } else if offlineConfig.layout.latin, let replacement = cachedReplacements[word.lowercased()],
                      !word.isEmpty, word.count <= 30 {
                for _ in word { textDocumentProxy.deleteBackward() }
                textDocumentProxy.insertText(replacement)
            } else if offlineConfig.layout.latin && learnWordsEnabled && word.count >= 3 && word.count <= 24 {
                let normalized = word.lowercased()
                learnedWords[normalized, default: 0] += 1
                if learnedWords.count > 360 {
                    // The active session can last hours. Keep the dictionary
                    // bounded in RAM instead of scanning unbounded learned
                    // words and inflating every prediction job.
                    learnedWords = Dictionary(uniqueKeysWithValues:
                        learnedWords.sorted {
                            if $0.value != $1.value { return $0.value > $1.value }
                            return $0.key < $1.key
                        }.prefix(300).map { ($0.key, $0.value) })
                }
                scheduleLearnedWordsFlush()
            }
        }
        textDocumentProxy.insertText(" ")
        if typingPro6.doubleSpace, let before = textDocumentProxy.documentContextBeforeInput {
            pro6LastSpace = (textDocumentProxy.documentIdentifier,before,Date())
        }
        knownWordBoundary = true
        recentWord = ""
        showNextWords()
        if offlineConfig.layout.latin && autocapitalizeEnabled && !isShiftLocked {
            let before = textDocumentProxy.documentContextBeforeInput ?? ""
            let trimmed = before.trimmingCharacters(in: .whitespacesAndNewlines)
            let nextUppercase = trimmed.isEmpty || [".", "!", "?"].contains(String(trimmed.suffix(1)))
            if nextUppercase != isUppercase {
                isUppercase = nextUppercase
                updateKeys()
            }
        }
    }
    @objc func returnTapped() {
        commitPhraseWord(boundary:"\n")
        let snapshot = proSnapshot()
        defer { recordProEdit(snapshot) }
        resetProHangul()
        resetBilingualComposition()
        beginTyping()
        tactileFeedback()
        textDocumentProxy.insertText("\n")
        knownWordBoundary = true
        recentWord = ""
        updateCandidates()
        if KeyboardSettings.autoCapitalize {
            isUppercase = true
            updateKeys()
        }
    }
    @objc func deleteTapped() {
        cancelPhrasePending()
        let snapshot = proSnapshot()
        defer { recordProEdit(snapshot) }
        resetProHangul()
        beginTyping()
        tactileFeedback()
        knownWordBoundary = false
        if !rawComposingWord.isEmpty {
            let preference: BilingualComposer.Preference =
                useSmartBilingual ? (pro6Language ?? bilingualPreference) : .vietnamese
            let priorRaw = String(rawComposingWord.dropLast())
            let prior = BilingualComposer.removingLastKey(
                from: rawComposingWord, preference: preference).rendered
            if let edit = FastTyping.edit(from: displayedComposingWord, to: prior) {
                // A multi-character rewrite is only safe if the host still
                // ends with the exact word this keyboard previously inserted.
                // Plain single-character backspace keeps the native fast path.
                let safe = !displayedComposingWord.isEmpty
                    && (textDocumentProxy.selectedText?.isEmpty ?? true)
                    && textDocumentProxy.documentContextAfterInput?.first?.isLetter != true
                    && (textDocumentProxy.documentContextBeforeInput ?? "")
                        .hasSuffix(displayedComposingWord)
                if safe {
                    for _ in 0..<edit.deleteCount { textDocumentProxy.deleteBackward() }
                    if !edit.insertion.isEmpty {
                        textDocumentProxy.insertText(edit.insertion)
                    }
                    rawComposingWord = priorRaw
                    displayedComposingWord = prior
                    telexCandidateWord = VietnameseTelex.composeKeys(priorRaw)
                    recentWord = prior
                    updateCandidates()
                    return
                }
            }
        }
        // Host context changed or no active composition: native deletion.
        resetBilingualComposition()
        textDocumentProxy.deleteBackward()
        if !recentWord.isEmpty { recentWord.removeLast() }
        updateCandidates()
    }

    @objc func deleteWordGesture(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state != .began {
            pro6RepeatWork?.cancel();pro6RepeatWork=nil
            return
        }
        defer { if typingPro6.repeatEnabled { schedulePro6Repeat(gesture) } }
        resetPhraseContext()
        let snapshot = proSnapshot()
        defer { recordProEdit(snapshot) }
        resetProHangul()
        resetBilingualComposition()
        knownWordBoundary = false
        beginTyping()
        tactileFeedback()
        if !(textDocumentProxy.selectedText ?? "").isEmpty {
            textDocumentProxy.deleteBackward();recentWord="";updateCandidates();return
        }
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        let reversed = before.reversed()
        let spaces = reversed.prefix(while: { $0.isWhitespace }).count
        let letters = reversed.dropFirst(spaces).prefix(while: { $0.isLetter || $0.isNumber }).count
        for _ in 0..<min(80,min(before.count,spaces + max(1, letters))) { textDocumentProxy.deleteBackward() }
        recentWord = ""
        updateCandidates()
    }

    @objc func shiftTapped() {
        tactileFeedback()
        if typingPro6.smartShift {
            let now=Date()
            if let last=pro6LastShift,now.timeIntervalSince(last)<0.35 { isUppercase=true;isShiftLocked=true;pro6LastShift=nil }
            else { isUppercase = !isUppercase; isShiftLocked=false;pro6LastShift=now }
        } else if isUppercase { isShiftLocked.toggle() } else { isUppercase = true }
        if !isUppercase { isShiftLocked = false }
        updateKeys()
    }

    @objc func numbersTapped() {
        resetBilingualComposition()
        knownWordBoundary = false
        tactileFeedback()
        isNumbers.toggle()
        configureGlideRecognizer()
        recentWord = ""
        updateCandidates()
        updateKeys()
    }

    @objc func globeTapped() {
        resetPhraseContext()
        resetBilingualComposition()
        knownWordBoundary = false
        tactileFeedback()
        advanceToNextInputMode()
    }

    @objc func spaceCursorPanned(_ recognizer: UIPanGestureRecognizer) {
        if recognizer.state == .began { resetPhraseContext(); resetBilingualComposition(); resetProHangul(); proHistory.clear(); cancelAIRequest(); studioEdit = nil }
        if premiumPreferences.spaceGesture != "cursor" {
            if recognizer.state == .ended {
                let delta = recognizer.translation(in: recognizer.view)
                if abs(delta.x) >= 45 && abs(delta.x) > abs(delta.y) {
                    if premiumPreferences.spaceGesture == "command" { openPremiumPalette() }
                    else if premiumPreferences.spaceGesture == "delete", delta.x < 0 { premiumDeleteWord() }
                }
                recentWord = ""; updateCandidates()
            }
            return
        }
        let space = recognizer.view
        if typingPro6.spaceUp {
            let delta=recognizer.translation(in:space)
            if abs(delta.y)>abs(delta.x),delta.y < -30 {
                if recognizer.state == .ended { recentWord=""; openPro6Continuation() }
                return
            }
        }
        switch recognizer.state {
        case .began:
            cursorSteps = 0
        case .changed:
            let translation = recognizer.translation(in: space)
            let steps = Int(translation.x / (offlineConfig.trackpad == "accelerated" && abs(translation.x) > 65 ? 8 : 13))
            let move = steps - cursorSteps
            if move != 0 {
                if offlineConfig.trackpad == "word" {
                    for _ in 0..<min(8,abs(move)) { moveProWord(forward: move > 0) }
                } else {
                    textDocumentProxy.adjustTextPosition(byCharacterOffset: move)
                }
                cursorSteps = steps
                tactileFeedback()
            }
        default:
            cursorSteps = 0
            recentWord = ""
            updateCandidates()
        }
    }

    func beginTyping() {
        studioEdit = nil
        if isRequestRunning { cancelAIRequest() }
        nextWordAnchor = nil
        nextWordDocument = nil
        isComposingInteraction = true
        updateContextVisibility()
        // When the user continues after accepting the automatically chosen
        // word, record one real usage. Explicitly picking a different tone
        // records only that chosen tone, never the abandoned auto-choice.
        glideResultGeneration &+= 1
        if let word = pendingGlideWord {
            if glideLearningEnabled,
               (textDocumentProxy.documentContextBeforeInput ?? "").hasSuffix(word + " ") {
                KeyboardSettings.recordGlideChoice(word)
                glideUsageCounts = KeyboardSettings.glideUsageCounts
            }
            pendingGlideWord = nil
            fullGlideOptions = []
        }
        lastWordReplacement = nil
        pro6LastCorrectionDocument=nil;pro6LastCorrectionAnchor=nil
        // Once the user starts composing, do not analyze stale clipboard text.
        selectedText = ""
        if suggestionContainer != nil { clearSuggestions() }
        if !statusLabel.isHidden {
            statusLabel.isHidden = true
            updateKeyboardHeight()
        }
    }
}
