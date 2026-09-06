import Foundation

open class MDLCamera: MDLObject {
    public var projection: MDLCameraProjection = .perspective
    public var nearVisibilityDistance: Float = 0.1
    public var farVisibilityDistance: Float = 1000
    public var fieldOfView: Float = 54
    public var focalLength: Float = 50
    public var focusDistance: Float = 2.5
    public var fStop: Float = 5.6
    public var apertureBladeCount: UInt = 0
    public var maximumCircleOfConfusion: Float = 0.05
    public var shutterOpenInterval: TimeInterval = 0
    public var barrelDistortion: Float = 0
    public var opticalVignetting: Float = 0
    public var chromaticAberration: Float = 0
    public var fisheyeDistortion: Float = 0
    public var worldToMetersConversionScale: Float = 1
    public var sensorVerticalAperture: Float = 24
    public var sensorAspect: Float = 1.5
    public var sensorEnlargement: SIMD2<Float> = SIMD2(1, 1)
    public var sensorShift: SIMD2<Float> = SIMD2()
    public var flash: SIMD3<Float> = SIMD3()
    public var exposure: SIMD3<Float> = SIMD3(1, 1, 1)
    public var exposureCompression: SIMD2<Float> = SIMD2(1, 0)

    public var projectionMatrix: matrix_float4x4 {
        let aspect = max(sensorAspect, 0.01)
        if projection == .orthographic {
            let h = max(sensorVerticalAperture, 0.01) * 0.5
            let w = h * aspect
            return mdlOrtho(left: -w, right: w, bottom: -h, top: h, near: nearVisibilityDistance, far: farVisibilityDistance)
        }
        let fov = fieldOfView * Float.pi / 180
        return mdlPerspective(
            fovYRadians: fov,
            aspect: aspect,
            near: nearVisibilityDistance,
            far: farVisibilityDistance
        )
    }

    public func look(at focusPosition: SIMD3<Float>) {
        let from: SIMD3<Float>
        if let model = transform as? MDLTransform {
            from = model.translation
        } else if let transform {
            let m = transform.matrix
            from = SIMD3(m.columns.3.x, m.columns.3.y, m.columns.3.z)
        } else {
            from = SIMD3(0, 0, 1)
        }
        look(at: focusPosition, from: from)
    }

    public func look(at focusPosition: SIMD3<Float>, from cameraPosition: SIMD3<Float>) {
        let model: MDLTransform
        if let existing = transform as? MDLTransform {
            model = existing
        } else {
            model = MDLTransform()
        }
        model.setTranslation(cameraPosition, forTime: 0)
        let matrix = mdlLookAt(eye: cameraPosition, target: focusPosition, up: SIMD3(0, 1, 0))
        model.setLocalTransform(matrix, forTime: 0)
        transform = model
    }

    public func frameBoundingBox(_ boundingBox: MDLAxisAlignedBoundingBox, setNearAndFar: Bool) {
        let center = (boundingBox.maxBounds + boundingBox.minBounds) * 0.5
        let radius = simd_length(boundingBox.maxBounds - boundingBox.minBounds) * 0.5
        let distance = max(radius / max(tan(fieldOfView * Float.pi / 360), 0.01), 0.1)
        look(at: center, from: center + SIMD3(0, 0, distance))
        if setNearAndFar {
            nearVisibilityDistance = max(distance - radius, 0.01)
            farVisibilityDistance = distance + radius
        }
    }

    public func ray(to pixel: SIMD2<Int32>, forViewPort size: SIMD2<Int32>) -> SIMD3<Float> {
        let x = (2 * (Float(pixel.x) + 0.5) / max(Float(size.x), 1)) - 1
        let y = 1 - (2 * (Float(pixel.y) + 0.5) / max(Float(size.y), 1))
        let fov = fieldOfView * Float.pi / 180
        let tanFov = tan(fov / 2)
        let aspect = max(Float(size.x), 1) / max(Float(size.y), 1)
        return simd_normalize(SIMD3(x * tanFov * aspect, y * tanFov, -1))
    }

    public func bokehKernel(withSize size: SIMD2<Int32>) -> MDLTexture {
        let w = max(Int(size.x), 1)
        let h = max(Int(size.y), 1)
        var pixels = Data(count: w * h)
        let blades = max(Int(apertureBladeCount), 0)
        let cx = Float(w) / 2, cy = Float(h) / 2
        let radius = min(cx, cy)
        for y in 0..<h {
            for x in 0..<w {
                let dx = Float(x) + 0.5 - cx
                let dy = Float(y) + 0.5 - cy
                let inside: Bool
                if blades >= 3 {
                    let angle = atan2(dy, dx)
                    let sector = Float.pi * 2 / Float(blades)
                    let local = abs((angle + Float.pi) .truncatingRemainder(dividingBy: sector) - sector / 2)
                    let r = radius * cos(Float.pi / Float(blades)) / max(cos(local), 0.01)
                    inside = hypot(dx, dy) <= r
                } else {
                    inside = hypot(dx, dy) <= radius
                }
                pixels[y * w + x] = inside ? 255 : 0
            }
        }
        return MDLTexture(
            data: pixels,
            topLeftOrigin: true,
            name: "bokeh",
            dimensions: size,
            rowStride: w,
            channelCount: 1,
            channelEncoding: .uInt8,
            isCube: false
        )
    }
}

public class MDLStereoscopicCamera: MDLCamera {
    public var interPupillaryDistance: Float = 63
    public var overlap: Float = 0
    public var leftVergence: Float = 0
    public var rightVergence: Float = 0

    public var leftViewMatrix: matrix_float4x4 {
        mdlMul(mdlTranslationMatrix(SIMD3(interPupillaryDistance * 0.0005, 0, 0)), transform?.matrix ?? .identity)
    }

    public var rightViewMatrix: matrix_float4x4 {
        mdlMul(mdlTranslationMatrix(SIMD3(-interPupillaryDistance * 0.0005, 0, 0)), transform?.matrix ?? .identity)
    }

    public var leftProjectionMatrix: matrix_float4x4 {
        var matrix = projectionMatrix
        matrix.columns.2.x += leftVergence + overlap
        return matrix
    }

    public var rightProjectionMatrix: matrix_float4x4 {
        var matrix = projectionMatrix
        matrix.columns.2.x += rightVergence - overlap
        return matrix
    }
}
