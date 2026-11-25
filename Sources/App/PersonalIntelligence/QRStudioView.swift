import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

struct QRStudioView:View {
    @State private var source=""
    @State private var image:UIImage?
    @State private var status=""
    var body:some View {
        VStack(alignment:.leading,spacing:12){
            Text("QR Studio").font(.title.bold())
            Text("Tạo QR cho văn bản hoặc URL trên thiết bị. Không tải lên máy chủ. QR không mã hóa bí mật.").font(.caption).foregroundStyle(.secondary)
            TextEditor(text:$source).frame(minHeight:110)
            Button("Tạo mã QR"){generate()}.buttonStyle(.borderedProminent)
            if let image{
                Image(uiImage:image).interpolation(.none).resizable().scaledToFit().frame(maxWidth:270).padding(15).background(.white,in:RoundedRectangle(cornerRadius:12)).frame(maxWidth:.infinity)
                    .accessibilityLabel("Mã QR từ văn bản đã nhập")
                Button("Sao chép ảnh QR"){UIPasteboard.general.image=image;status="Đã sao chép ảnh."}.buttonStyle(.bordered)
            }
            Text(status).font(.caption).foregroundStyle(.orange)
        }.onChange(of:source){_ in image=nil;status=""}
    }
    private func generate(){
        let bytes=Data(source.utf8)
        guard !bytes.isEmpty,bytes.count<=900 else{status="Nhập từ 1 đến 900 byte.";return}
        let filter=CIFilter.qrCodeGenerator();filter.message=bytes;filter.correctionLevel="M"
        guard let output=filter.outputImage?.transformed(by:CGAffineTransform(scaleX:8,y:8)),
              let cg=CIContext().createCGImage(output,from:output.extent)else{status="Không tạo được QR.";return}
        image=UIImage(cgImage:cg);status="Đã tạo trên thiết bị."
    }
}
