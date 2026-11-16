import SwiftUI

/// Add and remove the dates the keyboard should remember: the day a couple got
/// together, birthdays and other occasions. Saved on this device only.
struct SpecialDatesView: View {
    @State private var items: [SpecialDate] = []
    @State private var kind = "anniversary"
    @State private var title = ""
    @State private var pickedDate = Date()

    private static let kinds: [(id: String, label: String)] = [
        ("anniversary", "Ngày yêu / kỷ niệm"),
        ("birthday", "Sinh nhật"),
        ("other", "Dịp khác")
    ]

    var body: some View {
        List {
            Section(header: Text("Đã lưu"),
                    footer: Text("Bàn phím nhắc khi đến ngày, và Giữ nút Couple để chèn lời chúc. Gõ /ngay để chèn số ngày bên nhau, /chao để chèn lời chào hợp giờ.")) {
                if items.isEmpty {
                    Text("Chưa có ngày nào.").foregroundColor(.secondary)
                }
                ForEach(items) { item in
                    HStack {
                        Text(icon(item.kind))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                            Text(describe(item)).font(.footnote).foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete { offsets in
                    items.remove(atOffsets: offsets)
                    save()
                }
            }
            Section(header: Text("Thêm ngày mới")) {
                Picker("Loại", selection: $kind) {
                    ForEach(Self.kinds, id: \.id) { entry in
                        Text(entry.label).tag(entry.id)
                    }
                }
                TextField(placeholder, text: $title)
                DatePicker(kind == "anniversary" ? "Ngày bắt đầu yêu" : "Ngày",
                           selection: $pickedDate, displayedComponents: .date)
                Button("Thêm") { add() }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                              || items.count >= SpecialDates.maxItems)
            }
        }
        .navigationTitle("Ngày đặc biệt")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { items = SpecialDates.decode(KeyboardSettings.specialDatesData) }
    }

    private var placeholder: String {
        switch kind {
        case "birthday": return "Tên người (ví dụ: Mai)"
        case "anniversary": return "Tên dịp (ví dụ: Ngày yêu)"
        default: return "Tên dịp (ví dụ: Ngày cưới)"
        }
    }

    private func icon(_ kind: String) -> String {
        kind == "birthday" ? "🎂" : (kind == "anniversary" ? "💗" : "💫")
    }

    private func describe(_ item: SpecialDate) -> String {
        var text = "\(item.day)/\(item.month)"
        if let year = item.year { text += "/\(year)" }
        let days = SpecialDates.daysUntilNext(item, from: Date())
        text += days == 0 ? " · hôm nay" : " · còn \(days) ngày"
        return text
    }

    private func add() {
        let calendar = Calendar.current
        let parts = calendar.dateComponents([.year, .month, .day], from: pickedDate)
        guard let month = parts.month, let day = parts.day else { return }
        let cleanTitle = String(title.trimmingCharacters(in: .whitespacesAndNewlines).prefix(40))
        var item = SpecialDate(id: UUID().uuidString, title: cleanTitle, kind: kind,
                               month: month, day: day, year: nil)
        if kind == "anniversary" { item.year = parts.year }
        // One relationship start date is enough; the new one replaces the old.
        if kind == "anniversary" && item.year != nil {
            items.removeAll { $0.kind == "anniversary" && $0.year != nil }
        }
        items.append(item)
        title = ""
        save()
    }

    private func save() {
        KeyboardSettings.specialDatesData = SpecialDates.encode(items)
    }
}
