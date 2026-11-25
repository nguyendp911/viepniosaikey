import Foundation

@main
struct VerifyPersonalIntelligence {
    static func main() throws {
        let a=PersonalMemory(personaID:"a",kind:"Sở thích",title:"Trà",detail:"Thích trà",date:Date(timeIntervalSince1970:1))
        let b=PersonalMemory(personaID:"b",kind:"Ghi chú",title:"Khác",detail:"Không chia sẻ",date:Date(timeIntervalSince1970:2))
        precondition(PersonalMemoryStore.scoped([a,b],personaID:"a")==[a])
        let context=PersonalMemoryStore.context([a,b],selected:[a.id,b.id],personaID:"a")
        precondition(context.contains("Thích trà") && !context.contains("Không chia sẻ"))
        precondition(PersonalMemoryStore.context([a],selected:[],personaID:"a").isEmpty)
        precondition(!PersonalMemoryStore.valid(.init(personaID:"a",kind:"Ghi chú",title:"OTP 123456",detail:"")))
        var mix=ToneMix(values:[-1,120],length:"x")
        mix=mix.normalized
        precondition(mix.values==[0,100,0,0,0,0] && mix.length=="Ngắn")
        precondition(mix.instruction.contains("100/100"))
        precondition(PersonalUnits.convert(1,group:"Chiều dài",from:"km",to:"m")==1000)
        precondition(abs(PersonalUnits.convert(32,group:"Nhiệt độ",from:"f",to:"c")!)<0.00001)
        precondition(PersonalUnits.convert(-300,group:"Nhiệt độ",from:"c",to:"k")==nil)
        precondition(PersonalUnits.currency(2,rate:3)==6)
        precondition(PersonalUnits.currency(2,rate:0)==nil)
        let password=SecureTextGenerator.password(length:24,symbols:true)
        precondition(password.count==24 && password.contains(where:{$0.isUppercase}) && password.contains(where:{$0.isLowercase}) && password.contains(where:{$0.isNumber}) && password.contains(where:{"!@#$%&*+-=?".contains($0)}))
        let diff=PersonalDiff.compare("a b c","a d c")
        precondition(diff.filter{$0.kind=="remove"}.map(\.text)==["b"])
        precondition(diff.filter{$0.kind=="add"}.map(\.text)==["d"])
        precondition(ReminderDateHint.parse("Hẹn 29/02/2028 09:15") != nil)
        precondition(ReminderDateHint.parse("Hẹn 31/02/2028 09:15")==nil)
        precondition(ReminderDateHint.parse("mai 9 giờ")==nil)
        var schedule=ThemeSchedule();schedule.enabled=true
        precondition(schedule.resolve(base:"system",hour:8,allowed:["zenedition","obsidiangold"])=="zenedition")
        precondition(schedule.resolve(base:"system",hour:22,allowed:["zenedition","obsidiangold"])=="obsidiangold")
        schedule.dayHour=20;schedule.nightHour=6
        precondition(schedule.resolve(base:"system",hour:23,allowed:["zenedition","obsidiangold"])=="zenedition")
        schedule.nightHour=20
        precondition(schedule.resolve(base:"system",hour:23,allowed:["zenedition","obsidiangold"])=="system")
        precondition(Set(PersonalIntelligenceCatalog.tasks.map(\.id)).count==PersonalIntelligenceCatalog.tasks.count)
        print("PASS Personal Intelligence 3.0: scoped memory, consent selection, tone, units, password, diff, dates, scheduler")
    }
}
