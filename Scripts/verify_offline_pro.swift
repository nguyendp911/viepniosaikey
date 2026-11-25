import Foundation

@main
struct VerifyOfflinePro {
    static func main() {
        for layout in ProLayout.allCases { for shift in [false,true] {
            precondition(layout.rows(shift:shift,custom:["qwertyuiop","asdfghjkl","zxcvbnm"]).map(\.count)==[10,9,7])
        }}
        precondition(ProLayout.valid(["qwertyuiop","asdfghjkl","zxcvbnm"]))
        precondition(!ProLayout.valid(["aaaaaaaaaa","asdfghjkl","zxcvbnm"]))
        var text=""
        for key in "ㅎㅏㄴㄱㅜㄱ" {
            let result=HangulComposer.append(previous:text.last,key:key)
            if result.remove{text.removeLast()};text+=result.text
        }
        precondition(text=="한국")
        text=""
        for key in "ㄱㅏㄱㅏ" {
            let result=HangulComposer.append(previous:text.last,key:key)
            if result.remove{text.removeLast()};text+=result.text
        }
        precondition(text=="가가")
        let doc=UUID()
        let a=ProTextSnapshot(document:doc,before:"a",after:"")
        let b=ProTextSnapshot(document:doc,before:"ab",after:"")
        let c=ProTextSnapshot(document:doc,before:"abc",after:"")
        var history=ProTextHistory()
        history.record(ProTextEdit.make(a,b)!);history.record(ProTextEdit.make(b,c)!)
        precondition(history.take(current:c,forward:false)?.inserted=="c")
        precondition(history.take(current:b,forward:false)?.inserted=="b")
        precondition(history.take(current:a,forward:true)?.inserted=="b")
        precondition(history.take(current:c,forward:true)==nil)
        let item=ProSnippet(trigger:";hi",value:"Chào",folder:"Test")
        precondition(item.valid && OfflineProStore.expansion(token:";hi",profile:"Daily",items:[item])=="Chào")
        precondition(OfflineProStore.expansion(token:"hi",profile:"Daily",items:[item])==nil)
        precondition(ProTextTools.clean(" a  b \n a b\nc")=="a b\nc")
        precondition(ProTextTools.encode("abc",mode:"Base64")=="YWJj")
        precondition(ProTextTools.encode("YWJj",mode:"Decode Base64")=="abc")
        precondition(ProTextTools.encode("A",mode:"Binary")=="01000001")
        precondition(ProTextTools.stylize("ABC",mode:"Double Stroke")=="𝔸𝔹ℂ")
        precondition(ProTextTools.table("A|B\n1|2")=="| A | B |\n| --- | --- |\n| 1 | 2 |")
        precondition(ProTextTools.link("https://example.com/?utm_source=x&a=1",utm:"",remove:true)=="https://example.com/?a=1")
        precondition(ProTextTools.link("file:///secret",utm:"",remove:true)==nil)
        print("PASS Offline 4.0: layout, Hangul, guarded history, expansion, Unicode, encoding, tables and links")
    }
}
