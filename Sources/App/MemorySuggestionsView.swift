import SwiftUI

/// Facts the AI proposed to remember about a person. Nothing is saved as a
/// note, and nothing reaches an AI prompt, until it is approved here.
struct MemorySuggestionsView: View {
    @State private var items: [MemorySuggestion] = []
    @State private var failed = false

    private func personName(_ id: String) -> String {
        PersonaStore.all.first(where: { $0.id == id })?.name ?? "Hồ sơ đã xoá"
    }

    var body: some View {
        List {
            if items.isEmpty {
                Section {
                    Text("Chưa có gợi ý. Dán đoạn chat, giữ nút AI trên bàn phím và chọn “Gợi ý ghi nhớ về người ấy”.")
                        .foregroundColor(.secondary)
                }
            }
            ForEach(PersonaStore.all.map { $0.id } + [""], id: \.self) { personaID in
                let group = items.filter { $0.personaID == personaID }
                if !group.isEmpty {
                    Section(header: Text(personName(personaID)),
                            footer: Text("Ghi nhớ đã duyệt được AI dùng khi soạn câu trả lời cho người này.")) {
                        ForEach(group) { item in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(item.text)
                                HStack(spacing: 12) {
                                    Button("Ghi nhớ") { approve(item) }
                                        .buttonStyle(.borderedProminent)
                                    Button("Bỏ", role: .destructive) { dismiss(item) }
                                        .buttonStyle(.bordered)
                                }
                            }
                        }
                    }
                }
            }
            if failed {
                Section {
                    Text("Không lưu được ghi nhớ. Thử lại sau.").foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Gợi ý ghi nhớ")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { items = MemorySuggestionStore.all }
    }

    private func approve(_ item: MemorySuggestion) {
        failed = !MemorySuggestionStore.approve(item.id)
        items = MemorySuggestionStore.all
    }

    private func dismiss(_ item: MemorySuggestion) {
        MemorySuggestionStore.dismiss(item.id)
        items = MemorySuggestionStore.all
    }
}
