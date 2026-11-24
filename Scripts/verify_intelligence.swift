import Foundation

@main
struct VerifyIntelligence {
    static func main() {
        precondition(Set(IntelligenceTask.tasks.map(\.id)).count == IntelligenceTask.tasks.count)
        precondition(IntelligenceTask.tasks.contains { $0.id == "complaint" })
        precondition(IntelligenceTask.translation(to: "Korean", bilingual: true, formal: true).contains("original text"))
        precondition(SymbolCatalog.search("cuoi").contains { $0.value == "😀" })
        precondition(SymbolCatalog.search("tim", category: "Tình cảm").contains { $0.value == "❤️" })
        precondition(PersonalDictionary.normalize("  chào\nCHÀO\n123\nđẹp\nfoo bar") == ["chào", "đẹp"])
        let dna = PersonalStyleDNA.analyze(["Chào bạn?", "Chào bạn!"])
        precondition(dna.count == 2 && dna.averageWords == 2 && dna.questions == 1 && dna.exclamations == 1)
        print("PASS [Intelligence] task catalog, symbols, dictionary and personal style")
    }
}
