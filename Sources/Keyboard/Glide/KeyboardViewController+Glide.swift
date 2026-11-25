import UIKit
import AudioToolbox
import Vision

extension KeyboardViewController {
    func letterUnder(_ position: CGPoint) -> String? {
        // Sample the nearest visible letter inside a small gutter around a
        // key. A finger rarely passes through exact button center points.
        var best: (distance: CGFloat, name: String)?
        for key in letterButtons where !key.isHidden {
            let rect = key.convert(key.bounds, to: view)
            guard rect.insetBy(dx: -7, dy: -7).contains(position),
                  let name = key.title(for: .normal), name.count == 1 else {
                continue
            }
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let dx = center.x - position.x
            let dy = center.y - position.y
            let distance = dx * dx + dy * dy
            if best == nil || distance < best!.distance {
                best = (distance, name.lowercased())
            }
        }
        return best?.name
    }

    func captureGlidePoint(_ position: CGPoint) {
        guard let key = letterUnder(position), key != glideLastKey else { return }
        glideLastKey = key
        glidePath += key
    }

    func captureGlideSegment(to point: CGPoint) {
        guard let previous = glideLastPoint else {
            captureGlidePoint(point)
            glideLastPoint = point
            return
        }
        let dx = point.x - previous.x
        let dy = point.y - previous.y
        let distance = hypot(dx, dy)
        glideTravelDistance += distance
        // 10-point sampling is sufficient for key centers (~35-45pt), while
        // bounded work prevents huge UIKit hit-test loops during fast swipes.
        let steps = max(1, min(24, Int(ceil(distance / 10))))
        for index in 1...steps {
            let t = CGFloat(index) / CGFloat(steps)
            captureGlidePoint(CGPoint(x: previous.x + dx * t,
                                     y: previous.y + dy * t))
        }
        glideLastPoint = point
    }

    func installGlideTrailLayers() {
        // Draw above key caps, below no touch target: CAShapeLayer cannot
        // intercept UIKit events. Two strokes produce a soft neon track.
        for layer in [glideGlowLayer, glideTrailLayer, glideTipLayer] {
            layer.frame = view.bounds
            layer.opacity = 0
            layer.fillColor = UIColor.clear.cgColor
            view.layer.addSublayer(layer)
        }
        glideGlowLayer.strokeColor = cyanColor.withAlphaComponent(0.27).cgColor
        glideGlowLayer.lineWidth = 13
        glideGlowLayer.lineCap = .round
        glideGlowLayer.lineJoin = .round
        glideTrailLayer.strokeColor = cyanColor.withAlphaComponent(0.95).cgColor
        glideTrailLayer.lineWidth = 4.5
        glideTrailLayer.lineCap = .round
        glideTrailLayer.lineJoin = .round
        glideTrailLayer.shadowColor = cyanColor.cgColor
        glideTrailLayer.shadowOpacity = 0.55
        glideTrailLayer.shadowRadius = 5
        glideTrailLayer.shadowOffset = .zero
        glideTipLayer.fillColor = UIColor.white.cgColor
        glideTipLayer.shadowColor = cyanColor.cgColor
        glideTipLayer.shadowOpacity = 0.95
        glideTipLayer.shadowRadius = 8
        glideTipLayer.shadowOffset = .zero
    }

    func startGlideTrail(at point: CGPoint) {
        guard glideTrailEnabled else { return }
        for layer in [glideGlowLayer, glideTrailLayer, glideTipLayer] {
            layer.removeAllAnimations()
            layer.opacity = 1
        }
        glideTrailPath = UIBezierPath()
        glideTrailPath.move(to: point)
        glideTrailPointCount = 0
        drawGlideTrail(to: point)
    }

    func drawGlideTrail(to point: CGPoint) {
        guard glideTrailEnabled, glideTrailPointCount < 180 else { return }
        let now = CACurrentMediaTime()
        // Limit Core Animation path/shadow updates to one per display frame.
        guard now - lastGlideDrawTime >= 1.0 / 60.0 else { return }
        lastGlideDrawTime = now
        glideTrailPointCount += 1
        glideTrailPath.addLine(to: point)
        // Avoid implicit Core Animation transitions on every finger move.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let path = glideTrailPath.cgPath
        glideGlowLayer.path = path
        glideTrailLayer.path = path
        glideTipLayer.path = UIBezierPath(
            ovalIn: CGRect(x: point.x - 5.5, y: point.y - 5.5,
                           width: 11, height: 11)).cgPath
        CATransaction.commit()
    }

    func finishGlideTrail() {
        guard glideTrailEnabled else { return }
        for layer in [glideGlowLayer, glideTrailLayer, glideTipLayer] {
            layer.removeAllAnimations()
            let fade = CABasicAnimation(keyPath: "opacity")
            fade.fromValue = layer.presentation()?.opacity ?? 1
            fade.toValue = 0
            fade.duration = 0.24
            fade.timingFunction = CAMediaTimingFunction(name: .easeOut)
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            layer.opacity = 0
            CATransaction.commit()
            layer.add(fade, forKey: "glideFade")
        }
    }

    func hideGlideTrail() {
        for layer in [glideGlowLayer, glideTrailLayer, glideTipLayer] {
            layer.removeAllAnimations()
            layer.opacity = 0
        }
    }

    func configureGlideRecognizer() {
        if glideRecognizer == nil {
            let pan = UIPanGestureRecognizer(target: self,
                                             action: #selector(glidePanned(_:)))
            pan.minimumNumberOfTouches = 1
            pan.maximumNumberOfTouches = 1
            pan.cancelsTouchesInView = false
            pan.delaysTouchesBegan = false
            pan.delegate = self
            view.addGestureRecognizer(pan)
            glideRecognizer = pan
        }
        glideRecognizer?.isEnabled = useGlide && !isNumbers
        if !useGlide || isNumbers { hideGlideTrail() }
    }

    @objc func glidePanned(_ recognizer: UIPanGestureRecognizer) {
        guard useGlide, !isNumbers else { return }
        let point = recognizer.location(in: view)
        switch recognizer.state {
        case .began:
            isComposingInteraction = true
            updateContextVisibility()
            glideResultGeneration &+= 1
            glidePath = ""
            glideLastKey = ""
            glideIsActive = false
            glideTravelDistance = 0
            let origin = glideTouchOrigin ?? point
            glideLastPoint = origin
            captureGlidePoint(origin)
            captureGlideSegment(to: point)
            startGlideTrail(at: origin)
            drawGlideTrail(to: point)
        case .changed:
            captureGlideSegment(to: point)
            drawGlideTrail(to: point)
            if glidePath.count >= 2 { glideIsActive = true }
        case .ended:
            captureGlideSegment(to: point)
            drawGlideTrail(to: point)
            finishGlideTrail()
            let trace = glidePath
            let isWordSwipe = SmartTyping.isIntentionalGlide(
                trace: trace, travelPoints: Double(glideTravelDistance),
                keyHeight: Double(KeyboardSettings.keyHeight))
            glidePath = ""
            glideLastKey = ""
            glideIsActive = false
            glideTravelDistance = 0
            glideTouchOrigin = nil
            glideLastPoint = nil
            guard isWordSwipe else { return }
            let personalWords = learnedWords.merging(customWords, uniquingKeysWith: max)
            let usageCounts = glideLearningEnabled ? glideUsageCounts : [:]
            let language = useSmartBilingual ? bilingualPreference.rawValue : "vi"
            let swipeDocument=textDocumentProxy.documentIdentifier
            let swipeBefore=textDocumentProxy.documentContextBeforeInput ?? ""
            let currentToken=String(swipeBefore.reversed().prefix(while:{$0.isLetter}).reversed())
            let context=String(swipeBefore.dropLast(currentToken.count))
            let phraseSnapshot=learnWordsEnabled && !proPrivate ? phraseModel : PersonalPhraseModel()
            let allowPhraseGlide=typingPro6.sentenceGlide && language != "en"
            let generation = glideResultGeneration
            let touchCount = typingTouchCount
            // Edit-distance scoring runs off the touch-critical main thread.
            glideRecognitionQueue.async { [weak self] in
                let original = SmartTyping.glideCandidates(
                    trace: trace, learned: personalWords, language: language, limit: 12)
                let preferred=phraseSnapshot.suggestions(context:PersonalPhraseModel.context(context),limit:5).compactMap{$0.split(separator:" ").first.map(String.init)}
                let ranked=preferred.filter{original.contains($0)}
                let suggestions=ranked+original.filter{!ranked.contains($0)}
                let complete = SmartTyping.glideOptions(
                    suggestions, language: language, usage: usageCounts, showAll: true)
                let display = SmartTyping.glideOptions(
                    suggestions, language: language, usage: usageCounts)
                // Explicit phrase candidates only; keep single-word recognizer
                // and automatic commitment unchanged.
                let phraseOptions=allowPhraseGlide ? TypingProGlide.phrases(trace:trace,model:phraseSnapshot) : []
                DispatchQueue.main.async { [weak self] in
                    guard let self,
                          self.glideResultGeneration == generation,
                          self.typingTouchCount == touchCount,
                          self.textDocumentProxy.documentIdentifier==swipeDocument,
                          (self.textDocumentProxy.documentContextBeforeInput ?? "")==swipeBefore else { return }
                    guard !display.isEmpty else {
                        self.showStatus("Chưa nhận diện được từ · Thử vuốt chậm hơn")
                        return
                    }
                    // Keep swipe options visible whether general predictions
                    // are enabled or not; these are separate user features.
                    self.isGlideSuggestionVisible = true
                    self.isComposingInteraction = true
                    self.updateContextVisibility()
                    let before = self.textDocumentProxy.documentContextBeforeInput ?? ""
                    let current = String(before.reversed()
                        .prefix(while: { $0.isLetter }).reversed())
                    let initial = String(trace.prefix(1))
                    if current.lowercased() == initial,
                       SmartTyping.glideStartsWithPhysicalKey(
                           display[0], key: initial) {
                        // touchDown already inserted the first letter.
                        // Replace just that letter with the recognized word.
                        self.replaceCurrentWord(display[0])
                        self.commitPhraseWord(boundary:" ")
                        self.textDocumentProxy.insertText(" ")
                        self.knownWordBoundary = true
                        self.resetBilingualComposition()
                        self.pendingGlideWord = display[0]
                        self.pro6GlideDocument=self.textDocumentProxy.documentIdentifier
                        self.pro6GlideAnchor=self.textDocumentProxy.documentContextBeforeInput
                        self.fullGlideOptions = complete+phraseOptions.filter{!complete.contains($0)}
                        self.recentWord = ""
                        self.updateCandidates(display+phraseOptions.filter{!display.contains($0)})
                    } else {
                        // Never overwrite an existing draft or a changed caret.
                        // Still show choices if the text was modified by
                        // iOS or a host app during the gesture.
                        self.updateCandidates(display)
                    }
                }
            }
        default:
            glidePath = ""
            glideLastKey = ""
            glideIsActive = false
            glideTravelDistance = 0
            glideTouchOrigin = nil
            glideLastPoint = nil
            hideGlideTrail()
        }
    }
}
