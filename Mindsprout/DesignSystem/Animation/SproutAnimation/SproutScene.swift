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
    // ✅ Sprout + Shadow
    var sprout: SKSpriteNode?
    var shadow: SKShapeNode?

    private let sproutHeight: CGFloat = 400
    private var idleSproutSize: CGSize = .zero
    private var sleepSproutSize: CGSize = .zero
    
    // ✅ États
    var isWalking = false
    var isReturning = false
    var isHungry = false
    var isHappy = false
    var isDoingBehavior = false
    private var pendingState: SproutState = .idle
    private var isPlayingFaceGesture = false
    
    var isIdle: Bool {
        !isWalking && !isHungry && !isHappy && !isDoingBehavior
    }
    
    // ✅ Comportement aléatoire
    var behaviorTimer: Timer?
    var lastBehavior: Int = -1
    
    // ✅ Touch / Drag / Tap
    var isDragging = false
    var dragOffset = CGPoint.zero
    var lastTouchPosition = CGPoint.zero
    var touchPoints: [CGPoint] = []
    var swipeStartX: CGFloat = 0
    var touchStartTime: TimeInterval = 0
    var touchStartPosition: CGPoint = .zero
    var tapCount = 0
    var tapTimer: Timer?
    private var touchStartedOnSprout = false
    private var presentationScale: CGFloat = 1
    private var restingVerticalOffset: CGFloat = 0

    private var restingPosition: CGPoint {
        CGPoint(x: size.width / 2, y: size.height / 2 - restingVerticalOffset)
    }

    func configurePresentation(scale: CGFloat, restingVerticalOffset: CGFloat) {
        presentationScale = scale
        self.restingVerticalOffset = restingVerticalOffset

        guard let sprout, !isDragging, !isReturning else { return }
        sprout.setScale(scale)
        sprout.position = restingPosition
    }

    // MARK: - Setup
    
    override func didMove(to view: SKView) {
        backgroundColor = .clear

        guard UIImage(named: "Sprout_idle_1") != nil else {
            print("❌ Sprout_idle_1 not found")
            return
        }

        let texture = SKTexture(imageNamed: "Sprout_idle_1")
        let aspect = texture.size().height / texture.size().width
        let sproutWidth = sproutHeight / aspect
        let sproutSize = CGSize(width: sproutWidth, height: sproutHeight)
        idleSproutSize = sproutSize
        sleepSproutSize = CGSize(width: sproutHeight * (674.0 / 800.0), height: sproutHeight)

        // ✅ Sprout
        let sproutNode = SKSpriteNode(texture: texture)
        sproutNode.size = sproutSize
        sproutNode.position = restingPosition
        sproutNode.setScale(presentationScale)
        sproutNode.zPosition = 1
        addChild(sproutNode)
        sprout = sproutNode

        // ✅ Ombre enfant de Sprout
        let shadowNode = SKShapeNode(ellipseOf: CGSize(width: sproutWidth * 0.55, height: 12))
        shadowNode.fillColor = UIColor.black.withAlphaComponent(0.2)
        shadowNode.strokeColor = .clear
        shadowNode.position = CGPoint(x: 0, y: -sproutHeight / 2 + sproutHeight * 0.28)
        shadowNode.zPosition = -1
        sproutNode.addChild(shadowNode)
        shadow = shadowNode

        updateState(pendingState)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard oldSize != .zero, let sprout, !isDragging, !isReturning else { return }
        sprout.position = restingPosition
    }

    // MARK: - State

    func updateState(_ state: SproutState) {
        pendingState = state
        guard !isDragging else { return }
        guard let sprout = sprout else {
            return
        }
        sprout.removeAllActions()
        isWalking = false
        isHungry = false
        isHappy = false
        isDoingBehavior = false

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

    private func resumePendingState() {
        updateState(pendingState)
    }

    // MARK: - Idle

    func startIdle() {
        guard let sprout = sprout, !isDragging else { return }
        stopIdleLoops()
        sprout.zRotation = 0
        sprout.xScale = 1.0
        sprout.yScale = 1.0
        sprout.setScale(presentationScale)
        applySize(CGSize(
            width: sproutHeight * HomeDashboardLayout.sproutAspectRatio,
            height: sproutHeight
        ))
        sprout.texture = SKTexture(imageNamed: "Sprout_idle_1")
        startBreatheLoop()
        startBlinkLoop()
        startRandomBehavior()
    }

    private func stopIdleLoops() {
        sprout?.removeAction(forKey: "breathe")
        sprout?.removeAction(forKey: "blink")
        sprout?.removeAction(forKey: "faceGesture")
        isPlayingFaceGesture = false
    }

    func startBreatheLoop() {
        guard let sprout = sprout else { return }
        let wait = SKAction.wait(forDuration: 5.5, withRange: 3)
        let fire = SKAction.run { [weak self] in self?.playBreath() }
        sprout.run(SKAction.repeatForever(SKAction.sequence([wait, fire])), withKey: "breathe")
    }

    private func playBreath() {
        guard let sprout = sprout,
              isIdle,
              !isPlayingFaceGesture else { return }
        isPlayingFaceGesture = true

        sprout.texture = SKTexture(imageNamed: "Sprout_idle_1")

        let inhaleX = SKAction.scaleX(to: presentationScale * 0.985, duration: 0.55)
        inhaleX.timingMode = .easeInEaseOut
        let inhaleY = SKAction.scaleY(to: presentationScale * 1.02, duration: 0.55)
        inhaleY.timingMode = .easeInEaseOut
        let exhaleX = SKAction.scaleX(to: presentationScale, duration: 0.55)
        exhaleX.timingMode = .easeInEaseOut
        let exhaleY = SKAction.scaleY(to: presentationScale, duration: 0.55)
        exhaleY.timingMode = .easeInEaseOut
        let breath = SKAction.sequence([
            .group([inhaleX, inhaleY]),
            .group([exhaleX, exhaleY])
        ])

        if let shadow = shadow {
            let up = SKAction.scale(to: 1.05, duration: 0.55); up.timingMode = .easeInEaseOut
            let down = SKAction.scale(to: 1.0, duration: 0.55); down.timingMode = .easeInEaseOut
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

    // MARK: - Emotions

    func playHappy() {
        guard let sprout = sprout else { return }
        stopIdleLoops()
        isHappy = true
        let happyFrames = (1...11).map { SKTexture(imageNamed: "Sprout_happy_\($0)") }
        let happy = SKAction.animate(with: happyFrames, timePerFrame: 0.1, resize: false, restore: false)
        sprout.run(happy) { [weak self] in
            self?.isHappy = false
            self?.startIdle()
        }
    }

    func playHungry() {
        guard let sprout = sprout else { return }
        stopIdleLoops()
        let hungryFrames = (1...10).map { SKTexture(imageNamed: "Sprout_hungry_\($0)") }
        let hungry = SKAction.animate(with: hungryFrames, timePerFrame: 0.15, resize: false, restore: false)
        let pityEyes = SKAction.animate(with: [SKTexture(imageNamed: "Sprout_hungry_5")], timePerFrame: 1.5, resize: false, restore: false)
        sprout.run(SKAction.repeatForever(SKAction.sequence([hungry, pityEyes])), withKey: "hungry")
    }

    func stopHungry() {
        sprout?.removeAction(forKey: "hungry")
        startIdle()
    }

    func onReflectionCompleted() {
        sprout?.removeAction(forKey: "hungry")
        isHungry = false
        playHappy()
    }

    // MARK: - Jump

    func playJump() {
        guard let sprout = sprout else { return }
        stopIdleLoops()

        let levelUpFrames = (1...16).map { SKTexture(imageNamed: "Sprout_levelup_\($0)") }
        let jumpBig = SKAction.animate(with: levelUpFrames, timePerFrame: 0.1, resize: false, restore: false)
        let jumpSmall = SKAction.animate(with: levelUpFrames, timePerFrame: 0.06, resize: false, restore: false)

        sprout.run(SKAction.sequence([jumpBig, jumpSmall])) { [weak self] in
            self?.startIdle()
        }
    }

    // MARK: - Walk

    func playWalk() {
        guard let sprout = sprout else { return }
        stopIdleLoops()

        let goRight = Bool.random()
        let direction: CGFloat = goRight ? 1 : -1
        sprout.xScale = goRight ? 1.0 : -1.0

        let startFrames = (1...4).map { SKTexture(imageNamed: "Sprout_walk_start_\($0)") }
        let startTransition = SKAction.animate(with: startFrames, timePerFrame: 0.12, resize: false, restore: false)

        let walkDuration = Double.random(in: 3...6)
        let walkDistance = direction * CGFloat(walkDuration) * 40
        let moveAction = SKAction.moveBy(x: walkDistance, y: 0, duration: walkDuration)

        let waitThenStop = SKAction.sequence([
            SKAction.wait(forDuration: walkDuration),
            SKAction.run { [weak self] in self?.stopWalk() }
        ])

        sprout.run(startTransition) { [weak self] in
            guard let self = self else { return }
            self.walkLoop()
            self.sprout?.run(moveAction, withKey: "walkMove")
            self.sprout?.run(waitThenStop, withKey: "walkTimer")
        }
    }

    func walkLoop() {
        guard let sprout = sprout, isWalking else { return }
        let walkFrames = (1...11).map { SKTexture(imageNamed: "Sprout_walk_\($0)") }
        let walk = SKAction.animate(with: walkFrames, timePerFrame: 0.1, resize: false, restore: false)
        sprout.run(SKAction.sequence([walk, SKAction.run { [weak self] in self?.walkLoop() }]), withKey: "walkLoop")
    }

    func stopWalk() {
        guard let sprout = sprout, !isDragging else { return }
        sprout.removeAllActions()
        isWalking = false

        let center = restingPosition
        let distance = abs(sprout.position.x - center.x)
        let returnDuration = Double(distance / 80)

        sprout.xScale = sprout.position.x > center.x ? -1.0 : 1.0
        isReturning = true
        returnWalkLoop()

        let returnHome = SKAction.move(to: center, duration: returnDuration)
        returnHome.timingMode = .linear

        sprout.run(returnHome) { [weak self] in
            guard let self = self else { return }
            self.isReturning = false

            let endFrames = (1...4).map { SKTexture(imageNamed: "Sprout_walk_end_\($0)") }
            let endTransition = SKAction.animate(with: endFrames, timePerFrame: 0.12, resize: false, restore: false)

            self.sprout?.run(endTransition) { [weak self] in
                self?.sprout?.xScale = 1.0
                self?.startIdle()
            }
        }
    }

    func returnWalkLoop() {
        guard let sprout = sprout, isReturning else { return }
        let walkFrames = (1...11).map { SKTexture(imageNamed: "Sprout_walk_\($0)") }
        let walk = SKAction.animate(with: walkFrames, timePerFrame: 0.1, resize: false, restore: false)
        sprout.run(walk) { [weak self] in self?.returnWalkLoop() }
    }

    // MARK: - Random Behavior

    func startRandomBehavior() {
        guard !isDoingBehavior, !isDragging else { return }
        behaviorTimer?.invalidate()
        let randomDelay = Double.random(in: 10...30)
        behaviorTimer = Timer.scheduledTimer(withTimeInterval: randomDelay, repeats: false) { [weak self] _ in
            guard let self = self, self.isIdle else {
                self?.startRandomBehavior()
                return
            }
            self.chooseRandomBehavior()
        }
    }

    func chooseRandomBehavior() {
        guard !isDragging else { return }
        isDoingBehavior = true
        var random: Int
        repeat { random = Int.random(in: 0...3) } while random == lastBehavior
        lastBehavior = random

        switch random {
        case 0: walkThenReturn()
        case 1: playSitDown()
        case 2:
            playJump()
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                self?.isDoingBehavior = false
                self?.startRandomBehavior()
            }
        case 3: playSleepDaily()
        default:
            isDoingBehavior = false
            startRandomBehavior()
        }
    }

    func walkThenReturn() {
        isWalking = true
        playWalk()
        let walkDuration = Double.random(in: 3...6)
        DispatchQueue.main.asyncAfter(deadline: .now() + walkDuration) { [weak self] in
            guard let self = self else { return }
            self.isWalking = false
            self.stopWalk()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.isDoingBehavior = false
                self?.startRandomBehavior()
            }
        }
    }

    // MARK: - Sit

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
        guard let sprout = sprout, !isDragging else { return }
        sprout.removeAction(forKey: "sitIdle")
        let standUpFrames = (1...5).map { SKTexture(imageNamed: "Sprout_standup_\($0)") }
        let standUp = SKAction.animate(with: standUpFrames, timePerFrame: 0.15, resize: false, restore: false)
        sprout.run(standUp) { [weak self] in
            self?.isDoingBehavior = false
            self?.startIdle()
        }
    }

    // MARK: - LevelUp + Evolution

    func playLevelUp(willEvolve: Bool = false) {
        guard let sprout = sprout else { return }
        stopIdleLoops()
        let levelUpFrames = (1...16).map { SKTexture(imageNamed: "Sprout_levelup_\($0)") }
        let levelUp = SKAction.animate(with: levelUpFrames, timePerFrame: 0.1, resize: false, restore: false)
        run(SKAction.sequence([SKAction.wait(forDuration: 0.6), SKAction.run { [weak self] in self?.playConfetti() }]))
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
            confetti.run(SKAction.group([SKAction.sequence([moveUp, fall, fade, SKAction.removeFromParent()]), rotate]))
        }
    }

    func playEvolution() { startIdle() }

    // MARK: - Sleep

    private func applySize(_ size: CGSize) {
        sprout?.size = size
        if let shadow {
            shadow.path = CGPath(ellipseIn: CGRect(
                x: -size.width * 0.55 / 2, y: -6,
                width: size.width * 0.55, height: 12
            ), transform: nil)
        }
    }

    func playSleepDaily() {
        guard let sprout = sprout, !isDragging else { return }
        stopIdleLoops()
        let yawnFrames = (1...7).map { SKTexture(imageNamed: "Sprout_yawn_\($0)") }
        let yawn = SKAction.animate(with: yawnFrames, timePerFrame: 0.18, resize: false, restore: false)
        let switchToSleepSize = SKAction.run { [weak self] in
            guard let self else { return }
            self.applySize(self.sleepSproutSize)
        }
        let fallFrames = (1...4).map { SKTexture(imageNamed: "Sprout_fall_\($0)") }
        let fall = SKAction.animate(with: fallFrames, timePerFrame: 0.15, resize: false, restore: false)
        let sleepFrames = (1...7).map { SKTexture(imageNamed: "Sprout_sleep_\($0)") }
        let sleepLoop = SKAction.animate(with: sleepFrames, timePerFrame: 0.3, resize: false, restore: false)
        sprout.run(SKAction.sequence([yawn, switchToSleepSize, fall])) { [weak self] in
            self?.sprout?.run(SKAction.repeatForever(sleepLoop), withKey: "sleepLoop")
        }
    }

    func playWakeUpDaily() {
        guard let sprout = sprout else { return }
        sprout.removeAction(forKey: "sleepLoop")
        let wakeUpFrames = (1...15).map { SKTexture(imageNamed: "Sprout_wakeup_\($0)") }
        let wakeUp = SKAction.animate(with: wakeUpFrames, timePerFrame: 0.12, resize: false, restore: false)
        sprout.run(wakeUp) { [weak self] in
            guard let self else { return }
            self.applySize(self.idleSproutSize)
            self.startIdle()
        }
    }

    func playSleepEvolution() {
        guard let sprout = sprout else { return }
        stopIdleLoops()
        let yawnFrames = (1...7).map { SKTexture(imageNamed: "Sprout_yawn_\($0)") }
        let yawn = SKAction.animate(with: yawnFrames, timePerFrame: 0.18, resize: false, restore: false)
        let switchToSleepSize = SKAction.run { [weak self] in
            guard let self else { return }
            self.applySize(self.sleepSproutSize)
        }
        let fallFrames = (1...4).map { SKTexture(imageNamed: "Sprout_fall_\($0)") }
        let fall = SKAction.animate(with: fallFrames, timePerFrame: 0.15, resize: false, restore: false)
        let sleepFrames = (1...7).map { SKTexture(imageNamed: "Sprout_sleep_\($0)") }
        let sleepLoop = SKAction.animate(with: sleepFrames, timePerFrame: 0.3, resize: false, restore: false)
        sprout.run(SKAction.sequence([yawn, switchToSleepSize, fall])) { [weak self] in
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
            guard let self else { return }
            self.applySize(self.idleSproutSize)
            self.playEvolutionFlash()
        }
    }

    // MARK: - Evolved

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
            ray.run(SKAction.sequence([fadeIn, SKAction.group([expand, SKAction.wait(forDuration: 0.6)]), hold, fadeOut, SKAction.removeFromParent()]))
        }
        let glow = SKShapeNode(circleOfRadius: 5)
        glow.fillColor = .white
        glow.strokeColor = .clear
        glow.position = center
        glow.zPosition = 99
        addChild(glow)
        let expand = SKAction.scale(to: 15, duration: 0.6); expand.timingMode = .easeOut
        glow.run(SKAction.sequence([SKAction.group([expand, SKAction.wait(forDuration: 0.6)]), SKAction.wait(forDuration: 0.5), SKAction.fadeOut(withDuration: 0.5), SKAction.removeFromParent()]))
        run(SKAction.sequence([SKAction.wait(forDuration: 1.8), SKAction.run { [weak self] in
            self?.startEvolvedIdleAnimation()
            self?.startEvolvedBlinkLoop()
            self?.playConfetti()
            UserDefaults.standard.set(false, forKey: "sproutIsEvolving")
            UserDefaults.standard.set(UserDefaults.standard.integer(forKey: "sproutLevel") + 1, forKey: "sproutLevel")
        }]))
    }

    // MARK: - Sit/Stand

    // MARK: - Drag & Touch

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        beginInteraction(at: touch.location(in: self), timestamp: touch.timestamp)
    }

    func beginInteraction(at location: CGPoint, timestamp: TimeInterval) {
        guard let sprout else { return }
        touchPoints = [location]
        swipeStartX = location.x
        lastTouchPosition = location
        touchStartTime = timestamp
        touchStartPosition = location
        touchStartedOnSprout = sprout.contains(location)

        if touchStartedOnSprout {
            dragOffset = CGPoint(x: sprout.position.x - location.x, y: sprout.position.y - location.y)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        updateInteraction(to: touch.location(in: self))
    }

    func updateInteraction(to location: CGPoint) {
        guard let sprout else { return }
        let distanceMoved = abs(location.x - touchStartPosition.x) + abs(location.y - touchStartPosition.y)

        // ✅ Démarre le drag seulement si bougé > 10px
        if distanceMoved > 10 && touchStartedOnSprout {
            if !isDragging {
                isDragging = true
                isReturning = false
                stopIdleLoops()
                behaviorTimer?.invalidate()
                tapTimer?.invalidate()
                tapCount = 0
                isWalking = false
                isHappy = false
                isDoingBehavior = false
                sprout.removeAllActions()
                shadow?.removeAllActions()

                let grabbedFrames = (1...5).map { SKTexture(imageNamed: "Sprout_grabbed_\($0)") }
                let grabbed = SKAction.animate(with: grabbedFrames, timePerFrame: 0.1, resize: false, restore: false)
                sprout.run(grabbed, withKey: "dragGrab")
            }

            touchPoints.append(location)
            sprout.position = CGPoint(x: location.x + dragOffset.x, y: location.y + dragOffset.y)

            let deltaX = location.x - lastTouchPosition.x
            if deltaX > 5 {
                let rightFrames = (1...2).map { SKTexture(imageNamed: "Sprout_drag_right_\($0)") }
                sprout.run(SKAction.animate(with: rightFrames, timePerFrame: 0.1, resize: false, restore: false), withKey: "dragDirection")
            } else if deltaX < -5 {
                let leftFrames = (1...2).map { SKTexture(imageNamed: "Sprout_drag_left_\($0)") }
                sprout.run(SKAction.animate(with: leftFrames, timePerFrame: 0.1, resize: false, restore: false), withKey: "dragDirection")
            } else {
                sprout.texture = SKTexture(imageNamed: "Sprout_drag_idle")
                sprout.removeAction(forKey: "dragDirection")
            }

            lastTouchPosition = location
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        endInteraction(at: touch.location(in: self), timestamp: touch.timestamp)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        let timestamp = touches.first?.timestamp ?? touchStartTime
        let location = touches.first?.location(in: self) ?? lastTouchPosition
        endInteraction(at: location, timestamp: timestamp, cancelled: true)
    }

    func endInteraction(at location: CGPoint, timestamp: TimeInterval, cancelled: Bool = false) {
        guard let sprout else { return }
        let touchDuration = timestamp - touchStartTime
        let distanceMoved = abs(location.x - touchStartPosition.x) + abs(location.y - touchStartPosition.y)

        // ✅ Tap — pas un drag
        if !cancelled && touchStartedOnSprout && distanceMoved < 10 && touchDuration < 0.3 {
            isDragging = false
            touchStartedOnSprout = false
            tapCount += 1
            tapTimer?.invalidate()
            tapTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                switch self.tapCount {
                case 1: self.playJump()    // ✅ single tap → jump
                case 2: self.playHappy()   // ✅ double tap → happy
                default: break
                }
                self.tapCount = 0
            }
            return
        }

        // ✅ Drag
        if isDragging {
            isDragging = false
            touchStartedOnSprout = false
            sprout.removeAction(forKey: "dragGrab")
            sprout.removeAction(forKey: "dragDirection")

            if sprout.position.y > size.height / 2 + 100 {
                playDropped()
            } else {
                returnToCenter()
            }
        }

        touchPoints = []
        touchStartedOnSprout = false
    }

    func returnToCenter() {
        guard let sprout = sprout else { return }
        let returnHome = makeReturnMovementAction(duration: 0.4)
        let resetScale = SKAction.scale(to: presentationScale, duration: 0.2)
        resetScale.timingMode = .easeInEaseOut
        let resetRotation = SKAction.rotate(toAngle: 0, duration: 0.2)
        resetRotation.timingMode = .easeInEaseOut
        isReturning = true
        let finish = SKAction.run { [weak self] in
            self?.isReturning = false
            self?.resumePendingState()
        }
        sprout.run(
            SKAction.sequence([SKAction.group([returnHome, resetScale, resetRotation]), finish]),
            withKey: "returnToCenter"
        )
    }

    func makeReturnMovementAction(duration: TimeInterval) -> SKAction {
        let action = SKAction.move(to: restingPosition, duration: duration)
        action.timingMode = .easeInEaseOut
        return action
    }

    func playDropped() {
        guard let sprout = sprout else { return }
        let fall = makeReturnMovementAction(duration: 0.3)
        let droppedFrames = (1...5).map { SKTexture(imageNamed: "Sprout_dropped_\($0)") }
        let dropped = SKAction.animate(with: droppedFrames, timePerFrame: 0.12, resize: false, restore: false)
        isReturning = true
        let finish = SKAction.run { [weak self] in
            self?.isReturning = false
            self?.resumePendingState()
        }
        sprout.run(SKAction.sequence([fall, dropped, finish]), withKey: "returnToCenter")
    }

    // MARK: - Seed

    func playSeedIdle() {
        guard let sprout = sprout else { return }
        let seedFrames = (1...13).map { SKTexture(imageNamed: "Seed_idle_\($0)") }
        let seedIdle = SKAction.animate(with: seedFrames, timePerFrame: 0.15, resize: false, restore: false)
        sprout.run(SKAction.repeatForever(seedIdle), withKey: "seedIdle")
    }

    func playSeedToSprout(completion: (() -> Void)? = nil) {
        guard let sprout = sprout else { return }
        sprout.removeAction(forKey: "seedIdle")
        let transformFrames = (1...22).map { SKTexture(imageNamed: "Seed_transform_\($0)") }
        let transform = SKAction.animate(with: transformFrames, timePerFrame: 0.12, resize: false, restore: false)
        sprout.run(transform) { [weak self] in
            self?.playConfetti()
            self?.startIdle()
            completion?()
        }
    }
}

// MARK: - Holder + View

class SproutSceneHolder: ObservableObject {
    let scene: SproutScene
    init(presentationScale: CGFloat = 1, restingVerticalOffset: CGFloat = 0) {
        scene = SproutScene()
        scene.size = CGSize(width: 1, height: 1)
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear
        scene.configurePresentation(scale: presentationScale, restingVerticalOffset: restingVerticalOffset)
    }
}

struct SproutView: View {
    let state: SproutState
    @StateObject private var holder: SproutSceneHolder

    init(
        state: SproutState,
        presentationScale: CGFloat = 1,
        restingVerticalOffset: CGFloat = 0
    ) {
        self.state = state
        _holder = StateObject(
            wrappedValue: SproutSceneHolder(
                presentationScale: presentationScale,
                restingVerticalOffset: restingVerticalOffset
            )
        )
    }

    var body: some View {
        SpriteView(scene: holder.scene, options: [.allowsTransparency])
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            .onChange(of: state, initial: true) { _, newState in
                holder.scene.updateState(newState)
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
