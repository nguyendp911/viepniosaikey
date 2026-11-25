import SwiftUI

struct ProFontStudioView:View{
    @State private var source="ViePN Keyboard"
    @State private var status=""
    var body:some View{
        VStack(alignment:.leading,spacing:12){
            Text("Font & Text Studio").font(.title.bold())
            Text("Kiểu chữ Unicode tương thích tùy ứng dụng nhận; giữ nguyên ký tự tiếng Việt không có biến thể tương ứng.").font(.caption).foregroundStyle(.secondary)
            TextEditor(text:$source).frame(minHeight:90)
            ForEach(ProTextTools.modes,id:\.self){mode in
                let text=ProTextTools.stylize(source,mode:mode)
                VStack(alignment:.leading,spacing:6){
                    Text(mode).font(.caption).foregroundStyle(.secondary)
                    Text(text).font(.title3).textSelection(.enabled)
                    PersonalResultActions(text:text,status:$status)
                }.padding(10).frame(maxWidth:.infinity,alignment:.leading).background(.white.opacity(0.06),in:RoundedRectangle(cornerRadius:10))
            }
            Text(status).font(.caption)
        }
    }
}
