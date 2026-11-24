import SwiftUI
import PhotosUI
import Vision
import Speech
import AVFoundation
import EventKit
import UIKit
import LocalAuthentication

/// Photo OCR and speech recognition must run in the containing app; third-party
/// keyboard extensions cannot inspect other apps' conversations or use microphone.
struct AdvancedAssistantView: View {
    @State var chosenImage: PhotosPickerItem?
    @State var screenshotMatch: PersonaStore.ScreenshotMatch?
    @State var screenshotEvidence = ""
    @State var screenshotVisualOnly = false
    @State var screenshotRecognitionRequest = UUID()
    @State var screenshotMatchStatus = ""
    @State var sourceText = ""
    @State var responseText = ""
    @State var replyChoices: [ReplySuggestion] = []
    @State var feedback = ""
    @State var busy = false
    @State var privatePreview = true
    @State var mode = "Viết tự nhiên"
    @State var memoryText = ""
    @State var transcriptDraft = ""
    @State var savedChatTurns = ConversationHistory.turns(for: PersonaStore.activeID)
    @State var chatSearch = ""
    @State var editingChatTurnID: String?
    @State var editingChatText = ""
    @State var showClearChatConfirmation = false
    @State var chatPreview = ""
    @State var generatedChatSuggestions: [ReplySuggestion] = []
    @State var evidenceExplanation = ""
    @State var showExplanation = false
    @State var openingNote = ""
    @State var historyLockEnabled = KeyboardSettings.historyScreenLockEnabled
    @State var conversationStyleEnabled =
        KeyboardSettings.learnConversationStyleEnabled
    @State var historyUnlocked = false
    @State var remindersTitle = ""
    @State var reminderDate = Date().addingTimeInterval(3600)
    @State var savedMemories = ConversationMemory.forActivePersona()
    @State var diagnostics = KeyboardStability.report()
    @StateObject var voice = VoiceTranscriber()

    let tools = ["Viết tự nhiên", "Kiểm tra giọng điệu", "Dịch song ngữ",
                         "Gợi ý trả lời", "Sửa chính tả", "Rút gọn"]

    var body: some View {
        VStack(spacing: 12) {
            screenshotSection
            voiceSection
            writingSection
            historyPrivacySection
            if !historyLockEnabled || historyUnlocked {
                memorySection
                historySection
            } else {
                lockedHistorySection
            }
            calendarSection
            learningSection
            diagnosticsSection
            if !feedback.isEmpty {
                Text(feedback)
                    .font(.caption)
                    .foregroundStyle(.cyan)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .foregroundStyle(.white)
        .onAppear {
            refreshActiveChatProfile()
        }
        .onReceive(NotificationCenter.default.publisher(
            for: UIApplication.didBecomeActiveNotification)) { _ in
                if !historyLockEnabled || historyUnlocked {
                    refreshActiveChatProfile()
                }
        }
        .onDisappear { historyUnlocked = false }
    }

    private func section<Content: View>(_ heading: String, icon: String,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(heading, systemImage: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.cyan)
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
    }

}
