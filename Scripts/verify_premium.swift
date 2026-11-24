import Foundation

@main
struct VerifyPremium {
    static func main() throws {
        precondition(Set(PremiumCommands.all.map(\.id)).count == PremiumCommands.all.count)
        precondition(PremiumCommands.search("lạnh lùng").contains{$0.id == "lanhlung"})
        precondition(PremiumCommands.search("/dich han").contains{$0.id == "dichhan"})
        precondition(PremiumCommands.personalities.count == 7)
        let a = try PremiumCalculator.evaluate("2+3*4"); precondition(a == "14")
        let b = try PremiumCalculator.evaluate("(2+3)×4"); precondition(b == "20")
        let c = try PremiumCalculator.evaluate("-2.5+1.5"); precondition(c == "-1")
        for expression in ["1/0","2+","x","(3","1;2"] { precondition((try? PremiumCalculator.evaluate(expression)) == nil) }
        precondition(PremiumOffline.format("  xin   chào  ",mode:"gon") == "xin chào")
        precondition(PremiumOffline.format("a\nb",mode:"danhsach") == "• a\n• b")
        precondition(PremiumOffline.variables("Chào {{ten}} {{x}}",name:"Bạn",custom:["x":"{{ten}}"]) == "Chào Bạn {{ten}}")
        precondition(PremiumOffline.guardian("OTP 123456").contains("OTP"))
        precondition(GhostCompletion.suffix(after:"hôm nay bạn ") == "có khỏe không?")
        precondition(GhostCompletion.suffix(after:"hôm nay bạn") == nil)
        let workflow = PremiumWorkflow(title:"test",steps:["suachinh","dichhan"])
        let restored = try JSONDecoder().decode(PremiumWorkflow.self,from:JSONEncoder().encode(workflow))
        precondition(restored == workflow)
        print("PASS Premium 2.0: catalog, search, calculator, formatter, variables, guardian, ghost and workflow serialization")
    }
}
