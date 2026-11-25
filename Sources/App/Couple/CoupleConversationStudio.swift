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
            Picker("Phong cách",selection:$style){ForEach(CoupleStyleCatalog.styles){Text($0.title).tag($0.id)}}
            HStack{
                Button("Phản hồi offline"){generateLocal()}.buttonStyle(.borderedProminent).accessibilityIdentifier("couple.conversation.offline")
                Button("Dùng AI hiện có"){
                    cloudSource=String(source.prefix(3000));confirmCloud=true
                }.buttonStyle(.bordered).disabled(busy || !KeyboardSettings.allowCloudAI || KeyboardSettings.privateTypingMode)
            }.disabled(source.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty || ocrBusy)
            if !source.isEmpty {Button("Ẩn dữ liệu nhạy cảm"){source=MessageSafety.redacted(source)}.font(.caption)}
            if busy{ProgressView();Button("Hủy"){request?.cancel();busy=false}}
            if let reading{
                VStack(alignment:.leading,spacing:5){
                    Text("Chủ đề: "+reading.topic).font(.headline)
                    Text(reading.evidence).font(.subheadline)
                    Text(reading.caution).font(.caption).foregroundStyle(.secondary)
                }.padding(12).frame(maxWidth:.infinity,alignment:.leading).background(.white.opacity(0.06),in:RoundedRectangle(cornerRadius:12))
            }
            ForEach(replies){reply in CoupleReplyCard(reply:reply,style:style,status:$status)}
            if !status.isEmpty{Text(status).font(.caption).foregroundStyle(.secondary)}
        }.onAppear{if source.isEmpty{source=initial};if conflict{style="reconcile"}}
            .onChange(of:source){_ in request?.cancel();busy=false;replies=[];reading=nil}
            .onDisappear{request?.cancel();ticket=UUID()}
            .alert("Gửi văn bản đã chọn đến AI?",isPresented:$confirmCloud){
                Button("Gửi"){generateCloud(cloudSource)}
                Button("Hủy",role:.cancel){}
            }message:{Text("Sử dụng nhà cung cấp AI đã cấu hình. Hồ sơ/ngữ cảnh đã cho phép trong hệ thống hiện tại có thể được dùng cùng đoạn hội thoại.\n\n"+cloudSource)}
    }
    private func generateLocal(){
        request?.cancel();busy=false
        reading=CoupleLocalEngine.reading(source)
        let context=ConversationContextResolver.resolve(source)
        if let family=ConversationContextResolver.offlineFamilyReplies(for:source,context:context){replies=family}
        else {replies=CoupleLocalEngine.suggest(source,style:style,address:KeyboardSettings.coupleAddress,preferences:CoupleStudioPreferences.current)}
        status="Gợi ý offline · chọn và chỉnh lại theo ý bạn."
    }
    private func generateCloud(_ input:String){
        guard !KeyboardSettings.privateTypingMode,MessageSafety.warnings(in:input).isEmpty else{status="Hãy ẩn thông tin nhạy cảm trước khi gửi.";return}
        guard KeyboardSettings.coupleEnabled else{status="Bật Couple trong Thiết lập Couple hiện tại để sử dụng phong cách đã chọn với AI.";return}
        request?.cancel();busy=true;reading=CoupleLocalEngine.reading(input)
        // Explicitly selected style, using the existing shared preference.
        KeyboardSettings.coupleStyle=style
        request=Task{@MainActor in
            do{
                let result=try await AIService.reply(to:input)
                guard !Task.isCancelled else{return};replies=result;status="Đã tạo bằng AI hiện có."
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
