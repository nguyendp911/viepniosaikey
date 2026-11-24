import Foundation

enum PremiumWorkflowService {
    static func run(_ text:String, steps:[String], provider:String) async throws -> String {
        guard !steps.isEmpty, steps.count <= 4, steps.allSatisfy({ PremiumCommands.find($0)?.isAI == true }) else { throw AIServiceError.invalidResponse }
        var result = text
        for step in steps {
            try Task.checkCancellation()
            guard KeyboardSettings.allowCloudAI, let command = PremiumCommands.find(step), MessageSafety.warnings(in:result).isEmpty else { throw AIServiceError.missingConsent }
            result = try await AIWritingService.studio(result,instruction:command.instruction,provider:provider)
        }
        return result
    }
}
