import SwiftUI
import UIKit

/// Compact native settings screen for the ViePN AI Keyboard host application.
/// This view intentionally has no NavigationStack or large navigation title:
/// the first card starts directly below the iPhone safe area.
struct ContentView: View {
    @State private var provider = KeyboardSettings.provider
    @State private var selectedPage = "couple"
    @State private var showCouplePrivacy = false
    @State private var geminiAPIKey = KeyboardSettings.geminiAPIKey
    @State private var geminiModel = KeyboardSettings.geminiModel
    @State private var openAIAPIKey = KeyboardSettings.openAIAPIKey
    @State private var openAIModel = KeyboardSettings.openAIModel
    @State private var showGeminiKey = false
    @State private var showOpenAIKey = false
    @State private var cloudEnabled = KeyboardSettings.allowCloudAI
    @State private var telexEnabled = KeyboardSettings.telexEnabled
    @State private var emojiEnabled = KeyboardSettings.emojiEnabled
    @State private var coupleEnabled = KeyboardSettings.coupleEnabled
    @State private var coupleStage = KeyboardSettings.coupleStage
    @State private var coupleStyle = KeyboardSettings.coupleStyle
    @State private var coupleAddress = KeyboardSettings.coupleAddress
    @State private var typingMode = KeyboardSettings.typingMode
    @State private var keyboardTheme = KeyboardSettings.theme
    @State private var hapticEnabled = KeyboardSettings.hapticEnabled
    @State private var autoCapitalize = KeyboardSettings.autoCapitalize
    @State private var preferredTone = KeyboardSettings.preferredTone
    @State private var preferredLength = KeyboardSettings.preferredLength
    @State private var fallbackModel = KeyboardSettings.fallbackModel
    @State private var translationLanguage = KeyboardSettings.translationLanguage
    @State private var abbreviations = KeyboardSettings.replacementDictionary
    @State private var shortcut = ""
    @State private var expansion = ""
    @State private var favorites = KeyboardSettings.favoriteReplies
    @State private var availableModels: [GeminiModelOption] = []
    @State private var loadingModels = false
    @State private var testingAPI = false
    @State private var testingMessage = false
    @State private var apiFeedback = ""
    @State private var demoFeedback = ""
    @State private var demoMessage = "Hôm nay của bạn thế nào?"
    @State private var suggestions: [ReplySuggestion] = []
    @State private var phrases = KeyboardSettings.savedPhrases
    @State private var newPhrase = ""
    @State private var showGuide = false
    @State private var showDiagnosis = false
    @State private var showQuickReplies = false
    @State private var showTest = false
    @State private var keyboardDiagnosis = "Chưa kiểm tra cấu trúc Keyboard Extension."

    private let background = Color(red: 0.045, green: 0.060, blue: 0.105)
    private let cardColor = Color(red: 0.105, green: 0.128, blue: 0.195)
    private let violet = Color(red: 0.46, green: 0.43, blue: 1.0)
    private let cyan = Color(red: 0.28, green: 0.82, blue: 0.97)
    private let muted = Color(red: 0.66, green: 0.71, blue: 0.82)

    // Full-height dashboard. The background bleeds under both iOS safe areas,
    // while interactive controls remain inside the safe area.
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [background, Color(red: 0.085, green: 0.095, blue: 0.16), background],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                compactHeader
                    .padding(.horizontal, 17)
                    .padding(.top, 5)
                    .padding(.bottom, 8)

                Rectangle()
                    .fill(.white.opacity(0.08))
                    .frame(height: 1)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 12) {
                        if selectedPage == "couple" {
                            coupleStudio
                            testArea
                            savedReplies
                        } else if selectedPage == "ai" {
                            aiConfiguration
                        } else if selectedPage == "keyboard" {
                            personalization
                        } else {
                            activationGuide
                            keyboardDiagnostics
                            privacyInfo
                        }
                    }
                    .frame(maxWidth: 600)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 13)
                    .padding(.top, 12)
                    .padding(.bottom, 12)
                }
                .scrollDismissesKeyboard(.interactively)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                bottomNavigation
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .preferredColorScheme(.dark)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            favorites = KeyboardSettings.favoriteReplies
            phrases = KeyboardSettings.savedPhrases
            coupleEnabled = KeyboardSettings.coupleEnabled
            coupleStage = KeyboardSettings.coupleStage
            coupleStyle = KeyboardSettings.coupleStyle
            coupleAddress = KeyboardSettings.coupleAddress
        }
    }

    private var compactHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: "keyboard.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(
                    LinearGradient(colors: [cyan, violet], startPoint: .topLeading,
                                   endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 11)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text("ViePN AI Keyboard")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text("AI · Couple · Tiếng Việt")
                    .font(.system(size: 11))
                    .foregroundStyle(muted)
            }
            Spacer(minLength: 0)
            Text(provider == "gemini" ? "Gemini" : "OpenAI")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(cyan)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(cyan.opacity(0.1), in: Capsule())
        }
    }

    private var bottomNavigation: some View {
        HStack(spacing: 4) {
            tabItem("Couple", symbol: "heart.fill", page: "couple")
            tabItem("AI & API", symbol: "sparkles", page: "ai")
            tabItem("Bàn phím", symbol: "keyboard", page: "keyboard")
            tabItem("Công cụ", symbol: "square.grid.2x2", page: "tools")
        }
        .padding(.horizontal, 12)
        .padding(.top, 9)
        .padding(.bottom, 4)
        .background {
            Color(red: 0.09, green: 0.11, blue: 0.18)
                .ignoresSafeArea(edges: .bottom)
        }
        .overlay(alignment: .top) {
            Rectangle().fill(.white.opacity(0.08)).frame(height: 1)
        }
    }

    private func tabItem(_ title: String, symbol: String, page: String) -> some View {
        let active = selectedPage == page
        return Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                selectedPage = page
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.system(size: 17, weight: active ? .semibold : .regular))
                Text(title)
                    .font(.system(size: 10, weight: active ? .bold : .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
            }
            .foregroundStyle(active ? cyan : muted)
            .frame(maxWidth: .infinity)
            .frame(height: 45)
            .background(active ? cyan.opacity(0.10) : .clear,
                        in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(active ? [.isSelected] : [])
    }

    private func card<Content: View>(
        title: String, subtitle: String, icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 11) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(cyan)
                    .frame(width: 38, height: 38)
                    .background(cyan.opacity(0.12), in: RoundedRectangle(cornerRadius: 11))
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardColor, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
    }

    private func smallLabel(_ label: String) -> some View {
        Text(label)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(muted)
    }

    private func keyField(_ title: String, text: Binding<String>, revealed: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            smallLabel(title)
            HStack(spacing: 8) {
                Group {
                    if revealed.wrappedValue {
                        TextField("Nhập API Key", text: text)
                    } else {
                        SecureField("Nhập API Key", text: text)
                    }
                }
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.system(size: 14))
                .foregroundStyle(.white)
                Button {
                    revealed.wrappedValue.toggle()
                } label: {
                    Image(systemName: revealed.wrappedValue ? "eye.slash" : "eye")
                        .foregroundStyle(muted)
                        .frame(width: 30, height: 32)
                }
                .accessibilityLabel(revealed.wrappedValue ? "Ẩn API Key" : "Hiện API Key")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.white.opacity(0.065), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func modelField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            smallLabel(title)
            TextField("Nhập tên model", text: text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.system(size: 14))
                .foregroundStyle(.white)
                .padding(12)
                .background(Color.white.opacity(0.065), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func actionButton(
        _ label: String, symbol: String, prominent: Bool = false, disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: symbol)
                Text(label)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .font(.system(size: 13, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundStyle(prominent ? Color.white : cyan)
            .background(
                prominent ? violet : cyan.opacity(0.11),
                in: RoundedRectangle(cornerRadius: 12)
            )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.46 : 1.0)
    }

    private var coupleStudio: some View {
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

    private func coupleChoice(
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

    private func coupleSample(for style: String) -> String {
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

    private var aiConfiguration: some View {
        card(title: "AI & API", subtitle: "Chọn nhà cung cấp và kết nối model", icon: "sparkles") {
            VStack(alignment: .leading, spacing: 13) {
                Picker("Nhà cung cấp AI", selection: $provider) {
                    Text("Google Gemini").tag("gemini")
                    Text("OpenAI").tag("openai")
                }
                .pickerStyle(.segmented)
                .onChange(of: provider) { newValue in
                    KeyboardSettings.provider = newValue
                    apiFeedback = ""
                    suggestions = []
                }

                Toggle(isOn: $cloudEnabled) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Cho phép AI online")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Chỉ gửi nội dung khi bạn chủ động yêu cầu")
                            .font(.system(size: 11))
                            .foregroundStyle(muted)
                    }
                }
                .tint(violet)
                .onChange(of: cloudEnabled) { KeyboardSettings.allowCloudAI = $0 }

                if provider == "gemini" {
                    keyField("Gemini API Key", text: $geminiAPIKey, revealed: $showGeminiKey)
                        .onChange(of: geminiAPIKey) { KeyboardSettings.geminiAPIKey = $0 }
                    modelField("Model Gemini", text: $geminiModel)
                        .onChange(of: geminiModel) { KeyboardSettings.geminiModel = $0 }
                    modelField("Model dự phòng (429/503)", text: $fallbackModel)
                        .onChange(of: fallbackModel) { KeyboardSettings.fallbackModel = $0 }

                    if !availableModels.isEmpty {
                        Picker("Model được Google cung cấp", selection: $geminiModel) {
                            if !availableModels.contains(where: { $0.id == geminiModel }) {
                                Text("Model đang nhập: \(geminiModel)").tag(geminiModel)
                            }
                            ForEach(availableModels) { item in
                                Text(item.id).tag(item.id)
                            }
                        }
                        .tint(cyan)
                        .onChange(of: geminiModel) { KeyboardSettings.geminiModel = $0 }
                    }

                    HStack(spacing: 9) {
                        actionButton(loadingModels ? "Đang tải…" : "Lấy model", symbol: "arrow.clockwise",
                                     disabled: loadingModels || geminiAPIKey.isEmpty) {
                            fetchModels()
                        }
                        actionButton(testingAPI ? "Đang thử…" : "Kiểm tra API", symbol: "checkmark.circle",
                                     prominent: true,
                                     disabled: testingAPI || !cloudEnabled || geminiAPIKey.isEmpty) {
                            testConnection()
                        }
                    }
                } else {
                    keyField("OpenAI API Key", text: $openAIAPIKey, revealed: $showOpenAIKey)
                        .onChange(of: openAIAPIKey) { KeyboardSettings.openAIAPIKey = $0 }
                    modelField("Model OpenAI", text: $openAIModel)
                        .onChange(of: openAIModel) { KeyboardSettings.openAIModel = $0 }

                    actionButton(testingAPI ? "Đang thử kết nối…" : "Kiểm tra OpenAI API",
                                 symbol: "checkmark.circle", prominent: true,
                                 disabled: testingAPI || !cloudEnabled || openAIAPIKey.isEmpty) {
                        testConnection()
                    }
                }

                if !apiFeedback.isEmpty {
                    Text(apiFeedback)
                        .font(.system(size: 12))
                        .foregroundStyle(apiFeedback.hasPrefix("✓") ? Color.mint : Color.orange)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack {
                    Label("Khóa lưu trong App Group, chưa mã hóa bằng Keychain",
                          systemImage: "lock.shield")
                        .font(.system(size: 11))
                        .foregroundStyle(muted)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Button("Xóa khóa", role: .destructive) {
                        if provider == "gemini" {
                            geminiAPIKey = ""
                            KeyboardSettings.geminiAPIKey = ""
                        } else {
                            openAIAPIKey = ""
                            KeyboardSettings.openAIAPIKey = ""
                        }
                        apiFeedback = "Đã xóa API Key của nhà cung cấp hiện tại."
                    }
                    .font(.system(size: 12))
                }
            }
        }
    }

    private func themeSampleColor(_ id: String) -> Color {
        switch id {
        case "midnight": return Color(red: 0.09, green: 0.11, blue: 0.19)
        case "ocean": return Color(red: 0.73, green: 0.87, blue: 0.94)
        case "rose": return Color(red: 0.95, green: 0.84, blue: 0.89)
        case "lavender": return Color(red: 0.83, green: 0.80, blue: 0.96)
        case "mint": return Color(red: 0.77, green: 0.92, blue: 0.86)
        case "sunset": return Color(red: 0.94, green: 0.78, blue: 0.72)
        case "graphite": return Color(red: 0.14, green: 0.15, blue: 0.17)
        case "sakura": return Color(red: 0.98, green: 0.88, blue: 0.92)
        case "forest": return Color(red: 0.15, green: 0.25, blue: 0.22)
        case "sand": return Color(red: 0.92, green: 0.88, blue: 0.79)
        case "aurora": return Color(red: 0.08, green: 0.20, blue: 0.26)
        default: return cardColor
        }
    }

    private func themeDisplayName(_ id: String) -> String {
        id.prefix(1).uppercased() + id.dropFirst()
    }

    private var personalization: some View {
        card(title: "Cá nhân hóa", subtitle: "Bàn phím tiếng Việt và câu trả lời tự nhiên",
             icon: "slider.horizontal.3") {
            VStack(spacing: 13) {
                Toggle(isOn: $telexEnabled) {
                    Label("Gõ tiếng Việt Telex", systemImage: "character.cursor.ibeam")
                        .font(.system(size: 14, weight: .medium))
                }
                .tint(violet)
                .onChange(of: telexEnabled) { KeyboardSettings.telexEnabled = $0 }

                Rectangle().fill(.white.opacity(0.08)).frame(height: 1)

                Toggle(isOn: $emojiEnabled) {
                    Label("Emoji thông minh theo ngữ cảnh", systemImage: "face.smiling")
                        .font(.system(size: 14, weight: .medium))
                }
                .tint(violet)
                .onChange(of: emojiEnabled) { KeyboardSettings.emojiEnabled = $0 }

                Picker("Kiểu gõ", selection: $typingMode) {
                    Text("Telex").tag("telex")
                    Text("VNI").tag("vni")
                    Text("Không dấu").tag("off")
                }
                .onChange(of: typingMode) {
                    KeyboardSettings.typingMode = $0
                    telexEnabled = $0 == "telex"
                    KeyboardSettings.telexEnabled = telexEnabled
                }
                Picker("Chủ đề bàn phím", selection: $keyboardTheme) {
                    Text("Theo hệ thống").tag("system")
                    Text("Midnight").tag("midnight")
                    Text("Ocean").tag("ocean")
                    Text("Rose").tag("rose")
                    Text("Lavender").tag("lavender")
                    Text("Mint").tag("mint")
                    Text("Sunset").tag("sunset")
                    Text("Graphite").tag("graphite")
                    Text("Sakura").tag("sakura")
                    Text("Forest").tag("forest")
                    Text("Sand").tag("sand")
                    Text("Aurora").tag("aurora")
                }
                .onChange(of: keyboardTheme) { KeyboardSettings.theme = $0 }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(["midnight", "ocean", "rose", "lavender", "mint", "sunset",
                                 "graphite", "sakura", "forest", "sand", "aurora"], id: \.self) { id in
                            Button {
                                keyboardTheme = id
                                KeyboardSettings.theme = id
                            } label: {
                                VStack(spacing: 5) {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(themeSampleColor(id))
                                        .frame(width: 62, height: 40)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(keyboardTheme == id ? cyan : Color.white.opacity(0.25),
                                                        lineWidth: keyboardTheme == id ? 3 : 1)
                                        )
                                    Text(themeDisplayName(id))
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(keyboardTheme == id ? cyan : muted)
                                        .lineLimit(1)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                Toggle("Rung nhẹ khi gõ", isOn: $hapticEnabled)
                    .tint(violet)
                    .onChange(of: hapticEnabled) { KeyboardSettings.hapticEnabled = $0 }
                Toggle("Viết hoa đầu câu", isOn: $autoCapitalize)
                    .tint(violet)
                    .onChange(of: autoCapitalize) { KeyboardSettings.autoCapitalize = $0 }
                Picker("Giọng điệu AI", selection: $preferredTone) {
                    ForEach(["Tự nhiên", "Lịch sự", "Ngọt ngào", "Hài hước", "Chuyên nghiệp"], id: \.self) {
                        Text($0)
                    }
                }
                .onChange(of: preferredTone) { KeyboardSettings.preferredTone = $0 }
                Picker("Độ dài câu trả lời", selection: $preferredLength) {
                    ForEach(["Ngắn", "Vừa", "Chi tiết"], id: \.self) { Text($0) }
                }
                .onChange(of: preferredLength) { KeyboardSettings.preferredLength = $0 }
                Picker("Ngôn ngữ dịch", selection: $translationLanguage) {
                    ForEach(["English", "Chinese (Simplified)", "Japanese", "Korean", "French"], id: \.self) {
                        Text($0)
                    }
                }
                .onChange(of: translationLanguage) { KeyboardSettings.translationLanguage = $0 }
                Text("Từ viết tắt cá nhân")
                    .font(.system(size: 13, weight: .semibold))
                HStack(spacing: 6) {
                    TextField("Viết tắt", text: $shortcut)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Thay bằng", text: $expansion)
                    Button {
                        let key = shortcut.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                        let value = expansion.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !key.isEmpty, key.count <= 20, !value.isEmpty, value.count <= 80 else { return }
                        abbreviations[key] = value
                        KeyboardSettings.replacementDictionary = abbreviations
                        shortcut = ""
                        expansion = ""
                    } label: {
                        Image(systemName: "plus.circle.fill").foregroundStyle(cyan)
                    }
                    .accessibilityLabel("Thêm từ viết tắt")
                }
                .font(.system(size: 12))
                .padding(8)
                .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 10))
                ForEach(abbreviations.keys.sorted(), id: \.self) { key in
                    HStack {
                        Text(key + " → " + (abbreviations[key] ?? ""))
                            .font(.system(size: 12))
                        Spacer()
                        Button(role: .destructive) {
                            abbreviations.removeValue(forKey: key)
                            KeyboardSettings.replacementDictionary = abbreviations
                        } label: {
                            Image(systemName: "minus.circle").foregroundStyle(.red)
                        }
                        .accessibilityLabel("Xóa từ viết tắt")
                    }
                }
                Text("Telex/VNI, 4 chủ đề, rung phím, gợi ý AI và từ viết tắt cá nhân.")


                    .font(.system(size: 11))
                    .foregroundStyle(muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var testArea: some View {
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

    private var savedReplies: some View {
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

    private var activationGuide: some View {
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

    private func guideStep(_ number: Int, _ description: String) -> some View {
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

    private var keyboardDiagnostics: some View {
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

    private var privacyInfo: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "hand.raised.fill")
                .foregroundStyle(cyan)
            Text("Không tự đọc cuộc hội thoại. Clipboard chỉ được truy cập khi bạn chủ động bấm Dán; nội dung được gửi tới dịch vụ AI khi bạn chọn AI Online. API Key được lưu trong App Group, chưa bảo vệ bằng Keychain.")
                .font(.system(size: 11))
                .foregroundStyle(muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    private func fetchModels() {
        guard !loadingModels else { return }
        loadingModels = true
        apiFeedback = ""
        Task {
            do {
                let models = try await GeminiModelCatalog.fetch(apiKey: geminiAPIKey)
                availableModels = models
                if models.isEmpty {
                    apiFeedback = "Danh sách không có model hỗ trợ generateContent cho API Key này."
                } else {
                    if !models.contains(where: { $0.id == geminiModel }), let first = models.first {
                        geminiModel = first.id
                        KeyboardSettings.geminiModel = first.id
                    }
                    apiFeedback = "✓ Đã tải \(models.count) model từ Google."
                }
            } catch {
                apiFeedback = error.localizedDescription
            }
            loadingModels = false
        }
    }

    private func testConnection() {
        guard !testingAPI else { return }
        testingAPI = true
        apiFeedback = ""
        Task {
            do {
                let items = try await AIService.reply(to: "Xin chào, bạn có khỏe không?")
                apiFeedback = "✓ API hoạt động, nhận \(items.count) gợi ý."
            } catch {
                apiFeedback = error.localizedDescription
            }
            testingAPI = false
        }
    }

    private func testMessage() {
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

    private func diagnoseKeyboard() -> String {
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
