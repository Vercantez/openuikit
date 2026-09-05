import Foundation

open class SKTileDefinition: NSObject, NSSecureCoding {
    public var textures: [SKTexture]
    public var normalTextures: [SKTexture]
    public var size: CGSize
    public var timePerFrame: CGFloat
    public var placementWeight: UInt = 1
    public var rotation: SKTileDefinitionRotation = .rotation0
    public var flipHorizontally: Bool = false
    public var flipVertically: Bool = false
    public var name: String?
    public var userData: NSMutableDictionary?

    public init(texture: SKTexture) {
        textures = [texture]
        normalTextures = []
        size = texture.size()
        timePerFrame = 0
        super.init()
    }

    public init(texture: SKTexture, size: CGSize) {
        textures = [texture]
        normalTextures = []
        self.size = size
        timePerFrame = 0
        super.init()
    }

    public init(texture: SKTexture, normalTexture: SKTexture, size: CGSize) {
        textures = [texture]
        normalTextures = [normalTexture]
        self.size = size
        timePerFrame = 0
        super.init()
    }

    public init(textures: [SKTexture], size: CGSize, timePerFrame: CGFloat) {
        self.textures = textures
        self.normalTextures = []
        self.size = size
        self.timePerFrame = timePerFrame
        super.init()
    }

    public init(textures: [SKTexture], normalTextures: [SKTexture], size: CGSize, timePerFrame: CGFloat) {
        self.textures = textures
        self.normalTextures = normalTextures
        self.size = size
        self.timePerFrame = timePerFrame
        super.init()
    }

    public required init?(coder: NSCoder) {
        textures = []
        normalTextures = []
        size = .zero
        timePerFrame = 0
        super.init()
    }

    public func encode(with coder: NSCoder) {}
    public static var supportsSecureCoding: Bool { true }
}

open class SKTileGroupRule: NSObject, NSSecureCoding {
    public var adjacency: SKTileAdjacencyMask
    public var tileDefinitions: [SKTileDefinition]
    public var name: String?

    public init(adjacency: SKTileAdjacencyMask, tileDefinitions: [SKTileDefinition]) {
        self.adjacency = adjacency
        self.tileDefinitions = tileDefinitions
        super.init()
    }

    public required init?(coder: NSCoder) {
        adjacency = []
        tileDefinitions = []
        super.init()
    }

    public func encode(with coder: NSCoder) {}
    public static var supportsSecureCoding: Bool { true }
}

open class SKTileGroup: NSObject, NSSecureCoding {
    public var rules: [SKTileGroupRule]
    public var name: String?

    public init(rules: [SKTileGroupRule]) {
        self.rules = rules
        super.init()
    }

    public init(tileDefinition: SKTileDefinition) {
        self.rules = [SKTileGroupRule(adjacency: .adjacencyAll, tileDefinitions: [tileDefinition])]
        super.init()
    }

    public class func empty() -> SKTileGroup {
        SKTileGroup(rules: [])
    }

    public required init?(coder: NSCoder) {
        rules = []
        super.init()
    }

    public func encode(with coder: NSCoder) {}
    public static var supportsSecureCoding: Bool { true }
}

open class SKTileSet: NSObject, NSSecureCoding {
    public var tileGroups: [SKTileGroup]
    public var type: SKTileSetType
    public var name: String?
    public var defaultTileGroup: SKTileGroup?
    public var defaultTileSize: CGSize = CGSize(width: 32, height: 32)

    public init(tileGroups: [SKTileGroup]) {
        self.tileGroups = tileGroups
        self.type = .grid
        super.init()
    }

    public init(tileGroups: [SKTileGroup], tileSetType: SKTileSetType) {
        self.tileGroups = tileGroups
        self.type = tileSetType
        super.init()
    }

    public convenience init?(named name: String) {
        _ = name
        return nil
    }

    public convenience init?(from url: URL) {
        _ = url
        return nil
    }

    public convenience init?(fromURL url: URL) {
        self.init(from: url)
    }

    public required init?(coder: NSCoder) {
        tileGroups = []
        type = .grid
        super.init()
    }

    public func encode(with coder: NSCoder) {}
    public static var supportsSecureCoding: Bool { true }
}

open class SKTileMapNode: SKNode {
    public var tileSet: SKTileSet
    public var numberOfColumns: UInt
    public var numberOfRows: UInt
    public var tileSize: CGSize
    public var anchorPoint: CGPoint = CGPoint(x: 0.5, y: 0.5)
    public var color: SKColor = .white
    public var colorBlendFactor: CGFloat = 0
    public var blendMode: SKBlendMode = .alpha
    public var lightingBitMask: UInt32 = 0
    public var enableAutomapping: Bool = false
    public var shader: SKShader?
    var groups: [[SKTileGroup?]]
    var definitions: [[SKTileDefinition?]]

    public init(tileSet: SKTileSet, columns: UInt, rows: UInt, tileSize: CGSize) {
        self.tileSet = tileSet
        self.numberOfColumns = columns
        self.numberOfRows = rows
        self.tileSize = tileSize
        groups = Array(repeating: Array(repeating: nil, count: Int(columns)), count: Int(rows))
        definitions = Array(repeating: Array(repeating: nil, count: Int(columns)), count: Int(rows))
        super.init()
    }

    public convenience init(
        tileSet: SKTileSet,
        columns: UInt,
        rows: UInt,
        tileSize: CGSize,
        fillWith tileGroup: SKTileGroup
    ) {
        self.init(tileSet: tileSet, columns: columns, rows: rows, tileSize: tileSize)
        fill(with: tileGroup)
    }

    public convenience init(
        tileSet: SKTileSet,
        columns: UInt,
        rows: UInt,
        tileSize: CGSize,
        fillWithTileGroup tileGroup: SKTileGroup
    ) {
        self.init(tileSet: tileSet, columns: columns, rows: rows, tileSize: tileSize, fillWith: tileGroup)
    }

    public init(
        tileSet: SKTileSet,
        columns: UInt,
        rows: UInt,
        tileSize: CGSize,
        tileGroupLayout: [SKTileGroup]
    ) {
        self.tileSet = tileSet
        self.numberOfColumns = columns
        self.numberOfRows = rows
        self.tileSize = tileSize
        groups = Array(repeating: Array(repeating: nil, count: Int(columns)), count: Int(rows))
        definitions = Array(repeating: Array(repeating: nil, count: Int(columns)), count: Int(rows))
        super.init()
        var i = 0
        for r in 0..<Int(rows) {
            for c in 0..<Int(columns) {
                if i < tileGroupLayout.count {
                    groups[r][c] = tileGroupLayout[i]
                    i += 1
                }
            }
        }
    }

    public required init?(coder: NSCoder) {
        tileSet = SKTileSet(tileGroups: [])
        numberOfColumns = 0
        numberOfRows = 0
        tileSize = .zero
        groups = []
        definitions = []
        super.init(coder: coder)
    }

    public var mapSize: CGSize {
        CGSize(width: CGFloat(numberOfColumns) * tileSize.width, height: CGFloat(numberOfRows) * tileSize.height)
    }

    public func fill(with tileGroup: SKTileGroup?) {
        for r in 0..<Int(numberOfRows) {
            for c in 0..<Int(numberOfColumns) {
                groups[r][c] = tileGroup
                definitions[r][c] = tileGroup?.rules.first?.tileDefinitions.first
            }
        }
    }

    public func setTileGroup(_ tileGroup: SKTileGroup?, forColumn column: UInt, row: UInt) {
        guard _valid(column, row) else { return }
        groups[Int(row)][Int(column)] = tileGroup
        definitions[Int(row)][Int(column)] = tileGroup?.rules.first?.tileDefinitions.first
    }

    public func setTileGroup(
        _ tileGroup: SKTileGroup,
        andTileDefinition tileDefinition: SKTileDefinition,
        forColumn column: UInt,
        row: UInt
    ) {
        guard _valid(column, row) else { return }
        groups[Int(row)][Int(column)] = tileGroup
        definitions[Int(row)][Int(column)] = tileDefinition
    }

    public func tileGroup(atColumn column: UInt, row: UInt) -> SKTileGroup? {
        guard _valid(column, row) else { return nil }
        return groups[Int(row)][Int(column)]
    }

    public func tileDefinition(atColumn column: UInt, row: UInt) -> SKTileDefinition? {
        guard _valid(column, row) else { return nil }
        return definitions[Int(row)][Int(column)]
    }

    public func centerOfTile(atColumn column: UInt, row: UInt) -> CGPoint {
        let origin = CGPoint(
            x: -mapSize.width * anchorPoint.x,
            y: -mapSize.height * anchorPoint.y
        )
        return CGPoint(
            x: origin.x + (CGFloat(column) + 0.5) * tileSize.width,
            y: origin.y + (CGFloat(row) + 0.5) * tileSize.height
        )
    }

    public func tileColumnIndex(fromPosition position: CGPoint) -> UInt {
        let origin = CGPoint(
            x: -mapSize.width * anchorPoint.x,
            y: -mapSize.height * anchorPoint.y
        )
        let col = Int(((position.x - origin.x) / max(tileSize.width, 0.0001)).rounded(.down))
        return UInt(max(0, min(col, Int(numberOfColumns) - 1)))
    }

    public func tileRowIndex(fromPosition position: CGPoint) -> UInt {
        let origin = CGPoint(
            x: -mapSize.width * anchorPoint.x,
            y: -mapSize.height * anchorPoint.y
        )
        let row = Int(((position.y - origin.y) / max(tileSize.height, 0.0001)).rounded(.down))
        return UInt(max(0, min(row, Int(numberOfRows) - 1)))
    }

    func _valid(_ column: UInt, _ row: UInt) -> Bool {
        column < numberOfColumns && row < numberOfRows
    }

    public override var frame: CGRect {
        CGRect(
            x: position.x - mapSize.width * anchorPoint.x,
            y: position.y - mapSize.height * anchorPoint.y,
            width: mapSize.width,
            height: mapSize.height
        )
    }
}
