import UIKit

extension KeyboardViewController {
    func reloadPhraseLearning() {
        let revision=PersonalPhraseStore.revision
        if !learnWordsEnabled || proPrivate {
            phraseSaveWork?.cancel();phraseSaveWork=nil;phraseModel=PersonalPhraseModel();phraseRevision=""
        } else if phraseRevision != revision {
            phraseSaveWork?.cancel();phraseSaveWork=nil;phraseRevision=revision
            phraseModel=PersonalPhraseStore.load()
        }
        resetPhraseContext()
    }
    func resetPhraseContext() {
        cancelPhrasePending()
        phraseDocument=nil;phraseStart=nil;phraseChain=[];phraseEnd=nil
    }
    // Begin observing only when our own letter starts at a word boundary.
    // Never adopt a word already typed by a host app or another keyboard.
    func beginPhraseKey(_ key:String) {
        guard learnWordsEnabled,!proPrivate else{resetPhraseContext();return}
        cancelPhrasePending()
        guard key.first?.isLetter==true else {
            if typingMode != "vni" {resetPhraseContext()}
            return
        }
        let proxy=textDocumentProxy
        let doc=proxy.documentIdentifier
        if phraseStart != nil && phraseDocument==doc {return}
        guard (proxy.selectedText?.isEmpty ?? true),
              proxy.documentContextAfterInput?.first?.isLetter != true else{resetPhraseContext();return}
        let before=proxy.documentContextBeforeInput ?? ""
        guard before.last.map({$0.isWhitespace || ".!?,".contains($0)}) ?? true else{resetPhraseContext();return}
        if phraseDocument != doc || phraseEnd.map({!before.hasSuffix($0)}) != false {phraseChain=[]}
        phraseDocument=doc;phraseStart=String(before.suffix(40))
    }
    func commitPhraseWord(boundary:String) {
        cancelPhrasePending()
        guard learnWordsEnabled,!proPrivate,KeyboardSettings.autoLearnWords,!KeyboardSettings.privateTypingMode,
              let start=phraseStart,phraseDocument==textDocumentProxy.documentIdentifier,
              (textDocumentProxy.selectedText?.isEmpty ?? true),
              textDocumentProxy.documentContextAfterInput?.first?.isLetter != true,
              let before=textDocumentProxy.documentContextBeforeInput else{resetPhraseContext();return}
        let word=String(before.reversed().prefix(while:{$0.isLetter}).reversed())
        guard !word.isEmpty,before.hasSuffix(start+word),
              let token=PersonalPhraseModel.token(word) else{resetPhraseContext();return}
        // A change of revision means the user cleared learning in the app.
        if phraseRevision != PersonalPhraseStore.revision {reloadPhraseLearning();return}
        phraseChain.append(token);phraseChain=Array(phraseChain.suffix(9))
        if PersonalPhraseModel.safe(phraseChain) {
            phraseModel.observe(phraseChain)
            schedulePhraseSave()
        } else {phraseChain=[]}
        phraseStart=nil
        phraseEnd=String((before+boundary).suffix(40))
        if boundary != " " {resetPhraseContext()}
    }
    // A host's send action may clear the field without pressing space.
    // Stage the final verified word after a short pause, in RAM only.
    // Commit it if the same document subsequently clears completely.
    func cancelPhrasePending() {
        phraseIdleWork?.cancel();phraseIdleWork=nil
        phrasePendingWords=nil;phrasePendingDocument=nil
    }
    func stagePhraseWord() {
        guard learnWordsEnabled,!proPrivate,phraseStart != nil,!phraseChain.isEmpty else{return}
        phraseIdleWork?.cancel()
        let job=DispatchWorkItem{[weak self] in
            guard let self,self.learnWordsEnabled,!KeyboardSettings.privateTypingMode,KeyboardSettings.autoLearnWords,
                  let start=self.phraseStart,self.phraseDocument==self.textDocumentProxy.documentIdentifier,
                  (self.textDocumentProxy.selectedText?.isEmpty ?? true),
                  self.textDocumentProxy.documentContextAfterInput?.first?.isLetter != true,
                  let before=self.textDocumentProxy.documentContextBeforeInput else{return}
            let word=String(before.reversed().prefix(while:{$0.isLetter}).reversed())
            guard let token=PersonalPhraseModel.token(word),before.hasSuffix(start+word) else{return}
            let words=Array((self.phraseChain+[token]).suffix(9))
            guard PersonalPhraseModel.safe(words) else{return}
            self.phrasePendingWords=words
            self.phrasePendingDocument=self.phraseDocument
        }
        phraseIdleWork=job
        DispatchQueue.main.asyncAfter(deadline:.now() + .milliseconds(180),execute:job)
    }
    func learnPhraseAfterHostClear() {
        guard let words=phrasePendingWords else{return}
        let proxy=textDocumentProxy
        if phrasePendingDocument != proxy.documentIdentifier {resetPhraseContext();return}
        guard (proxy.documentContextBeforeInput ?? "").isEmpty,
              (proxy.documentContextAfterInput ?? "").isEmpty,
              (proxy.selectedText?.isEmpty ?? true) else{return}
        if learnWordsEnabled,!proPrivate,KeyboardSettings.autoLearnWords,!KeyboardSettings.privateTypingMode,
           phraseRevision==PersonalPhraseStore.revision {
            phraseModel.observe(words);schedulePhraseSave()
        }
        resetPhraseContext()
    }
    func schedulePhraseSave() {
        phraseSaveWork?.cancel()
        let job=DispatchWorkItem{[weak self] in self?.flushPhraseLearning()}
        phraseSaveWork=job
        DispatchQueue.main.asyncAfter(deadline:.now() + .seconds(3),execute:job)
    }
    func flushPhraseLearning() {
        phraseSaveWork?.cancel();phraseSaveWork=nil
        let snapshot=phraseModel, revision=phraseRevision
        phraseStorageQueue.async {PersonalPhraseStore.save(snapshot,revision:revision)}
    }
    func personalPhraseSuggestions(context:String,partial:String="")->[String] {
        guard learnWordsEnabled,!proPrivate,KeyboardSettings.autoLearnWords,!KeyboardSettings.privateTypingMode,
              phraseRevision==PersonalPhraseStore.revision else{return []}
        return phraseModel.suggestions(context:PersonalPhraseModel.context(context),partial:partial,minimum:max(2,min(5,typingPro6.confidence)))
    }
}
