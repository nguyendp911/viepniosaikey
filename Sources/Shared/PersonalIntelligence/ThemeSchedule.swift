import Foundation

struct ThemeSchedule: Codable, Equatable {
    var enabled=false
    var dayHour=7
    var nightHour=19
    var dayTheme="zenedition"
    var nightTheme="obsidiangold"
    static var current:Self {
        get { guard let data=KeyboardSettings.defaults.data(forKey:"viepnaikey.themeSchedule3"),let value=try? JSONDecoder().decode(Self.self,from:data) else { return .init() }; return value }
        set { if let data=try? JSONEncoder().encode(newValue) { KeyboardSettings.defaults.set(data,forKey:"viepnaikey.themeSchedule3") } }
    }
    func resolve(base:String,hour:Int,allowed:[String])->String {
        guard enabled,(0...23).contains(dayHour),(0...23).contains(nightHour),dayHour != nightHour else { return base }
        let day=dayHour<nightHour ? hour>=dayHour && hour<nightHour : hour>=dayHour || hour<nightHour
        let theme=day ? dayTheme : nightTheme
        return allowed.contains(theme) ? theme : base
    }
    static func effective(now:Date=Date())->String {
        current.resolve(base:KeyboardSettings.theme,hour:Calendar.current.component(.hour,from:now),allowed:KeyboardSettings.availableThemes)
    }
}
