//
//  SeedScene.swift
//  Mindsprout
//
//  Created by Changrila Souksamlane on 11/6/2026.
//

import SpriteKit
import SwiftUI
import Combine

class SeedScene: SKScene {
    var seed: SKSpriteNode?
    
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        scaleMode = .resizeFill
        
        guard UIImage(named: "Seed_idle_1") != nil else {
            print("❌ Seed_idle_1 not found")
            return
        }
        
        let texture = SKTexture(imageNamed: "Seed_idle_1")
        let aspect = texture.size().height / texture.size().width
        let seedHeight: CGFloat = size.height * 0.9
        let seedWidth = seedHeight / aspect
        
        let seedNode = SKSpriteNode(texture: texture)
        seedNode.size = CGSize(width: seedWidth, height: seedHeight)
        seedNode.position = CGPoint(x: size.width/2, y: size.height/2)
        seedNode.zPosition = 1
        addChild(seedNode)
        seed = seedNode
        
        playSeedIdle()
    }
    
    // ✅ Seed idle loop — 13 frames
    func playSeedIdle() {
        guard let seed = seed else { return }
        
        let seedFrames = (1...13).map {
            SKTexture(imageNamed: "Seed_idle_\($0)")
        }
        let seedIdle = SKAction.animate(
            with: seedFrames,
            timePerFrame: 0.15,
            resize: false,
            restore: false
        )
        seed.run(SKAction.repeatForever(seedIdle), withKey: "seedIdle")
    }
    
    // ✅ Transformation seed → Sprout — 22 frames
    func playSeedToSprout(completion: (() -> Void)? = nil) {
        guard let seed = seed else { return }
        seed.removeAction(forKey: "seedIdle")
        
        let transformFrames = (1...22).map {
            SKTexture(imageNamed: "Seed_transform_\($0)")
        }
        let transform = SKAction.animate(
            with: transformFrames,
            timePerFrame: 0.06,
            resize: false,
            restore: false
        )
        
        seed.run(transform) { [weak self] in
            completion?()
        }
    }
    
}

// ✅ Holder
class SeedSceneHolder: ObservableObject {
    let scene: SeedScene
    
    init() {
        scene = SeedScene()
        scene.size = CGSize(width: 300, height: 300)
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear
    }
}

// ✅ View
struct SeedView: View {
    @StateObject private var holder = SeedSceneHolder()
    
    var body: some View {
        SpriteView(scene: holder.scene, options: [.allowsTransparency])
            .frame(width: 300, height: 300)
    }
}

#Preview {
    ZStack {
        BackgroundSky()
        SeedView()
    }
}
