import UIKit

extension KeyboardViewController {
    func resetProHangul() { proHangulLast = nil; proHangulDocument = nil }
    func insertProLanguage(_ title: String) {
        let proxy = textDocumentProxy
        if offlineConfig.layout == .hangul, let key = title.first {
            let previous = proHangulDocument == proxy.documentIdentifier &&
                (proxy.selectedText?.isEmpty ?? true) &&
                proxy.documentContextAfterInput?.first?.isLetter != true &&
                proxy.documentContextBeforeInput?.last == proHangulLast ? proHangulLast : nil
            let result = HangulComposer.append(previous: previous, key: key)
            if result.remove { proxy.deleteBackward() }
            proxy.insertText(result.text)
            proHangulLast = result.text.last; proHangulDocument = proxy.documentIdentifier
        } else { proxy.insertText(title); resetProHangul() }
        resetBilingualComposition(); recentWord = ""; knownWordBoundary = false
        if isUppercase && !isShiftLocked { isUppercase = false; updateKeys() }
        updateCandidates(); tactileFeedback()
    }
    func proSnapshot() -> ProTextSnapshot? {
        guard offlineConfig.history, !proPrivate, !performanceMode,
              (textDocumentProxy.selectedText?.isEmpty ?? true),
              let before = textDocumentProxy.documentContextBeforeInput,
              let after = textDocumentProxy.documentContextAfterInput,
              before.count <= 512, after.count <= 512 else { return nil }
        return .init(document:textDocumentProxy.documentIdentifier,before:before,after:after)
    }
    func recordProEdit(_ snapshot: ProTextSnapshot?) {
        guard let snapshot, let current = proSnapshot() else { return }
        if let edit = ProTextEdit.make(snapshot,current) { proHistory.record(edit) }
        else if snapshot != current { proHistory.clear() }
    }
    func applyProHistory(forward: Bool) {
        guard let current = proSnapshot(), let edit = proHistory.take(current:current,forward:forward) else {
            showStatus("Không có bước phù hợp hoặc văn bản đã thay đổi.");return
        }
        beginTyping();resetProHangul();resetBilingualComposition()
        let remove = forward ? edit.removed : edit.inserted
        let insert = forward ? edit.inserted : edit.removed
        for _ in remove { textDocumentProxy.deleteBackward() }
        if !insert.isEmpty { textDocumentProxy.insertText(insert) }
        recentWord = ""; updateCandidates(); showStatus(forward ? "Đã làm lại" : "Đã hoàn tác")
    }
    func moveProWord(forward:Bool) {
        let context = forward ? (textDocumentProxy.documentContextAfterInput ?? "") : String((textDocumentProxy.documentContextBeforeInput ?? "").reversed())
        let spaces = context.prefix(while:{$0.isWhitespace}).count
        let word = context.dropFirst(spaces).prefix(while:{!$0.isWhitespace}).count
        let delta = min(80,spaces+word)
        if delta>0 { textDocumentProxy.adjustTextPosition(byCharacterOffset:forward ? delta : -delta) }
    }
    func installProNumberRow() {
        let row = UIStackView();row.axis = .horizontal;row.distribution = .fillEqually;row.spacing = 4
        for char in "1234567890" {
            let button = keyButton(String(char),action:#selector(proNumberTapped(_:)))
            button.titleLabel?.font = .systemFont(ofSize:15,weight:.semibold)
            row.addArrangedSubview(button)
        }
        proNumberRow = row;proNumberHeight = row.heightAnchor.constraint(equalToConstant:32)
        proNumberHeight?.priority = UILayoutPriority(999);proNumberHeight?.isActive = true
        container.addArrangedSubview(row)
        row.isHidden = !offlineConfig.numberRow
    }
    @objc func proNumberTapped(_ button:UIButton) {
        let snapshot = proSnapshot();defer{recordProEdit(snapshot)}
        beginTyping();resetProHangul();resetBilingualComposition()
        if let text = button.title(for:.normal) { textDocumentProxy.insertText(text) }
        recentWord = ""; updateCandidates();tactileFeedback()
    }
    func installProKeyGesture(_ button:UIButton) {
        let hold = UILongPressGestureRecognizer(target:self,action:#selector(proAlternateHeld(_:)))
        hold.minimumPressDuration = 0.38;hold.cancelsTouchesInView = true;hold.isEnabled = offlineConfig.multiTap
        button.addGestureRecognizer(hold)
        for direction in [UISwipeGestureRecognizer.Direction.up,.down,.left,.right] {
            let swipe = UISwipeGestureRecognizer(target:self,action:#selector(proAlternateSwiped(_:)))
            swipe.direction=direction;swipe.cancelsTouchesInView=true;swipe.isEnabled=offlineConfig.multiTap
            button.addGestureRecognizer(swipe)
        }
    }
    func updateProLayout() {
        proNumberRow?.isHidden = !offlineConfig.numberRow
        proSpaceWidth?.isActive = offlineConfig.wideSpace
        for button in letterButtons {
            button.removeTarget(self,action:#selector(letterTapped(_:)),for:[.touchDown,.touchUpInside])
            button.addTarget(self,action:#selector(letterTapped(_:)),for:offlineConfig.multiTap ? .touchUpInside : .touchDown)
            button.gestureRecognizers?.filter{$0 is UILongPressGestureRecognizer || $0 is UISwipeGestureRecognizer}.forEach{$0.isEnabled=offlineConfig.multiTap}
        }
        updateKeys();updateKeyboardHeight()
    }
    func proAlternate(_ key:String,direction:UISwipeGestureRecognizer.Direction)->String {
        let map:[String:String]=["a":"áàảãạâă","e":"éèẻẽẹê","i":"íìỉĩị","o":"óòỏõọôơ","u":"úùủũụư","y":"ýỳỷỹỵ","d":"đ","q":"1","w":"2","r":"4","t":"5","p":"0"]
        let choices = Array(map[key.lowercased()] ?? "")
        if direction == .up { return choices.first.map(String.init) ?? key.uppercased() }
        if direction == .down { return choices.last.map(String.init) ?? key.lowercased() }
        if direction == .left { return choices.dropFirst().first.map(String.init) ?? "("+key+")" }
        return choices.dropFirst(2).first.map(String.init) ?? key
    }
    @objc func proAlternateSwiped(_ gesture:UISwipeGestureRecognizer) {
        guard gesture.state == .ended,let button=gesture.view as? UIButton,let text=button.title(for:.normal) else{return}
        insertProExplicit(proAlternate(text,direction:gesture.direction))
    }
    @objc func proAlternateHeld(_ gesture:UILongPressGestureRecognizer) {
        guard gesture.state == .began,let button=gesture.view as? UIButton,let text=button.title(for:.normal)else{return}
        let values=[text,proAlternate(text,direction:.up),proAlternate(text,direction:.down),proAlternate(text,direction:.left),proAlternate(text,direction:.right)]
        let (stack,palette)=premiumPanel(title:"Ký tự thay thế")
        for value in Array(Set(values)).sorted() {
            stack.addArrangedSubview(premiumKey(value,palette:palette){[weak self] in self?.closeIntelligenceHub();self?.insertProExplicit(value)})
        }
    }
    func insertProExplicit(_ text:String) {
        let snapshot=proSnapshot();defer{recordProEdit(snapshot)}
        beginTyping();resetProHangul();resetBilingualComposition()
        textDocumentProxy.insertText(text);recentWord="";updateCandidates();tactileFeedback()
    }
    func startProSession() {
        proSessionStart=Date();proSessionTaps=0;prepareProSound()
    }
    func finishProSession() {
        if offlineConfig.analytics && !proPrivate {
            ProTypingStats.add(taps:proSessionTaps,seconds:min(3600,max(1,Date().timeIntervalSince(proSessionStart))))
        }
        proSessionTaps=0
    }
}
