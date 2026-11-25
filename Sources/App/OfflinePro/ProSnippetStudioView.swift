import SwiftUI

struct ProSnippetStudioView:View{
    @State private var snippets=OfflineProStore.snippets
    @State private var signatures=OfflineProStore.signatures
    @State private var trigger=";"
    @State private var value=""
    @State private var folder="Cá nhân"
    @State private var profile="All"
    @State private var editID:String?
    @State private var signature=""
    @State private var status=""
    var body:some View{
        VStack(alignment:.leading,spacing:12){
            Text("Text Expander Pro").font(.title.bold())
            Text("Gõ ;tên rồi dấu cách để mở rộng. Biến {{ngay}}, {{gio}}, {{ten}} và biến đã tạo. Chỉ khớp token đầy đủ ở cuối từ. Không lưu mã OTP hoặc bí mật.").font(.caption).foregroundStyle(.secondary)
            TextField("Phím tắt",text:$trigger).textFieldStyle(.roundedBorder).textInputAutocapitalization(.never).autocorrectionDisabled()
            TextField("Thư mục",text:$folder).textFieldStyle(.roundedBorder)
            Picker("Hồ sơ",selection:$profile){Text("Tất cả").tag("All");ForEach(Array(Set(OfflineProStore.profiles.map(\.name)+["Daily"])).sorted(),id:\.self){Text($0)}}
            TextEditor(text:$value).frame(minHeight:110)
            Button(editID==nil ? "Lưu snippet" : "Cập nhật"){save()}.buttonStyle(.borderedProminent)
            ForEach(snippets){item in
                VStack(alignment:.leading,spacing:6){
                    Text(item.trigger+" · "+item.folder+" · "+item.profile).font(.headline)
                    Text(item.value).font(.caption).lineLimit(3)
                    HStack{
                        Button("Sửa"){editID=item.id;trigger=item.trigger;value=item.value;folder=item.folder;profile=item.profile}
                        Spacer()
                        Button(role:.destructive){snippets.removeAll{$0.id==item.id};OfflineProStore.snippets=snippets}label:{Image(systemName:"trash")}
                    }.buttonStyle(.borderless)
                }.padding(10).background(.white.opacity(0.06),in:RoundedRectangle(cornerRadius:10))
            }
            Divider()
            Text("Quick Signature").font(.headline)
            TextEditor(text:$signature).frame(minHeight:80)
            Button("Thêm chữ ký"){
                guard !signature.isEmpty,signature.count<=500,MessageSafety.warnings(in:signature).isEmpty else{status="Chữ ký không hợp lệ.";return}
                signatures.insert(signature,at:0);OfflineProStore.signatures=signatures;signatures=OfflineProStore.signatures;signature=""
            }.buttonStyle(.bordered)
            ForEach(Array(signatures.enumerated()),id:\.offset){i,item in HStack{Text(item).font(.subheadline);Spacer();Button(role:.destructive){signatures.remove(at:i);OfflineProStore.signatures=signatures}label:{Image(systemName:"trash")}}}
            Text(status).font(.caption).foregroundStyle(.orange)
        }
    }
    private func save(){
        let item=ProSnippet(id:editID ?? UUID().uuidString,trigger:trigger,value:value,folder:folder,profile:profile)
        guard item.valid,!KeyboardSettings.privateTypingMode else{status="Phím tắt hoặc nội dung không hợp lệ, hoặc đang riêng tư.";return}
        snippets.removeAll{$0.id==item.id || ($0.trigger==item.trigger && $0.profile==item.profile)}
        snippets.insert(item,at:0);OfflineProStore.snippets=snippets;snippets=OfflineProStore.snippets
        trigger=";";value="";editID=nil;status="Đã lưu."
    }
}
