import UIKit

enum ToolbarActionRouter {
    static func selector(for action: ToolbarAction) -> Selector {
        switch action {
        case .paste: return #selector(KeyboardViewController.pasteTapped)
        case .couple: return #selector(KeyboardViewController.coupleTapped)
        case .ai: return #selector(KeyboardViewController.cloudTapped)
        case .offline: return #selector(KeyboardViewController.offlineTapped)
        case .phrases: return #selector(KeyboardViewController.phrasesTapped)
        case .tools: return #selector(KeyboardViewController.openIntelligenceHub)
        }
    }
}
