import SwiftUI

struct PremiumAutomationStudioView: View {
    @State private var flows = PremiumStore.workflows
    @State private var macros = PremiumStore.macros
    @State private var title = ""
    @State private var template = ""
    @State private var steps:[String] = []
    @State private var next = "suachinh"
    @State private var macroMode = false
    @State private var editing:String?
    @State private var status = ""
    var body: some View {
        VStack(alignment:.leading,spacing:12) {
            Text("Workflow & Macro").font(.title.bold())
            Text("Workflow chạy tuần tự tối đa 4 yêu cầu AI. Macro có thể chỉ chèn mẫu offline hoặc chạy thêm các bước AI. Mỗi bước cloud có thể sử dụng hạn mức API.").font(.caption).foregroundStyle(.secondary)
            Picker("Loại",selection:Binding(get:{ macroMode },set:{ value in if value != macroMode { reset(); macroMode = value } })) { Text("Workflow").tag(false); Text("Macro").tag(true) }.pickerStyle(.segmented)
            TextField("Tên",text:$title).textFieldStyle(.roundedBorder)
            if macroMode {
                Text("Mẫu · {{ngay}}, {{gio}}, {{ten}}, hoặc biến riêng").font(.caption)
                TextEditor(text:$template).frame(minHeight:100)
            }
            Picker("Thêm bước",selection:$next) {
                ForEach(PremiumCommands.all.filter(\.isAI)) { Text($0.title).tag($0.id) }
            }
            Button("Thêm bước AI") { if steps.count < 4 { steps.append(next) } }.buttonStyle(.bordered).disabled(steps.count >= 4)
            ForEach(steps.indices,id:\.self) { index in
                HStack {
                    Text("\(index+1). "+(PremiumCommands.find(steps[index])?.title ?? steps[index])).font(.subheadline)
                    Spacer()
                    Button { steps.swapAt(index,index-1) } label:{ Image(systemName:"chevron.up") }.disabled(index == 0)
                    Button { steps.swapAt(index,index+1) } label:{ Image(systemName:"chevron.down") }.disabled(index == steps.count-1)
                    Button(role:.destructive) { steps.remove(at:index) } label:{ Image(systemName:"trash") }
                }.buttonStyle(.borderless).padding(8).background(.white.opacity(0.05),in:RoundedRectangle(cornerRadius:8))
            }
            Button(editing == nil ? "Lưu" : "Cập nhật") { save() }.buttonStyle(.borderedProminent)
            if editing != nil { Button("Hủy sửa") { reset() } }
            Text(status).font(.caption).foregroundStyle(.secondary)
            Text("Workflow đã lưu").font(.headline)
            ForEach(flows) { flow in
                HStack {
                    Button { macroMode = false; editing = flow.id; title = flow.title; steps = flow.steps; template = "" } label:{ VStack(alignment:.leading){Text(flow.title).bold();Text("\(flow.steps.count) bước").font(.caption)} }.buttonStyle(.plain)
                    Spacer()
                    Button(role:.destructive) { flows.removeAll{$0.id == flow.id}; PremiumStore.workflows = flows } label:{ Image(systemName:"trash") }
                }
            }
            Text("Macro đã lưu").font(.headline)
            ForEach(macros) { macro in
                HStack {
                    Button { macroMode = true; editing = macro.id; title = macro.title; template = macro.template; steps = macro.steps } label:{ VStack(alignment:.leading){Text(macro.title).bold();Text(macro.template).font(.caption).lineLimit(2)} }.buttonStyle(.plain)
                    Spacer()
                    Button(role:.destructive) { macros.removeAll{$0.id == macro.id}; PremiumStore.macros = macros } label:{ Image(systemName:"trash") }
                }
            }
        }
    }
    private func reset() { title = ""; template = ""; steps = []; editing = nil }
    private func save() {
        let name = String(title.trimmingCharacters(in:.whitespacesAndNewlines).prefix(60))
        guard !name.isEmpty, MessageSafety.warnings(in:name).isEmpty else { status = "Tên không hợp lệ."; return }
        if macroMode {
            guard !template.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty, template.count <= 1500, MessageSafety.warnings(in:template).isEmpty else { status = "Mẫu trống, quá dài hoặc nhạy cảm."; return }
            let item = PremiumMacro(id:editing ?? UUID().uuidString,title:name,template:template,steps:steps)
            macros.removeAll{$0.id == item.id}; macros.insert(item,at:0); PremiumStore.macros = macros; macros = PremiumStore.macros
        } else {
            guard !steps.isEmpty else { status = "Thêm ít nhất một bước."; return }
            let item = PremiumWorkflow(id:editing ?? UUID().uuidString,title:name,steps:steps)
            flows.removeAll{$0.id == item.id}; flows.insert(item,at:0); PremiumStore.workflows = flows; flows = PremiumStore.workflows
        }
        reset(); status = "Đã lưu · mở Công cụ trên bàn phím."
    }
}
