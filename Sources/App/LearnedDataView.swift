import SwiftUI

/// Lets the user see, and delete one by one, everything the keyboard has
/// learned on this device: personal words, names and word pairs.
struct LearnedDataView: View {
    @Environment(\.dismiss) private var dismiss

    private struct WordRow: Identifiable {
        let id: String
        let count: Int
    }

    private struct NameRow: Identifiable {
        let id: String
        let display: String
        let count: Int
    }

    private struct PairRow: Identifiable {
        let id: String
        let first: String
        let second: String
        let count: Int
    }

    @State private var words: [WordRow] = []
    @State private var names: [NameRow] = []
    @State private var pairs: [PairRow] = []
    @State private var confirmClear = false

    private var isEmpty: Bool { words.isEmpty && names.isEmpty && pairs.isEmpty }

    var body: some View {
        NavigationView {
            List {
                if isEmpty {
                    Text("Chưa có dữ liệu. Bật “Ghi nhớ từ đã gõ” để bàn phím bắt đầu học.")
                        .foregroundColor(.secondary)
                }
                if !words.isEmpty {
                    Section(header: Text("Từ đã học (\(words.count))")) {
                        ForEach(words) { row in
                            HStack {
                                Text(row.id)
                                Spacer()
                                Text("\(row.count)").foregroundColor(.secondary)
                            }
                        }
                        .onDelete { offsets in deleteWords(at: offsets) }
                    }
                }
                if !names.isEmpty {
                    Section(header: Text("Tên riêng (\(names.count))")) {
                        ForEach(names) { row in
                            HStack {
                                Text(row.display)
                                Spacer()
                                Text("\(row.count)").foregroundColor(.secondary)
                            }
                        }
                        .onDelete { offsets in deleteNames(at: offsets) }
                    }
                }
                if !pairs.isEmpty {
                    Section(header: Text("Cặp từ hay đi cùng nhau")) {
                        ForEach(pairs) { row in
                            HStack {
                                Text(row.first + " → " + row.second)
                                Spacer()
                                Text("\(row.count)").foregroundColor(.secondary)
                            }
                        }
                        .onDelete { offsets in deletePairs(at: offsets) }
                    }
                }
            }
            .navigationTitle("Dữ liệu đã học")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Xóa tất cả", role: .destructive) { confirmClear = true }
                        .disabled(isEmpty)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Xong") { dismiss() }
                }
            }
            .alert("Xóa toàn bộ dữ liệu đã học?", isPresented: $confirmClear) {
                Button("Xóa", role: .destructive) { clearAll() }
                Button("Hủy", role: .cancel) {}
            } message: {
                Text("Từ, tên riêng và cặp từ bàn phím đã nhớ sẽ bị xóa khỏi máy này.")
            }
        }
        .onAppear { reload() }
    }

    // MARK: Loading

    private func reload() {
        var wordRows: [WordRow] = []
        for (word, count) in KeyboardSettings.learnedWords {
            wordRows.append(WordRow(id: word, count: count))
        }
        wordRows.sort { (a: WordRow, b: WordRow) -> Bool in
            if a.count != b.count { return a.count > b.count }
            return a.id < b.id
        }
        words = wordRows

        var nameRows: [NameRow] = []
        let memory = ProperNounMemory.decode(KeyboardSettings.properNounData)
        for (key, entry) in memory.entries {
            nameRows.append(NameRow(id: key, display: entry.display, count: entry.count))
        }
        nameRows.sort { (a: NameRow, b: NameRow) -> Bool in
            if a.count != b.count { return a.count > b.count }
            return a.id < b.id
        }
        names = nameRows

        var pairRows: [PairRow] = []
        let model = NextWordModel.decode(KeyboardSettings.nextWordModelData)
        for (first, followers) in model.bigrams {
            for (second, count) in followers {
                pairRows.append(PairRow(id: first + " " + second,
                                        first: first, second: second, count: count))
            }
        }
        pairRows.sort { (a: PairRow, b: PairRow) -> Bool in
            if a.count != b.count { return a.count > b.count }
            return a.id < b.id
        }
        pairs = Array(pairRows.prefix(300))
    }

    // MARK: Deleting

    private func deleteWords(at offsets: IndexSet) {
        var learned = KeyboardSettings.learnedWords
        for index in offsets where words.indices.contains(index) {
            learned.removeValue(forKey: words[index].id)
        }
        KeyboardSettings.learnedWords = learned
        reload()
    }

    private func deleteNames(at offsets: IndexSet) {
        var memory = ProperNounMemory.decode(KeyboardSettings.properNounData)
        for index in offsets where names.indices.contains(index) {
            memory.entries.removeValue(forKey: names[index].id)
        }
        KeyboardSettings.properNounData = memory.encoded()
        reload()
    }

    private func deletePairs(at offsets: IndexSet) {
        var model = NextWordModel.decode(KeyboardSettings.nextWordModelData)
        for index in offsets where pairs.indices.contains(index) {
            let row = pairs[index]
            model.bigrams[row.first]?.removeValue(forKey: row.second)
            if model.bigrams[row.first]?.isEmpty == true {
                model.bigrams.removeValue(forKey: row.first)
            }
            // Three-word habits ending in the same pair go too.
            for key in Array(model.trigrams.keys) where key.hasSuffix(" " + row.first) {
                model.trigrams[key]?.removeValue(forKey: row.second)
                if model.trigrams[key]?.isEmpty == true {
                    model.trigrams.removeValue(forKey: key)
                }
            }
        }
        KeyboardSettings.nextWordModelData = model.encoded()
        reload()
    }

    private func clearAll() {
        KeyboardSettings.learnedWords = [:]
        KeyboardSettings.nextWordModelData = nil
        KeyboardSettings.properNounData = nil
        reload()
    }
}
