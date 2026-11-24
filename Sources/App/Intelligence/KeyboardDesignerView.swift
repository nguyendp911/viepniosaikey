import SwiftUI
import PhotosUI
import UIKit
import ImageIO

struct KeyboardDesignerView: View {
    @State private var design = KeyboardDesign.current
    @State private var image = KeyboardDesign.wallpaper()
    @State private var picker: PhotosPickerItem?
    @State private var status = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Thiết kế chủ đề riêng. Ảnh chỉ lưu trong App Group, không gửi AI.").font(.caption).foregroundStyle(.secondary)
            VStack(spacing: 5) {
                ForEach(["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"], id: \.self) { row in
                    HStack(spacing: 3) {
                        ForEach(Array(row), id: \.self) { char in
                            Text(String(char)).font(Font(KeyboardDesign.font(14, design: design.font)))
                                .foregroundStyle(Color(uiColor: KeyboardDesign.color(design.text)))
                                .frame(maxWidth: .infinity, minHeight: 31)
                                .background(Color(uiColor: KeyboardDesign.color(design.key)).opacity(design.opacity), in: RoundedRectangle(cornerRadius: design.radius))
                        }
                    }
                }
            }.padding(9).background {
                ZStack {
                    Color(uiColor: KeyboardDesign.color(design.canvas))
                    if let image { Image(uiImage: image).resizable().scaledToFill().clipped() }
                }
            }.clipShape(RoundedRectangle(cornerRadius: 12))
            Group {
                TextField("Màu nền HEX", text: $design.canvas).textFieldStyle(.roundedBorder)
                TextField("Màu phím HEX", text: $design.key).textFieldStyle(.roundedBorder)
                TextField("Màu chữ HEX", text: $design.text).textFieldStyle(.roundedBorder)
                TextField("Màu phím phụ HEX", text: $design.modifier).textFieldStyle(.roundedBorder)
            }.textInputAutocapitalization(.characters).autocorrectionDisabled()
            Text("Độ đục phím: \(Int(design.opacity*100))%")
            Slider(value: $design.opacity, in: 0.45...1)
            Text("Bo góc: \(Int(design.radius))")
            Slider(value: $design.radius, in: 3...15, step: 1)
            Picker("Font", selection: $design.font) {
                Text("Rounded").tag("rounded"); Text("System").tag("system"); Text("Mono").tag("mono"); Text("Serif").tag("serif")
            }
            Toggle("Âm thanh phím", isOn: $design.sound)
            PhotosPicker("Chọn ảnh nền", selection: $picker, matching: .images).buttonStyle(.bordered)
                .onChange(of: picker) { item in
                    guard let item else { return }
                    Task { @MainActor in
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let source = CGImageSourceCreateWithData(data as CFData, nil),
                           let thumb = CGImageSourceCreateThumbnailAtIndex(source, 0, [kCGImageSourceCreateThumbnailFromImageAlways:true, kCGImageSourceCreateThumbnailWithTransform:true, kCGImageSourceThumbnailMaxPixelSize:1000] as CFDictionary) {
                            image = UIImage(cgImage: thumb)
                        } else { status = "Không đọc được ảnh." }
                    }
                }
            Button("Bỏ ảnh nền") { image = nil }.buttonStyle(.bordered)
            Button("Lưu & áp dụng") {
                guard [design.canvas,design.key,design.text,design.modifier].allSatisfy({ $0.count == 6 && UInt32($0, radix: 16) != nil }),
                      let url = KeyboardDesign.wallpaperURL else { status = "Kiểm tra mã HEX và quyền App Group."; return }
                do {
                    if let image, let bytes = image.jpegData(compressionQuality: 0.72) { try bytes.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication]) }
                    else if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }
                    KeyboardDesign.current = design; KeyboardSettings.theme = "custom"; status = "Đã lưu. Mở lại bàn phím để áp dụng."
                } catch { status = error.localizedDescription }
            }.buttonStyle(.borderedProminent)
            Text(status).font(.caption)
        }
    }
}
