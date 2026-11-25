import SwiftUI
import MetricKit

/// MetricKit delivers OS-generated host-app reports asynchronously. Retain
/// aggregate counters only, never stack traces, URLs, or diagnostic payloads.
final class EverydayCrashMonitor:NSObject,MXMetricManagerSubscriber {
    static let shared=EverydayCrashMonitor()
    private var started=false
    private let queue=DispatchQueue(label:"com.viepn.everyday.metrics")
    func start(){
        guard !started else{return};started=true;MXMetricManager.shared.add(self)
    }
    func didReceive(_ payloads:[MXDiagnosticPayload]){
        let crashes=payloads.reduce(0){$0+($1.crashDiagnostics?.count ?? 0)}
        let hangs=payloads.reduce(0){$0+($1.hangDiagnostics?.count ?? 0)}
        queue.async{
            guard EverydayPreferences.current.diagnostics,!KeyboardSettings.privateTypingMode else{return}
            let defaults=KeyboardSettings.defaults
            defaults.set(min(100000,max(0,min(100000,defaults.integer(forKey:"everyday7.crashes")))+crashes),forKey:"everyday7.crashes")
            defaults.set(min(100000,max(0,min(100000,defaults.integer(forKey:"everyday7.hangs")))+hangs),forKey:"everyday7.hangs")
        }
    }
    func didReceive(_ payloads:[MXMetricPayload]){
        let values=payloads.compactMap{$0.memoryMetrics?.peakMemoryUsage.converted(to:.megabytes).value}
        guard let peak=values.max(),peak.isFinite else{return}
        queue.async{
            guard EverydayPreferences.current.diagnostics,!KeyboardSettings.privateTypingMode else{return}
            KeyboardSettings.defaults.set(max(0,peak),forKey:"everyday7.peakMB")
        }
    }
}
struct EverydayDiagnosticsView:View {
    @State private var prefs=EverydayPreferences.current
    @State private var heat=EverydayTouchMap()
    @State private var report=""
    @State private var crashes=0
    @State private var hangs=0
    @State private var peak=0.0
    var body:some View {
        VStack(alignment:.leading,spacing:14){
            Text("Typing Heatmap").font(.title2.bold())
            Toggle("Ghi thống kê vùng chạm tổng hợp",isOn:$prefs.heatmap)
            Text("Lưới vị trí 10×5, không lưu ký tự hoặc từng lần chạm. Chỉ tính điểm bắt đầu trên phím chữ; không phải bản đồ lỗi chính tả. Không thu khi riêng tư.").font(.caption)
            LazyVGrid(columns:Array(repeating:GridItem(.flexible(),spacing:3),count:10),spacing:3){
                ForEach(0..<50){i in
                    let value=max(0,heat.bins[i]),maxValue=max(1,heat.bins.max() ?? 1)
                    RoundedRectangle(cornerRadius:4).fill(Color.mint.opacity(0.07+0.93*Double(value)/Double(maxValue)))
                        .aspectRatio(1,contentMode:.fit).accessibilityLabel("Ô \(i+1): \(value)")
                }
            }
            Button("Xóa heatmap",role:.destructive){EverydayTouchMap.clear();heat=EverydayTouchMap()}.buttonStyle(.bordered)
            Divider()
            Text("Typing Diagnostics").font(.title2.bold())
            Text("Thống kê mẫu độ trễ hiện có, đo mỗi 50 lượt chạm. Không phải benchmark toàn bộ iOS.").font(.caption)
            Text(report).font(.system(.caption,design:.monospaced)).textSelection(.enabled)
            Divider()
            Text("Crash Diagnostics").font(.title2.bold())
            Toggle("Nhận số liệu MetricKit của app",isOn:$prefs.diagnostics)
            LabeledContent("Báo cáo crash đã nhận",value:String(crashes))
            LabeledContent("Báo cáo treo đã nhận",value:String(hangs))
            LabeledContent("Đỉnh RAM app (báo cáo OS)",value:peak>0 ? String(format:"%.1f MB",peak) : "Chưa có")
            Text("iOS gửi báo cáo trễ và không đảm bảo có ngay; số 0 không có nghĩa chưa từng crash. Không thu stack trace và không xác nhận được crash riêng của Keyboard Extension bằng chỉ số này.").font(.caption).foregroundStyle(.secondary)
            Button("Làm mới"){refresh()}.buttonStyle(.borderedProminent)
            Button("Xóa thống kê chẩn đoán",role:.destructive){
                KeyboardStability.clear()
                for key in ["everyday7.crashes","everyday7.hangs","everyday7.peakMB"]{KeyboardSettings.defaults.removeObject(forKey:key)}
                refresh()
            }.buttonStyle(.bordered)
        }.onAppear{refresh()}.onChange(of:prefs){EverydayPreferences.current=$0}
    }
    private func refresh(){
        if KeyboardSettings.privateTypingMode{heat=EverydayTouchMap();report="Đang riêng tư";crashes=0;hangs=0;peak=0;return}
        heat=EverydayTouchMap.current;report=KeyboardStability.report()
        crashes=KeyboardSettings.defaults.integer(forKey:"everyday7.crashes")
        hangs=KeyboardSettings.defaults.integer(forKey:"everyday7.hangs")
        peak=KeyboardSettings.defaults.double(forKey:"everyday7.peakMB")
    }
}
