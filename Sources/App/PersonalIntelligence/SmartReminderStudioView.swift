import SwiftUI
import UserNotifications

struct SmartReminderStudioView:View {
    var source:String = ""
    @State private var text=""
    @State private var title=""
    @State private var date=Date().addingTimeInterval(3600)
    @State private var status=""
    @State private var requests:[UNNotificationRequest]=[]
    @State private var busy=false
    var body:some View {
        VStack(alignment:.leading,spacing:11){
            Text("Smart Reminder").font(.title2.bold())
            Text("Thông báo cục bộ của ViePN, không phải ứng dụng Reminders của Apple. Chỉ tạo sau khi xác nhận giờ và nội dung; cần quyền thông báo.").font(.caption).foregroundStyle(.secondary)
            TextEditor(text:$text).frame(minHeight:85)
            HStack {
                Button("Lấy bản nháp"){text=ShareDraft.current}
                Button("Gợi ý thời gian"){
                    if let found=ReminderDateHint.parse(text),found>Date(){date=found;status="Đã tìm thấy thời gian rõ ràng; xác nhận lại."}
                    else{status="Không tìm thấy giờ tương lai rõ ràng. Dùng dd/MM/yyyy HH:mm hoặc chọn thủ công."}
                    if title.isEmpty{title=String(text.trimmingCharacters(in:.whitespacesAndNewlines).prefix(80))}
                }
            }.buttonStyle(.bordered)
            TextField("Tiêu đề nhắc nhở",text:$title).textFieldStyle(.roundedBorder)
            DatePicker("Thời gian",selection:$date,in:Date()...)
            Button(busy ? "Đang tạo…" : "Xác nhận tạo nhắc nhở"){schedule()}.buttonStyle(.borderedProminent).disabled(busy)
            Text(status).font(.caption).foregroundStyle(.orange)
            Text("Nhắc nhở đang chờ").font(.headline)
            ForEach(requests,id:\.identifier){request in
                HStack{
                    VStack(alignment:.leading){Text(request.content.title).bold();if let trigger=request.trigger as? UNCalendarNotificationTrigger,let next=trigger.nextTriggerDate(){Text(next,style:.date);Text(next,style:.time)}}
                    Spacer()
                    Button(role:.destructive){UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers:[request.identifier]);requests.removeAll{$0.identifier==request.identifier}}label:{Image(systemName:"trash")}
                }.font(.subheadline).padding(8).background(.white.opacity(0.05),in:RoundedRectangle(cornerRadius:10))
            }
        }.onAppear{text=source;Task{await reload()}}.onChange(of:source){text=$0}
    }
    @MainActor private func reload()async{
        let items=await UNUserNotificationCenter.current().pendingNotificationRequests()
        requests=items.filter{$0.identifier.hasPrefix("viepn.personal.")}.sorted{$0.identifier<$1.identifier}
    }
    private func schedule(){
        let name=title.trimmingCharacters(in:.whitespacesAndNewlines)
        guard !KeyboardSettings.privateTypingMode,!name.isEmpty,date>Date().addingTimeInterval(60),MessageSafety.warnings(in:name).isEmpty else{status="Tiêu đề, giờ hoặc chế độ riêng tư không hợp lệ.";return}
        let when=date;busy=true
        Task{@MainActor in
            defer{busy=false}
            do{
                let center=UNUserNotificationCenter.current()
                guard try await center.requestAuthorization(options:[.alert,.sound,.badge]) else{status="Chưa cấp quyền thông báo.";return}
                let existing=await center.pendingNotificationRequests()
                guard existing.count<60 else{status="Đã gần giới hạn thông báo đang chờ.";return}
                let content=UNMutableNotificationContent();content.title=String(name.prefix(80));content.body="ViePN · Nhắc hẹn đã tạo";content.sound = .default
                let components=Calendar.current.dateComponents([.year,.month,.day,.hour,.minute],from:when)
                let trigger=UNCalendarNotificationTrigger(dateMatching:components,repeats:false)
                guard trigger.nextTriggerDate() != nil else{status="Thời gian không hợp lệ.";return}
                try await center.add(UNNotificationRequest(identifier:"viepn.personal."+UUID().uuidString,content:content,trigger:trigger))
                status="Đã đăng ký thông báo trên thiết bị.";await reload()
            }catch{status=error.localizedDescription}
        }
    }
}
