import CoreFoundation
import Foundation
import ColorSync

func testColorSyncProfileCreateFromData() {
    let named = csNamedProfile(kColorSyncSRGBProfile)
    guard let copied = ColorSyncProfileCopyData(named, nil) else {
        fatalError("copy data")
    }
    let bytes = csData(copied.takeRetainedValue())
    var error: Unmanaged<CFError>?
    let created = csTakeProfile(ColorSyncProfileCreate(csCFData(bytes), &error))
    precondition(created != nil)
    precondition(error == nil)
    precondition(ColorSyncProfileIsMatrixBased(created!))
    precondition(ColorSyncProfileGetTagCount(created!) >= 6)
}

func testColorSyncProfileCreateInvalidData() {
    var error: Unmanaged<CFError>?
    let created = ColorSyncProfileCreate(csCFData(Data([0x00, 0x01, 0x02])), &error)
    precondition(created == nil)
    precondition(error != nil)
    let ns = csNSError(error!.takeRetainedValue())
    precondition(ns.domain == "com.apple.ColorSync.error")
    precondition(ns.code == 1)
}

func testColorSyncProfileCreateWithNameSRGB() {
    let profile = csNamedProfile(kColorSyncSRGBProfile)
    precondition(ColorSyncProfileIsMatrixBased(profile))
    precondition(ColorSyncProfileContainsTag(profile, kColorSyncSigRedColorantTag.takeUnretainedValue()))
    precondition(ColorSyncProfileContainsTag(profile, kColorSyncSigProfileDescriptionTag.takeUnretainedValue()))
    let description = ColorSyncProfileCopyDescriptionString(profile)?.takeRetainedValue()
    precondition(description != nil)
    let text = unsafeBitCast(description!, to: NSString.self) as String
    precondition(text == "com.apple.ColorSync.sRGB")
}

func testColorSyncProfileCreateUnknownName() {
    let created = ColorSyncProfileCreateWithName(csCFString("com.apple.ColorSync.DoesNotExist"))
    precondition(created == nil)
}

func testColorSyncProfileCreateWithURLRoundTrip() {
    let named = csNamedProfile(kColorSyncDisplayP3Profile)
    guard let copied = ColorSyncProfileCopyData(named, nil) else { fatalError("copy") }
    let bytes = csData(copied.takeRetainedValue())
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("colorsync-p3-\(UUID().uuidString).icc")
    try! bytes.write(to: url)
    defer { try? FileManager.default.removeItem(at: url) }
    var error: Unmanaged<CFError>?
    let created = csTakeProfile(ColorSyncProfileCreateWithURL(csCFURL(url), &error))
    precondition(created != nil)
    precondition(error == nil)
    let got = ColorSyncProfileGetURL(created!, nil)!.takeRetainedValue()
    let round = unsafeBitCast(got, to: NSURL.self) as URL
    precondition(round.path == url.path)
    precondition(ColorSyncProfileIsWideGamut(created!))
}

func testColorSyncProfileCreateWithURLAndOptionsMissing() {
    var error: Unmanaged<CFError>?
    let missing = URL(fileURLWithPath: "/tmp/colorsync-missing-\(UUID().uuidString).icc")
    let created = ColorSyncProfileCreateWithURLAndOptions(csCFURL(missing), nil, &error)
    precondition(created == nil)
    precondition(error != nil)
    _ = error!.takeRetainedValue()
}

func testColorSyncProfileCreateMutableAndTags() {
    let mutable = csTakeMutable(ColorSyncProfileCreateMutable())!
    precondition(ColorSyncProfileGetTagCount(mutable) == 0)
    ColorSyncProfileSetTag(
        mutable,
        kColorSyncSigCopyrightTag.takeUnretainedValue(),
        csCFData(Data("cprt".utf8))
    )
    precondition(ColorSyncProfileContainsTag(mutable, kColorSyncSigCopyrightTag.takeUnretainedValue()))
    precondition(ColorSyncProfileGetTagCount(mutable) == 1)
    let copied = ColorSyncProfileCopyTag(mutable, kColorSyncSigCopyrightTag.takeUnretainedValue())!
        .takeRetainedValue()
    precondition(csData(copied) == Data("cprt".utf8))
    ColorSyncProfileRemoveTag(mutable, kColorSyncSigCopyrightTag.takeUnretainedValue())
    precondition(!ColorSyncProfileContainsTag(mutable, kColorSyncSigCopyrightTag.takeUnretainedValue()))
    precondition(ColorSyncProfileGetTagCount(mutable) == 0)
}

func testColorSyncProfileCreateMutableCopy() {
    let source = csNamedProfile(kColorSyncGenericRGBProfile)
    let copy = csTakeMutable(ColorSyncProfileCreateMutableCopy(source))!
    precondition(ColorSyncProfileGetTagCount(copy) == ColorSyncProfileGetTagCount(source))
    ColorSyncProfileRemoveTag(copy, kColorSyncSigCopyrightTag.takeUnretainedValue())
    precondition(ColorSyncProfileContainsTag(source, kColorSyncSigCopyrightTag.takeUnretainedValue()))
}

func testColorSyncProfileCopyTagSignatures() {
    let profile = csNamedProfile(kColorSyncSRGBProfile)
    let signatures = ColorSyncProfileCopyTagSignatures(profile)!.takeRetainedValue()
    let array = unsafeBitCast(signatures, to: NSArray.self)
    precondition(array.count == ColorSyncProfileGetTagCount(profile))
    let strings = array.map { unsafeBitCast($0 as AnyObject, to: NSString.self) as String }
    precondition(strings.contains("desc"))
    precondition(strings.contains("rXYZ"))
}

func testColorSyncProfileCopyHeaderAndSetHeader() {
    let source = csNamedProfile(kColorSyncGenericGrayGamma22Profile)
    let header = ColorSyncProfileCopyHeader(source)!.takeRetainedValue()
    let host = csData(header)
    precondition(host.count == 128)
    let mutable = csTakeMutable(ColorSyncProfileCreateMutableCopy(source))!
    ColorSyncProfileSetHeader(mutable, header)
    let again = csData(ColorSyncProfileCopyHeader(mutable)!.takeRetainedValue())
    precondition(again.count == 128)
}

func testColorSyncProfileGetMD5Stable() {
    let a = csNamedProfile(kColorSyncSRGBProfile)
    let b = csNamedProfile(kColorSyncSRGBProfile)
    let md5a = ColorSyncProfileGetMD5(a)
    let md5b = ColorSyncProfileGetMD5(b)
    precondition(md5a.digest.0 == md5b.digest.0)
    precondition(md5a.digest.15 == md5b.digest.15)
    var nonzero = false
    let bytes = [
        md5a.digest.0, md5a.digest.1, md5a.digest.2, md5a.digest.3,
        md5a.digest.4, md5a.digest.5, md5a.digest.6, md5a.digest.7,
        md5a.digest.8, md5a.digest.9, md5a.digest.10, md5a.digest.11,
        md5a.digest.12, md5a.digest.13, md5a.digest.14, md5a.digest.15
    ]
    nonzero = bytes.contains { $0 != 0 }
    precondition(nonzero)
}

func testColorSyncProfileVerifyValid() {
    let profile = csNamedProfile(kColorSyncAdobeRGB1998Profile)
    var errors: Unmanaged<CFError>?
    var warnings: Unmanaged<CFError>?
    precondition(ColorSyncProfileVerify(profile, &errors, &warnings))
    if let errors { _ = errors.takeRetainedValue() }
    if let warnings { _ = warnings.takeRetainedValue() }
}

func testColorSyncProfileEstimateGammaGray() {
    let gray = csNamedProfile(kColorSyncGenericGrayGamma22Profile)
    var error: Unmanaged<CFError>?
    let gamma = ColorSyncProfileEstimateGamma(gray, &error)
    precondition(abs(gamma - 2.2) < 0.01)
    precondition(error == nil)
}

func testColorSyncProfileIsFlags() {
    let srgb = csNamedProfile(kColorSyncSRGBProfile)
    let p3 = csNamedProfile(kColorSyncDisplayP3Profile)
    let gray = csNamedProfile(kColorSyncGenericGrayProfile)
    precondition(ColorSyncProfileIsMatrixBased(srgb))
    precondition(!ColorSyncProfileIsMatrixBased(gray))
    precondition(ColorSyncProfileIsWideGamut(p3))
    precondition(!ColorSyncProfileIsWideGamut(srgb))
    precondition(!ColorSyncProfileIsPQBased(srgb))
    precondition(!ColorSyncProfileIsHLGBased(srgb))
}

func testColorSyncProfileCreateLinkMatrix() {
    let src = csNamedProfile(kColorSyncSRGBProfile)
    let dst = csNamedProfile(kColorSyncDisplayP3Profile)
    let sequence = [src, dst] as NSArray
    let link = csTakeProfile(ColorSyncProfileCreateLink(unsafeBitCast(sequence, to: CFArray.self), nil))
    precondition(link != nil)
}

func testColorSyncIterateInstalledProfilesSeed() {
    var seed: UInt32 = 0
    var count = 0
    ColorSyncIterateInstalledProfiles({ _, _ in
        count += 1
        return true
    }, &seed, nil, nil)
    precondition(count >= 10)
    precondition(seed != 0)
    var second: UInt32 = 0
    ColorSyncIterateInstalledProfiles(nil, &second, nil, nil)
    precondition(second != seed)
}
