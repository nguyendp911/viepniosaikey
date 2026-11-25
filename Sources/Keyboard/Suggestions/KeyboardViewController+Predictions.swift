import UIKit
import AudioToolbox
import Vision

extension KeyboardViewController {
    func updateCandidates(_ override: [String]? = nil) {
        learnedPhraseChoices=[:];learnedPhraseAnchor=nil;learnedPhraseDocument=nil
        if override == nil {
            nextWordAnchor = nil
            nextWordDocument = nil
        }
        if override == nil && pendingGlideWord == nil {
            isGlideSuggestionVisible = false
        }
        if override != nil && !(override?.isEmpty ?? true) {
            isComposingInteraction = true
        } else if !recentWord.isEmpty || pendingGlideWord != nil {
            isComposingInteraction = true
        } else if !glideIsActive {
            isComposingInteraction = false
        }
        updateContextVisibility()
        // Prediction sorting and keyboard-height changes happen after a
        // short typing pause, not synchronously for every physical key.
        // A direct swipe prediction is shown immediately.
        candidateUpdateWork?.cancel()
        candidateGeneration &+= 1
        if let override {
            renderCandidates(override)
            return
        }
        guard (useSuggestions || useSentenceSuggestions), !recentWord.isEmpty else {
            renderCandidates([])
            return
        }
        let word = recentWord
        // Show the physical word immediately; async candidate scoring can
        // replace it later without ever exposing an empty suggestion strip.
        renderCandidates([word])
        let generation = candidateGeneration
        // Keep dictionary scanning and sorting off the keyboard UI thread.
        // Debounce the background work, then return only the final 3 labels.
        let personalWords = learnedWords.merging(customWords, uniquingKeysWith: max)
        let sentenceSuggestionsEnabled = useSentenceSuggestions
        let wordSuggestionsEnabled = useSuggestions
        let sentenceTone = KeyboardSettings.preferredTone
        let phraseEnabled = learnWordsEnabled && !proPrivate && sentenceSuggestionsEnabled
        let phraseSnapshot = phraseEnabled ? phraseModel : PersonalPhraseModel()
        let phraseVersion = phraseRevision
        // Debounce on main before scheduling any CPU work. Previously each
        // touch scheduled a global-queue worker (even if soon cancelled),
        // causing contention after sustained fast typing.
        let job = DispatchWorkItem { [weak self] in
            guard let self, self.candidateGeneration == generation,
                  self.recentWord == word else { return }
            // Read host context only after the debounce, not on every key.
            let phraseContext = phraseEnabled ? (self.textDocumentProxy.documentContextBeforeInput ?? "") : ""
            let phraseDocument = self.textDocumentProxy.documentIdentifier
            let prefixContext = phraseContext.hasSuffix(word) ? String(phraseContext.dropLast(word.count)) : ""
            self.predictionQueue.async { [weak self] in
                var results = wordSuggestionsEnabled
                    ? SmartTyping.predictions(prefix: word, learned: personalWords)
                    : [word]
                if sentenceSuggestionsEnabled {
                    let completions = OfflineSentenceSuggestions.suggestions(for: word, tone: sentenceTone)
                    // Word corrections stay first; clearly labeled whole sentences
                    // remain an explicit tap rather than an automatic replacement.
                    // Keep the typed word first, then show one explicit
                    // sentence choice without hiding it behind word predictions.
                    if let phrase = completions.first, !results.contains(phrase) {
                        results.insert(phrase, at: min(1, results.count))
                    }
                }
                let learned=phraseSnapshot.suggestions(context:PersonalPhraseModel.context(prefixContext),partial:word,limit:2)
                DispatchQueue.main.async { [weak self] in
                    guard let self, self.candidateGeneration == generation,
                          self.recentWord == word else { return }
                    if !learned.isEmpty,phraseVersion==PersonalPhraseStore.revision,
                       KeyboardSettings.autoLearnWords,!KeyboardSettings.privateTypingMode,
                       self.textDocumentProxy.documentIdentifier==phraseDocument,
                       (self.textDocumentProxy.documentContextBeforeInput ?? "")==phraseContext {
                        var labels:[String]=[]
                        for completion in learned {
                            let prefix=word.lowercased()+" "
                            let label=completion.hasPrefix(prefix) ? String(completion.dropFirst(prefix.count)) : completion
                            guard !label.isEmpty,!labels.contains(label),label != word else{continue}
                            self.learnedPhraseChoices[label]=completion
                            labels.append(label)
                        }
                        self.learnedPhraseAnchor=phraseContext;self.learnedPhraseDocument=phraseDocument
                        let rest=results.filter{!labels.contains($0) && $0 != word}
                        results=[word]+labels+rest
                    }
                    self.renderCandidates(results)
                }
            }
        }
        candidateUpdateWork = job
        DispatchQueue.main.asyncAfter(
            deadline: .now() + .milliseconds(95), execute: job)
    }

    func renderCandidates(_ results: [String]) {
        // Reuse word chips for the entire keyboard lifetime. The old version
        // destroyed and recreated 1-3 Auto Layout-backed UIButtons on nearly
        // every keypress: [typed] -> [three predictions] -> [typed] -> ...
        // Repeated allocations and constraints eventually stuttered.
        let shouldHide = !isComposingInteraction
            || (!useSuggestions && !useSentenceSuggestions && !isGlideSuggestionVisible)
        let needsExpand = pendingGlideWord != nil
            && fullGlideOptions.count > results.count
        if results == candidateWords,
           candidateScroll.isHidden == shouldHide,
           (candidateExpandButton?.isHidden ?? true) == !needsExpand { return }

        candidateWords = results
        if candidateScroll.isHidden != shouldHide {
            candidateScroll.isHidden = shouldHide
        }
        while candidateButtons.count < results.count {
            let index = candidateButtons.count
            let button = UIButton(type: .system)
            button.tag = index
            button.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
            SuggestionChipView.style(button, palette: KeyboardThemePalette.resolve(currentTheme))
            button.contentEdgeInsets = UIEdgeInsets(
                top: 6, left: 13, bottom: 6, right: 13)
            button.addTarget(self, action: #selector(candidateTapped(_:)),
                             for: .touchUpInside)
            // Hidden arrangedSubviews get UIKit's required zero-width
            // constraint. A required minimum width here would conflict with
            // it and produce repeated Auto Layout warnings on every word.
            let minWidth = button.widthAnchor.constraint(
                greaterThanOrEqualToConstant: 62)
            minWidth.priority = .defaultHigh
            minWidth.isActive = true
            candidateButtons.append(button)
            candidateBar.insertArrangedSubview(button, at: index)
        }
        for (index, button) in candidateButtons.enumerated() {
            let visible = index < results.count
            if visible {
                let word = results[index]
                if button.title(for: .normal) != word {
                    button.setTitle(word, for: .normal)
                    button.accessibilityLabel = "Chọn từ " + word
                }
            }
            if button.isHidden == visible {
                button.isHidden = !visible
            }
        }
        if needsExpand && candidateExpandButton == nil {
            let more = UIButton(type: .system)
            more.setTitle("Tất cả  ···", for: .normal)
            more.setTitleColor(cyanColor, for: .normal)
            more.titleLabel?.font = .systemFont(ofSize: 12, weight: .bold)
            SuggestionChipView.style(more, palette: KeyboardThemePalette.resolve(currentTheme))
            more.layer.cornerRadius = 11
            more.contentEdgeInsets = UIEdgeInsets(
                top: 6, left: 12, bottom: 6, right: 12)
            more.addTarget(self, action: #selector(expandGlideCandidates),
                           for: .touchUpInside)
            candidateExpandButton = more
            candidateBar.addArrangedSubview(more)
        }
        if let more = candidateExpandButton {
            more.isHidden = !needsExpand
        }
        updateContextVisibility()
    }

    @objc func expandGlideCandidates() {
        guard pendingGlideWord != nil, !fullGlideOptions.isEmpty else { return }
        renderCandidates(fullGlideOptions)
        tactileFeedback()
    }

    @objc func candidateTapped(_ sender: UIButton) {
        guard candidateWords.indices.contains(sender.tag) else { return }
        let chosen = candidateWords[sender.tag]
        resetPhraseContext()
        if let completion=learnedPhraseChoices[chosen] {
            guard learnedPhraseDocument==textDocumentProxy.documentIdentifier,
                  learnedPhraseAnchor==(textDocumentProxy.documentContextBeforeInput ?? ""),
                  (textDocumentProxy.selectedText?.isEmpty ?? true),
                  textDocumentProxy.documentContextAfterInput?.first?.isLetter != true,
                  KeyboardSettings.autoLearnWords,!KeyboardSettings.privateTypingMode else{updateCandidates();return}
            resetBilingualComposition()
            replaceCurrentWord(completion)
            if completion.contains(" ") {
                textDocumentProxy.insertText(" ")
                knownWordBoundary=true;recentWord="";showNextWords()
            }
            tactileFeedback();return
        }
        if let anchor = nextWordAnchor {
            guard nextWordDocument == textDocumentProxy.documentIdentifier,
                  (textDocumentProxy.selectedText?.isEmpty ?? true),
                  textDocumentProxy.documentContextAfterInput?.first?.isLetter != true,
                  (textDocumentProxy.documentContextBeforeInput ?? "").hasSuffix(anchor) else {
                updateCandidates()
                return
            }
            nextWordAnchor = nil
            nextWordDocument = nil
            resetBilingualComposition()
            textDocumentProxy.insertText(chosen + " ")
            knownWordBoundary = true
            recentWord = ""
            showNextWords()
            tactileFeedback()
            return
        }
        if let committed = pendingGlideWord {
            // An explicitly chosen alternate can replace the word created by
            // the previous swipe, including its trailing space. Only touch
            // the host field when the exact suffix is still present.
            let current = textDocumentProxy.documentContextBeforeInput ?? ""
            if (textDocumentProxy.selectedText?.isEmpty ?? true),
               textDocumentProxy.documentContextAfterInput?.first?.isLetter != true,
               current.hasSuffix(committed + " ") {
                for _ in 0..<(committed.count + 1) {
                    textDocumentProxy.deleteBackward()
                }
                textDocumentProxy.insertText(chosen + " ")
                if glideLearningEnabled {
                    KeyboardSettings.recordGlideChoice(chosen)
                    glideUsageCounts = KeyboardSettings.glideUsageCounts
                }
                resetBilingualComposition()
                knownWordBoundary = true
                recentWord = ""
                updateCandidates()
                tactileFeedback()
                return
            }
            resetBilingualComposition()
            renderCandidates([])
            return
        }
        resetBilingualComposition()
        replaceCurrentWord(chosen)
        if chosen.contains(" ") {
            // A full phrase is a committed suggestion, not a single word
            // to re-enter the predictive keyboard pipeline.
            knownWordBoundary = true
            recentWord = ""
            updateCandidates()
        }
        tactileFeedback()
    }

    func replaceCurrentWord(_ replacement: String) {
        // Do not rewrite a selected range or the left half of a word when
        // the caret is moved into the middle of an existing sentence.
        guard (textDocumentProxy.selectedText?.isEmpty ?? true),
              textDocumentProxy.documentContextAfterInput?.first?.isLetter != true,
              let before = textDocumentProxy.documentContextBeforeInput else { return }
        let current = String(before.reversed().prefix(while: { $0.isLetter }).reversed())
        guard current.count <= 40, replacement.count <= 240 else { return }
        if let edit = FastTyping.edit(from: current, to: replacement) {
            for _ in 0..<edit.deleteCount { textDocumentProxy.deleteBackward() }
            if !edit.insertion.isEmpty { textDocumentProxy.insertText(edit.insertion) }
        } else if current.isEmpty {
            textDocumentProxy.insertText(replacement)
        }
        if !current.isEmpty && current != replacement {
            lastWordReplacement = (original: current, corrected: replacement)
        }
        recentWord = replacement
        updateCandidates()
    }

    @objc func undoWordCorrection() {
        guard let stored = lastWordReplacement else {
            showStatus("Chưa có sửa từ để hoàn tác")
            return
        }
        lastWordReplacement = nil
        guard (textDocumentProxy.selectedText?.isEmpty ?? true),
              textDocumentProxy.documentContextAfterInput?.first?.isLetter != true,
              let context = textDocumentProxy.documentContextBeforeInput,
              context.hasSuffix(stored.corrected),
              let edit = FastTyping.edit(from: stored.corrected, to: stored.original) else {
            showStatus("Văn bản đã thay đổi, không thể hoàn tác an toàn")
            return
        }
        for _ in 0..<edit.deleteCount { textDocumentProxy.deleteBackward() }
        if !edit.insertion.isEmpty { textDocumentProxy.insertText(edit.insertion) }
        resetBilingualComposition()
        recentWord = stored.original
        updateCandidates()
        showStatus("Đã hoàn tác sửa từ")
    }
}
