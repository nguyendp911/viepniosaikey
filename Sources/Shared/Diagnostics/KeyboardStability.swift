import Foundation

/// No keystrokes are logged. Only anonymized, bounded counters and timings
/// for user-triggered actions are stored locally until explicitly cleared.
enum KeyboardStability {
    private static let prefix = "viepnaikey.diagnostics."
    private static var defaults: UserDefaults { KeyboardSettings.defaults }
    static func note(_ action: String, durationMs: Double) {
        let valid = ["paste", "couple", "offline", "ai", "phrases", "typing"]
        guard valid.contains(action) else { return }
        let key = prefix + action
        let samples = min(1000, defaults.integer(forKey: key + ".count") + 1)
        let previous = defaults.double(forKey: key + ".averageMs")
        defaults.set(samples, forKey: key + ".count")
        let boundedMs = max(0, min(60000, durationMs))
        defaults.set((previous * Double(samples - 1) + boundedMs)
                     / Double(samples), forKey: key + ".averageMs")
        if action == "typing" {
            // Aggregate latency buckets only: no actual letters, usernames,
            // touch locations or surrounding message content are collected.
            let cutoffs: [Double] = [8, 16, 24, 40, 80]
            var buckets = defaults.array(forKey: key + ".histogram")
                as? [Int] ?? Array(repeating: 0, count: 6)
            if buckets.count != 6 { buckets = Array(repeating: 0, count: 6) }
            let index = cutoffs.firstIndex(where: { boundedMs <= $0 }) ?? 5
            buckets[index] = min(100000, buckets[index] + 1)
            defaults.set(buckets, forKey: key + ".histogram")
        }
    }
    static func report() -> String {
        let rows = ["paste", "couple", "offline", "ai", "phrases", "typing"].map { name in
            let count = defaults.integer(forKey: prefix + name + ".count")
            return "\(name): \(count) lần, trung bình \(Int(defaults.double(forKey: prefix + name + ".averageMs")))ms"
        }
        let hist = defaults.array(forKey: prefix + "typing.histogram") as? [Int] ?? []
        guard hist.count == 6, hist.reduce(0, +) > 0 else {
            return rows.joined(separator: "\n")
        }
        let total = hist.reduce(0, +)
        let target = Int(ceil(Double(total) * 0.95))
        var running = 0
        let labels = ["≤8", "≤16", "≤24", "≤40", "≤80", ">80"]
        var estimate = labels.last!
        for (index, count) in hist.enumerated() {
            running += count
            if running >= target { estimate = labels[index]; break }
        }
        return (rows + ["typing: P95 bucket \(estimate)ms (\(total) samples; 1/50 touches)"])
            .joined(separator: "\n")
    }
    static func clear() {
        for name in ["paste", "couple", "offline", "ai", "phrases", "typing"] {
            defaults.removeObject(forKey: prefix + name + ".count")
            defaults.removeObject(forKey: prefix + name + ".averageMs")
            defaults.removeObject(forKey: prefix + name + ".histogram")
        }
    }
}
