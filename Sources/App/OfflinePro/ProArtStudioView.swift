import SwiftUI
import UIKit
import PhotosUI
import ImageIO

struct ProArtStudioView:View{
    @State private var mode="Pixel Art"
    @State private var pixels=Array(repeating:0,count:144)
    @State private var ink=1
    @State private var photo:PhotosPickerItem?
    @State private var source:UIImage?
    @State private var caption=""
    @State private var preview:UIImage?
    @State private var status=""
    @State private var pickerTicket=UUID()
    private let colors:[UIColor]=[.clear,.white,.black,.systemRed,.systemOrange,.systemYellow,.systemGreen,.systemBlue,.systemPurple,.systemPink,.brown,.cyan]
    var body:some View{
        VStack(alignment:.leading,spacing:12){
            Text("Sticker & Pixel Art").font(.title.bold())
            Picker("Loại",selection:$mode){Text("Pixel Art").tag("Pixel Art");Text("Sticker").tag("Sticker")}.pickerStyle(.segmented).onChange(of:mode){_ in preview=nil}
            if mode=="Pixel Art"{
                LazyVGrid(columns:Array(repeating:GridItem(.flexible(),spacing:2),count:12),spacing:2){
                    ForEach(pixels.indices,id:\.self){i in
                        Button{pixels[i]=ink;preview=nil}label:{Rectangle().fill(Color(uiColor:colors[pixels[i]])).aspectRatio(1,contentMode:.fit).background(.gray.opacity(0.35)).overlay{Rectangle().strokeBorder(.white.opacity(0.15))}}.buttonStyle(.plain).accessibilityLabel("Pixel \(i+1)")
                    }
                }
                LazyVGrid(columns:Array(repeating:GridItem(.flexible()),count:6)){
                    ForEach(colors.indices,id:\.self){i in
                        Button{ink=i}label:{Circle().fill(Color(uiColor:colors[i])).frame(width:34,height:34).overlay{Circle().strokeBorder(ink==i ? Color.cyan : Color.gray,lineWidth:2)}}.buttonStyle(.plain).accessibilityLabel(i==0 ? "Tẩy" : "Màu \(i)")
                    }
                }
                Button("Xóa toàn bộ"){pixels=Array(repeating:0,count:144);preview=nil}.buttonStyle(.bordered)
            }else{
                PhotosPicker("Chọn ảnh sticker",selection:$photo,matching:.images).buttonStyle(.bordered)
                    .onChange(of:photo){item in
                        guard let item else{return};let ticket=UUID();pickerTicket=ticket
                        Task{@MainActor in
                            guard let data=try? await item.loadTransferable(type:Data.self),data.count<=30_000_000,let imageSource=CGImageSourceCreateWithData(data as CFData,nil),let thumb=CGImageSourceCreateThumbnailAtIndex(imageSource,0,[kCGImageSourceCreateThumbnailFromImageAlways:true,kCGImageSourceCreateThumbnailWithTransform:true,kCGImageSourceThumbnailMaxPixelSize:800] as CFDictionary),pickerTicket==ticket else{return}
                            source=UIImage(cgImage:thumb);preview=nil
                        }
                    }
                if let source{Image(uiImage:source).resizable().scaledToFit().frame(maxHeight:160)}
                TextField("Chữ trên sticker",text:$caption).textFieldStyle(.roundedBorder)
                Text("Sticker là ảnh PNG bo góc với chữ, không tự tách nền hoặc gửi trực tiếp đến app chat.").font(.caption).foregroundStyle(.secondary)
            }
            Button("Tạo ảnh PNG"){render()}.buttonStyle(.borderedProminent)
            if let preview{
                Image(uiImage:preview).resizable().interpolation(.none).scaledToFit().frame(maxHeight:200).background(.gray.opacity(0.12))
                Button("Sao chép ảnh"){UIPasteboard.general.image=preview;status="Đã sao chép ảnh. Dán trong ứng dụng hỗ trợ ảnh."}.buttonStyle(.bordered)
            }
            Text(status).font(.caption).foregroundStyle(.secondary)
        }
    }
    private func render(){
        let format=UIGraphicsImageRendererFormat();format.opaque=false;format.scale=1
        let renderer=UIGraphicsImageRenderer(size:CGSize(width:384,height:384),format:format)
        if mode=="Pixel Art"{
            preview=renderer.image{ctx in
                for i in pixels.indices where pixels[i]>0{
                    colors[pixels[i]].setFill();ctx.fill(CGRect(x:(i%12)*32,y:(i/12)*32,width:32,height:32))
                }
            }
        }else{
            guard let source else{status="Chọn ảnh trước.";return}
            preview=renderer.image{_ in
                let rect=CGRect(x:8,y:8,width:368,height:368);UIBezierPath(roundedRect:rect,cornerRadius:42).addClip()
                let factor=max(rect.width/source.size.width,rect.height/source.size.height)
                let size=CGSize(width:source.size.width*factor,height:source.size.height*factor)
                source.draw(in:CGRect(x:rect.midX-size.width/2,y:rect.midY-size.height/2,width:size.width,height:size.height))
                if !caption.isEmpty{
                    UIColor.black.withAlphaComponent(0.65).setFill();UIBezierPath(rect:CGRect(x:8,y:286,width:368,height:90)).fill()
                    let style=NSMutableParagraphStyle();style.alignment = .center
                    (String(caption.prefix(60)) as NSString).draw(in:CGRect(x:16,y:298,width:352,height:70),withAttributes:[.font:UIFont.boldSystemFont(ofSize:25),.foregroundColor:UIColor.white,.paragraphStyle:style])
                }
            }
        }
        status="Đã tạo ảnh trên thiết bị."
    }
}
