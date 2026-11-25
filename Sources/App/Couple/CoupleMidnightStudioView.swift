import SwiftUI
import UIKit

private enum CoupleRoute:String,Identifiable {
    case conversation,emotion,profile,conflict,library,moments,journal,writing,simulation
    var id:String{rawValue}
    var title:String {
        switch self {
        case .conversation:return "Hội thoại"
        case .emotion:return "Cảm xúc"
        case .profile:return "Cá tính"
        case .conflict:return "Làm hòa"
        case .library:return "Kho tình cảm"
        case .moments:return "Kỷ niệm"
        case .journal:return "Nhật ký"
        case .writing:return "Viết lời nhắn"
        case .simulation:return "Luyện hội thoại"
        }
    }
    var detail:String {
        switch self {
        case .conversation:return "Ngữ cảnh & phản hồi"
        case .emotion:return "Điều chỉnh giọng điệu"
        case .profile:return "Phong cách của bạn"
        case .conflict:return "Giao tiếp & ranh giới"
        case .library:return "Câu đã lưu"
        case .moments:return "Nhắc ngày đặc biệt"
        case .journal:return "Ghi chú riêng tư"
        case .writing:return "Viết lại & lời chúc"
        case .simulation:return "Tình huống giả lập"
        }
    }
    var symbol:String {
        switch self {
        case .conversation:return "bubble.left.and.bubble.right"
        case .emotion:return "slider.horizontal.3"
        case .profile:return "person.crop.circle"
        case .conflict:return "heart.text.square"
        case .library:return "bookmark"
        case .moments:return "calendar"
        case .journal:return "book.closed"
        case .writing:return "square.and.pencil"
        case .simulation:return "theatermasks"
        }
    }
}
struct CoupleMidnightStudioView:View {
    @State private var route:CoupleRoute?
    private let rose=Color(red:0.91,green:0.66,blue:0.74)
    var body:some View {
        VStack(alignment:.leading,spacing:14){
            ZStack(alignment:.topTrailing){
                RoundedRectangle(cornerRadius:22).fill(LinearGradient(colors:[Color(red:0.22,green:0.13,blue:0.25),Color(red:0.10,green:0.08,blue:0.15)],startPoint:.topLeading,endPoint:.bottomTrailing))
                Circle().stroke(rose.opacity(0.16),lineWidth:1).frame(width:130,height:130).offset(x:24,y:-36)
                Circle().stroke(rose.opacity(0.10),lineWidth:1).frame(width:94,height:94).offset(x:15,y:-18)
                Image(systemName:"heart.text.square").font(.system(size:38,weight:.ultraLight)).foregroundStyle(rose.opacity(0.9)).padding(19)
                VStack(alignment:.leading,spacing:12){
                    Text("VIEPN  ·  RELATIONSHIP").font(.system(size:10,weight:.semibold)).tracking(2).foregroundStyle(rose)
                    Text("Couple Studio").font(.system(size:30,weight:.medium,design:.serif)).foregroundStyle(.white)
                    Text("Hiểu nhau hơn qua từng lời nhắn.").font(.subheadline).foregroundStyle(.white.opacity(0.72))
                    Rectangle().fill(rose.opacity(0.7)).frame(width:48,height:1)
                }.padding(20).frame(maxWidth:.infinity,alignment:.leading)
            }.clipShape(RoundedRectangle(cornerRadius:22))
            LazyVGrid(columns:[GridItem(.flexible(),spacing:9),GridItem(.flexible(),spacing:9)],spacing:9){
                ForEach([CoupleRoute.conversation,.emotion,.profile,.conflict,.library,.moments,.journal,.writing,.simulation]){item in
                    Button{route=item}label:{
                        VStack(alignment:.leading,spacing:8){
                            Image(systemName:item.symbol).font(.system(size:22,weight:.light)).foregroundStyle(rose)
                            Text(item.title).font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                            Text(item.detail).font(.caption).foregroundStyle(.white.opacity(0.58)).lineLimit(2)
                        }.padding(13).frame(maxWidth:.infinity,minHeight:100,alignment:.leading)
                            .background(Color(red:0.15,green:0.11,blue:0.19),in:RoundedRectangle(cornerRadius:15))
                            .overlay{RoundedRectangle(cornerRadius:15).strokeBorder(rose.opacity(0.13))}
                    }.buttonStyle(.plain).accessibilityIdentifier("couple.studio."+item.rawValue)
                }
            }
            Label("Riêng tư · Không tự đọc hay gửi tin nhắn",systemImage:"lock.shield").font(.caption).foregroundStyle(rose.opacity(0.85))
        }.sheet(item:$route){item in
            NavigationStack{
                Group {
                    switch item {
                    case .conversation: ScrollView{CoupleConversationStudio().padding()}
                    case .emotion: CoupleEmotionStudio()
                    case .profile: CoupleProfileStudio()
                    case .conflict: ScrollView{CoupleConversationStudio(initial:"",conflict:true).padding()}
                    case .library: CoupleLibraryStudio()
                    case .moments: CoupleMomentsStudio()
                    case .journal: CoupleJournalStudio()
                    case .writing: ScrollView{CoupleWritingStudio().padding()}
                    case .simulation: ScrollView{CoupleSimulationStudio().padding()}
                    }
                }.navigationTitle(item.title).navigationBarTitleDisplayMode(.inline)
                    .toolbar{ToolbarItem(placement:.cancellationAction){Button("Đóng"){route=nil}.accessibilityIdentifier("couple.studio.close")}}
            }.preferredColorScheme(.dark).tint(rose)
        }
    }
}
struct CoupleEmotionStudio:View {
    @State private var prefs=CoupleStudioPreferences.current
    @State private var style=KeyboardSettings.coupleStyle
    @State private var incoming="Hôm nay em bận, không nói chuyện được."
    var body:some View {
        Form{
            Section("Giọng điệu"){
                Toggle("Điều chỉnh cảm xúc riêng",isOn:$prefs.customEmotion)
                Picker("Phong cách",selection:$style){ForEach(CoupleStyleCatalog.styles){Text($0.title).tag($0.id)}}
                    .onChange(of:style){KeyboardSettings.coupleStyle=$0}
                meter("Lạnh lùng",value:$prefs.cold)
                meter("Tổn thương",value:$prefs.hurt)
                meter("Dịu dàng",value:$prefs.warmth)
                Picker("Độ dài",selection:$prefs.length){Text("Ngắn").tag("short");Text("Vừa").tag("medium");Text("Dài").tag("long")}
                Toggle("Cho phép emoji",isOn:$prefs.emoji)
                Text("Offline dùng các nhóm mức cảm xúc; AI hiện có dùng các mức đã chọn khi Couple được bật. Đây là lựa chọn cách viết, không đo cảm xúc thực.").font(.caption)
            }
            Section("Xem trước offline"){
                TextField("Tin nhắn nhận được",text:$incoming,axis:.vertical)
                ForEach(CoupleLocalEngine.suggest(incoming,style:style,address:KeyboardSettings.coupleAddress,preferences:prefs)){item in
                    Text(item.text).font(.subheadline)
                }
            }
        }.onChange(of:prefs){CoupleStudioPreferences.current=$0}
    }
    private func meter(_ title:String,value:Binding<Int>)->some View{
        VStack(alignment:.leading,spacing:4){
            HStack{Text(title);Spacer();Text("\(value.wrappedValue)%").monospacedDigit().foregroundStyle(.secondary)}
            Slider(value:Binding(get:{Double(value.wrappedValue)},set:{value.wrappedValue=Int($0)}),in:0...100,step:5)
        }.disabled(!prefs.customEmotion)
    }
}
struct CoupleProfileStudio:View {
    @State private var prefs=CoupleStudioPreferences.current
    @State private var address=KeyboardSettings.coupleAddress
    @State private var stage=KeyboardSettings.coupleStage
    @State private var style=KeyboardSettings.coupleStyle
    @State private var dna=CouplePersonalDNA.current
    var body:some View {
        Form{
            Section("Hồ sơ"){
                TextField("Biệt danh (chỉ trên máy)",text:$prefs.nickname)
                    .onChange(of:prefs.nickname){if $0.count>32{prefs.nickname=String($0.prefix(32))}}
                Picker("Xưng hô",selection:$address){ForEach(["anh/em","em/anh","mình/cậu","tớ/cậu","bạn/mình"],id:\.self){Text($0)}}
                    .onChange(of:address){KeyboardSettings.coupleAddress=$0}
                Picker("Giai đoạn",selection:$stage){ForEach(["Mới quen","Đang tìm hiểu","Đang yêu","Yêu xa","Đã kết hôn"],id:\.self){Text($0)}}
                    .onChange(of:stage){KeyboardSettings.coupleStage=$0}
                Picker("Phong cách",selection:$style){ForEach(CoupleStyleCatalog.styles){Text($0.title).tag($0.id)}}.onChange(of:style){KeyboardSettings.coupleStyle=$0}
            }
            Section("Personal DNA"){
                Toggle("Học khi tôi chủ động lưu câu",isOn:$prefs.learnFromSaved)
                Text("Chỉ lưu số liệu tổng hợp từ thao tác lưu trong Couple Studio: độ dài, emoji và phong cách. Không tự đọc hội thoại.").font(.caption)
                LabeledContent("Số mẫu đã xác nhận",value:String(dna.samples))
                LabeledContent("Độ dài trung bình",value:"\(dna.meanLength) ký tự")
                LabeledContent("Phong cách thường chọn",value:dna.favoriteStyle.map{CoupleStyleCatalog.selected($0).title} ?? "Chưa có")
                Button("Áp dụng thói quen đã học"){
                    guard dna.samples>0 else{return}
                    prefs.length=dna.meanLength<55 ? "short":dna.meanLength>120 ? "long":"medium"
                    prefs.emoji=dna.emojiSamples*2>=dna.samples
                    if let preferred=dna.favoriteStyle{style=preferred;KeyboardSettings.coupleStyle=preferred}
                    prefs.customEmotion=true
                }.disabled(dna.samples==0)
                Button("Xóa thống kê DNA",role:.destructive){CouplePersonalDNA.clear();dna=CouplePersonalDNA()}
            }
        }.onChange(of:prefs){CoupleStudioPreferences.current=$0}.onAppear{dna=CouplePersonalDNA.current}
    }
}
