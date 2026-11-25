import SwiftUI

struct CoupleWritingStudio:View {
    @State private var kind="rewrite"
    @State private var draft=""
    @State private var style=KeyboardSettings.coupleStyle
    @State private var results:[ReplySuggestion]=[]
    @State private var status=""
    var body:some View {
        VStack(alignment:.leading,spacing:14){
            Picker("Nội dung",selection:$kind){
                Text("Viết lại").tag("rewrite");Text("Mở đầu").tag("starter");Text("Viết tiếp").tag("continue");Text("Thư / lời chúc").tag("letter")
            }.pickerStyle(.segmented)
            Text("Offline tạo từ mẫu và giữ ý gốc khi viết lại. Không tự bịa kỷ niệm, sự kiện hay lời hứa.").font(.caption).foregroundStyle(.secondary)
            TextEditor(text:$draft).frame(minHeight:140)
            Picker("Phong cách",selection:$style){ForEach(CoupleStyleCatalog.styles){Text($0.title).tag($0.id)}}
            Button("Tạo lời nhắn"){
                let address=KeyboardSettings.coupleAddress
                let clean=draft.trimmingCharacters(in:.whitespacesAndNewlines)
                let templates:[String]
                switch kind {
                case "starter":templates=["Hôm nay của {you} thế nào?","Có chuyện gì vui muốn kể {me} nghe không?","Khi nào rảnh mình nói chuyện một chút nhé."]
                case "continue":templates=["{me} muốn nói thêm một chút.","{me} muốn nghe suy nghĩ của {you}.","Khi nào thuận tiện, mình nói chuyện rõ hơn nhé."]
                case "letter":templates=["{me} mong {you} luôn có những ngày bình yên. Cảm ơn vì đã dành thời gian đọc những lời này.","{me} muốn gửi {you} những lời chân thành. Mong mình luôn biết lắng nghe và tôn trọng nhau.","Chúc {you} có thật nhiều niềm vui, sức khỏe và những điều tốt đẹp."]
                default:templates=[]
                }
                if kind=="rewrite" {
                    results=["hurt","firm",style].map{ReplySuggestion(tone:CoupleStyleCatalog.selected($0).title,text:CoupleLocalEngine.refine(clean,style:$0,address:address))}
                }else{
                    results=templates.map{template in
                        let text=CoupleLocalEngine.render(template,address:address)
                        return ReplySuggestion(tone:CoupleStyleCatalog.selected(style).title,text:kind=="continue" ? clean+" "+text:kind=="letter" && !clean.isEmpty ? clean+"\n\n"+text:text)
                    }
                }
            }.buttonStyle(.borderedProminent).disabled((kind=="rewrite" || kind=="continue") && draft.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty)
            ForEach(results){CoupleReplyCard(reply:$0,style:style,status:$status)}
            Text(status).font(.caption)
        }.onChange(of:draft){_ in results=[]}.onChange(of:kind){_ in results=[]}
    }
}
struct CoupleSimulationStudio:View {
    private let scenes=["Hôm nay mình bận, hẹn hôm khác nhé.","Mình đang giận vì có chuyện chưa rõ.","Mình cần không gian riêng một thời gian.","Hôm nay mình rất mệt."]
    @State private var index=0
    @State private var answer=""
    @State private var checked=false
    var body:some View{
        VStack(alignment:.leading,spacing:14){
            Text("Tình huống giả lập").font(.title2.bold())
            Text(scenes[index]).padding(14).frame(maxWidth:.infinity,alignment:.leading).background(.white.opacity(0.07),in:RoundedRectangle(cornerRadius:12))
            TextEditor(text:$answer).frame(minHeight:120)
            Button("Xem phản hồi luyện tập"){checked=true}.buttonStyle(.borderedProminent).disabled(answer.isEmpty)
            if checked{
                let warnings=CoupleLocalEngine.guardian(answer)
                Text(warnings.isEmpty ? "Chưa phát hiện mẫu gây áp lực trong bộ quy tắc. Hãy tự kiểm tra sự chân thành và tính phù hợp.":warnings.joined(separator:"\n")).font(.caption)
                Text("Một vài cách diễn đạt khác").font(.headline)
                ForEach(CoupleLocalEngine.suggest(scenes[index],style:"mature",address:KeyboardSettings.coupleAddress,preferences:.init())){Text($0.text).font(.subheadline)}
            }
            Button("Tình huống tiếp theo"){index=(index+1)%scenes.count;answer="";checked=false}.buttonStyle(.bordered)
        }.onChange(of:answer){_ in checked=false}
    }
}
