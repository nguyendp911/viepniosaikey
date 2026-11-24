import UIKit

final class KeyboardToolbarView: UIView {
    private let scroll = UIScrollView()
    private let row = UIStackView()
    private var heightRule: NSLayoutConstraint!
    private var widthRules: [NSLayoutConstraint] = []
    override init(frame: CGRect) {
        super.init(frame: frame)
        scroll.translatesAutoresizingMaskIntoConstraints = false
        row.translatesAutoresizingMaskIntoConstraints = false
        row.axis = .horizontal
        row.alignment = .fill
        row.distribution = .fill
        scroll.showsHorizontalScrollIndicator = false
        scroll.alwaysBounceHorizontal = false
        addSubview(scroll); scroll.addSubview(row)
        heightRule = heightAnchor.constraint(equalToConstant: 44)
        heightRule.isActive = true
        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: leadingAnchor), scroll.trailingAnchor.constraint(equalTo: trailingAnchor),
            scroll.topAnchor.constraint(equalTo: topAnchor), scroll.bottomAnchor.constraint(equalTo: bottomAnchor),
            row.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            row.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            row.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            row.heightAnchor.constraint(equalTo: scroll.frameLayoutGuide.heightAnchor)
        ])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
    func apply(_ layout: ToolbarLayout, buttons: [ToolbarAction: ToolbarButton]) {
        NSLayoutConstraint.deactivate(widthRules); widthRules = []
        row.arrangedSubviews.forEach { row.removeArrangedSubview($0); $0.removeFromSuperview() }
        row.spacing = CGFloat(layout.spacing)
        heightRule.constant = CGFloat(layout.height)
        for item in layout.items {
            guard let button = buttons[item.action] else { continue }
            row.addArrangedSubview(button)
            widthRules.append(button.widthAnchor.constraint(equalToConstant: CGFloat(item.width)))
        }
        NSLayoutConstraint.activate(widthRules)
        scroll.setContentOffset(.zero, animated: false)
    }
}
