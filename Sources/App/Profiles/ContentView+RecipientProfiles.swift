import SwiftUI
import UIKit
import AudioToolbox
import PhotosUI

extension ContentView {
    @MainActor
    func recognizePersonaScreenshot(_ picker: PhotosPickerItem) async {
        screenshotReferenceStatus = "Đang kiểm tra hướng ảnh và đọc tiêu đề trên iPhone..."
        pendingHeaderPNG = nil
        scannedTitleOptions = []
        headerDiagnosticPreview = nil
        manualScreenshotData = nil
        do {
            guard let data = try await picker.loadTransferable(type: Data.self) else {
                screenshotReferenceStatus = "Không tải được ảnh từ Thư viện."
                return
            }
            manualScreenshotData = data
            let scan = try await ChatScreenshotReference.scan(
                data, preferredName: personaName)
            scannedTitleOptions = scan.candidates
            headerDiagnosticPreview = scan.headerPreviewPNG
            let wanted = PersonaStore.normalizedName(personaName)
            if let matched = scan.candidates.first(where: {
                !wanted.isEmpty && $0.midY >= 0.66
                    && PersonaStore.normalizedScreenshotTitle($0.title) == wanted
            }) {
                pendingHeaderTitle = matched.title
                pendingHeaderPNG = matched.png
                screenshotReferenceStatus = "Đã khớp tên hồ sơ với tiêu đề trong ảnh."
            } else if !scan.candidates.isEmpty {
                // Do not silently enroll a navigation button or chat bubble
                // as a recipient name. Show alternatives for user selection.
                screenshotReferenceStatus = "Đã đọc "
                    + String(scan.totalOCRLines)
                    + " vùng chữ. Chọn đúng tên trong các dòng bên dưới."
            } else {
                screenshotReferenceStatus = scan.totalOCRLines == 0
                    ? "OCR chưa đọc được chữ nào. Kiểm tra ảnh có rõ nét và đúng hướng."
                    : "Có " + String(scan.totalOCRLines)
                        + " vùng chữ, nhưng chưa tìm được tên phù hợp. Xem ảnh tiêu đề rồi chọn ảnh rõ hơn."
            }
        } catch {
            screenshotReferenceStatus = "Không đọc được ảnh: " + error.localizedDescription
        }
    }

    var personaSettingsCard: some View {
        keyboardPanel("Hồ sơ người nhận (AI Persona)", icon: "person.crop.rectangle.stack") {
            VStack(alignment: .leading, spacing: 11) {
                Text("Tự chọn đúng hồ sơ khi nội dung bạn Dán có dòng 'Người gửi: Tên'. iOS không cho bàn phím đọc tên cuộc trò chuyện từ Zalo, Messenger hoặc Facebook.")
                    .font(.system(size: 11)).foregroundStyle(muted)
                    .fixedSize(horizontal: false, vertical: true)
                Toggle("Tự khớp tên khi Dán hội thoại", isOn: $autoMatchPersona)
                    .font(.system(size: 12))
                    .tint(violet)
                    .onChange(of: autoMatchPersona) { PersonaStore.automaticNameMatch = $0 }
                HStack(spacing: 7) {
                    Text("Đang dùng")
                        .font(.system(size: 12, weight: .medium))
                    Spacer()
                    Menu {
                        Button("Tự nhận diện") {
                            PersonaStore.clearSelection()
                            activePersonaID = ""
                            recipientMode = "auto"
                        }
                        ForEach(personas) { item in
                            Button(item.name) {
                                PersonaStore.select(item.id)
                                activePersonaID = item.id
                            }
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Text(personas.first(where: { $0.id == activePersonaID })?.name ?? "Tự nhận diện")
                                .foregroundStyle(cyan)
                            Image(systemName: "chevron.down").foregroundStyle(muted)
                        }
                        .font(.system(size: 12, weight: .semibold))
                    }
                }
                keyboardDivider()
                HStack(spacing: 8) {
                    TextField("Tên hồ sơ trùng danh bạ/Zalo/Facebook", text: $personaName)
                        .font(.system(size: 13))
                        .textFieldStyle(.roundedBorder)
                    Button {
                        showContactNamePicker = true
                    } label: {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .font(.system(size: 19))
                    }
                    .accessibilityLabel("Chọn tên từ danh bạ iPhone")
                }
                .sheet(isPresented: $showContactNamePicker) {
                    ContactNamePicker(
                        onChoose: { name in
                            personaName = name
                            showContactNamePicker = false
                        },
                        onCancel: { showContactNamePicker = false }
                    )
                }
                PhotosPicker(selection: $personaScreenshotPicker, matching: .images) {
                    Label("Kèm ảnh chụp màn hình Zalo / Messenger",
                          systemImage: "photo.badge.plus")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.bordered)
                .onChange(of: personaScreenshotPicker) { image in
                    guard let image else { return }
                    Task { await recognizePersonaScreenshot(image) }
                }
                if let diagnostic = headerDiagnosticPreview,
                   let image = UIImage(data: diagnostic) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Vùng phía trên ảnh mà ViePN đã kiểm tra")
                            .font(.system(size: 11, weight: .semibold))
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 320)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        Text("Đây chỉ là ảnh xem trước, không được lưu kèm hồ sơ.")
                            .font(.system(size: 10)).foregroundStyle(muted)
                    }
                }
                if !scannedTitleOptions.isEmpty {
                    Text("Chạm đúng dòng tên người đang nhắn (không chọn nội dung tin nhắn):")
                        .font(.system(size: 11)).foregroundStyle(muted)
                    ForEach(Array(scannedTitleOptions.enumerated()), id: \.offset) {
                        index, result in
                        Button {
                            pendingHeaderTitle = result.title
                            pendingHeaderPNG = result.png
                            screenshotReferenceStatus = "Đã chọn: " + result.title
                                + ". Kiểm tra lại phần ảnh tên bên dưới trước khi lưu."
                        } label: {
                            HStack {
                                Text(result.title).lineLimit(2)
                                Spacer()
                                if let preview = UIImage(data: result.png) {
                                    Image(uiImage: preview).resizable()
                                        .scaledToFit().frame(height: 22)
                                }
                                if pendingHeaderTitle == result.title {
                                    Image(systemName: "checkmark.circle.fill")
                                }
                            }
                            .font(.system(size: 12))
                        }
                        .buttonStyle(.bordered)
                    }
                }
                if let source = manualScreenshotData {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("Không thấy tên? Chọn thủ công vị trí dòng tên trên ảnh:")
                            .font(.system(size: 11, weight: .semibold))
                        HStack {
                            Text("Vị trí từ mép trên")
                                .font(.system(size: 10)).foregroundStyle(muted)
                            Slider(value: $manualHeaderTop, in: 0.035...0.34)
                                .tint(violet)
                            Text(String(Int(manualHeaderTop * 100)) + "%")
                                .font(.system(size: 10)).foregroundStyle(cyan)
                        }
                        if let cropped = ChatScreenshotReference.manualHeaderCrop(
                            source, topFraction: manualHeaderTop),
                           let preview = UIImage(data: cropped) {
                            Image(uiImage: preview)
                                .resizable().scaledToFit()
                                .frame(maxWidth: 320)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            Button {
                                pendingHeaderPNG = cropped
                                let entered = personaName.trimmingCharacters(
                                    in: .whitespacesAndNewlines)
                                pendingHeaderTitle = !entered.isEmpty ? entered :
                                    (personas.first(where: { $0.id == activePersonaID })?.name ?? "")
                                screenshotReferenceStatus =
                                    "Đã chọn vùng ảnh thủ công. Kiểm tra tên và vùng cắt trước khi lưu."
                            } label: {
                                Label("Dùng vùng ảnh này làm mẫu", systemImage: "crop")
                            }
                            .buttonStyle(.bordered)
                            .disabled(personaName.trimmingCharacters(
                                in: .whitespacesAndNewlines).isEmpty
                                && !personas.contains(where: { $0.id == activePersonaID }))
                            Text("Chỉ chọn khi vùng cắt chứa tên người nhận, không chứa tin nhắn. Tên sử dụng là tên hồ sơ bạn nhập.")
                                .font(.system(size: 10)).foregroundStyle(muted)
                        }
                    }
                }
                if let png = pendingHeaderPNG, let preview = UIImage(data: png) {
                    VStack(alignment: .leading, spacing: 6) {
                        Image(uiImage: preview)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        TextField("Tên trên ảnh (sửa lỗi OCR nếu cần)", text: $pendingHeaderTitle)
                            .font(.system(size: 12))
                            .textFieldStyle(.roundedBorder)
                        Text("Xác nhận vùng chữ cắt đúng tên người trước khi lưu. Sửa tên không thay đổi ảnh tham chiếu.")
                            .font(.system(size: 10)).foregroundStyle(muted)
                        Text("ViePN chỉ lưu vùng tiêu đề của ảnh, không lưu nội dung tin nhắn.")
                            .font(.system(size: 10)).foregroundStyle(muted)
                        if !activePersonaID.isEmpty {
                            Button {
                                if ChatScreenshotReference.save(
                                    personaID: activePersonaID,
                                    title: pendingHeaderTitle, headerPNG: png) {
                                    screenshotReferenceStatus =
                                        "Đã gắn ảnh mẫu với hồ sơ đang chọn."
                                    pendingHeaderPNG = nil
                                } else {
                                    screenshotReferenceStatus =
                                        "Không lưu được ảnh mẫu; kiểm tra App Group."
                                }
                            } label: {
                                Label("Gắn ảnh cho hồ sơ đang chọn",
                                      systemImage: "person.crop.circle.badge.checkmark")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                if !screenshotReferenceStatus.isEmpty {
                    Text(screenshotReferenceStatus)
                        .font(.system(size: 11)).foregroundStyle(cyan)
                }
                keyboardMenuRow("Vai người nhận", symbol: "person",
                                value: $personaRole,
                                options: ReplyRecipient.allCases.filter { $0 != .automatic }
                                    .map { ($0.rawValue, $0.title) })
                HStack(spacing: 8) {
                    TextField("Tự xưng: cháu", text: $personaSelfAddress)
                    TextField("Giọng: Lịch sự", text: $personaTone)
                }
                .font(.system(size: 12))
                .textFieldStyle(.roundedBorder)
                Button {
                    let previousID = PersonaStore.activeID
                    PersonaStore.add(name: personaName, role: personaRole,
                                     selfAddress: personaSelfAddress, tone: personaTone)
                    personas = PersonaStore.all
                    activePersonaID = PersonaStore.activeID
                    if activePersonaID != previousID,
                       let png = pendingHeaderPNG {
                        screenshotReferenceStatus = ChatScreenshotReference.save(
                            personaID: activePersonaID,
                            title: pendingHeaderTitle, headerPNG: png)
                            ? "Đã tạo hồ sơ kèm ảnh tiêu đề tham chiếu."
                            : "Đã tạo hồ sơ, nhưng chưa lưu được ảnh mẫu."
                        if screenshotReferenceStatus.hasPrefix("Đã tạo hồ sơ kèm") {
                            pendingHeaderPNG = nil
                        }
                    }
                    personaName = ""
                } label: {
                    Label("Thêm & chọn hồ sơ", systemImage: "plus.circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(violet)
                .disabled(personaName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                keyboardDivider()
                Text("Kiểm tra nhận diện tên trong hội thoại")
                    .font(.system(size: 12, weight: .semibold))
                TextField("Người gửi: Nhân Mod", text: $transcriptPreview)
                    .font(.system(size: 12))
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.words)
                Button {
                    if let name = PersonaStore.nameFromSharedTranscript(transcriptPreview),
                       let matched = PersonaStore.matchingProfile(named: name) {
                        PersonaStore.select(matched.id)
                        activePersonaID = matched.id
                        transcriptMatchStatus = "Đã khớp: " + matched.name
                    } else {
                        transcriptMatchStatus = "Không có tên người gửi được gắn nhãn hoặc không có hồ sơ trùng duy nhất."
                    }
                } label: {
                    Label("Thử khớp tên", systemImage: "person.crop.circle.badge.checkmark")
                        .font(.system(size: 11))
                }
                .buttonStyle(.bordered)
                if !transcriptMatchStatus.isEmpty {
                    Text(transcriptMatchStatus)
                        .font(.system(size: 11))
                        .foregroundStyle(cyan)
                        .fixedSize(horizontal: false, vertical: true)
                }
                ForEach(personas) { item in
                    HStack(spacing: 7) {
                        Image(systemName: item.id == activePersonaID
                              ? "checkmark.circle.fill" : "person.crop.circle")
                            .foregroundStyle(item.id == activePersonaID ? cyan : muted)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name).font(.system(size: 12, weight: .semibold))
                            Text((ReplyRecipient(rawValue: item.recipient)?.title ?? "") +
                                 " · " + item.selfAddress + " · " + item.tone)
                                .font(.system(size: 10)).foregroundStyle(muted)
                        }
                        Spacer()
                        Button {
                            PersonaStore.select(item.id)
                            activePersonaID = item.id
                        } label: {
                            Image(systemName: "checkmark")
                                .foregroundStyle(cyan)
                        }
                        .accessibilityLabel("Chọn hồ sơ " + item.name)
                        Button {
                            // Prevent an orphaned private transcript when a
                            // person is deleted from the profile list.
                            ConversationHistory.clear(for: item.id)
                            let withoutNotes = ConversationMemory.notes.filter {
                                $0.personaID != item.id
                            }
                            ConversationMemory.notes = withoutNotes
                            guard ConversationHistory.turns(for: item.id).isEmpty,
                                  !ConversationMemory.notes.contains(where: {
                                      $0.personaID == item.id
                                  }),
                                  ChatScreenshotReference.remove(personaID: item.id) else {
                                apiFeedback = "Không thể xóa lịch sử của hồ sơ này. Hãy mở khóa thiết bị và thử lại."
                                return
                            }
                            personas.removeAll { $0.id == item.id }
                            PersonaStore.all = personas
                            if activePersonaID == item.id {
                                PersonaStore.clearSelection()
                                activePersonaID = ""
                            }
                        } label: {
                            Image(systemName: "trash").foregroundStyle(.red.opacity(0.8))
                        }
                        .accessibilityLabel("Xóa hồ sơ " + item.name)
                    }
                }
            }
        }
    }
}
