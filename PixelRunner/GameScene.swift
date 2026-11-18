
import SpriteKit
import UIKit

final class GameScene: SKScene, SKPhysicsContactDelegate {

    private enum State {
        case ready
        case playing
        case gameOver
    }

    private let playerCategory: UInt32 = 1
    private let groundCategory: UInt32 = 2
    private let obstacleCategory: UInt32 = 4
    private let coinCategory: UInt32 = 8

    private var gameState: State = .ready

    private var player = SKShapeNode()
    private var ground = SKShapeNode()

    private var scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private var bestLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")

    private var titleLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private var messageLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
    private var actionLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")

    private var score = 0
    private var bestScore = UserDefaults.standard.integer(forKey: "pixelRunnerBest")

    private var groundY: CGFloat = 75
    private var playerX: CGFloat = 180
    private var elapsedTime: TimeInterval = 0
    private var lastUpdateTime: TimeInterval = 0

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.035, green: 0.055, blue: 0.12, alpha: 1)

        physicsWorld.gravity = CGVector(dx: 0, dy: -18)
        physicsWorld.contactDelegate = self

        view.ignoresSiblingOrder = true
        view.isMultipleTouchEnabled = false

        setupBackground()
        setupGround()
        setupPlayer()
        setupHUD()
        setupOverlay()

        showReadyScreen()
    }

    private func setupBackground() {
        let stars = SKNode()
        stars.zPosition = -10

        for _ in 0..<75 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.7...2.0))
            star.fillColor = .white
            star.strokeColor = .clear
            star.alpha = CGFloat.random(in: 0.3...0.9)

            star.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: size.height * 0.35...size.height)
            )

            stars.addChild(star)
        }

        addChild(stars)

        let moon = SKShapeNode(circleOfRadius: 35)
        moon.fillColor = SKColor(red: 1, green: 0.88, blue: 0.55, alpha: 1)
        moon.strokeColor = .clear
        moon.glowWidth = 12
        moon.position = CGPoint(x: size.width * 0.78, y: size.height * 0.78)
        moon.zPosition = -8
        addChild(moon)

        createMountain(
            height: size.height * 0.32,
            color: SKColor(red: 0.10, green: 0.13, blue: 0.27, alpha: 1),
            offset: 0
        )

        createMountain(
            height: size.height * 0.22,
            color: SKColor(red: 0.07, green: 0.10, blue: 0.20, alpha: 1),
            offset: 120
        )
    }

    private func createMountain(height: CGFloat, color: SKColor, offset: CGFloat) {
        let path = CGMutablePath()
        let base: CGFloat = 45

        path.move(to: CGPoint(x: 0, y: base))
        path.addLine(to: CGPoint(x: size.width * 0.15, y: height))
        path.addLine(to: CGPoint(x: size.width * 0.32, y: base + offset * 0.1))
        path.addLine(to: CGPoint(x: size.width * 0.53, y: height * 0.85))
        path.addLine(to: CGPoint(x: size.width * 0.73, y: base))
        path.addLine(to: CGPoint(x: size.width, y: height * 0.9))
        path.addLine(to: CGPoint(x: size.width, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.closeSubpath()

        let mountain = SKShapeNode(path: path)
        mountain.fillColor = color
        mountain.strokeColor = .clear
        mountain.zPosition = -5
        addChild(mountain)
    }

    private func setupGround() {
        groundY = size.height * 0.19

        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: groundY))
        path.addLine(to: CGPoint(x: size.width, y: groundY))
        path.addLine(to: CGPoint(x: size.width, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.closeSubpath()

        ground = SKShapeNode(path: path)
        ground.fillColor = SKColor(red: 0.08, green: 0.13, blue: 0.17, alpha: 1)
        ground.strokeColor = .clear
        ground.zPosition = 1
        addChild(ground)

        let line = SKShapeNode(rectOf: CGSize(width: size.width, height: 5))
        line.fillColor = SKColor(red: 0.15, green: 1, blue: 0.55, alpha: 1)
        line.strokeColor = .clear
        line.position = CGPoint(x: size.width / 2, y: groundY)
        line.glowWidth = 5
        line.zPosition = 2
        addChild(line)

        let groundBody = SKPhysicsBody(
            edgeFrom: CGPoint(x: 0, y: groundY),
            to: CGPoint(x: size.width, y: groundY)
        )

        groundBody.categoryBitMask = groundCategory
        groundBody.collisionBitMask = playerCategory
        groundBody.contactTestBitMask = 0

        let groundPhysics = SKNode()
        groundPhysics.physicsBody = groundBody
        addChild(groundPhysics)
    }

    private func setupPlayer() {
        playerX = size.width * 0.20

        player = SKShapeNode(
            rectOf: CGSize(width: 38, height: 43),
            cornerRadius: 8
        )

        player.fillColor = SKColor(red: 0.15, green: 0.95, blue: 0.55, alpha: 1)
        player.strokeColor = .white
        player.lineWidth = 1.5
        player.glowWidth = 5
        player.position = CGPoint(
            x: playerX,
            y: groundY + 22
        )
        player.zPosition = 5

        let eye = SKShapeNode(circleOfRadius: 3)
        eye.fillColor = .black
        eye.strokeColor = .clear
        eye.position = CGPoint(x: 9, y: 6)
        player.addChild(eye)

        let body = SKPhysicsBody(rectangleOf: CGSize(width: 34, height: 40))
        body.mass = 0.8
        body.allowsRotation = false
        body.restitution = 0
        body.friction = 0
        body.categoryBitMask = playerCategory
        body.collisionBitMask = groundCategory | obstacleCategory
        body.contactTestBitMask = obstacleCategory | coinCategory

        player.physicsBody = body
        addChild(player)
    }

    private func setupHUD() {
        scoreLabel.fontSize = 25
        scoreLabel.fontColor = .white
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.position = CGPoint(
            x: size.width - 30,
            y: size.height - 48
        )
        scoreLabel.zPosition = 20
        addChild(scoreLabel)

        bestLabel.fontSize = 14
        bestLabel.fontColor = SKColor(white: 0.75, alpha: 1)
        bestLabel.horizontalAlignmentMode = .left
        bestLabel.position = CGPoint(x: 30, y: size.height - 43)
        bestLabel.zPosition = 20
        addChild(bestLabel)

        updateHUD()
    }

    private func setupOverlay() {
        titleLabel.fontSize = 43
        titleLabel.fontColor = .white
        titleLabel.verticalAlignmentMode = .center
        titleLabel.horizontalAlignmentMode = .center
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.66)
        titleLabel.zPosition = 30
        addChild(titleLabel)

        messageLabel.fontSize = 18
        messageLabel.fontColor = SKColor(white: 0.8, alpha: 1)
        messageLabel.horizontalAlignmentMode = .center
        messageLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.53)
        messageLabel.zPosition = 30
        addChild(messageLabel)

        actionLabel.fontSize = 19
        actionLabel.fontColor = SKColor(red: 0.2, green: 1, blue: 0.6, alpha: 1)
        actionLabel.horizontalAlignmentMode = .center
        actionLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.39)
        actionLabel.zPosition = 30
        addChild(actionLabel)

        actionLabel.run(
            SKAction.repeatForever(
                SKAction.sequence([
                    .fadeAlpha(to: 0.35, duration: 0.7),
                    .fadeAlpha(to: 1, duration: 0.7)
                ])
            )
        )
    }

    private func showReadyScreen() {
        titleLabel.text = "PIXEL RUNNER"
        messageLabel.text = "Jump over obstacles • Collect coins"
        actionLabel.text = "TAP TO START"
        showOverlay(true)
    }

    private func showOverlay(_ visible: Bool) {
        let alpha: CGFloat = visible ? 1 : 0
        titleLabel.alpha = alpha
        messageLabel.alpha = alpha
        actionLabel.alpha = alpha
    }

    private func startGame() {
        gameState = .playing
        score = 0
        elapsedTime = 0

        player.position = CGPoint(x: playerX, y: groundY + 22)
        player.physicsBody?.velocity = .zero
        player.physicsBody?.isDynamic = true

        updateHUD()
        showOverlay(false)

        run(
            SKAction.repeatForever(
                SKAction.sequence([
                    .wait(forDuration: 1.35),
                    .run { [weak self] in self?.spawnObstacle() }
                ])
            ),
            withKey: "obstacleSpawner"
        )

        run(
            SKAction.repeatForever(
                SKAction.sequence([
                    .wait(forDuration: 1.8),
                    .run { [weak self] in self?.spawnCoin() }
                ])
            ),
            withKey: "coinSpawner"
        )
    }

    private func spawnObstacle() {
        guard gameState == .playing else { return }

        let height = CGFloat.random(in: 35...65)
        let width = CGFloat.random(in: 24...34)

        let obstacle = SKShapeNode(
            rectOf: CGSize(width: width, height: height),
            cornerRadius: 5
        )

        obstacle.fillColor = SKColor(red: 1, green: 0.25, blue: 0.32, alpha: 1)
        obstacle.strokeColor = SKColor(red: 1, green: 0.65, blue: 0.55, alpha: 1)
        obstacle.lineWidth = 2
        obstacle.glowWidth = 3

        obstacle.position = CGPoint(
            x: size.width + 50,
            y: groundY + height / 2
        )
        obstacle.zPosition = 4

        let body = SKPhysicsBody(rectangleOf: CGSize(width: width - 3, height: height - 3))
        body.isDynamic = false
        body.categoryBitMask = obstacleCategory
        body.contactTestBitMask = playerCategory
        body.collisionBitMask = playerCategory
        obstacle.physicsBody = body

        addChild(obstacle)

        let duration = max(0.85, 2.0 - Double(score) * 0.006)

        obstacle.run(
            SKAction.sequence([
                .moveTo(x: -60, duration: duration),
                .removeFromParent()
            ])
        )
    }

    private func spawnCoin() {
        guard gameState == .playing else { return }

        let coin = SKShapeNode(circleOfRadius: 12)
        coin.fillColor = SKColor(red: 1, green: 0.78, blue: 0.12, alpha: 1)
        coin.strokeColor = SKColor(red: 1, green: 0.95, blue: 0.55, alpha: 1)
        coin.lineWidth = 2
        coin.glowWidth = 7

        coin.position = CGPoint(
            x: size.width + 30,
            y: groundY + CGFloat.random(in: 65...125)
        )
        coin.zPosition = 4

        let body = SKPhysicsBody(circleOfRadius: 10)
        body.isDynamic = false
        body.categoryBitMask = coinCategory
        body.contactTestBitMask = playerCategory
        body.collisionBitMask = 0
        coin.physicsBody = body

        addChild(coin)

        let spin = SKAction.rotate(byAngle: .pi * 2, duration: 1)
        coin.run(.repeatForever(spin))

        coin.run(
            SKAction.sequence([
                .moveTo(x: -40, duration: 2.4),
                .removeFromParent()
            ])
        )
    }

    private func jump() {
        guard gameState == .playing else { return }
        guard let body = player.physicsBody else { return }

        if player.position.y <= groundY + 25,
           body.velocity.dy <= 5 {
            body.velocity = CGVector(dx: 0, dy: 0)
            body.applyImpulse(CGVector(dx: 0, dy: 520))

            player.run(
                SKAction.sequence([
                    .scaleX(to: 1.15, duration: 0.08),
                    .scaleX(to: 1, duration: 0.12)
                ])
            )
        }
    }

    func didBegin(_ contact: SKPhysicsContact) {
        let first = contact.bodyA.categoryBitMask
        let second = contact.bodyB.categoryBitMask

        let isCoin =
            (first == playerCategory && second == coinCategory) ||
            (second == playerCategory && first == coinCategory)

        let isObstacle =
            (first == playerCategory && second == obstacleCategory) ||
            (second == playerCategory && first == obstacleCategory)

        if isCoin {
            let coinBody = first == coinCategory ? contact.bodyA : contact.bodyB
            coinBody.node?.removeFromParent()

            score += 10
            updateHUD()

            let effect = SKLabelNode(fontNamed: "AvenirNext-Heavy")
            effect.text = "+10"
            effect.fontSize = 18
            effect.fontColor = .yellow
            effect.position = player.position
            effect.zPosition = 25
            addChild(effect)

            effect.run(
                .sequence([
                    .group([
                        .moveBy(x: 0, y: 40, duration: 0.5),
                        .fadeOut(withDuration: 0.5)
                    ]),
                    .removeFromParent()
                ])
            )
        }

        if isObstacle {
            endGame()
        }
    }

    private func endGame() {
        guard gameState == .playing else { return }

        gameState = .gameOver

        removeAction(forKey: "obstacleSpawner")
        removeAction(forKey: "coinSpawner")

        player.physicsBody?.velocity = .zero

        if score > bestScore {
            bestScore = score
            UserDefaults.standard.set(bestScore, forKey: "pixelRunnerBest")
        }

        updateHUD()

        titleLabel.text = "GAME OVER"
        messageLabel.text = "Your score: \(score)"
        actionLabel.text = "TAP TO PLAY AGAIN"

        showOverlay(true)

        player.run(
            .sequence([
                .rotate(byAngle: -.15, duration: 0.1),
                .rotate(byAngle: .15, duration: 0.1)
            ])
        )
    }

    private func updateHUD() {
        scoreLabel.text = "SCORE  \(score)"
        bestLabel.text = "BEST  \(bestScore)"
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        switch gameState {
        case .ready:
            startGame()
        case .playing:
            jump()
        case .gameOver:
            restartGame()
        }
    }

    private func restartGame() {
        removeAllActions()

        enumerateChildNodes(withName: "//obstacle") { node, _ in
            node.removeFromParent()
        }

        for node in children where
            node.physicsBody?.categoryBitMask == obstacleCategory ||
            node.physicsBody?.categoryBitMask == coinCategory {
            node.removeFromParent()
        }

        player.removeAllActions()
        player.zRotation = 0
        player.xScale = 1
        player.yScale = 1

        player.physicsBody?.velocity = .zero
        player.physicsBody?.angularVelocity = 0
        player.position = CGPoint(x: playerX, y: groundY + 22)

        gameState = .ready
        startGame()
    }

    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }

        let delta = min(currentTime - lastUpdateTime, 0.05)
        lastUpdateTime = currentTime

        guard gameState == .playing else { return }

        elapsedTime += delta

        if elapsedTime >= 0.1 {
            score += 1
            elapsedTime = 0
            updateHUD()
        }

        if player.position.y < -100 {
            endGame()
        }
    }
}
