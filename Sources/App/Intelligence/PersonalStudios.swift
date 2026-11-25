import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct PersonalDNAView: View {
    @State private var samples = KeyboardSettings.writingSamples
    @State private var draft = ""
    var body: some View {
        let metrics = PersonalStyleDNA.analyze(samples)
        VStack(alignment: .leading, spacing: 12) {
            Text("Chỉ học từ mẫu bạn tự thêm. Không đọc tin nhắn hoặc lịch sử gõ.").font(.caption).foregroundStyle(.secondary)
            LabeledContent("Mẫu", value: "\(metrics.count)/8")
            LabeledContent("Độ dài trung bình", value: "\(metrics.averageWords) từ")
            LabeledContent("Mẫu có câu hỏi", value: "\(metrics.questions)")
            LabeledContent("Mẫu có dấu chấm than", value: "\(metrics.exclamations)")
            Text("Từ thường gặp: " + metrics.commonWords.joined(separator: ", "))
            TextEditor(text: $draft).frame(minHeight: 90)
            Button("Thêm mẫu văn phong") {
                guard !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      MessageSafety.warnings(in: draft).isEmpty else { return }
                samples.insert(String(draft.prefix(350)), at: 0)
                samples = Array(samples.prefix(8)); KeyboardSettings.writingSamples = samples; draft = ""
            }.buttonStyle(.borderedProminent)
            ForEach(samples.indices, id: \.self) { index in
                HStack { Text(samples[index]); Spacer(); Button(role: .destructive) { samples.remove(at: index); KeyboardSettings.writingSamples = samples } label: { Image(systemName: "trash") } }
            }
        }
    }
}

struct PromptStudioView: View {
    @State private var prompts = PersonalPromptStore.items
    @State private var title = ""
    @State private var instruction = ""
    @State private var editing: String?
    @State private var status = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tạo lệnh viết hoặc giao tiếp riêng; có thể chạy từ nút Công cụ trên bàn phím.").font(.caption).foregroundStyle(.secondary)
            TextField("Tên lệnh", text: $title).textFieldStyle(.roundedBorder)
            TextEditor(text: $instruction).frame(minHeight: 100)
            Button(editing == nil ? "Thêm prompt" : "Lưu thay đổi") {
                let name = title.trimmingCharacters(in: .whitespacesAndNewlines)
                let text = instruction.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty, !text.isEmpty, MessageSafety.warnings(in: text).isEmpty else { status = "Lệnh trống hoặc có dữ liệu nhạy cảm."; return }
                if let editing, let i = prompts.firstIndex(where: { $0.id == editing }) { prompts[i].title = name; prompts[i].instruction = text }
                else { prompts.insert(.init(title: name, instruction: text), at: 0) }
                PersonalPromptStore.items = prompts; prompts = PersonalPromptStore.items
                title = ""; instruction = ""; editing = nil; status = "Đã lưu."
            }.buttonStyle(.borderedProminent)
            Text(status).font(.caption)
            ForEach(prompts) { prompt in
                HStack {
                    Button { editing = prompt.id; title = prompt.title; instruction = prompt.instruction } label: {
                        VStack(alignment: .leading) { Text(prompt.title).bold(); Text(prompt.instruction).font(.caption).lineLimit(2) }
                    }.buttonStyle(.plain)
                    Spacer()
                    Button(role: .destructive) { prompts.removeAll { $0.id == prompt.id }; PersonalPromptStore.items = prompts } label: { Image(systemName: "trash") }
                }.padding(.vertical, 5)
            }
        }
    }
}

struct DictionaryStudioView: View {
    @State private var words = PersonalDictionary.words.joined(separator: "\n")
    @State private var status = ""
    @State private var importing = false
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Từ điển riêng offline · tối đa 500 từ. Mỗi dòng một từ, chỉ chữ cái. Từ được thêm tham gia gợi ý và nhận diện vuốt.").font(.caption).foregroundStyle(.secondary)
            TextEditor(text: $words).frame(minHeight: 240)
            HStack {
                Button("Lưu từ điển") { PersonalDictionary.words = PersonalDictionary.normalize(words); words = PersonalDictionary.words.joined(separator: "\n"); status = "Đã lưu \(PersonalDictionary.words.count) từ." }
                    .buttonStyle(.borderedProminent)
                Button("Nhập TXT") { importing = true }.buttonStyle(.bordered)
            }
            Text(status).font(.caption)
        }.fileImporter(isPresented: $importing, allowedContentTypes: [.plainText]) { result in
            do {
                let url = try result.get()
                let scoped = url.startAccessingSecurityScopedResource()
                defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                guard let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize, size <= 128_000 else { status = "File quá lớn."; return }
                let text = try String(contentsOf: url, encoding: .utf8)
                words = PersonalDictionary.normalize(words + "\n" + text).joined(separator: "\n")
                status = "Đã nhập vào bản xem trước. Bấm Lưu để áp dụng."
            } catch { status = error.localizedDescription }
        }
    }
}

struct SymbolStudioView: View {
    @State private var query = ""
    @State private var category = "Tất cả"
    @State private var favorites = SymbolCatalog.favorites
    @State private var chosen = ""
    @State private var art = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Tìm bằng tiếng Việt, ví dụ: tim, cười", text: $query).textFieldStyle(.roundedBorder)
            Picker("Danh mục", selection: $category) { ForEach(SymbolCatalog.categories, id: \.self) { Text($0) } }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 72))]) {
                ForEach(SymbolCatalog.search(query, category: category)) { entry in
                    VStack(spacing: 4) {
                        Button(entry.value) { chosen = entry.value; UIPasteboard.general.string = entry.value }
                            .font(.system(size: 24)).frame(maxWidth: .infinity, minHeight: 35)
                        Button { SymbolCatalog.toggle(entry.value); favorites = SymbolCatalog.favorites } label: {
                            Image(systemName: favorites.contains(entry.value) ? "star.fill" : "star")
                        }.buttonStyle(.plain).foregroundStyle(.yellow)
                    }.padding(5).background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 9))
                }
            }
            TextField("Chữ trang trí", text: $art).textFieldStyle(.roundedBorder)
            Button("Tạo chữ nghệ thuật") { chosen = SymbolCatalog.decorative(art); UIPasteboard.general.string = chosen }.buttonStyle(.bordered)
            if !chosen.isEmpty { Text("Đã sao chép: " + chosen); Button("Đưa sang bàn phím") { ShareDraft.save(chosen) }.buttonStyle(.bordered) }
        }
    }
}

struct PrivacyStudioView: View {
    @State private var incognito = KeyboardSettings.privateTypingMode
    @State private var confirm = false
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Toggle("Gõ riêng tư", isOn: $incognito).onChange(of: incognito) { KeyboardSettings.privateTypingMode = $0 }
            Text("Tắt AI cloud và học từ mới trong chế độ riêng tư. Dữ liệu cũ không bị tự động xóa.").font(.caption).foregroundStyle(.secondary)
            Button("Xóa clipboard, từ/cụm từ đã học, emoji thường dùng và bản nháp", role: .destructive) { confirm = true }
                .buttonStyle(.bordered)
        }.alert("Xóa dữ liệu cục bộ?", isPresented: $confirm) {
            Button("Xóa", role: .destructive) {
                ClipboardVault.clear(); PremiumStore.clearNotes(); KeyboardSettings.learnedWords = [:]; PersonalPhraseStore.clear(); TypingProFeedback.clear(); KeyboardSettings.glideUsageCounts = [:]
                KeyboardSettings.frequentlyUsedEmoji = [:]; ShareDraft.clear()
            }
            Button("Hủy", role: .cancel) {}
        } message: { Text("Không xóa hồ sơ, lịch sử hội thoại, bộ nhớ 3.0, API Key hoặc từ điển tự nhập. Xóa bộ nhớ 3.0 trong Second Brain.") }
    }
}
