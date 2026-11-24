import UIKit

extension KeyboardViewController {
    // Session-only counts of key hits in the keyboard's expanded gutter.
    // No text sequences, coordinates, or per-key statistics are persisted.
    func recordPremiumTouch(_ sender: UIButton) {
        guard premiumPreferences.dynamicTouch, adaptiveTouchEnabled, !performanceMode, !KeyboardSettings.privateTypingMode,
              let key = sender as? AdaptiveKeyButton else { return }
        // Use only the existing gap and never expand beyond its midpoint.
        let id = String(ObjectIdentifier(key).hashValue)
        let count = min(20,(premiumTouchCounts[id] ?? 0)+1)
        premiumTouchCounts[id] = count
        let maximum = CGFloat(min(4, KeyboardSettings.keySpacing / 2))
        key.horizontalHitExpansion = min(maximum, 1 + CGFloat(count) * 0.15)
    }
    func premiumDeleteWord() {
        guard (textDocumentProxy.selectedText?.isEmpty ?? true),
              textDocumentProxy.documentContextAfterInput?.first?.isLetter != true,
              let before = textDocumentProxy.documentContextBeforeInput else { showStatus("Không đủ ngữ cảnh để xóa an toàn."); return }
        let reversed = before.reversed()
        let spaces = reversed.prefix(while: { $0.isWhitespace }).count
        let letters = reversed.dropFirst(spaces).prefix(while: { $0.isLetter || $0.isNumber }).count
        guard letters > 0, spaces + letters <= 80 else { return }
        beginTyping()
        for _ in 0..<(spaces+letters) { textDocumentProxy.deleteBackward() }
        resetBilingualComposition(); recentWord = ""; updateCandidates()
    }
    func premiumSelectionMenu() -> UIMenu {
        UIMenu(title:"Văn bản · giới hạn iOS",children:[
            UIAction(title:"Xem đoạn đã chọn") { [weak self] _ in
                guard let self else { return }; self.closeIntelligenceHub()
                guard let selected = self.textDocumentProxy.selectedText, !selected.isEmpty else { self.showStatus("Bôi đen văn bản bằng menu iOS trước."); return }
                self.show([ReplySuggestion(tone:"Đã chọn",text:selected)])
            },
            UIAction(title:"Viết lại đoạn đã chọn") { [weak self] _ in
                guard let self else { return }; self.closeIntelligenceHub()
                guard let selected = self.textDocumentProxy.selectedText, !selected.isEmpty else { self.showStatus("Bôi đen văn bản trước."); return }
                self.runPremiumAI(title:"Viết lại",source:selected,steps:["suachinh"])
            },
            UIAction(title:"Đầu từ trước con trỏ") { [weak self] _ in
                guard let self else { return }; self.closeIntelligenceHub()
                let word = (self.textDocumentProxy.documentContextBeforeInput ?? "").reversed().prefix(while: { $0.isLetter }).count
                self.beginTyping(); self.resetBilingualComposition()
                self.textDocumentProxy.adjustTextPosition(byCharacterOffset:-word)
                self.recentWord = ""; self.updateCandidates()
            },
            UIAction(title:"Cuối từ sau con trỏ") { [weak self] _ in
                guard let self else { return }; self.closeIntelligenceHub()
                let word = (self.textDocumentProxy.documentContextAfterInput ?? "").prefix(while: { $0.isLetter }).count
                self.beginTyping(); self.resetBilingualComposition()
                self.textDocumentProxy.adjustTextPosition(byCharacterOffset:word)
                self.recentWord = ""; self.updateCandidates()
            }
        ])
    }
}
