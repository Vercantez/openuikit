import CoreFoundation
import Foundation
import ColorSync

func csString(_ value: Unmanaged<CFString>!) -> String {
    unsafeBitCast(value.takeUnretainedValue(), to: NSString.self) as String
}

func csCFString(_ value: String) -> CFString {
    unsafeBitCast(value as NSString, to: CFString.self)
}

func csCFData(_ data: Data) -> CFData {
    unsafeBitCast(data as NSData, to: CFData.self)
}

func csData(_ data: CFData) -> Data {
    unsafeBitCast(data, to: NSData.self) as Data
}

func csCFURL(_ url: URL) -> CFURL {
    unsafeBitCast(url as NSURL, to: CFURL.self)
}

func csNSError(_ error: CFError) -> NSError {
    unsafeBitCast(error, to: NSError.self)
}

func csTakeProfile(_ value: Unmanaged<ColorSyncProfile>?) -> ColorSyncProfile? {
    value?.takeRetainedValue()
}

func csTakeMutable(_ value: Unmanaged<ColorSyncMutableProfile>?) -> ColorSyncMutableProfile? {
    value?.takeRetainedValue()
}

func csTakeTransform(_ value: Unmanaged<ColorSyncTransform>?) -> ColorSyncTransform? {
    value?.takeRetainedValue()
}

func csNamedProfile(_ name: Unmanaged<CFString>!) -> ColorSyncProfile {
    guard let profile = csTakeProfile(ColorSyncProfileCreateWithName(name.takeUnretainedValue())) else {
        fatalError("named profile missing: \(csString(name))")
    }
    return profile
}

func testColorSyncAlphaInfoRawValues() {
    precondition(kColorSyncAlphaNone.rawValue == 0)
    precondition(kColorSyncAlphaPremultipliedLast.rawValue == 1)
    precondition(kColorSyncAlphaPremultipliedFirst.rawValue == 2)
    precondition(kColorSyncAlphaLast.rawValue == 3)
    precondition(kColorSyncAlphaFirst.rawValue == 4)
    precondition(kColorSyncAlphaNoneSkipLast.rawValue == 5)
    precondition(kColorSyncAlphaNoneSkipFirst.rawValue == 6)
    precondition(ColorSyncAlphaInfo(rawValue: 0) == kColorSyncAlphaNone)
    precondition(ColorSyncAlphaInfo(3) == kColorSyncAlphaLast)
    precondition(kColorSyncAlphaNone != kColorSyncAlphaLast)
    var hasher = Hasher()
    kColorSyncAlphaNone.hash(into: &hasher)
    kColorSyncAlphaLast.hash(into: &hasher)
    _ = hasher.finalize()
}

func testColorSyncDataDepthRawValues() {
    precondition(kColorSync1BitGamut.rawValue == 1)
    precondition(kColorSync8BitInteger.rawValue == 2)
    precondition(kColorSync16BitInteger.rawValue == 3)
    precondition(kColorSync16BitFloat.rawValue == 4)
    precondition(kColorSync32BitInteger.rawValue == 5)
    precondition(kColorSync32BitNamedColorIndex.rawValue == 6)
    precondition(kColorSync32BitFloat.rawValue == 7)
    precondition(kColorSync10BitInteger.rawValue == 8)
    precondition(ColorSyncDataDepth(rawValue: 2) == kColorSync8BitInteger)
    precondition(ColorSyncDataDepth(8) == kColorSync10BitInteger)
    precondition(kColorSync8BitInteger != kColorSync16BitFloat)
    var hasher = Hasher()
    kColorSync8BitInteger.hash(into: &hasher)
    kColorSync32BitFloat.hash(into: &hasher)
    _ = hasher.finalize()
}

func testColorSyncByteOrderMasks() {
    precondition(kColorSyncAlphaInfoMask == 0x1F)
    precondition(kColorSyncByteOrderMask == 0x7000)
    precondition(kColorSyncByteOrderDefault == 0)
    precondition(kColorSyncByteOrder16Little == 1 << 12)
    precondition(kColorSyncByteOrder32Little == 2 << 12)
    precondition(kColorSyncByteOrder16Big == 3 << 12)
    precondition(kColorSyncByteOrder32Big == 4 << 12)
    let layout: ColorSyncDataLayout = UInt32(kColorSyncAlphaLast.rawValue) | UInt32(kColorSyncByteOrderDefault)
    precondition((Int(layout) & kColorSyncAlphaInfoMask) == Int(kColorSyncAlphaLast.rawValue))
}

func testColorSyncMD5Init() {
    let zero = ColorSyncMD5()
    precondition(zero.digest.0 == 0)
    precondition(zero.digest.15 == 0)
    var filled = ColorSyncMD5()
    filled.digest.0 = 0xAB
    filled.digest.15 = 0xCD
    let copied = ColorSyncMD5(digest: filled.digest)
    precondition(copied.digest.0 == 0xAB)
    precondition(copied.digest.15 == 0xCD)
}

func testColorSyncVersionMacros() {
    precondition(COLORSYNC_API_VERSION == 0x10000000)
    precondition(ColorSyncAPIVersion() == UInt32(COLORSYNC_API_VERSION))
    precondition(COLORSYNC_MD5_LENGTH == 16)
    precondition(icVersion4Number == 0x04000000)
    precondition(icVersion4Point4Number == 0x04400000)
}

func testColorSyncDataLayoutAlias() {
    let layout: ColorSyncDataLayout = 3
    precondition(layout == kColorSyncAlphaLast.rawValue)
}

func testColorSyncProfileHashable() {
    let a = csNamedProfile(kColorSyncSRGBProfile)
    let b = csNamedProfile(kColorSyncSRGBProfile)
    precondition(a == a)
    precondition(a != b)
    precondition(!(a != a))
    var hasher = Hasher()
    a.hash(into: &hasher)
    b.hash(into: &hasher)
    _ = hasher.finalize()
}

func testColorSyncTransformHashable() {
    let profile = csNamedProfile(kColorSyncSRGBProfile)
    let sequence = [profile] as NSArray
    let array = unsafeBitCast(sequence, to: CFArray.self)
    let first = csTakeTransform(ColorSyncTransformCreate(array, nil))!
    let second = csTakeTransform(ColorSyncTransformCreate(array, nil))!
    precondition(first == first)
    precondition(first != second)
    var hasher = Hasher()
    first.hash(into: &hasher)
    second.hash(into: &hasher)
    _ = hasher.finalize()
    _ = ColorSyncTransformGetTypeID()
}

func testColorSyncProfileTypeID() {
    precondition(ColorSyncProfileGetTypeID() != 0)
    precondition(ColorSyncProfileGetTypeID() != ColorSyncTransformGetTypeID())
}

func testColorSyncIterateCallbackType() {
    var seen = 0
    let callback: ColorSyncProfileIterateCallback = { info, _ in
        seen += 1
        return info != nil
    }
    ColorSyncIterateInstalledProfiles(callback, nil, nil, nil)
    precondition(seen >= 1)
}
