import Foundation

@main
struct VerifySentenceSuggestions {
    static func main() {
        let triggers = ["cam", "cảm", "chao", "chào", "chieu", "chiều",
                        "hen", "hẹn", "hom", "hôm", "xin", "toi", "tôi"]
        for trigger in triggers {
            let proposals = OfflineSentenceSuggestions.suggestions(for: trigger)
            precondition(!proposals.isEmpty, "Missing completion for \(trigger)")
            precondition(proposals.allSatisfy { !$0.isEmpty && $0.count <= 140 })
        }
        for unsafe in ["", "ca", "store", "/bank", "password", "123456", "a".repeated(100)] {
            precondition(OfflineSentenceSuggestions.suggestions(for: unsafe).isEmpty,
                         "Unexpected suggestion: \(unsafe)")
        }
        precondition(OfflineSentenceSuggestions.suggestions(for: "xin", limit: 0).isEmpty)
        let formal = OfflineSentenceSuggestions.suggestions(for: "cam", tone: "Lịch sự")
        precondition(formal == ["Xin chân thành cảm ơn anh/chị!"])
        let casual = OfflineSentenceSuggestions.suggestions(for: "cam", tone: "Tự nhiên")
        precondition(casual == ["Cảm ơn bạn rất nhiều!"])
        precondition(OfflineSentenceSuggestions.nextWords(after: "hôm nay ").first == "bạn")
        precondition(OfflineSentenceSuggestions.nextWords(after: "cảm ").first == "ơn")
        precondition(OfflineSentenceSuggestions.nextWords(after: "how are ", language: "en") == ["you"])
        precondition(OfflineSentenceSuggestions.nextWords(after: "hôm nay ", language: "en").isEmpty)
        precondition(OfflineSentenceSuggestions.nextWords(after: "hôm nay").isEmpty)
        precondition(OfflineSentenceSuggestions.nextWords(after: "hôm nay! ").isEmpty)
        print("PASS [Sentence] deterministic, bounded offline completions and next-word suggestions")
    }
}

private extension String {
    func repeated(_ count: Int) -> String {
        String(repeating: self, count: count)
    }
}
