import SwiftUI

/// Settings for the smart typing extras. It lives on its own screen (opened
/// from the Keyboard tab) so the busy Keyboard tab stays exactly as it was.
struct SmartTypingSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var emoji = KeyboardSettings.emojiSuggestionsEnabled
    @State private var shorthand = KeyboardSettings.shorthandSuggestionsEnabled
    @State private var spelling = KeyboardSettings.spellingSuggestionsEnabled
    @State private var restoreAccents = KeyboardSettings.restoreDiacriticsEnabled
    @State private var longPressDigits = KeyboardSettings.longPressDigitsEnabled
    @State private var properNouns = KeyboardSettings.properNounsEnabled
    @State private var softer = KeyboardSettings.coupleSoftenEnabled
    @State private var tone = KeyboardSettings.coupleToneEnabled
    @State private var datePhrases = KeyboardSettings.datePhrasesEnabled
    @State private var askProfile = KeyboardSettings.askConversationProfile
    @State private var keyPreview = KeyboardSettings.keyPreviewEnabled
    @State private var showLearnedData = false

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Gợi ý khi gõ"),
                        footer: Text("Tất cả chạy ngay trên máy, không gửi nội dung gõ đi đâu. Bàn phím tải thiết lập mới khi mở lại.")) {
                    Toggle("Gợi ý emoji theo từ", isOn: $emoji)
                        .onChange(of: emoji) { KeyboardSettings.emojiSuggestionsEnabled = $0 }
                    Toggle("Viết tắt chat và số tiền (ntn, vs, 50k…)", isOn: $shorthand)
                        .onChange(of: shorthand) { KeyboardSettings.shorthandSuggestionsEnabled = $0 }
                    Toggle("Sửa lỗi chính tả hay gặp", isOn: $spelling)
                        .onChange(of: spelling) { KeyboardSettings.spellingSuggestionsEnabled = $0 }
                    Toggle("Thêm dấu cho câu gõ không dấu", isOn: $restoreAccents)
                        .onChange(of: restoreAccents) { KeyboardSettings.restoreDiacriticsEnabled = $0 }
                }
                Section(header: Text("Phím và tên riêng"),
                        footer: Text("Tên riêng chỉ được viết hoa tự động khi bạn đã viết hoa tên đó từ 2 lần trở lên, và cần bật “Ghi nhớ từ đã gõ”.")) {
                    Toggle("Giữ phím chữ hàng trên để gõ số", isOn: $longPressDigits)
                        .onChange(of: longPressDigits) { KeyboardSettings.longPressDigitsEnabled = $0 }
                    Toggle("Tự viết hoa tên riêng đã học", isOn: $properNouns)
                        .onChange(of: properNouns) { KeyboardSettings.properNounsEnabled = $0 }
                }
                Section(header: Text("Giao diện bàn phím"),
                        footer: Text("Bong bóng chữ hiện phía trên phím đang bấm, giống bàn phím iOS. Chế độ siêu nhẹ tự tắt.")) {
                    Toggle("Bong bóng chữ khi bấm phím", isOn: $keyPreview)
                        .onChange(of: keyPreview) { KeyboardSettings.keyPreviewEnabled = $0 }
                }
                Section(header: Text("Couple và hẹn hò"),
                        footer: Text("Hai gợi ý đầu chỉ hoạt động khi nút Couple trên bàn phím đang bật. Bàn phím chỉ gợi ý, không tự sửa tin của bạn.")) {
                    Toggle("Gợi ý nói nhẹ hơn (“lúc nào cũng”, “kệ em”…)", isOn: $softer)
                        .onChange(of: softer) { KeyboardSettings.coupleSoftenEnabled = $0 }
                    Toggle("Đoán tâm trạng tin nhắn đã dán, gợi ý phong cách", isOn: $tone)
                        .onChange(of: tone) { KeyboardSettings.coupleToneEnabled = $0 }
                    Toggle("Đổi “mai 7h”, “t6 tuần sau” thành ngày giờ cụ thể", isOn: $datePhrases)
                        .onChange(of: datePhrases) { KeyboardSettings.datePhrasesEnabled = $0 }
                    Toggle("Nhớ hồ sơ theo từng cuộc trò chuyện và hỏi khi gặp chat mới", isOn: $askProfile)
                        .onChange(of: askProfile) { KeyboardSettings.askConversationProfile = $0 }
                    NavigationLink(destination: SpecialDatesView()) {
                        Text("Ngày đặc biệt (ngày yêu, sinh nhật…)")
                    }
                }
                Section(header: Text("Dữ liệu đã học")) {
                    Button("Quản lý dữ liệu đã học") { showLearnedData = true }
                }
            }
            .navigationTitle("Gõ thông minh")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Xong") { dismiss() }
                }
            }
            .sheet(isPresented: $showLearnedData) {
                LearnedDataView()
            }
        }
    }
}
