import SwiftUI

struct TextDiffStudioView:View {
    @State private var original=""
    @State private var revised=""
    @State private var rows:[PersonalDiff.Row]=[]
    @State private var status=""
    var body:some View {
        VStack(alignment:.leading,spacing:12){
            Text("Text Diff Studio").font(.title.bold())
            Text("So sánh offline theo từ, tối đa 240 từ đầu và 3.000 ký tự mỗi bản. Không phân tích khác biệt chỉ về khoảng trắng.").font(.caption).foregroundStyle(.secondary)
            Text("Bản gốc").font(.headline)
            TextEditor(text:$original).frame(minHeight:100)
            Text("Bản sửa").font(.headline)
            TextEditor(text:$revised).frame(minHeight:100)
            Button("Lấy bản nháp làm bản sửa"){revised=ShareDraft.current}.buttonStyle(.bordered)
            Button("So sánh"){rows=PersonalDiff.compare(original,revised)}.buttonStyle(.borderedProminent)
            if !rows.isEmpty{
                HStack{Label("\(rows.filter{$0.kind=="add"}.count) thêm",systemImage:"plus.circle").foregroundStyle(.green);Spacer();Label("\(rows.filter{$0.kind=="remove"}.count) xóa",systemImage:"minus.circle").foregroundStyle(.red)}.font(.caption)
                Text(rows.reduce(into:AttributedString()){value,row in
                    var token=AttributedString(row.text+" ")
                    if row.kind=="add"{token.foregroundColor = .green;token.backgroundColor = .green.opacity(0.12)}
                    else if row.kind=="remove"{token.foregroundColor = .red;token.strikethroughStyle = .single}
                    value += token
                }).textSelection(.enabled).padding(10).background(.white.opacity(0.05),in:RoundedRectangle(cornerRadius:10))
                PersonalResultActions(text:revised,status:$status)
            }
            Text(status).font(.caption)
        }.onChange(of:original){_ in rows=[]}.onChange(of:revised){_ in rows=[]}
    }
}
