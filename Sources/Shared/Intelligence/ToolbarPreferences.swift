import Foundation

enum ToolbarAction: String, CaseIterable, Codable {
    case paste, couple, ai, offline, phrases, tools
    var title: String {
        switch self {
        case .paste: return "Dán"
        case .couple: return "Couple"
        case .ai: return "ViePN AI"
        case .offline: return "Offline"
        case .phrases: return "Mẫu"
        case .tools: return "Công cụ"
        }
    }
    var symbol: String {
        switch self {
        case .paste: return "doc.on.clipboard"
        case .couple: return "heart"
        case .ai: return "sparkles"
        case .offline: return "wifi.slash"
        case .phrases: return "text.quote"
        case .tools: return "square.grid.2x2"
        }
    }
    // Keep primary access and long-press menus reachable.
    var required: Bool { self == .paste || self == .ai || self == .tools }
}

enum ToolbarMode: String, CaseIterable, Codable {
    case premium, compact, classic
    var title: String { rawValue.capitalized }
}

struct ToolbarConfiguration: Codable, Equatable {
    var mode: ToolbarMode = .premium
    var order: [ToolbarAction] = ToolbarAction.allCases
    // nil = mode defaults; explicit pins apply across modes.
    var pins: [ToolbarAction]? = nil
    var height: Int = 44
    var radius: Int = 10
    var iconsOnly: Bool = false

    var normalized: Self {
        var result = self
        var seen = Set<ToolbarAction>()
        result.order = (order + ToolbarAction.allCases).filter { seen.insert($0).inserted }
        if let pins {
            let allowed = Set(pins + ToolbarAction.allCases.filter(\.required))
            result.pins = result.order.filter { allowed.contains($0) }
        }
        result.height = min(52, max(38, height))
        result.radius = min(18, max(4, radius))
        return result
    }
    var visible: [ToolbarAction] {
        let config = normalized
        let set = Set(config.pins ?? (mode == .premium ? [.paste, .couple, .ai, .phrases, .tools] : ToolbarAction.allCases))
        return config.order.filter { set.contains($0) }
    }
}

enum ToolbarPreferences {
    static let standard = ToolbarAction.allCases.map(\.rawValue)
    static func title(_ id: String) -> String { ToolbarAction(rawValue: id)?.title ?? id }
    static var configuration: ToolbarConfiguration {
        get {
            if let data = KeyboardSettings.defaults.data(forKey: "viepnaikey.toolbar.v2"),
               let decoded = try? JSONDecoder().decode(ToolbarConfiguration.self, from: data) {
                return decoded.normalized
            }
            var migrated = ToolbarConfiguration()
            if let legacy = KeyboardSettings.defaults.stringArray(forKey: "viepnaikey.toolbarOrder") {
                migrated.order = legacy.compactMap(ToolbarAction.init(rawValue:))
            }
            return migrated.normalized
        }
        set {
            if let data = try? JSONEncoder().encode(newValue.normalized) {
                KeyboardSettings.defaults.set(data, forKey: "viepnaikey.toolbar.v2")
            }
        }
    }
    static var order: [String] {
        get { configuration.order.map(\.rawValue) }
        set { var config = configuration; config.order = newValue.compactMap(ToolbarAction.init(rawValue:)); configuration = config }
    }
}
