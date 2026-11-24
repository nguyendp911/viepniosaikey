import UIKit

final class IntelligenceToolCell: UIButton {
    init(title: String, symbol: String, palette: KeyboardThemePalette) {
        super.init(frame: .zero)
        var config = UIButton.Configuration.filled()
        config.title = title
        config.image = UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .medium))
        config.imagePlacement = .top
        config.imagePadding = 4
        config.titleAlignment = .center
        config.titleLineBreakMode = .byTruncatingTail
        config.baseForegroundColor = palette.text
        config.baseBackgroundColor = palette.key
        config.cornerStyle = .fixed
        config.background.cornerRadius = 10
        config.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 4, bottom: 5, trailing: 4)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var result = incoming
            result.font = .systemFont(ofSize: 11, weight: .semibold)
            return result
        }
        configuration = config
        titleLabel?.numberOfLines = 1
        accessibilityLabel = title
        heightAnchor.constraint(equalToConstant: 60).isActive = true
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
}
