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
        shape.shadowOpacity = 0.28
        shape.shadowRadius = 5
        shape.shadowOffset = CGSize(width: 0, height: 2)
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

    /// `keyFrame` and `container` are in the coordinates of the view this one
    /// is added to. The bubble sits above the key and is joined to it by a
    /// column the width of the key, so the two read as one shape.
    func show(text: String, keyFrame: CGRect, container: CGRect,
              fill: UIColor, textColor: UIColor) {
        let radius: CGFloat = 9
        let bubbleHeight = max(46, keyFrame.height * 1.1)
        let bubbleWidth = min(keyFrame.width + 26, container.width - 8)
        var bubbleX = keyFrame.midX - bubbleWidth / 2
        bubbleX = min(max(bubbleX, container.minX + 2), container.maxX - bubbleWidth - 2)
        let bubble = CGRect(x: bubbleX, y: keyFrame.minY - bubbleHeight + 6,
                            width: bubbleWidth, height: bubbleHeight)
        let stemTop = bubble.maxY - radius
        let stem = CGRect(x: keyFrame.minX, y: stemTop,
                          width: keyFrame.width, height: max(1, keyFrame.maxY - stemTop))
        let path = UIBezierPath(roundedRect: bubble, cornerRadius: radius)
        path.append(UIBezierPath(roundedRect: stem,
                                 byRoundingCorners: [.bottomLeft, .bottomRight],
                                 cornerRadii: CGSize(width: 8, height: 8)))
        if frame != container { frame = container }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        shape.frame = bounds
        shape.path = path.cgPath
        shape.shadowPath = path.cgPath
        shape.fillColor = fill.resolvedColor(with: traitCollection).cgColor
        CATransaction.commit()
        label.text = text
        label.textColor = textColor
        label.frame = CGRect(x: bubble.minX, y: bubble.minY,
                             width: bubble.width, height: bubble.height - 6)
        isHidden = false
    }

    func hide() {
        if !isHidden { isHidden = true }
    }
}
