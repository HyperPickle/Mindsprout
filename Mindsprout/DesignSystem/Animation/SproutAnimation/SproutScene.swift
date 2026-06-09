//
//  SproutScene.swift
//  Mindsprout
//
//  Created by Changrila Souksamlane on 6/6/2026.
//

import SpriteKit
import SwiftUI
import Combine

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
            playHungry()
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
        
        let levelUpFrames = (1...8).map {
            SKTexture(imageNamed: "Sprout_levelup_\($0)")
        }
        
        let levelUp = SKAction.animate(
            with: levelUpFrames,
            timePerFrame: 0.12,
            resize: false,
            restore: false
        )
        
        sprout.run(levelUp) { [weak self] in
            if willEvolve {
                self?.playEvolution()  // ← va évoluer
            } else {
                self?.startIdleAnimation()  // ← retour idle
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
