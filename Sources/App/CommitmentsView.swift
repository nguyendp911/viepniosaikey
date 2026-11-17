import SwiftUI
import UserNotifications

/// Schedules local reminders for promises the user confirmed. Notifications
/// are created by this app only, from data the user reviewed.
enum CommitmentReminders {
    private static let prefix = "viepn.commitment."

    static func requestAccess(_ completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    /// Replaces every pending promise reminder with the current confirmed list.
    static func reschedule(_ items: [Commitment], leadMinutes: Int) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { pending in
            let old = pending.map { $0.identifier }.filter { $0.hasPrefix(prefix) }
            center.removePendingNotificationRequests(withIdentifiers: old)
            let now = Date()
            for item in items where item.confirmed && !item.done {
                guard let due = item.due else { continue }
                var fire = due.addingTimeInterval(-Double(leadMinutes) * 60)
                if fire <= now { fire = due }
                guard fire > now else { continue }
                let content = UNMutableNotificationContent()
                content.title = item.mine ? "📌 Bạn đã hứa" : "📌 Người ấy đã hẹn"
                content.body = item.text
                content.sound = .default
                let parts = Calendar.current.dateComponents(
                    [.year, .month, .day, .hour, .minute], from: fire)
                let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
                center.add(UNNotificationRequest(identifier: prefix + item.id,
                                                 content: content, trigger: trigger))
            }
        }
    }
}

/// Promises found in pasted chats. New ones wait here for a yes or no.
struct CommitmentsView: View {
    @State private var items: [Commitment] = []
    @State private var remindersAllowed = true
    @State private var lead = KeyboardSettings.reminderLeadMinutes

    private func personName(_ id: String) -> String {
        PersonaStore.all.first(where: { $0.id == id })?.name ?? "Chưa chọn hồ sơ"
    }

    private func dueText(_ date: Date?) -> String {
        guard let date = date else { return "Chưa có giờ" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "EEEE d/M, HH:mm"
        return formatter.string(from: date)
    }

    private func row(_ item: Commitment) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(item.text).font(.body)
            Text((item.mine ? "Bạn hứa · " : "Người ấy hẹn · ") + personName(item.profileID)
                 + " · " + dueText(item.due))
                .font(.footnote).foregroundColor(.secondary)
        }
    }

    var body: some View {
        List {
            let fresh = items.filter { !$0.confirmed && !$0.done }
            let kept = items.filter { $0.confirmed && !$0.done }
            let finished = items.filter { $0.done }
            if items.isEmpty {
                Section {
                    Text("Chưa có lời hứa nào. Khi bạn dán đoạn chat hoặc ảnh chụp có câu như “mai anh đón em lúc 7h”, bàn phím tự ghi lại để bạn duyệt ở đây.")
                        .foregroundColor(.secondary)
                }
            }
            if !fresh.isEmpty {
                Section(header: Text("Mới phát hiện (\(fresh.count))"),
                        footer: Text("Chỉ những mục bạn giữ lại mới được nhắc.")) {
                    ForEach(fresh) { item in
                        VStack(alignment: .leading, spacing: 8) {
                            row(item)
                            HStack(spacing: 12) {
                                Button("Giữ lại") { change(item) { $0.confirmed = true } }
                                    .buttonStyle(.borderedProminent)
                                Button("Bỏ", role: .destructive) { remove(item) }
                                    .buttonStyle(.bordered)
                            }
                        }
                    }
                }
            }
            if !kept.isEmpty {
                Section(header: Text("Đang theo dõi (\(kept.count))")) {
                    ForEach(kept) { item in
                        HStack {
                            row(item)
                            Spacer()
                            Button("Xong") { change(item) { $0.done = true } }
                                .buttonStyle(.bordered)
                        }
                    }
                    .onDelete { offsets in
                        for index in offsets { remove(kept[index]) }
                    }
                }
            }
            if !finished.isEmpty {
                Section(header: Text("Đã xong")) {
                    ForEach(finished) { item in
                        row(item).foregroundColor(.secondary)
                    }
                    .onDelete { offsets in
                        for index in offsets { remove(finished[index]) }
                    }
                }
            }
            Section(header: Text("Nhắc nhở"),
                    footer: Text(remindersAllowed
                                 ? "Nhắc bằng thông báo của ViePN, chỉ cho mục có giờ."
                                 : "Chưa được phép gửi thông báo. Bật trong Cài đặt → ViePN → Thông báo.")) {
                Stepper("Nhắc trước \(lead) phút", value: $lead, in: 0...240, step: 5)
                    .onChange(of: lead) { value in
                        KeyboardSettings.reminderLeadMinutes = value
                        reschedule()
                    }
                Button("Bật thông báo nhắc") {
                    CommitmentReminders.requestAccess { granted in
                        remindersAllowed = granted
                        reschedule()
                    }
                }
            }
        }
        .navigationTitle("Sổ lời hứa")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            items = CommitmentStore.all
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                let allowed = settings.authorizationStatus != .denied
                DispatchQueue.main.async { remindersAllowed = allowed }
            }
        }
    }

    private func change(_ item: Commitment, _ edit: (inout Commitment) -> Void) {
        var updated = item
        edit(&updated)
        CommitmentStore.update(updated)
        items = CommitmentStore.all
        reschedule()
    }

    private func remove(_ item: Commitment) {
        CommitmentStore.remove(id: item.id)
        items = CommitmentStore.all
        reschedule()
    }

    private func reschedule() {
        CommitmentReminders.reschedule(CommitmentStore.all, leadMinutes: lead)
    }
}
