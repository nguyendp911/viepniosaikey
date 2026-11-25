import SwiftUI
import UIKit

/// Public owner/contact information. This screen does not collect user data,
/// require full keyboard access, or make any network request on its own.
struct OwnerInformationView: View {
    private let owner = "Dương Phúc Nguyên"
    private let phone = "0788811107"
    private let email = "nguyendp.vie@gmail.com"
    private let ink = Color(red: 0.055, green: 0.075, blue: 0.14)
    private let accent = Color(red: 0.79, green: 0.69, blue: 0.46)
    private let muted = Color(red: 0.67, green: 0.73, blue: 0.85)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            hero
            contactCard
            projectCard
            rightsCard
            footer
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
    }

    private var hero: some View {
        VStack(alignment:.leading,spacing:18) {
            HStack {
                Text("VIEPN").font(.system(size:13,weight:.heavy,design:.monospaced)).tracking(4).foregroundStyle(accent)
                Spacer()
                Text("DEVELOPER PROFILE").font(.system(size:9,weight:.semibold)).tracking(1.4).foregroundStyle(muted)
            }
            Divider().overlay(accent.opacity(0.23))
            HStack(alignment:.center,spacing:15) {
                ZStack {
                    RoundedRectangle(cornerRadius:24).fill(LinearGradient(colors:[accent.opacity(0.23),.black.opacity(0.3)],startPoint:.topLeading,endPoint:.bottomTrailing))
                    RoundedRectangle(cornerRadius:24).strokeBorder(accent.opacity(0.65),lineWidth:1)
                    Text("DPN").font(.system(size:25,weight:.semibold,design:.serif)).foregroundStyle(accent)
                }.frame(width:84,height:84).accessibilityHidden(true)
                VStack(alignment:.leading,spacing:6) {
                    Text("CHỦ SỞ HỮU & PHÁT TRIỂN").font(.system(size:9,weight:.bold)).tracking(1.1).foregroundStyle(accent)
                    Text(owner).font(.system(size:24,weight:.bold,design:.serif)).foregroundStyle(.white).minimumScaleFactor(0.7)
                    Text("ViePN AI Keyboard").font(.subheadline).foregroundStyle(muted)
                }
            }
            Text("Một không gian nhập liệu dành cho người Việt — tinh tế, thực dụng và tôn trọng quyền riêng tư.")
                .font(.system(size:13)).foregroundStyle(muted).fixedSize(horizontal:false,vertical:true)
            HStack(spacing:10) {
                Label("Nhà phát triển",systemImage:"person.crop.circle").font(.caption.weight(.semibold))
                Spacer()
                Image(systemName:"keyboard").font(.system(size:18,weight:.light))
            }.foregroundStyle(accent)
        }.padding(20)
        .background {
            ZStack {
                LinearGradient(colors:[Color(red:0.12,green:0.16,blue:0.25),ink,Color.black.opacity(0.95)],startPoint:.topLeading,endPoint:.bottomTrailing)
                Circle().strokeBorder(accent.opacity(0.10),lineWidth:1).frame(width:230,height:230).offset(x:140,y:-100)
                Circle().strokeBorder(accent.opacity(0.07),lineWidth:1).frame(width:280,height:280).offset(x:140,y:-100)
            }.clipShape(RoundedRectangle(cornerRadius:24))
        }.overlay {RoundedRectangle(cornerRadius:24).strokeBorder(accent.opacity(0.28),lineWidth:1)}
    }

    private var projectCard: some View {
        VStack(alignment:.leading,spacing:12) {
            sectionTitle("Thông tin dự án",symbol:"info.circle")
            let version=Bundle.main.object(forInfoDictionaryKey:"CFBundleShortVersionString") as? String ?? "—"
            let build=Bundle.main.object(forInfoDictionaryKey:"CFBundleVersion") as? String ?? "—"
            HStack {
                VStack(alignment:.leading,spacing:4) {
                    Text("PHIÊN BẢN").font(.system(size:10,weight:.semibold)).tracking(1).foregroundStyle(muted)
                    Text(version).font(.system(size:22,weight:.semibold,design:.monospaced)).foregroundStyle(.white)
                }
                Spacer()
                VStack(alignment:.trailing,spacing:4) {
                    Text("BUILD").font(.system(size:10,weight:.semibold)).tracking(1).foregroundStyle(muted)
                    Text(build).font(.system(size:22,weight:.semibold,design:.monospaced)).foregroundStyle(.white)
                }
            }.padding(12).background(.white.opacity(0.045),in:RoundedRectangle(cornerRadius:12))
            contactLink("Mã nguồn GitHub",detail:"nguyendp911/viepniosaikey",symbol:"chevron.left.forwardslash.chevron.right",destination:"https://github.com/nguyendp911/viepniosaikey")
        }.padding(17).background(ink,in:RoundedRectangle(cornerRadius:20))
            .overlay {RoundedRectangle(cornerRadius:20).strokeBorder(.white.opacity(0.09))}
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
            Button {
                UIPasteboard.general.string = detail
            } label: {
                Image(systemName:"doc.on.doc").font(.system(size:13,weight:.medium))
                    .foregroundStyle(accent).frame(width:34,height:35)
            }.buttonStyle(.plain).accessibilityLabel("Sao chép "+title)
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
