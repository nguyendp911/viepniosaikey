import UIKit
import AVFoundation

extension KeyboardViewController {
    func prepareProSound() {
        proSoundPlayer=nil
        guard offlineConfig.sound=="custom",!performanceMode,let url=ProSoundFile.url,
              let player=try? AVAudioPlayer(contentsOf:url),player.duration<=3 else{return}
        player.volume=Float(offlineConfig.volume);player.prepareToPlay();proSoundPlayer=player
    }
    func applyProVisuals() {
        let palette=KeyboardThemePalette.resolve(currentTheme)
        if let row=proNumberRow {
            for case let button as UIButton in row.arrangedSubviews {button.backgroundColor=palette.modifier;button.setTitleColor(palette.text,for:.normal)}
        }
        for button in letterButtons {
            if offlineConfig.keycap=="flat" { 
                button.layer.borderWidth=0
                button.layer.shadowOpacity=0.08;button.layer.shadowOffset=CGSize(width:0,height:1)
                continue
            }
            button.layer.cornerRadius=CGFloat(offlineConfig.radius)
            button.layer.borderWidth=1
            button.layer.borderColor=(offlineConfig.keycap=="heritage" ? UIColor(red:0.9,green:0.72,blue:0.32,alpha:1) : palette.text.withAlphaComponent(0.23)).cgColor
            button.layer.shadowColor=UIColor.black.cgColor
            button.layer.shadowOpacity=offlineConfig.keycap=="mechanical" ? 0.5 : 0.14
            button.layer.shadowOffset=CGSize(width:0,height:offlineConfig.keycap=="mechanical" ? 3 : 1)
            if offlineConfig.keycap=="crystal" {button.backgroundColor=palette.key.withAlphaComponent(0.65)}
        }
        proWallpaperLayer?.removeFromSuperlayer();proWallpaperLayer=nil
        guard offlineConfig.wallpaper != "off" else{return}
        let layer=CAGradientLayer();layer.frame=view.bounds
        let colors:[UIColor]
        switch offlineConfig.wallpaper {
        case "stars": colors=[UIColor(white:0.02,alpha:1),UIColor(red:0.15,green:0.18,blue:0.40,alpha:1),UIColor(white:0.08,alpha:1)]
        case "lotus": colors=[UIColor(red:0.20,green:0.05,blue:0.13,alpha:1),UIColor(red:0.48,green:0.17,blue:0.30,alpha:1),UIColor(red:0.18,green:0.08,blue:0.17,alpha:1)]
        default: colors=[UIColor(red:0.12,green:0.14,blue:0.40,alpha:1),UIColor(red:0.04,green:0.42,blue:0.39,alpha:1),UIColor(red:0.29,green:0.10,blue:0.44,alpha:1)]
        }
        layer.colors=colors.map(\.cgColor);layer.startPoint=CGPoint(x:0,y:0);layer.endPoint=CGPoint(x:1,y:1)
        view.layer.insertSublayer(layer,at:0);proWallpaperLayer=layer
        if !performanceMode,!UIAccessibility.isReduceMotionEnabled {
            let motion=CABasicAnimation(keyPath:"locations");motion.fromValue=[0,0.15,1];motion.toValue=[0,0.85,1];motion.duration=5;motion.autoreverses=true;motion.repeatCount = .infinity
            layer.add(motion,forKey:"offline4.wallpaper")
        }
    }
    func clearProParticles() {proParticleLayers.forEach{$0.removeFromSuperlayer()};proParticleLayers=[]}
    func animateProKey(_ key:UIButton) {
        guard !performanceMode,!UIAccessibility.isReduceMotionEnabled,offlineConfig.particles != "off",let parent=key.superview else{return}
        if offlineConfig.particles=="rgb" {
            let adjacent=(parent as? UIStackView)?.arrangedSubviews.compactMap{$0 as? UIButton} ?? [key]
            guard let index=adjacent.firstIndex(of:key)else{return}
            for i in max(0,index-2)...min(adjacent.count-1,index+2) {
                let neighbor=adjacent[i];let pulse=CAKeyframeAnimation(keyPath:"backgroundColor")
                let original=neighbor.backgroundColor?.cgColor ?? UIColor.darkGray.cgColor
                let accent=UIColor(hue:CGFloat((i+Int(typingTouchCount%24))%24)/24,saturation:0.75,brightness:0.9,alpha:1).cgColor
                pulse.values=[original,accent,original];pulse.duration=0.30;pulse.beginTime=CACurrentMediaTime()+Double(abs(i-index))*0.035
                neighbor.layer.add(pulse,forKey:"offline4.wave")
            }
            return
        }
        let center=parent.convert(key.center,to:view)
        while proParticleLayers.count>=12 {proParticleLayers.removeFirst().removeFromSuperlayer()}
        for index in 0..<3 {
            let particle=CATextLayer();particle.string=offlineConfig.particles=="heart" ? "♥" : offlineConfig.particles=="petal" ? "✿" : "✦"
            particle.fontSize=14;particle.alignmentMode = .center;particle.foregroundColor=UIColor(red:0.95,green:0.56,blue:0.83,alpha:1).cgColor
            particle.contentsScale=view.window?.screen.scale ?? 2;particle.frame=CGRect(x:center.x-10,y:center.y-10,width:20,height:20)
            view.layer.addSublayer(particle);proParticleLayers.append(particle)
            let position=CABasicAnimation(keyPath:"position");position.fromValue=particle.position;position.toValue=CGPoint(x:center.x+CGFloat(index-1)*22,y:center.y-34)
            let fade=CABasicAnimation(keyPath:"opacity");fade.fromValue=1;fade.toValue=0
            let group=CAAnimationGroup();group.animations=[position,fade];group.duration=0.38;particle.opacity=0;particle.add(group,forKey:"offline4.particle")
            DispatchQueue.main.asyncAfter(deadline:.now()+0.4){[weak self,weak particle] in if let particle {particle.removeFromSuperlayer();self?.proParticleLayers.removeAll{$0===particle}}}
        }
    }
}
