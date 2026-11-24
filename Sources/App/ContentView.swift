import SwiftUI
import UIKit
import AudioToolbox
import PhotosUI

/// Compact native settings screen for the ViePN AI Keyboard host application.
/// This view intentionally has no NavigationStack or large navigation title:
/// the first card starts directly below the iPhone safe area.
struct ContentView: View {
    @State var provider = KeyboardSettings.provider
    @State var recipientMode = KeyboardSettings.recipientMode
    @State var selectedPage = "couple"
    @State var showCouplePrivacy = false
    @State var geminiAPIKey = KeyboardSettings.geminiAPIKey
    @State var geminiModel = KeyboardSettings.geminiModel
    @State var openAIAPIKey = KeyboardSettings.openAIAPIKey
    @State var openAIModel = KeyboardSettings.openAIModel
    @State var showGeminiKey = false
    @State var showOpenAIKey = false
    @State var cloudEnabled = KeyboardSettings.allowCloudAI
    @State var telexEnabled = KeyboardSettings.telexEnabled
    @State var emojiEnabled = KeyboardSettings.emojiEnabled
    @State var coupleEnabled = KeyboardSettings.coupleEnabled
    @State var coupleStage = KeyboardSettings.coupleStage
    @State var coupleStyle = KeyboardSettings.coupleStyle
    @State var coupleAddress = KeyboardSettings.coupleAddress
    @State var typingMode = KeyboardSettings.typingMode
    @State var keyboardTheme = KeyboardSettings.theme
    @State var keypressEffect = KeyboardSettings.keypressEffect
    @State var showAllThemes = false
    @State var showAllShortcuts = false
    @State var hapticEnabled = KeyboardSettings.hapticEnabled
    @State var hapticStyle = KeyboardSettings.hapticStyle
    @State var smartBilingual = KeyboardSettings.smartBilingual
    @State var bilingualPreference = KeyboardSettings.bilingualPreference
    @State var performanceMode = KeyboardSettings.performanceMode
    @State var predictionsEnabled = KeyboardSettings.predictionsEnabled
    @State var sentenceSuggestionsEnabled = KeyboardSettings.sentenceSuggestionsEnabled
    @State var glideEnabled = KeyboardSettings.glideEnabled
    @State var glideTrailEnabled = KeyboardSettings.glideTrailEnabled
    @State var glideLearningEnabled = KeyboardSettings.glideLearningEnabled
    @State var adaptiveTouchEnabled = KeyboardSettings.adaptiveTouchEnabled
    @State var writingSamples = KeyboardSettings.writingSamples
    @State var newWritingSample = ""
    @State var privateTypingMode = KeyboardSettings.privateTypingMode
    @State var autoLearnWords = KeyboardSettings.autoLearnWords
    @State var oneHandMode = KeyboardSettings.oneHandMode
    @State var keySpacingValue = String(KeyboardSettings.keySpacing)
    @State var keyHeightValue = String(KeyboardSettings.keyHeight)
    @State var newSnippetKey = ""
    @State var newSnippetValue = ""
    @State var snippets = KeyboardSettings.textSnippets
    @State var personas = PersonaStore.all
    @State var activePersonaID = PersonaStore.activeID
    @State var personaName = ""
    @State var showContactNamePicker = false
    @State var personaScreenshotPicker: PhotosPickerItem?
    @State var pendingHeaderTitle = ""
    @State var pendingHeaderPNG: Data?
    @State var scannedTitleOptions: [ChatScreenshotReference.ScannedTitle] = []
    @State var headerDiagnosticPreview: Data?
    @State var manualScreenshotData: Data?
    @State var manualHeaderTop = 0.075
    @State var screenshotReferenceStatus = ""
    @State var autoMatchPersona = PersonaStore.automaticNameMatch
    @State var transcriptPreview = ""
    @State var transcriptMatchStatus = ""
    @State var personaRole = "uncle"
    @State var personaSelfAddress = "cháu"
    @State var personaTone = "Lịch sự"
    @State var savedClipboard = ClipboardVault.items
    @State var autoCapitalize = KeyboardSettings.autoCapitalize
    @State var preferredTone = KeyboardSettings.preferredTone
    @State var preferredLength = KeyboardSettings.preferredLength
    @State var fallbackModel = KeyboardSettings.fallbackModel
    @State var translationLanguage = KeyboardSettings.translationLanguage
    @State var abbreviations = KeyboardSettings.replacementDictionary
    @State var shortcut = ""
    @State var expansion = ""
    @State var favorites = KeyboardSettings.favoriteReplies
    @State var availableModels: [GeminiModelOption] = []
    @State var loadingModels = false
    @State var testingAPI = false
    @State var testingMessage = false
    @State var apiFeedback = ""
    @State var demoFeedback = ""
    @State var demoMessage = "Hôm nay của bạn thế nào?"
    @State var suggestions: [ReplySuggestion] = []
    @State var phrases = KeyboardSettings.savedPhrases
    @State var newPhrase = ""
    @State var showGuide = false
    @State var showDiagnosis = false
    @State var showQuickReplies = false
    @State var showTest = false
    @State var keyboardDiagnosis = "Chưa kiểm tra cấu trúc Keyboard Extension."

    let background = Color(red: 0.045, green: 0.060, blue: 0.105)
    let cardColor = Color(red: 0.105, green: 0.128, blue: 0.195)
    let violet = Color(red: 0.46, green: 0.43, blue: 1.0)
    let cyan = Color(red: 0.28, green: 0.82, blue: 0.97)
    let muted = Color(red: 0.66, green: 0.71, blue: 0.82)

    // Full-height dashboard. The background bleeds under both iOS safe areas,
    // while interactive controls remain inside the safe area.
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [background, Color(red: 0.085, green: 0.095, blue: 0.16), background],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                compactHeader
                    .padding(.horizontal, 17)
                    .padding(.top, 5)
                    .padding(.bottom, 8)

                Rectangle()
                    .fill(.white.opacity(0.08))
                    .frame(height: 1)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 12) {
                        if selectedPage == "couple" {
                            coupleStudio
                            testArea
                            savedReplies
                        } else if selectedPage == "ai" {
                            aiConfiguration
                            personaSettingsCard
                        } else if selectedPage == "keyboard" {
                            personalization
                        } else if selectedPage == "assistant" {
                            AdvancedAssistantView()
                        } else if selectedPage == "owner" {
                            OwnerInformationView()
                        } else {
                            IntelligenceHubView()
                            activationGuide
                            keyboardDiagnostics
                            clipboardSettingsCard
                            privacyInfo
                        }
                    }
                    .frame(maxWidth: 600)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 13)
                    .padding(.top, 12)
                    .padding(.bottom, 12)
                }
                .scrollDismissesKeyboard(.interactively)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                bottomNavigation
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .preferredColorScheme(.dark)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            provider = KeyboardSettings.provider
            favorites = KeyboardSettings.favoriteReplies
            phrases = KeyboardSettings.savedPhrases
            writingSamples = KeyboardSettings.writingSamples
            coupleEnabled = KeyboardSettings.coupleEnabled
            coupleStage = KeyboardSettings.coupleStage
            coupleStyle = KeyboardSettings.coupleStyle
            coupleAddress = KeyboardSettings.coupleAddress
            savedClipboard = ClipboardVault.items
            personas = PersonaStore.all
            activePersonaID = PersonaStore.activeID
        }
    }
}
