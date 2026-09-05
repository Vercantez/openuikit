import Foundation
import SpriteKit

func testEmitterAndKeyframe() {
    let emitter = SKEmitterNode()
    emitter.particleBirthRate = 10
    emitter.numParticlesToEmit = 5
    emitter.particleLifetime = 1
    emitter.particleLifetimeRange = 0.1
    emitter.particlePosition = .zero
    emitter.particlePositionRange = CGVector(dx: 4, dy: 4)
    emitter.particleSpeed = 20
    emitter.particleSpeedRange = 2
    emitter.emissionAngle = 0
    emitter.emissionAngleRange = 0.2
    emitter.xAcceleration = 0
    emitter.yAcceleration = -9
    emitter.particleAlpha = 1
    emitter.particleAlphaRange = 0
    emitter.particleAlphaSpeed = 0
    emitter.particleScale = 1
    emitter.particleScaleRange = 0
    emitter.particleScaleSpeed = 0
    emitter.particleRotation = 0
    emitter.particleRotationRange = 0
    emitter.particleRotationSpeed = 0
    emitter.particleSize = CGSize(width: 2, height: 2)
    emitter.particleColor = .white
    emitter.particleColorBlendFactor = 1
    emitter.particleColorRedRange = 0
    emitter.particleColorGreenRange = 0
    emitter.particleColorBlueRange = 0
    emitter.particleColorAlphaRange = 0
    emitter.particleColorRedSpeed = 0
    emitter.particleColorGreenSpeed = 0
    emitter.particleColorBlueSpeed = 0
    emitter.particleColorAlphaSpeed = 0
    emitter.particleColorBlendFactorRange = 0
    emitter.particleColorBlendFactorSpeed = 0
    emitter.particleZPosition = 0
    emitter.particleZPositionRange = 0
    emitter.particleZPositionSpeed = 0
    emitter.particleBlendMode = .add
    emitter.particleRenderOrder = .oldestFirst
    emitter.fieldBitMask = 1
    emitter.particleTexture = SKTexture(imageNamed: "p")
    emitter.advanceSimulationTime(0.5)
    emitter.resetSimulation()
    let seq = SKKeyframeSequence(keyframeValues: [0, 1], times: [0, 1])
    seq.interpolationMode = .linear
    seq.repeatMode = .clamp
    seq.addKeyframeValue(0.5 as CGFloat, time: 0.5)
    _ = seq.count()
    _ = seq.sample(atTime: 0.25) as? CGFloat
    _ = seq.getKeyframeTime(for: 0)
    _ = seq.getKeyframeValue(for: 0)
    seq.setKeyframeTime(0.1, for: 0)
    seq.setKeyframeValue(0.2 as CGFloat, for: 0)
    seq.setKeyframeValue(0.3 as CGFloat, time: 0.2, for: 0)
    seq.removeKeyframe(at: UInt(seq.count() - 1))
    seq.removeLastKeyframe()
    emitter.particleAlphaSequence = seq
    emitter.particleScaleSequence = seq
    emitter.particleColorSequence = seq
    emitter.particleColorBlendFactorSequence = seq
    emitter.particleAction = SKAction.wait(forDuration: 0)
    _ = SKKeyframeSequence(capacity: 4)
}

func testFieldNodeFactories() {
    _ = SKFieldNode.dragField()
    _ = SKFieldNode.electricField()
    _ = SKFieldNode.magneticField()
    _ = SKFieldNode.radialGravityField()
    _ = SKFieldNode.springField()
    _ = SKFieldNode.vortexField()
    let linear = SKFieldNode.linearGravityField(withVector: SIMD3<Float>(0, -1, 0))
    linear.strength = 2
    linear.falloff = 1
    linear.minimumRadius = 0
    linear.isEnabled = true
    linear.isExclusive = false
    linear.categoryBitMask = 1
    linear.smoothness = 0
    linear.animationSpeed = 0
    linear.direction = SIMD3<Float>(0, 1, 0)
    linear.region = SKRegion.infinite()
    _ = SKFieldNode.velocityField(withVector: SIMD3<Float>(1, 0, 0))
    _ = SKFieldNode.velocityField(with: SKTexture(imageNamed: "v"))
    _ = SKFieldNode.noiseField(withSmoothness: 0.5, animationSpeed: 1)
    _ = SKFieldNode.turbulenceField(withSmoothness: 0.5, animationSpeed: 1)
    let custom = SKFieldNode.customField { _, _, _, strength, _ in
        SIMD3<Float>(strength, 0, 0)
    }
    _ = custom.strength
}

func testTileMapAndSet() {
    let def = SKTileDefinition(texture: SKTexture(imageNamed: "t"))
    def.flipHorizontally = false
    def.flipVertically = false
    def.rotation = .rotation90
    def.placementWeight = 2
    def.name = "floor"
    def.timePerFrame = 0.1
    def.size = CGSize(width: 16, height: 16)
    def.userData = NSMutableDictionary()
    _ = SKTileDefinition(texture: SKTexture(imageNamed: "t"), size: CGSize(width: 8, height: 8))
    _ = SKTileDefinition(
        texture: SKTexture(imageNamed: "t"),
        normalTexture: SKTexture(imageNamed: "n"),
        size: CGSize(width: 8, height: 8)
    )
    _ = SKTileDefinition(
        textures: [SKTexture(imageNamed: "t")],
        size: CGSize(width: 8, height: 8),
        timePerFrame: 0.1
    )
    _ = SKTileDefinition(
        textures: [SKTexture(imageNamed: "t")],
        normalTextures: [],
        size: CGSize(width: 8, height: 8),
        timePerFrame: 0.1
    )
    let rule = SKTileGroupRule(adjacency: .adjacencyAll, tileDefinitions: [def])
    rule.name = "r"
    let group = SKTileGroup(tileDefinition: def)
    group.name = "g"
    group.rules = [rule]
    _ = SKTileGroup(rules: [rule])
    _ = SKTileGroup.empty()
    let set = SKTileSet(tileGroups: [group], tileSetType: .grid)
    set.name = "tiles"
    set.defaultTileGroup = group
    set.defaultTileSize = CGSize(width: 16, height: 16)
    set.type = .grid
    _ = SKTileSet(tileGroups: [group])
    precondition(SKTileSet(named: "missing") == nil)
    precondition(SKTileSet(from: URL(fileURLWithPath: "/tmp/x.sks")) == nil)
    _ = SKTileSet(fromURL: URL(fileURLWithPath: "/tmp/x.sks"))
    let map = SKTileMapNode(tileSet: set, columns: 4, rows: 3, tileSize: CGSize(width: 16, height: 16))
    map.fill(with: group)
    map.enableAutomapping = true
    map.color = .white
    map.colorBlendFactor = 0
    map.blendMode = .alpha
    map.lightingBitMask = 0
    map.anchorPoint = CGPoint(x: 0.5, y: 0.5)
    let center = map.centerOfTile(atColumn: 1, row: 1)
    let col = map.tileColumnIndex(fromPosition: center)
    let row = map.tileRowIndex(fromPosition: center)
    precondition(col == 1 && row == 1)
    map.setTileGroup(group, forColumn: 0, row: 0)
    map.setTileGroup(group, andTileDefinition: def, forColumn: 0, row: 0)
    _ = map.tileGroup(atColumn: 0, row: 0)
    _ = map.tileDefinition(atColumn: 0, row: 0)
    _ = map.mapSize
    _ = SKTileMapNode(
        tileSet: set, columns: 2, rows: 2, tileSize: CGSize(width: 8, height: 8),
        fillWith: group
    )
    _ = SKTileMapNode(
        tileSet: set, columns: 2, rows: 2, tileSize: CGSize(width: 8, height: 8),
        fillWithTileGroup: group
    )
    _ = SKTileMapNode(
        tileSet: set, columns: 2, rows: 2, tileSize: CGSize(width: 8, height: 8),
        tileGroupLayout: [group, group, group, group]
    )
}

func testConstraintsRangeRegionWarp() {
    let range = SKRange(lowerLimit: 0, upperLimit: 10)
    precondition(range.lowerLimit == 0)
    _ = SKRange(constantValue: 4)
    _ = SKRange(lowerLimit: 1)
    _ = SKRange(upperLimit: 5)
    _ = SKRange(value: 3, variance: 1)
    _ = SKRange.withNoLimits()
    let scene = SKScene(size: CGSize(width: 40, height: 40))
    let node = SKNode()
    node.position = CGPoint(x: 20, y: -4)
    scene.addChild(node)
    let cx = SKConstraint.positionX(range)
    cx.enabled = true
    cx.referenceNode = node
    node.constraints = [cx]
    node.subdivisionLevels = 1
    node.warpGeometry = SKWarpGeometry()
    scene.update(0)
    scene.update(0.1)
    precondition(node.position.x == 10)
    _ = SKConstraint.positionY(range)
    _ = SKConstraint.positionX(range, y: range)
    _ = SKConstraint.zRotation(range)
    let other = SKNode()
    _ = SKConstraint.distance(range, to: other)
    _ = SKConstraint.distance(range, to: .zero)
    _ = SKConstraint.distance(range, to: .zero, in: other)
    _ = SKConstraint.orient(to: other, offset: range)
    _ = SKConstraint.orient(to: .zero, offset: range)
    _ = SKConstraint.orient(to: .zero, in: other, offset: range)
    let region = SKRegion(radius: 5)
    precondition(region.contains(.zero))
    _ = SKRegion(size: CGSize(width: 4, height: 4))
    _ = SKRegion(path: CGPath(rect: CGRect(x: -1, y: -1, width: 2, height: 2)))
    _ = SKRegion.infinite()
    _ = region.inverse()
    _ = region.byUnion(with: region)
    _ = region.byIntersection(with: region)
    _ = region.byDifference(from: region)
    let grid = SKWarpGeometryGrid(columns: 2, rows: 2)
    precondition(grid.vertexCount == 9)
    _ = grid.sourcePosition(at: 0)
    _ = grid.destPosition(at: 0)
    _ = grid.replacingBySourcePositions(positions: [])
    _ = grid.replacingByDestinationPositions(positions: [])
    _ = SKWarpGeometryGrid(columns: 1, rows: 1, sourcePositions: [], destinationPositions: [])
    _ = SKWarpGeometry()
    let attr = SKAttribute(name: "a", type: .float)
    precondition(attr.type == .float)
    let value = SKAttributeValue(float: 3)
    _ = SKAttributeValue(vectorFloat2: SIMD2<Float>(1, 2))
    _ = SKAttributeValue(vectorFloat3: SIMD3<Float>(1, 2, 3))
    _ = SKAttributeValue(vectorFloat4: SIMD4<Float>(1, 2, 3, 4))
    _ = SKAttributeValue()
    let uniform = SKUniform(name: "u", float: 1)
    precondition(uniform.uniformType == .float)
    uniform.floatValue = 2
    uniform.vectorFloat2Value = SIMD2<Float>(1, 0)
    uniform.vectorFloat3Value = SIMD3<Float>(0, 1, 0)
    uniform.vectorFloat4Value = SIMD4<Float>(0, 0, 1, 0)
    uniform.matrixFloat2x2Value = matrix_float2x2()
    uniform.matrixFloat3x3Value = matrix_float3x3()
    uniform.matrixFloat4x4Value = matrix_float4x4()
    uniform.textureValue = SKTexture(imageNamed: "u")
    _ = uniform.name
    _ = SKUniform(name: "n")
    _ = SKUniform(name: "v2", vectorFloat2: SIMD2<Float>(0, 1))
    _ = SKUniform(name: "v3", vectorFloat3: SIMD3<Float>(0, 1, 0))
    _ = SKUniform(name: "v4", vectorFloat4: SIMD4<Float>(0, 0, 0, 1))
    _ = SKUniform(name: "m2", matrixFloat2x2: matrix_float2x2())
    _ = SKUniform(name: "m3", matrixFloat3x3: matrix_float3x3())
    _ = SKUniform(name: "m4", matrixFloat4x4: matrix_float4x4())
    _ = SKUniform(name: "tex", texture: SKTexture(imageNamed: "t"))
    let shader = SKShader(source: "void main() {}")
    shader.addUniform(uniform)
    precondition(shader.uniformNamed("u") != nil)
    shader.removeUniformNamed("u")
    shader.attributes = [attr]
    _ = SKShader(source: "", uniforms: [])
    _ = SKShader(fileNamed: "missing.fsh")
    let reach = SKReachConstraints(lowerAngleLimit: 0, upperAngleLimit: 1)
    _ = reach.copy()
}
