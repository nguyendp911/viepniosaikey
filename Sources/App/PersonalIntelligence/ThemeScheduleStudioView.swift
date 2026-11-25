import SwiftUI

struct ThemeScheduleStudioView:View{
    @State private var schedule=ThemeSchedule.current
    @State private var theme=KeyboardSettings.theme
    private let themes=[("holographic","Holographic Glass"),("obsidiangold","Obsidian Gold"),("zenedition","Zen Edition"),("auroralive","Aurora Live")]
    var body:some View{
        VStack(alignment:.leading,spacing:14){
            Text("Theme Scheduler").font(.title.bold())
            Text("Chuyển giao diện theo giờ địa phương khi mở bàn phím và kiểm tra mỗi phút lúc bàn phím hiện. Không có tác vụ nền.").font(.caption).foregroundStyle(.secondary)
            ForEach(themes,id:\.0){item in
                Button{KeyboardSettings.theme=item.0;theme=item.0;schedule.enabled=false}label:{
                    VStack(alignment:.leading,spacing:8){
                        HStack{Text(item.1).bold();Spacer();if theme==item.0{Image(systemName:"checkmark.circle.fill").foregroundStyle(.cyan)}}
                        KeyboardThemePreview(theme:item.0,spacing:KeyboardSettings.keySpacing,height:KeyboardSettings.keyHeight)
                    }.padding(10).background(.white.opacity(0.06),in:RoundedRectangle(cornerRadius:12))
                }.buttonStyle(.plain)
            }
            Toggle("Tự chuyển theme theo giờ",isOn:$schedule.enabled)
            Stepper("Bắt đầu ngày: \(schedule.dayHour):00",value:$schedule.dayHour,in:0...23)
            Stepper("Bắt đầu đêm: \(schedule.nightHour):00",value:$schedule.nightHour,in:0...23)
            Picker("Theme ban ngày",selection:$schedule.dayTheme){ForEach(KeyboardSettings.availableThemes,id:\.self){Text($0).tag($0)}}
            Picker("Theme ban đêm",selection:$schedule.nightTheme){ForEach(KeyboardSettings.availableThemes,id:\.self){Text($0).tag($0)}}
            if schedule.dayHour==schedule.nightHour{Text("Hai mốc giờ phải khác nhau. Khi trùng, dùng theme thủ công.").font(.caption).foregroundStyle(.orange)}
            TimelineView(.periodic(from:.now,by:60)){context in
                let effective=schedule.resolve(base:theme,hour:Calendar.current.component(.hour,from:context.date),allowed:KeyboardSettings.availableThemes)
                Text("Theme hiệu lực: "+effective).font(.subheadline.bold()).foregroundStyle(.cyan)
            }
        }.onChange(of:schedule){ThemeSchedule.current=$0}
    }
}
