import SwiftUI
import PhotosUI
import Vision
import Speech
import AVFoundation
import EventKit
import UIKit
import LocalAuthentication

extension AdvancedAssistantView {
    var voiceSection: some View {
            section("Giọng nói thành văn bản", icon: "waveform") {
                Text("Thu âm trong ứng dụng chính. Nội dung nhận dạng được đưa vào ô soạn để bạn kiểm tra trước khi gửi AI.")
                    .font(.caption).foregroundStyle(.secondary)
                HStack {
                    Button {
                        if voice.recording {
                            Task {
                                if let value = await voice.finish() {
                                    sourceText = value
                                    feedback = "Đã nhận diện giọng nói; hãy kiểm tra văn bản."
                                } else { feedback = voice.errorText }
                            }
                        } else {
                            Task { await voice.begin() }
                        }
                    } label: {
                        Label(voice.recording ? "Dừng & nhận dạng" : "Bắt đầu thu âm",
                              systemImage: voice.recording ? "stop.circle" : "mic.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(voice.recording ? .red : .indigo)
                    if !voice.errorText.isEmpty {
                        Text(voice.errorText).font(.caption2).foregroundStyle(.orange)
                    }
                }
            }
    }
}
