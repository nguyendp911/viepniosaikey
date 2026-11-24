import SwiftUI
import UIKit
import AudioToolbox
import PhotosUI

extension ContentView {
    var personalWritingCard: some View {
        keyboardPanel("Phong cách viết cá nhân", icon: "pencil.and.scribble") {
            VStack(alignment: .leading, spacing: 9) {
                Text("Dán một câu mẫu do bạn tự chọn. AI sẽ học giọng điệu từ những câu đã lưu khi bạn chủ động yêu cầu viết lại hoặc gợi ý trả lời.")
                    .font(.system(size: 11))
                    .foregroundStyle(muted)
                    .fixedSize(horizontal: false, vertical: true)
                TextEditor(text: $newWritingSample)
                    .frame(height: 76)
                    .scrollContentBackground(.hidden)
                    .font(.system(size: 12))
                    .padding(7)
                    .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 11))
                    .accessibilityLabel("Ví dụ phong cách viết do bạn tự nhập")
                HStack {
                    Text("Lưu tối đa 8 ví dụ · 350 ký tự / ví dụ")
                        .font(.system(size: 10))
                        .foregroundStyle(muted)
                    Spacer()
                    Button {
                        let value = String(newWritingSample
                            .trimmingCharacters(in: .whitespacesAndNewlines).prefix(350))
                        guard !value.isEmpty, writingSamples.count < 8,
                              MessageSafety.warnings(in: value).isEmpty else { return }
                        writingSamples.append(value)
                        KeyboardSettings.writingSamples = writingSamples
                        newWritingSample = ""
                    } label: {
                        Label("Lưu mẫu", systemImage: "plus")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(violet)
                    .disabled(newWritingSample.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                              || writingSamples.count >= 8
                              || !MessageSafety.warnings(in: newWritingSample).isEmpty)
                }
                ForEach(Array(writingSamples.enumerated()), id: \.offset) { index, sample in
                    HStack(alignment: .top, spacing: 8) {
                        Text(String(format: "%02d", index + 1))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(cyan)
                        Text(sample)
                            .font(.system(size: 11))
                            .foregroundStyle(.white)
                            .lineLimit(3)
                        Spacer(minLength: 0)
                        Button {
                            writingSamples.remove(at: index)
                            KeyboardSettings.writingSamples = writingSamples
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                                .foregroundStyle(.red)
                        }
                        .accessibilityLabel("Xóa ví dụ phong cách \(index + 1)")
                    }
                    .padding(8)
                    .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 10))
                }
                if !writingSamples.isEmpty {
                    Button(role: .destructive) {
                        writingSamples = []
                        KeyboardSettings.writingSamples = []
                    } label: {
                        Label("Xóa toàn bộ phong cách cá nhân", systemImage: "trash")
                            .font(.system(size: 11))
                    }
                }
                Text("Ví dụ lưu trong App Group trên thiết bị, chưa mã hóa. Khi bật AI online và nhấn yêu cầu AI, các mẫu này có thể được gửi cho nhà cung cấp AI. Không lưu thông tin nhạy cảm.")
                    .font(.system(size: 10))
                    .foregroundStyle(muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    var snippetsCard: some View {
        keyboardPanel("Mẫu gõ nhanh", icon: "text.insert") {
            VStack(spacing: 10) {
                Text("Gõ /date, /time, /ten, /camon hoặc ;date rồi nhấn dấu cách. Hỗ trợ {date}, {time}, {recipient} (hồ sơ đã chọn).")
                    .font(.system(size: 11)).foregroundStyle(muted)
                HStack(spacing: 6) {
                    TextField("/phimtat", text: $newSnippetKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .frame(width: 90)
                    TextField("Nội dung thay thế", text: $newSnippetValue)
                    Button {
                        let key = newSnippetKey.trimmingCharacters(in: .whitespacesAndNewlines)
                        let value = newSnippetValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard (key.hasPrefix(";") || key.hasPrefix("/")), key.count >= 2, key.count <= 30,
                              !key.contains(" "), !value.isEmpty else { return }
                        snippets[key] = String(value.prefix(500))
                        KeyboardSettings.textSnippets = snippets
                        newSnippetKey = ""
                        newSnippetValue = ""
                    } label: { Image(systemName: "plus.circle.fill").font(.system(size: 23)) }
                        .accessibilityLabel("Thêm mẫu gõ nhanh")
                }
                .font(.system(size: 12))
                .textFieldStyle(.roundedBorder)
                ForEach(snippets.keys.sorted(), id: \.self) { key in
                    HStack {
                        Text(key).foregroundStyle(cyan)
                            .font(.system(size: 12, weight: .semibold))
                        Text("→").foregroundStyle(muted)
                        Text(snippets[key] ?? "").font(.system(size: 11))
                            .lineLimit(1)
                        Spacer()
                        Button {
                            snippets.removeValue(forKey: key)
                            KeyboardSettings.textSnippets = snippets
                        } label: { Image(systemName: "trash").foregroundStyle(.red.opacity(0.8)) }
                            .accessibilityLabel("Xóa mẫu " + key)
                    }
                }
            }
        }
    }

    var keyboardShortcutsCard: some View {
        keyboardPanel("Từ viết tắt cá nhân", icon: "textformat.abc") {
            VStack(alignment: .leading, spacing: 9) {
                HStack(spacing: 7) {
                    TextField("Viết tắt", text: $shortcut)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .frame(maxWidth: 105)
                    Rectangle().fill(muted.opacity(0.35))
                        .frame(width: 1, height: 22)
                    TextField("Thay bằng…", text: $expansion)
                        .frame(maxWidth: .infinity)
                    Button {
                        let key = shortcut.lowercased()
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        let value = expansion.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !key.isEmpty, key.count <= 20,
                              !value.isEmpty, value.count <= 80 else { return }
                        abbreviations[key] = value
                        KeyboardSettings.replacementDictionary = abbreviations
                        shortcut = ""
                        expansion = ""
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(violet, in: RoundedRectangle(cornerRadius: 9))
                    }
                    .disabled(shortcut.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                              || expansion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityLabel("Thêm từ viết tắt")
                }
                .font(.system(size: 12))
                .padding(8)
                .background(Color.white.opacity(0.06),
                            in: RoundedRectangle(cornerRadius: 12))

                let keys = abbreviations.keys.sorted()
                ForEach(Array((showAllShortcuts ? keys : Array(keys.prefix(3)))),
                        id: \.self) { key in
                    HStack(spacing: 10) {
                        Text(key)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(cyan)
                            .frame(minWidth: 37, alignment: .leading)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10))
                            .foregroundStyle(muted)
                        Text(abbreviations[key] ?? "")
                            .font(.system(size: 12))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                        Spacer(minLength: 0)
                        Button {
                            abbreviations.removeValue(forKey: key)
                            KeyboardSettings.replacementDictionary = abbreviations
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.red.opacity(0.78))
                                .frame(width: 30, height: 30)
                                .background(Color.red.opacity(0.085),
                                            in: RoundedRectangle(cornerRadius: 9))
                        }
                        .accessibilityLabel("Xóa từ viết tắt " + key)
                    }
                    .frame(minHeight: 33)
                    if key != (showAllShortcuts ? keys : Array(keys.prefix(3))).last {
                        keyboardDivider()
                    }
                }
                if keys.count > 3 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showAllShortcuts.toggle()
                        }
                    } label: {
                        Text(showAllShortcuts
                             ? "Thu gọn"
                             : "Xem tất cả " + String(keys.count) + " từ viết tắt")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(cyan)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
                Text("Tự thay từ khi bạn nhấn dấu cách.")
                    .font(.system(size: 11))
                    .foregroundStyle(muted)
            }
        }
    }
}
