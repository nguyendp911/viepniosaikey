import UIKit

/// In-memory single edit only. Do not attempt to undo arbitrary host typing.
struct StudioEdit {
    let document: UUID
    let before: String
    let after: String
    let original: String
    let replacement: String
    var applied: Bool
}

extension KeyboardViewController {
    func insertTrackedStudioText(_ answer: String) {
        studioEdit = nil
        let proxy = textDocumentProxy
        let original = proxy.selectedText ?? ""
        let before = proxy.documentContextBeforeInput
        let after = proxy.documentContextAfterInput
        proxy.insertText(answer)
        resetBilingualComposition()
        recentWord = ""
        updateCandidates()
        guard let before, let after, answer.count <= 500, original.count <= 500,
              proxy.documentContextBeforeInput?.hasSuffix(before + answer) == true,
              proxy.documentContextAfterInput == after else { return }
        studioEdit = StudioEdit(document: proxy.documentIdentifier, before: before, after: after,
                                original: original, replacement: answer, applied: true)
    }

    func undoStudioEdit() {
        guard var edit = studioEdit, edit.applied else { undoWordCorrection(); return }
        guard validate(edit, current: edit.replacement) else {
            studioEdit = nil; showStatus("Văn bản đã đổi hoặc iOS không cung cấp đủ ngữ cảnh."); return
        }
        for _ in edit.replacement { textDocumentProxy.deleteBackward() }
        if !edit.original.isEmpty { textDocumentProxy.insertText(edit.original) }
        edit.applied = false
        studioEdit = edit
        showStatus("Đã hoàn tác chỉnh sửa ViePN.")
    }

    func redoStudioEdit() {
        guard var edit = studioEdit, !edit.applied, validate(edit, current: edit.original) else {
            studioEdit = nil; showStatus("Không có chỉnh sửa có thể làm lại an toàn."); return
        }
        for _ in edit.original { textDocumentProxy.deleteBackward() }
        textDocumentProxy.insertText(edit.replacement)
        edit.applied = true
        studioEdit = edit
        showStatus("Đã làm lại chỉnh sửa ViePN.")
    }

    private func validate(_ edit: StudioEdit, current: String) -> Bool {
        let proxy = textDocumentProxy
        return proxy.documentIdentifier == edit.document
            && (proxy.selectedText?.isEmpty ?? true)
            && proxy.documentContextBeforeInput == edit.before + current
            && proxy.documentContextAfterInput == edit.after
    }
}
