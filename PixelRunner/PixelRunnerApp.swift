import SwiftUI
import SpriteKit

@main
struct PixelRunnerApp: App {
    var body: some Scene {
        WindowGroup {
            SpriteView(scene: GameScene(), options: [.ignoresSiblingOrder])
                .ignoresSafeArea()
                .statusBarHidden(true)
        }
    }
}