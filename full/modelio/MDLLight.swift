import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

open class MDLLight: MDLObject {
    public var lightType: MDLLightType = .unknown
    public var colorSpace: String = "sRGB"

#if canImport(CoreGraphics)
    public func irradiance(atPoint point: SIMD3<Float>) -> Unmanaged<CGColor> {
        irradiance(atPoint: point, colorSpace: CGColorSpaceCreateDeviceRGB())
    }

    public func irradiance(atPoint point: SIMD3<Float>, colorSpace: CGColorSpace) -> Unmanaged<CGColor> {
        _ = point
        let color = CGColor(colorSpace: colorSpace, components: [1, 1, 1, 1]) ?? CGColor(gray: 1, alpha: 1)
        return Unmanaged.passRetained(color)
    }
#endif
}

open class MDLPhysicallyPlausibleLight: MDLLight {
    public var lumens: Float = 1000
    public var innerConeAngle: Float = 0
    public var outerConeAngle: Float = 45
    public var attenuationStartDistance: Float = 0
    public var attenuationEndDistance: Float = 10
#if canImport(CoreGraphics)
    public var color: CGColor?
#endif
    var linuxColor = SIMD3<Float>(1, 1, 1)

    public override init() {
        super.init()
        lightType = .point
    }

    public func setColorByTemperature(_ temperature: Float) {
        linuxColor = mdlBlackbody(temperature)
#if canImport(CoreGraphics)
        color = CGColor(red: CGFloat(linuxColor.x), green: CGFloat(linuxColor.y), blue: CGFloat(linuxColor.z), alpha: 1)
#endif
    }
}

public class MDLAreaLight: MDLPhysicallyPlausibleLight {
    public var areaRadius: Float = 0
    public var superEllipticPower: SIMD2<Float> = SIMD2(2, 2)
    public var aspect: Float = 1

    public override init() {
        super.init()
        lightType = .discArea
    }
}

public class MDLPhotometricLight: MDLPhysicallyPlausibleLight {
    public private(set) var lightCubeMap: MDLTexture?
    public private(set) var sphericalHarmonicsLevel: UInt = 0
    public private(set) var sphericalHarmonicsCoefficients: Data?

    public init?(iesProfile URL: URL) {
        super.init()
        lightType = .photometric
        if (try? Data(contentsOf: URL)) == nil {
            return nil
        }
    }

    public convenience init?(IESProfile URL: URL) {
        self.init(iesProfile: URL)
    }

    public func generateSphericalHarmonics(fromLight sphericalHarmonicsLevel: UInt) {
        self.sphericalHarmonicsLevel = sphericalHarmonicsLevel
        let count = Int((sphericalHarmonicsLevel + 1) * (sphericalHarmonicsLevel + 1) * 3) * 4
        sphericalHarmonicsCoefficients = Data(count: max(count, 12))
    }

    public func generateCubemap(fromLight textureSize: UInt) {
        let size = max(Int(textureSize), 1)
        lightCubeMap = MDLTexture(
            data: Data(count: size * size * 4),
            topLeftOrigin: true,
            name: "ies-cube",
            dimensions: SIMD2(Int32(size), Int32(size)),
            rowStride: size * 4,
            channelCount: 4,
            channelEncoding: .uInt8,
            isCube: true
        )
    }

    public func generateTexture(_ textureSize: UInt) -> MDLTexture {
        let size = max(Int(textureSize), 1)
        return MDLTexture(
            data: Data(count: size * size * 4),
            topLeftOrigin: true,
            name: "ies",
            dimensions: SIMD2(Int32(size), Int32(size)),
            rowStride: size * 4,
            channelCount: 4,
            channelEncoding: .uInt8,
            isCube: false
        )
    }
}

public class MDLLightProbe: MDLLight {
    public private(set) var reflectiveTexture: MDLTexture?
    public private(set) var irradianceTexture: MDLTexture?
    public private(set) var sphericalHarmonicsLevel: UInt = 0
    public private(set) var sphericalHarmonicsCoefficients: Data?

    public init(reflectiveTexture: MDLTexture?, irradianceTexture: MDLTexture?) {
        self.reflectiveTexture = reflectiveTexture
        self.irradianceTexture = irradianceTexture
        super.init()
        lightType = .probe
    }

    public init?(
        textureSize: Int,
        forLocation transform: MDLTransform,
        lightsToConsider: [MDLLight],
        objectsToConsider: [MDLObject],
        reflectiveCubemap: MDLTexture?,
        irradianceCubemap: MDLTexture?
    ) {
        _ = (lightsToConsider, objectsToConsider)
        let size = max(textureSize, 1)
        self.reflectiveTexture = reflectiveCubemap ?? MDLTexture(
            data: Data(count: size * size * 4),
            topLeftOrigin: true,
            name: "probe-ref",
            dimensions: SIMD2(Int32(size), Int32(size)),
            rowStride: size * 4,
            channelCount: 4,
            channelEncoding: .uInt8,
            isCube: true
        )
        self.irradianceTexture = irradianceCubemap ?? MDLTexture(
            data: Data(count: size * size * 4),
            topLeftOrigin: true,
            name: "probe-irr",
            dimensions: SIMD2(Int32(size), Int32(size)),
            rowStride: size * 4,
            channelCount: 4,
            channelEncoding: .uInt8,
            isCube: true
        )
        super.init()
        lightType = .probe
        self.transform = transform
    }

    public func generateSphericalHarmonics(fromIrradiance sphericalHarmonicsLevel: UInt) {
        self.sphericalHarmonicsLevel = sphericalHarmonicsLevel
        let bands = Int(sphericalHarmonicsLevel) + 1
        sphericalHarmonicsCoefficients = Data(count: bands * bands * 12)
    }
}
