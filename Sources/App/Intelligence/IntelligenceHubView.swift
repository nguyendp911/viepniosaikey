import SwiftUI

struct IntelligenceHubView: View {
    @State private var route: String? = nil
    private let tiles: [(String, String, String)] = [
        ("Premium 2.0", "sparkles.rectangle.stack", "Command · AI · Offline"),
        ("Workflow & Macro", "arrow.triangle.branch", "Chuỗi xử lý"),
        ("Kho cá nhân", "archivebox", "Drafts · Clipboard · Variables"),
        ("Trải nghiệm Pro", "paintpalette.fill", "Gesture · Ghost · Visual"),
        ("Hội thoại", "bubble.left.and.bubble.right", "Smart Conversation"),
        ("Tình cảm", "heart", "Relationship Studio"),
        ("Dịch", "globe", "Live Translator"),
        ("Ảnh hội thoại", "viewfinder", "Screenshot 2.0"),
        ("Văn phong", "fingerprint", "Personal DNA"),
        ("Giao diện", "paintpalette", "Keyboard Designer"),
        ("Công việc", "briefcase", "Business Assistant"),
        ("Emoji", "face.smiling", "Emoji & Symbol"),
        ("Prompt", "text.badge.plus", "Prompt Studio"),
        ("Từ điển", "book", "Smart Dictionary"),
        ("Thanh công cụ", "slider.horizontal.3", "Toolbar Studio"),
        ("Riêng tư", "hand.raised", "Privacy Studio")
    ]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles").font(.title2).foregroundStyle(.cyan)
                VStack(alignment: .leading) {
                    Text("ViePN Intelligence").font(.title2.bold())
                    Text("Trung tâm công cụ · AI & Offline").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 9) {
                ForEach(tiles, id: \.0) { tile in
                    Button { route = tile.0 } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Image(systemName: tile.1).font(.title2).foregroundStyle(.cyan)
                            Text(tile.0).font(.system(size: 14, weight: .semibold))
                            Text(tile.2).font(.system(size: 10)).foregroundStyle(.secondary)
                        }.frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12).background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
                    }.buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 18))
        .fullScreenCover(isPresented: Binding(get: { route != nil }, set: { if !$0 { route = nil } })) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        switch route {
                        case "Premium 2.0": PremiumCommandStudioView()
                        case "Workflow & Macro": PremiumAutomationStudioView()
                        case "Kho cá nhân": PremiumVaultStudioView()
                        case "Trải nghiệm Pro": PremiumExperienceStudioView()
                        case "Hội thoại": IntelligenceWritingView(group: "Hội thoại")
                        case "Tình cảm": IntelligenceWritingView(group: "Tình cảm")
                        case "Công việc": IntelligenceWritingView(group: "Công việc")
                        case "Dịch": IntelligenceWritingView(group: "Dịch")
                        case "Ảnh hội thoại": ScreenshotStudioView()
                        case "Văn phong": PersonalDNAView()
                        case "Giao diện": KeyboardDesignerView()
                        case "Emoji": SymbolStudioView()
                        case "Prompt": PromptStudioView()
                        case "Từ điển": DictionaryStudioView()
                        case "Thanh công cụ": ToolbarStudioView()
                        case "Riêng tư": PrivacyStudioView()
                        default: EmptyView()
                        }
                    }.padding()
                }
                .navigationTitle(route ?? "Công cụ").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Đóng") { route = nil } } }
            }.preferredColorScheme(.dark)
        }
    }
}
