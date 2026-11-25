import SwiftUI

struct SmartNotesStudioView:View {
    @State private var text=""
    @State private var title=""
    @State private var status=""
    @State private var records=PersonalMemoryStore.all.filter{$0.kind=="Ghi chú" && $0.personaID.isEmpty}
    @State private var editing:String?
    @State private var busy=false
    @State private var work:Task<Void,Never>?
    var body:some View {
        VStack(alignment:.leading,spacing:12){
            Text("Smart Notes").font(.title.bold())
            Text("Ghi chú cá nhân trong bộ nhớ 3.0. AI sắp xếp nội dung khi bạn chủ động chọn.").font(.caption).foregroundStyle(.secondary)
            TextField("Tiêu đề",text:$title).textFieldStyle(.roundedBorder)
            TextEditor(text:$text).frame(minHeight:140)
            HStack{
                Button("Dàn ý offline"){text=PremiumOffline.format(text,mode:"danhsach")}
                Button(busy ? "Đang xử lý…" : "AI cấu trúc"){structure()}.disabled(busy)
                if busy{Button("Hủy"){work?.cancel();busy=false}}
            }.buttonStyle(.bordered)
            Button(editing==nil ? "Lưu ghi chú" : "Cập nhật"){save()}.buttonStyle(.borderedProminent)
            if editing != nil{Button("Hủy sửa"){editing=nil;title="";text=""}}
            Text(status).font(.caption).foregroundStyle(.orange)
            ForEach(records){record in
                VStack(alignment:.leading,spacing:8){
                    Text(record.title).bold();Text(record.detail).font(.subheadline)
                    HStack{
                        Button("Sửa"){editing=record.id;title=record.title;text=record.detail}
                        Spacer()
                        Button(role:.destructive){if PersonalMemoryStore.save(PersonalMemoryStore.all.filter{$0.id != record.id}){reload()}else{status="Không xóa được."}}label:{Image(systemName:"trash")}
                    }.buttonStyle(.borderless)
                }.padding(10).background(.white.opacity(0.06),in:RoundedRectangle(cornerRadius:12))
            }
        }.onDisappear{work?.cancel()}
    }
    private func reload(){records=PersonalMemoryStore.all.filter{$0.kind=="Ghi chú" && $0.personaID.isEmpty}}
    private func save(){
        let record=PersonalMemory(id:editing ?? UUID().uuidString,personaID:"",kind:"Ghi chú",title:title.trimmingCharacters(in:.whitespacesAndNewlines),detail:text)
        guard PersonalMemoryStore.save([record]+PersonalMemoryStore.all.filter{$0.id != record.id})else{status="Không lưu được. Tối đa 1.000 ký tự mỗi ghi chú, không chứa dữ liệu nhạy cảm.";return}
        title="";text="";editing=nil;reload();status="Đã lưu."
    }
    private func structure(){
        guard KeyboardSettings.allowCloudAI,!text.isEmpty,MessageSafety.warnings(in:text).isEmpty else{status="Kiểm tra AI online và dữ liệu.";return}
        let input=text;let provider=KeyboardSettings.provider;busy=true
        work=Task{@MainActor in
            defer{if !Task.isCancelled{busy=false}}
            do{let value=try await AIWritingService.studio(input,instruction:PersonalIntelligenceCatalog.task("notes")!.instruction,provider:provider);if !Task.isCancelled{text=value}}
            catch{if !Task.isCancelled{status=error.localizedDescription}}
        }
    }
}
struct MiniCalculatorView:View{
    @State private var expression=""
    @State private var result=""
    @State private var status=""
    var body:some View{
        VStack(alignment:.leading,spacing:12){
            TextField("Ví dụ: (2+3)*4",text:$expression).textFieldStyle(.roundedBorder).keyboardType(.numbersAndPunctuation)
            Button("Tính"){do{result=try PremiumCalculator.evaluate(expression);status=""}catch{result="";status="Biểu thức không hợp lệ."}}.buttonStyle(.borderedProminent)
            Text(result).font(.largeTitle.bold())
            if !result.isEmpty{PersonalResultActions(text:result,status:$status)}
            Text(status).font(.caption)
        }
    }
}
struct MiniDateView:View{
    @State private var status=""
    var body:some View{
        TimelineView(.periodic(from:.now,by:1)){context in
            let date=PremiumOffline.variables("{{ngay}} {{gio}}",name:"",custom:[:],now:context.date)
            VStack(alignment:.leading,spacing:12){Text(date).font(.largeTitle.bold());PersonalResultActions(text:date,status:$status);Text(status).font(.caption)}
        }
    }
}
