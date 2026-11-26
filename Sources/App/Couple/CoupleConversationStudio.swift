import SwiftUI
import PhotosUI
import UIKit

struct CoupleConversationStudio:View {
    var initial:String=""
    var conflict=false
    @State private var source=""
    @State private var style=KeyboardSettings.coupleStyle
    @State private var replies:[ReplySuggestion]=[]
    @State private var reading:CoupleLocalEngine.Reading?
    @State private var status=""
    @State private var busy=false
    @State private var request:Task<Void,Never>?
    @State private var confirmCloud=false
    @State private var cloudSource=""
    @State private var cloudOptions:CoupleRequestOptions?
    @State private var selectedTurn:Int?
    @State private var goal:CoupleReplyGoal = .natural
    @State private var round=0
    @State private var prefs=CoupleStudioPreferences.current
    @State private var includeExistingContext=false
    @State private var usedCloud=false
    private var target:CoupleTurn? {CoupleTranscript.target(source,selected:selectedTurn)}
    private var excerpt:String? {CoupleTranscript.excerpt(source,selected:selectedTurn)}
    private var options:CoupleRequestOptions {
        .init(goal:goal,style:style,address:KeyboardSettings.coupleAddress,preferences:prefs,includeExistingContext:includeExistingContext)
    }
    @State private var picker:PhotosPickerItem?
    @State private var lines:[OCRChatLine]=[]
    @State private var ticket=UUID()
    @State private var ocrBusy=false
    var body:some View {
        VStack(alignment:.leading,spacing:13){
            Text(conflict ? "Cùng tìm cách nói chuyện rõ ràng hơn":"Hội thoại theo ngữ cảnh").font(.title2.bold())
            Text("Dán đoạn hội thoại, hoặc nhập từng dòng với nhãn Tôi: / Đối phương:. Kiểm tra người nói trước khi tạo phản hồi. Không tự đọc ứng dụng nhắn tin.").font(.caption).foregroundStyle(.secondary)
            TextEditor(text:$source).frame(minHeight:130).accessibilityIdentifier("couple.conversation.input")
                .overlay{RoundedRectangle(cornerRadius:8).strokeBorder(.white.opacity(0.15))}
            PhotosPicker("Đọc ảnh hội thoại (OCR offline)",selection:$picker,matching:.images).buttonStyle(.bordered)
                .onChange(of:picker){if let item=$0{read(item)}}
            if ocrBusy{ProgressView()}
            ForEach($lines){$line in
                VStack(alignment:.leading,spacing:5){
                    Text(line.text).font(.caption)
                    Text("Vị trí: "+line.alignment+" · xác nhận thủ công").font(.caption2).foregroundStyle(.secondary)
                    Picker("Vai trò",selection:$line.speaker){Text("Bỏ qua").tag("skip");Text("Tôi").tag("me");Text("Đối phương").tag("other");Text("Chưa rõ").tag("unknown")}.pickerStyle(.segmented)
                }
            }
            if !lines.isEmpty{
                Button("Dùng các dòng đã xác nhận"){
                    source=lines.filter{$0.speaker=="me" || $0.speaker=="other"}.map{($0.speaker=="me" ? "Tôi: ":"Đối phương: ")+$0.text}.joined(separator:"\n")
                    lines=[]
                }.buttonStyle(.bordered)
            }
            if !source.isEmpty {
                Picker("Tin nhắn cần trả lời",selection:$selectedTurn){
                    Text("Tin cuối (tự chọn)").tag(nil as Int?)
                    ForEach(CoupleTranscript.turns(source).filter{$0.speaker=="other" || $0.speaker=="unlabeled"}){turn in
                        Text(String(turn.text.prefix(75))).tag(Optional(turn.id))
                    }
                }
                if let target {
                    Text("Đang trả lời: "+target.text).font(.subheadline).padding(10)
                        .frame(maxWidth:.infinity,alignment:.leading).background(.white.opacity(0.06),in:RoundedRectangle(cornerRadius:10))
                }else{Text("Tin cuối là của bạn hoặc chưa rõ người nói. Chọn tin nhận được.").font(.caption).foregroundStyle(.orange)}
            }
            Picker("Mục đích",selection:$goal){ForEach(CoupleReplyGoal.allCases){Text($0.title).tag($0)}}
            Picker("Phong cách",selection:$style){ForEach(CoupleStyleCatalog.styles){Text($0.title).tag($0.id)}}
            DisclosureGroup("Tinh chỉnh riêng cho lượt này"){
                Toggle("Tùy chỉnh cảm xúc",isOn:$prefs.customEmotion)
                if prefs.customEmotion{
                    toneSlider("Lạnh lùng",value:$prefs.cold)
                    toneSlider("Tổn thương",value:$prefs.hurt)
                    toneSlider("Dịu dàng",value:$prefs.warmth)
                    Picker("Độ dài",selection:$prefs.length){Text("Ngắn").tag("short");Text("Vừa").tag("medium");Text("Dài").tag("long")}
                    Toggle("Emoji",isOn:$prefs.emoji)
                }
            }
            Toggle("Dùng thêm lịch sử & ghi chú AI đã cho phép",isOn:$includeExistingContext).font(.caption)
            Text("Mặc định chỉ gửi đoạn hội thoại đã chọn, không gửi thêm lịch sử hay ghi chú cũ. Vai trò người nhận đã thiết lập vẫn được tôn trọng.").font(.caption2).foregroundStyle(.secondary)
            HStack{
                Button("Phản hồi offline"){generateLocal()}.buttonStyle(.borderedProminent).accessibilityIdentifier("couple.conversation.offline")
                Button("Dùng AI hiện có"){
                    prepareCloud()
                }.buttonStyle(.bordered).disabled(busy || !KeyboardSettings.allowCloudAI || KeyboardSettings.privateTypingMode)
            }.disabled(excerpt==nil || ocrBusy)
            if !source.isEmpty {Button("Ẩn dữ liệu nhạy cảm"){source=MessageSafety.redacted(source)}.font(.caption)}
            if busy{ProgressView();Button("Hủy"){request?.cancel();busy=false}}
            if let reading{
                VStack(alignment:.leading,spacing:5){
                    Text("Chủ đề: "+reading.topic).font(.headline)
                    Text(reading.evidence).font(.subheadline)
                    Text(reading.caution).font(.caption).foregroundStyle(.secondary)
                }.padding(12).frame(maxWidth:.infinity,alignment:.leading).background(.white.opacity(0.06),in:RoundedRectangle(cornerRadius:12))
            }
            if !replies.isEmpty && !busy {
                HStack{
                    Button("Câu khác"){if usedCloud{prepareCloud()}else{generateLocal(another:true)}}.buttonStyle(.bordered)
                    Button("Ngắn hơn"){prefs.customEmotion=true;prefs.length="short";generateLocal()}.buttonStyle(.bordered)
                }
                Button("Dịu dàng hơn"){prefs.customEmotion=true;prefs.warmth=min(100,prefs.warmth+25);prefs.cold=max(0,prefs.cold-25);generateLocal()}.buttonStyle(.bordered)
                Text("Tinh chỉnh nhanh dùng offline; tạo lại bằng AI cần xác nhận gửi.").font(.caption2).foregroundStyle(.secondary)
            }
            ForEach(replies){reply in CoupleReplyCard(reply:reply,style:style,status:$status)}
            if !status.isEmpty{Text(status).font(.caption).foregroundStyle(.secondary)}
        }.onAppear{if source.isEmpty{source=initial};if conflict{style="reconcile"}}
            .onChange(of:source){_ in selectedTurn=nil;resetResults()}
            .onChange(of:selectedTurn){_ in resetResults()}
            .onChange(of:style){_ in resetResults()}
            .onChange(of:goal){_ in resetResults()}
            .onDisappear{request?.cancel();ticket=UUID()}
            .alert("Gửi văn bản đã chọn đến AI?",isPresented:$confirmCloud){
                Button("Gửi"){if let cloudOptions{generateCloud(cloudSource,options:cloudOptions)}}
                Button("Hủy",role:.cancel){}
            }message:{Text("Sử dụng nhà cung cấp AI đã cấu hình. Kiểm tra đoạn hội thoại và tùy chọn lịch sử trước khi gửi.\n\n"+cloudSource)}
    }
    private func resetResults(){
        request?.cancel();busy=false;replies=[];reading=nil;round=0
    }
    private func toneSlider(_ label:String,value:Binding<Int>)->some View {
        VStack(alignment:.leading){
            Text(label+" · "+String(value.wrappedValue)+"%").font(.caption)
            Slider(value:Binding(get:{Double(value.wrappedValue)},set:{value.wrappedValue=Int($0)}),in:0...100,step:5)
        }
    }
    private func prepareCloud(){
        guard let excerpt else{status="Chọn tin nhận được hợp lệ.";return}
        cloudSource=excerpt;cloudOptions=options;confirmCloud=true
    }
    private func generateLocal(another:Bool=false){
        guard let excerpt,let target else{return}
        request?.cancel();busy=false;usedCloud=false
        round=another ? (round+1)%1000 : 0
        reading=CoupleLocalEngine.reading(excerpt)
        let context=ConversationContextResolver.resolve(target.text)
        if let family=ConversationContextResolver.offlineFamilyReplies(for:target.text,context:context){replies=family}
        else if !context.romanticInstructionsAllowed{replies=OfflineReplyEngine.suggest(for:target.text)}
        else {
            let old=Set(replies.map(\.text))
            let next=CoupleLocalEngine.replyPool(excerpt,style:style,address:KeyboardSettings.coupleAddress,preferences:prefs,goal:goal,round:round)
            replies=next
            if another && old==Set(next.map(\.text)){status="Kho offline hiện không còn lựa chọn mới cho tình huống này.";return}
        }
        status="Gợi ý offline · chọn và chỉnh lại theo ý bạn."
    }
    private func generateCloud(_ input:String,options:CoupleRequestOptions){
        guard !KeyboardSettings.privateTypingMode,MessageSafety.warnings(in:input).isEmpty else{status="Hãy ẩn thông tin nhạy cảm trước khi gửi.";return}
        guard KeyboardSettings.coupleEnabled else{status="Bật Couple trong thiết lập để sử dụng AI.";return}
        request?.cancel();busy=true;reading=CoupleLocalEngine.reading(input)
        request=Task{@MainActor in
            do{
                let result=try await AIService.reply(to:input,coupleOptions:options)
                guard !Task.isCancelled else{return}
                replies=result;usedCloud=true;status="Đã tạo bằng AI hiện có."
            }catch{guard !Task.isCancelled else{return};status=error.localizedDescription}
            busy=false
        }
    }
    private func read(_ item:PhotosPickerItem){
        let id=UUID();ticket=id;ocrBusy=true;lines=[]
        Task{@MainActor in
            do{
                guard let data=try await item.loadTransferable(type:Data.self)else{throw AIServiceError.invalidResponse}
                let result=try await ScreenshotStudioOCR.read(data)
                guard id==ticket else{return};lines=result
                status="Đã đọc \(result.count) dòng. Xác nhận người nói, không suy ra từ vị trí."
            }catch{if ticket==id{status=error.localizedDescription}}
            if ticket==id{ocrBusy=false}
        }
    }
}
struct CoupleReplyCard:View {
    let reply:ReplySuggestion
    let style:String
    @Binding var status:String
    @State private var draft=""
    var body:some View {
        VStack(alignment:.leading,spacing:8){
            Text(reply.tone).font(.caption.bold()).foregroundStyle(.pink)
            TextField("Tin nhắn",text:$draft,axis:.vertical).font(.subheadline)
            ForEach(CoupleLocalEngine.guardian(draft),id:\.self){Text($0).font(.caption).foregroundStyle(.orange)}
            HStack{
                Button("Sao chép"){UIPasteboard.general.string=draft;status="Đã sao chép."}.buttonStyle(.bordered)
                Button("Lưu yêu thích"){
                    guard !KeyboardSettings.privateTypingMode,!draft.isEmpty,draft.count<=500,MessageSafety.warnings(in:draft).isEmpty else{status="Không lưu trong riêng tư hoặc khi có thông tin nhạy cảm.";return}
                    var items=KeyboardSettings.favoriteReplies
                    guard !items.contains(draft)else{status="Câu đã được lưu.";return}
                    items.insert(draft,at:0);KeyboardSettings.favoriteReplies=items
                    CouplePersonalDNA.record(draft,style:style);status="Đã lưu vào kho yêu thích."
                }.buttonStyle(.bordered)
            }
        }.padding(12).background(.white.opacity(0.055),in:RoundedRectangle(cornerRadius:12)).onAppear{draft=reply.text}
    }
}
struct CoupleLibraryStudio:View{
    @State private var items=KeyboardSettings.favoriteReplies
    @State private var status=""
    var body:some View{
        List{
            if KeyboardSettings.privateTypingMode {
                Text("Đang riêng tư · không hiển thị kho câu đã lưu.")
            }else{
            Section("Câu yêu thích hiện có"){
                ForEach(Array(items.enumerated()),id:\.offset){index,item in
                    HStack{
                        Text(item).font(.subheadline);Spacer()
                        Button{UIPasteboard.general.string=item;status="Đã sao chép."}label:{Image(systemName:"doc.on.doc")}.buttonStyle(.borderless)
                        Button(role:.destructive){items.remove(at:index);KeyboardSettings.favoriteReplies=items}label:{Image(systemName:"trash")}.buttonStyle(.borderless)
                    }
                }
                if items.isEmpty{Text("Chưa có câu yêu thích. Lưu từ màn hình Hội thoại.").font(.caption)}
                Text(status).font(.caption)
            }
            }
        }
    }
}
