import UIKit

extension KeyboardViewController {
    func applyCustomDesign() {
        wallpaperView?.removeFromSuperview()
        wallpaperView = nil
        let custom = currentTheme == "custom"
        let design = KeyboardDesign.current
        customSound = custom && design.sound && !performanceMode
        if custom, let image = KeyboardDesign.wallpaper() {
            let background = UIImageView(image: image)
            background.contentMode = .scaleAspectFill
            background.clipsToBounds = true
            background.isUserInteractionEnabled = false
            background.translatesAutoresizingMaskIntoConstraints = false
            view.insertSubview(background, at: 0)
            NSLayoutConstraint.activate([background.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                background.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                background.topAnchor.constraint(equalTo: view.topAnchor),
                background.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
            wallpaperView = background
        }
        for button in letterButtons {
            button.layer.cornerRadius = custom ? CGFloat(max(3,min(15,design.radius))) : 8
            let size: CGFloat = 21
            button.titleLabel?.font = custom ? KeyboardDesign.font(size, design: design.font) : .systemFont(ofSize: size, weight: .medium)
        }
    }
}
