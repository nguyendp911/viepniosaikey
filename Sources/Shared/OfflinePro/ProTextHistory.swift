import Foundation

struct ProTextSnapshot: Equatable {
    let document:UUID
    let before:String
    let after:String
}
struct ProTextEdit: Equatable {
    let old:ProTextSnapshot
    let new:ProTextSnapshot
    var removed:String { String(old.before.dropFirst(commonCount)) }
    var inserted:String { String(new.before.dropFirst(commonCount)) }
    private var commonCount:Int { zip(old.before,new.before).prefix(while:{$0.0==$0.1}).count }
    static func make(_ old:ProTextSnapshot,_ new:ProTextSnapshot)->Self? {
        guard old.document==new.document,old.after==new.after,old.before != new.before else{return nil}
        let edit=Self(old:old,new:new)
        guard max(edit.removed.count,edit.inserted.count)<=80 else{return nil}
        return edit
    }
}
struct ProTextHistory {
    private(set) var undo:[ProTextEdit]=[]
    private(set) var redo:[ProTextEdit]=[]
    mutating func record(_ edit:ProTextEdit) {
        if undo.last?.new != edit.old { undo=[] }
        undo.append(edit);if undo.count>30{undo.removeFirst()};redo=[]
    }
    mutating func clear(){undo=[];redo=[]}
    mutating func take(current:ProTextSnapshot,forward:Bool)->ProTextEdit? {
        if forward {
            guard let edit=redo.last,edit.old==current else{clear();return nil}
            redo.removeLast();undo.append(edit);return edit
        }
        guard let edit=undo.last,edit.new==current else{clear();return nil}
        undo.removeLast();redo.append(edit);return edit
    }
}
