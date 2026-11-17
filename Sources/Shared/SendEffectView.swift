import UIKit

/// Draws a send effect over a view (the keyboard, or the app window for the
/// preview). It never takes touches and removes itself when the pieces have
/// faded out, so it cannot get in the way of typing.
final class SendEffectView: UIView {
    /// Shows `effect` over `host`. Does nothing when the user asked iOS to
    /// reduce motion.
    static func play(_ effect: SendEffect, in host: UIView) {
        guard !UIAccessibility.isReduceMotionEnabled, host.bounds.width > 50 else { return }
        let view = SendEffectView(frame: host.bounds)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        host.addSubview(view)
        view.start(effect)
    }

    private var layersToStop: [CAEmitterLayer] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        clipsToBounds = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    // MARK: Pieces

    private var scale: CGFloat { max(1, traitCollection.displayScale) }

    private func emojiImage(_ emoji: String, size: CGFloat) -> CGImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = false
        let side = size * 1.25
        let image = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format)
            .image { _ in
                let text = NSString(string: emoji)
                let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: size)]
                let measured = text.size(withAttributes: attributes)
                text.draw(at: CGPoint(x: (side - measured.width) / 2, y: (side - measured.height) / 2),
                          withAttributes: attributes)
            }
        return image.cgImage
    }

    private func shapeImage(_ color: UIColor, size: CGSize, round: Bool) -> CGImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = false
        let image = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            color.setFill()
            let rect = CGRect(origin: .zero, size: size)
            (round ? UIBezierPath(ovalIn: rect) : UIBezierPath(roundedRect: rect, cornerRadius: 1.5)).fill()
        }
        return image.cgImage
    }

    private func cell(_ image: CGImage?, rate: Float, lifetime: Float, velocity: CGFloat,
                      velocityRange: CGFloat, longitude: CGFloat, range: CGFloat,
                      spin: CGFloat = 0, scale pieceScale: CGFloat = 1, scaleRange: CGFloat = 0,
                      yAcceleration: CGFloat = 0, xAcceleration: CGFloat = 0,
                      alphaSpeed: Float = 0) -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.contents = image
        cell.contentsScale = scale
        cell.birthRate = rate
        cell.lifetime = lifetime
        cell.velocity = velocity
        cell.velocityRange = velocityRange
        cell.emissionLongitude = longitude
        cell.emissionRange = range
        cell.spin = spin
        cell.spinRange = spin
        cell.scale = pieceScale
        cell.scaleRange = scaleRange
        cell.yAcceleration = yAcceleration
        cell.xAcceleration = xAcceleration
        cell.alphaSpeed = alphaSpeed
        return cell
    }

    private func addEmitter(position: CGPoint, size: CGSize, shape: CAEmitterLayerEmitterShape,
                            cells: [CAEmitterCell]) -> CAEmitterLayer {
        let emitter = CAEmitterLayer()
        emitter.frame = bounds
        emitter.emitterPosition = position
        emitter.emitterSize = size
        emitter.emitterShape = shape
        emitter.renderMode = .unordered
        emitter.emitterCells = cells
        layer.addSublayer(emitter)
        layersToStop.append(emitter)
        return emitter
    }

    // MARK: Effects

    private func start(_ effect: SendEffect) {
        let width = bounds.width
        let height = bounds.height
        let top = CGPoint(x: width / 2, y: -12)
        let bottom = CGPoint(x: width / 2, y: height + 12)
        let wide = CGSize(width: width, height: 1)
        var showFor: TimeInterval = 1.4
        var lifetime: TimeInterval = 3.5

        switch effect {
        case .confetti:
            let colors: [UIColor] = [.systemPink, .systemYellow, .systemTeal, .systemOrange,
                                     .systemPurple, .systemGreen, .systemRed, .systemBlue]
            let pieces = colors.enumerated().map { index, color in
                cell(shapeImage(color, size: index % 2 == 0 ? CGSize(width: 7, height: 11) : CGSize(width: 8, height: 8),
                                round: index % 2 == 1),
                     rate: 14, lifetime: 3.4, velocity: 190, velocityRange: 90,
                     longitude: .pi / 2, range: .pi / 4, spin: 4, scaleRange: 0.35,
                     yAcceleration: 90)
            }
            _ = addEmitter(position: top, size: wide, shape: .line, cells: pieces)
            lifetime = 3.6
        case .hearts:
            let hearts = ["❤️", "💖", "💕", "💗", "💝"].map { emoji in
                cell(emojiImage(emoji, size: 30), rate: 5, lifetime: 3.2, velocity: 150,
                     velocityRange: 70, longitude: -.pi / 2, range: .pi / 5, spin: 0.6,
                     scale: 0.8, scaleRange: 0.45, yAcceleration: -10, alphaSpeed: -0.22)
            }
            _ = addEmitter(position: bottom, size: wide, shape: .line, cells: hearts)
            showFor = 1.6
            lifetime = 3.4
        case .balloons:
            let balloons = ["🎈", "🎈", "🎊"].map { emoji in
                cell(emojiImage(emoji, size: 34), rate: 3, lifetime: 4.6, velocity: 100,
                     velocityRange: 45, longitude: -.pi / 2, range: .pi / 9, spin: 0.25,
                     scale: 0.85, scaleRange: 0.35, xAcceleration: 6)
            }
            _ = addEmitter(position: bottom, size: wide, shape: .line, cells: balloons)
            showFor = 1.6
            lifetime = 4.8
        case .snow:
            let flakes = ["❄️", "❅", "❆"].map { symbol in
                cell(emojiImage(symbol, size: 24), rate: 8, lifetime: 4.2, velocity: 55,
                     velocityRange: 30, longitude: .pi / 2, range: .pi / 6, spin: 1.1,
                     scale: 0.8, scaleRange: 0.5, xAcceleration: 7)
            }
            _ = addEmitter(position: top, size: wide, shape: .line, cells: flakes)
            showFor = 1.8
            lifetime = 4.4
        case .flowers:
            let petals = ["🌸", "🌺", "🌷", "🌼"].map { emoji in
                cell(emojiImage(emoji, size: 26), rate: 5, lifetime: 3.8, velocity: 85,
                     velocityRange: 40, longitude: .pi / 2, range: .pi / 5, spin: 2,
                     scale: 0.8, scaleRange: 0.4, yAcceleration: 25, xAcceleration: 9)
            }
            _ = addEmitter(position: top, size: wide, shape: .line, cells: petals)
            showFor = 1.7
            lifetime = 4
        case .stars:
            let twinkles = ["✨", "⭐️", "🌟"].map { emoji in
                cell(emojiImage(emoji, size: 26), rate: 12, lifetime: 1.5, velocity: 0,
                     velocityRange: 0, longitude: 0, range: 0, spin: 1,
                     scale: 0.2, scaleRange: 0.2, alphaSpeed: -0.6)
            }
            for item in twinkles { item.scaleSpeed = 0.55 }
            _ = addEmitter(position: CGPoint(x: width / 2, y: height / 2),
                           size: CGSize(width: width, height: height),
                           shape: .rectangle, cells: twinkles)
            showFor = 1.5
            lifetime = 1.6
        case .luckyMoney:
            let gifts = ["🧧", "💰", "🧧", "🪙"].map { emoji in
                cell(emojiImage(emoji, size: 28), rate: 5, lifetime: 3.6, velocity: 120,
                     velocityRange: 60, longitude: .pi / 2, range: .pi / 6, spin: 2.2,
                     scale: 0.85, scaleRange: 0.35, yAcceleration: 70)
            }
            _ = addEmitter(position: top, size: wide, shape: .line, cells: gifts)
            showFor = 1.6
            lifetime = 3.8
        case .fireworks:
            startFireworks(width: width, height: height)
            showFor = 1.3
            lifetime = 1.6
        }

        let stopAfter = showFor
        DispatchQueue.main.asyncAfter(deadline: .now() + stopAfter) { [weak self] in
            self?.layersToStop.forEach { $0.birthRate = 0 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + stopAfter + lifetime + 0.3) { [weak self] in
            self?.removeFromSuperview()
        }
    }

    /// Three bursts of sparks, one after the other, at different places.
    private func startFireworks(width: CGFloat, height: CGFloat) {
        let colors: [UIColor] = [.systemPink, .systemYellow, .systemTeal, .systemOrange,
                                 .systemPurple, .white]
        let spark = shapeImage(.white, size: CGSize(width: 5, height: 5), round: true)
        let spots: [(x: CGFloat, y: CGFloat, delay: TimeInterval)] = [
            (0.28, 0.42, 0), (0.72, 0.34, 0.35), (0.5, 0.55, 0.7)
        ]
        for (index, spot) in spots.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + spot.delay) { [weak self] in
                guard let self = self else { return }
                let color = colors[(index * 2) % colors.count]
                let burst = self.cell(spark, rate: 140, lifetime: 1.1, velocity: 120,
                                      velocityRange: 55, longitude: 0, range: .pi * 2,
                                      scale: 1, scaleRange: 0.5, yAcceleration: 85,
                                      alphaSpeed: -0.9)
                burst.color = color.cgColor
                let emitter = self.addEmitter(
                    position: CGPoint(x: width * spot.x, y: height * spot.y),
                    size: .zero, shape: .point, cells: [burst])
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { emitter.birthRate = 0 }
            }
        }
    }
}
