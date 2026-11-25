import SwiftUI

struct PersonalMiniAppsView:View {
    @State private var route:String?
    private let tiles:[PersonalStudioTile] = [
        .init(id:"screen",title:"Screen to Action",subtitle:"OCR · tác vụ",symbol:"viewfinder"),
        .init(id:"reminder",title:"Smart Reminder",subtitle:"Nhắc hẹn cục bộ",symbol:"bell.badge"),
        .init(id:"units",title:"Unit Converter",subtitle:"Đơn vị · tỷ giá nhập tay",symbol:"ruler"),
        .init(id:"qr",title:"QR Studio",subtitle:"Tạo ảnh QR offline",symbol:"qrcode"),
        .init(id:"password",title:"Secure Generator",subtitle:"Mật khẩu trên thiết bị",symbol:"key"),
        .init(id:"notes",title:"Smart Notes",subtitle:"Ghi chú · AI cấu trúc",symbol:"note.text"),
        .init(id:"diff",title:"Text Diff Studio",subtitle:"So sánh hai văn bản",symbol:"arrow.left.arrow.right"),
        .init(id:"calc",title:"Máy tính",subtitle:"Biểu thức offline",symbol:"calculator"),
        .init(id:"date",title:"Ngày giờ",subtitle:"Ngày giờ thiết bị",symbol:"clock"),
        .init(id:"tutor",title:"Ngoại ngữ",subtitle:"Language Tutor",symbol:"character.book.closed"),
        .init(id:"social",title:"Caption",subtitle:"Social Studio",symbol:"text.bubble")
    ]
    var body:some View {
        VStack(alignment:.leading,spacing:14){
            Text("ViePN Mini Apps").font(.largeTitle.bold())
            Text("Công cụ nhỏ, dữ liệu do bạn chủ động nhập. Những chức năng ảnh và thông báo chạy trong ứng dụng chính.").font(.caption).foregroundStyle(.secondary)
            PersonalStudioGrid(tiles:tiles){route=$0}
        }.sheet(isPresented:Binding(get:{route != nil},set:{if !$0{route=nil}})){
            NavigationStack{
                ScrollView{
                    VStack(alignment:.leading,spacing:14){
                        switch route{
                        case "screen": ScreenActionStudioView()
                        case "reminder": SmartReminderStudioView()
                        case "units": UnitConverterStudioView()
                        case "qr": QRStudioView()
                        case "password": SecureGeneratorStudioView()
                        case "notes": SmartNotesStudioView()
                        case "diff": TextDiffStudioView()
                        case "calc": MiniCalculatorView()
                        case "date": MiniDateView()
                        default: if let route,let task=PersonalIntelligenceCatalog.task(route){PersonalAITaskView(task:task)}
                        }
                    }.padding()
                }.navigationTitle(tiles.first{$0.id==route}?.title ?? "Mini Apps").navigationBarTitleDisplayMode(.inline)
                    .toolbar{ToolbarItem(placement:.cancellationAction){Button("Đóng"){route=nil}}}
            }.preferredColorScheme(.dark)
        }
    }
}
