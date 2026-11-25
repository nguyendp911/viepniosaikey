import SwiftUI

/// Read the protected store after the view is mounted. Never decode or sort
/// learned phrases synchronously from a SwiftUI body or during tab switching.
struct PersonalPhraseCountView: View {
    let refreshID: UUID
    let privateMode: Bool
    @State private var count: Int?
    var body: some View {
        HStack {
            Image(systemName: "chart.bar.xaxis").foregroundStyle(.cyan)
            Text("Cụm từ đã học").font(.system(size: 12))
            Spacer()
            Text(privateMode ? "—" : count.map(String.init) ?? "…")
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
        }
        .padding(8)
        .accessibilityIdentifier("keyboard.learnedPhraseCount")
        .task(id: "\(refreshID.uuidString)-\(privateMode)") {
            count = nil
            guard !privateMode else { return }
            let value = await Task.detached(priority: .utility) {
                PersonalPhraseStore.load().entries.count
            }.value
            guard !Task.isCancelled, !KeyboardSettings.privateTypingMode else { return }
            count = value
        }
    }
}
