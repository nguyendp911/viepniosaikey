import Foundation

struct SymbolEntry: Identifiable, Equatable {
    let value: String
    let keywords: String
    let category: String
    var id: String { value }
}
enum SymbolCatalog {
    static let entries: [SymbolEntry] = [
        .init(value:"😀", keywords:"cười vui happy", category:"Cảm xúc"), .init(value:"😂", keywords:"cười nước mắt lol", category:"Cảm xúc"),
        .init(value:"🥹", keywords:"xúc động rưng rưng", category:"Cảm xúc"), .init(value:"😔", keywords:"buồn tâm trạng", category:"Cảm xúc"),
        .init(value:"🥰", keywords:"yêu thương ngọt ngào", category:"Cảm xúc"), .init(value:"😍", keywords:"yêu thích đẹp", category:"Cảm xúc"),
        .init(value:"😎", keywords:"ngầu kính cool", category:"Cảm xúc"), .init(value:"😡", keywords:"giận tức", category:"Cảm xúc"),
        .init(value:"🤔", keywords:"suy nghĩ hỏi", category:"Cảm xúc"), .init(value:"😭", keywords:"khóc buồn", category:"Cảm xúc"),
        .init(value:"❤️", keywords:"tim tình yêu đỏ", category:"Tình cảm"), .init(value:"💗", keywords:"tim hồng yêu", category:"Tình cảm"),
        .init(value:"💔", keywords:"tim vỡ đau", category:"Tình cảm"), .init(value:"🫶", keywords:"tay tim thương", category:"Tình cảm"),
        .init(value:"💐", keywords:"hoa bó tặng", category:"Tình cảm"), .init(value:"🌹", keywords:"hoa hồng", category:"Tình cảm"),
        .init(value:"👍", keywords:"đồng ý tốt like", category:"Giao tiếp"), .init(value:"🙏", keywords:"cảm ơn cầu nguyện", category:"Giao tiếp"),
        .init(value:"🤝", keywords:"bắt tay hợp tác", category:"Giao tiếp"), .init(value:"👋", keywords:"chào tạm biệt", category:"Giao tiếp"),
        .init(value:"🎉", keywords:"chúc mừng tiệc", category:"Giao tiếp"), .init(value:"✅", keywords:"xong đúng kiểm tra", category:"Giao tiếp"),
        .init(value:"✨", keywords:"ánh sáng lấp lánh sao", category:"Ký tự"), .init(value:"★", keywords:"sao star", category:"Ký tự"),
        .init(value:"♡", keywords:"tim rỗng", category:"Ký tự"), .init(value:"→", keywords:"mũi tên phải", category:"Ký tự"),
        .init(value:"✓", keywords:"dấu tích", category:"Ký tự"), .init(value:"•", keywords:"chấm đầu dòng", category:"Ký tự"),
        .init(value:"∞", keywords:"vô cực", category:"Ký tự"), .init(value:"✦", keywords:"sao bốn cánh", category:"Ký tự"),
        .init(value:"(◕‿◕)", keywords:"cười dễ thương", category:"Kaomoji"), .init(value:"(づ｡◕‿‿◕｡)づ", keywords:"ôm yêu", category:"Kaomoji"),
        .init(value:"(╥﹏╥)", keywords:"khóc buồn", category:"Kaomoji"), .init(value:"¯\\_(ツ)_/¯", keywords:"không biết", category:"Kaomoji"),
        .init(value:"(ง •̀_•́)ง", keywords:"cố lên", category:"Kaomoji"), .init(value:"(｡♥‿♥｡)", keywords:"yêu tim", category:"Kaomoji")
    ]
    static let categories = ["Tất cả", "Yêu thích", "Cảm xúc", "Tình cảm", "Giao tiếp", "Ký tự", "Kaomoji"]
    static var favorites: [String] {
        get { KeyboardSettings.defaults.stringArray(forKey: "viepnaikey.symbolFavorites") ?? [] }
        set { KeyboardSettings.defaults.set(Array(newValue.prefix(64)), forKey: "viepnaikey.symbolFavorites") }
    }
    static func toggle(_ value: String) {
        guard !KeyboardSettings.privateTypingMode else { return }
        var list = favorites
        if list.contains(value) { list.removeAll { $0 == value } } else { list.insert(value, at: 0) }
        favorites = list
    }
    static func folded(_ text: String) -> String {
        text.lowercased().folding(options: .diacriticInsensitive, locale: Locale(identifier: "vi_VN"))
            .replacingOccurrences(of: "đ", with: "d")
    }
    static func search(_ query: String, category: String = "Tất cả") -> [SymbolEntry] {
        let terms = folded(query).split(whereSeparator: { $0.isWhitespace })
        return entries.filter { entry in
            (category == "Tất cả" || (category == "Yêu thích" ? favorites.contains(entry.value) : category == entry.category))
                && terms.allSatisfy { folded(entry.keywords + " " + entry.value).contains($0) }
        }
    }
    static func decorative(_ text: String) -> String {
        "✦ " + String(text.prefix(140)) + " ✦"
    }
}
