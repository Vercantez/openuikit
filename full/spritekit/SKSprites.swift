import Foundation

open class SKTexture: NSObject, NSSecureCoding, NSCopying {
    public var filteringMode: SKTextureFilteringMode = .linear
    public var usesMipmaps: Bool = false
    var _size: CGSize
    var _rect: CGRect
    var _pixels: Data
    var _name: String?

    public override init() {
        _size = CGSize(width: 1, height: 1)
        _rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        _pixels = Data([0, 0, 0, 255])
        super.init()
    }

    public convenience init(imageNamed name: String) {
        self.init()
        _name = name
        _size = CGSize(width: 32, height: 32)
        _pixels = Data(repeating: 255, count: 32 * 32 * 4)
    }

    public convenience init(data pixelData: Data, size: CGSize) {
        self.init()
        _pixels = pixelData
        _size = size
    }

    public convenience init(data pixelData: Data, size: CGSize, flipped: Bool) {
        _ = flipped
        self.init(data: pixelData, size: size)
    }

    public convenience init(data pixelData: Data, size: CGSize, rowLength: UInt32, alignment: UInt32) {
        _ = rowLength
        _ = alignment
        self.init(data: pixelData, size: size)
    }

    public convenience init(rect: CGRect, in texture: SKTexture) {
        self.init()
        _rect = rect
        _size = CGSize(width: texture._size.width * rect.width, height: texture._size.height * rect.height)
        _pixels = texture._pixels
        _name = texture._name
    }

    public convenience init(rect: CGRect, inTexture texture: SKTexture) {
        self.init(rect: rect, in: texture)
    }

    public convenience init(cgImage image: CGImage) {
        self.init(data: Data(image.pixels), size: CGSize(width: image.width, height: image.height))
    }

    public convenience init(CGImage image: CGImage) {
        self.init(cgImage: image)
    }

    public convenience init(noiseWithSmoothness smoothness: CGFloat, size: CGSize, grayscale: Bool) {
        var pixels = [UInt8](repeating: 0, count: max(0, Int(size.width) * Int(size.height) * 4))
        let w = max(1, Int(size.width))
        let h = max(1, Int(size.height))
        for y in 0..<h {
            for x in 0..<w {
                let n = sk_valueNoise(x: x, y: y, smoothness: smoothness)
                let v = UInt8(sk_clamp(n * 255, 0, 255))
                let i = (y * w + x) * 4
                pixels[i] = v
                pixels[i + 1] = grayscale ? v : UInt8((x * 13) & 255)
                pixels[i + 2] = grayscale ? v : UInt8((y * 7) & 255)
                pixels[i + 3] = 255
            }
        }
        self.init(data: Data(pixels), size: size)
    }

    public convenience init(vectorNoiseWithSmoothness smoothness: CGFloat, size: CGSize) {
        self.init(noiseWithSmoothness: smoothness, size: size, grayscale: false)
    }

    public required init?(coder: NSCoder) {
        _size = CGSize(width: 1, height: 1)
        _rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        _pixels = Data([0, 0, 0, 255])
        super.init()
    }

    public func encode(with coder: NSCoder) {}
    public static var supportsSecureCoding: Bool { true }
    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = SKTexture(data: _pixels, size: _size)
        copy.filteringMode = filteringMode
        copy.usesMipmaps = usesMipmaps
        copy._rect = _rect
        return copy
    }

    public func size() -> CGSize { _size }
    public func textureRect() -> CGRect { _rect }

    public func cgImage() -> CGImage {
        CGImage(width: Int(_size.width), height: Int(_size.height), pixels: Array(_pixels))
    }

    public func preload(completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    public class func preload(_ textures: [SKTexture]) async {
        _ = textures
    }

    public func generatingNormalMap() -> Self {
        generatingNormalMap(withSmoothness: 0, contrast: 1)
    }

    public func generatingNormalMap(withSmoothness smoothness: CGFloat, contrast: CGFloat) -> Self {
        _ = smoothness
        _ = contrast
        return self
    }
}

open class SKMutableTexture: SKTexture {
    public init(size: CGSize) {
        super.init()
        _size = size
        _pixels = Data(repeating: 0, count: max(0, Int(size.width) * Int(size.height) * 4))
    }

    public convenience init(size: CGSize, pixelFormat format: Int32) {
        _ = format
        self.init(size: size)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    public func modifyPixelData(_ block: @escaping (UnsafeMutableRawPointer?, Int) -> Void) {
        var bytes = [UInt8](_pixels)
        bytes.withUnsafeMutableBytes { raw in
            block(raw.baseAddress, Int(_size.width) * 4)
        }
        _pixels = Data(bytes)
    }
}

open class SKTextureAtlas: NSObject, NSSecureCoding {
    public private(set) var textureNames: [String]
    var textures: [String: SKTexture]

    public convenience init(named name: String) {
        self.init(dictionary: [name: name])
    }

    public convenience init(dictionary properties: [String: Any]) {
        var map: [String: SKTexture] = [:]
        for (key, value) in properties {
            if let texture = value as? SKTexture {
                map[key] = texture
            } else if let name = value as? String {
                map[key] = SKTexture(imageNamed: name)
            }
        }
        self.init()
        textures = map
        textureNames = map.keys.sorted()
    }

    public override init() {
        textureNames = []
        textures = [:]
        super.init()
    }

    public required init?(coder: NSCoder) {
        textureNames = []
        textures = [:]
        super.init()
    }

    public func encode(with coder: NSCoder) {}
    public static var supportsSecureCoding: Bool { true }

    public func textureNamed(_ name: String) -> SKTexture {
        if let existing = textures[name] { return existing }
        let texture = SKTexture(imageNamed: name)
        textures[name] = texture
        if !textureNames.contains(name) { textureNames.append(name) }
        return texture
    }

    public func preload(completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    public class func preloadTextureAtlases(_ textureAtlases: [SKTextureAtlas]) async {
        _ = textureAtlases
    }

    public class func preloadTextureAtlasesNamed(_ atlasNames: [String]) async throws -> [SKTextureAtlas] {
        atlasNames.map { SKTextureAtlas(named: $0) }
    }
}

func sk_valueNoise(x: Int, y: Int, smoothness: CGFloat) -> CGFloat {
    let h = UInt32(bitPattern: Int32(x &* 374_761_393 &+ y &* 668_265_263))
    let mixed = (h ^ (h >> 13)) &* 1_274_126_177
    let unit = CGFloat(mixed % 1000) / 1000
    return sk_lerp(unit, 0.5, sk_clamp(smoothness, 0, 1))
}

open class SKSpriteNode: SKNode {
    public var texture: SKTexture?
    public var normalTexture: SKTexture?
    public var size: CGSize = CGSize(width: 32, height: 32)
    public var anchorPoint: CGPoint = CGPoint(x: 0.5, y: 0.5)
    public var color: SKColor = .white
    public var colorBlendFactor: CGFloat = 0
    public var blendMode: SKBlendMode = .alpha
    public var centerRect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)
    public var lightingBitMask: UInt32 = 0
    public var shadowedBitMask: UInt32 = 0
    public var shadowCastBitMask: UInt32 = 0
    public var shader: SKShader?

    public convenience init(color: SKColor, size: CGSize) {
        self.init(texture: nil, color: color, size: size)
    }

    public convenience init(imageNamed name: String) {
        let texture = SKTexture(imageNamed: name)
        self.init(texture: texture, color: .white, size: texture.size())
    }

    public convenience init(imageNamed name: String, normalMapped generateNormalMap: Bool) {
        let texture = SKTexture(imageNamed: name)
        self.init(texture: texture, color: .white, size: texture.size())
        if generateNormalMap {
            normalTexture = texture.generatingNormalMap()
        }
    }

    public convenience init(texture: SKTexture?) {
        let size = texture?.size() ?? CGSize(width: 32, height: 32)
        self.init(texture: texture, color: .white, size: size)
    }

    public convenience init(texture: SKTexture?, size: CGSize) {
        self.init(texture: texture, color: .white, size: size)
    }

    public convenience init(texture: SKTexture?, normalMap: SKTexture?) {
        self.init(texture: texture)
        self.normalTexture = normalMap
    }

    public init(texture: SKTexture?, color: SKColor, size: CGSize) {
        self.texture = texture
        self.color = color
        self.size = size
        super.init()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    public func scale(to size: CGSize) {
        self.size = size
    }

    public override var frame: CGRect {
        CGRect(
            x: position.x - size.width * anchorPoint.x * xScale,
            y: position.y - size.height * anchorPoint.y * yScale,
            width: size.width * abs(xScale),
            height: size.height * abs(yScale)
        )
    }
}

open class SKLabelNode: SKNode {
    public var text: String?
    public var attributedText: NSAttributedString?
    public var fontName: String?
    public var fontSize: CGFloat = 32
    public var fontColor: SKColor? = .white
    public var color: SKColor?
    public var colorBlendFactor: CGFloat = 0
    public var blendMode: SKBlendMode = .alpha
    public var horizontalAlignmentMode: SKLabelHorizontalAlignmentMode = .center
    public var verticalAlignmentMode: SKLabelVerticalAlignmentMode = .baseline
    public var numberOfLines: Int = 1
    public var lineBreakMode: NSLineBreakMode = .byWordWrapping
    public var preferredMaxLayoutWidth: CGFloat = 0

    public override init() { super.init() }

    public init(fontNamed fontName: String?) {
        self.fontName = fontName
        super.init()
    }

    public convenience init(text: String?) {
        self.init(fontNamed: nil)
        self.text = text
    }

    public convenience init(attributedText: NSAttributedString?) {
        self.init(fontNamed: nil)
        self.attributedText = attributedText
        self.text = attributedText?.string
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        text = coder.decodeObject(forKey: "text") as? String
    }

    public override var frame: CGRect {
        let width = CGFloat((text ?? "").count) * fontSize * 0.5
        let height = fontSize * CGFloat(max(1, numberOfLines))
        var x = position.x
        var y = position.y
        switch horizontalAlignmentMode {
        case .center: x -= width / 2
        case .left: break
        case .right: x -= width
        }
        switch verticalAlignmentMode {
        case .baseline, .bottom: break
        case .center: y -= height / 2
        case .top: y -= height
        }
        return CGRect(x: x, y: y, width: width, height: height)
    }
}

open class SKShapeNode: SKNode {
    public var path: CGPath?
    public var fillColor: SKColor = .clear
    public var strokeColor: SKColor = .white
    public var lineWidth: CGFloat = 1
    public var glowWidth: CGFloat = 0
    public var isAntialiased: Bool = true
    public var lineCap: CGLineCap = .round
    public var lineJoin: CGLineJoin = .round
    public var miterLimit: CGFloat = 10
    public var blendMode: SKBlendMode = .alpha
    public var fillTexture: SKTexture?
    public var fillShader: SKShader?
    public var strokeTexture: SKTexture?
    public var strokeShader: SKShader?

    public override init() { super.init() }
    public required init?(coder: NSCoder) { super.init(coder: coder) }

    public convenience init(path: CGPath) {
        self.init()
        self.path = path
    }

    public convenience init(path: CGPath, centered: Bool) {
        self.init(path: path)
        _ = centered
    }

    public convenience init(rect: CGRect) {
        self.init(path: CGPath(rect: rect))
    }

    public convenience init(rect: CGRect, cornerRadius: CGFloat) {
        _ = cornerRadius
        self.init(rect: rect)
    }

    public convenience init(rectOf size: CGSize) {
        self.init(rect: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height))
    }

    public convenience init(rectOfSize size: CGSize) {
        self.init(rectOf: size)
    }

    public convenience init(rectOf size: CGSize, cornerRadius: CGFloat) {
        _ = cornerRadius
        self.init(rectOf: size)
    }

    public convenience init(rectOfSize size: CGSize, cornerRadius: CGFloat) {
        self.init(rectOf: size, cornerRadius: cornerRadius)
    }

    public convenience init(circleOfRadius radius: CGFloat) {
        let rect = CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2)
        self.init(path: CGPath(ellipseIn: rect))
    }

    public convenience init(ellipseIn rect: CGRect) {
        self.init(path: CGPath(ellipseIn: rect))
    }

    public convenience init(ellipseInRect rect: CGRect) {
        self.init(ellipseIn: rect)
    }

    public convenience init(ellipseOf size: CGSize) {
        self.init(ellipseIn: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height))
    }

    public convenience init(ellipseOfSize size: CGSize) {
        self.init(ellipseOf: size)
    }

    public convenience init(points: UnsafeMutablePointer<CGPoint>, count numPoints: Int) {
        let buffer = UnsafeBufferPointer(start: points, count: numPoints)
        self.init(path: CGPath(points: Array(buffer)))
    }

    public convenience init(splinePoints points: UnsafeMutablePointer<CGPoint>, count numPoints: Int) {
        self.init(points: points, count: numPoints)
    }

    public var lineLength: CGFloat {
        guard let path else { return 0 }
        return SKPathMath.length(path.commands)
    }

    public override var frame: CGRect {
        let box = path?.boundingBox ?? CGRect(x: -0.5, y: -0.5, width: 1, height: 1)
        return box.offsetBy(dx: position.x, dy: position.y)
    }
}
