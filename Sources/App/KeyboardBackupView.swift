import SwiftUI
import UniformTypeIdentifiers

private struct KeyboardBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws {
        guard let bytes = configuration.file.regularFileContents, bytes.count <= 16_384
        else { throw KeyboardPreferencesBackup.BackupError.invalid }
        data = bytes
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

struct KeyboardBackupView: View {
    var onRestore: () -> Void
    @State private var exportDocument: KeyboardBackupDocument?
    @State private var exporting = false
    @State private var importing = false
    @State private var pendingBackup: KeyboardPreferencesBackup?
    @State private var confirm = false
    @State private var status = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Xuất và khôi phục giao diện, bộ gõ, gợi ý và hiệu ứng. Không bao gồm khóa API, hồ sơ, tin nhắn hay từ đã học.")
                .font(.system(size: 11)).foregroundStyle(.secondary)
            HStack {
                Button {
                    do {
                        let encoder = JSONEncoder()
                        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                        exportDocument = .init(data: try encoder.encode(KeyboardPreferencesBackup.capture()))
                        exporting = true
                    } catch { status = error.localizedDescription }
                } label: { Label("Xuất JSON", systemImage: "square.and.arrow.up") }
                .buttonStyle(.borderedProminent)
                Button { importing = true } label: { Label("Nhập JSON", systemImage: "square.and.arrow.down") }
                    .buttonStyle(.bordered)
            }
            .font(.system(size: 12, weight: .medium))
            if !status.isEmpty { Text(status).font(.system(size: 11)).foregroundStyle(.secondary) }
        }
        .fileExporter(isPresented: $exporting, document: exportDocument,
                      contentType: .json, defaultFilename: "ViePN-Keyboard-Settings") { result in
            switch result {
            case .success: status = "Đã xuất cài đặt."
            case .failure(let error): status = error.localizedDescription
            }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            do {
                let url = try result.get()
                let scoped = url.startAccessingSecurityScopedResource()
                defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                let metadata = try url.resourceValues(forKeys: [.fileSizeKey])
                guard let size = metadata.fileSize, size <= 16_384 else {
                    throw KeyboardPreferencesBackup.BackupError.invalid
                }
                let data = try Data(contentsOf: url)
                guard data.count <= 16_384 else { throw KeyboardPreferencesBackup.BackupError.invalid }
                pendingBackup = try JSONDecoder().decode(KeyboardPreferencesBackup.self, from: data)
                confirm = true
            } catch { status = error.localizedDescription }
        }
        .alert("Khôi phục cài đặt?", isPresented: $confirm) {
            Button("Khôi phục", role: .destructive) {
                do {
                    guard let backup = pendingBackup else { throw KeyboardPreferencesBackup.BackupError.invalid }
                    try backup.restore()
                    onRestore()
                    status = "Đã khôi phục. Chuyển sang bàn phím khác rồi quay lại ViePN để áp dụng."
                } catch { status = error.localizedDescription }
                pendingBackup = nil
            }
            Button("Hủy", role: .cancel) { pendingBackup = nil }
        } message: { Text("Thay đổi các tùy chọn giao diện và gõ phím hiện tại. Không thay đổi dữ liệu cá nhân hay khóa API.") }
    }
}
