import SwiftUI

/// Fixed examples preview a preference, without invoking AI or reading a chat.
struct ToneStudioPreview: View {
    let tone: String
    let length: String
    private var example: String {
        let samples: [String: [String]] = [
            "Tự nhiên": ["Ừ, nghỉ ngơi nhé.", "Hôm nay mệt rồi thì nghỉ ngơi nhé, mình nói chuyện sau cũng được."],
            "Lịch sự": ["Bạn nghỉ ngơi nhé.", "Bạn cứ dành thời gian nghỉ ngơi. Khi nào thuận tiện, mình trao đổi tiếp nhé."],
            "Ngọt ngào": ["Thương em, nghỉ ngơi nhé.", "Hôm nay em vất vả rồi. Thương em, nhớ dành thời gian nghỉ ngơi nhé."],
            "Quan tâm": ["Có cần anh giúp gì không?", "Hôm nay em mệt lắm không? Nhớ nghỉ ngơi và cho anh biết nếu cần giúp gì nhé."],
            "Lạnh lùng": ["Ừ, nghỉ đi.", "Ừ, em nghỉ ngơi đi. Khi nào rảnh thì nói chuyện."],
            "Hờn nhẹ": ["Anh hơi nhớ em, nghỉ nhé.", "Anh cũng hơi nhớ em hôm nay, nhưng em mệt thì cứ nghỉ trước nhé."],
            "Trưởng thành": ["Cứ nghỉ đi, mình nói sau.", "Em cứ dành thời gian cho bản thân, khi nào thoải mái mình nói chuyện tiếp nhé."],
            "Hài hước": ["Hết pin rồi, sạc lại thôi!", "Hôm nay hết pin rồi à? Nghỉ ngơi, sạc đầy năng lượng rồi mai chiến tiếp nhé!"],
            "Chuyên nghiệp": ["Bạn cứ nghỉ ngơi nhé.", "Bạn cứ nghỉ ngơi. Chúng ta sẽ tiếp tục trao đổi khi bạn thấy thuận tiện."]
        ]
        let selected = samples[tone] ?? samples["Tự nhiên"]!
        return selected[length == "Ngắn" ? 0 : 1]
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Label("Tone Studio · Ví dụ offline", systemImage: "waveform.path")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.cyan)
            Text("Tin mẫu: Hôm nay đi làm mệt quá.")
                .font(.system(size: 11)).foregroundStyle(.secondary)
            Text(example).font(.system(size: 14, weight: .medium))
                .fixedSize(horizontal: false, vertical: true)
            Text("Chỉ minh họa sắc thái; AI thực tế vẫn dựa vào người nhận và ngữ cảnh.")
                .font(.system(size: 10)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
    }
}
