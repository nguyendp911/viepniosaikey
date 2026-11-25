import SwiftUI

struct ProProfilesStudioView:View{
    @State private var profiles=OfflineProStore.profiles
    @State private var name=""
    @State private var status=""
    private let builtins=["Daily","Couple","Business","Developer","Korean","Private","Gaming"]
    var body:some View{
        VStack(alignment:.leading,spacing:12){
            Text("Keyboard Profiles").font(.title.bold())
            Text("Hồ sơ lưu bố cục, thiết kế, theme, thứ tự toolbar và chế độ riêng tư. Snippet gắn tên hồ sơ. Chuyển thủ công, không nhận diện ứng dụng đang dùng.").font(.caption).foregroundStyle(.secondary)
            ForEach(builtins,id:\.self){item in
                Button("Tạo preset "+item){createPreset(item)}.buttonStyle(.bordered)
            }
            HStack{TextField("Tên hồ sơ riêng",text:$name).textFieldStyle(.roundedBorder);Button("Lưu hiện tại"){save(name,config:OfflineKeyboardConfig.current,theme:KeyboardSettings.theme,privateMode:KeyboardSettings.privateTypingMode);name=""}}
            ForEach(profiles){profile in
                VStack(alignment:.leading,spacing:7){
                    HStack{Text(profile.name).bold();Spacer();Text(profile.config.layout.title).font(.caption).foregroundStyle(.secondary)}
                    ProKeyboardPreview(config:profile.config,theme:profile.theme)
                    HStack{
                        Button("Áp dụng"){apply(profile)}
                        Button("Ghi đè bằng hiện tại"){save(profile.name,config:OfflineKeyboardConfig.current,theme:KeyboardSettings.theme,privateMode:KeyboardSettings.privateTypingMode)}
                        Spacer()
                        Button(role:.destructive){profiles.removeAll{$0.id==profile.id};OfflineProStore.profiles=profiles}label:{Image(systemName:"trash")}
                    }.buttonStyle(.borderless)
                }.padding(9).background(.white.opacity(0.05),in:RoundedRectangle(cornerRadius:12))
            }
            Text(status).font(.caption).foregroundStyle(.cyan)
        }
    }
    private func createPreset(_ name:String){
        var config=OfflineKeyboardConfig();var theme="titaniumpro"
        switch name{
        case "Couple":theme="rose";config.particles="heart"
        case "Business":theme="zenedition";config.numberRow=true
        case "Developer":config.layout = .developer;config.numberRow=true;theme="obsidiangold"
        case "Korean":config.layout = .hangul;theme="liquidglass"
        case "Private":theme="amoled"
        case "Gaming":theme="rgbpro";config.particles="rgb"
        default:break
        }
        save(name,config:config,theme:theme,privateMode:name=="Private")
    }
    private func save(_ name:String,config:OfflineKeyboardConfig,theme:String,privateMode:Bool){
        let clean=String(name.trimmingCharacters(in:.whitespacesAndNewlines).prefix(40))
        guard !clean.isEmpty else{return}
        var value=config;value.profile=clean
        let profile=ProKeyboardProfile(name:clean,config:value.normalized,theme:theme,toolbarOrder:ToolbarPreferences.order,privateMode:privateMode)
        profiles.removeAll{$0.name==clean};profiles.insert(profile,at:0);OfflineProStore.profiles=profiles;profiles=OfflineProStore.profiles;status="Đã lưu "+clean
    }
    private func apply(_ profile:ProKeyboardProfile){
        OfflineKeyboardConfig.current=profile.config;KeyboardSettings.theme=profile.theme;KeyboardSettings.privateTypingMode=profile.privateMode
        ToolbarPreferences.order=profile.toolbarOrder
        var schedule=ThemeSchedule.current;schedule.enabled=false;ThemeSchedule.current=schedule
        status="Đã áp dụng "+profile.name+". Mở lại bàn phím."
    }
}
