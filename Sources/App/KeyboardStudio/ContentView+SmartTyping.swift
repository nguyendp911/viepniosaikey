import SwiftUI
import UIKit
import AudioToolbox
import PhotosUI

extension ContentView {
    var smartTypingCard: some View {
        keyboardPanel("Gõ thông minh & Hiệu năng", icon: "brain") {
            VStack(spacing: 9) {
                keyboardToggleRow("Chế độ siêu nhẹ · Ưu tiên gõ mượt",
                                  symbol: "bolt.fill", isOn: $performanceMode)
                    .onChange(of: performanceMode) {
                        KeyboardSettings.performanceMode = $0
                    }
                Text("Khi bật: giữ bộ gõ Telex/VNI, tạm tắt gợi ý từ, vuốt, hiệu ứng, rung và tự học từ. AI chỉ chạy khi bạn chủ động gọi. Chuyển bàn phím rồi mở lại ViePN để áp dụng.")
                    .font(.system(size: 11)).foregroundStyle(muted)
                    .fixedSize(horizontal: false, vertical: true)
                keyboardDivider()
                keyboardToggleRow("Tự phân biệt Việt – Anh", symbol: "globe",
                                  isOn: $smartBilingual)
                    .onChange(of: smartBilingual) { KeyboardSettings.smartBilingual = $0 }
                keyboardMenuRow("Ưu tiên ngôn ngữ", symbol: "character.bubble",
                                value: $bilingualPreference,
                                options: [("auto", "Tự động"),
                                          ("vi", "Ưu tiên tiếng Việt"),
                                          ("en", "Chỉ tiếng Anh")])
                    .onChange(of: bilingualPreference) {
                        KeyboardSettings.bilingualPreference = $0
                    }
                Text("Tự động nhận diện theo cả từ; nếu hai ngôn ngữ trùng nhau, bạn có thể chọn ưu tiên tiếng Việt hoặc chỉ tiếng Anh.")
                    .font(.system(size: 11)).foregroundStyle(muted)
                    .fixedSize(horizontal: false, vertical: true)
                keyboardDivider()
                keyboardToggleRow("Gợi ý ba từ offline", symbol: "text.word.spacing",
                                  isOn: $predictionsEnabled)
                    .onChange(of: predictionsEnabled) { KeyboardSettings.predictionsEnabled = $0 }
                keyboardDivider()
                keyboardToggleRow("Gợi ý câu hoàn chỉnh offline",
                                  symbol: "text.bubble", isOn: $sentenceSuggestionsEnabled)
                    .onChange(of: sentenceSuggestionsEnabled) {
                        KeyboardSettings.sentenceSuggestionsEnabled = $0
                    }
                Text("Gợi ý câu chỉ xuất hiện khi bạn gõ một từ kích hoạt và chọn thủ công; không đọc hội thoại hoặc gửi dữ liệu lên mạng.")
                    .font(.system(size: 11)).foregroundStyle(muted)
                    .fixedSize(horizontal: false, vertical: true)
                keyboardDivider()
                keyboardToggleRow("Vuốt chữ để nhập từ",
                                  symbol: "hand.draw", isOn: $glideEnabled)
                    .onChange(of: glideEnabled) { KeyboardSettings.glideEnabled = $0 }
                if glideEnabled {
                    keyboardToggleRow("Hiệu ứng vệt sáng khi vuốt",
                                      symbol: "scribble.variable", isOn: $glideTrailEnabled)
                        .onChange(of: glideTrailEnabled) {
                            KeyboardSettings.glideTrailEnabled = $0
                        }
                    keyboardDivider()
                    keyboardToggleRow("Tự học từ tôi thường chọn khi vuốt",
                                      symbol: "brain.head.profile",
                                      isOn: $glideLearningEnabled)
                        .onChange(of: glideLearningEnabled) {
                            KeyboardSettings.glideLearningEnabled = $0
                        }
                    if glideLearningEnabled {
                        Button(role: .destructive) {
                            KeyboardSettings.glideUsageCounts = [:]
                        } label: {
                            Label("Xóa lịch sử học từ vuốt", systemImage: "trash")
                                .font(.system(size: 11))
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                Text("Lần đầu vuốt minh, thanh gợi ý cuộn ngang hiện minh, mình, mính, mĩnh, mỉnh, mịnh. Chọn từ bạn cần; sau vài lần sử dụng, bàn phím ưu tiên những từ chọn nhiều. Nút Tất cả luôn mở lại mọi dấu. Dữ liệu học chỉ lưu trên thiết bị.")
                    .font(.system(size: 11)).foregroundStyle(muted)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Nếu bàn phím đang mở, chuyển sang bàn phím khác rồi chọn lại ViePN để cập nhật.")
                    .font(.system(size: 11)).foregroundStyle(muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .font(.system(size: 11)).foregroundStyle(muted)
                    .fixedSize(horizontal: false, vertical: true)
                keyboardDivider()
                keyboardToggleRow("Vùng chạm phím rộng hơn",
                                  symbol: "hand.point.up.left.fill",
                                  isOn: $adaptiveTouchEnabled)
                    .onChange(of: adaptiveTouchEnabled) {
                        KeyboardSettings.adaptiveTouchEnabled = $0
                    }
                Text("Chỉ mở rộng vùng chạm trong khe giữa các phím; không tự thay chữ hay ghi lại tọa độ ngón tay.")
                    .font(.system(size: 11)).foregroundStyle(muted)
                    .fixedSize(horizontal: false, vertical: true)
                keyboardDivider()
                keyboardToggleRow("Chế độ gõ riêng tư (tắt AI và tự học)", symbol: "hand.raised.fill", isOn: $privateTypingMode)
                    .onChange(of: privateTypingMode) {
                        KeyboardSettings.privateTypingMode = $0
                        cloudEnabled = KeyboardSettings.allowCloudAI
                    }
                keyboardDivider()
                keyboardToggleRow("Học từ và cụm từ đã gõ (trên máy)",
                                  symbol: "book.closed", isOn: $autoLearnWords)
                    .onChange(of: autoLearnWords) { KeyboardSettings.autoLearnWords = $0 }
                Text("Học cụm từ 2–9 tiếng từ nội dung bạn tự gõ; sau ít nhất hai lần lặp, ưu tiên gợi ý phần còn thiếu. Không gửi mạng. Chế độ riêng tư dừng học và gợi ý cá nhân. Không học mã số; bộ lọc không thể nhận diện mọi bí mật.")
                    .font(.system(size: 11)).foregroundStyle(muted)
                if autoLearnWords {
                    HStack {
                        Image(systemName:"chart.bar.xaxis").foregroundStyle(.cyan)
                        Text("Cụm từ đã học").font(.system(size:12))
                        Spacer()
                        Text("\(PersonalPhraseStore.load().entries.count)").font(.system(size:14,weight:.semibold,design:.monospaced))
                    }.padding(8)
                    Button(role: .destructive) {
                        KeyboardSettings.learnedWords = [:]
                        PersonalPhraseStore.clear()
                    } label: {
                        Label("Xóa từ và cụm từ đã học", systemImage: "trash")
                            .font(.system(size: 11))
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                keyboardDivider()
                keyboardMenuRow("Chế độ một tay", symbol: "hand.point.up.left",
                                value: $oneHandMode,
                                options: [("off", "Tắt"), ("left", "Tay trái"),
                                          ("right", "Tay phải")])
                    .onChange(of: oneHandMode) { KeyboardSettings.oneHandMode = $0 }
                keyboardDivider()
                keyboardMenuRow("Khoảng cách phím", symbol: "arrow.left.and.right",
                                value: $keySpacingValue,
                                options: ["3","4","5","6","7","8","9"].map { ($0, $0 + " pt") })
                    .onChange(of: keySpacingValue) {
                        KeyboardSettings.keySpacing = Int($0) ?? 6
                    }
                keyboardDivider()
                keyboardMenuRow("Chiều cao phím", symbol: "arrow.up.and.down",
                                value: $keyHeightValue,
                                options: ["40","43","46","49"].map { ($0, $0 + " pt") })
                    .onChange(of: keyHeightValue) {
                        KeyboardSettings.keyHeight = Int($0) ?? 43
                    }
                Text("Bàn phím tải thiết lập mới khi mở lại. Tính năng vuốt chữ sử dụng từ điển offline giới hạn; không tự gửi nội dung gõ tới AI.")
                    .font(.system(size: 11))
                    .foregroundStyle(muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
