import Foundation
import SpriteKit

func testEnumAndOptionSetValues() {
    precondition(SKActionTimingMode.linear.rawValue == 0)
    precondition(SKActionTimingMode.easeIn.rawValue == 1)
    precondition(SKActionTimingMode.easeOut.rawValue == 2)
    precondition(SKActionTimingMode.easeInEaseOut.rawValue == 3)
    precondition(SKAttributeType.none.rawValue == 0)
    precondition(SKAttributeType.float.rawValue == 1)
    precondition(SKAttributeType.vectorFloat2.rawValue == 2)
    precondition(SKAttributeType.vectorFloat3.rawValue == 3)
    precondition(SKAttributeType.vectorFloat4.rawValue == 4)
    precondition(SKAttributeType.halfFloat.rawValue == 5)
    precondition(SKAttributeType.vectorHalfFloat2.rawValue == 6)
    precondition(SKAttributeType.vectorHalfFloat3.rawValue == 7)
    precondition(SKAttributeType.vectorHalfFloat4.rawValue == 8)
    precondition(SKBlendMode.alpha.rawValue == 0)
    precondition(SKBlendMode.add.rawValue == 1)
    precondition(SKBlendMode.subtract.rawValue == 2)
    precondition(SKBlendMode.multiply.rawValue == 3)
    precondition(SKBlendMode.multiplyX2.rawValue == 4)
    precondition(SKBlendMode.screen.rawValue == 5)
    precondition(SKBlendMode.replace.rawValue == 6)
    precondition(SKBlendMode.multiplyAlpha.rawValue == 7)
    precondition(SKInterpolationMode.linear.rawValue == 1)
    precondition(SKInterpolationMode.spline.rawValue == 2)
    precondition(SKInterpolationMode.step.rawValue == 3)
    precondition(SKLabelHorizontalAlignmentMode.center.rawValue == 0)
    precondition(SKLabelHorizontalAlignmentMode.left.rawValue == 1)
    precondition(SKLabelHorizontalAlignmentMode.right.rawValue == 2)
    precondition(SKLabelVerticalAlignmentMode.baseline.rawValue == 0)
    precondition(SKLabelVerticalAlignmentMode.center.rawValue == 1)
    precondition(SKLabelVerticalAlignmentMode.top.rawValue == 2)
    precondition(SKLabelVerticalAlignmentMode.bottom.rawValue == 3)
    precondition(SKNodeFocusBehavior.none.rawValue == 0)
    precondition(SKNodeFocusBehavior.occluding.rawValue == 1)
    precondition(SKNodeFocusBehavior.focusable.rawValue == 2)
    precondition(SKParticleRenderOrder.oldestLast.rawValue == 0)
    precondition(SKParticleRenderOrder.oldestFirst.rawValue == 1)
    precondition(SKParticleRenderOrder.dontCare.rawValue == 2)
    precondition(SKRepeatMode.clamp.rawValue == 1)
    precondition(SKRepeatMode.loop.rawValue == 2)
    precondition(SKSceneScaleMode.fill.rawValue == 0)
    precondition(SKSceneScaleMode.aspectFill.rawValue == 1)
    precondition(SKSceneScaleMode.aspectFit.rawValue == 2)
    precondition(SKSceneScaleMode.resizeFill.rawValue == 3)
    precondition(SKTextureFilteringMode.nearest.rawValue == 0)
    precondition(SKTextureFilteringMode.linear.rawValue == 1)
    precondition(SKTileDefinitionRotation.rotation0.rawValue == 0)
    precondition(SKTileDefinitionRotation.rotation90.rawValue == 1)
    precondition(SKTileDefinitionRotation.rotation180.rawValue == 2)
    precondition(SKTileDefinitionRotation.rotation270.rawValue == 3)
    precondition(SKTileSetType.grid.rawValue == 0)
    precondition(SKTileSetType.isometric.rawValue == 1)
    precondition(SKTileSetType.hexagonalFlat.rawValue == 2)
    precondition(SKTileSetType.hexagonalPointy.rawValue == 3)
    precondition(SKTransitionDirection.up.rawValue == 0)
    precondition(SKTransitionDirection.down.rawValue == 1)
    precondition(SKTransitionDirection.right.rawValue == 2)
    precondition(SKTransitionDirection.left.rawValue == 3)
    precondition(SKUniformType.none.rawValue == 0)
    precondition(SKUniformType.float.rawValue == 1)
    precondition(SKUniformType.floatVector2.rawValue == 2)
    precondition(SKUniformType.floatVector3.rawValue == 3)
    precondition(SKUniformType.floatVector4.rawValue == 4)
    precondition(SKUniformType.floatMatrix2.rawValue == 5)
    precondition(SKUniformType.floatMatrix3.rawValue == 6)
    precondition(SKUniformType.floatMatrix4.rawValue == 7)
    precondition(SKUniformType.texture.rawValue == 8)
    precondition(SKTileAdjacencyMask.adjacencyUp.rawValue == 1)
    precondition(SKTileAdjacencyMask.adjacencyAll.rawValue == 255)
    precondition(SKTileAdjacencyMask.hexFlatAdjacencyAll.rawValue == 63)
    precondition(SKTileAdjacencyMask.hexPointyAdjacencyAdd.rawValue == 63)
    var mask: SKTileAdjacencyMask = [.adjacencyUp, .adjacencyDown]
    precondition(mask.contains(.adjacencyUp))
    precondition(!mask.contains(.adjacencyLeft))
    _ = mask.insert(.adjacencyLeft)
    _ = mask.remove(.adjacencyUp)
    _ = mask.update(with: .adjacencyRight)
    _ = mask.union(.adjacencyAll)
    _ = mask.intersection(.adjacencyDown)
    _ = mask.symmetricDifference(.adjacencyLeft)
    mask.formUnion(.adjacencyUp)
    mask.formIntersection(.adjacencyAll)
    mask.formSymmetricDifference([])
    precondition(SKTileAdjacencyMask().isEmpty)
    precondition(SKTileAdjacencyMask.adjacencyUp.isSubset(of: .adjacencyAll))
    precondition(SKTileAdjacencyMask.adjacencyAll.isSuperset(of: .adjacencyDown))
    precondition(SKTileAdjacencyMask.adjacencyUp.isDisjoint(with: .adjacencyDown))
    precondition(SKTileAdjacencyMask.adjacencyUp.isStrictSubset(of: .adjacencyAll))
    precondition(SKTileAdjacencyMask.adjacencyAll.isStrictSuperset(of: .adjacencyUp))
    var copy = SKTileAdjacencyMask.adjacencyUp
    copy.subtract(.adjacencyUp)
    _ = copy.subtracting(.adjacencyDown)
    _ = SKTileAdjacencyMask(rawValue: 4)
    _ = SKTileAdjacencyMask([.adjacencyUp, .adjacencyLeft])
    _ = SKTileAdjacencyMask(arrayLiteral: .adjacencyDown)
    precondition(SKTileAdjacencyMask.adjacencyUp != .adjacencyDown)
    precondition(SKActionTimingMode.linear != .easeIn)
    precondition(SKBlendMode.alpha != .add)
    precondition(SKInterpolationMode.linear != .step)
    precondition(SKSceneScaleMode.fill != .aspectFit)
    precondition(SKUniformType.float != .texture)
    _ = SKTileAdjacencyMask.adjacencyDownEdge
    _ = SKTileAdjacencyMask.adjacencyLeftEdge
    _ = SKTileAdjacencyMask.adjacencyRightEdge
    _ = SKTileAdjacencyMask.adjacencyUpEdge
    _ = SKTileAdjacencyMask.adjacencyUpperLeft
    _ = SKTileAdjacencyMask.adjacencyUpperRight
    _ = SKTileAdjacencyMask.adjacencyLowerLeft
    _ = SKTileAdjacencyMask.adjacencyLowerRight
    _ = SKTileAdjacencyMask.adjacencyUpperLeftEdge
    _ = SKTileAdjacencyMask.adjacencyUpperRightEdge
    _ = SKTileAdjacencyMask.adjacencyLowerLeftEdge
    _ = SKTileAdjacencyMask.adjacencyLowerRightEdge
    _ = SKTileAdjacencyMask.adjacencyUpperLeftCorner
    _ = SKTileAdjacencyMask.adjacencyUpperRightCorner
    _ = SKTileAdjacencyMask.adjacencyLowerLeftCorner
    _ = SKTileAdjacencyMask.adjacencyLowerRightCorner
    _ = SKTileAdjacencyMask.hexFlatAdjacencyUp
    _ = SKTileAdjacencyMask.hexFlatAdjacencyDown
    _ = SKTileAdjacencyMask.hexFlatAdjacencyUpperLeft
    _ = SKTileAdjacencyMask.hexFlatAdjacencyUpperRight
    _ = SKTileAdjacencyMask.hexFlatAdjacencyLowerLeft
    _ = SKTileAdjacencyMask.hexFlatAdjacencyLowerRight
    _ = SKTileAdjacencyMask.hexPointyAdjacencyLeft
    _ = SKTileAdjacencyMask.hexPointyAdjacencyRight
    _ = SKTileAdjacencyMask.hexPointyAdjacencyUpperLeft
    _ = SKTileAdjacencyMask.hexPointyAdjacencyUpperRight
    _ = SKTileAdjacencyMask.hexPointyAdjacencyLowerLeft
    _ = SKTileAdjacencyMask.hexPointyAdjacencyLowerRight
}

func testVersionMacros() {
    precondition(SK_VERSION == 0)
    precondition(SKVIEW_AVAILABLE == 1)
    precondition(PHYSICSKIT_MINUS_GL_IMPORTS == 1)
}

func testColorAndVectorTypes() {
    let color = SKColor(red: 1, green: 0, blue: 0, alpha: 1)
    precondition(color.red == 1)
    let v = CGVector(dx: 3, dy: 4)
    precondition(v.dx == 3)
    _ = SKColor.white
    _ = SKColor.black
    _ = SKColor.clear
    let timing: SKActionTimingFunction = { $0 * $0 }
    precondition(timing(2) == 4)
}
