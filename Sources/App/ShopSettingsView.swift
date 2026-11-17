import SwiftUI

/// The shop's name, shipping fee, payment line and products. The keyboard's
/// "Bán hàng" chip reads this. Saved on this device only.
struct ShopSettingsView: View {
    @State private var profile = ShopStore.profile
    @State private var shipText = ""
    @State private var newName = ""
    @State private var newPrice = ""
    @State private var newNote = ""
    @State private var priceError = false

    var body: some View {
        List {
            Section(header: Text("Cửa hàng"),
                    footer: Text("Tên shop và thông tin chuyển khoản được chèn vào các mẫu tin (xin địa chỉ, thanh toán…).")) {
                TextField("Tên shop (ví dụ: Shop Mây)", text: $profile.shopName)
                    .onChange(of: profile.shopName) { _ in save() }
                TextField("Phí ship mặc định (ví dụ: 20k)", text: $shipText)
                    .keyboardType(.numbersAndPunctuation)
                    .onChange(of: shipText) { value in
                        profile.shipFee = ShopTools.parsePrice(value) ?? 0
                        save()
                    }
                TextField("Thông tin chuyển khoản (một dòng)", text: $profile.bankLine)
                    .onChange(of: profile.bankLine) { _ in save() }
            }
            Section(header: Text("Sản phẩm (\(profile.products.count))"),
                    footer: Text("Gõ trên bàn phím “áo thun x2, quần jean 1, ship 25k” rồi chọn Bán hàng → Tính đơn: bàn phím tự cộng tiền.")) {
                if profile.products.isEmpty {
                    Text("Chưa có sản phẩm.").foregroundColor(.secondary)
                }
                ForEach(profile.products) { product in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(product.name)
                            Spacer()
                            Text(ShopTools.money(product.price)).foregroundColor(.secondary)
                        }
                        if !product.note.isEmpty {
                            Text(product.note).font(.footnote).foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete { offsets in
                    profile.products.remove(atOffsets: offsets)
                    save()
                }
            }
            Section(header: Text("Thêm sản phẩm")) {
                TextField("Tên sản phẩm", text: $newName)
                TextField("Giá (ví dụ: 150k hoặc 150000)", text: $newPrice)
                    .keyboardType(.numbersAndPunctuation)
                TextField("Ghi chú (size, màu…) – không bắt buộc", text: $newNote)
                if priceError {
                    Text("Giá chưa đúng. Ví dụ: 150k, 150.000 hoặc 1tr5.")
                        .font(.footnote).foregroundColor(.red)
                }
                Button("Thêm") { add() }
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty
                              || newPrice.trimmingCharacters(in: .whitespaces).isEmpty
                              || profile.products.count >= ShopTools.maxProducts)
            }
        }
        .navigationTitle("Cửa hàng")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            profile = ShopStore.profile
            shipText = profile.shipFee > 0 ? String(profile.shipFee) : ""
        }
    }

    private func add() {
        guard let price = ShopTools.parsePrice(newPrice) else {
            priceError = true
            return
        }
        priceError = false
        let name = String(newName.trimmingCharacters(in: .whitespacesAndNewlines).prefix(60))
        let note = String(newNote.trimmingCharacters(in: .whitespacesAndNewlines).prefix(60))
        profile.products.append(ShopProduct(id: UUID().uuidString, name: name, price: price, note: note))
        newName = ""
        newPrice = ""
        newNote = ""
        save()
    }

    private func save() {
        ShopStore.profile = profile
    }
}
