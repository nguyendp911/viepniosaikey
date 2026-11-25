import SwiftUI
import UniformTypeIdentifiers

struct ProThemePackage:Codable{
    var version=1
    var theme:String
    var config:OfflineKeyboardConfig
    var design:KeyboardDesign
}
struct ProThemeDocument:FileDocument{
    static var readableContentTypes:[UTType]{[.json]}
    var data:Data
    init(data:Data=Data()){self.data=data}
    init(configuration:ReadConfiguration)throws{guard let data=configuration.file.regularFileContents else{throw CocoaError(.fileReadCorruptFile)};self.data=data}
    func fileWrapper(configuration:WriteConfiguration)throws->FileWrapper{FileWrapper(regularFileWithContents:data)}
}
struct ProThemeWorkshopView:View{
    @State private var importing=false
    @State private var exporting=false
    @State private var document=ProThemeDocument()
    @State private var status=""
    var body:some View{
        VStack(alignment:.leading,spacing:14){
            Text("Theme Workshop").font(.title.bold())
            ProKeyboardPreview(config:OfflineKeyboardConfig.current)
            Text("Xuất JSON gồm màu, hình dáng phím và hiệu ứng. Không gồm ảnh nền, tệp âm thanh, dữ liệu cá nhân, API key hoặc lịch sử.").font(.caption).foregroundStyle(.secondary)
            Button("Xuất theme JSON"){
                var config=OfflineKeyboardConfig.current
                config.profile="Daily";config.history=false;config.analytics=false;config.sound="off"
                let package=ProThemePackage(theme:KeyboardSettings.theme,config:config,design:KeyboardDesign.current)
                if let data=try? JSONEncoder().encode(package){document=ProThemeDocument(data:data);exporting=true}
            }.buttonStyle(.borderedProminent)
            Button("Nhập theme JSON"){importing=true}.buttonStyle(.bordered)
            Text(status).font(.caption).foregroundStyle(.orange)
        }.fileExporter(isPresented:$exporting,document:document,contentType:.json,defaultFilename:"ViePN-Theme"){result in status=(try? result.get()) != nil ? "Đã xuất theme." : "Chưa xuất được."}
            .fileImporter(isPresented:$importing,allowedContentTypes:[.json]){result in
                do{
                    let url=try result.get();let access=url.startAccessingSecurityScopedResource();defer{if access{url.stopAccessingSecurityScopedResource()}}
                    guard let size=try? url.resourceValues(forKeys:[.fileSizeKey]).fileSize,size<100_000 else{status="Tệp quá lớn.";return}
                    let package=try JSONDecoder().decode(ProThemePackage.self,from:Data(contentsOf:url))
                    let d=package.design
                    guard package.version==1,KeyboardSettings.availableThemes.contains(package.theme),[d.canvas,d.key,d.text,d.modifier].allSatisfy({$0.count==6 && UInt32($0,radix:16) != nil}),(0.45...1).contains(d.opacity),(3...18).contains(d.radius) else{status="Theme không hợp lệ.";return}
                    var current=OfflineKeyboardConfig.current
                    let incoming=package.config.normalized
                    current.keycap=incoming.keycap;current.radius=incoming.radius;current.particles=incoming.particles;current.wallpaper=incoming.wallpaper
                    OfflineKeyboardConfig.current=current;KeyboardDesign.current=d;KeyboardSettings.theme=package.theme
                    var schedule=ThemeSchedule.current;schedule.enabled=false;ThemeSchedule.current=schedule
                    status="Đã nhập và áp dụng phần giao diện."
                }catch{status=error.localizedDescription}
            }
    }
}
