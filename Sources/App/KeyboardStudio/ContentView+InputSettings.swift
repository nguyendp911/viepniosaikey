import SwiftUI
import UIKit
import AudioToolbox
import PhotosUI

extension ContentView {
    var keyboardInputCard: some View {
        keyboardPanel("Nhập liệu nhanh", icon: "keyboard") {
            VStack(spacing: 7) {
                keyboardToggleRow(
                    "Gõ tiếng Việt", symbol: "character.cursor.ibeam",
                    isOn: Binding(
                        get: { typingMode != "off" },
                        set: { enabled in
                            let mode = enabled ? "telex" : "off"
                            typingMode = mode
                            telexEnabled = enabled
                            KeyboardSettings.typingMode = mode
                            KeyboardSettings.telexEnabled = enabled
                        }
                    )
                )
                keyboardDivider()
                keyboardToggleRow("Emoji thông minh", symbol: "face.smiling",
                                  isOn: $emojiEnabled)
                    .onChange(of: emojiEnabled) { KeyboardSettings.emojiEnabled = $0 }
                keyboardDivider()
                keyboardToggleRow("Rung khi gõ", symbol: "hand.tap",
                                  isOn: $hapticEnabled)
                    .onChange(of: hapticEnabled) { KeyboardSettings.hapticEnabled = $0 }
                if hapticEnabled {
                    keyboardMenuRow("Kiểu rung", symbol: "waveform",
                                    value: $hapticStyle,
                                    options: [("vibrate", "Rõ · rung hệ thống"),
                                              ("light", "Nhẹ · Taptic")])
                        .onChange(of: hapticStyle) { KeyboardSettings.hapticStyle = $0 }
                    HStack {
                        Text("iOS có thể giới hạn rung trên bàn phím bên thứ ba.")
                            .font(.system(size: 10))
                            .foregroundStyle(muted)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 3)
                        Button {
                            if hapticStyle == "vibrate" {
                                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                            } else {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        } label: {
                            Label("Thử rung", systemImage: "hand.tap")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .buttonStyle(.bordered)
                        .tint(cyan)
                    }
                }
                keyboardDivider()
                keyboardToggleRow("Viết hoa đầu câu", symbol: "textformat.abc.dottedunderline",
                                  isOn: $autoCapitalize)
                    .onChange(of: autoCapitalize) { KeyboardSettings.autoCapitalize = $0 }
            }
        }
    }

    var keyboardPreferencesCard: some View {
        keyboardPanel("Cấu hình & AI", icon: "slider.horizontal.3") {
            VStack(spacing: 5) {
                keyboardMenuRow("Kiểu gõ", symbol: "character.book.closed",
                                value: $typingMode,
                                options: [("telex", "Telex"), ("vni", "VNI"),
                                          ("off", "Không dấu")])
                    .onChange(of: typingMode) { newValue in
                        KeyboardSettings.typingMode = newValue
                        telexEnabled = newValue == "telex"
                        KeyboardSettings.telexEnabled = telexEnabled
                    }
                if typingMode == "vni" {
                    Text("VNI: bấm 123 để nhập số dấu (1–5), 6/7/8 để đổi nguyên âm, 9 đổi d thành đ và 0 bỏ dấu thanh. Ví dụ: da9 → đa; duong7 → dương.")
                        .font(.system(size: 11))
                        .foregroundStyle(muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                keyboardDivider()
                keyboardMenuRow("Giọng điệu AI", symbol: "bubble.left",
                                value: $preferredTone,
                                options: ["Tự nhiên", "Lịch sự", "Ngọt ngào", "Quan tâm", "Lạnh lùng",
                                          "Hờn nhẹ", "Trưởng thành", "Hài hước", "Chuyên nghiệp"].map { ($0, $0) })
                    .onChange(of: preferredTone) { KeyboardSettings.preferredTone = $0 }
                ToneStudioPreview(tone: preferredTone, length: preferredLength)
                keyboardDivider()
                keyboardMenuRow("Độ dài trả lời", symbol: "text.alignleft",
                                value: $preferredLength,
                                options: ["Ngắn", "Vừa", "Chi tiết"].map { ($0, $0) })
                    .onChange(of: preferredLength) { KeyboardSettings.preferredLength = $0 }
                keyboardDivider()
                keyboardMenuRow("Dịch sang", symbol: "translate",
                                value: $translationLanguage,
                                options: [("English", "Tiếng Anh"),
                                          ("Chinese (Simplified)", "Tiếng Trung"),
                                          ("Japanese", "Tiếng Nhật"),
                                          ("Korean", "Tiếng Hàn"),
                                          ("French", "Tiếng Pháp")])
                    .onChange(of: translationLanguage) {
                        KeyboardSettings.translationLanguage = $0
                    }
            }
        }
    }
}
