import SwiftUI

struct ToolStudioSettingsView:View{
    @State private var prefs=ToolStudioPreferences.current
    @State private var query=""
    var body:some View{
        List{
            Section("Workspace"){
                Picker("Bộ công cụ",selection:$prefs.workspace){
                    Text("Cá nhân").tag("personal");Text("Công việc").tag("work");Text("Tình cảm").tag("couple")
                }
                Toggle("Gợi ý công cụ theo văn bản đang chọn",isOn:$prefs.contextual)
                Text("Ghim tối đa 6 công cụ cho mỗi workspace. Không thêm nút toolbar; chỉ thay hàng truy cập nhanh trong Tool Studio.").font(.caption)
                Button("Khôi phục ghim mặc định"){prefs.pins.removeValue(forKey:prefs.workspace)}
            }
            ForEach(ToolStudioCatalog.sections.indices,id:\.self){index in
                let section=ToolStudioCatalog.sections[index]
                Section(section.0){
                    ForEach(section.1.filter{ToolStudioCatalog.matches($0,query:query)},id:\.self){name in
                        Button{toggle(name)}label:{
                            HStack{Text(name).foregroundStyle(.primary);Spacer();Image(systemName:prefs.favorites.contains(name) ? "pin.fill":"pin").foregroundStyle(.mint)}
                        }.disabled(!prefs.favorites.contains(name) && prefs.favorites.count>=6)
                    }
                }
            }
        }.navigationTitle("Tool Studio").searchable(text:$query)
            .onChange(of:prefs){ToolStudioPreferences.current=$0}
    }
    private func toggle(_ name:String){
        var items=prefs.favorites
        if items.contains(name){items.removeAll{$0==name}}
        else if items.count<6{items.append(name)}
        prefs.pins[prefs.workspace]=items
    }
}
