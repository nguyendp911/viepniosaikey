import SwiftUI
import AVFoundation
import AudioToolbox
import UniformTypeIdentifiers
import UIKit

struct ProSoundStudioView:View{
    @State private var config=OfflineKeyboardConfig.current
    @State private var importing=false
    @State private var status=""
    @State private var player:AVAudioPlayer?
    var body:some View{
        VStack(alignment:.leading,spacing:14){
            Text("Sound & Haptic").font(.title.bold())
            Picker("Âm thanh",selection:$config.sound){Text("Theo cài đặt cũ / Tắt").tag("off");Text("Click").tag("click");Text("Soft").tag("soft");Text("Tệp riêng").tag("custom")}
            Button("Nhập WAV / MP3 / M4A"){importing=true}.buttonStyle(.bordered)
            Text("Tệp tối đa 2 MB, không quá 3 giây. Chỉ lưu trong App Group; phát âm thanh tùy thuộc thiết bị và chế độ im lặng.").font(.caption).foregroundStyle(.secondary)
            Text("Âm lượng tệp riêng: \(Int(config.volume*100))%")
            Slider(value:$config.volume,in:0...1,step:0.05)
            Text("Cường độ rung: \(Int(config.feedback*100))%")
            Slider(value:$config.feedback,in:0.1...1,step:0.05)
            Button("Nghe và thử rung"){
                if config.sound=="custom",let url=ProSoundFile.url{player=try? AVAudioPlayer(contentsOf:url);player?.volume=Float(config.volume);player?.play()}
                else if config.sound=="click"{AudioServicesPlaySystemSound(1104)}
                else if config.sound=="soft"{AudioServicesPlaySystemSound(1123)}
                UIImpactFeedbackGenerator(style:.light).impactOccurred(intensity:CGFloat(config.feedback))
            }.buttonStyle(.borderedProminent)
            Text(status).font(.caption).foregroundStyle(.orange)
        }.onChange(of:config){OfflineKeyboardConfig.current=$0}
            .fileImporter(isPresented:$importing,allowedContentTypes:[.audio]){result in
                do{
                    let url=try result.get();let access=url.startAccessingSecurityScopedResource();defer{if access{url.stopAccessingSecurityScopedResource()}}
                    guard let size=try? url.resourceValues(forKeys:[.fileSizeKey]).fileSize,size<=2_000_000,let destination=ProSoundFile.url else{status="Tệp quá lớn hoặc App Group không khả dụng.";return}
                    let data=try Data(contentsOf:url)
                    let test=try AVAudioPlayer(data:data)
                    guard test.duration>0,test.duration<=3 else{status="Chọn âm thanh ngắn tối đa 3 giây.";return}
                    try data.write(to:destination,options:[.atomic,.completeFileProtectionUntilFirstUserAuthentication])
                    config.sound="custom";status="Đã nhập âm thanh."
                }catch{status=error.localizedDescription}
            }.onDisappear{player?.stop();player=nil}
    }
}
