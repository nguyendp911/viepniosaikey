import SwiftUI

struct ToolbarStudioView: View {
    @State private var config = ToolbarPreferences.configuration
    @State private var dragged: ToolbarAction?
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Thanh công cụ Premium").font(.title2.bold())
            Text("Xem trước theo chiều rộng thực tế. Dán, AI và Công cụ luôn có mặt; các nút khác có thể ẩn hoặc đổi vị trí.").font(.caption).foregroundStyle(.secondary)
            Picker("Kiểu", selection: $config.mode) {
                ForEach(ToolbarMode.allCases, id: \.self) { Text($0.title).tag($0) }
            }.pickerStyle(.segmented)
            ToolbarStudioPreview(config: config)
            Text("Nút ghim · kéo thả hoặc dùng mũi tên").font(.headline)
            ForEach(config.order, id: \.self) { action in
                HStack {
                    Image(systemName: action.symbol).foregroundStyle(.cyan).frame(width: 24)
                    Text(action.title)
                    Spacer()
                    Toggle("Ghim " + action.title, isOn: Binding(get: { config.visible.contains(action) }, set: { value in
                        var pins = Set(config.visible)
                        if value { pins.insert(action) } else { pins.remove(action) }
                        config.pins = config.order.filter { pins.contains($0) }
                    })).labelsHidden().disabled(action.required)
                    Button { move(action, -1) } label: { Image(systemName: "chevron.up") }.disabled(config.order.first == action)
                    Button { move(action, 1) } label: { Image(systemName: "chevron.down") }.disabled(config.order.last == action)
                    Image(systemName: "line.3.horizontal").foregroundStyle(.secondary)
                        .onDrag { dragged = action; return NSItemProvider(object: action.rawValue as NSString) }
                }.buttonStyle(.borderless).padding(10)
                    .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
                    .dropDestination(for: String.self) { items, _ in
                        guard let source = items.first.flatMap(ToolbarAction.init(rawValue:)),
                              let from = config.order.firstIndex(of: source), let to = config.order.firstIndex(of: action), from != to else { return false }
                        config.order.remove(at: from); config.order.insert(source, at: to); dragged = nil
                        return true
                    }
            }
            Button("Dùng ghim mặc định theo chế độ") { config.pins = nil }.buttonStyle(.bordered)
            Toggle("Chỉ biểu tượng", isOn: $config.iconsOnly)
            Text("Chiều cao: \(max(44, config.height)) pt")
            Slider(value: Binding(get: { Double(config.height) }, set: { config.height = Int($0) }), in: 44...52, step: 1)
            Text("Bo góc: \(config.radius) pt")
            Slider(value: Binding(get: { Double(config.radius) }, set: { config.radius = Int($0) }), in: 4...18, step: 1)
            Text("Tự lưu khi thay đổi. Mở lại bàn phím để áp dụng. Classic có chữ dưới icon; nếu quá hẹp, tự giảm chữ trước khi cuộn ngang.").font(.caption).foregroundStyle(.secondary)
            Button("Khôi phục mặc định") { config = ToolbarConfiguration() }.buttonStyle(.bordered)
        }.onChange(of: config) { ToolbarPreferences.configuration = $0 }
    }
    private func move(_ action: ToolbarAction, _ offset: Int) {
        guard let i = config.order.firstIndex(of: action), config.order.indices.contains(i+offset) else { return }
        config.order.swapAt(i, i+offset)
    }
}
