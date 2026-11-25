import SwiftUI

struct TypingProCalibrationView:View{
    @State private var offsets=TypingProCustomization.offsets
    @State private var actions=TypingProCustomization.actions
    @State private var key="a"
    @State private var action=""
    @State private var samples:[Double]=[]
    @State private var status=""
    var body:some View{
        VStack(alignment:.leading,spacing:14){
            Text("Personal Touch Calibration").font(.title2.bold())
            Text("Chạm 8 lần vào phím mẫu như khi gõ tự nhiên. Chỉ lưu độ lệch trung bình tối đa 3 pt; không lưu từng tọa độ. Vùng chạm vẫn nằm trong nửa khe phím.").font(.caption).foregroundStyle(.secondary)
            Picker("Phím",selection:$key){ForEach(Array("abcdefghijklmnopqrstuvwxyz"),id:\.self){Text(String($0)).tag(String($0))}}
                .onChange(of:key){_ in samples=[];action=actions[key] ?? ""}
            GeometryReader{geometry in
                ZStack {
                    RoundedRectangle(cornerRadius:12).fill(Color(red:0.12,green:0.16,blue:0.23))
                    RoundedRectangle(cornerRadius:8).fill(.white.opacity(0.17)).frame(width:38,height:44)
                    Text(key.uppercased()).font(.title2.weight(.medium))
                    Rectangle().fill(.cyan.opacity(0.65)).frame(width:1,height:48).allowsHitTesting(false)
                }.contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance:0).onEnded{value in
                        guard samples.count<8,abs(value.location.x-geometry.size.width/2)<=30 else{return}
                        samples.append(Double(value.location.x-geometry.size.width/2))
                        if samples.count==8 {
                            let average=samples.reduce(0,+)/Double(samples.count)
                            offsets[key]=min(3,max(-3,average));TypingProCustomization.offsets=offsets
                            status="Đã lưu hiệu chỉnh phím "+key.uppercased()
                        }
                    }).accessibilityLabel("Phím luyện chạm "+key)
            }.frame(height:80)
            ProgressView(value:Double(samples.count),total:8)
            Text("\(samples.count)/8 · Độ lệch đã lưu: "+String(format:"%.1f pt",offsets[key] ?? 0)).font(.caption.monospacedDigit())
            HStack{Button("Đo lại"){samples=[]};Button("Xóa hiệu chỉnh",role:.destructive){offsets.removeValue(forKey:key);TypingProCustomization.offsets=offsets;samples=[]}}
                .buttonStyle(.bordered)
            Divider()
            Text("Custom Key Actions").font(.headline)
            Text("Gán chuỗi tối đa 24 ký tự vào menu nhấn giữ của phím; cần bật Multi-Tap trong Layout Designer. Không thay các ký tự có sẵn.").font(.caption).foregroundStyle(.secondary)
            TextField("Ký tự hoặc chuỗi",text:$action).textFieldStyle(.roundedBorder)
            Button("Lưu thao tác riêng"){
                guard action.count<=24,MessageSafety.warnings(in:action).isEmpty else{status="Chuỗi không hợp lệ.";return}
                if action.isEmpty{actions.removeValue(forKey:key)}else{actions[key]=action}
                TypingProCustomization.actions=actions;status="Đã lưu."
            }.buttonStyle(.borderedProminent)
            Text(status).font(.caption).foregroundStyle(.cyan)
        }.onAppear{action=actions[key] ?? ""}
    }
}
