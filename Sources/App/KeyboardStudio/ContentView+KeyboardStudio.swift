import SwiftUI
import UIKit
import AudioToolbox
import PhotosUI

extension ContentView {
    func themeSampleColor(_ id: String) -> Color {
        Color(uiColor: KeyboardThemePalette.resolve(id).canvas)
    }

    func themeDisplayName(_ id: String) -> String {
        let names = ["titanium": "Titanium Black", "purewhite": "Pure White", "cyberneon": "Cyber Neon", "rosegold": "Rose Gold", "jade": "Emerald Jade", "heritage": "Vietnam Heritage"]
        return names[id] ?? (id.prefix(1).uppercased() + id.dropFirst())
    }

    // Four focused cards keep settings aligned, labeled, and easy to tap.
    // No system Picker is placed directly in a large VStack: every selection
    // belongs to its own full-width Menu row.
    var personalization: some View {
        LazyVStack(spacing: 12) {
            AnyView(keyboardInputCard).accessibilityIdentifier("keyboard.input")
            AnyView(TypingProEntryView())
            AnyView(keyboardPreferencesCard)
            AnyView(smartTypingCard).accessibilityIdentifier("keyboard.smart")
            AnyView(personalWritingCard)
            AnyView(keyboardThemesCard)
            AnyView(keyboardShortcutsCard)
            AnyView(snippetsCard)
            AnyView(keyboardBackupCard)
        }
        .accessibilityIdentifier("keyboard.settings")
    }

    var keyboardBackupCard: some View {
            keyboardPanel("Sao lưu cài đặt", icon: "externaldrive.badge.checkmark") {
                KeyboardBackupView {
                    typingMode = KeyboardSettings.typingMode
                    telexEnabled = KeyboardSettings.telexEnabled
                    keyboardTheme = KeyboardSettings.theme
                    keypressEffect = KeyboardSettings.keypressEffect
                    keySpacingValue = String(KeyboardSettings.keySpacing)
                    keyHeightValue = String(KeyboardSettings.keyHeight)
                    oneHandMode = KeyboardSettings.oneHandMode
                    smartBilingual = KeyboardSettings.smartBilingual
                    bilingualPreference = KeyboardSettings.bilingualPreference
                    predictionsEnabled = KeyboardSettings.predictionsEnabled
                    sentenceSuggestionsEnabled = KeyboardSettings.sentenceSuggestionsEnabled
                    glideEnabled = KeyboardSettings.glideEnabled
                    glideTrailEnabled = KeyboardSettings.glideTrailEnabled
                    performanceMode = KeyboardSettings.performanceMode
                    hapticEnabled = KeyboardSettings.hapticEnabled
                    hapticStyle = KeyboardSettings.hapticStyle
                    preferredTone = KeyboardSettings.preferredTone
                    preferredLength = KeyboardSettings.preferredLength
                    translationLanguage = KeyboardSettings.translationLanguage
                }
            }
    }

    var keyboardThemesCard: some View {
        keyboardPanel("Giao diện bàn phím", icon: "paintpalette") {
            VStack(alignment: .leading, spacing: 10) {
                keyboardMenuRow("Chủ đề", symbol: "circle.lefthalf.filled",
                                value: $keyboardTheme,
                                options: [("system", "Theo hệ thống"),
                                          ("midnight", "Midnight"), ("ocean", "Ocean"),
                                          ("rose", "Rose"), ("lavender", "Lavender"),
                                          ("mint", "Mint"), ("sunset", "Sunset"),
                                          ("graphite", "Graphite"), ("sakura", "Sakura"),
                                          ("forest", "Forest"), ("sand", "Sand"),
                                          ("aurora", "Aurora"), ("amoled", "AMOLED"),
                                          ("neon", "Neon"), ("cyberpunk", "Cyberpunk"),
                                          ("coffee", "Coffee"), ("ice", "Ice"),
                                          ("gold", "Gold")])
                    .onChange(of: keyboardTheme) { KeyboardSettings.theme = $0 }
                keyboardDivider()
                keyboardMenuRow("Hiệu ứng khi chạm phím", symbol: "sparkles",
                                value: $keypressEffect,
                                options: [("off", "Không hiệu ứng · Mượt nhất"),
                                          ("pop", "Pop · Nhấn nhẹ"),
                                          ("glow", "Glow · Phát sáng"),
                                          ("bounce", "Bounce · Nảy phím"),
                                          ("flash", "Flash · Chớp sáng")])
                    .onChange(of: keypressEffect) {
                        KeyboardSettings.keypressEffect = $0
                    }
                Text("Hiệu ứng chạy trên lớp phím có sẵn, không tạo thêm giao diện khi gõ. Chế độ Siêu nhẹ tự tắt hiệu ứng; cài đặt Giảm chuyển động của iOS cũng được tôn trọng.")
                    .font(.system(size: 11)).foregroundStyle(muted)
                    .fixedSize(horizontal: false, vertical: true)
                keyboardDivider()

                KeyboardThemePreview(theme: keyboardTheme, spacing: Int(keySpacingValue) ?? 6, height: Int(keyHeightValue) ?? 43)
                let themes = KeyboardSettings.availableThemes
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4),
                    spacing: 10
                ) {
                    ForEach(Array((showAllThemes ? themes : Array(themes.prefix(8)))),
                            id: \.self) { id in
                        Button {
                            keyboardTheme = id
                            KeyboardSettings.theme = id
                        } label: {
                            VStack(spacing: 5) {
                                RoundedRectangle(cornerRadius: 9)
                                    .fill(themeSampleColor(id))
                                    .frame(height: 39)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 9)
                                            .stroke(keyboardTheme == id ? cyan :
                                                        Color.white.opacity(0.18),
                                                    lineWidth: keyboardTheme == id ? 2.5 : 1)
                                    }
                                    .overlay {
                                        HStack(spacing: 3) {
                                            ForEach(["A", "S", "D"], id: \.self) { letter in
                                                Text(letter)
                                                    .font(.system(size: 10, weight: .bold,
                                                                  design: .rounded))
                                                    .foregroundStyle(Color(uiColor: KeyboardThemePalette.resolve(id).text))
                                                    .frame(width: 18, height: 23)
                                                    .background(Color(uiColor: KeyboardThemePalette.resolve(id).key),
                                                                in: RoundedRectangle(cornerRadius: 5))
                                            }
                                        }
                                    }
                                    .overlay(alignment: .topTrailing) {
                                        if keyboardTheme == id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 13))
                                                .foregroundStyle(cyan)
                                                .padding(3)
                                        }
                                    }
                                Text(id == "system" ? "Tự động" : themeDisplayName(id))
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(keyboardTheme == id ? cyan : muted)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Chủ đề " + (id == "system" ? "Tự động" : id))
                    }
                }
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showAllThemes.toggle()
                    }
                } label: {
                    HStack(spacing: 5) {
                        Text(showAllThemes ? "Thu gọn" : "Xem đủ \(themes.count) chủ đề")
                        Image(systemName: showAllThemes ? "chevron.up" : "chevron.down")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(cyan)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 3)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
