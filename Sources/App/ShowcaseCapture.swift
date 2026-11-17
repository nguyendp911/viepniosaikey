import SwiftUI
import UIKit

/// Takes pictures of the app itself, one set per tab, for introductions and
/// articles. For every tab it saves the whole window as it looks, and (if
/// asked) one tall picture of the whole scrollable content, stitched from the
/// real screen so system controls are drawn exactly as the user sees them.
enum ShowcaseCapture {
    @MainActor
    static func keyWindow() -> UIWindow? {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
        return windows.first(where: { $0.isKeyWindow }) ?? windows.first
    }

    /// The window without the empty band where the status bar would be, so
    /// the picture starts at the app's own header.
    @MainActor
    static func windowImage(_ window: UIWindow) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = window.screen.scale
        format.opaque = true
        let top = window.safeAreaInsets.top
        let size = CGSize(width: window.bounds.width, height: window.bounds.height - top)
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            window.drawHierarchy(
                in: CGRect(x: 0, y: -top, width: window.bounds.width, height: window.bounds.height),
                afterScreenUpdates: true)
        }
    }

    /// The tall page scroller (not a small text box or a horizontal strip).
    @MainActor
    static func mainScrollView(in root: UIView) -> UIScrollView? {
        var best: UIScrollView?
        func walk(_ view: UIView) {
            if let scroll = view as? UIScrollView,
               scroll.bounds.width > 250, scroll.bounds.height > 300,
               scroll.contentSize.height > scroll.bounds.height + 40 {
                if best == nil || scroll.contentSize.height > (best?.contentSize.height ?? 0) {
                    best = scroll
                }
            }
            for child in view.subviews { walk(child) }
        }
        walk(root)
        return best
    }

    /// One image with the whole scrollable content, or nil when the page fits
    /// on the screen. The scroll position is restored afterwards.
    @MainActor
    static func longImage(in window: UIWindow) async -> UIImage? {
        guard let scroll = mainScrollView(in: window) else { return nil }
        let contentHeight = scroll.contentSize.height
        let viewHeight = scroll.bounds.height
        let width = scroll.bounds.width
        let region = scroll.convert(scroll.bounds, to: window)
        let scale = window.screen.scale
        let originalOffset = scroll.contentOffset
        let top = scroll.adjustedContentInset.top
        let maxOffset = max(0, contentHeight - viewHeight)

        var offsets: [CGFloat] = []
        var position: CGFloat = 0
        while position < maxOffset {
            offsets.append(position)
            position += viewHeight
        }
        offsets.append(maxOffset)

        let tileFormat = UIGraphicsImageRendererFormat()
        tileFormat.scale = scale
        tileFormat.opaque = true
        var tiles: [(y: CGFloat, image: UIImage)] = []
        for offset in offsets {
            scroll.setContentOffset(CGPoint(x: 0, y: offset - top), animated: false)
            try? await Task.sleep(nanoseconds: 280_000_000)
            let actual = scroll.contentOffset.y + top
            let tile = UIGraphicsImageRenderer(size: region.size, format: tileFormat).image { _ in
                window.drawHierarchy(
                    in: CGRect(x: -region.minX, y: -region.minY,
                               width: window.bounds.width, height: window.bounds.height),
                    afterScreenUpdates: true)
            }
            tiles.append((y: actual, image: tile))
        }
        scroll.setContentOffset(originalOffset, animated: false)

        let fullFormat = UIGraphicsImageRendererFormat()
        fullFormat.scale = scale
        fullFormat.opaque = true
        let size = CGSize(width: width, height: contentHeight)
        return UIGraphicsImageRenderer(size: size, format: fullFormat).image { _ in
            for tile in tiles { tile.image.draw(at: CGPoint(x: 0, y: tile.y)) }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

/// Keeps the state of a capture run. The card lives in the Tools tab and is
/// removed while the app visits the other tabs, so the state cannot live in
/// the card itself.
@MainActor
final class ShowcaseModel: ObservableObject {
    static let shared = ShowcaseModel()

    @Published var includeLong = true
    @Published var busy = false
    @Published var status = ""
    @Published var files: [URL] = []
    @Published var showShare = false
    private var autorunStarted = false

    func autorunIfRequested(run: @escaping () -> Void) {
        guard ProcessInfo.processInfo.environment["VIEPN_SHOWCASE_AUTORUN"] != nil,
              !autorunStarted else { return }
        autorunStarted = true
        run()
    }

    func capture(pages: [(id: String, title: String)],
                 select: (String) -> Void, current: () -> String,
                 hideSecrets: () -> Void, autorun: Bool = false) async {
        guard !busy else { return }
        busy = true
        let original = current()
        hideSecrets()
        let folder = autorun
            ? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("showcase", isDirectory: true)
            : FileManager.default.temporaryDirectory.appendingPathComponent("ViePN-gioi-thieu", isDirectory: true)
        try? FileManager.default.removeItem(at: folder)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        var written: [URL] = []
        for (index, page) in pages.enumerated() {
            select(page.id)
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard let window = ShowcaseCapture.keyWindow() else { continue }
            let number = String(format: "%02d", index + 1)
            if let data = ShowcaseCapture.windowImage(window).pngData() {
                let url = folder.appendingPathComponent("\(number)-\(page.id).png")
                if (try? data.write(to: url)) != nil { written.append(url) }
            }
            if includeLong, let tall = await ShowcaseCapture.longImage(in: window),
               let data = tall.pngData() {
                let url = folder.appendingPathComponent("\(number)-\(page.id)-dai.png")
                if (try? data.write(to: url)) != nil { written.append(url) }
            }
        }
        select(original)
        files = written
        busy = false
        status = written.isEmpty ? "Không chụp được ảnh nào." : "Đã chụp \(written.count) ảnh."
        if autorun {
            print("SHOWCASE DONE \(written.count)")
        } else if !written.isEmpty {
            showShare = true
        }
    }
}

/// A card for the Tools tab: "take pictures of every tab".
struct ShowcaseCaptureCard: View {
    let pages: [(id: String, title: String)]
    let select: (String) -> Void
    let current: () -> String
    let hideSecrets: () -> Void

    @ObservedObject private var model = ShowcaseModel.shared

    private let cyan = Color(red: 0.28, green: 0.82, blue: 0.97)
    private let violet = Color(red: 0.46, green: 0.43, blue: 1.0)
    private let muted = Color(red: 0.66, green: 0.71, blue: 0.82)
    private let cardColor = Color(red: 0.105, green: 0.128, blue: 0.195)

    private func start(autorun: Bool) {
        Task {
            await model.capture(pages: pages, select: select, current: current,
                                hideSecrets: hideSecrets, autorun: autorun)
        }
    }

    var body: some View {
        // While pictures are being taken the card disappears, so it does not
        // show up in the picture of the Tools tab.
        Group {
            if !model.busy {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 9) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(cyan)
                            .frame(width: 30, height: 30)
                            .background(cyan.opacity(0.11), in: RoundedRectangle(cornerRadius: 9))
                        Text("Chụp ảnh giới thiệu app")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                        Spacer(minLength: 0)
                    }
                    Text("App tự chuyển qua từng tab và chụp cả màn hình. Có thể chụp thêm một ảnh dài chứa toàn bộ nội dung của tab, tiện để làm bài giới thiệu. Ảnh có thể chứa tên hồ sơ hay thông tin của bạn, hãy kiểm tra trước khi đăng.")
                        .font(.system(size: 11))
                        .foregroundStyle(muted)
                        .fixedSize(horizontal: false, vertical: true)
                    Toggle("Kèm ảnh dài toàn bộ nội dung từng tab", isOn: $model.includeLong)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                        .tint(violet)
                    Button {
                        start(autorun: false)
                    } label: {
                        Label("Bắt đầu chụp \(pages.count) tab", systemImage: "camera.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundStyle(.white)
                            .background(violet, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    if !model.status.isEmpty {
                        Text(model.status)
                            .font(.system(size: 11))
                            .foregroundStyle(muted)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardColor, in: RoundedRectangle(cornerRadius: 17))
                .overlay(RoundedRectangle(cornerRadius: 17)
                    .stroke(Color.white.opacity(0.065), lineWidth: 1))
            }
        }
        .sheet(isPresented: $model.showShare) {
            ShareSheet(items: model.files)
        }
        .onAppear {
            model.autorunIfRequested { start(autorun: true) }
        }
    }
}
