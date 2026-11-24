import SwiftUI

struct ToolbarStudioPreview: View {
    let config: ToolbarConfiguration
    var body: some View {
        GeometryReader { proxy in
            let layout = ToolbarLayoutEngine.layout(width: Int(proxy.size.width), configuration: config)
            let palette = KeyboardThemePalette.resolve(KeyboardSettings.theme)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: CGFloat(layout.spacing)) {
                    ForEach(layout.items, id: \.action) { item in
                        Group {
                            if item.presentation == .stacked {
                                VStack(spacing: 3) { icon(item); label(item) }
                            } else {
                                HStack(spacing: 4) { icon(item); if item.presentation == .inline { label(item) } }
                            }
                        }
                        .foregroundStyle(item.action == .ai ? Color.white : Color(uiColor: palette.text))
                        .frame(width: CGFloat(item.width), height: CGFloat(layout.height))
                        .background(item.action == .ai ? Color(red: 0.36, green: 0.30, blue: 0.85) : Color(uiColor: palette.key), in: RoundedRectangle(cornerRadius: CGFloat(config.radius)))
                    }
                }
            }
        }.frame(height: 54)
    }
    private func icon(_ item: ToolbarItemLayout) -> some View { Image(systemName: item.action.symbol).font(.system(size: item.presentation == .icon ? 19 : 15, weight: .semibold)) }
    private func label(_ item: ToolbarItemLayout) -> some View {
        Text(item.action == .ai && item.presentation == .stacked ? "AI" : item.action.title)
            .font(.system(size: item.presentation == .stacked ? 10 : 12, weight: .semibold)).lineLimit(1)
    }
}
