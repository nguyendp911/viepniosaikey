import SwiftUI

struct EverydayPhraseView:View {
    @State private var model=PersonalPhraseModel()
    @State private var query=""
    @State private var pinnedOnly=false
    @State private var editKey:String?
    @State private var draft=""
    @State private var editing=false
    @State private var status=""
    @State private var busy=false
    @State private var deleteKey:String?
    private var rows:[String] {
        model.entries.keys.filter{key in
            (!pinnedOnly || model.entries[key]?.pinned==true) && (query.isEmpty || key.localizedCaseInsensitiveContains(query))
        }.sorted{a,b in
            guard let x=model.entries[a],let y=model.entries[b] else{return a<b}
            if (x.pinned==true) != (y.pinned==true){return x.pinned==true}
            if x.count != y.count{return x.count>y.count}
            return a<b
        }
    }
    var body:some View {
        List{
            Section{
                LabeledContent("Cụm từ",value:String(model.entries.count))
                LabeledContent("Đã ghim",value:String(model.entries.values.filter{$0.pinned==true}.count))
                Toggle("Chỉ cụm từ ghim",isOn:$pinnedOnly)
                Text("Cụm ghim không hết hạn; dữ liệu cá nhân chỉ hiển thị khi không ở chế độ riêng tư. Mỗi cụm gồm 2–9 tiếng.").font(.caption)
                if !status.isEmpty{Text(status).font(.caption).foregroundStyle(.orange)}
            }
            Section{
                ForEach(rows,id:\.self){key in
                    if let item=model.entries[key]{
                        VStack(alignment:.leading,spacing:6){
                            HStack{
                                Text(key).font(.headline)
                                Spacer()
                                Button{mutate{$0.setPinned(key,item.pinned != true)}}label:{Image(systemName:item.pinned==true ? "pin.fill":"pin")}.buttonStyle(.borderless)
                            }
                            Text("\(item.count) lần · "+Date(timeIntervalSince1970:Double(item.day)*86400).formatted(.dateTime.day().month().year())).font(.caption).foregroundStyle(.secondary)
                            HStack{
                                Button("Sửa"){editKey=key;draft=key;editing=true}.buttonStyle(.borderless)
                                Spacer()
                                Button("Xóa",role:.destructive){deleteKey=key}.buttonStyle(.borderless)
                            }
                        }.disabled(busy)
                    }
                }
            }
        }.navigationTitle("Cụm từ cá nhân").searchable(text:$query)
            .toolbar{ToolbarItem(placement:.primaryAction){Button{editKey=nil;draft="";editing=true}label:{Image(systemName:"plus")}.disabled(busy || KeyboardSettings.privateTypingMode)}}
            .task{await refresh()}
            .sheet(isPresented:$editing){
                NavigationStack{Form{
                    TextField("Cụm từ 2–9 tiếng",text:$draft)
                    Button("Lưu"){let old=editKey,value=draft;editing=false;mutate{$0.edit(old,to:value)}}
                }.navigationTitle("Cụm từ").toolbar{ToolbarItem(placement:.cancellationAction){Button("Hủy"){editing=false}}}}
            }.alert("Xóa cụm từ này?",isPresented:Binding(get:{deleteKey != nil},set:{if !$0{deleteKey=nil}})){
                Button("Xóa",role:.destructive){if let key=deleteKey{mutate{$0.remove(key);return true}};deleteKey=nil}
                Button("Hủy",role:.cancel){deleteKey=nil}
            }
    }
    @MainActor private func refresh() async {
        model=await Task.detached(priority:.utility){PersonalPhraseStore.readForManagement()}.value
        if KeyboardSettings.privateTypingMode{status="Đang riêng tư."}
    }
    private func mutate(_ change:@escaping @Sendable (inout PersonalPhraseModel)->Bool) {
        guard !busy else{return};busy=true
        Task{@MainActor in
            let ok=await Task.detached(priority:.utility){PersonalPhraseStore.modify(change)}.value
            await refresh();busy=false;status=ok ? "Đã lưu." : "Không lưu được. Kiểm tra cụm từ, chế độ riêng tư hoặc thử lại khi bàn phím đóng."
        }
    }
}
