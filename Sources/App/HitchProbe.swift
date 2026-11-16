import UIKit

/// Debug-only probe: records the longest gap between frames after a tab switch.
final class HitchProbe {
    static let shared = HitchProbe()
    private var link: CADisplayLink?
    private var last: CFTimeInterval = 0
    private var worst: Double = 0
    private var frames = 0

    func start(label: String, duration: TimeInterval) {
        last = CACurrentMediaTime()
        worst = 0
        frames = 0
        let l = CADisplayLink(target: self, selector: #selector(tick))
        l.add(to: .main, forMode: .common)
        link = l
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [self] in
            link?.invalidate()
            print("VIEPN_HITCH \(label) worst_ms=\(Int(worst * 1000)) frames=\(frames)")
            fflush(stdout)
        }
    }

    @objc private func tick() {
        let now = CACurrentMediaTime()
        worst = max(worst, now - last)
        last = now
        frames += 1
    }
}
