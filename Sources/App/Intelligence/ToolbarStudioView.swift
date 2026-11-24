import SwiftUI

struct ToolbarStudioView: View {
    @State private var order = ToolbarPreferences.order
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Di chuyển nút lên hoặc xuống. Thứ tự thay đổi khi mở lại bàn phím; không ẩn nút đổi bàn phím của iOS.").font(.caption).foregroundStyle(.secondary)
            ForEach(order.indices, id: \.self) { i in
                HStack {
                    Text(ToolbarPreferences.title(order[i]))
                    Spacer()
                    Button { order.swapAt(i, i-1); ToolbarPreferences.order = order } label: { Image(systemName: "arrow.up") }.disabled(i == 0)
                    Button { order.swapAt(i, i+1); ToolbarPreferences.order = order } label: { Image(systemName: "arrow.down") }.disabled(i == order.count-1)
                }.buttonStyle(.bordered)
            }
            Button("Khôi phục mặc định") { order = ToolbarPreferences.standard; ToolbarPreferences.order = order }
        }
    }
}
