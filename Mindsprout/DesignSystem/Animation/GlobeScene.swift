//
//  GlobeScene.swift
//  Mindsprout
//
//  Created by Changrila Souksamlane on 6/6/2026.
//
import SpriteKit
import SwiftUI
import Combine

class GlobeScene: SKScene {
    var globe: SKSpriteNode?
    var currentSpeed: TimeInterval = 0.08
    var lastTouchX: CGFloat = 0


    var isDarkMode: Bool = false {
            didSet {
                rotateGlobe(speed: currentSpeed)
            }
        }
        
        var globePrefix: String {
            isDarkMode ? "Earth_dark_" : "Earth_"
        }
    
    
    let minSpeed: TimeInterval = 0.04
    let maxSpeed: TimeInterval = 0.12
    
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        scaleMode = .resizeFill
        
        guard UIImage(named: "\(globePrefix)1") != nil else {
            return
        }

        let globeNode = SKSpriteNode(imageNamed: "\(globePrefix)1")
        globeNode.position = CGPoint(x: size.width/2, y: size.height/2)
        globeNode.size = CGSize(width: 800, height: 800)
        addChild(globeNode)
        globe = globeNode
        
        rotateGlobe(speed: currentSpeed)
    }
    
    func rotateGlobe(speed: TimeInterval) {
        guard let globe = globe else {
            return
        }

        globe.removeAllActions()

        let frames = (1...20).compactMap { i -> SKTexture? in
            guard UIImage(named: "\(globePrefix)\(i)") != nil else {
                return nil
            }
            return SKTexture(imageNamed: "\(globePrefix)\(i)")
        }

        guard !frames.isEmpty else {
            return
        }
        
        let rotation = SKAction.animate(with: frames, timePerFrame: speed)
        globe.run(SKAction.repeatForever(rotation))
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        guard globe != nil else { return }
        rotateGlobe(speed: currentSpeed)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard globe != nil else { return }
        guard let touch = touches.first else { return }
        lastTouchX = touch.location(in: self).x
        globe?.removeAllActions()
        rotateGlobe(speed: currentSpeed)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard globe != nil else { return }
        guard let touch = touches.first else { return }
        let currentX = touch.location(in: self).x
        let deltaX = abs(currentX - lastTouchX)
        
        if deltaX > 3 {
            let acceleration = deltaX * 0.0002
            currentSpeed = max(minSpeed, currentSpeed - acceleration)
            rotateGlobe(speed: currentSpeed)
        }
        lastTouchX = currentX
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard globe != nil else { return }
        slowDownGlobe()
    }

    func slowDownGlobe() {
        guard let globe = globe else { return }
        
        let steps = 20
        let duration = 2.0
        let stepDuration = duration / Double(steps)
        let speedDiff = maxSpeed - currentSpeed
        
        var actions: [SKAction] = []
        
        for i in 1...steps {
            let stepSpeed = currentSpeed + (speedDiff * Double(i) / Double(steps))
            let wait = SKAction.wait(forDuration: stepDuration)
            let updateSpeed = SKAction.customAction(withDuration: 0) { [weak self] _, _ in
                guard let self = self else { return }
                self.rotateGlobe(speed: stepSpeed)
            }
            actions.append(contentsOf: [wait, updateSpeed])
        }
        
        actions.append(SKAction.customAction(withDuration: 0) { [weak self] _, _ in
            self?.currentSpeed = self?.maxSpeed ?? 0.12
            self?.rotateGlobe(speed: self?.maxSpeed ?? 0.12)
        })
        
        globe.run(SKAction.sequence(actions))
    }
}

class GlobeSceneHolder: ObservableObject {
    let scene: GlobeScene
    
    init() {
        scene = GlobeScene()
        scene.size = CGSize(width: 800, height: 800)
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear
    }
}

struct GlobeView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var sceneHolder = GlobeSceneHolder()
    
    var body: some View {
        SpriteView(scene: sceneHolder.scene, options: [.allowsTransparency])
            .frame(width: 800, height: 800)
            .rotationEffect(.degrees(-40))
            .onAppear {
                sceneHolder.scene.isDarkMode = colorScheme == .dark
            }
            .onChange(of: colorScheme) { _, newMode in
                sceneHolder.scene.isDarkMode = newMode == .dark
            }
    }
}

#Preview {
    ZStack{
    
        BackgroundSky()
        GlobeView()
    }
}
