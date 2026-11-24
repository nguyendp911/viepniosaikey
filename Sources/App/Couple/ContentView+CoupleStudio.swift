import SwiftUI
import UIKit
import AudioToolbox
import PhotosUI

extension ContentView {
    var coupleStudio: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(red: 1, green: 0.60, blue: 0.75))
                    .frame(width: 39, height: 39)
                    .background(.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Couple Studio")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Gợi ý tình cảm, đúng ngữ cảnh")
                        .font(.system(size: 11))
                        .foregroundStyle(muted)
                }
                Spacer(minLength: 0)
                Toggle("Couple", isOn: $coupleEnabled)
                    .labelsHidden()
                    .tint(Color(red: 0.91, green: 0.35, blue: 0.63))
                    .onChange(of: coupleEnabled) {
                        KeyboardSettings.coupleEnabled = $0
                    }
            }

            if coupleEnabled {
                HStack(spacing: 8) {
                    coupleChoice(
                        title: "Mối quan hệ", value: coupleStage,
                        options: ["Mới quen", "Đang tìm hiểu", "Đang yêu", "Yêu xa", "Đã kết hôn"]
                    ) { option in
                        coupleStage = option
                        KeyboardSettings.coupleStage = option
                    }
                    coupleChoice(
                        title: "Xưng hô", value: coupleAddress,
                        options: ["anh/em", "em/anh", "mình/cậu", "tớ/cậu", "bạn/mình"]
                    ) { option in
                        coupleAddress = option
                        KeyboardSettings.coupleAddress = option
                    }
                }

                Menu {
                    ForEach(CoupleStyleCatalog.styles) { style in
                        Button {
                            coupleStyle = style.id
                            KeyboardSettings.coupleStyle = style.id
                        } label: {
                            Text(style.icon + " " + style.title)
                            if style.id == coupleStyle {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 9) {
                        Text(CoupleStyleCatalog.selected(coupleStyle).icon)
                            .font(.system(size: 19))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Phong cách hiện tại")
                                .font(.system(size: 10))
                                .foregroundStyle(muted)
                            Text(CoupleStyleCatalog.selected(coupleStyle).title)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        Spacer(minLength: 0)
                        Text("18 style")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(muted)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(muted)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(.white.opacity(0.055),
                                in: RoundedRectangle(cornerRadius: 12))
                }

                HStack {
                    Text("CHỌN NHANH")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.0)
                        .foregroundStyle(muted)
                    Spacer()
                    Text("3 câu trả lời / lượt")
                        .font(.system(size: 10))
                        .foregroundStyle(muted)
                }
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 7),
                                    GridItem(.flexible(), spacing: 7)], spacing: 7) {
                    ForEach(["sweet", "flirty", "funny", "gentle", "mature", "reconcile"],
                            id: \.self) { id in
                        let style = CoupleStyleCatalog.selected(id)
                        Button {
                            coupleStyle = id
                            KeyboardSettings.coupleStyle = id
                        } label: {
                            HStack(spacing: 6) {
                                Text(style.icon).font(.system(size: 14))
                                Text(style.title)
                                    .font(.system(size: 12, weight: .medium))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                Spacer(minLength: 0)
                                if id == coupleStyle {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                }
                            }
                            .foregroundStyle(id == coupleStyle ? Color.white : muted)
                            .padding(.horizontal, 10)
                            .frame(height: 34)
                            .background(
                                id == coupleStyle
                                    ? Color(red: 0.65, green: 0.28, blue: 0.58)
                                    : Color.white.opacity(0.06),
                                in: RoundedRectangle(cornerRadius: 10)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(id == coupleStyle
                                            ? Color.pink.opacity(0.38)
                                            : Color.white.opacity(0.06), lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack(alignment: .top, spacing: 9) {
                    Image(systemName: "text.bubble.fill")
                        .foregroundStyle(Color(red: 1, green: 0.63, blue: 0.78))
                    VStack(alignment: .leading, spacing: 3) {
                        Text("VÍ DỤ MINH HỌA")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(muted)
                        Text(coupleSample(for: coupleStyle))
                            .font(.system(size: 12))
                            .foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .padding(11)
                .background(.white.opacity(0.045),
                            in: RoundedRectangle(cornerRadius: 12))

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showCouplePrivacy.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.shield")
                        Text("Riêng tư · Không tự thu thập cuộc trò chuyện")
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        Spacer(minLength: 0)
                        Image(systemName: showCouplePrivacy ? "chevron.up" : "chevron.down")
                    }
                    .font(.system(size: 10))
                    .foregroundStyle(muted)
                }
                .buttonStyle(.plain)
                if showCouplePrivacy {
                    Text("Ứng dụng sử dụng ví dụ hội thoại giả lập để hướng dẫn AI, không tự dùng cuộc trò chuyện cá nhân để huấn luyện. Nội dung chỉ gửi đến AI khi bạn chủ động yêu cầu.")
                        .font(.system(size: 11))
                        .foregroundStyle(muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                Text("Bật để tạo các câu trả lời tình cảm theo tình huống và phong cách bạn chọn.")
                    .font(.system(size: 12))
                    .foregroundStyle(muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color(red: 0.17, green: 0.13, blue: 0.28),
                         Color(red: 0.26, green: 0.14, blue: 0.30)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.pink.opacity(0.15), lineWidth: 1)
        }
    }

    func coupleChoice(
        title: String, value: String, options: [String],
        action: @escaping (String) -> Void
    ) -> some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button {
                    action(option)
                } label: {
                    Text(option)
                    if value == option { Image(systemName: "checkmark") }
                }
            }
        } label: {
            HStack(spacing: 5) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 10))
                        .foregroundStyle(muted)
                    Text(value)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(muted)
            }
            .padding(.horizontal, 10)
            .frame(height: 49)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.065),
                        in: RoundedRectangle(cornerRadius: 11))
        }
    }

    func coupleSample(for style: String) -> String {
        switch style {
        case "sweet": return "Ngủ ngon nha, mai kể nhau nghe chuyện hôm nay nhé 💗"
        case "romantic": return "Tối nay ngắm trời, tự nhiên lại nhớ đến em 🌙"
        case "flirty": return "Hình như hôm nay anh thiếu một tin nhắn từ em đó ✨"
        case "funny": return "Mình nói chuyện chút đi, anh đang thiếu vitamin em 😄"
        case "playful": return "Đang bận nghĩ xem ai dễ thương hơn ai nè 😜"
        case "gentle": return "Em cứ nghỉ ngơi nhé, khi nào muốn kể anh nghe."
        case "caring": return "Hôm nay của em ổn không? Muốn kể anh nghe không? 🌷"
        case "mature": return "Mình cứ bình tĩnh nói rõ điều cả hai cần nhé."
        case "reconcile": return "Anh muốn hiểu em hơn, mình nói chuyện khi sẵn sàng nhé."
        case "boundaries": return "Điều đó làm em không thoải mái. Mong anh tôn trọng nhé."
        case "longdistance": return "Xa nhau chút thôi, tối mình gọi nhau nhé 🤍"
        case "minimal": return "Ừ, anh nghe em nè."
        default: return "Hôm nay em thế nào? Kể anh nghe một chút nhé."
        }
    }

    var testArea: some View {
        card(title: "Thử gợi ý", subtitle: "Kiểm tra câu trả lời trước khi mở bàn phím",
             icon: "bubble.left.and.text.bubble.right") {
            VStack(alignment: .leading, spacing: 10) {
                DisclosureGroup("Mở khu vực thử câu trả lời", isExpanded: $showTest) {
                    VStack(alignment: .leading, spacing: 11) {
                        TextEditor(text: $demoMessage)
                            .scrollContentBackground(.hidden)
                            .font(.system(size: 14))
                            .padding(8)
                            .frame(height: 95)
                            .background(Color.white.opacity(0.065),
                                        in: RoundedRectangle(cornerRadius: 12))
                        HStack(spacing: 9) {
                            actionButton("Offline", symbol: "bolt") {
                                suggestions = OfflineReplyEngine.suggest(for: demoMessage)
                                demoFeedback = ""
                            }
                            actionButton(testingMessage ? "Đang tạo…" : "AI Online",
                                         symbol: "sparkles", prominent: true,
                                         disabled: testingMessage || !cloudEnabled) {
                                testMessage()
                            }
                        }
                        ForEach(suggestions) { item in
                            Button {
                                UIPasteboard.general.string = item.text
                                demoFeedback = "✓ Đã sao chép câu trả lời, không kèm tin gốc."
                            } label: {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(item.tone)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(cyan)
                                    Text(item.text)
                                        .font(.system(size: 14))
                                        .foregroundStyle(.white)
                                        .multilineTextAlignment(.leading)
                                    Label("Chạm để sao chép", systemImage: "doc.on.doc")
                                        .font(.system(size: 11))
                                        .foregroundStyle(muted)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(Color.white.opacity(0.055),
                                            in: RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                        if !demoFeedback.isEmpty {
                            Text(demoFeedback)
                                .font(.system(size: 12))
                                .foregroundStyle(muted)
                                .textSelection(.enabled)
                        }
                    }
                    .padding(.top, 9)
                }
                .tint(cyan)
            }
        }
    }

    var savedReplies: some View {
        card(title: "Mẫu câu nhanh", subtitle: "Lưu, chèn và quản lý các câu thường dùng",
             icon: "text.bubble") {
            DisclosureGroup("Quản lý \(phrases.count) mẫu câu", isExpanded: $showQuickReplies) {
                VStack(spacing: 8) {
                    if !favorites.isEmpty {
                        Text("Câu trả lời AI đã lưu")
                            .font(.system(size: 13, weight: .semibold))
                        ForEach(Array(favorites.enumerated()), id: \.offset) { index, reply in
                            HStack {
                                Button {
                                    UIPasteboard.general.string = reply
                                } label: {
                                    Text(reply).font(.system(size: 12))
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                Button(role: .destructive) {
                                    favorites.remove(at: index)
                                    KeyboardSettings.favoriteReplies = favorites
                                } label: {
                                    Image(systemName: "trash").foregroundStyle(.red)
                                }
                            }
                            .padding(9)
                            .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    ForEach(Array(phrases.enumerated()), id: \.offset) { index, phrase in
                        HStack(spacing: 10) {
                            Text(phrase)
                                .font(.system(size: 13))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Button {
                                phrases.remove(at: index)
                                KeyboardSettings.savedPhrases = phrases
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red.opacity(0.9))
                                    .padding(8)
                            }
                            .accessibilityLabel("Xóa mẫu câu")
                        }
                        .padding(10)
                        .background(Color.white.opacity(0.055),
                                    in: RoundedRectangle(cornerRadius: 11))
                    }
                    HStack(spacing: 8) {
                        TextField("Thêm mẫu câu", text: $newPhrase)
                            .font(.system(size: 13))
                            .padding(11)
                            .background(Color.white.opacity(0.065),
                                        in: RoundedRectangle(cornerRadius: 10))
                        Button {
                            let phrase = newPhrase.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !phrase.isEmpty, phrases.count < 30 else { return }
                            phrases.append(String(phrase.prefix(500)))
                            KeyboardSettings.savedPhrases = phrases
                            newPhrase = ""
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 38, height: 38)
                                .background(violet, in: RoundedRectangle(cornerRadius: 10))
                        }
                        .disabled(newPhrase.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                  || phrases.count >= 30)
                        .accessibilityLabel("Thêm mẫu câu")
                    }
                }
                .padding(.top, 9)
            }
            .tint(cyan)
        }
    }

    func testMessage() {
        guard !testingMessage else { return }
        testingMessage = true
        demoFeedback = ""
        Task {
            do {
                suggestions = try await AIService.reply(to: demoMessage)
            } catch {
                demoFeedback = error.localizedDescription
            }
            testingMessage = false
        }
    }
}
