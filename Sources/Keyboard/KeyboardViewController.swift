import UIKit
import AudioToolbox
import Vision

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
    var toolButtons: [UIButton] = []
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
    var learnedWordFlushWork: DispatchWorkItem?
    var learnedWordDirty = false
    var recentWord = ""
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
        let words = OfflineSentenceSuggestions.nextWords(after: anchor, language: bilingualPreference.rawValue)
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
        useSuggestions = KeyboardSettings.predictionsEnabled && !performanceMode
        useGlide = KeyboardSettings.glideEnabled && !performanceMode
        glideTrailEnabled = KeyboardSettings.glideTrailEnabled && !performanceMode
        adaptiveTouchEnabled = KeyboardSettings.adaptiveTouchEnabled
        let privateMode = KeyboardSettings.privateTypingMode
        learnedWords = privateMode ? [:] : KeyboardSettings.learnedWords
        glideLearningEnabled = KeyboardSettings.glideLearningEnabled && !privateMode
        glideUsageCounts = privateMode ? [:] : KeyboardSettings.glideUsageCounts
        cachedSnippets = KeyboardSettings.textSnippets
        cachedReplacements = KeyboardSettings.replacementDictionary
        autocapitalizeEnabled = KeyboardSettings.autoCapitalize
        learnWordsEnabled = KeyboardSettings.autoLearnWords && !performanceMode && !KeyboardSettings.privateTypingMode
    }
    var currentTheme: String = ""
    let aiGradient = CAGradientLayer()

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
        if currentTheme != KeyboardSettings.theme { applyTheme() }
        // Do not reset composition here: iOS may call textDidChange for
        // normal inserts made by this keyboard, not only external edits.
        // Destructive rewrites are independently guarded by host suffix checks.
    }

    override func viewWillDisappear(_ animated: Bool) {
        // Persist at the end of a typing session, not on every space key.
        cancelAIRequest()
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
        applyTheme()
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
        if toolButtons.count > 2 { aiGradient.frame = toolButtons[2].bounds }
        for layer in [glideGlowLayer, glideTrailLayer, glideTipLayer] {
            layer.frame = view.bounds
        }
    }
}
