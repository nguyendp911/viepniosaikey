import SwiftUI
import UserNotifications

private struct CoupleMoment:Codable,Identifiable{
    var id=UUID();var title:String;var date:Date;var reminder=false
}
private struct CoupleJournalEntry:Codable,Identifiable{
    var id=UUID();var text:String;var date=Date()
}
/// Only the host app's private, protected local directory. Never in App Group.
private enum CouplePrivateStore{
    static func url(_ name:String)->URL? {
        guard let base=FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask).first else{return nil}
        let dir=base.appendingPathComponent("CouplePrivate",isDirectory:true)
        do {
            try FileManager.default.createDirectory(at:dir,withIntermediateDirectories:true)
            var mutable=dir;var values=URLResourceValues();values.isExcludedFromBackup=true;try mutable.setResourceValues(values)
            return dir.appendingPathComponent(name+".json")
        }catch{return nil}
    }
    static func read<T:Decodable>(_ name:String,as type:T.Type)->[T]{
        guard !KeyboardSettings.privateTypingMode,let url=url(name),let data=try? Data(contentsOf:url),data.count<=1_000_000 else{return []}
        return (try? JSONDecoder().decode([T].self,from:data)) ?? []
    }
    static func write<T:Encodable>(_ values:[T],name:String)->Bool{
        guard !KeyboardSettings.privateTypingMode,let url=url(name),let data=try? JSONEncoder().encode(values),data.count<=1_000_000 else{return false}
        // Never replace an existing unreadable or corrupt file with an empty
        // in-memory model (e.g. before first unlock).
        if FileManager.default.fileExists(atPath:url.path) {
            guard let existing=try? Data(contentsOf:url),existing.count<=1_000_000,
                  (try? JSONSerialization.jsonObject(with:existing)) is [Any] else{return false}
        }
        do{try data.write(to:url,options:[.atomic,.completeFileProtection]);return true}catch{return false}
    }
}
struct CoupleJournalStudio:View{
    @State private var entries=CouplePrivateStore.read("journal",as:CoupleJournalEntry.self)
    @State private var draft=""
    @State private var status=""
    var body:some View{
        List{
            Section("Ghi chú cá nhân"){
                Text("Lưu cục bộ trong app, bảo vệ tệp theo thiết bị; không gửi AI hay xuất vào bản sao học bàn phím. Không lưu trong chế độ riêng tư.").font(.caption)
                TextEditor(text:$draft).frame(minHeight:100)
                Button("Lưu ghi chú"){
                    let text=draft.trimmingCharacters(in:.whitespacesAndNewlines)
                    guard !text.isEmpty,text.count<=2000,entries.count<200 else{status="Giới hạn 200 ghi chú, 2.000 ký tự mỗi ghi chú.";return}
                    let next=[CoupleJournalEntry(text:text)]+entries
                    if CouplePrivateStore.write(next,name:"journal"){entries=next;draft="";status="Đã lưu."}else{status="Không lưu được."}
                }
                Text(status).font(.caption)
            }
            Section("Nhật ký"){
                ForEach(entries){entry in
                    VStack(alignment:.leading,spacing:5){
                        Text(entry.date.formatted(date:.abbreviated,time:.shortened)).font(.caption).foregroundStyle(.secondary)
                        Text(entry.text).font(.subheadline)
                        Button("Xóa",role:.destructive){
                            let next=entries.filter{$0.id != entry.id}
                            if CouplePrivateStore.write(next,name:"journal"){entries=next}else{status="Không xóa được."}
                        }.buttonStyle(.borderless)
                    }
                }
            }
        }
    }
}
struct CoupleMomentsStudio:View{
    @State private var items=CouplePrivateStore.read("moments",as:CoupleMoment.self)
    @State private var title=""
    @State private var date=Date()
    @State private var status=""
    @State private var busy=false
    var body:some View{
        List{
            Section("Ngày đặc biệt"){
                TextField("Tên kỷ niệm",text:$title)
                DatePicker("Ngày",selection:$date,displayedComponents:.date)
                Button("Thêm ngày"){
                    let clean=title.trimmingCharacters(in:.whitespacesAndNewlines)
                    guard !clean.isEmpty,clean.count<=64,items.count<30 else{status="Giới hạn 30 ngày, tên tối đa 64 ký tự.";return}
                    let next=items+[CoupleMoment(title:clean,date:date)]
                    if CouplePrivateStore.write(next,name:"moments"){items=next;title=""}else{status="Không lưu được."}
                }
                Text("Nhắc hằng năm lúc 9:00 theo lịch dương. Thông báo chung, không hiện tên kỷ niệm trên màn hình khóa.").font(.caption)
                Text(status).font(.caption)
            }
            Section("Kỷ niệm đã lưu"){
                ForEach(items){item in
                    VStack(alignment:.leading,spacing:5){
                        Text(item.title).font(.headline)
                        Text(item.date.formatted(date:.abbreviated,time:.omitted)).font(.caption)
                        Button(item.reminder ? "Tắt nhắc":"Bật nhắc hằng năm"){toggle(item)}.disabled(busy).buttonStyle(.borderless)
                        Button("Xóa",role:.destructive){
                            let next=items.filter{$0.id != item.id}
                            if CouplePrivateStore.write(next,name:"moments"){
                                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers:["couple."+item.id.uuidString]);items=next
                            }else{status="Không xóa được."}
                        }.disabled(busy).buttonStyle(.borderless)
                    }
                }
            }
        }
    }
    private func toggle(_ item:CoupleMoment){
        guard !KeyboardSettings.privateTypingMode,!busy else{return};busy=true
        Task{@MainActor in
            defer{busy=false}
            let center=UNUserNotificationCenter.current(),id="couple."+item.id.uuidString
            do{
                if !item.reminder{
                    guard try await center.requestAuthorization(options:[.alert,.sound])else{status="Chưa có quyền thông báo.";return}
                    let day=Calendar(identifier:.gregorian).dateComponents([.month,.day],from:item.date)
                    var components=day;components.hour=9;components.minute=0
                    let content=UNMutableNotificationContent();content.title="Couple Studio";content.body="Hôm nay có một ngày đặc biệt bạn đã lưu.";content.sound = .default
                    try await center.add(UNNotificationRequest(identifier:id,content:content,trigger:UNCalendarNotificationTrigger(dateMatching:components,repeats:true)))
                }
                var next=items
                guard let index=next.firstIndex(where:{$0.id==item.id})else{return}
                next[index].reminder.toggle()
                guard CouplePrivateStore.write(next,name:"moments")else{
                    if !item.reminder{center.removePendingNotificationRequests(withIdentifiers:[id])};status="Không lưu được.";return
                }
                if item.reminder{center.removePendingNotificationRequests(withIdentifiers:[id])}
                items=next;status="Đã cập nhật nhắc nhở."
            }catch{status=error.localizedDescription}
        }
    }
}
