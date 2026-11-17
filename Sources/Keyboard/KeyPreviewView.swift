import UIKit

/// The enlarged letter that pops up above a key while it is held down, like the
/// system keyboard. One reusable view: shown on touch down, hidden on touch up.
/// It is a single shape layer with an explicit shadow path, so it costs almost
/// nothing per touch.
final class KeyPreviewView: UIView {
    private let shape = CAShapeLayer()
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        isHidden = true
        shape.shadowColor = UIColor.black.cgColor
        shape.shadowOpacity = 0.30
        shape.shadowRadius = 6
        shape.shadowOffset = CGSize(width: 0, height: 2)
        shape.lineWidth = 0.5
        layer.addSublayer(shape)
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 34, weight: .regular)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        addSubview(label)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Dark keys get a lighter bubble so it stands out from the keys around it.
    private static func bubbleColor(from base: UIColor) -> (fill: UIColor, hairline: UIColor) {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        guard base.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return (base, .clear)
        }
        let luminance = 0.299 * red + 0.587 * green + 0.114 * blue
        guard luminance < 0.5 else { return (base, UIColor.black.withAlphaComponent(0.06)) }
        let amount: CGFloat = 0.24
        let lifted = UIColor(red: red + (1 - red) * amount,
                             green: green + (1 - green) * amount,
                             blue: blue + (1 - blue) * amount, alpha: alpha)
        return (lifted, UIColor.white.withAlphaComponent(0.14))
    }

    /// `keyFrame` and `container` are in the coordinates of the view this one
    /// is added to. The bubble sits above the key and flares smoothly into it.
    func show(text: String, keyFrame: CGRect, container: CGRect,
              fill: UIColor, textColor: UIColor) {
        let radius: CGFloat = 10
        let keyRadius: CGFloat = 8
        let bubbleHeight = max(46, keyFrame.height * 1.1)
        let bubbleWidth = min(keyFrame.width + 28, container.width - 8)
        var bubbleX = keyFrame.midX - bubbleWidth / 2
        bubbleX = min(max(bubbleX, container.minX + 2), container.maxX - bubbleWidth - 2)
        let x0 = min(bubbleX, keyFrame.minX)
        let x1 = max(bubbleX + bubbleWidth, keyFrame.maxX)
        let top = keyFrame.minY - bubbleHeight + 4
        let neckStart = keyFrame.minY - 8
        let neckEnd = keyFrame.minY + 8
        let neck = neckEnd - neckStart
        let kx0 = keyFrame.minX
        let kx1 = keyFrame.maxX
        let bottom = keyFrame.maxY

        let path = UIBezierPath()
        path.move(to: CGPoint(x: x0 + radius, y: top))
        path.addLine(to: CGPoint(x: x1 - radius, y: top))
        path.addArc(withCenter: CGPoint(x: x1 - radius, y: top + radius), radius: radius,
                    startAngle: -.pi / 2, endAngle: 0, clockwise: true)
        path.addLine(to: CGPoint(x: x1, y: neckStart))
        path.addCurve(to: CGPoint(x: kx1, y: neckEnd),
                      controlPoint1: CGPoint(x: x1, y: neckStart + neck * 0.6),
                      controlPoint2: CGPoint(x: kx1, y: neckEnd - neck * 0.6))
        path.addLine(to: CGPoint(x: kx1, y: bottom - keyRadius))
        path.addArc(withCenter: CGPoint(x: kx1 - keyRadius, y: bottom - keyRadius), radius: keyRadius,
                    startAngle: 0, endAngle: .pi / 2, clockwise: true)
        path.addLine(to: CGPoint(x: kx0 + keyRadius, y: bottom))
        path.addArc(withCenter: CGPoint(x: kx0 + keyRadius, y: bottom - keyRadius), radius: keyRadius,
                    startAngle: .pi / 2, endAngle: .pi, clockwise: true)
        path.addLine(to: CGPoint(x: kx0, y: neckEnd))
        path.addCurve(to: CGPoint(x: x0, y: neckStart),
                      controlPoint1: CGPoint(x: kx0, y: neckEnd - neck * 0.6),
                      controlPoint2: CGPoint(x: x0, y: neckStart + neck * 0.6))
        path.addLine(to: CGPoint(x: x0, y: top + radius))
        path.addArc(withCenter: CGPoint(x: x0 + radius, y: top + radius), radius: radius,
                    startAngle: .pi, endAngle: .pi * 1.5, clockwise: true)
        path.close()

        let colors = KeyPreviewView.bubbleColor(from: fill.resolvedColor(with: traitCollection))
        if frame != container { frame = container }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        shape.frame = bounds
        shape.path = path.cgPath
        shape.shadowPath = path.cgPath
        shape.fillColor = colors.fill.cgColor
        shape.strokeColor = colors.hairline.cgColor
        CATransaction.commit()
        label.text = text
        label.textColor = textColor
        label.frame = CGRect(x: x0, y: top, width: x1 - x0, height: bubbleHeight - 10)
        isHidden = false
    }

    func hide() {
        if !isHidden { isHidden = true }
    }
}
