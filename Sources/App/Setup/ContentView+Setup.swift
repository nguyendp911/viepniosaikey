import SwiftUI
import UIKit
import AudioToolbox
import PhotosUI

extension ContentView {
    var activationGuide: some View {
        card(title: "Kích hoạt bàn phím", subtitle: "Hướng dẫn thiết lập trên iPhone",
             icon: "keyboard") {
            DisclosureGroup("Xem hướng dẫn kích hoạt", isExpanded: $showGuide) {
                VStack(alignment: .leading, spacing: 11) {
                    guideStep(1, "Cài đặt → Cài đặt chung → Bàn phím.")
                    guideStep(2, "Chọn Bàn phím → Thêm bàn phím mới.")
                    guideStep(3, "Chọn ViePN AI Keyboard.")
                    guideStep(4, "Để gọi AI, bật Cho phép truy cập đầy đủ nếu bạn tin tưởng ứng dụng.")
                    guideStep(5, "Nếu iOS còn hỏi quyền Dán: Cài đặt → Ứng dụng → ViePN AI Keyboard → Dán từ ứng dụng khác → Cho phép (khi mục này xuất hiện).")
                    Text("Nút Dán dùng điều khiển của Apple. Quyền lâu dài do iOS quản lý, ứng dụng không tự cấp quyền.")
                        .font(.system(size: 11))
                        .foregroundStyle(muted)
                    actionButton("Mở Cài đặt của ứng dụng", symbol: "gearshape",
                                 prominent: true) {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    Text("iOS có thể yêu cầu bạn điều hướng thủ công tới mục Bàn phím.")
                        .font(.system(size: 11))
                        .foregroundStyle(muted)
                }
                .padding(.top, 10)
            }
            .tint(cyan)
        }
    }

    func guideStep(_ number: Int, _ description: String) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Text("\(number)")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 25, height: 25)
                .background(violet.opacity(0.8), in: Circle())
            Text(description)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.91))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    var keyboardDiagnostics: some View {
        card(title: "Chẩn đoán bàn phím", subtitle: "Kiểm tra Keyboard Extension trong ứng dụng",
             icon: "checkmark.shield") {
            DisclosureGroup("Kiểm tra cấu trúc IPA đã cài", isExpanded: $showDiagnosis) {
                VStack(alignment: .leading, spacing: 11) {
                    Text(keyboardDiagnosis)
                        .font(.system(size: 12))
                        .foregroundStyle(muted)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 9) {
                        actionButton("Kiểm tra", symbol: "checkmark.shield", prominent: true) {
                            keyboardDiagnosis = diagnoseKeyboard()
                        }
                        actionButton("Sao chép", symbol: "doc.on.doc") {
                            UIPasteboard.general.string = keyboardDiagnosis
                        }
                    }
                    Text("Chỉ kiểm tra cấu trúc extension; không xác nhận chữ ký hoặc việc iOS đã bật bàn phím.")
                        .font(.system(size: 11))
                        .foregroundStyle(muted)
                }
                .padding(.top, 10)
            }
            .tint(cyan)
        }
    }

    var clipboardSettingsCard: some View {
        keyboardPanel("Clipboard chủ động", icon: "doc.on.clipboard") {
            VStack(alignment: .leading, spacing: 10) {
                Text("Trên bàn phím, chạm Dán để lấy nội dung cho AI; nhấn giữ Dán → Lưu đoạn vừa Dán để lưu. ViePN không theo dõi clipboard tự động.")
                    .font(.system(size: 11))
                    .foregroundStyle(muted)
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    Text("Đã lưu: \(savedClipboard.count)/15")
                        .font(.system(size: 12, weight: .medium))
                    Spacer()
                    Button {
                        savedClipboard = ClipboardVault.items
                    } label: { Label("Làm mới", systemImage: "arrow.clockwise") }
                        .font(.system(size: 11))
                    Button(role: .destructive) {
                        ClipboardVault.clear()
                        savedClipboard = []
                    } label: { Label("Xóa hết", systemImage: "trash") }
                        .font(.system(size: 11))
                }
                ForEach(savedClipboard.indices, id: \.self) { index in
                    HStack(spacing: 8) {
                        Text(savedClipboard[index])
                            .font(.system(size: 11))
                            .lineLimit(2)
                        Spacer()
                        Button {
                            UIPasteboard.general.string = savedClipboard[index]
                        } label: { Image(systemName: "doc.on.doc") }
                            .accessibilityLabel("Sao chép đoạn " + String(index + 1))
                        Button {
                            var items = ClipboardVault.items
                            if items.indices.contains(index) {
                                items.remove(at: index)
                                ClipboardVault.items = items
                                savedClipboard = items
                            }
                        } label: { Image(systemName: "trash").foregroundStyle(.red.opacity(0.8)) }
                            .accessibilityLabel("Xóa đoạn " + String(index + 1))
                    }
                }
                Text("Clipboard tự hết hạn sau 7 ngày kể từ lúc lưu (khi truy cập). Không lưu mật khẩu, OTP hoặc dữ liệu nhạy cảm. Dữ liệu lưu trên thiết bị trong App Group.")
                    .font(.system(size: 10))
                    .foregroundStyle(muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    var privacyInfo: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "hand.raised.fill")
                .foregroundStyle(cyan)
            Text("Không tự đọc cuộc hội thoại. Clipboard chỉ được truy cập khi bạn chủ động bấm Dán; nội dung được gửi tới dịch vụ AI khi bạn chọn AI Online. API Key được lưu trong Keychain dùng chung App Group.")
                .font(.system(size: 11))
                .foregroundStyle(muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    func diagnoseKeyboard() -> String {
        guard let plugins = Bundle.main.builtInPlugInsURL else {
            return "KHÔNG TÌM THẤY thư mục PlugIns trong ứng dụng. IPA thiếu extension."
        }
        let extensionURL = plugins.appendingPathComponent("ViePNKeyboardExtension.appex")
        guard FileManager.default.fileExists(atPath: extensionURL.path) else {
            let names = (try? FileManager.default.contentsOfDirectory(atPath: plugins.path)) ?? []
            return "THIẾU ViePNKeyboardExtension.appex. Các mục trong PlugIns: " + names.joined(separator: ", ")
        }
        guard let bundle = Bundle(url: extensionURL) else {
            return "Có .appex nhưng không đọc được bundle. Kiểm tra đóng gói IPA."
        }
        let point = (bundle.object(forInfoDictionaryKey: "NSExtension") as? [String: Any])?["NSExtensionPointIdentifier"] as? String ?? "(thiếu)"
        let principal = (bundle.object(forInfoDictionaryKey: "NSExtension") as? [String: Any])?["NSExtensionPrincipalClass"] as? String ?? "(thiếu)"
        let identifier = bundle.bundleIdentifier ?? "(thiếu)"
        let executable = bundle.executableURL.map { FileManager.default.fileExists(atPath: $0.path) } ?? false
        let valid = point == "com.apple.keyboard-service" && executable &&
                    principal.contains("KeyboardViewController")
        return """
        Trạng thái bundle: \(valid ? "HỢP LỆ VỀ CẤU TRÚC" : "CẤU TRÚC KHÔNG HỢP LỆ")
        Extension: \(identifier)
        Extension Point: \(point)
        Principal Class: \(principal)
        File thực thi: \(executable ? "Có" : "Thiếu")
        Lưu ý: Kiểm tra này KHÔNG xác nhận chữ ký hoặc việc iOS đã đăng ký bàn phím.
        """
    }
}
