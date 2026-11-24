import UIKit

extension KeyboardViewController {
    func premiumPanel(title:String) -> (UIStackView, KeyboardThemePalette) {
        closeIntelligenceHub()
        let palette = KeyboardThemePalette.resolve(currentTheme)
        let panel = UIView(); panel.backgroundColor = palette.canvas; panel.layer.cornerRadius = 14
        panel.clipsToBounds = true; panel.accessibilityViewIsModal = true; panel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(panel)
        NSLayoutConstraint.activate([panel.leadingAnchor.constraint(equalTo:view.leadingAnchor,constant:4),panel.trailingAnchor.constraint(equalTo:view.trailingAnchor,constant:-4),panel.topAnchor.constraint(equalTo:view.topAnchor,constant:4),panel.bottomAnchor.constraint(equalTo:view.bottomAnchor,constant:-4)])
        intelligenceOverlay = panel
        let stack = UIStackView(); stack.axis = .vertical; stack.spacing = 5; stack.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(stack)
        NSLayoutConstraint.activate([stack.leadingAnchor.constraint(equalTo:panel.leadingAnchor,constant:8),stack.trailingAnchor.constraint(equalTo:panel.trailingAnchor,constant:-8),stack.topAnchor.constraint(equalTo:panel.topAnchor,constant:6),stack.bottomAnchor.constraint(equalTo:panel.bottomAnchor,constant:-6)])
        let header = UIStackView(); header.alignment = .center
        let label = UILabel(); label.text = title; label.textColor = palette.text; label.font = .systemFont(ofSize:17,weight:.bold)
        let close = UIButton(type:.system); close.setImage(UIImage(systemName:"xmark.circle.fill"),for:.normal); close.tintColor = palette.text
        close.accessibilityLabel = "Đóng"; close.widthAnchor.constraint(equalToConstant:44).isActive = true; close.heightAnchor.constraint(equalToConstant:36).isActive = true
        close.addAction(UIAction { [weak self] _ in self?.closeIntelligenceHub() },for:.touchUpInside)
        header.addArrangedSubview(label); header.addArrangedSubview(close); stack.addArrangedSubview(header)
        return (stack,palette)
    }
    func premiumKey(_ title:String, palette:KeyboardThemePalette, action:@escaping ()->Void) -> UIButton {
        let button = UIButton(type:.system)
        var config = UIButton.Configuration.filled(); config.title = title; config.baseForegroundColor = palette.text; config.baseBackgroundColor = palette.key
        config.cornerStyle = .medium; config.contentInsets = NSDirectionalEdgeInsets(top:3,leading:2,bottom:3,trailing:2)
        button.configuration = config; button.titleLabel?.font = .systemFont(ofSize:13,weight:.medium)
        button.addAction(UIAction { _ in action() },for:.touchUpInside); return button
    }
    func openPremiumPalette() {
        let source = premiumSource()
        let (stack,palette) = premiumPanel(title:"ViePN Command")
        let query = UILabel(); query.text = "/"; query.textColor = palette.text; query.font = .monospacedSystemFont(ofSize:15,weight:.medium); query.heightAnchor.constraint(equalToConstant:25).isActive = true
        stack.addArrangedSubview(query)
        let scroll = UIScrollView(); let list = UIStackView(); list.axis = .vertical; list.spacing = 4; list.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(list); NSLayoutConstraint.activate([list.leadingAnchor.constraint(equalTo:scroll.contentLayoutGuide.leadingAnchor),list.trailingAnchor.constraint(equalTo:scroll.contentLayoutGuide.trailingAnchor),list.topAnchor.constraint(equalTo:scroll.contentLayoutGuide.topAnchor),list.bottomAnchor.constraint(equalTo:scroll.contentLayoutGuide.bottomAnchor),list.widthAnchor.constraint(equalTo:scroll.frameLayoutGuide.widthAnchor)])
        stack.addArrangedSubview(scroll)
        var search = ""
        // Closures retain the state only while the panel exists; weak view references avoid cycles.
        let refresh: () -> Void = { [weak self, weak list, weak query] in
            guard let self, let list else { return }
            query?.text = "/"+search
            list.arrangedSubviews.forEach { list.removeArrangedSubview($0); $0.removeFromSuperview() }
            for command in PremiumCommands.search(search) {
                let cell = self.premiumKey("/"+command.id+" · "+command.title,palette:palette) { [weak self] in self?.executePremium(command,source:source) }
                cell.heightAnchor.constraint(equalToConstant:36).isActive = true; list.addArrangedSubview(cell)
            }
            if !KeyboardSettings.privateTypingMode {
                for prompt in PersonalPromptStore.items where search.isEmpty || prompt.title.lowercased().contains(search) {
                    let cell = self.premiumKey("Prompt · "+prompt.title,palette:palette) { [weak self] in self?.closeIntelligenceHub(); self?.runStudio(title:prompt.title,instruction:prompt.instruction,style:true) }
                    cell.heightAnchor.constraint(equalToConstant:36).isActive = true; list.addArrangedSubview(cell)
                }
                for flow in PremiumStore.workflows where search.isEmpty || flow.title.lowercased().contains(search) {
                    let cell = self.premiumKey("Workflow · "+flow.title,palette:palette) { [weak self] in self?.closeIntelligenceHub(); self?.runPremiumAI(title:flow.title,source:source,steps:flow.steps) }
                    cell.heightAnchor.constraint(equalToConstant:36).isActive = true; list.addArrangedSubview(cell)
                }
            }
        }
        for letters in ["qwertyuiop","asdfghjkl","zxcvbnm"] {
            let row = UIStackView(); row.distribution = .fillEqually; row.spacing = 3
            for ch in letters {
                row.addArrangedSubview(premiumKey(String(ch),palette:palette) { if search.count < 30 { search.append(ch); refresh() } })
            }
            if letters == "zxcvbnm" { row.addArrangedSubview(premiumKey("⌫",palette:palette) { if !search.isEmpty { search.removeLast(); refresh() } }) }
            row.heightAnchor.constraint(equalToConstant:30).isActive = true; stack.addArrangedSubview(row)
        }
        refresh()
    }
    func openPremiumCalculator() {
        let source = premiumSource()
        let (stack,palette) = premiumPanel(title:"Máy tính offline")
        let label = UILabel(); label.textColor = palette.text; label.textAlignment = .right; label.font = .monospacedDigitSystemFont(ofSize:25,weight:.medium); label.adjustsFontSizeToFitWidth = true
        stack.addArrangedSubview(label)
        var expression = (try? PremiumCalculator.evaluate(source)) != nil ? source : ""
        label.text = expression.isEmpty ? "0" : expression
        for keys in [["7","8","9","÷","⌫"],["4","5","6","×","("],["1","2","3","−",")"],["0",".","+","C","="]] {
            let row = UIStackView(); row.distribution = .fillEqually; row.spacing = 4
            for key in keys {
                row.addArrangedSubview(premiumKey(key,palette:palette) { [weak label] in
                    if key == "C" { expression = "" }
                    else if key == "⌫" { if !expression.isEmpty { expression.removeLast() } }
                    else if key == "=" { if let result = try? PremiumCalculator.evaluate(expression) { expression = result } else { label?.text = "Biểu thức không hợp lệ"; return } }
                    else if expression.count < 120 { expression += key == "−" ? "-" : key }
                    label?.text = expression.isEmpty ? "0" : expression
                })
            }
            row.heightAnchor.constraint(equalToConstant:35).isActive = true; stack.addArrangedSubview(row)
        }
        stack.addArrangedSubview(premiumKey("Xem trước kết quả để chèn",palette:palette) { [weak self] in
            guard let self else { return }
            guard let result = try? PremiumCalculator.evaluate(expression) else { label.text = "Biểu thức không hợp lệ"; return }
            self.closeIntelligenceHub(); self.show([ReplySuggestion(tone:"Kết quả",text:result)])
        })
    }
}
