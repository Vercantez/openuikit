import CoreFoundation
import Foundation

public class ColorSyncProfile: Hashable, @unchecked Sendable {
    let storage: _CSProfileStorage

    init(storage: _CSProfileStorage) {
        self.storage = storage
    }

    public static func == (left: ColorSyncProfile, right: ColorSyncProfile) -> Bool {
        left === right
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

public final class ColorSyncMutableProfile: ColorSyncProfile, @unchecked Sendable {
}

public func ColorSyncProfileGetTypeID() -> CFTypeID {
    _csProfileTypeID
}

public func ColorSyncProfileCreate(
    _ data: CFData!,
    _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?
) -> Unmanaged<ColorSyncProfile>? {
    guard let data else {
        _csWriteError(error, code: .invalidArgument, message: "nil profile data")
        return nil
    }
    guard let parsed = _csParseICC(_csData(data)) else {
        _csWriteError(error, code: .invalidData, message: "invalid ICC profile")
        return nil
    }
    return Unmanaged.passRetained(ColorSyncProfile(storage: parsed))
}

public func ColorSyncProfileCreateWithURL(
    _ url: CFURL!,
    _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?
) -> Unmanaged<ColorSyncProfile>? {
    ColorSyncProfileCreateWithURLAndOptions(url, nil, error)
}

public func ColorSyncProfileCreateWithURLAndOptions(
    _ url: CFURL!,
    _ options: CFDictionary?,
    _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?
) -> Unmanaged<ColorSyncProfile>? {
    _ = options
    guard let url else {
        _csWriteError(error, code: .invalidArgument, message: "nil profile URL")
        return nil
    }
    let fileURL = _csURL(url)
    guard let bytes = try? Data(contentsOf: fileURL) else {
        _csWriteError(error, code: .missingResource, message: "profile URL is unreadable")
        return nil
    }
    guard let parsed = _csParseICC(bytes) else {
        _csWriteError(error, code: .invalidData, message: "invalid ICC profile")
        return nil
    }
    parsed.url = fileURL
    return Unmanaged.passRetained(ColorSyncProfile(storage: parsed))
}

public func ColorSyncProfileCreateWithName(_ name: CFString!) -> Unmanaged<ColorSyncProfile>? {
    guard let name else { return nil }
    let key = _csString(name)
    guard let storage = _csNamedProfileStorage(key) else { return nil }
    return Unmanaged.passRetained(ColorSyncProfile(storage: storage))
}

public func ColorSyncProfileCreateMutable() -> Unmanaged<ColorSyncMutableProfile>? {
    let header = Data(count: 128)
    var bytes = header
    bytes[36] = 0x61 // a
    bytes[37] = 0x63 // c
    bytes[38] = 0x73 // s
    bytes[39] = 0x70 // p
    let storage = _CSProfileStorage(bytes: bytes, tags: [], url: nil, named: nil, mutable: true)
    storage.bytes = _csRebuildBytes(storage)
    return Unmanaged.passRetained(ColorSyncMutableProfile(storage: storage))
}

public func ColorSyncProfileCreateMutableCopy(_ prof: ColorSyncProfile!) -> Unmanaged<ColorSyncMutableProfile>? {
    guard let prof else { return nil }
    let copy = prof.storage.copy(mutable: true)
    return Unmanaged.passRetained(ColorSyncMutableProfile(storage: copy))
}

public func ColorSyncProfileCreateLink(
    _ profileInfo: CFArray!,
    _ options: CFDictionary?
) -> Unmanaged<ColorSyncProfile>? {
    _ = options
    guard let profileInfo else { return nil }
    let array = _csNSArray(profileInfo)
    var rgb: [ColorSyncProfile] = []
    for element in array {
        if let profile = element as? ColorSyncProfile {
            rgb.append(profile)
            continue
        }
        if let dictionary = element as? NSDictionary {
            let key = unsafeBitCast(kColorSyncProfile.takeUnretainedValue(), to: NSString.self)
            if let profile = dictionary.object(forKey: key) as? ColorSyncProfile {
                rgb.append(profile)
            }
        }
    }
    guard rgb.count >= 2,
          _csIsMatrixBased(rgb.first!.storage),
          _csIsMatrixBased(rgb.last!.storage) else {
        return nil
    }
    let copy = rgb.last!.storage.copy(mutable: false)
    copy.named = "DeviceLink"
    return Unmanaged.passRetained(ColorSyncProfile(storage: copy))
}

public func ColorSyncProfileContainsTag(_ prof: ColorSyncProfile!, _ signature: CFString!) -> Bool {
    guard let prof, let signature else { return false }
    return _csContainsTag(prof.storage, _csString(signature))
}

public func ColorSyncProfileCopyTag(
    _ prof: ColorSyncProfile!,
    _ signature: CFString!
) -> Unmanaged<CFData>? {
    guard let prof, let signature,
          let data = _csTag(prof.storage, _csString(signature)) else { return nil }
    return Unmanaged.passRetained(_csCFData(data))
}

public func ColorSyncProfileCopyTagSignatures(_ prof: ColorSyncProfile!) -> Unmanaged<CFArray>? {
    guard let prof else { return nil }
    let signatures = prof.storage.tags.map { _csInternedString($0.signature) as Any }
    return Unmanaged.passRetained(_csCFArray(signatures as NSArray))
}

public func ColorSyncProfileGetTagCount(_ prof: ColorSyncProfile!) -> Int {
    guard let prof else { return 0 }
    return prof.storage.tags.count
}

public func ColorSyncProfileCopyHeader(_ prof: ColorSyncProfile!) -> Unmanaged<CFData>! {
    guard let prof else { return nil }
    let header = _csHeaderHostEndian(prof.storage.bytes)
    return Unmanaged.passRetained(_csCFData(header))
}

public func ColorSyncProfileSetHeader(_ prof: ColorSyncMutableProfile!, _ header: CFData!) {
    guard let prof, let header, prof.storage.mutable else { return }
    guard let file = _csHeaderFileEndian(_csData(header)) else { return }
    var bytes = prof.storage.bytes
    if bytes.count < 128 {
        bytes.append(Data(count: 128 - bytes.count))
    }
    bytes.replaceSubrange(0..<128, with: file)
    prof.storage.bytes = bytes
    prof.storage.bytes = _csRebuildBytes(prof.storage)
}

public func ColorSyncProfileSetTag(
    _ prof: ColorSyncMutableProfile!,
    _ signature: CFString!,
    _ data: CFData!
) {
    guard let prof, let signature, let data, prof.storage.mutable else { return }
    let sig = _csString(signature)
    let payload = _csData(data)
    if let index = prof.storage.tags.firstIndex(where: { $0.signature == sig }) {
        prof.storage.tags[index] = _CSTag(signature: sig, data: payload)
    } else {
        prof.storage.tags.append(_CSTag(signature: sig, data: payload))
    }
    prof.storage.bytes = _csRebuildBytes(prof.storage)
}

public func ColorSyncProfileRemoveTag(_ prof: ColorSyncMutableProfile!, _ signature: CFString!) {
    guard let prof, let signature, prof.storage.mutable else { return }
    let sig = _csString(signature)
    prof.storage.tags.removeAll(where: { $0.signature == sig })
    prof.storage.bytes = _csRebuildBytes(prof.storage)
}

public func ColorSyncProfileCopyDescriptionString(_ prof: ColorSyncProfile!) -> Unmanaged<CFString>? {
    guard let prof, let description = _csDescription(prof.storage) else { return nil }
    return Unmanaged.passRetained(_csCFString(description))
}

public func ColorSyncProfileCopyData(
    _ prof: ColorSyncProfile!,
    _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?
) -> Unmanaged<CFData>! {
    guard let prof else {
        _csWriteError(error, code: .invalidArgument, message: "nil profile")
        return nil
    }
    return Unmanaged.passRetained(_csCFData(prof.storage.bytes))
}

public func ColorSyncProfileGetMD5(_ prof: ColorSyncProfile!) -> ColorSyncMD5 {
    guard let prof else { return ColorSyncMD5() }
    return _csMD5FromBytes(_csProfileID(prof.storage.bytes))
}

public func ColorSyncProfileGetURL(
    _ prof: ColorSyncProfile!,
    _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?
) -> Unmanaged<CFURL>! {
    guard let prof, let url = prof.storage.url else {
        _csWriteError(error, code: .missingResource, message: "profile has no URL")
        return nil
    }
    return Unmanaged.passRetained(_csCFURL(url))
}

public func ColorSyncProfileVerify(
    _ prof: ColorSyncProfile!,
    _ errors: UnsafeMutablePointer<Unmanaged<CFError>?>?,
    _ warnings: UnsafeMutablePointer<Unmanaged<CFError>?>?
) -> Bool {
    guard let prof else {
        _csWriteError(errors, code: .invalidArgument, message: "nil profile")
        return false
    }
    let result = _csVerify(prof.storage)
    if !result.errors.isEmpty {
        _csWriteError(errors, code: .invalidData, message: result.errors.joined(separator: "; "))
    }
    if !result.warnings.isEmpty {
        _csWriteError(warnings, code: .unsupported, message: result.warnings.joined(separator: "; "))
    }
    return result.ok
}

public func ColorSyncProfileEstimateGamma(
    _ prof: ColorSyncProfile!,
    _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?
) -> Float {
    guard let prof else {
        _csWriteError(error, code: .invalidArgument, message: "nil profile")
        return 0
    }
    if let gray = _csTag(prof.storage, "kTRC"), let trc = _csParseTRC(gray), let gamma = _csEstimateGamma(trc) {
        return gamma
    }
    if let red = _csTag(prof.storage, "rTRC"), let trc = _csParseTRC(red), let gamma = _csEstimateGamma(trc) {
        return gamma
    }
    _csWriteError(error, code: .unsupported, message: "gamma cannot be estimated")
    return 0
}

public func ColorSyncProfileIsMatrixBased(_ prof: ColorSyncProfile!) -> Bool {
    guard let prof else { return false }
    return _csIsMatrixBased(prof.storage)
}

public func ColorSyncProfileIsWideGamut(_ prof: ColorSyncProfile!) -> Bool {
    guard let prof else { return false }
    return _csIsWideGamut(prof.storage)
}

public func ColorSyncProfileIsPQBased(_ prof: ColorSyncProfile!) -> Bool {
    guard let prof else { return false }
    return _csIsPQBased(prof.storage)
}

public func ColorSyncProfileIsHLGBased(_ prof: ColorSyncProfile!) -> Bool {
    guard let prof else { return false }
    return _csIsHLGBased(prof.storage)
}

private let _csIterateLock = NSLock()
private var _csIterateSeed: UInt32 = 1

public func ColorSyncIterateInstalledProfiles(
    _ callBack: ColorSyncProfileIterateCallback?,
    _ seed: UnsafeMutablePointer<UInt32>?,
    _ userInfo: UnsafeMutableRawPointer?,
    _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?
) {
    _ = error
    _csIterateLock.lock()
    _csIterateSeed &+= 1
    let current = _csIterateSeed
    _csIterateLock.unlock()
    if let seed {
        seed.pointee = current
    }
    guard let callBack else { return }
    for key in _csAllNamedProfileKeys() {
        guard let storage = _csNamedProfileStorage(key) else { continue }
        let info = NSMutableDictionary()
        info.setObject(
            ColorSyncProfile(storage: storage),
            forKey: unsafeBitCast(kColorSyncProfile.takeUnretainedValue(), to: NSString.self)
        )
        info.setObject(
            unsafeBitCast(_csInternedString(key), to: NSString.self),
            forKey: unsafeBitCast(kColorSyncProfileDescription.takeUnretainedValue(), to: NSString.self)
        )
        info.setObject(
            unsafeBitCast(_csInternedString(_csProfileClass(storage)), to: NSString.self),
            forKey: unsafeBitCast(kColorSyncProfileClass.takeUnretainedValue(), to: NSString.self)
        )
        info.setObject(
            unsafeBitCast(_csInternedString(_csColorSpace(storage)), to: NSString.self),
            forKey: unsafeBitCast(kColorSyncProfileColorSpace.takeUnretainedValue(), to: NSString.self)
        )
        info.setObject(
            NSNumber(value: true),
            forKey: unsafeBitCast(kColorSyncProfileIsValid.takeUnretainedValue(), to: NSString.self)
        )
        if !callBack(_csCFDictionary(info), userInfo) {
            break
        }
    }
}
