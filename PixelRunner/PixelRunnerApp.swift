import SwiftUI
import SpriteKit

@main
struct PixelRunnerApp: App {
    var body: some Scene {
        WindowGroup {
            GameView()
                .ignoresSafeArea(.all)
                .statusBarHidden(true)
                .persistentSystemOverlays(.hidden)
                .preferredColorScheme(.dark)
        }
    }
}

struct GameView: View {
    private let scene: GameScene = {
        let scene = GameScene(size: CGSize(width: 896, height: 414))
        scene.scaleMode = .resizeFill
        return scene
    }()

    var body: some View {
        SpriteView(
            scene: scene,
            options: [.ignoresSiblingOrder]
        )
        .ignoresSafeArea(.all)
        .background(Color.black)
    }
}