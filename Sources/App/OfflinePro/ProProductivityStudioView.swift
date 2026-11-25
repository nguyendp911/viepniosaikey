import SwiftUI
import UIKit

struct ProProductivityStudioView:View{
    @State private var mode="Find & Replace"
    @State private var source=""
    @State private var find=""
    @State private var replacement=""
    @State private var encoding="Base64"
    @State private var result=""
    @State private var status=""
    @State private var stripTracking=true
    @State private var color=Color.cyan
    @State private var formName=""
    @State private var formEmail=""
    @State private var formAddress=""
    @State private var formOther=""
    @State private var markdown="Tiêu đề"
    private let modes=["Find & Replace","Text Statistics","Text Cleaner","Smart Table","Text Encoder","Link Studio","Quick Form","Markdown Studio","Color Studio","Developer Keyboard","Snippet Library","Quick Signature"]
    var body:some View{
        VStack(alignment:.leading,spacing:12){
            Text("Productivity Studio").font(.title.bold())
            Picker("Công cụ",selection:$mode){ForEach(modes,id:\.self){Text($0)}}.onChange(of:mode){_ in result="";status=""}
            switch mode{
            case "Snippet Library","Quick Signature":ProSnippetStudioView()
            case "Developer Keyboard":
                Text("Bố cục lập trình có hàng số và menu ký tự bổ sung.")
                Button("Bật bố cục Developer"){var config=OfflineKeyboardConfig.current;config.layout = .developer;config.numberRow=true;OfflineKeyboardConfig.current=config;status="Đã lưu. Mở lại bàn phím."}.buttonStyle(.borderedProminent)
                ProKeyboardPreview(config:OfflineKeyboardConfig.current)
                Text("{} [] () <> _ := ; / | & + - * # @").font(.system(.body,design:.monospaced)).textSelection(.enabled)
            case "Quick Form":
                Text("Dữ liệu chỉ giữ trong màn hình này; tự quyết định có sao chép hay không.").font(.caption).foregroundStyle(.secondary)
                TextField("Họ tên",text:$formName).textFieldStyle(.roundedBorder)
                TextField("Email",text:$formEmail).textFieldStyle(.roundedBorder)
                TextField("Địa chỉ",text:$formAddress).textFieldStyle(.roundedBorder)
                TextField("Thông tin khác",text:$formOther).textFieldStyle(.roundedBorder)
                Button("Tạo biểu mẫu"){result=[("Họ tên",formName),("Email",formEmail),("Địa chỉ",formAddress),("Ghi chú",formOther)].filter{!$0.1.isEmpty}.map{$0.0+": "+$0.1}.joined(separator:"\n")}.buttonStyle(.borderedProminent)
            case "Color Studio":
                ColorPicker("Chọn màu",selection:$color,supportsOpacity:false)
                RoundedRectangle(cornerRadius:12).fill(color).frame(height:80)
                Button("Tạo mã HEX / RGB / HSL"){result=colorCodes()}.buttonStyle(.borderedProminent)
            default:
                TextEditor(text:$source).frame(minHeight:120)
                if mode=="Find & Replace"{TextField("Tìm",text:$find).textFieldStyle(.roundedBorder);TextField("Thay bằng",text:$replacement).textFieldStyle(.roundedBorder)}
                if mode=="Smart Table"{Text("Mỗi dòng là một hàng; các cột phân cách bởi |").font(.caption).foregroundStyle(.secondary)}
                if mode=="Text Encoder"{Picker("Mã hóa",selection:$encoding){ForEach(["Base64","Decode Base64","URL","Decode URL","Hex","Binary","Morse"],id:\.self){Text($0)}}}
                if mode=="Link Studio"{Toggle("Xóa tham số theo dõi",isOn:$stripTracking);TextField("UTM source (tùy chọn)",text:$replacement).textFieldStyle(.roundedBorder)}
                if mode=="Markdown Studio"{Picker("Định dạng",selection:$markdown){ForEach(["Tiêu đề","Đậm","Nghiêng","Danh sách","Trích dẫn","Code"],id:\.self){Text($0)}}}
                Button("Xử lý offline"){run()}.buttonStyle(.borderedProminent)
            }
            if !result.isEmpty{
                Text("Kết quả").font(.headline)
                TextEditor(text:$result).frame(minHeight:120)
                PersonalResultActions(text:result,status:$status)
            }
            Text(status).font(.caption).foregroundStyle(.orange)
        }
    }
    private func run(){
        let input=String(source.prefix(6000))
        status=""
        switch mode{
        case "Find & Replace":result=ProTextTools.replace(input,find:find,replacement:replacement)
        case "Text Statistics":result=ProTextTools.stats(input)
        case "Text Cleaner":result=ProTextTools.clean(input)
        case "Smart Table":result=ProTextTools.table(input)
        case "Text Encoder":result=ProTextTools.encode(input,mode:encoding) ?? "";if result.isEmpty{status="Dữ liệu không hợp lệ hoặc trống."}
        case "Link Studio":result=ProTextTools.link(input,utm:replacement,remove:stripTracking) ?? "";if result.isEmpty{status="Cần URL http/https hợp lệ."}
        case "Markdown Studio":
            switch markdown{
            case "Tiêu đề":result="# "+input
            case "Đậm":result="**"+input+"**"
            case "Nghiêng":result="*"+input+"*"
            case "Danh sách":result=input.components(separatedBy:.newlines).map{"- "+$0}.joined(separator:"\n")
            case "Trích dẫn":result=input.components(separatedBy:.newlines).map{"> "+$0}.joined(separator:"\n")
            default:result="```\n"+input+"\n```"
            }
        default:break
        }
    }
    private func colorCodes()->String{
        var r:CGFloat=0,g:CGFloat=0,b:CGFloat=0,a:CGFloat=0
        guard UIColor(color).getRed(&r,green:&g,blue:&b,alpha:&a)else{return ""}
        let hi=max(r,max(g,b)),lo=min(r,min(g,b)),delta=hi-lo,light=(hi+lo)/2
        var hue:CGFloat=0
        if delta>0{
            if hi==r{hue=(g-b)/delta}
            else if hi==g{hue=(b-r)/delta+2}
            else{hue=(r-g)/delta+4}
        }
        hue*=60;if hue<0{hue+=360}
        let saturation=delta==0 ? 0 : delta/(1-abs(2*light-1))
        let rgb=[r,g,b].map{Int(($0*255).rounded())}
        return String(format:"#%02X%02X%02X",rgb[0],rgb[1],rgb[2])+"\nRGB "+rgb.map(String.init).joined(separator:", ")+"\nHSL \(Int(hue.rounded()))°, \(Int((saturation*100).rounded()))%, \(Int((light*100).rounded()))%"
    }
}
