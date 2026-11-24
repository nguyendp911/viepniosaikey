import SwiftUI

struct KeyboardThemePreview: View {
    let theme: String
    let spacing: Int
    let height: Int
    private var palette: KeyboardThemePalette { .resolve(theme) }
    private var gap: CGFloat { CGFloat(min(9, max(3, spacing))) * 0.55 }
    private var keyHeight: CGFloat { CGFloat(min(49, max(40, height))) * 0.67 }

    private func key(_ title: String, modifier: Bool = false) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.65)
            .foregroundStyle(Color(uiColor: palette.text))
            .frame(maxWidth: .infinity, minHeight: keyHeight, maxHeight: keyHeight)
            .background(Color(uiColor: modifier ? palette.modifier : palette.key),
                        in: RoundedRectangle(cornerRadius: 5))
    }

    var body: some View {
        VStack(spacing: gap) {
            HStack {
                Image(systemName: "sparkles")
                Spacer()
                Text("Xem trước bàn phím")
                    .font(.system(size: 10, weight: .semibold))
                Spacer()
                Image(systemName: "face.smiling")
            }
            .foregroundStyle(Color(uiColor: palette.text))
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            HStack(spacing: gap) {
                ForEach(["Chào", "Hôm nay", "Cảm ơn"], id: \.self) { key($0) }
            }
            ForEach(Array(["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"].enumerated()), id: \.offset) { row, letters in
                HStack(spacing: gap) {
                    if row == 2 { key("⇧", modifier: true) }
                    ForEach(Array(letters), id: \.self) { key(String($0)) }
                    if row == 2 { key("⌫", modifier: true) }
                }
                .padding(.horizontal, row == 1 ? 12 : 0)
            }
            HStack(spacing: gap) {
                key("123", modifier: true).frame(maxWidth: 42)
                key("🌐", modifier: true).frame(maxWidth: 34)
                key("ViePN · VI / EN")
                key("↵", modifier: true).frame(maxWidth: 44)
            }
        }
        .padding(9)
        .background(Color(uiColor: palette.canvas), in: RoundedRectangle(cornerRadius: 13))
        .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(.white.opacity(0.18)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Xem trước chủ đề bàn phím")
    }
}
