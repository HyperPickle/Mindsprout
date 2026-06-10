//
//  SproutScene.swift
//  Mindsprout
//
//  Created by Changrila Souksamlane on 6/6/2026.
//

import SpriteKit
import SwiftUI
import Combine
import Foundation

class SproutScene: SKScene {
    var sprout: SKSpriteNode?
    var eyesNode: SKSpriteNode?
    var isWalking = false
    var isHungry = false    // ✅ ajoute ces états
    var isHappy = false
    
    var isIdle: Bool {
          !isWalking && !isHungry && !isHappy
      }
    
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        scaleMode = .resizeFill
        
        guard UIImage(named: "Sprout_idle_1") != nil else {
            print("❌ Sprout_idle_1 non trouvée")
            return
        }
        
        let texture = SKTexture(imageNamed: "Sprout_idle_1")
        let ratio = texture.size().height / texture.size().width
        let desiredWidth: CGFloat = size.width * 0.5
        let sproutSize = CGSize(width: desiredWidth, height: desiredWidth * 1.8)
        
        // ✅ Ombre
        let shadow = SKShapeNode(ellipseOf: CGSize(width: desiredWidth * 0.5, height: 12))
        shadow.fillColor = UIColor.black.withAlphaComponent(0.2)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: size.width/2, y: size.height/2 - sproutSize.height/2 + 65)
        shadow.zPosition = 0
        addChild(shadow)
        animateShadow(shadow: shadow)
        
        // ✅ Corps de Sprout
        let sproutNode = SKSpriteNode(texture: texture)
        sproutNode.size = sproutSize
        sproutNode.position = CGPoint(x: size.width/2, y: size.height/2)
        sproutNode.zPosition = 1
        addChild(sproutNode)
        sprout = sproutNode
        

        
        startIdleAnimation()
        startBlinkLoop()
    }

   
    func animateShadow(shadow: SKShapeNode) {
        // ✅ Même timing que la respiration
        let breatheIn = SKAction.scale(to: 1.05, duration: 0.8)   // ← grandit avec Sprout
        breatheIn.timingMode = .easeInEaseOut
        let breatheOut = SKAction.scale(to: 1.0, duration: 0.8)   // ← rétrécit avec Sprout
        breatheOut.timingMode = .easeInEaseOut
        
        shadow.run(SKAction.repeatForever(
            SKAction.sequence([breatheIn, breatheOut])
        ))
    }

    func startIdleAnimation() {
        guard let sprout = sprout else { return }
        
        let idleFrames = (1...9).map {
            SKTexture(imageNamed: "Sprout_idle_\($0)")
        }
        
        // ✅ Corps respire avec les frames
        let animate = SKAction.animate(
            with: idleFrames,
            timePerFrame: 0.2,
            resize: false,
            restore: false
        )
        
        // ✅ Légère respiration verticale — pas de flottement !
        let breatheIn = SKAction.scaleY(to: 1.03, duration: 0.8)   // ← grandit légèrement
        breatheIn.timingMode = .easeInEaseOut
        let breatheOut = SKAction.scaleY(to: 1.0, duration: 0.8)   // ← rétrécit
        breatheOut.timingMode = .easeInEaseOut
        
        let breathe = SKAction.repeatForever(
            SKAction.sequence([breatheIn, breatheOut])
        )
        
        // ✅ Les deux ensemble
        sprout.run(SKAction.group([
            SKAction.repeatForever(animate),
            breathe
        ]), withKey: "idle")
    }
    
    func startBlinkLoop() {
        guard let sprout = sprout else { return }
        
        let blinkFrames = [
            SKTexture(imageNamed: "Sprout_blink_1"),
            SKTexture(imageNamed: "Sprout_blink_2"),
            SKTexture(imageNamed: "Sprout_blink_3"),
            SKTexture(imageNamed: "Sprout_blink_2"),
            SKTexture(imageNamed: "Sprout_blink_1"),
        ]
        
        let wait = SKAction.wait(forDuration: 3.0)
        
        // ✅ Stoppe idle → blink → reprend idle
        let stopIdle = SKAction.run { [weak self] in
            guard let self = self else { return }
            // ✅ Ne stoppe pas si Sprout marche ou autre animation
            if !self.isWalking {
                sprout.removeAction(forKey: "idle")
            }
        }
        
        let blink = SKAction.animate(
            with: blinkFrames,
            timePerFrame: 0.08,
            resize: false,
            restore: true  // ✅ restore: true → retourne à la texture avant le blink
        )
        
        let resumeIdle = SKAction.run { [weak self] in
            guard let self = self else { return }
            // ✅ Ne reprend l'idle que si Sprout ne marche pas
            if !self.isWalking {
                self.startIdleAnimation()
            }
        }
       
        
        let blinkSequence = SKAction.sequence([
            wait,
            stopIdle,   // ← stoppe idle
            blink,      // ← cligne
            resumeIdle  // ← reprend idle depuis le début
        ])
        
        sprout.run(SKAction.repeatForever(blinkSequence), withKey: "blink")
    }
    
    func playHappy() {
        guard let sprout = sprout else { return }
        
        // Stoppe l'idle
        sprout.removeAction(forKey: "idle")
        
        let happyFrames = (1...11).map {
            SKTexture(imageNamed: "Sprout_happy_\($0)")
        }
        
        let happy = SKAction.animate(
            with: happyFrames,
            timePerFrame: 0.1,   // ← ajuste la vitesse
            resize: false,
            restore: false
        )
        
        // ✅ Joue happy UNE fois puis reprend idle
        sprout.run(happy) { [weak self] in
            self?.startIdleAnimation()
        }
    }
    
    func tapReaction() {
        guard let sprout = sprout else { return }
        sprout.removeAction(forKey: "idle")
        playHappy()  // ← au lieu du pop !
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let sprout = sprout else { return }
        
        if sprout.contains(touch.location(in: self)) {
            //tapReaction()
            //playHungry()
//            playSleepDaily()
//            playWakeUpDaily()
//            playEvolutionFlash()
            playSitDown()
            

        }
    }
    
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//            guard let touch = touches.first,
//                  let sprout = sprout else { return }
//            
//            if sprout.contains(touch.location(in: self)) {
//                if isWalking {
//                    isWalking = false
//                    stopWalk()   // ✅ 2ème tap → stoppe
//                } else {
//                    isWalking = true
//                    playWalk()   // ✅ 1er tap → démarre
//                }
//            }
//        }

//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        guard let touch = touches.first,
//              let sprout = sprout else { return }
//        
//        if sprout.contains(touch.location(in: self)) {
//            // Test sans évolution
//            playLevelUp(willEvolve: false)
//            
//            // Test avec évolution
//            // playLevelUp(willEvolve: true)
//        }
//    }
    
    func playHungry() {
        guard let sprout = sprout else { return }
        sprout.removeAction(forKey: "idle")
        
        let hungryFrames = (1...10).map {
            SKTexture(imageNamed: "Sprout_hungry_\($0)")
        }
        
        let hungry = SKAction.animate(
            with: hungryFrames,
            timePerFrame: 0.15,
            resize: false,
            restore: false
        )
        
        // ✅ Pause avec yeux suppliants (frame 5 ou 6)
        let pityEyes = SKAction.animate(
            with: [SKTexture(imageNamed: "Sprout_hungry_5")],
            timePerFrame: 1.5,  // ← reste 1.5 secondes avec yeux suppliants
            resize: false,
            restore: false
        )
        
        let cycle = SKAction.sequence([hungry, pityEyes])
        sprout.run(SKAction.repeatForever(cycle), withKey: "hungry")
    }

    // ✅ Pour stopper
    func stopHungry() {
        sprout?.removeAction(forKey: "hungry")
        startIdleAnimation()
    }
    
    func onReflectionCompleted() {
        guard let sprout = sprout else { return }
        
        // Stoppe hungry
        sprout.removeAction(forKey: "hungry")
        
        // Joue Happy d'abord !
        playHappy()
    }
    
    // WALK
    func playWalk() {
        guard let sprout = sprout else { return }
        sprout.removeAction(forKey: "idle")
        
        // ✅ Transition face → 3/4
        let startFrames = (1...4).map {
            SKTexture(imageNamed: "Sprout_walk_start_\($0)")
        }
        let startTransition = SKAction.animate(
            with: startFrames,
            timePerFrame: 0.12,
            resize: false,
            restore: false
        )
        
        sprout.run(startTransition) { [weak self] in
            self?.walkLoop()
        }
    }

    func walkLoop() {
        guard let sprout = sprout, isWalking else { return }
        
        let walkFrames = (1...11).map {
            SKTexture(imageNamed: "Sprout_walk_\($0)")
        }
        
        let walk = SKAction.animate(
            with: walkFrames,
            timePerFrame: 0.1,
            resize: false,
            restore: false
        )
        
        sprout.run(walk) { [weak self] in
            self?.walkLoop()
        }
    }

    func stopWalk() {
        guard let sprout = sprout else { return }
        
        sprout.removeAction(forKey: "walkLoop")
        
        let endFrames = (1...4).map {
            SKTexture(imageNamed: "Sprout_walk_end_\($0)")
        }
        let endTransition = SKAction.animate(
            with: endFrames,
            timePerFrame: 0.12,
            resize: false,
            restore: false
        )
        
        sprout.run(endTransition) { [weak self] in
            self?.startIdleAnimation()
        }
    }
    
    //LEVEL UP
    func playLevelUp(willEvolve: Bool = false) {
        guard let sprout = sprout else { return }
        sprout.removeAction(forKey: "idle")
        sprout.removeAction(forKey: "blink")
        
        let levelUpFrames = (1...16).map {
            SKTexture(imageNamed: "Sprout_levelup_\($0)")
        }
        
        let levelUp = SKAction.animate(
            with: levelUpFrames,
            timePerFrame: 0.1,
            resize: false,
            restore: false
        )
        
        // ✅ Lance confettis quand Sprout est en l'air
        // (environ frame 6-8 = peak du saut)
        let waitForJump = SKAction.wait(forDuration: 0.6)
        let launchConfetti = SKAction.run { [weak self] in
            self?.playConfetti()
        }
        run(SKAction.sequence([waitForJump, launchConfetti]))
        
        // ✅ Joue levelup puis décide selon willEvolve
        sprout.run(levelUp) { [weak self] in
            guard let self = self else { return }
            if willEvolve {
//                self.playEvolution()   // ← va évoluer
            } else {
                self.startIdleAnimation()  // ← retour idle
                self.startBlinkLoop()      // ← reprend le blink
            }
        }
    }
    
    func playConfetti() {
        let colors: [UIColor] = [
            .systemYellow, .systemPink, .systemBlue,
            .systemGreen, .systemOrange, .systemPurple
        ]
        
        // ✅ 20 confettis
        for _ in 0..<20 {
            let confetti = SKShapeNode(
                rectOf: CGSize(width: 8, height: 8),
                cornerRadius: 2
            )
            confetti.fillColor = colors.randomElement()!
            confetti.strokeColor = .clear
            confetti.position = CGPoint(
                x: sprout?.position.x ?? size.width/2 + CGFloat.random(in: -50...50),
                y: sprout?.position.y ?? size.height/2 + (sprout?.size.height ?? 0) / 2
            )
            confetti.zPosition = 10
            addChild(confetti)
            
            // ✅ Animation — monte et tombe
            let moveUp = SKAction.moveBy(
                x: CGFloat.random(in: -80...80),
                y: CGFloat.random(in: 100...200),
                duration: 0.4
            )
            let fall = SKAction.moveBy(
                x: CGFloat.random(in: -40...40),
                y: -300,
                duration: 0.8
            )
            let fade = SKAction.fadeOut(withDuration: 0.3)
            let rotate = SKAction.rotate(
                byAngle: CGFloat.random(in: -CGFloat.pi...CGFloat.pi),                duration: 1.2
            )
            
            let sequence = SKAction.sequence([
                moveUp,
                fall,
                fade,
                SKAction.removeFromParent()
            ])
            let group = SKAction.group([sequence, rotate])
            
            confetti.run(group)
        }
    }
    
    
    //SLEEP
    func playSleepDaily() {
        guard let sprout = sprout else { return }
        sprout.removeAction(forKey: "idle")
        sprout.removeAction(forKey: "blink")
        
        // ✅ Yawn — 7 frames
        let yawnFrames = (1...7).map {
            SKTexture(imageNamed: "Sprout_yawn_\($0)")
        }
        let yawn = SKAction.animate(
            with: yawnFrames,
            timePerFrame: 0.18,
            resize: false,
            restore: false
        )
        
        // ✅ Fall — 4 frames
        let fallFrames = (1...4).map {
            SKTexture(imageNamed: "Sprout_fall_\($0)")
        }
        let fall = SKAction.animate(
            with: fallFrames,
            timePerFrame: 0.15,
            resize: false,
            restore: false
        )
        
        // ✅ Sleep loop — 7 frames
        let sleepFrames = (1...7).map {
            SKTexture(imageNamed: "Sprout_sleep_\($0)")
        }
        let sleepLoop = SKAction.animate(
            with: sleepFrames,
            timePerFrame: 0.3,  // ← plus lent = plus endormi
            resize: false,
            restore: false
        )
        
        // ✅ Séquence : Yawn → Fall → Sleep loop
        sprout.run(SKAction.sequence([yawn, fall])) { [weak self] in
            self?.sprout?.run(
                SKAction.repeatForever(sleepLoop),
                withKey: "sleepLoop"
            )
        }
    }

    func playWakeUpDaily() {
        guard let sprout = sprout else { return }
        sprout.removeAction(forKey: "sleepLoop")
        
        // ✅ Wake Up — 15 frames
        let wakeUpFrames = (1...15).map {
            SKTexture(imageNamed: "Sprout_wakeup_\($0)")
        }
        let wakeUp = SKAction.animate(
            with: wakeUpFrames,
            timePerFrame: 0.12,
            resize: false,
            restore: false
        )
        
        sprout.run(wakeUp) { [weak self] in
            self?.startIdleAnimation()
            self?.startBlinkLoop()
        }
    }

    // ✅ Evolution — même base que daily mais avec évolution après
    func playSleepEvolution() {
        guard let sprout = sprout else { return }
        sprout.removeAction(forKey: "idle")
        sprout.removeAction(forKey: "blink")
        
        let yawnFrames = (1...7).map {
            SKTexture(imageNamed: "Sprout_yawn_\($0)")
        }
        let yawn = SKAction.animate(
            with: yawnFrames,
            timePerFrame: 0.18,
            resize: false,
            restore: false
        )
        
        let fallFrames = (1...4).map {
            SKTexture(imageNamed: "Sprout_fall_\($0)")
        }
        let fall = SKAction.animate(
            with: fallFrames,
            timePerFrame: 0.15,
            resize: false,
            restore: false
        )
        
        let sleepFrames = (1...7).map {
            SKTexture(imageNamed: "Sprout_sleep_\($0)")
        }
        let sleepLoop = SKAction.animate(
            with: sleepFrames,
            timePerFrame: 0.3,
            resize: false,
            restore: false
        )
        
        sprout.run(SKAction.sequence([yawn, fall])) { [weak self] in
            guard let self = self else { return }
            
            // ✅ Enregistre l'heure
            UserDefaults.standard.set(
                Date().timeIntervalSince1970,
                forKey: "sproutSleepTime"
            )
            UserDefaults.standard.set(true, forKey: "sproutIsEvolving")
            
            self.sprout?.run(
                SKAction.repeatForever(sleepLoop),
                withKey: "sleepLoop"
            )
        }
    }

    func playWakeUpAndEvolve() {
        guard let sprout = sprout else { return }
        sprout.removeAction(forKey: "sleepLoop")
        
        // ✅ Wake Up — 15 frames
        let wakeUpFrames = (1...15).map {
            SKTexture(imageNamed: "Sprout_wakeup_\($0)")
        }
        let wakeUp = SKAction.animate(
            with: wakeUpFrames,
            timePerFrame: 0.12,
            resize: false,
            restore: false
        )
        
        // ✅ Evolution — 8 frames
        let evolveFrames = (1...8).map {
            SKTexture(imageNamed: "Sprout_evolve_\($0)")
        }
        let evolve = SKAction.animate(
            with: evolveFrames,
            timePerFrame: 0.12,
            resize: false,
            restore: false
        )
        
        sprout.run(SKAction.sequence([wakeUp, evolve])) { [weak self] in
            guard let self = self else { return }
            UserDefaults.standard.set(false, forKey: "sproutIsEvolving")
            UserDefaults.standard.set(
                UserDefaults.standard.integer(forKey: "sproutLevel") + 1,
                forKey: "sproutLevel"
            )
            self.playConfetti()
            self.startIdleAnimation()
            self.startBlinkLoop()
        }
    }
    
    func startEvolvedIdleAnimation() {
        guard let sprout = sprout else { return }
        
        let evolvedIdleFrames = (1...8).map {  // ✅ 8 frames
            SKTexture(imageNamed: "Sprout_evolved_1_idle_\($0)")
        }
        
        let animate = SKAction.animate(
            with: evolvedIdleFrames,
            timePerFrame: 0.2,
            resize: false,
            restore: false
        )
        
        let breatheIn = SKAction.scaleY(to: 1.03, duration: 0.8)
        breatheIn.timingMode = .easeInEaseOut
        let breatheOut = SKAction.scaleY(to: 1.0, duration: 0.8)
        breatheOut.timingMode = .easeInEaseOut
        
        let breathe = SKAction.repeatForever(
            SKAction.sequence([breatheIn, breatheOut])
        )
        
        sprout.run(SKAction.group([
            SKAction.repeatForever(animate),
            breathe
        ]), withKey: "idle")
    }

    func startEvolvedBlinkLoop() {
        guard let sprout = sprout else { return }
        
        let blinkFrames = [
            SKTexture(imageNamed: "Sprout_evolved_1_blink_1"),
            SKTexture(imageNamed: "Sprout_evolved_1_blink_2"),
            SKTexture(imageNamed: "Sprout_evolved_1_blink_3"),
            SKTexture(imageNamed: "Sprout_evolved_1_blink_2"),
            SKTexture(imageNamed: "Sprout_evolved_1_blink_1"),
        ]
        
        let wait = SKAction.wait(forDuration: 3.0)
        let stopIdle = SKAction.run { [weak self] in
            sprout.removeAction(forKey: "idle")
        }
        let blink = SKAction.animate(
            with: blinkFrames,
            timePerFrame: 0.08,
            resize: false,
            restore: true
        )
        let resumeIdle = SKAction.run { [weak self] in
            self?.startEvolvedIdleAnimation()
        }
        
        sprout.run(SKAction.repeatForever(
            SKAction.sequence([wait, stopIdle, blink, resumeIdle])
        ), withKey: "blink")
    }
    
    func playEvolutionFlash() {
        guard let sprout = sprout else { return }
        
        let center = CGPoint(x: size.width/2, y: size.height/2)
        
        // ✅ 8 rayons autour de Sprout
        for i in 0..<8 {
            let angle = CGFloat(i) * CGFloat.pi / 4  // ← 45° entre chaque rayon
            
            let ray = SKShapeNode(rectOf: CGSize(width: 8, height: 200))
            ray.fillColor = UIColor.white.withAlphaComponent(0.8)
            ray.strokeColor = .clear
            ray.position = center
            ray.zRotation = angle
            ray.zPosition = 99
            ray.alpha = 0
            ray.setScale(0)
            addChild(ray)
            
            // ✅ Apparaît et grandit
            let fadeIn = SKAction.fadeIn(withDuration: 0.2)
            let expand = SKAction.scale(to: 1.5, duration: 0.6)
            expand.timingMode = .easeOut
            let fadeOut = SKAction.fadeOut(withDuration: 0.5)
            let remove = SKAction.removeFromParent()
            
            ray.run(SKAction.sequence([
                fadeIn,
                SKAction.group([expand, fadeOut]),
                remove
            ]))
        }
        
        // ✅ Cercle central
        let glow = SKShapeNode(circleOfRadius: 5)
        glow.fillColor = .white
        glow.strokeColor = .clear
        glow.position = center
        glow.zPosition = 99
        addChild(glow)
        
        let expand = SKAction.scale(to: 15, duration: 0.6)
        expand.timingMode = .easeOut
        let hold = SKAction.wait(forDuration: 0.5)
        let fade = SKAction.fadeOut(withDuration: 0.5)
        let remove = SKAction.removeFromParent()
        
        glow.run(SKAction.sequence([
            SKAction.group([expand, fade]),
            remove
        ]))
        
        // ✅ Après l'effet → Sprout évolué
        let wait = SKAction.wait(forDuration: 0.8)
        run(SKAction.sequence([wait, SKAction.run { [weak self] in
            self?.startEvolvedIdleAnimation()
            self?.startEvolvedBlinkLoop()
            self?.playConfetti()
        }]))
    }
    
    func playSitDown() {
        guard let sprout = sprout else { return }
        sprout.removeAction(forKey: "idle")
        sprout.removeAction(forKey: "blink")
        
        // ✅ Sit down transition — 5 frames
        let sitDownFrames = (1...5).map {
            SKTexture(imageNamed: "Sprout_sitdown_\($0)")
        }
        let sitDown = SKAction.animate(
            with: sitDownFrames,
            timePerFrame: 0.15,
            resize: false,
            restore: false
        )
        
        // ✅ Sit idle loop — 4 frames
        let sitIdleFrames = (1...4).map {
            SKTexture(imageNamed: "Sprout_sit_idle_\($0)")
        }
        let sitIdle = SKAction.animate(
            with: sitIdleFrames,
            timePerFrame: 0.2,
            resize: false,
            restore: false
        )
        
        sprout.run(sitDown) { [weak self] in
            guard let self = self else { return }
            
            // ✅ Loop sit idle
            self.sprout?.run(
                SKAction.repeatForever(sitIdle),
                withKey: "sitIdle"
            )
            
            // ✅ Reste assis 5-10 secondes puis se relève
            let sitDuration = Double.random(in: 5...10)
            DispatchQueue.main.asyncAfter(deadline: .now() + sitDuration) {
                self.playStandUp()
            }
        }
    }

    func playStandUp() {
        guard let sprout = sprout else { return }
        sprout.removeAction(forKey: "sitIdle")
        
        // ✅ Stand up transition — 5 frames
        let standUpFrames = (1...5).map {
            SKTexture(imageNamed: "Sprout_standup_\($0)")
        }
        let standUp = SKAction.animate(
            with: standUpFrames,
            timePerFrame: 0.15,
            resize: false,
            restore: false
        )
        
        sprout.run(standUp) { [weak self] in
            self?.startIdleAnimation()
            self?.startBlinkLoop()
            self?.startRandomBehavior()  // ✅ reset le cycle
        }
    }
    
    var behaviorTimer: Timer?

    func startRandomBehavior() {
        // ✅ Toutes les 30-60 secondes — fait quelque chose
        let randomDelay = Double.random(in: 30...60)
        
        behaviorTimer = Timer.scheduledTimer(
            withTimeInterval: randomDelay,
            repeats: false
        ) { [weak self] _ in
            self?.chooseRandomBehavior()
        }
    }

    func chooseRandomBehavior() {
        let random = Int.random(in: 0...2)
        
        switch random {
        case 0:
            // ✅ Se balade puis revient
            playRandomWalk()
        case 1:
            // ✅ S'assoit
            playSitDown()
        case 2:
            // ✅ Reste en idle — reset le timer
            startRandomBehavior()
        default:
            startRandomBehavior()
        }
    }

    func playRandomWalk() {
        isWalking = true
        playWalk()
        
        // ✅ Marche pendant 3-6 secondes puis s'arrête
        let walkDuration = Double.random(in: 3...6)
        DispatchQueue.main.asyncAfter(deadline: .now() + walkDuration) { [weak self] in
            self?.isWalking = false
            self?.stopWalk()
            
            // ✅ Après la marche → peut s'asseoir ou idle
            let random = Int.random(in: 0...1)
            if random == 0 {
                self?.playSitDown()
            } else {
                self?.startRandomBehavior()  // ← retour idle + reset timer
            }
        }
    }

}

class SproutSceneHolder: ObservableObject {
    let scene: SproutScene
    
    init() {
        scene = SproutScene()
        scene.size = CGSize(width: 400, height: 600)
        scene.scaleMode = .aspectFit
        scene.backgroundColor = .clear
    }
}

struct SproutView: View {
    @StateObject private var holder = SproutSceneHolder()
    
    var body: some View {
        SpriteView(scene: holder.scene, options: [.allowsTransparency])
            .frame(width: 400, height: 500)
    }
}

#Preview {
    ZStack {
        Image("GrassBackgroundImage")
            .resizable()
            .frame(width: 900, height:900)
            .ignoresSafeArea()
        SproutView()
    }
}
