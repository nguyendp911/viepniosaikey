import UIKit
import AudioToolbox
import Vision
import AVFoundation

/// ViePN keyboard: composing a suggested reply never writes the source message
/// to the host chat field. All host-field modifications are explicit user taps.
final class KeyboardViewController: UIInputViewController {
    let container = UIStackView()
    let statusLabel = UILabel()
    let previewLabel = UILabel()
    var selectedText = ""
    var isUppercase = KeyboardSettings.autoCapitalize
    var isNumbers = false
    var isShiftLocked = false
    var lastSuggestions: [ReplySuggestion] = []
    var suggestionDocumentID: UUID?
    var suggestionPersonaID = ""
    var chosenIndex = 0
    var suggestionContainer: UIStackView?
    var isRequestRunning = false
    var requestID = UUID()
    var aiTask: Task<Void, Never>?

    func cancelAIRequest() {
        aiTask?.cancel()
        aiTask = nil
        requestID = UUID()
        isRequestRunning = false
    }
    var letterButtons: [UIButton] = []
    var letterRows: [UIStackView] = []
    var secondaryRow: UIStackView?
    var heightConstraint: NSLayoutConstraint?
    var toneButtons: [UIButton] = []
    var toolbarButtons: [ToolbarAction: ToolbarButton] = [:]
    let keyboardToolbar = KeyboardToolbarView()
    var toolbarConfiguration = ToolbarPreferences.configuration
    var lastToolbarLayout: ToolbarLayout?
    let aiColor = UIColor(red: 0.32, green: 0.36, blue: 0.93, alpha: 1)
    let cyanColor = UIColor(red: 0.07, green: 0.65, blue: 0.86, alpha: 1)
    let haptic = UIImpactFeedbackGenerator(style: .light)
    var lastVibrationAt: CFTimeInterval = 0
    // Read App Group preferences when the keyboard opens rather than on each key.
    var typingMode = KeyboardSettings.typingMode
    var telexEnabled = KeyboardSettings.telexEnabled
    var hapticsEnabled = KeyboardSettings.hapticEnabled
    var hapticsStyle = KeyboardSettings.hapticStyle
    var useSmartBilingual = KeyboardSettings.smartBilingual
    var useSentenceSuggestions = KeyboardSettings.sentenceSuggestionsEnabled
    var useSuggestions = KeyboardSettings.predictionsEnabled
    var useGlide = KeyboardSettings.glideEnabled
    var glideTrailEnabled = KeyboardSettings.glideTrailEnabled
    var performanceMode = KeyboardSettings.performanceMode
    var keypressEffect = KeyboardSettings.keypressEffect
    var adaptiveTouchEnabled = KeyboardSettings.adaptiveTouchEnabled
    var lastWordReplacement: (original: String, corrected: String)?
    // A swipe auto-inserts a trailing space. Keep its alternatives selectable
    // until the next physical key press, without editing arbitrary host text.
    var pendingGlideWord: String?
    var learnedWords: [String: Int] = [:]
    var customWords: [String: Int] = [:]
    var learnedWordFlushWork: DispatchWorkItem?
    var learnedWordDirty = false
    var recentWord = ""
    var typingPro6 = TypingProPreferences.current
    var pro6Feedback = TypingProFeedback()
    var pro6LastCorrectionDocument: UUID?
    var pro6LastCorrectionAnchor: String?
    var pro6Popup: UILabel?
    var pro6PopupWork: DispatchWorkItem?
    var pro6RepeatWork: DispatchWorkItem?
    var pro6DeleteAnchor: String?
    var pro6DeleteAfter: String?
    var pro6DeleteDocument: UUID?
    var pro6DeleteCount = 0
    weak var pro6DeletePanRecognizer: UIPanGestureRecognizer?
    var pro6LastSpace: (document: UUID, before: String, time: Date)?
    var pro6LastShift: Date?
    var pro6TouchOffsets: [String: Double] = [:]
    var pro6CustomActions: [String: String] = [:]
    var pro6Language: BilingualComposer.Preference?
    var pro6FeedbackRevision = ""
    var phraseModel=PersonalPhraseModel()
    var phraseRevision=""
    var phraseDocument:UUID?
    var phraseStart:String?
    var phraseEnd:String?
    var phraseChain:[String]=[]
    var phraseSaveWork:DispatchWorkItem?
    var phraseIdleWork:DispatchWorkItem?
    var phrasePendingWords:[String]?
    var phrasePendingDocument:UUID?
    var learnedPhraseChoices:[String:String]=[:]
    var learnedPhraseAnchor:String?
    var learnedPhraseDocument:UUID?
    let phraseStorageQueue=DispatchQueue(label:"com.viepn.phrase-storage",qos:.utility)
    var nextWordAnchor: String?
    var nextWordDocument: UUID?

    func showNextWords() {
        guard useSuggestions, pendingGlideWord == nil,
              (textDocumentProxy.selectedText?.isEmpty ?? true),
              textDocumentProxy.documentContextAfterInput?.first?.isLetter != true,
              let context = textDocumentProxy.documentContextBeforeInput else {
            updateCandidates()
            return
        }
        let anchor = String(context.suffix(80))
        var words = OfflineSentenceSuggestions.nextWords(after: anchor, language: bilingualPreference.rawValue)
        if premiumPreferences.ghost, !performanceMode, let suffix = GhostCompletion.suffix(after: anchor), !words.contains(suffix) {
            words.insert(suffix, at: 0)
        }
        let personalized=personalPhraseSuggestions(context:anchor).filter{useSentenceSuggestions || !$0.contains(" ")}
        if typingPro6.contextualEmoji {
            let last = PersonalPhraseModel.context(anchor).last ?? ""
            words += TypingProText.emoji(last).filter { !words.contains($0) }
        }
        words=personalized+words.filter{!personalized.contains($0)}
        guard !words.isEmpty else { updateCandidates(); return }
        nextWordAnchor = anchor
        nextWordDocument = textDocumentProxy.documentIdentifier
        updateCandidates(words)
    }
    var typingTouchCount: UInt64 = 0
    // Set only after this keyboard inserts a word boundary. The next letter
    // can start a new composition without asking the host for its text context.
    var knownWordBoundary = false
    // Original physical keys and displayed word are tracked separately.
    // This allows a partial English prefix to become Vietnamese later,
    // or a Vietnamese-looking prefix to resolve back to English.
    var rawComposingWord = ""
    var displayedComposingWord = ""
    // Cached incremental candidate avoids reconstructing the word after
    // every touch (formerly replayed Telex over its entire history).
    var telexCandidateWord = ""
    var candidateUpdateWork: DispatchWorkItem?
    // A single worker keeps consecutive prediction requests from competing
    // for CPU and starving keystrokes during long chats.
    let predictionQueue = DispatchQueue(
        label: "com.viepn.keyboard.predictions", qos: .utility)
    let typingDiagnosticsQueue = DispatchQueue(
        label: "com.viepn.keyboard.diagnostics", qos: .utility)
    let glideRecognitionQueue = DispatchQueue(
        label: "com.viepn.keyboard.glide", qos: .utility)
    var candidateExpandButton: UIButton?
    // A monotonically increasing generation prevents stale suggestions from
    // appearing after deletion or when the same prefix is typed again.
    var candidateGeneration: UInt64 = 0
    var cachedSnippets: [String: String] = [:]
    var cachedReplacements: [String: String] = [:]
    var autocapitalizeEnabled = true
    var learnWordsEnabled = false
    var bilingualPreference: BilingualComposer.Preference = .automatic

    func resetBilingualComposition() {
        rawComposingWord = ""
        displayedComposingWord = ""
        telexCandidateWord = ""
        pendingGlideWord = nil
        fullGlideOptions = []
    }
    let candidateBar = UIStackView()
    let candidateScroll = UIScrollView()
    // One fixed-height region beneath the five tool buttons. It switches
    // between idle shortcuts and in-progress word predictions without
    // moving the character rows or resizing the keyboard.
    let contextSlot = UIView()
    let idleScroll = UIScrollView()
    let idleBar = UIStackView()
    var idleActions: [(title: String, insert: String, emoji: Bool)] = []
    var isComposingInteraction = false
    var candidateButtons: [UIButton] = []
    // Swipe suggestions remain visible even when ordinary predictions are off.
    var isGlideSuggestionVisible = false
    var glideResultGeneration: UInt64 = 0
    var fullGlideOptions: [String] = []
    var glideUsageCounts: [String: Int] = [:]
    var glideLearningEnabled = true
    var candidateWords: [String] = []
    var keyboardLeadingConstraint: NSLayoutConstraint?
    var keyboardTrailingConstraint: NSLayoutConstraint?
    var keyHeightConstraints: [NSLayoutConstraint] = []
    var glidePath = ""
    var glideLastKey = ""
    var glideIsActive = false
    var glideRecognizer: UIPanGestureRecognizer?
    var glideTouchOrigin: CGPoint?
    var glideLastPoint: CGPoint?
    // Transparent, non-interactive Core Animation layers. The gesture path
    // is drawn in keyboard-view coordinates; no image assets or network calls.
    let glideGlowLayer = CAShapeLayer()
    let glideTrailLayer = CAShapeLayer()
    let glideTipLayer = CAShapeLayer()
    var glideTrailPath = UIBezierPath()
    var glideTrailPointCount = 0
    var glideTravelDistance: CGFloat = 0
    var lastGlideDrawTime: CFTimeInterval = 0
    var cursorSteps = 0

    func refreshTypingPreferences() {
        offlineConfig = OfflineKeyboardConfig.current
        proPrivate = KeyboardSettings.privateTypingMode
        typingPro6 = TypingProPreferences.current
        pro6DeletePanRecognizer?.isEnabled=typingPro6.backspacePan
        pro6FeedbackRevision = TypingProFeedback.revision
        pro6Feedback = proPrivate ? TypingProFeedback() : TypingProFeedback.current
        pro6TouchOffsets = proPrivate ? [:] : TypingProCustomization.offsets
        pro6CustomActions = TypingProCustomization.actions
        pro6LastSpace = nil; pro6LastShift = nil; pro6Language = nil
        offlineSnippets = proPrivate ? [] : OfflineProStore.snippets
        proHangulLast = nil; proHangulDocument = nil
        if proPrivate { proHistory.clear() }
        premiumPreferences = PremiumStore.preferences
        premiumTouchCounts = [:]
        typingMode = KeyboardSettings.typingMode
        telexEnabled = KeyboardSettings.telexEnabled
        performanceMode = KeyboardSettings.performanceMode
        keypressEffect = performanceMode ? "off" : KeyboardSettings.keypressEffect
        hapticsEnabled = KeyboardSettings.hapticEnabled && !performanceMode
        hapticsStyle = KeyboardSettings.hapticStyle
        useSmartBilingual = KeyboardSettings.smartBilingual
        bilingualPreference = BilingualComposer.Preference(
            rawValue: KeyboardSettings.bilingualPreference) ?? .automatic
        resetBilingualComposition()
        knownWordBoundary = false
        useSentenceSuggestions = KeyboardSettings.sentenceSuggestionsEnabled && !performanceMode
        useSuggestions = KeyboardSettings.predictionsEnabled && !performanceMode && offlineConfig.layout.latin
        if !offlineConfig.layout.latin { useSentenceSuggestions = false }
        useGlide = KeyboardSettings.glideEnabled && !performanceMode && offlineConfig.layout.latin && !offlineConfig.multiTap
        glideTrailEnabled = KeyboardSettings.glideTrailEnabled && !performanceMode
        adaptiveTouchEnabled = KeyboardSettings.adaptiveTouchEnabled
        let privateMode = KeyboardSettings.privateTypingMode
        premiumTouchAllowed = premiumPreferences.dynamicTouch && !privateMode && !performanceMode
        learnedWords = privateMode ? [:] : KeyboardSettings.learnedWords
        customWords = privateMode ? [:] : PersonalDictionary.merge(with: [:])
        glideLearningEnabled = KeyboardSettings.glideLearningEnabled && !privateMode
        glideUsageCounts = privateMode ? [:] : KeyboardSettings.glideUsageCounts
        cachedSnippets = KeyboardSettings.textSnippets
        cachedReplacements = KeyboardSettings.replacementDictionary
        autocapitalizeEnabled = KeyboardSettings.autoCapitalize
        learnWordsEnabled = KeyboardSettings.autoLearnWords && !performanceMode && !KeyboardSettings.privateTypingMode
        reloadPhraseLearning()
    }
    var currentTheme: String = ""
    var themeScheduleTimer: Timer?
    var scheduledBaseTheme = ""
    var scheduledTheme = ""
    let aiGradient = CAGradientLayer()
    var intelligenceOverlay: UIView?
    var wallpaperView: UIImageView?
    var customSound = false
    var studioEdit: StudioEdit?
    var premiumPreferences = PremiumStore.preferences
    var premiumTouchCounts: [ObjectIdentifier: Int] = [:]
    var premiumTouchAllowed = false
    var offlineConfig = OfflineKeyboardConfig.current
    var offlineSnippets: [ProSnippet] = []
    var proHistory = ProTextHistory()
    var proHangulLast: Character?
    var proHangulDocument: UUID?
    var proPrivate = false
    var proNumberRow: UIStackView?
    var proNumberHeight: NSLayoutConstraint?
    var proSpaceWidth: NSLayoutConstraint?
    var proSoundPlayer: AVAudioPlayer?
    var proSessionStart = Date()
    var proSessionTaps = 0
    var proParticleLayers: [CALayer] = []
    var proWallpaperLayer: CAGradientLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        refreshTypingPreferences()
        buildKeyboard()
        applyTheme()
        if hapticsEnabled && hapticsStyle == "light" { haptic.prepare() }
        // Build dictionaries off the main thread so the first keys are not slow.
        DispatchQueue.global(qos: .userInitiated).async { SmartTyping.warmUp() }
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        learnPhraseAfterHostClear()
        if scheduledBaseTheme != KeyboardSettings.theme { refreshScheduledTheme() }
        // Do not reset composition here: iOS may call textDidChange for
        // normal inserts made by this keyboard, not only external edits.
        // Destructive rewrites are independently guarded by host suffix checks.
    }

    override func viewWillDisappear(_ animated: Bool) {
        // Persist at the end of a typing session, not on every space key.
        commitPhraseWord(boundary:"\n")
        flushPhraseLearning()
        finishProSession()
        clearPro6Transient()
        proHistory.clear(); proHangulLast = nil; proHangulDocument = nil
        proSoundPlayer?.stop(); proSoundPlayer = nil
        clearProParticles()
        proWallpaperLayer?.removeFromSuperlayer(); proWallpaperLayer = nil
        themeScheduleTimer?.invalidate(); themeScheduleTimer = nil
        cancelAIRequest()
        closeIntelligenceHub()
        studioEdit = nil
        clearSuggestions()
        flushLearnedWords()
        candidateUpdateWork?.cancel()
        candidateGeneration &+= 1
        glideResultGeneration &+= 1
        super.viewWillDisappear(animated)
    }

    func scheduleLearnedWordsFlush() {
        learnedWordDirty = true
        learnedWordFlushWork?.cancel()
        let job = DispatchWorkItem { [weak self] in
            self?.flushLearnedWords()
        }
        learnedWordFlushWork = job
        DispatchQueue.main.asyncAfter(
            deadline: .now() + .seconds(3), execute: job)
    }

    func flushLearnedWords() {
        learnedWordFlushWork?.cancel()
        learnedWordFlushWork = nil
        guard learnedWordDirty else { return }
        learnedWordDirty = false
        KeyboardSettings.learnedWords = learnedWords
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshTypingPreferences()
        startProSession()
        updateProLayout()
        refreshScheduledTheme(force:true)
        themeScheduleTimer?.invalidate()
        themeScheduleTimer = Timer.scheduledTimer(withTimeInterval:60,repeats:true) { [weak self] _ in
            Task { @MainActor in self?.refreshScheduledTheme() }
        }
        reloadToolbarConfiguration()
        updateAdaptiveLayout()
        updateAdaptiveTouchTargets()
        configureGlideRecognizer()
        if !glideTrailEnabled { hideGlideTrail() }
        updateCoupleTool()
        installWritingActions()
        installClipboardMenu()
        refreshProfileIndicator()
        updateCandidates()
        refreshIdleActions()
        updateContextVisibility()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.layer.sublayers?.first(where: { $0.name == "viepn.aurora" })?.frame = view.bounds
        proWallpaperLayer?.frame = view.bounds
        refreshToolbarLayout()
        if let button = toolbarButtons[.ai] { aiGradient.frame = button.bounds }
        for layer in [glideGlowLayer, glideTrailLayer, glideTipLayer] {
            layer.frame = view.bounds
        }
    }
}
