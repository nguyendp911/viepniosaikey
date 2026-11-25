import SwiftUI

struct PersonalStudioTile: Identifiable {
    let id:String
    let title:String
    let subtitle:String
    let symbol:String
}
struct PersonalStudioGrid: View {
    let tiles:[PersonalStudioTile]
    let action:(String)->Void
    var body:some View {
        LazyVGrid(columns:[GridItem(.adaptive(minimum:145),spacing:10)],spacing:10) {
            ForEach(tiles) { tile in
                Button { action(tile.id) } label: {
                    VStack(alignment:.leading,spacing:7) {
                        Image(systemName:tile.symbol).font(.system(size:21,weight:.medium)).foregroundStyle(.cyan)
                        Text(tile.title).font(.subheadline.bold()).foregroundStyle(.primary)
                        Text(tile.subtitle).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
                    }.frame(maxWidth:.infinity,minHeight:88,alignment:.leading).padding(12)
                        .background(.white.opacity(0.065),in:RoundedRectangle(cornerRadius:14))
                        .overlay { RoundedRectangle(cornerRadius:14).strokeBorder(.white.opacity(0.07)) }
                }.buttonStyle(.plain)
            }
        }
    }
}
struct PersonalIntelligenceDashboard: View {
    @State private var route:String? = nil
    private let tiles:[PersonalStudioTile] = [
        .init(id:"memory",title:"Second Brain",subtitle:"Bộ nhớ được chọn",symbol:"brain.head.profile"),
        .init(id:"timeline",title:"Relationship Timeline",subtitle:"Kỷ niệm và sự kiện",symbol:"calendar.badge.clock"),
        .init(id:"address",title:"Smart Address Book",subtitle:"Hồ sơ và sở thích",symbol:"person.crop.rectangle.stack"),
        .init(id:"tone",title:"Tone Mixer",subtitle:"Phối 6 sắc thái",symbol:"slider.horizontal.3"),
        .init(id:"arena",title:"Response Arena",subtitle:"Gemini và OpenAI",symbol:"square.split.2x1"),
        .init(id:"debate",title:"Debate Studio",subtitle:"Ba góc nhìn",symbol:"person.3"),
        .init(id:"coach",title:"Communication Coach",subtitle:"Luyện giao tiếp",symbol:"graduationcap"),
        .init(id:"document",title:"Document Writer",subtitle:"Email · văn bản",symbol:"doc.text"),
        .init(id:"social",title:"Social Studio",subtitle:"Caption · hashtag",symbol:"text.bubble"),
        .init(id:"tutor",title:"Language Tutor",subtitle:"Sửa và giải thích",symbol:"character.book.closed"),
        .init(id:"extract",title:"Information Extractor",subtitle:"Trích xuất dữ kiện",symbol:"list.bullet.rectangle")
    ]
    var body:some View {
        VStack(alignment:.leading,spacing:14) {
            Text("Personal Intelligence").font(.largeTitle.bold())
            Text("PREMIUM 3.0").font(.caption.bold()).tracking(2).foregroundStyle(.cyan)
            Text("Bộ nhớ có chọn lọc, công cụ giao tiếp và sáng tạo. Không tự đọc tin nhắn.").foregroundStyle(.secondary).font(.subheadline)
            PersonalStudioGrid(tiles:tiles) { route=$0 }
        }.sheet(isPresented:Binding(get:{route != nil},set:{if !$0 {route=nil}})) {
            NavigationStack {
                ScrollView {
                    VStack(alignment:.leading,spacing:14) {
                        switch route {
                        case "memory": PersonalMemoryStudioView(mode:"memory")
                        case "timeline": PersonalMemoryStudioView(mode:"timeline")
                        case "address": PersonalMemoryStudioView(mode:"address")
                        case "tone": ToneMixerStudioView()
                        case "arena": ResponseArenaStudioView()
                        default: if let route,let task=PersonalIntelligenceCatalog.task(route) { PersonalAITaskView(task:task) }
                        }
                    }.padding()
                }.navigationTitle(tiles.first{$0.id==route}?.title ?? "ViePN")
                    .navigationBarTitleDisplayMode(.inline).toolbar { ToolbarItem(placement:.cancellationAction){Button("Đóng"){route=nil}} }
            }.preferredColorScheme(.dark)
        }
    }
}
