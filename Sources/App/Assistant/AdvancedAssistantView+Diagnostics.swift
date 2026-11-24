import SwiftUI
import PhotosUI
import Vision
import Speech
import AVFoundation
import EventKit
import UIKit
import LocalAuthentication

extension AdvancedAssistantView {
    var learningSection: some View {
            section("ViePN đã học được gì?", icon: "chart.bar.xaxis") {
                Text("Thống kê chỉ từ các lựa chọn bạn đã chủ động sử dụng. Không ghi lại toàn bộ những gì gõ trong ứng dụng khác.")
                    .font(.caption2).foregroundStyle(.secondary)
                let usage = KeyboardSettings.glideUsageCounts
                let emojiUsage = KeyboardSettings.frequentlyUsedEmoji
                let words = KeyboardSettings.learnedWords
                HStack(spacing: 12) {
                    VStack(alignment: .leading) {
                        Text(String(usage.values.reduce(0, +)))
                            .font(.title3).bold()
                        Text("lượt chọn từ vuốt").font(.caption2)
                    }
                    VStack(alignment: .leading) {
                        Text(String(emojiUsage.values.reduce(0, +)))
                            .font(.title3).bold()
                        Text("emoji đã chọn").font(.caption2)
                    }
                    VStack(alignment: .leading) {
                        Text(String(KeyboardSettings.writingSamples.count))
                            .font(.title3).bold()
                        Text("ví dụ văn phong").font(.caption2)
                    }
                }
                .foregroundStyle(.cyan)
                let popular = Array(usage.sorted { $0.value > $1.value }.prefix(5))
                if !popular.isEmpty {
                    Text("Những từ vuốt thường chọn")
                        .font(.caption).bold()
                    ForEach(Array(popular.enumerated()), id: \.offset) { _, item in
                        let key = item.key.components(separatedBy: "|").last ?? item.key
                        HStack {
                            Text(key).font(.caption)
                            Spacer()
                            Text(String(item.value) + " lần")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
                let popularEmoji = Array(emojiUsage.sorted { $0.value > $1.value }.prefix(6))
                if !popularEmoji.isEmpty {
                    Text("Emoji đã chọn nhiều").font(.caption).bold()
                    HStack {
                        ForEach(Array(popularEmoji.enumerated()), id: \.offset) {
                            _, item in
                            Text(item.key + " ×" + String(item.value))
                                .font(.caption)
                        }
                    }
                }
                HStack {
                    Button(role: .destructive) {
                        KeyboardSettings.glideUsageCounts = [:]
                        KeyboardSettings.frequentlyUsedEmoji = [:]
                        feedback = "Đã đặt lại lịch sử học từ vuốt và emoji."
                    } label: { Label("Xóa thống kê học", systemImage: "trash") }
                    Button {
                        feedback = "Từ cá nhân đã học: " + String(words.count)
                            + ". Quản lý tại phần Bàn phím."
                    } label: { Label("Từ điển cá nhân", systemImage: "book") }
                }
                .font(.caption).buttonStyle(.bordered)
            }
    }

    var diagnosticsSection: some View {
            section("Chẩn đoán bàn phím", icon: "waveform.path.ecg") {
                Text("Chỉ đếm thời gian thao tác; không lưu ký tự, nội dung hội thoại hay mật khẩu.")
                    .font(.caption).foregroundStyle(.secondary)
                Text(diagnostics).font(.system(size: 11, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack {
                    Button("Làm mới") { diagnostics = KeyboardStability.report() }
                    Button("Sao chép báo cáo") {
                        UIPasteboard.general.string = KeyboardStability.report()
                    }
                    Button("Xóa", role: .destructive) {
                        KeyboardStability.clear()
                        diagnostics = KeyboardStability.report()
                    }
                }
                .font(.caption)
                .buttonStyle(.bordered)
            }
    }
}
