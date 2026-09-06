import CoreFoundation
import Foundation

public final class ColorSyncTransform: Hashable, @unchecked Sendable {
    let profiles: [ColorSyncProfile]
    var properties: [String: Any]
    let src: _CSMatrixSpace?
    let dst: _CSMatrixSpace?

    init(profiles: [ColorSyncProfile], properties: [String: Any]) {
        self.profiles = profiles
        self.properties = properties
        self.src = profiles.first.flatMap { _csMatrixSpace($0.storage) }
        self.dst = profiles.last.flatMap { _csMatrixSpace($0.storage) }
    }

    public static func == (left: ColorSyncTransform, right: ColorSyncTransform) -> Bool {
        left === right
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

public func ColorSyncTransformGetTypeID() -> CFTypeID {
    _csTransformTypeID
}

public func ColorSyncTransformCreate(
    _ profileSequence: CFArray?,
    _ options: CFDictionary?
) -> Unmanaged<ColorSyncTransform>? {
    var profiles: [ColorSyncProfile] = []
    if let profileSequence {
        for element in _csNSArray(profileSequence) {
            if let profile = element as? ColorSyncProfile {
                profiles.append(profile)
                continue
            }
            if let dictionary = element as? NSDictionary {
                let key = unsafeBitCast(kColorSyncProfile.takeUnretainedValue(), to: NSString.self)
                if let profile = dictionary.object(forKey: key) as? ColorSyncProfile {
                    profiles.append(profile)
                }
            }
        }
    }
    if profiles.isEmpty, let options {
        let dictionary = _csNSDictionary(options)
        let key = unsafeBitCast(kColorSyncProfile.takeUnretainedValue(), to: NSString.self)
        if let profile = dictionary.object(forKey: key) as? ColorSyncProfile {
            profiles.append(profile)
        }
    }
    guard !profiles.isEmpty else { return nil }
    var properties: [String: Any] = [:]
    if let options {
        properties["options"] = _csNSDictionary(options)
    }
    return Unmanaged.passRetained(ColorSyncTransform(profiles: profiles, properties: properties))
}

public func ColorSyncTransformGetProfileSequence(_ transform: ColorSyncTransform!) -> Unmanaged<CFArray>? {
    guard let transform else { return nil }
    return Unmanaged.passRetained(_csCFArray(transform.profiles as NSArray))
}

public func ColorSyncTransformCopyProperty(
    _ transform: ColorSyncTransform!,
    _ key: CFTypeRef!,
    _ options: CFDictionary?
) -> Unmanaged<CFTypeRef>? {
    _ = options
    guard let transform, let key else { return nil }
    let name = _csString(unsafeBitCast(key, to: CFString.self))
    if name == _csString(kColorSyncTransformProfileSequnce.takeUnretainedValue())
        || name == _csString(kColorSyncTransformInfo.takeUnretainedValue()) {
        return Unmanaged.passRetained(_csCFArray(transform.profiles as NSArray) as CFTypeRef)
    }
    if name == _csString(kColorSyncTransformSrcSpace.takeUnretainedValue()),
       let first = transform.profiles.first {
        return Unmanaged.passRetained(_csInternedString(_csColorSpace(first.storage)) as CFTypeRef)
    }
    if name == _csString(kColorSyncTransformDstSpace.takeUnretainedValue()),
       let last = transform.profiles.last {
        return Unmanaged.passRetained(_csInternedString(_csColorSpace(last.storage)) as CFTypeRef)
    }
    if name == _csString(kColorSyncTransformCreator.takeUnretainedValue()) {
        return Unmanaged.passRetained(_csInternedString("OpenUIKit.ColorSync") as CFTypeRef)
    }
    if name == _csString(kColorSyncTransformFullConversionData.takeUnretainedValue())
        || name == _csString(kColorSyncTransformSimplifiedConversionData.takeUnretainedValue())
        || name == _csString(kColorSyncTransformParametricConversionData.takeUnretainedValue())
        || name == _csString(kColorSyncTransformCodeFragmentType.takeUnretainedValue())
        || name == _csString(kColorSyncTransformCodeFragmentMD5.takeUnretainedValue()) {
        return nil
    }
    if let stored = transform.properties[name] {
        return Unmanaged.passRetained(stored as AnyObject)
    }
    return nil
}

public func ColorSyncTransformSetProperty(
    _ transform: ColorSyncTransform!,
    _ key: CFTypeRef!,
    _ property: CFTypeRef?
) {
    guard let transform, let key else { return }
    let name = _csString(unsafeBitCast(key, to: CFString.self))
    if let property {
        transform.properties[name] = property
    } else {
        transform.properties.removeValue(forKey: name)
    }
}

public func ColorSyncCreateCodeFragment(
    _ profileSequence: CFArray!,
    _ options: CFDictionary!
) -> Unmanaged<CFTypeRef>! {
    _ = profileSequence
    _ = options
    return nil
}

public func ColorSyncTransformConvert(
    _ transform: ColorSyncTransform!,
    _ width: Int,
    _ height: Int,
    _ dst: UnsafeMutableRawPointer!,
    _ dstDepth: ColorSyncDataDepth,
    _ dstLayout: ColorSyncDataLayout,
    _ dstBytesPerRow: Int,
    _ src: UnsafeRawPointer!,
    _ srcDepth: ColorSyncDataDepth,
    _ srcLayout: ColorSyncDataLayout,
    _ srcBytesPerRow: Int,
    _ options: CFDictionary?
) -> Bool {
    _ = options
    guard let transform, let dst, let src, width > 0, height > 0 else { return false }
    guard dstDepth == kColorSync8BitInteger, srcDepth == kColorSync8BitInteger else { return false }
    guard let srcSpace = transform.src, let dstSpace = transform.dst else { return false }
    let srcInfo = ColorSyncAlphaInfo(rawValue: srcLayout & UInt32(kColorSyncAlphaInfoMask))
    let dstInfo = ColorSyncAlphaInfo(rawValue: dstLayout & UInt32(kColorSyncAlphaInfoMask))
    guard let srcChannels = _csChannelCount(srcInfo),
          let dstChannels = _csChannelCount(dstInfo) else { return false }
    guard srcBytesPerRow >= width * srcChannels, dstBytesPerRow >= width * dstChannels else { return false }

    let srcPtr = src.assumingMemoryBound(to: UInt8.self)
    let dstPtr = dst.assumingMemoryBound(to: UInt8.self)
    for y in 0..<height {
        let srcRow = srcPtr + y * srcBytesPerRow
        let dstRow = dstPtr + y * dstBytesPerRow
        for x in 0..<width {
            let s = srcRow + x * srcChannels
            let (r, g, b, a) = _csUnpackPixel(s, srcInfo, srcChannels)
            let rgb = _csConvertRGB(r, g, b, from: srcSpace, to: dstSpace)
            _csPackPixel(dstRow + x * dstChannels, dstInfo, dstChannels, rgb.0, rgb.1, rgb.2, a)
        }
    }
    return true
}

func _csChannelCount(_ info: ColorSyncAlphaInfo) -> Int? {
    switch info {
    case kColorSyncAlphaNone:
        return 3
    case kColorSyncAlphaPremultipliedLast, kColorSyncAlphaLast, kColorSyncAlphaNoneSkipLast,
         kColorSyncAlphaPremultipliedFirst, kColorSyncAlphaFirst, kColorSyncAlphaNoneSkipFirst:
        return 4
    default:
        return nil
    }
}

func _csUnpackPixel(
    _ pointer: UnsafePointer<UInt8>,
    _ info: ColorSyncAlphaInfo,
    _ channels: Int
) -> (Double, Double, Double, Double) {
    func n(_ value: UInt8) -> Double { Double(value) / 255.0 }
    switch info {
    case kColorSyncAlphaNone:
        return (n(pointer[0]), n(pointer[1]), n(pointer[2]), 1)
    case kColorSyncAlphaLast, kColorSyncAlphaNoneSkipLast:
        return (n(pointer[0]), n(pointer[1]), n(pointer[2]), n(pointer[3]))
    case kColorSyncAlphaPremultipliedLast:
        let a = n(pointer[3])
        if a <= 0 { return (0, 0, 0, 0) }
        return (n(pointer[0]) / a, n(pointer[1]) / a, n(pointer[2]) / a, a)
    case kColorSyncAlphaFirst, kColorSyncAlphaNoneSkipFirst:
        return (n(pointer[1]), n(pointer[2]), n(pointer[3]), n(pointer[0]))
    case kColorSyncAlphaPremultipliedFirst:
        let a = n(pointer[0])
        if a <= 0 { return (0, 0, 0, 0) }
        return (n(pointer[1]) / a, n(pointer[2]) / a, n(pointer[3]) / a, a)
    default:
        if channels >= 3 {
            return (n(pointer[0]), n(pointer[1]), n(pointer[2]), 1)
        }
        return (0, 0, 0, 1)
    }
}

func _csPackPixel(
    _ pointer: UnsafeMutablePointer<UInt8>,
    _ info: ColorSyncAlphaInfo,
    _ channels: Int,
    _ r: Double,
    _ g: Double,
    _ b: Double,
    _ a: Double
) {
    func u(_ value: Double) -> UInt8 {
        UInt8(min(max(value, 0), 1) * 255.0 + 0.5)
    }
    switch info {
    case kColorSyncAlphaNone:
        pointer[0] = u(r)
        pointer[1] = u(g)
        pointer[2] = u(b)
    case kColorSyncAlphaLast, kColorSyncAlphaNoneSkipLast:
        pointer[0] = u(r)
        pointer[1] = u(g)
        pointer[2] = u(b)
        if channels > 3 { pointer[3] = u(a) }
    case kColorSyncAlphaPremultipliedLast:
        pointer[0] = u(r * a)
        pointer[1] = u(g * a)
        pointer[2] = u(b * a)
        pointer[3] = u(a)
    case kColorSyncAlphaFirst, kColorSyncAlphaNoneSkipFirst:
        pointer[0] = u(a)
        pointer[1] = u(r)
        pointer[2] = u(g)
        pointer[3] = u(b)
    case kColorSyncAlphaPremultipliedFirst:
        pointer[0] = u(a)
        pointer[1] = u(r * a)
        pointer[2] = u(g * a)
        pointer[3] = u(b * a)
    default:
        if channels >= 3 {
            pointer[0] = u(r)
            pointer[1] = u(g)
            pointer[2] = u(b)
        }
    }
}

func _csConvertRGB(
    _ r: Double,
    _ g: Double,
    _ b: Double,
    from src: _CSMatrixSpace,
    to dst: _CSMatrixSpace
) -> (Double, Double, Double) {
    let linear = _CSXYZ(
        x: _csApplyTRC(src.rTRC, r),
        y: _csApplyTRC(src.gTRC, g),
        z: _csApplyTRC(src.bTRC, b)
    )
    let xyz = _CSXYZ(
        x: src.r.x * linear.x + src.g.x * linear.y + src.b.x * linear.z,
        y: src.r.y * linear.x + src.g.y * linear.y + src.b.y * linear.z,
        z: src.r.z * linear.x + src.g.z * linear.y + src.b.z * linear.z
    )
    let matrix = [
        [dst.r.x, dst.g.x, dst.b.x],
        [dst.r.y, dst.g.y, dst.b.y],
        [dst.r.z, dst.g.z, dst.b.z]
    ]
    guard let inv = _csInvert3x3(matrix) else { return (r, g, b) }
    let device = _csMul3(inv, xyz)
    return (
        _csInvertTRC(dst.rTRC, device.x),
        _csInvertTRC(dst.gTRC, device.y),
        _csInvertTRC(dst.bTRC, device.z)
    )
}
