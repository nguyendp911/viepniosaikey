import SwiftUI
import AVFoundation

final class ProPianoEngine:ObservableObject{
    private var player:AVAudioPlayer?
    func play(_ midi:Int){
        let rate=22050,count=Int(Double(rate)*0.45),frequency=440*pow(2,Double(midi-69)/12)
        var pcm=Data()
        for i in 0..<count{
            let t=Double(i)/Double(rate)
            let envelope=min(1,t/0.009)*exp(-6*t)*min(1,Double(count-i)/350)
            let wave=sin(2*Double.pi*frequency*t)+0.22*sin(4*Double.pi*frequency*t)
            var sample=Int16(max(-32767,min(32767,wave*envelope*19000))).littleEndian
            withUnsafeBytes(of:&sample){pcm.append(contentsOf:$0)}
        }
        var data=Data("RIFF".utf8)
        func append32(_ n:UInt32){var value=n.littleEndian;withUnsafeBytes(of:&value){data.append(contentsOf:$0)}}
        func append16(_ n:UInt16){var value=n.littleEndian;withUnsafeBytes(of:&value){data.append(contentsOf:$0)}}
        append32(UInt32(36+pcm.count));data.append(Data("WAVEfmt ".utf8));append32(16);append16(1);append16(1);append32(UInt32(rate));append32(UInt32(rate*2));append16(2);append16(16);data.append(Data("data".utf8));append32(UInt32(pcm.count));data.append(pcm)
        player=try? AVAudioPlayer(data:data);player?.play()
    }
    func stop(){player?.stop();player=nil}
}
struct ProPianoStudioView:View{
    @StateObject private var engine=ProPianoEngine()
    @State private var octave=4
    @State private var last=""
    var body:some View{
        VStack(alignment:.leading,spacing:14){
            Text("Keyboard Piano").font(.title.bold())
            Text("Đàn mini tạo âm tổng hợp trên thiết bị. Nhấn từng phím để chơi; không tải hoặc ghi âm.").font(.caption).foregroundStyle(.secondary)
            Stepper("Quãng tám: \(octave)",value:$octave,in:2...6)
            HStack(spacing:4){
                ForEach(Array([("C♯",1),("D♯",3),("F♯",6),("G♯",8),("A♯",10)].enumerated()),id:\.offset){_,key in
                    Button{play(key)}label:{Text(key.0).font(.caption).frame(maxWidth:.infinity,minHeight:70).background(.black,in:RoundedRectangle(cornerRadius:6))}.buttonStyle(.plain)
                }
            }
            HStack(spacing:3){
                ForEach(Array([("C",0),("D",2),("E",4),("F",5),("G",7),("A",9),("B",11)].enumerated()),id:\.offset){_,key in
                    Button{play(key)}label:{Text(key.0).foregroundStyle(.black).frame(maxWidth:.infinity,minHeight:135).background(.white,in:RoundedRectangle(cornerRadius:6))}.buttonStyle(.plain)
                }
            }
            Text(last).font(.headline).foregroundStyle(.cyan)
        }.onDisappear{engine.stop()}
    }
    private func play(_ key:(String,Int)){last=key.0+"\(octave)";engine.play((octave+1)*12+key.1)}
}
