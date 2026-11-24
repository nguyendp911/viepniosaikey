import SwiftUI
import UIKit
import AudioToolbox
import PhotosUI

extension ContentView {
    func card<Content: View>(
        title: String, subtitle: String, icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 11) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(cyan)
                    .frame(width: 38, height: 38)
                    .background(cyan.opacity(0.12), in: RoundedRectangle(cornerRadius: 11))
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardColor, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
    }

    func smallLabel(_ label: String) -> some View {
        Text(label)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(muted)
    }

    func keyField(_ title: String, text: Binding<String>, revealed: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            smallLabel(title)
            HStack(spacing: 8) {
                Group {
                    if revealed.wrappedValue {
                        TextField("Nhập API Key", text: text)
                    } else {
                        SecureField("Nhập API Key", text: text)
                    }
                }
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.system(size: 14))
                .foregroundStyle(.white)
                Button {
                    revealed.wrappedValue.toggle()
                } label: {
                    Image(systemName: revealed.wrappedValue ? "eye.slash" : "eye")
                        .foregroundStyle(muted)
                        .frame(width: 30, height: 32)
                }
                .accessibilityLabel(revealed.wrappedValue ? "Ẩn API Key" : "Hiện API Key")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.white.opacity(0.065), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    func modelField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            smallLabel(title)
            TextField("Nhập tên model", text: text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.system(size: 14))
                .foregroundStyle(.white)
                .padding(12)
                .background(Color.white.opacity(0.065), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    func actionButton(
        _ label: String, symbol: String, prominent: Bool = false, disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: symbol)
                Text(label)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .font(.system(size: 13, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundStyle(prominent ? Color.white : cyan)
            .background(
                prominent ? violet : cyan.opacity(0.11),
                in: RoundedRectangle(cornerRadius: 12)
            )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.46 : 1.0)
    }

    func keyboardPanel<Content: View>(
        _ title: String, icon: String, @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 9) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(cyan)
                    .frame(width: 30, height: 30)
                    .background(cyan.opacity(0.11),
                                in: RoundedRectangle(cornerRadius: 9))
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                Spacer(minLength: 0)
            }
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardColor, in: RoundedRectangle(cornerRadius: 17))
        .overlay(
            RoundedRectangle(cornerRadius: 17)
                .stroke(Color.white.opacity(0.065), lineWidth: 1)
        )
    }

    func keyboardDivider() -> some View {
        Rectangle()
            .fill(.white.opacity(0.075))
            .frame(height: 1)
    }

    func keyboardToggleRow(
        _ title: String, symbol: String, isOn: Binding<Bool>
    ) -> some View {
        Toggle(isOn: isOn) {
            Label {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: symbol)
                    .font(.system(size: 15))
                    .foregroundStyle(muted)
                    .frame(width: 21)
            }
        }
        .tint(violet)
        .controlSize(.regular)
        .frame(minHeight: 37)
    }

    func keyboardMenuRow(
        _ title: String, symbol: String, value: Binding<String>,
        options: [(String, String)]
    ) -> some View {
        Menu {
            ForEach(options.indices, id: \.self) { index in
                let option = options[index]
                Button {
                    value.wrappedValue = option.0
                } label: {
                    Text(option.1)
                    if value.wrappedValue == option.0 {
                        Image(systemName: "checkmark")
                    }
                }
            }
        } label: {
            HStack(spacing: 9) {
                Image(systemName: symbol)
                    .font(.system(size: 15))
                    .foregroundStyle(muted)
                    .frame(width: 21)
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                Spacer(minLength: 6)
                Text(options.first(where: { $0.0 == value.wrappedValue })?.1
                    ?? value.wrappedValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(cyan)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(muted)
            }
            .frame(minHeight: 39)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}
