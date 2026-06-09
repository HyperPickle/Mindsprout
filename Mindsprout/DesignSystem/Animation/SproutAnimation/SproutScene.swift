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
    var shadow: SKShapeNode?
    var isWalking = false
    var isHungry = false
    var isHappy = false
    private var pendingState: SproutState = .idle
    // Breathe and blink both drive the node texture, so only one may play at a time.
    private var isPlayingFaceGesture = false

    var isIdle: Bool {
        !isWalking && !isHungry && !isHappy
    }

    override func didMove(to view: SKView) {
        backgroundColor = .clear

        guard UIImage(named: "Sprout_idle_1") != nil else {
            print("❌ Sprout_idle_1 not found")
            return
        }

        let texture = SKTexture(imageNamed: "Sprout_idle_1")
        // Size from the texture's true aspect ratio (~1.576) so the sprite never stretches.
        // Driven by height so it always fits the box; "bigger" is controlled by the layout box.
        let aspect = texture.size().height / texture.size().width
        let sproutHeight = size.height * 0.9
        let sproutWidth = sproutHeight / aspect
        let sproutSize = CGSize(width: sproutWidth, height: sproutHeight)

        let shadowNode = SKShapeNode(ellipseOf: CGSize(width: sproutWidth * 0.55, height: 12))
        shadowNode.fillColor = UIColor.black.withAlphaComponent(0.2)
        shadowNode.strokeColor = .clear
        // Sit near the feet: the art has transparent padding below, so offset up ~0.28 of height. Tunable.
        shadowNode.position = CGPoint(x: size.width / 2, y: size.height / 2 - sproutHeight / 2 + sproutHeight * 0.28)
        shadowNode.zPosition = 0
        addChild(shadowNode)
        shadow = shadowNode

        let sproutNode = SKSpriteNode(texture: texture)
        sproutNode.size = sproutSize
        sproutNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        sproutNode.zPosition = 1
        addChild(sproutNode)
        sprout = sproutNode

        updateState(pendingState)
    }

    func updateState(_ state: SproutState) {
        guard let sprout = sprout else {
            pendingState = state
            return
        }
        pendingState = state
        sprout.removeAllActions()
        isWalking = false
        isHungry = false
        isHappy = false

        switch state {
        case .idle, .readyToEvolve:
            startIdle()
        case .hungry:
            isHungry = true
            playHungry()
        case .evolving:
            playEvolution()
        case .sleeping:
            break
        }
    }

    // Rest on the base frame and start the three independent idle loops.
    func startIdle() {
        guard let sprout = sprout else { return }
        stopIdleLoops()
        sprout.texture = SKTexture(imageNamed: "Sprout_idle_1")
        startBreatheLoop()
        startBlinkLoop()
        scheduleRandomWalk()
    }

    private func stopIdleLoops() {
        sprout?.removeAction(forKey: "breathe")
        sprout?.removeAction(forKey: "blink")
        sprout?.removeAction(forKey: "randomWalk")
        sprout?.removeAction(forKey: "faceGesture")
        isPlayingFaceGesture = false
    }

    // Breathe ~every 10–15s by playing the idle frames once.
    func startBreatheLoop() {
        guard let sprout = sprout else { return }
        let wait = SKAction.wait(forDuration: 12.5, withRange: 5)
        let fire = SKAction.run { [weak self] in self?.playBreath() }
        sprout.run(SKAction.repeatForever(SKAction.sequence([wait, fire])), withKey: "breathe")
    }

    private func playBreath() {
        guard let sprout = sprout, isIdle, !isPlayingFaceGesture else { return }
        isPlayingFaceGesture = true

        let idleFrames = (1...9).map { SKTexture(imageNamed: "Sprout_idle_\($0)") }
        let timePerFrame = 0.15
        let breath = SKAction.animate(with: idleFrames, timePerFrame: timePerFrame, resize: false, restore: true)

        // Shadow swells with the breath.
        if let shadow = shadow {
            let dur = timePerFrame * Double(idleFrames.count) / 2
            let up = SKAction.scale(to: 1.05, duration: dur); up.timingMode = .easeInEaseOut
            let down = SKAction.scale(to: 1.0, duration: dur); down.timingMode = .easeInEaseOut
            shadow.run(SKAction.sequence([up, down]), withKey: "shadowBreath")
        }

        let done = SKAction.run { [weak self] in self?.isPlayingFaceGesture = false }
        sprout.run(SKAction.sequence([breath, done]), withKey: "faceGesture")
    }

    // Blink ~every 4–6s.
    func startBlinkLoop() {
        guard let sprout = sprout else { return }
        let wait = SKAction.wait(forDuration: 5, withRange: 2)
        let fire = SKAction.run { [weak self] in self?.playBlink() }
        sprout.run(SKAction.repeatForever(SKAction.sequence([wait, fire])), withKey: "blink")
    }

    private func playBlink() {
        guard let sprout = sprout, isIdle, !isPlayingFaceGesture else { return }
        isPlayingFaceGesture = true

        let blinkFrames = [1, 2, 3, 2, 1].map { SKTexture(imageNamed: "Sprout_blink_\($0)") }
        let blink = SKAction.animate(with: blinkFrames, timePerFrame: 0.08, resize: false, restore: true)

        let done = SKAction.run { [weak self] in self?.isPlayingFaceGesture = false }
        sprout.run(SKAction.sequence([blink, done]), withKey: "faceGesture")
    }

    func scheduleRandomWalk() {
        guard let sprout = sprout else { return }
        let wait = SKAction.wait(forDuration: 90, withRange: 60) // ~60–120s
        let walk = SKAction.run { [weak self] in
            guard let self = self, self.isIdle else {
                self?.scheduleRandomWalk()
                return
            }
            self.isWalking = true
            self.playWalk()
        }
        sprout.run(SKAction.sequence([wait, walk]), withKey: "randomWalk")
    }

    func playHappy() {
        guard let sprout = sprout else { return }

        stopIdleLoops()

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
            self?.startIdle()
        }
    }
    
    func tapReaction() {
        guard isIdle, let sprout = sprout else { return }
        sprout.removeAction(forKey: "randomWalk")
        isWalking = true
        playWalk()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let sprout = sprout else { return }
        
        if sprout.contains(touch.location(in: self)) {
            // Test sans évolution
            playLevelUp(willEvolve: false)
            
            // Test avec évolution
            // playLevelUp(willEvolve: true)
        }
    }
    
    func playHungry() {
        guard let sprout = sprout else { return }
        stopIdleLoops()

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
        startIdle()
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
        stopIdleLoops()

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
        
        let walkDuration = Double.random(in: 3...6)
        let waitThenStop = SKAction.sequence([
            SKAction.wait(forDuration: walkDuration),
            SKAction.run { [weak self] in self?.stopWalk() }
        ])

        sprout.run(startTransition) { [weak self] in
            guard let self = self else { return }
            self.walkLoop()
            self.sprout?.run(waitThenStop, withKey: "walkTimer")
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
        
        let loopAction = SKAction.sequence([
            walk,
            SKAction.run { [weak self] in self?.walkLoop() }
        ])
        sprout.run(loopAction, withKey: "walkLoop")
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
            guard let self = self else { return }
            self.isWalking = false
            self.startIdle()
        }
    }
    
    //LEVEL UP
    func playLevelUp(willEvolve: Bool = false) {
        guard let sprout = sprout else { return }
        stopIdleLoops()

        let levelUpFrames = (1...8).map {
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
                self.playEvolution()
            } else {
                self.startIdle()
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

    func playEvolution() {
        // TODO: play evolution frames when assets are available
        startIdle()
    }

}

class SproutSceneHolder: ObservableObject {
    let scene: SproutScene

    init() {
        scene = SproutScene()
        scene.size = CGSize(width: 300, height: 400)
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear
    }
}

struct SproutView: View {
    let state: SproutState
    @StateObject private var holder = SproutSceneHolder()

    var body: some View {
        SpriteView(scene: holder.scene, options: [.allowsTransparency])
            .onChange(of: state, initial: true) { _, newState in
                holder.scene.updateState(newState)
            }
            .onTapGesture {
                holder.scene.tapReaction()
            }
    }
}

#Preview {
    ZStack {
        Image("GrassBackgroundImage")
            .resizable()
            .frame(width: 900, height: 900)
            .ignoresSafeArea()
        SproutView(state: .idle)
    }
}
