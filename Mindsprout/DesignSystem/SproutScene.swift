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
            sprout.removeAction(forKey: "idle")
        }
        
        let blink = SKAction.animate(
            with: blinkFrames,
            timePerFrame: 0.08,
            resize: false,
            restore: true  // ✅ restore: true → retourne à la texture avant le blink
        )
        
        let resumeIdle = SKAction.run { [weak self] in
            self?.startIdleAnimation()  // ✅ reprend l'idle proprement
        }
        
        let blinkSequence = SKAction.sequence([
            wait,
            stopIdle,   // ← stoppe idle
            blink,      // ← cligne
            resumeIdle  // ← reprend idle depuis le début
        ])
        
        sprout.run(SKAction.repeatForever(blinkSequence), withKey: "blink")
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
