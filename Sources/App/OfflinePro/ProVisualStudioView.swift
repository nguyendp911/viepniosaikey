import SwiftUI

struct ProVisualStudioView:View {
    @State private var config=OfflineKeyboardConfig.current
    var body:some View{
        VStack(alignment:.leading,spacing:14){
            Text("Visual Engine").font(.title.bold())
            Text("Phím cơ, kính và viền vàng; hiệu ứng hạt và RGB có giới hạn tài nguyên.").font(.caption).foregroundStyle(.secondary)
            ProKeyboardPreview(config:config)
            Picker("Vật liệu phím",selection:$config.keycap){
                Text("Classic").tag("flat");Text("3D Mechanical").tag("mechanical");Text("Crystal Glass").tag("crystal");Text("Vietnam Heritage").tag("heritage")
            }
            Text("Bo góc: \(config.radius) pt")
            Slider(value:Binding(get:{Double(config.radius)},set:{config.radius=Int($0)}),in:3...18,step:1)
            Picker("Hiệu ứng khi gõ",selection:$config.particles){
                Text("Tắt").tag("off");Text("Hạt sáng / Typing Trail").tag("spark");Text("Trái tim").tag("heart");Text("Cánh hoa").tag("petal");Text("RGB Wave").tag("rgb")
            }
            Picker("Hình nền chuyển động",selection:$config.wallpaper){
                Text("Tắt").tag("off");Text("Aurora").tag("aurora");Text("Night Sky").tag("stars");Text("Lotus").tag("lotus")
            }
            if config.wallpaper != "off" {
                TimelineView(.animation(minimumInterval:0.08)){context in
                    let x=(sin(context.date.timeIntervalSinceReferenceDate*0.6)+1)/2
                    LinearGradient(colors:config.wallpaper=="lotus" ? [.purple,.pink,.black] : [.indigo,.teal,.black],startPoint:UnitPoint(x:x,y:0),endPoint:.bottomTrailing)
                        .frame(height:65).clipShape(RoundedRectangle(cornerRadius:12))
                }
            }
            Text("Hiệu ứng chuyển động sẽ tắt khi Reduce Motion hoặc chế độ hiệu năng được bật.").font(.caption).foregroundStyle(.secondary)
            Button("Khôi phục vật liệu mặc định"){config.keycap="flat";config.particles="off";config.wallpaper="off";config.radius=8}.buttonStyle(.bordered)
        }.onChange(of:config){OfflineKeyboardConfig.current=$0}
    }
}
