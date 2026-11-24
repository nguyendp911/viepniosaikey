import UIKit

final class ToolbarButton: UIButton {
    let action: ToolbarAction
    private let personaDot = UIView()
    init(action: ToolbarAction) {
        self.action = action
        super.init(frame: .zero)
        accessibilityLabel = action.title
        personaDot.backgroundColor = UIColor(red: 0.42, green: 0.94, blue: 0.71, alpha: 1)
        personaDot.layer.cornerRadius = 3
        personaDot.isUserInteractionEnabled = false
        personaDot.isHidden = true
        personaDot.translatesAutoresizingMaskIntoConstraints = false
        addSubview(personaDot)
        NSLayoutConstraint.activate([
            personaDot.widthAnchor.constraint(equalToConstant: 6), personaDot.heightAnchor.constraint(equalToConstant: 6),
            personaDot.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            personaDot.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5)
        ])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
    func setPersonaIndicator(_ active: Bool) { personaDot.isHidden = !active }
    func render(presentation: ToolbarPresentation, palette: KeyboardThemePalette, radius: Int, coupleActive: Bool) {
        let colors = ToolbarAppearance.colors(action, palette: palette, coupleActive: coupleActive)
        var config = UIButton.Configuration.filled()
        config.title = presentation == .icon ? nil : (action == .ai && presentation == .stacked ? "AI" : action.title)
        config.image = UIImage(systemName: action == .couple && coupleActive ? "heart.fill" : action.symbol,
                              withConfiguration: UIImage.SymbolConfiguration(pointSize: presentation == .icon ? 19 : 15, weight: .semibold))
        config.imagePlacement = presentation == .stacked ? .top : .leading
        config.imagePadding = 4
        config.titleAlignment = .center
        config.titleLineBreakMode = .byTruncatingTail
        config.contentInsets = NSDirectionalEdgeInsets(top: 3, leading: 3, bottom: 3, trailing: 3)
        config.cornerStyle = .fixed
        config.background.cornerRadius = CGFloat(radius)
        config.baseForegroundColor = colors.0
        config.baseBackgroundColor = colors.1
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: presentation == .stacked ? 10 : 12, weight: .semibold)
            return outgoing
        }
        configuration = config
        titleLabel?.numberOfLines = 1
        titleLabel?.lineBreakMode = .byTruncatingTail
        bringSubviewToFront(personaDot)
    }
}
