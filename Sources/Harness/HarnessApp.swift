import UIKit

/// Debug-only host: loads the real keyboard view controller in a plain app
/// (with saved profiles, Couple on and a special date today) and presses every
/// button, so a crash while the keyboard starts or reacts shows up in CI.
@main
final class HarnessAppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private var keyboard: KeyboardViewController?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        setvbuf(stdout, nil, _IONBF, 0)
        print("HARNESS start")
        PersonaStore.add(name: "Mai Linh", role: ReplyRecipient.partner.rawValue,
                         selfAddress: "anh", tone: "Ngọt ngào")
        PersonaStore.add(name: "Hoa", role: ReplyRecipient.friend.rawValue,
                         selfAddress: "mình", tone: "Tự nhiên")
        KeyboardSettings.coupleEnabled = true
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
        let height: CGFloat = 330
        keyboard.view.frame = CGRect(x: 0, y: host.view.bounds.height - height,
                                     width: host.view.bounds.width, height: height)
        keyboard.view.autoresizingMask = [.flexibleWidth, .flexibleTop]
        host.view.addSubview(keyboard.view)
        keyboard.didMove(toParent: host)
        self.keyboard = keyboard
        print("HARNESS keyboard loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in self?.poke() }
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
