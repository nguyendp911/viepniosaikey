import SwiftUI
import PhotosUI
import Vision
import Speech
import AVFoundation
import EventKit
import UIKit
import LocalAuthentication

extension AdvancedAssistantView {
    var calendarSection: some View {
            section("Lịch hẹn & lời nhắc", icon: "calendar.badge.plus") {
                Text("Đề xuất tác vụ từ văn bản đã nhận. Bạn xác nhận tiêu đề và giờ trước khi lưu vào Lịch iPhone.")
                    .font(.caption).foregroundStyle(.secondary)
                TextField("Tên sự kiện", text: $remindersTitle)
                    .textFieldStyle(.roundedBorder)
                DatePicker("Thời gian", selection: $reminderDate, in: Date()...)
                    .datePickerStyle(.compact)
                Button {
                    Task { await addCalendarEvent() }
                } label: { Label("Thêm vào Lịch", systemImage: "calendar.badge.plus") }
                    .buttonStyle(.bordered)
                    .disabled(remindersTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
    }

    @MainActor
    func addCalendarEvent() async {
        let store = EKEventStore()
        let granted: Bool
        if #available(iOS 17.0, *) {
            granted = (try? await store.requestWriteOnlyAccessToEvents()) ?? false
        } else {
            granted = (try? await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
                store.requestAccess(to: .event) { allowed, error in
                    if let error { continuation.resume(throwing: error) }
                    else { continuation.resume(returning: allowed) }
                }
            }) ?? false
        }
        guard granted else { feedback = "Chưa có quyền ghi vào Lịch iPhone."; return }
        let event = EKEvent(eventStore: store)
        event.title = String(remindersTitle.prefix(130))
        event.startDate = reminderDate
        event.endDate = reminderDate.addingTimeInterval(3600)
        event.calendar = store.defaultCalendarForNewEvents
        guard event.calendar != nil else {
            feedback = "Không có lịch mặc định để lưu sự kiện."; return
        }
        do {
            try store.save(event, span: .thisEvent)
            feedback = "Đã lưu sự kiện trong Lịch iPhone."
        } catch {
            feedback = "Không lưu được sự kiện: " + error.localizedDescription
        }
    }
}
