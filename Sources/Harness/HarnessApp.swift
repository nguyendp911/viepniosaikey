import UIKit

/// Debug-only host: loads the real keyboard view controller in a plain app so
/// CI can press every button (HARNESS_MODE=poke) or take pictures of it
/// (HARNESS_MODE=shot, optionally HARNESS_PRESS=1 to hold a key down).
@main
final class HarnessAppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private var keyboard: KeyboardViewController?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        setvbuf(stdout, nil, _IONBF, 0)
        let env = ProcessInfo.processInfo.environment
        let mode = env["HARNESS_MODE"] ?? "poke"
        print("HARNESS start mode=\(mode)")
        PersonaStore.add(name: "Mai Linh", role: ReplyRecipient.partner.rawValue,
                         selfAddress: "anh", tone: "Ngọt ngào")
        PersonaStore.add(name: "Hoa", role: ReplyRecipient.friend.rawValue,
                         selfAddress: "mình", tone: "Tự nhiên")
        KeyboardSettings.coupleEnabled = true
        if let theme = env["HARNESS_THEME"] { KeyboardSettings.theme = theme }
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        let today = SpecialDate(id: "harness", title: "Ngày yêu", kind: "anniversary",
                                month: parts.month ?? 1, day: parts.day ?? 1,
                                year: (parts.year ?? 2026) - 1)
        KeyboardSettings.setSpecialDatesData(SpecialDates.encode([today]), for: PersonaStore.activeID)

        let host = UIViewController()
        host.view.backgroundColor = .systemBackground
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = host
        window.makeKeyAndVisible()
        self.window = window

        let keyboard = KeyboardViewController()
        host.addChild(keyboard)
        let bottomInset = window.safeAreaInsets.bottom
        let height: CGFloat = 330
        keyboard.view.frame = CGRect(x: 0, y: host.view.bounds.height - height - bottomInset,
                                     width: host.view.bounds.width, height: height)
        keyboard.view.autoresizingMask = [.flexibleWidth, .flexibleTop]
        host.view.addSubview(keyboard.view)
        keyboard.didMove(toParent: host)
        self.keyboard = keyboard
        print("HARNESS keyboard loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            if mode == "shot" { self?.shot() } else { self?.poke() }
        }
        return true
    }

    private func buttons(in view: UIView) -> [UIButton] {
        var found: [UIButton] = []
        for child in view.subviews {
            if let button = child as? UIButton { found.append(button) }
            found.append(contentsOf: buttons(in: child))
        }
        return found
    }

    private func shot() {
        guard let keyboard else { return }
        keyboard.textDidChange(nil)
        if ProcessInfo.processInfo.environment["HARNESS_PRESS"] != nil {
            let key = buttons(in: keyboard.view).first { $0.title(for: .normal) == "g" }
            key?.isHighlighted = true
            key?.sendActions(for: .touchDown)
        }
        print("HARNESS SHOT READY")
    }

    private func poke() {
        guard let keyboard else { return }
        keyboard.textDidChange(nil)
        print("HARNESS textDidChange ok")
        let all = buttons(in: keyboard.view)
        print("HARNESS buttons \(all.count)")
        for (index, button) in all.enumerated() {
            button.sendActions(for: .touchUpInside)
            if index % 10 == 0 { print("HARNESS pressed \(index)") }
        }
        keyboard.textDidChange(nil)
        print("HARNESS OK")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { exit(0) }
    }
}
