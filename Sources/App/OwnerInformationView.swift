import SwiftUI
import UIKit

/// Public owner/contact information. This screen does not collect user data,
/// require full keyboard access, or make any network request on its own.
struct OwnerInformationView: View {
    private let owner = "Dương Phúc Nguyên"
    private let phone = "0788811107"
    private let email = "nguyendp.vie@gmail.com"
    private let ink = Color(red: 0.055, green: 0.075, blue: 0.14)
    private let accent = Color(red: 0.31, green: 0.82, blue: 0.95)
    private let muted = Color(red: 0.67, green: 0.73, blue: 0.85)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            hero
            contactCard
            rightsCard
            footer
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
    }

    private var hero: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.07))
                    .frame(width: 105, height: 105)
                Circle()
                    .stroke(.white.opacity(0.16), lineWidth: 1)
                    .frame(width: 92, height: 92)
                Image(systemName: "person.crop.circle.fill.badge.checkmark")
                    .font(.system(size: 57, weight: .thin))
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
            }
            Text("CHỦ SỞ HỮU & PHÁT TRIỂN")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(2.1)
                .foregroundStyle(accent)
            Text(owner)
                .font(.system(size: 27, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .minimumScaleFactor(0.8)
            Text("ViePN AI Keyboard")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
            HStack(spacing: 6) {
                Image(systemName: "shield.lefthalf.filled")
                Text("Thông tin chính thức từ nhà phát triển")
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.white.opacity(0.85))
            .padding(.horizontal, 13)
            .padding(.vertical, 8)
            .background(.white.opacity(0.12), in: Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 27)
        .padding(.horizontal, 14)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.18, green: 0.25, blue: 0.56),
                    Color(red: 0.17, green: 0.13, blue: 0.37),
                    ink
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 25)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 25)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
    }

    private var contactCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            sectionTitle("Kết nối với chủ sở hữu", symbol: "person.crop.rectangle.stack")
            Text("Hỗ trợ, trao đổi về ứng dụng và hợp tác phát triển.")
                .font(.system(size: 12))
                .foregroundStyle(muted)
            contactLink("Gọi điện", detail: phone, symbol: "phone.fill",
                        destination: "tel:\(phone)")
            contactLink("Nhắn qua Zalo", detail: phone, symbol: "message.fill",
                        destination: "https://zalo.me/\(phone)")
            contactLink("Email", detail: email, symbol: "envelope.fill",
                        destination: "mailto:\(email)")
        }
        .padding(17)
        .background(ink, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.09), lineWidth: 1)
        }
    }

    private func contactLink(_ title: String, detail: String,
                             symbol: String, destination: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: 36, height: 36)
                .background(accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 11))
                    .foregroundStyle(muted)
                Text(detail)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 4)
            Link(destination: URL(string: destination)!) {
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(ink)
                    .frame(width: 35, height: 35)
                    .background(accent, in: RoundedRectangle(cornerRadius: 10))
            }
            .accessibilityLabel("Mở \(title)")
        }
        .padding(10)
        .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 14))
    }

    private var rightsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Tuyên bố quyền sở hữu", symbol: "checkmark.shield.fill")
            Text("ViePN AI Keyboard là dự án ứng dụng do Dương Phúc Nguyên phát triển và quản lý.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
            Text("Các phần mã nguồn, thiết kế giao diện, tài liệu và nhận diện thương hiệu được sáng tạo riêng cho dự án được bảo hộ theo pháp luật hiện hành, trong phạm vi quyền hợp pháp của chủ sở hữu.")
                .font(.system(size: 12))
                .foregroundStyle(muted)
                .fixedSize(horizontal: false, vertical: true)
            Text("Không được tự ý sử dụng tên ViePN, sao chép, phân phối lại hoặc khai thác thương mại các thành phần thuộc quyền sở hữu của dự án khi chưa được cho phép, trừ các trường hợp pháp luật hoặc giấy phép áp dụng cho phép.")
                .font(.system(size: 12))
                .foregroundStyle(muted)
                .fixedSize(horizontal: false, vertical: true)
            Text("Các thư viện, API, nhãn hiệu và nội dung của bên thứ ba vẫn thuộc quyền của chủ thể tương ứng và tuân theo giấy phép, điều khoản sử dụng riêng. Thông báo này không thay thế giấy phép nguồn mở hoặc văn bản đăng ký bảo hộ.")
                .font(.system(size: 11))
                .foregroundStyle(muted.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
            Divider().overlay(.white.opacity(0.10))
            HStack(spacing: 8) {
                Image(systemName: "c.circle")
                Text("\(Calendar.current.component(.year, from: Date())) Dương Phúc Nguyên. Bảo lưu các quyền hợp pháp.")
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(accent)
        }
        .padding(17)
        .background(ink, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.09), lineWidth: 1)
        }
    }

    private func sectionTitle(_ name: String, symbol: String) -> some View {
        HStack(spacing: 9) {
            Image(systemName: symbol)
                .foregroundStyle(accent)
            Text(name)
                .foregroundStyle(.white)
        }
        .font(.system(size: 16, weight: .bold))
    }

    private var footer: some View {
        VStack(spacing: 5) {
            Text("ViePN  •  BUILD WITH PURPOSE")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(2.2)
            Text("Thiết kế để giao tiếp nhanh hơn, thông minh hơn.")
                .font(.system(size: 11))
        }
        .foregroundStyle(muted)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }
}
