import Foundation

/// A product the user sells. Prices are whole dong.
struct ShopProduct: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var price: Int
    var note: String
}

struct ShopProfile: Codable, Equatable {
    var shopName: String = ""
    var shipFee: Int = 0
    /// One line the customer can copy, for example "STK 0123456789 · Vietcombank · NGUYEN VAN A".
    var bankLine: String = ""
    var products: [ShopProduct] = []
}

/// Quick replies and order totals for people who sell on chat apps. All local.
enum ShopTools {
    static let maxProducts = 60

    static func decode(_ data: Data?) -> ShopProfile {
        guard let data, let profile = try? JSONDecoder().decode(ShopProfile.self, from: data) else {
            return ShopProfile()
        }
        var clean = profile
        clean.products = Array(profile.products.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty
            && $0.price > 0 }.prefix(maxProducts))
        return clean
    }

    static func encode(_ profile: ShopProfile) -> Data? {
        var clean = profile
        clean.products = Array(profile.products.prefix(maxProducts))
        return try? JSONEncoder().encode(clean)
    }

    // MARK: Money

    static func money(_ value: Int) -> String {
        MoneyShorthand.format(value) + "đ"
    }

    /// "150k", "150.000", "150000", "1tr5" -> 150000 ... A bare number under a
    /// thousand is read as thousands ("150" -> 150.000).
    static func parsePrice(_ text: String) -> Int? {
        var value = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        for suffix in ["vnđ", "vnd", "đ", "d"] where value.hasSuffix(suffix) {
            value = String(value.dropLast(suffix.count)).trimmingCharacters(in: .whitespaces)
            break
        }
        guard !value.isEmpty else { return nil }
        if value.allSatisfy({ $0.isNumber || $0 == "." || $0 == "," }) {
            let digits = value.filter { $0.isNumber }
            guard let number = Int(digits), number > 0 else { return nil }
            let hadSeparator = value.contains(".") || value.contains(",")
            if !hadSeparator && number < 1000 { return number * 1000 }
            return number
        }
        guard let shorthand = MoneyShorthand.suggestion(for: value) else { return nil }
        return Int(shorthand.filter { $0.isNumber })
    }

    // MARK: Orders

    struct Order: Equatable {
        struct Line: Equatable {
            let product: ShopProduct
            let quantity: Int
            var subtotal: Int { product.price * quantity }
        }
        let lines: [Line]
        let unmatched: [String]
        let shipping: Int
        var total: Int { lines.reduce(0) { $0 + $1.subtotal } + shipping }
    }

    private static func padded(_ text: String) -> String {
        " " + ScreenshotTranscript.looseKey(text) + " "
    }

    /// "áo thun x2, quần jean 1, ship 25k" -> an order, or nil if no product
    /// of the catalog is mentioned.
    static func order(from text: String, profile: ShopProfile) -> Order? {
        guard !profile.products.isEmpty else { return nil }
        var parts: [String] = []
        for chunk in text.components(separatedBy: CharacterSet(charactersIn: ",;+\n")) {
            parts.append(contentsOf: chunk.components(separatedBy: " và "))
        }
        let keys = profile.products.map { padded($0.name) }
        var lines: [Order.Line] = []
        var unmatched: [String] = []
        var shipping = profile.shipFee
        for raw in parts {
            let part = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if part.isEmpty { continue }
            let key = padded(part)
            if key.contains(" ship ") || key.contains(" van chuyen ") {
                if key.contains(" free ") || key.contains(" mien phi ") {
                    shipping = 0
                } else if let last = part.split(separator: " ").last, let fee = parsePrice(String(last)) {
                    shipping = fee
                }
                continue
            }
            var best: Int?
            for (index, productKey) in keys.enumerated() where key.contains(productKey) {
                if best == nil || productKey.count > keys[best!].count { best = index }
            }
            guard let chosen = best else { unmatched.append(part); continue }
            let remainder = key.replacingOccurrences(of: keys[chosen], with: " ")
            lines.append(Order.Line(product: profile.products[chosen],
                                    quantity: quantity(in: remainder)))
        }
        guard !lines.isEmpty else { return nil }
        return Order(lines: lines, unmatched: unmatched, shipping: shipping)
    }

    /// "x2", "2x" or a bare number next to the product name; 1 when absent.
    private static func quantity(in remainder: String) -> Int {
        for word in remainder.split(separator: " ") {
            var token = String(word)
            if token.hasPrefix("x") { token.removeFirst() }
            if token.hasSuffix("x") { token.removeLast() }
            if let number = Int(token), (1...999).contains(number) { return number }
        }
        return 1
    }

    static func summary(_ order: Order, profile: ShopProfile) -> String {
        var rows = ["🧾 Đơn hàng" + (profile.shopName.isEmpty ? "" : " · " + profile.shopName)]
        for line in order.lines {
            rows.append("• \(line.quantity) × \(line.product.name) = \(money(line.subtotal))")
        }
        if order.shipping > 0 { rows.append("Phí ship: " + money(order.shipping)) }
        rows.append("Tổng cộng: " + money(order.total))
        return rows.joined(separator: "\n")
    }

    // MARK: Ready-made messages

    static func templates(for profile: ShopProfile) -> [(title: String, text: String)] {
        let shop = profile.shopName.isEmpty ? "shop" : profile.shopName
        let bank = profile.bankLine.isEmpty ? "(chưa nhập thông tin chuyển khoản)" : profile.bankLine
        var list: [(title: String, text: String)] = []
        list.append(("Chào khách",
                     "Dạ \(shop) xin chào ạ! Anh/chị cần tư vấn sản phẩm nào ạ? 😊"))
        if !profile.products.isEmpty {
            let rows = profile.products.prefix(8).map { product -> String in
                "• " + product.name + " – " + money(product.price)
                    + (product.note.isEmpty ? "" : " (" + product.note + ")")
            }
            list.append(("Báo giá", "Dạ bên em có:\n" + rows.joined(separator: "\n")
                         + "\nAnh/chị quan tâm mẫu nào để em tư vấn thêm ạ?"))
        }
        list.append(("Xin địa chỉ",
                     "Dạ anh/chị cho em xin tên, số điện thoại và địa chỉ nhận hàng để em lên đơn ạ."))
        list.append(("Xác nhận đơn",
                     "Dạ em xác nhận đơn hàng của anh/chị rồi ạ. Em sẽ gửi hàng sớm nhất. Cảm ơn anh/chị đã ủng hộ \(shop) ❤️"))
        list.append(("Thanh toán",
                     "Anh/chị chuyển khoản giúp em theo thông tin này ạ:\n\(bank)\nChuyển xong anh/chị nhắn em để em xác nhận nha."))
        list.append(("Đã gửi hàng",
                     "Dạ em đã gửi hàng cho anh/chị rồi ạ. Có mã vận đơn em sẽ nhắn ngay. Anh/chị nhớ để ý điện thoại giúp em nha."))
        list.append(("Hết hàng",
                     "Dạ mẫu này bên em tạm hết hàng rồi ạ. Em báo anh/chị ngay khi có hàng lại, hoặc em gợi ý mẫu tương tự nhé?"))
        list.append(("Đổi trả",
                     "Dạ nếu hàng có lỗi hoặc không đúng mẫu, anh/chị chụp ảnh gửi em trong 3 ngày, \(shop) sẽ hỗ trợ đổi trả ạ."))
        list.append(("Xin đánh giá",
                     "Dạ cảm ơn anh/chị đã ủng hộ \(shop) ạ. Nếu hài lòng, anh/chị cho em xin đánh giá để shop có thêm động lực nhé ❤️"))
        return list
    }
}
