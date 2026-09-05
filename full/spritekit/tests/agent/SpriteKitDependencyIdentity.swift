import SpriteKit
import CoreGraphics
import Foundation
import QuartzCore
import UIKit

// Isolated host gate does not compile this file. The clean EC2 integration
// build is the authority for passing genuine CoreGraphics / QuartzCore /
// UIKit values through SpriteKit APIs.
func spriteKitDependencyIdentityProbe() {
    let node = SKNode()
    node.position = CGPoint(x: 1, y: 2)
    _ = node.position
    let scene = SKScene(size: CGSize(width: 64, height: 64))
    _ = scene.size
}
