import Foundation

enum ToolbarPresentation: Equatable { case icon, inline, stacked }
struct ToolbarItemLayout: Equatable {
    let action: ToolbarAction
    let width: Int
    let presentation: ToolbarPresentation
}
struct ToolbarLayout: Equatable {
    let items: [ToolbarItemLayout]
    let height: Int
    let spacing: Int
    var contentWidth: Int { items.reduce(0) { $0 + $1.width } + max(0, items.count - 1) * spacing }
}

enum ToolbarLayoutEngine {
    static func layout(width: Int, configuration: ToolbarConfiguration) -> ToolbarLayout {
        let config = configuration.normalized
        let actions = config.visible
        let spacing = 5
        let available = max(0, width - max(0, actions.count - 1) * spacing)
        var presentations = actions.map { action -> ToolbarPresentation in
            if config.iconsOnly || config.mode == .compact { return .icon }
            if config.mode == .classic { return .stacked }
            return [.couple, .tools, .offline].contains(action) ? .icon : .inline
        }
        func minimum(_ action: ToolbarAction, _ presentation: ToolbarPresentation) -> Int {
            switch presentation {
            case .icon: return 44
            case .stacked: return action == .tools ? 58 : 55
            case .inline: return action == .ai ? 96 : 64
            }
        }
        func total() -> Int { zip(actions, presentations).reduce(0) { $0 + minimum($1.0, $1.1) } }
        // Drop labels before ever reducing touch targets. Scroll at extreme widths.
        if total() > available {
            for action in [.phrases, .paste, .offline, .couple, .tools, .ai] as [ToolbarAction] {
                if total() <= available { break }
                if let index = actions.firstIndex(of: action) { presentations[index] = .icon }
            }
        }
        var widths = zip(actions, presentations).map { minimum($0.0, $0.1) }
        let extra = max(0, available - widths.reduce(0, +))
        // AI receives extra room, other controls share the remaining space.
        let weights = actions.map { $0 == .ai ? 2 : 1 }
        let denominator = max(1, weights.reduce(0, +))
        var distributed = 0
        for index in widths.indices {
            let addition = extra * weights[index] / denominator
            widths[index] += addition; distributed += addition
        }
        if let ai = actions.firstIndex(of: .ai) { widths[ai] += extra - distributed }
        let items = actions.indices.map { ToolbarItemLayout(action: actions[$0], width: widths[$0], presentation: presentations[$0]) }
        return .init(items: items, height: max(config.height, presentations.contains(.stacked) ? 52 : 44), spacing: spacing)
    }
}
