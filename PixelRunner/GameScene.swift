import SpriteKit

final class GameScene: SKScene, SKPhysicsContactDelegate {

    private enum GameState {
        case ready, playing, gameOver
    }

    private let playerCategory: UInt32 = 1
    private let groundCategory: UInt32 = 2
    private let obstacleCategory: UInt32 = 4
    private let coinCategory: UInt32 = 8

    private var player = SKShapeNode()
    private var scoreLabel = SKLabelNode()
    private var bestLabel = SKLabelNode()
    private var messageLabel = SKLabelNode()

    private var state: GameState = .ready
    private var score = 0
    private var bestScore = UserDefaults.standard.integer(forKey: "pixelRunnerBest")

    private var spawnTimer: TimeInterval = 0
    private var scoreTimer: TimeInterval = 0
    private var lastUpdate: TimeInterval = 0
    private var gameSpeed: CGFloat = 300

    private var floorY: CGFloat { size.height * 0.19 }

    override func didMove(to view: SKView) {
        physicsWorld.gravity = CGVector(dx: 0, dy: -22)
        physicsWorld.contactDelegate = self
        setupWorld()
    }

    private func setupWorld() {
        removeAllChildren()
        removeAllActions()

        backgroundColor = SKColor(red: 0.055, green: 0.075, blue: 0.14, alpha: 1)

        state = .ready
        score = 0
        spawnTimer = 0
        scoreTimer = 0
        gameSpeed = 300
        lastUpdate = 0

        createBackground()
        createGround()
        createPlayer()
        createHUD()
        updateLabels()
        showMessage("PIXEL RUNNER", subtitle: "TAP TO START")
    }

    private func createBackground() {
        for _ in 0..<45 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 1...2))
            star.fillColor = .white
            star.strokeColor = .clear
            star.alpha = CGFloat.random(in: 0.2...0.8)
            star.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: floorY + 100...max(floorY + 101, size.height))
            )
            star.zPosition = 0
            addChild(star)
        }

        let moon = SKShapeNode(circleOfRadius: 27)
        moon.fillColor = SKColor(red: 1, green: 0.82, blue: 0.43, alpha: 1)
        moon.strokeColor = .clear
        moon.position = CGPoint(x: size.width * 0.82, y: size.height * 0.76)
        moon.zPosition = 1
        addChild(moon)

        for index in 0..<5 {
            let mountain = SKShapeNode()
            let path = CGMutablePath()
            let x = CGFloat(index) * size.width / 3

            path.move(to: CGPoint(x: x - 100, y: floorY + 12))
            path.addLine(to: CGPoint(x: x + 100, y: floorY + 130))
            path.addLine(to: CGPoint(x: x + 300, y: floorY + 12))
            path.closeSubpath()

            mountain.path = path
            mountain.fillColor = SKColor(red: 0.12, green: 0.17, blue: 0.28, alpha: 1)
            mountain.strokeColor = .clear
            mountain.zPosition = 1
            addChild(mountain)
        }
    }

    private func createGround() {
        let ground = SKShapeNode(
            rectOf: CGSize(width: size.width * 2, height: 24)
        )

        ground.fillColor = SKColor(red: 0.15, green: 0.72, blue: 0.48, alpha: 1)
        ground.strokeColor = .clear
        ground.position = CGPoint(x: size.width / 2, y: floorY)
        ground.zPosition = 4

        ground.physicsBody = SKPhysicsBody(
            rectangleOf: CGSize(width: size.width * 2, height: 24)
        )
        ground.physicsBody?.isDynamic = false
        ground.physicsBody?.categoryBitMask = groundCategory
        ground.physicsBody?.collisionBitMask = playerCategory

        addChild(ground)

        let line = SKShapeNode(
            rectOf: CGSize(width: size.width * 2, height: 4)
        )
        line.fillColor = SKColor(red: 0.35, green: 1, blue: 0.65, alpha: 1)
        line.strokeColor = .clear
        line.position = CGPoint(x: size.width / 2, y: floorY + 14)
        line.zPosition = 5
        addChild(line)
    }

    private func createPlayer() {
        player = SKShapeNode(
            rectOf: CGSize(width: 38, height: 46),
            cornerRadius: 5
        )

        player.fillColor = SKColor(red: 1, green: 0.32, blue: 0.28, alpha: 1)
        player.strokeColor = .white
        player.lineWidth = 2
        player.position = CGPoint(x: size.width * 0.18, y: floorY + 36)
        player.zPosition = 10

        player.physicsBody = SKPhysicsBody(
            rectangleOf: CGSize(width: 34, height: 42)
        )
        player.physicsBody?.allowsRotation = false
        player.physicsBody?.restitution = 0
        player.physicsBody?.friction = 0
        player.physicsBody?.categoryBitMask = playerCategory
        player.physicsBody?.collisionBitMask = groundCategory
        player.physicsBody?.contactTestBitMask = obstacleCategory | coinCategory

        addChild(player)

        let eye = SKShapeNode(circleOfRadius: 3)
        eye.fillColor = .white
        eye.strokeColor = .clear
        eye.position = CGPoint(x: 8, y: 7)
        player.addChild(eye)
    }

    private func createHUD() {
        scoreLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        scoreLabel.fontSize = 21
        scoreLabel.fontColor = .white
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: 28, y: size.height - 45)
        scoreLabel.zPosition = 30
        addChild(scoreLabel)

        bestLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        bestLabel.fontSize = 15
        bestLabel.fontColor = .yellow
        bestLabel.horizontalAlignmentMode = .right
        bestLabel.position = CGPoint(x: size.width - 28, y: size.height - 43)
        bestLabel.zPosition = 30
        addChild(bestLabel)
    }

    private func updateLabels() {
        scoreLabel.text = "SCORE: \(score)"
        bestLabel.text = "BEST: \(bestScore)"
    }

    private func showMessage(_ title: String, subtitle: String) {
        messageLabel.removeFromParent()

        messageLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        messageLabel.text = title
        messageLabel.fontSize = 30
        messageLabel.fontColor = .white
        messageLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.62)
        messageLabel.zPosition = 50
        addChild(messageLabel)

        let sub = SKLabelNode(fontNamed: "Menlo-Bold")
        sub.text = subtitle
        sub.fontSize = 15
        sub.fontColor = .yellow
        sub.position = CGPoint(x: 0, y: -35)
        messageLabel.addChild(sub)
    }

    private func startGame() {
        state = .playing
        messageLabel.removeFromParent()

        score = 0
        scoreTimer = 0
        spawnTimer = 0.7
        gameSpeed = 300

        updateLabels()
    }

    private func jump() {
        guard state == .playing, let body = player.physicsBody else { return }

        if abs(body.velocity.dy) < 1 {
            body.applyImpulse(CGVector(dx: 0, dy: 650))
        }
    }

    private func spawnObstacle() {
        let height = CGFloat.random(in: 38...75)
        let width = CGFloat.random(in: 25...42)

        let obstacle = SKShapeNode(
            rectOf: CGSize(width: width, height: height),
            cornerRadius: 4
        )

        obstacle.name = "obstacle"
        obstacle.fillColor = SKColor(red: 0.45, green: 0.30, blue: 0.85, alpha: 1)
        obstacle.strokeColor = .white
        obstacle.lineWidth = 2
        obstacle.position = CGPoint(
            x: size.width + width,
            y: floorY + 12 + height / 2
        )
        obstacle.zPosition = 8

        obstacle.physicsBody = SKPhysicsBody(
            rectangleOf: CGSize(width: width, height: height)
        )
        obstacle.physicsBody?.isDynamic = false
        obstacle.physicsBody?.categoryBitMask = obstacleCategory
        obstacle.physicsBody?.contactTestBitMask = 0
        obstacle.physicsBody?.collisionBitMask = 0

        addChild(obstacle)

        let distance = size.width + width * 2
        let duration = TimeInterval(distance / gameSpeed)

        obstacle.run(
            SKAction.sequence([
                SKAction.moveBy(x: -distance, y: 0, duration: duration),
                SKAction.removeFromParent()
            ])
        )
    }

    private func spawnCoin() {
        let coin = SKShapeNode(circleOfRadius: 12)
        coin.name = "coin"
        coin.fillColor = .yellow
        coin.strokeColor = .orange
        coin.lineWidth = 3
        coin.position = CGPoint(
            x: size.width + 20,
            y: floorY + CGFloat.random(in: 85...150)
        )
        coin.zPosition = 9

        coin.physicsBody = SKPhysicsBody(circleOfRadius: 12)
        coin.physicsBody?.isDynamic = false
        coin.physicsBody?.categoryBitMask = coinCategory
        coin.physicsBody?.contactTestBitMask = 0
        coin.physicsBody?.collisionBitMask = 0

        addChild(coin)

        let distance = size.width + 50
        let duration = TimeInterval(distance / gameSpeed)

        coin.run(
            SKAction.sequence([
                SKAction.moveBy(x: -distance, y: 0, duration: duration),
                SKAction.removeFromParent()
            ])
        )
    }

    func didBegin(_ contact: SKPhysicsContact) {
        let first = contact.bodyA.categoryBitMask
        let second = contact.bodyB.categoryBitMask

        let categories = first | second

        if categories == (playerCategory | obstacleCategory) {
            endGame()
        }

        if categories == (playerCategory | coinCategory) {
            let coinBody = first == coinCategory ? contact.bodyA : contact.bodyB
            coinBody.node?.removeFromParent()

            score += 5
            updateLabels()
        }
    }

    private func endGame() {
        guard state == .playing else { return }

        state = .gameOver
        player.physicsBody?.velocity = .zero

        if score > bestScore {
            bestScore = score
            UserDefaults.standard.set(bestScore, forKey: "pixelRunnerBest")
        }

        updateLabels()
        showMessage("GAME OVER", subtitle: "TAP TO RESTART")
    }

    override func update(_ currentTime: TimeInterval) {
        if lastUpdate == 0 {
            lastUpdate = currentTime
        }

        let delta = min(currentTime - lastUpdate, 0.05)
        lastUpdate = currentTime

        guard state == .playing else { return }

        scoreTimer += delta
        spawnTimer += delta

        if scoreTimer >= 0.15 {
            score += 1
            scoreTimer = 0
            updateLabels()
        }

        if spawnTimer >= max(0.65, 1.45 - Double(score) * 0.003) {
            spawnObstacle()

            if Int.random(in: 0...2) == 0 {
                spawnCoin()
            }

            spawnTimer = 0
        }

        gameSpeed = min(600, 300 + CGFloat(score) * 1.2)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        switch state {
        case .ready:
            startGame()
        case .playing:
            jump()
        case .gameOver:
            setupWorld()
            startGame()
        }
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard oldSize != .zero else { return }
        if state != .playing {
            setupWorld()
        }
    }
}