import Foundation

@main
struct VerifyToolbar {
    static func main() {
        let original = ToolbarConfiguration()
        precondition(original.visible == [.paste, .couple, .ai, .phrases, .tools])
        for mode in ToolbarMode.allCases {
            for width in [160, 220, 280, 320, 375, 390, 430, 768, 1024] {
                for iconsOnly in [true, false] {
                    var config = ToolbarConfiguration()
                    config.mode = mode; config.iconsOnly = iconsOnly
                    let layout = ToolbarLayoutEngine.layout(width: width, configuration: config)
                    precondition(layout.items.map(\.action) == config.visible)
                    precondition(layout.items.allSatisfy { $0.width >= 44 })
                    precondition(layout.height >= 44)
                    if layout.contentWidth > width {
                        precondition(layout.items.allSatisfy { $0.presentation == .icon })
                    }
                    if iconsOnly { precondition(layout.items.allSatisfy { $0.presentation == .icon }) }
                }
            }
        }
        var migrated = ToolbarConfiguration()
        migrated.order = [.tools, .ai, .ai]; migrated.pins = [.couple]
        migrated.height = 99; migrated.radius = -10
        precondition(migrated.normalized.order.count == 6)
        precondition(Set(migrated.visible) == Set([.paste, .ai, .tools, .couple]))
        precondition(migrated.normalized.height == 52 && migrated.normalized.radius == 4)
        let restored = try! JSONDecoder().decode(ToolbarConfiguration.self, from: JSONEncoder().encode(migrated))
        precondition(restored.normalized == migrated.normalized)
        print("PASS Toolbar: 54 width/mode cases, minimum tap targets, overflow, order and migration")
    }
}
