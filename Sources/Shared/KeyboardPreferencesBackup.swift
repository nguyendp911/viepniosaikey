import Foundation

/// Explicit, non-sensitive settings only. Never includes secrets, messages,
/// learned words, clipboard, snippets, contact profiles or writing samples.
struct KeyboardPreferencesBackup: Codable {
    let version: Int
    let theme: String
    let effect: String
    let height: Int
    let spacing: Int
    let oneHand: String
    let typing: String
    let bilingual: Bool
    let language: String
    let predictions: Bool
    let sentenceSuggestions: Bool
    let glide: Bool
    let glideTrail: Bool
    let performance: Bool
    let haptic: Bool
    let hapticStyle: String
    let tone: String
    let length: String
    let translation: String

    static func capture() -> Self {
        .init(version: 1, theme: KeyboardSettings.theme, effect: KeyboardSettings.keypressEffect,
              height: KeyboardSettings.keyHeight, spacing: KeyboardSettings.keySpacing,
              oneHand: KeyboardSettings.oneHandMode, typing: KeyboardSettings.typingMode,
              bilingual: KeyboardSettings.smartBilingual, language: KeyboardSettings.bilingualPreference,
              predictions: KeyboardSettings.predictionsEnabled, sentenceSuggestions: KeyboardSettings.sentenceSuggestionsEnabled,
              glide: KeyboardSettings.glideEnabled, glideTrail: KeyboardSettings.glideTrailEnabled,
              performance: KeyboardSettings.performanceMode, haptic: KeyboardSettings.hapticEnabled,
              hapticStyle: KeyboardSettings.hapticStyle, tone: KeyboardSettings.preferredTone,
              length: KeyboardSettings.preferredLength, translation: KeyboardSettings.translationLanguage)
    }

    func restore() throws {
        guard version == 1,
              KeyboardSettings.availableThemes.contains(theme), KeyboardSettings.availableKeyEffects.contains(effect),
              (40...49).contains(height), (3...9).contains(spacing),
              ["off", "left", "right"].contains(oneHand),
              ["telex", "vni", "off"].contains(typing),
              ["auto", "vi", "en"].contains(language), ["light", "vibrate"].contains(hapticStyle),
              ["Tự nhiên", "Lịch sự", "Ngọt ngào", "Quan tâm", "Lạnh lùng", "Hờn nhẹ", "Trưởng thành", "Hài hước", "Chuyên nghiệp"].contains(tone),
              ["Ngắn", "Vừa", "Chi tiết"].contains(length),
              ["English", "Chinese (Simplified)", "Japanese", "Korean", "French"].contains(translation)
        else { throw BackupError.invalid }
        KeyboardSettings.theme = theme
        KeyboardSettings.keypressEffect = effect
        KeyboardSettings.keyHeight = height
        KeyboardSettings.keySpacing = spacing
        KeyboardSettings.oneHandMode = oneHand
        KeyboardSettings.typingMode = typing
        KeyboardSettings.telexEnabled = typing == "telex"
        KeyboardSettings.smartBilingual = bilingual
        KeyboardSettings.bilingualPreference = language
        KeyboardSettings.predictionsEnabled = predictions
        KeyboardSettings.sentenceSuggestionsEnabled = sentenceSuggestions
        KeyboardSettings.glideEnabled = glide
        KeyboardSettings.glideTrailEnabled = glideTrail
        KeyboardSettings.performanceMode = performance
        KeyboardSettings.hapticEnabled = haptic
        KeyboardSettings.hapticStyle = hapticStyle
        KeyboardSettings.preferredTone = tone
        KeyboardSettings.preferredLength = length
        KeyboardSettings.translationLanguage = translation
    }

    enum BackupError: LocalizedError {
        case invalid
        var errorDescription: String? { "File cài đặt không hợp lệ hoặc không tương thích." }
    }
}
