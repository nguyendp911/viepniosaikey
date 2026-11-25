import UIKit

extension KeyboardViewController {
    func reloadPhraseLearning() {
        phraseSaveWork?.cancel()
        phraseRevision=PersonalPhraseStore.revision
        phraseModel=PersonalPhraseStore.load()
        resetPhraseContext()
    }
    func resetPhraseContext() {
        phraseDocument=nil;phraseStart=nil;phraseChain=[];phraseEnd=nil
    }
    // Begin observing only when our own letter starts at a word boundary.
    // Never adopt a word already typed by a host app or another keyboard.
    func beginPhraseKey(_ key:String) {
        guard learnWordsEnabled,!proPrivate,KeyboardSettings.autoLearnWords,!KeyboardSettings.privateTypingMode else{resetPhraseContext();return}
        guard key.first?.isLetter==true else {
            if typingMode != "vni" {resetPhraseContext()}
            return
        }
        let proxy=textDocumentProxy
        let doc=proxy.documentIdentifier
        if phraseStart != nil && phraseDocument==doc {return}
        guard (proxy.selectedText?.isEmpty ?? true),
              proxy.documentContextAfterInput?.first?.isLetter != true,
              let before=proxy.documentContextBeforeInput,
              before.last?.isLetter != true,before.last?.isNumber != true else{resetPhraseContext();return}
        if phraseDocument != doc || phraseEnd.map({!before.hasSuffix($0)}) != false {phraseChain=[]}
        phraseDocument=doc;phraseStart=String(before.suffix(100))
    }
    func commitPhraseWord(boundary:String) {
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
        phraseEnd=String((before+boundary).suffix(100))
        if boundary != " " {resetPhraseContext()}
    }
    func schedulePhraseSave() {
        phraseSaveWork?.cancel()
        let job=DispatchWorkItem{[weak self] in self?.flushPhraseLearning()}
        phraseSaveWork=job
        DispatchQueue.main.asyncAfter(deadline:.now()+.seconds(3),execute:job)
    }
    func flushPhraseLearning() {
        phraseSaveWork?.cancel();phraseSaveWork=nil
        let snapshot=phraseModel, revision=phraseRevision
        phraseStorageQueue.async {PersonalPhraseStore.save(snapshot,revision:revision)}
    }
    func personalPhraseSuggestions(context:String,partial:String="")->[String] {
        guard learnWordsEnabled,!proPrivate,KeyboardSettings.autoLearnWords,!KeyboardSettings.privateTypingMode,
              phraseRevision==PersonalPhraseStore.revision else{return []}
        return phraseModel.suggestions(context:PersonalPhraseModel.context(context),partial:partial)
    }
}
