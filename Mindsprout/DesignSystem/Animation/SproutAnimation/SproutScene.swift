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

// ✅ SproutState EN DEHORS de SproutScene

class SproutScene: SKScene {
    var sprout: SKSpriteNode?
    var shadow: SKShapeNode?
    var isWalking = false
    var isHungry = false
    var isHappy = false
    var behaviorTimer: Timer?
    private var pendingState: SproutState = .idle  // ✅ une seule fois
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
        let aspect = texture.size().height / texture.size().width
        let sproutHeight = size.height * 0.9
        let sproutWidth = sproutHeight / aspect
        let sproutSize = CGSize(width: sproutWidth, height: sproutHeight)

        let shadowNode = SKShapeNode(ellipseOf: CGSize(width: sproutWidth * 0.55, height: 12))
        shadowNode.fillColor = UIColor.black.withAlphaComponent(0.2)
        shadowNode.strokeColor = .clear
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

        if let shadow = shadow {
            let dur = timePerFrame * Double(idleFrames.count) / 2
            let up = SKAction.scale(to: 1.05, duration: dur); up.timingMode = .easeInEaseOut
            let down = SKAction.scale(to: 1.0, duration: dur); down.timingMode = .easeInEaseOut
            shadow.run(SKAction.sequence([up, down]), withKey: "shadowBreath")
        }

        let done = SKAction.run { [weak self] in self?.isPlayingFaceGesture = false }
        sprout.run(SKAction.sequence([breath, done]), withKey: "faceGesture")
    }

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
        let wait = SKAction.wait(forDuration: 90, withRange: 60)
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
        let happyFrames = (1...11).map { SKTexture(imageNamed: "Sprout_happy_\($0)") }
        let happy = SKAction.animate(with: happyFrames, timePerFrame: 0.1, resize: false, restore: false)
        sprout.run(happy) { [weak self] in self?.startIdle() }
    }

    func tapReaction() {
        guard isIdle, let sprout = sprout else { return }
        sprout.removeAction(forKey: "randomWalk")
        isWalking = true
        playWalk()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let sprout = sprout else { return }
        if sprout.contains(touch.location(in: self)) {
            playSitDown()
        }
    }

    func playHungry() {
        guard let sprout = sprout else { return }
        stopIdleLoops()
        let hungryFrames = (1...10).map { SKTexture(imageNamed: "Sprout_hungry_\($0)") }
        let hungry = SKAction.animate(with: hungryFrames, timePerFrame: 0.15, resize: false, restore: false)
        let pityEyes = SKAction.animate(with: [SKTexture(imageNamed: "Sprout_hungry_5")], timePerFrame: 1.5, resize: false, restore: false)
        let cycle = SKAction.sequence([hungry, pityEyes])
        sprout.run(SKAction.repeatForever(cycle), withKey: "hungry")
    }

    func stopHungry() {
        sprout?.removeAction(forKey: "hungry")
        startIdle()
    }

    func onReflectionCompleted() {
        sprout?.removeAction(forKey: "hungry")
        playHappy()
    }

    func playWalk() {
        guard let sprout = sprout else { return }
        stopIdleLoops()
        let startFrames = (1...4).map { SKTexture(imageNamed: "Sprout_walk_start_\($0)") }
        let startTransition = SKAction.animate(with: startFrames, timePerFrame: 0.12, resize: false, restore: false)
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
        let walkFrames = (1...11).map { SKTexture(imageNamed: "Sprout_walk_\($0)") }
        let walk = SKAction.animate(with: walkFrames, timePerFrame: 0.1, resize: false, restore: false)
        let loopAction = SKAction.sequence([walk, SKAction.run { [weak self] in self?.walkLoop() }])
        sprout.run(loopAction, withKey: "walkLoop")
    }

    func stopWalk() {
        guard let sprout = sprout else { return }
        sprout.removeAction(forKey: "walkLoop")
        let endFrames = (1...4).map { SKTexture(imageNamed: "Sprout_walk_end_\($0)") }
        let endTransition = SKAction.animate(with: endFrames, timePerFrame: 0.12, resize: false, restore: false)
        sprout.run(endTransition) { [weak self] in
            guard let self = self else { return }
            self.isWalking = false
            self.startIdle()
        }
    }

    func playLevelUp(willEvolve: Bool = false) {
        guard let sprout = sprout else { return }
        stopIdleLoops()
        let levelUpFrames = (1...16).map { SKTexture(imageNamed: "Sprout_levelup_\($0)") }
        let levelUp = SKAction.animate(with: levelUpFrames, timePerFrame: 0.1, resize: false, restore: false)
        let waitForJump = SKAction.wait(forDuration: 0.6)
        let launchConfetti = SKAction.run { [weak self] in self?.playConfetti() }
        run(SKAction.sequence([waitForJump, launchConfetti]))
        sprout.run(levelUp) { [weak self] in
            guard let self = self else { return }
            if willEvolve { self.playSleepEvolution() } else { self.startIdle() }
        }
    }

    func playConfetti() {
        let colors: [UIColor] = [.systemYellow, .systemPink, .systemBlue, .systemGreen, .systemOrange, .systemPurple]
        for _ in 0..<20 {
            let confetti = SKShapeNode(rectOf: CGSize(width: 8, height: 8), cornerRadius: 2)
            confetti.fillColor = colors.randomElement()!
            confetti.strokeColor = .clear
            confetti.position = CGPoint(
                x: (sprout?.position.x ?? size.width/2) + CGFloat.random(in: -50...50),
                y: (sprout?.position.y ?? size.height/2) + (sprout?.size.height ?? 0) / 2
            )
            confetti.zPosition = 10
            addChild(confetti)
            let moveUp = SKAction.moveBy(x: CGFloat.random(in: -80...80), y: CGFloat.random(in: 100...200), duration: 0.4)
            let fall = SKAction.moveBy(x: CGFloat.random(in: -40...40), y: -300, duration: 0.8)
            let fade = SKAction.fadeOut(withDuration: 0.3)
            let rotate = SKAction.rotate(byAngle: CGFloat.random(in: -CGFloat.pi...CGFloat.pi), duration: 1.2)
            let sequence = SKAction.sequence([moveUp, fall, fade, SKAction.removeFromParent()])
            confetti.run(SKAction.group([sequence, rotate]))
        }
    }

    func playSleepDaily() {
        guard let sprout = sprout else { return }
        stopIdleLoops()
        let yawnFrames = (1...7).map { SKTexture(imageNamed: "Sprout_yawn_\($0)") }
        let yawn = SKAction.animate(with: yawnFrames, timePerFrame: 0.18, resize: false, restore: false)
        let fallFrames = (1...4).map { SKTexture(imageNamed: "Sprout_fall_\($0)") }
        let fall = SKAction.animate(with: fallFrames, timePerFrame: 0.15, resize: false, restore: false)
        let sleepFrames = (1...7).map { SKTexture(imageNamed: "Sprout_sleep_\($0)") }
        let sleepLoop = SKAction.animate(with: sleepFrames, timePerFrame: 0.3, resize: false, restore: false)
        sprout.run(SKAction.sequence([yawn, fall])) { [weak self] in
            self?.sprout?.run(SKAction.repeatForever(sleepLoop), withKey: "sleepLoop")
        }
    }

    func playWakeUpDaily() {
        guard let sprout = sprout else { return }
        sprout.removeAction(forKey: "sleepLoop")
        let wakeUpFrames = (1...15).map { SKTexture(imageNamed: "Sprout_wakeup_\($0)") }
        let wakeUp = SKAction.animate(with: wakeUpFrames, timePerFrame: 0.12, resize: false, restore: false)
        sprout.run(wakeUp) { [weak self] in self?.startIdle() }
    }

    func playSleepEvolution() {
        guard let sprout = sprout else { return }
        stopIdleLoops()
        let yawnFrames = (1...7).map { SKTexture(imageNamed: "Sprout_yawn_\($0)") }
        let yawn = SKAction.animate(with: yawnFrames, timePerFrame: 0.18, resize: false, restore: false)
        let fallFrames = (1...4).map { SKTexture(imageNamed: "Sprout_fall_\($0)") }
        let fall = SKAction.animate(with: fallFrames, timePerFrame: 0.15, resize: false, restore: false)
        let sleepFrames = (1...7).map { SKTexture(imageNamed: "Sprout_sleep_\($0)") }
        let sleepLoop = SKAction.animate(with: sleepFrames, timePerFrame: 0.3, resize: false, restore: false)
        sprout.run(SKAction.sequence([yawn, fall])) { [weak self] in
            guard let self = self else { return }
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "sproutSleepTime")
            UserDefaults.standard.set(true, forKey: "sproutIsEvolving")
            self.sprout?.run(SKAction.repeatForever(sleepLoop), withKey: "sleepLoop")
        }
    }

    func playWakeUpAndEvolve() {
        guard let sprout = sprout else { return }
        sprout.removeAction(forKey: "sleepLoop")
        let wakeUpFrames = (1...15).map { SKTexture(imageNamed: "Sprout_wakeup_\($0)") }
        let wakeUp = SKAction.animate(with: wakeUpFrames, timePerFrame: 0.12, resize: false, restore: false)
        sprout.run(wakeUp) { [weak self] in
            self?.playEvolutionFlash()
        }
    }

    func startEvolvedIdleAnimation() {
        guard let sprout = sprout else { return }
        let evolvedIdleFrames = (1...8).map { SKTexture(imageNamed: "Sprout_evolved_1_idle_\($0)") }
        let animate = SKAction.animate(with: evolvedIdleFrames, timePerFrame: 0.2, resize: false, restore: false)
        let breatheIn = SKAction.scaleY(to: 1.03, duration: 0.8); breatheIn.timingMode = .easeInEaseOut
        let breatheOut = SKAction.scaleY(to: 1.0, duration: 0.8); breatheOut.timingMode = .easeInEaseOut
        let breathe = SKAction.repeatForever(SKAction.sequence([breatheIn, breatheOut]))
        sprout.run(SKAction.group([SKAction.repeatForever(animate), breathe]), withKey: "idle")
    }

    func startEvolvedBlinkLoop() {
        guard let sprout = sprout else { return }
        let blinkFrames = [1, 2, 3, 2, 1].map { SKTexture(imageNamed: "Sprout_evolved_1_blink_\($0)") }
        let wait = SKAction.wait(forDuration: 3.0)
        let stopIdle = SKAction.run { sprout.removeAction(forKey: "idle") }
        let blink = SKAction.animate(with: blinkFrames, timePerFrame: 0.08, resize: false, restore: true)
        let resumeIdle = SKAction.run { [weak self] in self?.startEvolvedIdleAnimation() }
        sprout.run(SKAction.repeatForever(SKAction.sequence([wait, stopIdle, blink, resumeIdle])), withKey: "blink")
    }

    func playEvolutionFlash() {
        let center = CGPoint(x: size.width/2, y: size.height/2)
        for i in 0..<8 {
            let angle = CGFloat(i) * CGFloat.pi / 4
            let ray = SKShapeNode(rectOf: CGSize(width: 8, height: 200))
            ray.fillColor = UIColor.white.withAlphaComponent(0.8)
            ray.strokeColor = .clear
            ray.position = center
            ray.zRotation = angle
            ray.zPosition = 99
            ray.alpha = 0
            ray.setScale(0)
            addChild(ray)
            let fadeIn = SKAction.fadeIn(withDuration: 0.2)
            let expand = SKAction.scale(to: 1.5, duration: 0.6); expand.timingMode = .easeOut
            let hold = SKAction.wait(forDuration: 0.5)
            let fadeOut = SKAction.fadeOut(withDuration: 0.5)
            let remove = SKAction.removeFromParent()
            ray.run(SKAction.sequence([fadeIn, SKAction.group([expand, SKAction.wait(forDuration: 0.6)]), hold, fadeOut, remove]))
        }
        let glow = SKShapeNode(circleOfRadius: 5)
        glow.fillColor = .white
        glow.strokeColor = .clear
        glow.position = center
        glow.zPosition = 99
        addChild(glow)
        let expand = SKAction.scale(to: 15, duration: 0.6); expand.timingMode = .easeOut
        let hold = SKAction.wait(forDuration: 0.5)
        let fade = SKAction.fadeOut(withDuration: 0.5)
        glow.run(SKAction.sequence([SKAction.group([expand, SKAction.wait(forDuration: 0.6)]), hold, fade, SKAction.removeFromParent()]))
        let wait = SKAction.wait(forDuration: 1.8)
        run(SKAction.sequence([wait, SKAction.run { [weak self] in
            self?.startEvolvedIdleAnimation()
            self?.startEvolvedBlinkLoop()
            self?.playConfetti()
            UserDefaults.standard.set(false, forKey: "sproutIsEvolving")
            UserDefaults.standard.set(UserDefaults.standard.integer(forKey: "sproutLevel") + 1, forKey: "sproutLevel")
        }]))
    }

    func playSitDown() {
        guard let sprout = sprout else { return }
        stopIdleLoops()
        let sitDownFrames = (1...5).map { SKTexture(imageNamed: "Sprout_sitdown_\($0)") }
        let sitDown = SKAction.animate(with: sitDownFrames, timePerFrame: 0.15, resize: false, restore: false)
        let sitIdleFrames = (1...4).map { SKTexture(imageNamed: "Sprout_sit_idle_\($0)") }
        let sitIdle = SKAction.animate(with: sitIdleFrames, timePerFrame: 0.2, resize: false, restore: false)
        sprout.run(sitDown) { [weak self] in
            guard let self = self else { return }
            self.sprout?.run(SKAction.repeatForever(sitIdle), withKey: "sitIdle")
            let sitDuration = Double.random(in: 5...10)
            DispatchQueue.main.asyncAfter(deadline: .now() + sitDuration) { self.playStandUp() }
        }
    }

    func playStandUp() {
        guard let sprout = sprout else { return }
        sprout.removeAction(forKey: "sitIdle")
        let standUpFrames = (1...5).map { SKTexture(imageNamed: "Sprout_standup_\($0)") }
        let standUp = SKAction.animate(with: standUpFrames, timePerFrame: 0.15, resize: false, restore: false)
        sprout.run(standUp) { [weak self] in
            self?.startIdle()
            self?.startRandomBehavior()
        }
    }

    func startRandomBehavior() {
        let randomDelay = Double.random(in: 30...60)
        behaviorTimer = Timer.scheduledTimer(withTimeInterval: randomDelay, repeats: false) { [weak self] _ in
            self?.chooseRandomBehavior()
        }
    }

    func chooseRandomBehavior() {
        let random = Int.random(in: 0...2)
        switch random {
        case 0: playRandomWalk()
        case 1: playSitDown()
        default: startRandomBehavior()
        }
    }

    func playRandomWalk() {
        isWalking = true
        playWalk()
        let walkDuration = Double.random(in: 3...6)
        DispatchQueue.main.asyncAfter(deadline: .now() + walkDuration) { [weak self] in
            self?.isWalking = false
            self?.stopWalk()
            if Int.random(in: 0...1) == 0 { self?.playSitDown() }
            else { self?.startRandomBehavior() }
        }
    }

    func playEvolution() {
        startIdle()
    }
}

// ✅ SproutSceneHolder
class SproutSceneHolder: ObservableObject {
    let scene: SproutScene
    init() {
        scene = SproutScene()
        scene.size = CGSize(width: 300, height: 400)
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear
    }
}

// ✅ SproutView
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
