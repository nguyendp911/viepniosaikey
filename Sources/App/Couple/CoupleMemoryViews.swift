import SwiftUI

private struct CoupleMemoryItem:Codable,Identifiable{
    var id=UUID()
    var date:Date
    var title:String
    var detail:String
}
struct CoupleVaultView:View{
    @State private var items=CouplePrivateStore.read("signature-vault",as:CoupleMemoryItem.self)
    @State private var title=""
    @State private var detail=""
    @State private var date=Date()
    @State private var editing:UUID?
    @State private var status=""
    @State private var search=""
    var body:some View{
        List{
            if KeyboardSettings.privateTypingMode {Text("Kho riêng tư không hiển thị trong chế độ riêng tư.")}
            else{
                Section("Chi tiết bạn chủ động lưu"){
                    Text("Tệp bảo vệ cục bộ, không tự gửi sang AI và không sao lưu cùng dữ liệu bàn phím.").font(.caption)
                    TextField("Tiêu đề",text:$title)
                    DatePicker("Ngày",selection:$date,displayedComponents:.date)
                    TextEditor(text:$detail).frame(minHeight:100)
                    Button(editing==nil ? "Lưu kỷ niệm":"Cập nhật"){save()}
                    if editing != nil{Button("Hủy chỉnh sửa"){reset()}}
                    Text(status).font(.caption)
                }
                Section("Kho kỷ niệm"){
                    ForEach(items.filter{search.isEmpty || $0.title.localizedCaseInsensitiveContains(search) || $0.detail.localizedCaseInsensitiveContains(search)}){item in
                        VStack(alignment:.leading,spacing:7){
                            Text(item.title).font(.headline)
                            Text(item.date.formatted(date:.abbreviated,time:.omitted)).font(.caption)
                            Text(item.detail).font(.subheadline)
                            Button("Sửa"){editing=item.id;title=item.title;detail=item.detail;date=item.date}.buttonStyle(.borderless)
                            NavigationLink("Dùng chi tiết này viết câu chuyện"){ScrollView{CoupleSignatureWritingView(initial:item.title+"\n"+item.detail).padding()}.navigationTitle("Câu chuyện")}
                            Button("Xóa",role:.destructive){persist(items.filter{$0.id != item.id})}.buttonStyle(.borderless)
                        }
                    }
                }
            }
        }.navigationTitle("Memory Vault").searchable(text:$search)
    }
    private func save(){
        let t=title.trimmingCharacters(in:.whitespacesAndNewlines),d=detail.trimmingCharacters(in:.whitespacesAndNewlines)
        guard !t.isEmpty,!d.isEmpty,t.count<=80,d.count<=1500,editing != nil || items.count<200 else{status="Kiểm tra tiêu đề, nội dung hoặc giới hạn 200 mục.";return}
        var next=items
        if let editing,let index=next.firstIndex(where:{$0.id==editing}){next[index].title=t;next[index].detail=d;next[index].date=date}
        else{next.append(.init(date:date,title:t,detail:d))}
        if persist(next){reset()}
    }
    @discardableResult private func persist(_ next:[CoupleMemoryItem])->Bool{
        guard CouplePrivateStore.write(next,name:"signature-vault")else{status="Không ghi được tệp.";return false}
        items=next;status="Đã cập nhật kho.";return true
    }
    private func reset(){editing=nil;title="";detail="";date=Date()}
}
struct CoupleTimelineView:View{
    @State private var items=CouplePrivateStore.read("signature-vault",as:CoupleMemoryItem.self)
    var body:some View{
        List{
            if KeyboardSettings.privateTypingMode {Text("Đang riêng tư.")}
            else{
                NavigationLink("Thêm / chỉnh sửa kỷ niệm"){CoupleVaultView()}
                if items.isEmpty{Text("Chưa có kỷ niệm được lưu.").font(.caption)}
                ForEach(items.sorted{$0.date>$1.date}){item in
                    VStack(alignment:.leading,spacing:6){
                        Label(item.date.formatted(date:.abbreviated,time:.omitted),systemImage:"calendar").font(.caption).foregroundStyle(.pink)
                        Text(item.title).font(.headline);Text(item.detail).font(.subheadline)
                    }
                }
            }
        }.navigationTitle("Relationship Timeline").onAppear{items=CouplePrivateStore.read("signature-vault",as:CoupleMemoryItem.self)}
    }
}
