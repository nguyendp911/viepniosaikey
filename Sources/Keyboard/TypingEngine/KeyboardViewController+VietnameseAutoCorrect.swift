import UIKit

struct AutoCorrectionUndo {
    let document:UUID
    let prefix:String
    let original:String
    let corrected:String
    let after:String
    var boundary=""
}
extension KeyboardViewController {
    func resetAutoWord(){autoWordDocument=nil;autoWordPrefix=nil;autoWordExpected=nil;autoWordAfter=nil}
    var canVietnameseCorrect:Bool {
        vietnameseAutoCorrect.mode != "off" && offlineConfig.layout.latin &&
        (!useSmartBilingual || (bilingualPreference != .english && pro6Language != .english)) && !proPrivate
    }
    func beginAutoWord(_ key:String) {
        guard canVietnameseCorrect,key.count==1,key.first?.isLetter==true else{resetAutoWord();return}
        let proxy=textDocumentProxy
        let before=proxy.documentContextBeforeInput ?? "",after=proxy.documentContextAfterInput ?? ""
        guard (proxy.selectedText?.isEmpty ?? true),after.first?.isLetter != true,after.first?.isNumber != true else{resetAutoWord();return}
        if autoWordDocument==proxy.documentIdentifier,autoWordExpected==before,autoWordAfter==after{return}
        resetAutoWord()
        guard before.last.map({$0.isWhitespace || ".!?,".contains($0)}) ?? true else{return}
        autoWordDocument=proxy.documentIdentifier;autoWordPrefix=String(before.suffix(40));autoWordAfter=after
    }
    func finishAutoWord() {
        let proxy=textDocumentProxy
        guard let prefix=autoWordPrefix,autoWordDocument==proxy.documentIdentifier,let before=proxy.documentContextBeforeInput,
              autoWordAfter==(proxy.documentContextAfterInput ?? ""), (proxy.selectedText?.isEmpty ?? true) else{resetAutoWord();return}
        let word=String(before.reversed().prefix(while:{$0.isLetter}).reversed())
        guard !word.isEmpty,word.count<=24,before.hasSuffix(prefix+word) else{resetAutoWord();return}
        autoWordExpected=before
    }
    func applyVietnameseCorrection(boundary:String)->AutoCorrectionUndo? {
        defer{resetAutoWord()}
        guard canVietnameseCorrect,[" ","\n",".",",","!","?",";",":"].contains(boundary),
              let prefix=autoWordPrefix,let before=textDocumentProxy.documentContextBeforeInput,
              autoWordExpected==before,autoWordDocument==textDocumentProxy.documentIdentifier,
              autoWordAfter==(textDocumentProxy.documentContextAfterInput ?? ""),
              (textDocumentProxy.selectedText?.isEmpty ?? true) else{return nil}
        let word=String(before.reversed().prefix(while:{$0.isLetter}).reversed())
        guard !word.isEmpty,before.hasSuffix(prefix+word),
              cachedReplacements[word.lowercased()]==nil,cachedSnippets[word]==nil,
              OfflineProStore.expansion(token:word,profile:offlineConfig.profile,items:offlineSnippets)==nil else{return nil}
        let previous=String(before.dropLast(word.count))
        // Protect URL/email/technical tokens and user-authored dictionary entries.
        let token=before.split(whereSeparator:{$0.isWhitespace}).last ?? ""
        guard token.allSatisfy(\.isLetter) else{return nil}
        let feedback=learnWordsEnabled && !proPrivate && pro6FeedbackRevision==TypingProFeedback.revision ? pro6Feedback : TypingProFeedback()
        let choices=VietnameseAutoCorrect.choices(word:word,context:VietnameseAutoCorrect.context(previous),settings:vietnameseAutoCorrect,
              explicitVietnamese:useSmartBilingual && bilingualPreference == .vietnamese,english:SmartTyping.englishSet,known:SmartTyping.vietnameseSet,
              protected:Set(customWords.keys),feedback:feedback)
        guard let choice=choices.first,choice.automatic else{return nil}
        let corrected=EverydayLanguage.accent(choice.text,style:everyday7.accentStyle)
        guard let edit=FastTyping.edit(from:word,to:corrected) else{return nil}
        for _ in 0..<edit.deleteCount{textDocumentProxy.deleteBackward()}
        if !edit.insertion.isEmpty{textDocumentProxy.insertText(edit.insertion)}
        recentWord=corrected
        return AutoCorrectionUndo(document:textDocumentProxy.documentIdentifier,prefix:prefix,original:word,corrected:corrected,after:autoWordAfter ?? "")
    }
    func finishVietnameseCorrection(_ edit:AutoCorrectionUndo?,boundary:String) {
        guard var edit,textDocumentProxy.documentIdentifier==edit.document,
              (textDocumentProxy.documentContextBeforeInput ?? "").hasSuffix(edit.prefix+edit.corrected+boundary),
              (textDocumentProxy.documentContextAfterInput ?? "")==edit.after else{return}
        edit.boundary=boundary;autoCorrectionUndo=edit
    }
    @discardableResult func undoVietnameseCorrection()->Bool {
        guard let edit=autoCorrectionUndo else{return false}
        autoCorrectionUndo=nil
        let proxy=textDocumentProxy
        guard proxy.documentIdentifier==edit.document,(proxy.selectedText?.isEmpty ?? true),
              (proxy.documentContextBeforeInput ?? "").hasSuffix(edit.prefix+edit.corrected+edit.boundary),
              (proxy.documentContextAfterInput ?? "")==edit.after else{return false}
        let snapshot=proSnapshot();defer{recordProEdit(snapshot)}
        resetAutoWord();resetPhraseContext();resetBilingualComposition()
        for _ in edit.corrected+edit.boundary{proxy.deleteBackward()}
        proxy.insertText(edit.original)
        if learnWordsEnabled,!proPrivate,!KeyboardSettings.privateTypingMode {
            if pro6FeedbackRevision != TypingProFeedback.revision{pro6Feedback=TypingProFeedback.current;pro6FeedbackRevision=TypingProFeedback.revision}
            pro6Feedback.record(source:edit.original,target:edit.corrected,accept:false)
            TypingProFeedback.current=pro6Feedback
        }
        recentWord=edit.original;knownWordBoundary=false;updateCandidates();tactileFeedback()
        return true
    }
}
