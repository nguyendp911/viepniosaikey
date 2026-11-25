import SwiftUI

struct PersonalMemoryStudioView:View {
    let mode:String
    @State private var records=PersonalMemoryStore.all
    @State private var people=PersonaStore.all
    @State private var scope=PersonaStore.activeID
    @State private var kind="Sở thích"
    @State private var title=""
    @State private var detail=""
    @State private var date=Date()
    @State private var editID:String?
    @State private var selected=Set<String>()
    @State private var input=""
    @State private var result=""
    @State private var status=""
    @State private var busy=false
    @State private var work:Task<Void,Never>?
    @State private var newPerson=""
    @State private var newAddress=""
    @State private var newTone=""
    @State private var clearConfirm=false
    private var entries:[PersonalMemory] {
        let items=PersonalMemoryStore.scoped(records,personaID:scope)
        return mode=="timeline" ? items.filter{["Kỷ niệm","Lời hứa","Sự kiện"].contains($0.kind)} : items
    }
    var body:some View {
        VStack(alignment:.leading,spacing:12) {
            Text(mode=="timeline" ? "Relationship Timeline" : mode=="address" ? "Smart Address Book" : "Second Brain").font(.title.bold())
            Text("Dữ liệu tự nhập, lưu trong App Group với bảo vệ tệp của iOS; không đồng bộ cloud. Chỉ các mục được đánh dấu mới dùng làm bối cảnh AI.").font(.caption).foregroundStyle(.secondary)
            if mode=="address" {
                TextField("Tên hồ sơ mới",text:$newPerson).textFieldStyle(.roundedBorder)
                TextField("Cách tự xưng",text:$newAddress).textFieldStyle(.roundedBorder)
                TextField("Giọng điệu",text:$newTone).textFieldStyle(.roundedBorder)
                Button("Tạo hồ sơ") {
                    guard !KeyboardSettings.privateTypingMode,!newPerson.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty,MessageSafety.warnings(in:newPerson+" "+newAddress+" "+newTone).isEmpty else {status="Tên không hợp lệ hoặc đang riêng tư.";return}
                    let id=UUID().uuidString
                    let person=RecipientPersona(id:id,name:String(newPerson.prefix(36)),recipient:"auto",selfAddress:String(newAddress.prefix(30)),tone:String(newTone.prefix(80)))
                    PersonaStore.all=[person]+PersonaStore.all;people=PersonaStore.all;scope=id;newPerson="";newAddress="";newTone=""
                }.buttonStyle(.bordered)
            }
            Picker("Hồ sơ",selection:$scope){
                Text("Cá nhân (không gắn hồ sơ)").tag("")
                ForEach(people){Text($0.name).tag($0.id)}
            }.onChange(of:scope){_ in selected=[];reset()}
            if mode=="address",let person=people.first(where:{$0.id==scope}){
                LabeledContent("Xưng hô",value:person.selfAddress)
                LabeledContent("Giọng điệu",value:person.tone)
                Button("Dùng hồ sơ trên bàn phím"){PersonaStore.select(person.id);status="Đã chọn hồ sơ."}.buttonStyle(.bordered)
            }
            Picker("Loại",selection:$kind){ForEach(mode=="timeline" ? ["Kỷ niệm","Lời hứa","Sự kiện"] : PersonalMemoryStore.kinds,id:\.self){Text($0)}}
            TextField("Tiêu đề",text:$title).textFieldStyle(.roundedBorder)
            TextEditor(text:$detail).frame(minHeight:90)
            DatePicker("Ngày",selection:$date,displayedComponents:[.date])
            Button(editID==nil ? "Lưu bộ nhớ" : "Cập nhật"){save()}.buttonStyle(.borderedProminent)
            if editID != nil {Button("Hủy sửa"){reset()}}
            ForEach(entries){entry in
                VStack(alignment:.leading,spacing:5){
                    HStack{
                        if mode=="memory" {
                            Button{if selected.contains(entry.id){selected.remove(entry.id)}else if selected.count<6{selected.insert(entry.id)}}label:{Image(systemName:selected.contains(entry.id) ? "checkmark.circle.fill" : "circle")}
                        }
                        Text(entry.title).bold();Spacer()
                        Text(entry.date,style:.date).font(.caption2).foregroundStyle(.secondary)
                    }
                    Text(entry.kind).font(.caption).foregroundStyle(.cyan)
                    Text(entry.detail).font(.subheadline)
                    HStack{
                        Button("Sửa"){editID=entry.id;kind=entry.kind;title=entry.title;detail=entry.detail;date=entry.date}
                        Spacer()
                        Button(role:.destructive){let remaining=records.filter{$0.id != entry.id};if PersonalMemoryStore.save(remaining){records=remaining;selected.remove(entry.id)}else{status="Không xóa được."}}label:{Image(systemName:"trash")}
                    }.buttonStyle(.borderless)
                }.padding(10).background(.white.opacity(0.06),in:RoundedRectangle(cornerRadius:12))
            }
            if mode=="memory" {
                Divider()
                Text("Bối cảnh AI · \(selected.count)/6").font(.headline)
                let context=PersonalMemoryStore.context(records,selected:selected,personaID:scope)
                Text(context.isEmpty ? "Chưa chọn dữ kiện" : context).font(.caption).foregroundStyle(.secondary)
                TextEditor(text:$input).frame(minHeight:100)
                HStack{
                    Button(busy ? "Đang xử lý…" : "Gửi câu hỏi + bộ nhớ đã chọn"){run(context)}.buttonStyle(.borderedProminent).disabled(busy || context.isEmpty)
                    if busy{Button("Hủy"){work?.cancel();busy=false}}
                }
                if !result.isEmpty{TextEditor(text:$result).frame(minHeight:120);PersonalResultActions(text:result,status:$status)}
            }
            Text(status).font(.caption).foregroundStyle(.orange)
            Button("Xóa toàn bộ bộ nhớ 3.0",role:.destructive){clearConfirm=true}.buttonStyle(.bordered)
        }.onAppear{if mode=="timeline"{kind="Kỷ niệm"};if !people.contains(where:{$0.id==scope}){scope=""}}
            .onDisappear{work?.cancel()}
            .alert("Xóa toàn bộ bộ nhớ?",isPresented:$clearConfirm){
                Button("Xóa",role:.destructive){if PersonalMemoryStore.clear(){records=[];selected=[];reset()}else{status="Không xóa được."}}
                Button("Hủy",role:.cancel){}
            }
    }
    private func reset(){title="";detail="";editID=nil;date=Date()}
    private func save(){
        let item=PersonalMemory(id:editID ?? UUID().uuidString,personaID:scope,kind:kind,title:title.trimmingCharacters(in:.whitespacesAndNewlines),detail:detail,date:date)
        let updated=[item]+records.filter{$0.id != item.id}
        if PersonalMemoryStore.save(updated){records=updated;reset();status="Đã lưu."}else{status="Không lưu được: nội dung, giới hạn hoặc quyền App Group."}
    }
    private func run(_ context:String){
        guard KeyboardSettings.allowCloudAI,!context.isEmpty,!input.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty,MessageSafety.warnings(in:input+"\n"+context).isEmpty else{status="Kiểm tra nội dung và AI online.";return}
        let source="Tin nhắn:\n"+String(input.prefix(1800))+"\nDữ kiện do người dùng chọn:\n"+context
        let provider=KeyboardSettings.provider
        busy=true;result="";status=""
        work=Task{@MainActor in
            defer{if !Task.isCancelled{busy=false}}
            do{let value=try await AIWritingService.studio(source,instruction:PersonalIntelligenceCatalog.task("memory")!.instruction,provider:provider);if !Task.isCancelled{result=value}}
            catch{if !Task.isCancelled{status=error.localizedDescription}}
        }
    }
}
