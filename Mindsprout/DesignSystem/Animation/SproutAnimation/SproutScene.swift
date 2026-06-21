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

    @Published private(set) var isDragging = false
    @Published private(set) var isWalking = false


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
            fileName: "sprout",
            // artboardName: "Sprout",        // ← uncomment if artboard isn't "Main"
            stateMachineName: "SproutHomeSM", // ← comment this out first to isolate the crash
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
        
        // 1. On choisit aléatoirement si le personnage va à droite ou à gauche
        currentDirection = Bool.random() ? 1.0 : -1.0
        
        // 2. Si ton personnage est asymétrique, tu peux activer un booléen dans Rive ici
        // ex: riveVM.setInput("isFacingLeft", value: currentDirection == -1.0)
        
        // 3. On lance l'animation de marche Rive (qui déplace l'avatar)
        riveVM.triggerInput("triggerStartWalk")
        
        let duration = Double.random(in: 3...6)
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            // 4. On stoppe l'animation de marche
            self?.riveVM.triggerInput("triggerStopWalk")
            self?.isWalking = false
            self?.scheduleRandomBehavior()
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
    @State private var dragBaseOffset: CGSize = .zero  // capture si drag démarre en pleine animation
    @State private var lastDragX: CGFloat = 0

    var body: some View {
        ZStack {
            // Rive fullscreen → bonne taille, ne capte pas les gestes
            controller.riveVM.view()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .allowsHitTesting(false)
                // 💡 Effet miroir appliqué automatiquement si currentDirection = -1.0 (gauche)
                .scaleEffect(x: controller.currentDirection == -1.0 ? -1.0 : 1.0, y: 1.0)
                .offset(sproutOffset)

            // Couche transparente fullscreen pour les gestes
            Color.clear
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .gesture(dragGesture)
                .onTapGesture { controller.onTap() }
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
//
//#Preview {
//    ZStack {
//        Image("HomeBackground")
//            .resizable()
//            .scaledToFill()
//            .ignoresSafeArea()
//        SproutView(state: .idle)
//    }
//}

#Preview {
    ZStack {
        Image("HomeBackground")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
        SproutView(state: .idle)
    }
}
