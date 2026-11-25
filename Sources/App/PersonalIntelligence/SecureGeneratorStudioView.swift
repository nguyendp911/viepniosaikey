import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct SecureGeneratorStudioView:View {
    @State private var length=20.0
    @State private var symbols=true
    @State private var value=""
    @State private var status=""
    var body:some View {
        VStack(alignment:.leading,spacing:14){
            Text("Secure Generator").font(.title.bold())
            Text("Dùng bộ sinh ngẫu nhiên của hệ thống. Không gửi AI, không lưu mật khẩu vào kho nháp hoặc lịch sử.").font(.caption).foregroundStyle(.secondary)
            Text("Độ dài: \(Int(length))")
            Slider(value:$length,in:12...64,step:1)
            Toggle("Ký tự đặc biệt",isOn:$symbols)
            Button("Tạo mật khẩu"){value=SecureTextGenerator.password(length:Int(length),symbols:symbols);status=""}.buttonStyle(.borderedProminent)
            if !value.isEmpty{
                Text(value).font(.system(.title3,design:.monospaced)).padding(12).frame(maxWidth:.infinity,alignment:.leading).background(.white.opacity(0.08),in:RoundedRectangle(cornerRadius:10))
                Button("Sao chép trong 60 giây"){
                    UIPasteboard.general.setItems([[UTType.plainText.identifier:value]],options:[.localOnly:true,.expirationDate:Date().addingTimeInterval(60)])
                    status="Đã sao chép cục bộ; clipboard sẽ hết hạn."
                }.buttonStyle(.bordered)
                Button("Ẩn và xóa khỏi màn hình"){value="";status=""}
            }
            Text(status).font(.caption)
        }.onDisappear{value=""}
    }
}
