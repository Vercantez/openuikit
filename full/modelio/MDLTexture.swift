import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

open class MDLTexture: NSObject, MDLNamed {
    public var name: String = ""
    public private(set) var dimensions: SIMD2<Int32>
    public private(set) var rowStride: Int
    public private(set) var channelCount: UInt
    public private(set) var channelEncoding: MDLTextureChannelEncoding
    public var isCube: Bool
    public var hasAlphaValues: Bool
    public private(set) var mipLevelCount: UInt
    var texels: Data

    public override init() {
        dimensions = SIMD2<Int32>(1, 1)
        channelCount = 4
        channelEncoding = .uInt8
        rowStride = 4
        isCube = false
        hasAlphaValues = true
        mipLevelCount = 1
        texels = Data(count: 4)
        super.init()
    }

    public init(
        data pixelData: Data?,
        topLeftOrigin: Bool,
        name: String?,
        dimensions: SIMD2<Int32>,
        rowStride: Int,
        channelCount: UInt,
        channelEncoding: MDLTextureChannelEncoding,
        isCube: Bool
    ) {
        self.name = name ?? ""
        self.dimensions = dimensions
        self.rowStride = rowStride
        self.channelCount = channelCount
        self.channelEncoding = channelEncoding
        self.isCube = isCube
        self.hasAlphaValues = channelCount >= 4
        self.mipLevelCount = 1
        let expected = max(rowStride, 1) * max(Int(dimensions.y), 1)
        self.texels = pixelData ?? Data(count: expected)
        super.init()
        if !topLeftOrigin {
            self.texels = mdlFlipRows(self.texels, widthStride: rowStride, height: Int(dimensions.y))
        }
    }

    public convenience init?(named name: String) {
        self.init(named: name, bundle: nil)
    }

    public convenience init?(named name: String, bundle bundleOrNil: Bundle?) {
        _ = bundleOrNil
        self.init(named: name, assetResolver: MDLPathAssetResolver(path: FileManager.default.currentDirectoryPath))
        self.name = name
        if texels.isEmpty { return nil }
    }

    public convenience init?(named name: String, assetResolver resolver: any MDLAssetResolver) {
        guard resolver.canResolveAssetNamed(name) else { return nil }
        let url = resolver.resolveAssetNamed(name)
        guard let data = try? Data(contentsOf: url) else { return nil }
        self.init(
            data: data,
            topLeftOrigin: true,
            name: name,
            dimensions: SIMD2<Int32>(1, 1),
            rowStride: data.count,
            channelCount: 4,
            channelEncoding: .uInt8,
            isCube: false
        )
    }

    public convenience init?(cubeWithImagesNamed names: [String]) {
        self.init(cubeWithImagesNamed: names, bundle: nil)
    }

    public convenience init?(cubeWithImagesNamed names: [String], bundle bundleOrNil: Bundle?) {
        _ = bundleOrNil
        guard names.count == 6 else { return nil }
        self.init()
        self.isCube = true
        self.name = names.joined(separator: ",")
    }

    public class func irradianceTextureCube(with texture: MDLTexture, name: String?, dimensions: SIMD2<Int32>) -> Self {
        irradianceTextureCube(with: texture, name: name, dimensions: dimensions, roughness: 0)
    }

    public class func irradianceTextureCube(
        with texture: MDLTexture,
        name: String?,
        dimensions: SIMD2<Int32>,
        roughness: Float
    ) -> Self {
        _ = (texture, roughness)
        let width = max(Int(dimensions.x), 1)
        let height = max(Int(dimensions.y), 1)
        return MDLTexture(
            data: Data(count: width * height * 4),
            topLeftOrigin: true,
            name: name,
            dimensions: dimensions,
            rowStride: width * 4,
            channelCount: 4,
            channelEncoding: .uInt8,
            isCube: true
        ) as! Self
    }

    public func texelDataWithTopLeftOrigin() -> Data? { texels }

    public func texelDataWithBottomLeftOrigin() -> Data? {
        mdlFlipRows(texels, widthStride: rowStride, height: Int(dimensions.y))
    }

    public func texelDataWithTopLeftOrigin(atMipLevel level: Int, create: Bool) -> Data? {
        _ = (level, create)
        return texelDataWithTopLeftOrigin()
    }

    public func texelDataWithBottomLeftOrigin(atMipLevel level: Int, create: Bool) -> Data? {
        _ = (level, create)
        return texelDataWithBottomLeftOrigin()
    }

    public func write(to URL: URL) -> Bool {
        do {
            try texels.write(to: URL)
            return true
        } catch {
            return false
        }
    }

    public func write(to URL: URL, level: UInt) -> Bool {
        _ = level
        return write(to: URL)
    }

    public func write(to nsurl: URL, type: NSString) -> Bool {
        _ = type
        return write(to: nsurl)
    }

    public func write(to nsurl: URL, type: NSString, level: UInt) -> Bool {
        _ = (type, level)
        return write(to: nsurl)
    }
}

func mdlFlipRows(_ data: Data, widthStride: Int, height: Int) -> Data {
    guard widthStride > 0, height > 0, data.count >= widthStride * height else { return data }
    var flipped = Data()
    for row in stride(from: height - 1, through: 0, by: -1) {
        let start = row * widthStride
        flipped.append(data.subdata(in: start..<(start + widthStride)))
    }
    return flipped
}

public class MDLTextureFilter: NSObject {
    public var magFilter: MDLMaterialTextureFilterMode = .linear
    public var minFilter: MDLMaterialTextureFilterMode = .linear
    public var mipFilter: MDLMaterialMipMapFilterMode = .linear
    public var sWrapMode: MDLMaterialTextureWrapMode = .clamp
    public var tWrapMode: MDLMaterialTextureWrapMode = .clamp
    public var rWrapMode: MDLMaterialTextureWrapMode = .clamp
}

public class MDLTextureSampler: NSObject {
    public var texture: MDLTexture?
    public var hardwareFilter: MDLTextureFilter?
    public var transform: MDLTransform?
}

public class MDLURLTexture: MDLTexture {
    public var url: URL

    public init(url URL: URL, name: String?) {
        self.url = URL
        let data = try? Data(contentsOf: URL)
        super.init(
            data: data,
            topLeftOrigin: true,
            name: name,
            dimensions: SIMD2<Int32>(1, 1),
            rowStride: data?.count ?? 0,
            channelCount: 4,
            channelEncoding: .uInt8,
            isCube: false
        )
    }

    public convenience init(URL: URL, name: String?) {
        self.init(url: URL, name: name)
    }
}

public class MDLCheckerboardTexture: MDLTexture {
    public var divisions: Float
#if canImport(CoreGraphics)
    public var color1: CGColor?
    public var color2: CGColor?
#endif

    public init(
        divisions: Float,
        name: String?,
        dimensions: SIMD2<Int32>,
        channelCount: Int32,
        channelEncoding: MDLTextureChannelEncoding
    ) {
        self.divisions = divisions
        let w = max(Int(dimensions.x), 1)
        let h = max(Int(dimensions.y), 1)
        let channels = max(Int(channelCount), 1)
        var pixels = Data(count: w * h * channels)
        let n = max(divisions, 1)
        for y in 0..<h {
            for x in 0..<w {
                let on = (Int(Float(x) / (Float(w) / n)) + Int(Float(y) / (Float(h) / n))) % 2 == 0
                let value: UInt8 = on ? 255 : 0
                let offset = (y * w + x) * channels
                for c in 0..<channels {
                    pixels[offset + c] = value
                }
            }
        }
        super.init(
            data: pixels,
            topLeftOrigin: true,
            name: name,
            dimensions: dimensions,
            rowStride: w * channels,
            channelCount: UInt(channels),
            channelEncoding: channelEncoding,
            isCube: false
        )
    }

#if canImport(CoreGraphics)
    public convenience init(
        divisions: Float,
        name: String?,
        dimensions: SIMD2<Int32>,
        channelCount: Int32,
        channelEncoding: MDLTextureChannelEncoding,
        color1: CGColor,
        color2: CGColor
    ) {
        self.init(
            divisions: divisions,
            name: name,
            dimensions: dimensions,
            channelCount: channelCount,
            channelEncoding: channelEncoding
        )
        self.color1 = color1
        self.color2 = color2
    }
#endif
}

public class MDLColorSwatchTexture: MDLTexture {
    public init(
        colorTemperatureGradientFrom colorTemperature1: Float,
        toColorTemperature colorTemperature2: Float,
        name: String?,
        textureDimensions: SIMD2<Int32>
    ) {
        let w = max(Int(textureDimensions.x), 1)
        let h = max(Int(textureDimensions.y), 1)
        var pixels = Data(count: w * h * 4)
        for x in 0..<w {
            let t = w == 1 ? 0 : Float(x) / Float(w - 1)
            let temp = colorTemperature1 + (colorTemperature2 - colorTemperature1) * t
            let rgb = mdlBlackbody(temp)
            for y in 0..<h {
                let o = (y * w + x) * 4
                pixels[o] = UInt8(max(0, min(255, rgb.x * 255)))
                pixels[o + 1] = UInt8(max(0, min(255, rgb.y * 255)))
                pixels[o + 2] = UInt8(max(0, min(255, rgb.z * 255)))
                pixels[o + 3] = 255
            }
        }
        super.init(
            data: pixels,
            topLeftOrigin: true,
            name: name,
            dimensions: textureDimensions,
            rowStride: w * 4,
            channelCount: 4,
            channelEncoding: .uInt8,
            isCube: false
        )
    }

#if canImport(CoreGraphics)
    public convenience init(
        colorGradientFrom color1: CGColor,
        to color2: CGColor,
        name: String?,
        textureDimensions: SIMD2<Int32>
    ) {
        self.init(colorTemperatureGradientFrom: 6500, toColorTemperature: 6500, name: name, textureDimensions: textureDimensions)
        _ = (color1, color2)
    }

    public convenience init(
        colorGradientFrom color1: CGColor,
        toColor color2: CGColor,
        name: String?,
        textureDimensions: SIMD2<Int32>
    ) {
        self.init(colorGradientFrom: color1, to: color2, name: name, textureDimensions: textureDimensions)
    }
#endif
}

public class MDLNoiseTexture: MDLTexture {
    public init(
        vectorNoiseWithSmoothness smoothness: Float,
        name: String?,
        textureDimensions: SIMD2<Int32>,
        channelEncoding: MDLTextureChannelEncoding
    ) {
        let data = mdlGenerateNoise(dimensions: textureDimensions, smoothness: smoothness, channels: 3, grayscale: false)
        super.init(
            data: data,
            topLeftOrigin: true,
            name: name,
            dimensions: textureDimensions,
            rowStride: max(Int(textureDimensions.x), 1) * 3,
            channelCount: 3,
            channelEncoding: channelEncoding,
            isCube: false
        )
    }

    public init(
        scalarNoiseWithSmoothness smoothness: Float,
        name: String?,
        textureDimensions: SIMD2<Int32>,
        channelCount: Int32,
        channelEncoding: MDLTextureChannelEncoding,
        grayscale: Bool
    ) {
        let channels = max(Int(channelCount), 1)
        let data = mdlGenerateNoise(
            dimensions: textureDimensions,
            smoothness: smoothness,
            channels: channels,
            grayscale: grayscale
        )
        super.init(
            data: data,
            topLeftOrigin: true,
            name: name,
            dimensions: textureDimensions,
            rowStride: max(Int(textureDimensions.x), 1) * channels,
            channelCount: UInt(channels),
            channelEncoding: channelEncoding,
            isCube: false
        )
    }

    public init(
        cellularNoiseWithFrequency frequency: Float,
        name: String?,
        textureDimensions: SIMD2<Int32>,
        channelEncoding: MDLTextureChannelEncoding
    ) {
        let data = mdlGenerateNoise(
            dimensions: textureDimensions,
            smoothness: max(1 / max(frequency, 0.001), 0.01),
            channels: 1,
            grayscale: true
        )
        super.init(
            data: data,
            topLeftOrigin: true,
            name: name,
            dimensions: textureDimensions,
            rowStride: max(Int(textureDimensions.x), 1),
            channelCount: 1,
            channelEncoding: channelEncoding,
            isCube: false
        )
    }
}

public class MDLNormalMapTexture: MDLTexture {
    public convenience init(
        byGeneratingNormalMapWith sourceTexture: MDLTexture,
        name: String?,
        smoothness: Float,
        contrast: Float
    ) {
        self.init(
            byGeneratingNormalMapWithTexture: sourceTexture,
            name: name,
            smoothness: smoothness,
            contrast: contrast
        )
    }

    public init(
        byGeneratingNormalMapWithTexture sourceTexture: MDLTexture,
        name: String?,
        smoothness: Float,
        contrast: Float
    ) {
        let w = max(Int(sourceTexture.dimensions.x), 1)
        let h = max(Int(sourceTexture.dimensions.y), 1)
        let src = sourceTexture.texelDataWithTopLeftOrigin() ?? Data(count: w * h)
        var dst = Data(count: w * h * 3)
        _ = smoothness
        for y in 0..<h {
            for x in 0..<w {
                let left = mdlSampleGray(src, w: w, h: h, x: x - 1, y: y)
                let right = mdlSampleGray(src, w: w, h: h, x: x + 1, y: y)
                let up = mdlSampleGray(src, w: w, h: h, x: x, y: y - 1)
                let down = mdlSampleGray(src, w: w, h: h, x: x, y: y + 1)
                let dx = (right - left) * contrast
                let dy = (down - up) * contrast
                var n = simd_normalize(SIMD3(-dx, -dy, 1))
                n = n * 0.5 + 0.5
                let o = (y * w + x) * 3
                dst[o] = UInt8(n.x * 255)
                dst[o + 1] = UInt8(n.y * 255)
                dst[o + 2] = UInt8(n.z * 255)
            }
        }
        super.init(
            data: dst,
            topLeftOrigin: true,
            name: name,
            dimensions: sourceTexture.dimensions,
            rowStride: w * 3,
            channelCount: 3,
            channelEncoding: .uInt8,
            isCube: false
        )
    }
}

public class MDLSkyCubeTexture: MDLTexture {
    public var turbidity: Float
    public var sunElevation: Float
    public var sunAzimuth: Float
    public var upperAtmosphereScattering: Float
    public var groundAlbedo: Float
    public var horizonElevation: Float = 0
    public var brightness: Float = 1
    public var contrast: Float = 1
    public var exposure: Float = 0
    public var gamma: Float = 1
    public var saturation: Float = 1
    public var highDynamicRangeCompression: SIMD2<Float> = SIMD2(1, 1)
#if canImport(CoreGraphics)
    public var groundColor: CGColor?
#endif

    public init(
        name: String?,
        channelEncoding: MDLTextureChannelEncoding,
        textureDimensions: SIMD2<Int32>,
        turbidity: Float,
        sunElevation: Float,
        sunAzimuth: Float,
        upperAtmosphereScattering: Float,
        groundAlbedo: Float
    ) {
        self.turbidity = turbidity
        self.sunElevation = sunElevation
        self.sunAzimuth = sunAzimuth
        self.upperAtmosphereScattering = upperAtmosphereScattering
        self.groundAlbedo = groundAlbedo
        let w = max(Int(textureDimensions.x), 1)
        let h = max(Int(textureDimensions.y), 1)
        super.init(
            data: Data(count: w * h * 4),
            topLeftOrigin: true,
            name: name,
            dimensions: textureDimensions,
            rowStride: w * 4,
            channelCount: 4,
            channelEncoding: channelEncoding,
            isCube: true
        )
        update()
    }

    public convenience init(
        name: String?,
        channelEncoding: MDLTextureChannelEncoding,
        textureDimensions: SIMD2<Int32>,
        turbidity: Float,
        sunElevation: Float,
        upperAtmosphereScattering: Float,
        groundAlbedo: Float
    ) {
        self.init(
            name: name,
            channelEncoding: channelEncoding,
            textureDimensions: textureDimensions,
            turbidity: turbidity,
            sunElevation: sunElevation,
            sunAzimuth: 0,
            upperAtmosphereScattering: upperAtmosphereScattering,
            groundAlbedo: groundAlbedo
        )
    }

    public func update() {
        let w = max(Int(dimensions.x), 1)
        let h = max(Int(dimensions.y), 1)
        var pixels = Data(count: w * h * 4)
        let sun = SIMD3(cos(sunAzimuth) * cos(sunElevation), sin(sunElevation), sin(sunAzimuth) * cos(sunElevation))
        for y in 0..<h {
            for x in 0..<w {
                let u = (Float(x) / Float(w) - 0.5) * 2
                let v = (Float(y) / Float(h) - 0.5) * 2
                let dir = simd_normalize(SIMD3(u, 1 - abs(v), v))
                let elev = max(dir.y, 0)
                let scatter = pow(1 - elev, 2) * upperAtmosphereScattering
                var rgb = SIMD3(
                    0.4 + scatter * 0.4,
                    0.55 + scatter * 0.2,
                    0.85 - scatter * 0.3
                )
                rgb *= (1.2 - turbidity * 0.1)
                let sunDot = max(simd_dot(dir, sun), 0)
                rgb += SIMD3(repeating: pow(sunDot, 32) * 2)
                rgb = simd_mix(rgb, SIMD3(repeating: groundAlbedo), SIMD3(repeating: max(-dir.y, 0)))
                rgb *= brightness
                let o = (y * w + x) * 4
                pixels[o] = UInt8(max(0, min(255, rgb.x * 255)))
                pixels[o + 1] = UInt8(max(0, min(255, rgb.y * 255)))
                pixels[o + 2] = UInt8(max(0, min(255, rgb.z * 255)))
                pixels[o + 3] = 255
            }
        }
        texels = pixels
        _ = (contrast, exposure, gamma, saturation, horizonElevation, highDynamicRangeCompression)
    }
}

func mdlBlackbody(_ kelvin: Float) -> SIMD3<Float> {
    let t = max(1000, min(kelvin, 15000)) / 100
    var r: Float = 1
    var g: Float
    var b: Float
    if t <= 66 {
        g = max(0, min(1, 0.39008157877 * log(t) - 0.63184144379))
    } else {
        r = max(0, min(1, 1.29293618606 * pow(t - 60, -0.1332047592)))
        g = max(0, min(1, 1.12989086089 * pow(t - 60, -0.0755148492)))
    }
    if t >= 66 {
        b = 1
    } else if t <= 19 {
        b = 0
    } else {
        b = max(0, min(1, 0.54320678911 * log(t - 10) - 1.19625408914))
    }
    return SIMD3(r, g, b)
}

func mdlGenerateNoise(dimensions: SIMD2<Int32>, smoothness: Float, channels: Int, grayscale: Bool) -> Data {
    let w = max(Int(dimensions.x), 1)
    let h = max(Int(dimensions.y), 1)
    var data = Data(count: w * h * channels)
    let scale = max(smoothness, 0.01)
    for y in 0..<h {
        for x in 0..<w {
            let n = mdlValueNoise(Float(x) / scale, Float(y) / scale)
            let o = (y * w + x) * channels
            if grayscale || channels == 1 {
                let v = UInt8(max(0, min(255, n * 255)))
                for c in 0..<channels { data[o + c] = v }
            } else {
                data[o] = UInt8(max(0, min(255, n * 255)))
                if channels > 1 {
                    data[o + 1] = UInt8(max(0, min(255, mdlValueNoise(Float(x + 19) / scale, Float(y) / scale) * 255)))
                }
                if channels > 2 {
                    data[o + 2] = UInt8(max(0, min(255, mdlValueNoise(Float(x) / scale, Float(y + 37) / scale) * 255)))
                }
                if channels > 3 { data[o + 3] = 255 }
            }
        }
    }
    return data
}

func mdlValueNoise(_ x: Float, _ y: Float) -> Float {
    let ix = floor(x), iy = floor(y)
    let fx = x - ix, fy = y - iy
    let a = mdlHash(ix, iy)
    let b = mdlHash(ix + 1, iy)
    let c = mdlHash(ix, iy + 1)
    let d = mdlHash(ix + 1, iy + 1)
    let ux = fx * fx * (3 - 2 * fx)
    let uy = fy * fy * (3 - 2 * fy)
    return (a * (1 - ux) + b * ux) * (1 - uy) + (c * (1 - ux) + d * ux) * uy
}

func mdlHash(_ x: Float, _ y: Float) -> Float {
    var n = sin(x * 127.1 + y * 311.7) * 43758.5453
    n = n - floor(n)
    return n
}

func mdlSampleGray(_ data: Data, w: Int, h: Int, x: Int, y: Int) -> Float {
    let xx = min(max(x, 0), w - 1)
    let yy = min(max(y, 0), h - 1)
    let stride = max(data.count / max(w * h, 1), 1)
    let idx = (yy * w + xx) * stride
    guard idx < data.count else { return 0 }
    return Float(data[idx]) / 255
}
