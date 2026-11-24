import SwiftUI
import UIKit

struct PremiumVaultStudioView: View {
    @State private var clipboard = false
    @State private var category = "Cá nhân"
    @State private var title = ""
    @State private var text = ""
    @State private var notes:[PremiumNote] = []
    @State private var editing:String?
    @State private var key = ""
    @State private var value = ""
    @State private var variables = PremiumStore.variables
    @State private var status = ""
    var body: some View {
        VStack(alignment:.leading,spacing:12) {
            Text("Kho cá nhân").font(.title.bold())
            Text("Chỉ lưu khi bạn bấm lưu; clipboard hết hạn sau 7 ngày. Bản nháp tồn tại đến khi bạn xóa. Không đồng bộ cloud.").font(.caption).foregroundStyle(.secondary)
            Picker("Kho",selection:$clipboard) { Text("Bản nháp").tag(false); Text("Clipboard").tag(true) }.pickerStyle(.segmented)
                .onChange(of:clipboard) { _ in reload(); editing = nil; title = ""; text = "" }
            Picker("Danh mục",selection:$category) { ForEach(PremiumStore.categories,id:\.self) { Text($0) } }
            TextField("Tên",text:$title).textFieldStyle(.roundedBorder)
            TextEditor(text:$text).frame(minHeight:110)
            Button(editing == nil ? "Lưu nội dung" : "Cập nhật") { save() }.buttonStyle(.borderedProminent)
            if editing != nil { Button("Hủy sửa") { editing = nil; title = ""; text = "" } }
            ForEach(notes.filter{$0.category == category}) { note in
                VStack(alignment:.leading,spacing:6) {
                    Text(note.title).bold()
                    Text(note.text).font(.caption).lineLimit(4)
                    HStack {
                        Button("Sửa") { editing = note.id; title = note.title; text = note.text }
                        Button("Sao chép") { UIPasteboard.general.string = note.text }
                        Spacer()
                        Button(role:.destructive) { notes.removeAll{$0.id == note.id}; persist() } label:{ Image(systemName:"trash") }
                    }.buttonStyle(.borderless)
                }.padding(10).background(.white.opacity(0.06),in:RoundedRectangle(cornerRadius:10))
            }
            Divider()
            Text("Smart Variables").font(.headline)
            Text("{{ngay}} · {{gio}} · {{ten}} luôn có sẵn. Tạo biến riêng gồm chữ không dấu, số, dấu gạch dưới.").font(.caption).foregroundStyle(.secondary)
            TextField("Tên biến",text:$key).textFieldStyle(.roundedBorder).textInputAutocapitalization(.never)
            TextField("Giá trị",text:$value).textFieldStyle(.roundedBorder)
            Button("Lưu biến") {
                guard key.range(of:#"^[a-zA-Z0-9_]{1,24}$"#,options:.regularExpression) != nil, !["ngay","gio","ten"].contains(key), !value.isEmpty, MessageSafety.warnings(in:value).isEmpty else { status = "Tên hoặc giá trị biến không hợp lệ."; return }
                variables[key] = value; PremiumStore.variables = variables; variables = PremiumStore.variables; key = ""; value = ""
            }.buttonStyle(.bordered)
            ForEach(variables.keys.sorted(),id:\.self) { k in
                HStack { Button("{{"+k+"}}") { key = k; value = variables[k] ?? "" }; Spacer(); Text(variables[k] ?? "").lineLimit(1); Button(role:.destructive) { variables.removeValue(forKey:k); PremiumStore.variables = variables } label:{ Image(systemName:"trash") } }
            }
            Text(status).font(.caption).foregroundStyle(.orange)
        }.onAppear { reload() }
    }
    private func reload() { notes = clipboard ? PremiumStore.clipboard : PremiumStore.drafts }
    private func persist() { if clipboard { PremiumStore.clipboard = notes } else { PremiumStore.drafts = notes }; reload() }
    private func save() {
        guard !KeyboardSettings.privateTypingMode, !text.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty, text.count <= (clipboard ? 1000 : 3000), MessageSafety.warnings(in:text).isEmpty else { status = "Không lưu: riêng tư, nhạy cảm, trống hoặc quá dài."; return }
        if let editing, let index = notes.firstIndex(where:{$0.id == editing}) {
            notes[index].title = String(title.prefix(60)); notes[index].text = text; notes[index].category = category; persist()
        } else {
            guard PremiumStore.save(text,title:title.isEmpty ? String(text.prefix(40)) : title,category:category,isClipboard:clipboard) else { status = "Không lưu được."; return }; reload()
        }
        title = ""; text = ""; editing = nil; status = "Đã lưu."
    }
}
