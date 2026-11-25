import UIKit
import AudioToolbox
import Vision

extension KeyboardViewController {
    func buildKeyboard() {
        view.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.11, green: 0.13, blue: 0.20, alpha: 1)
                : UIColor(red: 0.89, green: 0.92, blue: 0.97, alpha: 1)
        }
        heightConstraint = view.heightAnchor.constraint(equalToConstant: 240)
        heightConstraint?.priority = .defaultHigh
        heightConstraint?.isActive = true
        container.axis = .vertical
        container.spacing = 6
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)
        keyboardLeadingConstraint = container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4)
        keyboardTrailingConstraint = container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4)
        NSLayoutConstraint.activate([
            keyboardLeadingConstraint!,
            keyboardTrailingConstraint!,
            container.topAnchor.constraint(equalTo: view.topAnchor, constant: 5),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -4)
        ])

        statusLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        statusLabel.textColor = .secondaryLabel
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 1
        statusLabel.lineBreakMode = .byTruncatingTail
        statusLabel.text = "✦ ViePN AI · Viết hay hơn, gửi nhanh hơn"
        statusLabel.isHidden = true
        container.addArrangedSubview(statusLabel)

        buildToolbar()

        previewLabel.numberOfLines = 2
        previewLabel.font = .systemFont(ofSize: 14, weight: .medium)
        previewLabel.textColor = .label
        previewLabel.textAlignment = .left
        previewLabel.backgroundColor = .secondarySystemBackground
        previewLabel.layer.cornerRadius = 12
        previewLabel.layer.borderWidth = 1
        previewLabel.layer.borderColor = UIColor.separator.withAlphaComponent(0.4).cgColor
        previewLabel.clipsToBounds = true
        previewLabel.isHidden = true
        previewLabel.heightAnchor.constraint(equalToConstant: 45).isActive = true
        container.addArrangedSubview(previewLabel)

        candidateBar.axis = .horizontal
        candidateBar.spacing = 6
        candidateBar.distribution = .fill
        candidateBar.alignment = .fill
        // Scroll horizontally: all six tone choices remain accessible on a
        // compact iPhone without shrinking each chip to unreadable text.
        candidateScroll.showsHorizontalScrollIndicator = false
        candidateScroll.alwaysBounceHorizontal = true
        candidateScroll.backgroundColor = .clear
        candidateScroll.isHidden = !useSuggestions
        candidateScroll.heightAnchor.constraint(equalToConstant: 35).isActive = true
        candidateScroll.addSubview(candidateBar)
        candidateBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            candidateBar.leadingAnchor.constraint(equalTo: candidateScroll.contentLayoutGuide.leadingAnchor),
            candidateBar.trailingAnchor.constraint(equalTo: candidateScroll.contentLayoutGuide.trailingAnchor),
            candidateBar.topAnchor.constraint(equalTo: candidateScroll.contentLayoutGuide.topAnchor),
            candidateBar.bottomAnchor.constraint(equalTo: candidateScroll.contentLayoutGuide.bottomAnchor),
            candidateBar.heightAnchor.constraint(equalTo: candidateScroll.frameLayoutGuide.heightAnchor)
        ])
        // Both modes occupy exactly the same persistent slot.
        contextSlot.translatesAutoresizingMaskIntoConstraints = false
        contextSlot.heightAnchor.constraint(equalToConstant: 46).isActive = true
        contextSlot.addSubview(candidateScroll)
        candidateScroll.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            candidateScroll.leadingAnchor.constraint(equalTo: contextSlot.leadingAnchor),
            candidateScroll.trailingAnchor.constraint(equalTo: contextSlot.trailingAnchor),
            candidateScroll.centerYAnchor.constraint(equalTo: contextSlot.centerYAnchor)
        ])
        idleScroll.showsHorizontalScrollIndicator = false
        idleScroll.alwaysBounceHorizontal = true
        idleScroll.translatesAutoresizingMaskIntoConstraints = false
        contextSlot.addSubview(idleScroll)
        NSLayoutConstraint.activate([
            idleScroll.leadingAnchor.constraint(equalTo: contextSlot.leadingAnchor),
            idleScroll.trailingAnchor.constraint(equalTo: contextSlot.trailingAnchor),
            idleScroll.topAnchor.constraint(equalTo: contextSlot.topAnchor),
            idleScroll.bottomAnchor.constraint(equalTo: contextSlot.bottomAnchor)
        ])
        idleBar.axis = .horizontal
        idleBar.spacing = 6
        idleBar.alignment = .center
        idleBar.distribution = .fill
        idleBar.translatesAutoresizingMaskIntoConstraints = false
        idleScroll.addSubview(idleBar)
        NSLayoutConstraint.activate([
            idleBar.leadingAnchor.constraint(equalTo: idleScroll.contentLayoutGuide.leadingAnchor, constant: 4),
            idleBar.trailingAnchor.constraint(equalTo: idleScroll.contentLayoutGuide.trailingAnchor, constant: -4),
            idleBar.topAnchor.constraint(equalTo: idleScroll.contentLayoutGuide.topAnchor),
            idleBar.bottomAnchor.constraint(equalTo: idleScroll.contentLayoutGuide.bottomAnchor),
            idleBar.heightAnchor.constraint(equalTo: idleScroll.frameLayoutGuide.heightAnchor)
        ])
        container.addArrangedSubview(contextSlot)
        refreshIdleActions()
        updateContextVisibility()

        installProNumberRow()
        let rows = ["qwertyuiop", "asdfghjkl", "zxcvbnm"]
        for (rowIndex, letters) in rows.enumerated() {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = CGFloat(KeyboardSettings.keySpacing)
            row.alignment = .fill
            row.distribution = .fillEqually
            if rowIndex == 1 {
                row.layoutMargins = UIEdgeInsets(top: 0, left: 19, bottom: 0, right: 19)
                row.isLayoutMarginsRelativeArrangement = true
            }
            if rowIndex == 2 {
                let shift = keyButton("", action: #selector(shiftTapped))
                configureIconOnly(shift, symbol: "shift.fill")
                styleModifier(shift)
                row.addArrangedSubview(shift)
            }
            for letter in letters {
                let key = keyButton(String(letter), action: #selector(letterTapped(_:)))
                // Register on first touch, not touch-up, for immediate visual
                // text feedback when typing quickly.
                key.removeTarget(self, action: #selector(letterTapped(_:)), for: .touchUpInside)
                key.addTarget(self, action: #selector(letterTapped(_:)), for: .touchDown)
                installProKeyGesture(key)
                letterButtons.append(key)
                row.addArrangedSubview(key)
            }
            if rowIndex == 2 {
                let delete = keyButton("", action: #selector(deleteTapped))
                configureIconOnly(delete, symbol: "delete.left")
                styleModifier(delete)
                let gesture = UILongPressGestureRecognizer(target: self, action: #selector(deleteWordGesture(_:)))
                gesture.minimumPressDuration = 0.45
                delete.addGestureRecognizer(gesture)
                let deletePan=UIPanGestureRecognizer(target:self,action:#selector(pro6DeletePanned(_:)))
                deletePan.isEnabled=typingPro6.backspacePan
                deletePan.maximumNumberOfTouches=1
                delete.addGestureRecognizer(deletePan)
                pro6DeletePanRecognizer=deletePan
                delete.accessibilityHint = "Nhấn giữ để xóa từ"
                row.addArrangedSubview(delete)
            }
            let height = row.heightAnchor.constraint(equalToConstant: CGFloat(KeyboardSettings.keyHeight))
            height.isActive = true
            keyHeightConstraints.append(height)
            letterRows.append(row)
            container.addArrangedSubview(row)
        }

        // Large spacebar, separate punctuation, globe and return as in iOS.
        let bottom = UIStackView()
        bottom.axis = .horizontal
        bottom.spacing = CGFloat(KeyboardSettings.keySpacing)
        bottom.distribution = .fill
        bottom.alignment = .fill

        let numeric = keyButton("123", action: #selector(numbersTapped))
        let globe = keyButton("", action: #selector(globeTapped))
        configureIconOnly(globe, symbol: "globe", size: 20)
        let comma = keyButton(",", action: #selector(punctuationTapped(_:)))
        let space = keyButton("dấu cách", action: #selector(spaceTapped))
        let cursorPan = UIPanGestureRecognizer(target: self, action: #selector(spaceCursorPanned(_:)))
        cursorPan.cancelsTouchesInView = true
        space.addGestureRecognizer(cursorPan)
        space.accessibilityHint = "Vuốt ngang để di chuyển con trỏ"
        let period = keyButton(".", action: #selector(punctuationTapped(_:)))
        let enter = keyButton("", action: #selector(returnTapped))
        configureIconOnly(enter, symbol: "return.left", size: 20)
        for key in [numeric, globe, comma, period] { styleModifier(key) }
        enter.backgroundColor = UIColor(red: 0.29, green: 0.54, blue: 0.98, alpha: 1)
        enter.setTitleColor(.white, for: .normal)
        enter.tintColor = .white
        for key in [numeric, globe, comma, space, period, enter] { bottom.addArrangedSubview(key) }
        numeric.widthAnchor.constraint(equalToConstant: 44).isActive = true
        globe.widthAnchor.constraint(equalToConstant: 40).isActive = true
        comma.widthAnchor.constraint(equalToConstant: 34).isActive = true
        period.widthAnchor.constraint(equalToConstant: 34).isActive = true
        enter.widthAnchor.constraint(equalToConstant: 48).isActive = true
        let bottomHeight = bottom.heightAnchor.constraint(equalToConstant: CGFloat(KeyboardSettings.keyHeight))
        bottomHeight.isActive = true
        keyHeightConstraints.append(bottomHeight)
        proSpaceWidth = space.widthAnchor.constraint(greaterThanOrEqualToConstant: 90)
        proSpaceWidth?.priority = .defaultHigh
        secondaryRow = bottom
        container.addArrangedSubview(bottom)
        // Install once regardless of the setting's initial value. A user
        // enabling swipe later must not need a fresh keyboard controller.
        configureGlideRecognizer()
        installGlideTrailLayers()
        updateProLayout()
        updateKeys()
        updateAdaptiveLayout()
        updateAdaptiveTouchTargets()
        updateKeyboardHeight()
    }

    func keyButton(_ title: String, action: Selector) -> UIButton {
        let button = AdaptiveKeyButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 21, weight: .regular)
        button.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(white: 0.31, alpha: 1) : .white
        }
        button.layer.cornerRadius = 10
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.08
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.layer.shadowRadius = 1
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.7
        button.addTarget(self, action: action, for: .touchUpInside)
        // All regular keys share the same optional tap effect (letters,
        // punctuation, space, delete and return) without extra subviews.
        button.addTarget(self, action: #selector(keypressAnimationTapped(_:)),
                         for: .touchDown)
        return button
    }

    /// Symbol + label typography is controlled through UIKit button configuration.
    /// This keeps the icon inside the actual tappable button (no overlay hit testing).
    func configureSymbolButton(_ button: UIButton, title: String, symbol: String,
                                       foreground: UIColor, background: UIColor) {
        var config = UIButton.Configuration.plain()
        config.title = title
        config.image = UIImage(systemName: symbol,
                               withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold))
                    ?? UIImage(systemName: "circle.fill")
        config.imagePlacement = .leading
        config.imagePadding = 5
        config.contentInsets = NSDirectionalEdgeInsets(top: 7, leading: 4, bottom: 7, trailing: 4)
        config.baseForegroundColor = foreground
        config.background.backgroundColor = background
        config.cornerStyle = .medium
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var result = incoming
            result.font = .systemFont(ofSize: 11, weight: .semibold)
            return result
        }
        button.configuration = config
        button.accessibilityLabel = title
    }

    func configureIconOnly(_ button: UIButton, symbol: String, size: CGFloat = 19) {
        button.setTitle(nil, for: .normal)
        let image = UIImage(systemName: symbol, withConfiguration:
            UIImage.SymbolConfiguration(pointSize: size, weight: .medium))
        button.setImage(image, for: .normal)
        button.tintColor = .label
        button.imageView?.contentMode = .scaleAspectFit
    }

    func styleModifier(_ button: UIButton) {
        button.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(white: 0.24, alpha: 1)
                : UIColor(red: 0.66, green: 0.70, blue: 0.76, alpha: 1)
        }
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
    }

    func makeRow(_ actions: [(String, Selector)], height: CGFloat) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.distribution = .fillEqually
        row.spacing = 4
        for (title, action) in actions {
            let button = keyButton(title, action: action)
            button.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
            row.addArrangedSubview(button)
        }
        row.heightAnchor.constraint(equalToConstant: height).isActive = true
        return row
    }

    func applyTheme() {
        scheduledBaseTheme = KeyboardSettings.theme
        scheduledTheme = ThemeSchedule.effective()
        currentTheme = scheduledTheme
        let palette = KeyboardThemePalette.resolve(currentTheme)
        let canvas = palette.canvas
        let keyColor = palette.key
        let primary = palette.text
        let modifier = palette.modifier
        view.backgroundColor = canvas
        applyCustomDesign()
        applyPersonalThemeBackdrop()
        for button in letterButtons {
            button.backgroundColor = keyColor
            button.setTitleColor(primary, for: .normal)
        }
        for row in letterRows {
            for case let button as UIButton in row.arrangedSubviews where !letterButtons.contains(button) {
                button.backgroundColor = modifier
                button.setTitleColor(primary, for: .normal)
                button.tintColor = primary
            }
        }
        if let bottom = secondaryRow {
            for (index, item) in bottom.arrangedSubviews.enumerated() {
                guard let button = item as? UIButton, index != bottom.arrangedSubviews.count - 1 else { continue }
                button.backgroundColor = index == 3 ? keyColor : modifier
                button.setTitleColor(primary, for: .normal)
                button.tintColor = primary
            }
        }
        applyProVisuals()
        applyToolbarAppearance()
        refreshSuggestionAppearance()
        previewLabel.backgroundColor = keyColor
        previewLabel.textColor = primary
        statusLabel.textColor = primary
    }

    func updateKeys() {
        let rows = isNumbers
            ? ["1234567890", "@#$%&*()-", "/:;!?.,"] : offlineConfig.layout.rows(shift: isUppercase, custom: offlineConfig.customRows)
        for (rowIndex, row) in letterRows.enumerated() {
            let arranged = row.arrangedSubviews.compactMap { $0 as? UIButton }
            // Row 3 reserves first and last keys for Shift and Delete.
            let letterKeys = rowIndex == 2 ? Array(arranged.dropFirst().dropLast()) : arranged
            let characters = Array(rows[rowIndex]).map(String.init)
            for (index, button) in letterKeys.enumerated() {
                if index < characters.count {
                    let ch = characters[index]
                    button.setTitle(isNumbers ? ch : (isUppercase && offlineConfig.layout.latin ? ch.uppercased() : ch), for: .normal)
                    button.isHidden = false
                } else {
                    button.isHidden = true
                }
            }
            if rowIndex == 2, let shift = arranged.first {
                configureIconOnly(shift, symbol: isShiftLocked ? "capslock.fill" : "shift.fill")
            }
        }
        if let bottom = secondaryRow, let numeric = bottom.arrangedSubviews.first as? UIButton {
            numeric.setTitle(isNumbers ? "ABC" : "123", for: .normal)
        }
    }

    func updateAdaptiveLayout() {
        let spacing = CGFloat(KeyboardSettings.keySpacing)
        let height = CGFloat(KeyboardSettings.keyHeight)
        for row in letterRows { row.spacing = spacing }
        secondaryRow?.spacing = spacing
        for constraint in keyHeightConstraints { constraint.constant = height }
        proNumberRow?.spacing = spacing
        let side = min(56, max(38, view.bounds.width * 0.12))
        switch KeyboardSettings.oneHandMode {
        case "left":
            keyboardLeadingConstraint?.constant = 4
            keyboardTrailingConstraint?.constant = -side
        case "right":
            keyboardLeadingConstraint?.constant = side
            keyboardTrailingConstraint?.constant = -4
        default:
            keyboardLeadingConstraint?.constant = 4
            keyboardTrailingConstraint?.constant = -4
        }
        updateKeyboardHeight()
    }

    func updateAdaptiveTouchTargets() {
        // Cover only the empty gutter between adjacent keys. No key changes
        // another key's label or steals touches from its visible bounds.
        let width = adaptiveTouchEnabled
            ? CGFloat(min(4, KeyboardSettings.keySpacing / 2)) : 0
        for button in letterButtons {
            (button as? AdaptiveKeyButton)?.horizontalHitExpansion = premiumPreferences.dynamicTouch ? min(width, 1) : width
            if let adaptive=button as? AdaptiveKeyButton {
                let title=button.title(for:.normal)?.lowercased() ?? ""
                adaptive.calibrationOffset = typingPro6.touchCalibration && adaptiveTouchEnabled && !proPrivate ? CGFloat(pro6TouchOffsets[title] ?? 0) : 0
            }
        }
    }

    func updateKeyboardHeight() {
        // No permanently reserved blank AI area.
        let base: CGFloat = 240 + CGFloat(KeyboardSettings.keyHeight - 43) * 4
        heightConstraint?.constant = base + 61 + CGFloat(lastToolbarLayout?.height ?? 44) - 37 - 14 +
            (offlineConfig.numberRow ? 38 : 0) +
            (statusLabel.isHidden ? 0 : 22) +
            (suggestionContainer == nil ? 0 : 127)
        view.setNeedsLayout()
    }
}
