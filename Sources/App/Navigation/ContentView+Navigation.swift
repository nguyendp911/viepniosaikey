import SwiftUI
import UIKit
import AudioToolbox
import PhotosUI

extension ContentView {
    var compactHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: "keyboard.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(
                    LinearGradient(colors: [cyan, violet], startPoint: .topLeading,
                                   endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 11)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text("ViePN AI Keyboard")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text("AI · Couple · Tiếng Việt")
                    .font(.system(size: 11))
                    .foregroundStyle(muted)
            }
            Spacer(minLength: 0)
            Text(provider == "gemini" ? "Gemini" : "OpenAI")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(cyan)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(cyan.opacity(0.1), in: Capsule())
        }
    }

    var bottomNavigation: some View {
        HStack(spacing: 2) {
            tabItem("Couple", symbol: "heart.fill", page: "couple")
            tabItem("AI & API", symbol: "sparkles", page: "ai")
            tabItem("Bàn phím", symbol: "keyboard", page: "keyboard")
            tabItem("Trợ lý", symbol: "wand.and.stars", page: "assistant")
            tabItem("Công cụ", symbol: "square.grid.2x2", page: "tools")
            tabItem("Sở hữu", symbol: "person.crop.circle.badge.checkmark", page: "owner")
        }
        .padding(.horizontal, 7)
        .padding(.top, 9)
        .padding(.bottom, 4)
        .background {
            Color(red: 0.09, green: 0.11, blue: 0.18)
                .ignoresSafeArea(edges: .bottom)
        }
        .overlay(alignment: .top) {
            Rectangle().fill(.white.opacity(0.08)).frame(height: 1)
        }
    }

    func tabItem(_ title: String, symbol: String, page: String) -> some View {
        let active = selectedPage == page
        return Button {
            // Avoid animating construction/teardown of a large settings tree.
            selectedPage = page
        } label: {
            VStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: active ? .semibold : .regular))
                Text(title)
                    .font(.system(size: 9, weight: active ? .bold : .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
            }
            .foregroundStyle(active ? cyan : muted)
            .frame(maxWidth: .infinity)
            .frame(height: 45)
            .background(active ? cyan.opacity(0.10) : .clear,
                        in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(active ? [.isSelected] : [])
        .accessibilityIdentifier("tab." + page)
    }
}
