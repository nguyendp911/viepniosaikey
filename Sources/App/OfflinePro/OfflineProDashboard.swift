import SwiftUI

struct OfflineProDashboard:View {
    @State private var route:String?
    private let tiles:[PersonalStudioTile] = [
        .init(id:"layout",title:"Layout Designer",subtitle:"8 bố cục · Hangul · hàng số",symbol:"keyboard"),
        .init(id:"visual",title:"Visual Engine",subtitle:"Keycap · RGB · hạt sáng",symbol:"sparkles"),
        .init(id:"sound",title:"Sound & Haptic",subtitle:"Nhập âm thanh · độ rung",symbol:"waveform"),
        .init(id:"theme",title:"Theme Workshop",subtitle:"Nhập và xuất cấu hình",symbol:"paintpalette"),
        .init(id:"profiles",title:"Keyboard Profiles",subtitle:"Daily · Business · Private",symbol:"person.crop.rectangle.stack"),
        .init(id:"snippets",title:"Text Expander",subtitle:"Phím tắt · chữ ký",symbol:"bolt"),
        .init(id:"text",title:"Font & Text",subtitle:"Unicode · chữ nghệ thuật",symbol:"textformat"),
        .init(id:"productivity",title:"Productivity",subtitle:"Bảng · biểu mẫu · mã hóa",symbol:"square.grid.2x2"),
        .init(id:"typing",title:"Typing Challenge",subtitle:"Luyện gõ · thống kê",symbol:"speedometer"),
        .init(id:"piano",title:"Keyboard Piano",subtitle:"Đàn mini",symbol:"pianokeys"),
        .init(id:"art",title:"Sticker & Pixel Art",subtitle:"Tạo ảnh · sao chép",symbol:"photo.artframe"),
        .init(id:"unicode",title:"Emoji & Unicode",subtitle:"Tìm và lưu yêu thích",symbol:"face.smiling")
    ]
    var body:some View {
        VStack(alignment:.leading,spacing:14){
            Text("Keyboard Pro").font(.largeTitle.bold())
            Text("OFFLINE EDITION 4.0").font(.caption.bold()).tracking(2).foregroundStyle(.cyan)
            Text("Tự thiết kế bàn phím, tăng tốc nhập liệu và sáng tạo trên thiết bị. Không gọi AI hay yêu cầu API key.").font(.subheadline).foregroundStyle(.secondary)
            PersonalStudioGrid(tiles:tiles){route=$0}
        }.sheet(isPresented:Binding(get:{route != nil},set:{if !$0{route=nil}})){
            NavigationStack{
                ScrollView{
                    VStack(alignment:.leading,spacing:14){
                        switch route{
                        case "layout": ProLayoutStudioView()
                        case "visual": ProVisualStudioView()
                        case "sound": ProSoundStudioView()
                        case "theme": ProThemeWorkshopView()
                        case "profiles": ProProfilesStudioView()
                        case "snippets": ProSnippetStudioView()
                        case "text": ProFontStudioView()
                        case "productivity": ProProductivityStudioView()
                        case "typing": ProTypingStudioView()
                        case "piano": ProPianoStudioView()
                        case "art": ProArtStudioView()
                        case "unicode": ProUnicodeStudioView()
                        default: EmptyView()
                        }
                    }.padding()
                }.navigationTitle(tiles.first{$0.id==route}?.title ?? "Keyboard Pro").navigationBarTitleDisplayMode(.inline)
                    .toolbar{ToolbarItem(placement:.cancellationAction){Button("Đóng"){route=nil}}}
            }.preferredColorScheme(.dark)
        }
    }
}
