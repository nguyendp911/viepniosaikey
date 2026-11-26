import UIKit

struct AutoPreviousWord {
    let document:UUID
    let prefix:String
    let word:String
    let after:String
}
struct AutoCorrectionUndo {
    let document:UUID
    let prefix:String
    let original:String
    let corrected:String
    let after:String
    var boundary=""
    var expectedBefore:String?
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
        let previousOwned=autoPreviousWord
        autoPreviousWord=nil
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
        let protected=Set(customWords.keys)
        // Correct the preceding word only when it was also typed in this
        // keyboard session, the exact host context matches and the bigram
        // is one of our explicit patterns.
        if let owned=previousOwned,owned.document==textDocumentProxy.documentIdentifier,
           owned.after==autoWordAfter,previous.hasSuffix(owned.prefix+owned.word+" "),
           let recovered=VietnameseAutoCorrect.pairRecovery(previous:owned.word,current:word,settings:vietnameseAutoCorrect,protected:protected,feedback:feedback),
           let edit=FastTyping.edit(from:owned.word+" "+word,to:recovered) {
            for _ in 0..<edit.deleteCount{textDocumentProxy.deleteBackward()}
            if !edit.insertion.isEmpty{textDocumentProxy.insertText(edit.insertion)}
            let parts=recovered.split(separator:" ").map(String.init)
            recentWord=parts.last ?? word
            // Align existing learning with the actual corrected previous word.
            if phraseChain.last==owned.word.lowercased(),parts.count==2 {
                phraseChain[phraseChain.count-1]=parts[0].lowercased()
                phraseStart=String((owned.prefix+parts[0]+" ").suffix(40))
            }
            if boundary==" ",let current=textDocumentProxy.documentContextBeforeInput {
                autoPreviousWord=AutoPreviousWord(document:owned.document,prefix:String(current.dropLast(recentWord.count).suffix(40)),word:recentWord,after:owned.after)
            }
            return AutoCorrectionUndo(document:owned.document,prefix:owned.prefix,original:owned.word+" "+word,corrected:recovered,after:owned.after)
        }
        let learned=learnWordsEnabled && !proPrivate && phraseRevision==PersonalPhraseStore.revision ? phraseModel : nil
        let choices=VietnameseAutoCorrect.choices(word:word,context:VietnameseAutoCorrect.context(previous),settings:vietnameseAutoCorrect,
              explicitVietnamese:useSmartBilingual && bilingualPreference == .vietnamese,english:SmartTyping.englishSet,known:SmartTyping.vietnameseSet,
              protected:protected,feedback:feedback,learned:learned,accentBuckets:SmartTyping.accentBuckets)
        guard let choice=choices.first,choice.automatic else{
            if boundary==" " {autoPreviousWord=AutoPreviousWord(document:textDocumentProxy.documentIdentifier,prefix:prefix,word:word,after:autoWordAfter ?? "")}
            return nil
        }
        let corrected=EverydayLanguage.accent(choice.text,style:everyday7.accentStyle)
        guard let edit=FastTyping.edit(from:word,to:corrected) else{return nil}
        for _ in 0..<edit.deleteCount{textDocumentProxy.deleteBackward()}
        if !edit.insertion.isEmpty{textDocumentProxy.insertText(edit.insertion)}
        recentWord=corrected
        if boundary==" " {autoPreviousWord=AutoPreviousWord(document:textDocumentProxy.documentIdentifier,prefix:prefix,word:corrected,after:autoWordAfter ?? "")}
        return AutoCorrectionUndo(document:textDocumentProxy.documentIdentifier,prefix:prefix,original:word,corrected:corrected,after:autoWordAfter ?? "")
    }
    func finishVietnameseCorrection(_ edit:AutoCorrectionUndo?,boundary:String) {
        guard var edit,textDocumentProxy.documentIdentifier==edit.document,
              (textDocumentProxy.documentContextBeforeInput ?? "").hasSuffix(edit.prefix+edit.corrected+boundary),
              (textDocumentProxy.documentContextAfterInput ?? "")==edit.after else{return}
        edit.boundary=boundary;edit.expectedBefore=textDocumentProxy.documentContextBeforeInput;autoCorrectionUndo=edit
    }
    @discardableResult func undoVietnameseCorrection()->Bool {
        guard let edit=autoCorrectionUndo else{return false}
        autoCorrectionUndo=nil
        let proxy=textDocumentProxy
        guard proxy.documentIdentifier==edit.document,(proxy.selectedText?.isEmpty ?? true),
              proxy.documentContextBeforeInput==edit.expectedBefore,
              (proxy.documentContextBeforeInput ?? "").hasSuffix(edit.prefix+edit.corrected+edit.boundary),
              (proxy.documentContextAfterInput ?? "")==edit.after else{return false}
        let snapshot=proSnapshot();defer{recordProEdit(snapshot)}
        resetAutoWord();autoPreviousWord=nil;resetPhraseContext();resetBilingualComposition()
        for _ in edit.corrected+edit.boundary{proxy.deleteBackward()}
        proxy.insertText(edit.original)
        if learnWordsEnabled,!proPrivate,!KeyboardSettings.privateTypingMode {
            if pro6FeedbackRevision != TypingProFeedback.revision{pro6Feedback=TypingProFeedback.current;pro6FeedbackRevision=TypingProFeedback.revision}
            let original=edit.original.split(separator:" ").map(String.init)
            let corrected=edit.corrected.split(separator:" ").map(String.init)
            if original.count==corrected.count {
                for (source,target) in zip(original,corrected) where source != target {
                    pro6Feedback.record(source:source,target:target,accept:false)
                }
            }
            TypingProFeedback.current=pro6Feedback
        }
        recentWord=edit.original.split(separator:" ").last.map(String.init) ?? "";knownWordBoundary=false;updateCandidates();tactileFeedback()
        return true
    }
}
