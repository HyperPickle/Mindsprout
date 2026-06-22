//
//  SproutScene.swift
//  Mindsprout
//
//  Created by Changrila Souksamlane on 6/6/2026.
//
import RiveRuntime
import SwiftUI
import Combine

// MARK: - Controller

@MainActor
final class SproutRiveController: ObservableObject {
    let riveVM: RiveViewModel
    
    
    @Published var currentDirection: CGFloat = 1.0
    @Published var sproutWalkOffset: CGSize = .zero
    @Published private(set) var isDragging = false
    @Published private(set) var isWalking = false
    @Published var isFacingLeft = false
  
    private let screenHalfWidth: CGFloat = UIScreen.main.bounds.width / 2 - 80

    private var tapCount = 0
    private var tapTimer: Timer?
    private var behaviorTimer: Timer?
    private var lastBehaviorIndex = -1
    private var currentState: SproutState = .idle
    // Rive loads the file async — queue the first state until the view has appeared
    private var pendingState: SproutState?
    private var isRiveReady = false

    init() {
        // Step 1: verify the .riv file loads at all (no state machine)
        // Step 2: if Step 1 works, uncomment stateMachineName and check artboardName
        riveVM = RiveViewModel(
            fileName: "sprouttest",
            stateMachineName: "SproutHomeSM",
            artboardName:"Sprout"
        )
    }

    func onViewAppeared() {
        isRiveReady = true
        if let pending = pendingState {
            pendingState = nil
            updateState(pending)
        }
    }

    // MARK: - App State

    func updateState(_ state: SproutState) {
        guard isRiveReady else {
            pendingState = state
            return
        }
        currentState = state
        behaviorTimer?.invalidate()

        riveVM.setInput("isHungry", value: false)
        riveVM.setInput("isSad", value: false)

        switch state {
        case .idle, .readyToEvolve:
            scheduleRandomBehavior()
        case .hungry:
            riveVM.setInput("isHungry", value: true)
        case .sleeping:
            riveVM.triggerInput("triggerSleep")
        case .evolving:
            riveVM.triggerInput("triggerLevelUp")
            let level = UserDefaults.standard.integer(forKey: "sproutLevel")
            riveVM.setInput("evolutionLevel", value: Double(level))
        }
    }

    // MARK: - Random Behavior

    private func scheduleRandomBehavior() {
        behaviorTimer?.invalidate()
        let delay = Double.random(in: 10...30)
        behaviorTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.runRandomBehavior() }
        }
    }

    private func runRandomBehavior() {
        guard currentState == .idle || currentState == .readyToEvolve, !isDragging else {
            scheduleRandomBehavior()
            return
        }
        var pick: Int
        repeat { pick = Int.random(in: 0...3) } while pick == lastBehaviorIndex
        lastBehaviorIndex = pick

        switch pick {
        case 0: doWalk()
        case 1: doSit()
        case 2: doJump()
        case 3: doSleepBriefly()
        default: scheduleRandomBehavior()
        }
    }

    

    private func doWalk() {
        isWalking = true
        let randomDir = Bool.random()
        currentDirection = randomDir ? 1.0 : -1.0
        self.isFacingLeft = (self.currentDirection == -1.0)
        
        // 1. Déclenche l'animation de marche Rive (démarre instantanément)
        riveVM.triggerInput("triggerStartWalk")
        
        let startX = sproutWalkOffset.width
        let screenLimit: CGFloat = 200.0
        let naturalStep: CGFloat = CGFloat.random(in: 80...150)
        
        // Durée totale de l'action de marche (identique à la durée de l'offset)
        let walkDuration: Double = 2.5
        
        if currentDirection > 0 {
            // --- MARCHE VERS LA DROITE ---
            if startX + naturalStep > screenLimit {
                // Sortie de l'écran en douceur
                withAnimation(.linear(duration: 1.5)) {
                    self.sproutWalkOffset = CGSize(width: screenLimit + 40, height: 0)
                }
                
                // Téléportation invisible SANS animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.sproutWalkOffset = CGSize(width: -screenLimit - 40, height: 0)
                    
                    // Rentre sur l'écran par la gauche en douceur
                    withAnimation(.linear(duration: 1.0)) {
                        self.sproutWalkOffset = CGSize(width: -screenLimit + 60, height: 0)
                    }
                }
            } else {
                // Déplacement linéaire fluide qui couvre exactement toute la durée de l'action
                withAnimation(.linear(duration: walkDuration)) {
                    self.sproutWalkOffset = CGSize(width: startX + naturalStep, height: 0)
                }
            }
        } else {
            // --- MARCHE VERS LA GAUCHE ---
            if startX - naturalStep < -screenLimit {
                // Sortie de l'écran en douceur
                withAnimation(.linear(duration: 1.5)) {
                    self.sproutWalkOffset = CGSize(width: -screenLimit - 40, height: 0)
                }
                
                // Téléportation invisible SANS animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.sproutWalkOffset = CGSize(width: screenLimit + 40, height: 0)
                    
                    // Rentre sur l'écran par la droite en douceur
                    withAnimation(.linear(duration: 1.2)) {
                        self.sproutWalkOffset = CGSize(width: screenLimit - 60, height: 0)
                    }
                }
            } else {
                // Déplacement linéaire fluide qui couvre exactement toute la durée de l'action
                withAnimation(.linear(duration: walkDuration)) {
                    self.sproutWalkOffset = CGSize(width: startX - naturalStep, height: 0)
                }
            }
        }
        
        // 2. On attend la fin exacte du déplacement (ici 2.5s) avant d'arrêter Rive et de le figer
        DispatchQueue.main.asyncAfter(deadline: .now() + walkDuration) { [weak self] in
            guard let self = self else { return }
            
            // Stoppe l'animation de marche dans Rive au même moment où il s'arrête de glisser
            self.riveVM.triggerInput("triggerStopWalk")
            
            // 3. Temps de stabilisation très court (0.3s) avant de repasser en Idle
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self = self else { return }
                self.isWalking = false
                self.isFacingLeft = false
                self.scheduleRandomBehavior()
            }
        }
    }
    
    private func doSit() {
        riveVM.triggerInput("triggerSit")
        let duration = Double.random(in: 5...10)
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.riveVM.triggerInput("triggerStandUp")
            self?.scheduleRandomBehavior()
        }
    }

    private func doJump() {
        riveVM.triggerInput("triggerJump")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            self?.scheduleRandomBehavior()
        }
    }

    private func doSleepBriefly() {
        riveVM.triggerInput("triggerSleep")
        let duration = Double.random(in: 5...10)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.riveVM.triggerInput("triggerWakeUp")
            self?.scheduleRandomBehavior()
        }
    }

    // MARK: - Touch / Drag / Tap

    func onGrabBegan() {
        guard !isDragging else { return }
        isDragging = true
        tapTimer?.invalidate()
        tapCount = 0
        riveVM.triggerInput("triggerGrab")
    }

    func onDragChanged(deltaX: CGFloat) {
        let direction: Double = deltaX > 5 ? 1 : (deltaX < -5 ? -1 : 0)
        riveVM.setInput("dragDirection", value: direction)
    }

    func onDropped() {
        isDragging = false
        riveVM.setInput("dragDirection", value: 0.0)
        riveVM.triggerInput("triggerDrop")
    }

    func onSwipeLeft() {
        riveVM.triggerInput("swipeLeft")
    }

    func onSwipeRight() {
        riveVM.triggerInput("swipeRight")
    }

    func onTap() {
        tapCount += 1
        tapTimer?.invalidate()
        tapTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                switch self.tapCount {
                case 1: self.riveVM.triggerInput("triggerJump")
                case 2: self.riveVM.triggerInput("triggerHappy")
                default: break
                }
                self.tapCount = 0
            }
        }
    }

    // MARK: - Level Up

    func playLevelUp(willEvolve: Bool) {
        riveVM.triggerInput("triggerLevelUp")
        if willEvolve {
            // triggerLevelUpEnd is fired after the animation completes via a Rive event
            // or manually after a delay matching the animation length
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
                self?.riveVM.triggerInput("triggerLevelUpEnd")
                let newLevel = UserDefaults.standard.integer(forKey: "sproutLevel") + 1
                UserDefaults.standard.set(newLevel, forKey: "sproutLevel")
                self?.riveVM.setInput("evolutionLevel", value: Double(newLevel))
            }
        }
    }
}

// MARK: - View
struct SproutView: View {
    let state: SproutState
    @StateObject private var controller = SproutRiveController()

    @State private var sproutOffset: CGSize = .zero
    @State private var dragBaseOffset: CGSize = .zero
    @State private var lastDragX: CGFloat = 0

    private let sproutSize: CGFloat = 300
    private let sproutAnchorY: CGFloat = 0.5

    private var totalOffset: CGSize {
        CGSize(
            width: sproutOffset.width + controller.sproutWalkOffset.width,
            height: sproutOffset.height + controller.sproutWalkOffset.height
        )
    }

    var body: some View {
        GeometryReader { geo in
            let baseX = geo.size.width / 2
            let baseY = geo.size.height * sproutAnchorY

            ZStack {
                controller.riveVM.view()
                    .frame(width: sproutSize, height: sproutSize)
                    .scaleEffect(
                        x: controller.isFacingLeft ? -1.0 : 1.0,
                        y: 1.0
                    )
                    .position(
                        x: baseX + totalOffset.width,
                        y: baseY + totalOffset.height
                    )
                    .allowsHitTesting(false)

                Color.clear
                    .contentShape(Rectangle())
                    .frame(width: sproutSize, height: sproutSize)
                    .position(
                        x: baseX + totalOffset.width,
                        y: baseY + totalOffset.height
                    )
                    .gesture(dragGesture)
                    .onTapGesture { controller.onTap() }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            controller.onViewAppeared()
            controller.updateState(state)
        }
        .onChange(of: state) { _, newState in
            controller.updateState(newState)
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { value in
                if !controller.isDragging {
                    controller.onGrabBegan()
                    dragBaseOffset = sproutOffset
                    lastDragX = 0
                }
                sproutOffset = CGSize(
                    width: dragBaseOffset.width + value.translation.width,
                    height: dragBaseOffset.height + value.translation.height
                )
                let delta = value.translation.width - lastDragX
                controller.onDragChanged(deltaX: delta)
                lastDragX = value.translation.width
            }
            .onEnded { value in
                lastDragX = 0
                let speedX = value.velocity.width
                if abs(speedX) > 500 {
                    speedX > 0 ? controller.onSwipeRight() : controller.onSwipeLeft()
                } else {
                    controller.onDropped()
                }
                withAnimation(.spring(response: 0.55, dampingFraction: 0.68)) {
                    sproutOffset = .zero
                }
            }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Image("HomeBackground")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
        SproutView(state: .idle)
    }
}

// MARK: - SproutIdleView (Welcome only)

struct SproutIdleView: View {
    @StateObject private var riveVM = RiveViewModel(
        fileName: "sprout2",
        stateMachineName: "SproutHomeSM",
        artboardName: "Sprout"
    )

    var body: some View {
        riveVM.view()
            .allowsHitTesting(false)
            .onAppear {
                // Force idle : aucun comportement random, juste breathing + blink
                riveVM.setInput("isHungry", value: false)
                riveVM.setInput("isSad", value: false)
            }
    }
}

