import CoreFoundation
import Foundation
import ColorSync

func testColorSyncNamedProfilesExist() {
    let names: [Unmanaged<CFString>] = [
        kColorSyncSRGBProfile,
        kColorSyncDisplayP3Profile,
        kColorSyncAdobeRGB1998Profile,
        kColorSyncGenericRGBProfile,
        kColorSyncGenericGrayProfile,
        kColorSyncGenericGrayGamma22Profile,
        kColorSyncGenericLabProfile,
        kColorSyncGenericXYZProfile,
        kColorSyncGenericCMYKProfile,
        kColorSyncACESCGLinearProfile,
        kColorSyncDCIP3Profile,
        kColorSyncITUR709Profile,
        kColorSyncITUR2020Profile,
        kColorSyncROMMRGBProfile,
        kColorSyncWebSafeColorsProfile
    ]
    for name in names {
        let profile = csNamedProfile(name)
        precondition(ColorSyncProfileVerify(profile, nil, nil))
        precondition(ColorSyncProfileCopyData(profile, nil) != nil)
    }
}

func testColorSyncTransformCreateAndSequence() {
    let src = csNamedProfile(kColorSyncSRGBProfile)
    let dst = csNamedProfile(kColorSyncDisplayP3Profile)
    let sequence = [src, dst] as NSArray
    let transform = csTakeTransform(ColorSyncTransformCreate(unsafeBitCast(sequence, to: CFArray.self), nil))!
    let copied = ColorSyncTransformGetProfileSequence(transform)!.takeRetainedValue()
    let array = unsafeBitCast(copied, to: NSArray.self)
    precondition(array.count == 2)
}

func testColorSyncTransformConvertIdentity() {
    let profile = csNamedProfile(kColorSyncSRGBProfile)
    let sequence = [profile, profile] as NSArray
    let transform = csTakeTransform(ColorSyncTransformCreate(unsafeBitCast(sequence, to: CFArray.self), nil))!
    let src: [UInt8] = [255, 0, 0, 10, 20, 30, 0, 128, 255]
    var dst = [UInt8](repeating: 0, count: 9)
    let ok = src.withUnsafeBytes { srcBuf in
        dst.withUnsafeMutableBytes { dstBuf in
            ColorSyncTransformConvert(
                transform,
                3,
                1,
                dstBuf.baseAddress!,
                kColorSync8BitInteger,
                kColorSyncAlphaNone.rawValue,
                9,
                srcBuf.baseAddress!,
                kColorSync8BitInteger,
                kColorSyncAlphaNone.rawValue,
                9,
                nil
            )
        }
    }
    precondition(ok)
    precondition(abs(Int(dst[0]) - 255) <= 2)
    precondition(dst[1] <= 2)
    precondition(dst[2] <= 2)
}

func testColorSyncTransformConvertSRGBtoP3() {
    let srcProfile = csNamedProfile(kColorSyncSRGBProfile)
    let dstProfile = csNamedProfile(kColorSyncDisplayP3Profile)
    let sequence = [srcProfile, dstProfile] as NSArray
    let transform = csTakeTransform(ColorSyncTransformCreate(unsafeBitCast(sequence, to: CFArray.self), nil))!
    let src: [UInt8] = [255, 0, 0]
    var dst = [UInt8](repeating: 0, count: 3)
    let ok = src.withUnsafeBytes { srcBuf in
        dst.withUnsafeMutableBytes { dstBuf in
            ColorSyncTransformConvert(
                transform,
                1,
                1,
                dstBuf.baseAddress!,
                kColorSync8BitInteger,
                kColorSyncAlphaNone.rawValue,
                3,
                srcBuf.baseAddress!,
                kColorSync8BitInteger,
                kColorSyncAlphaNone.rawValue,
                3,
                nil
            )
        }
    }
    precondition(ok)
    precondition(dst[0] > 200)
    precondition(dst[0] <= 255)
}

func testColorSyncTransformConvertAlphaLayouts() {
    let profile = csNamedProfile(kColorSyncGenericRGBProfile)
    let sequence = [profile, profile] as NSArray
    let transform = csTakeTransform(ColorSyncTransformCreate(unsafeBitCast(sequence, to: CFArray.self), nil))!
    let src: [UInt8] = [10, 20, 30, 255]
    var dst = [UInt8](repeating: 0, count: 4)
    let ok = src.withUnsafeBytes { srcBuf in
        dst.withUnsafeMutableBytes { dstBuf in
            ColorSyncTransformConvert(
                transform,
                1,
                1,
                dstBuf.baseAddress!,
                kColorSync8BitInteger,
                kColorSyncAlphaLast.rawValue,
                4,
                srcBuf.baseAddress!,
                kColorSync8BitInteger,
                kColorSyncAlphaLast.rawValue,
                4,
                nil
            )
        }
    }
    precondition(ok)
    precondition(dst[3] == 255)
}

func testColorSyncTransformUnsupportedDepthFailClosed() {
    let profile = csNamedProfile(kColorSyncSRGBProfile)
    let sequence = [profile, profile] as NSArray
    let transform = csTakeTransform(ColorSyncTransformCreate(unsafeBitCast(sequence, to: CFArray.self), nil))!
    let src: [UInt8] = [0, 0, 0]
    var dst = [UInt8](repeating: 0, count: 3)
    let ok = src.withUnsafeBytes { srcBuf in
        dst.withUnsafeMutableBytes { dstBuf in
            ColorSyncTransformConvert(
                transform,
                1,
                1,
                dstBuf.baseAddress!,
                kColorSync16BitFloat,
                kColorSyncAlphaNone.rawValue,
                6,
                srcBuf.baseAddress!,
                kColorSync8BitInteger,
                kColorSyncAlphaNone.rawValue,
                3,
                nil
            )
        }
    }
    precondition(!ok)
}

func testColorSyncTransformCopyAndSetProperty() {
    let profile = csNamedProfile(kColorSyncITUR709Profile)
    let sequence = [profile] as NSArray
    let transform = csTakeTransform(ColorSyncTransformCreate(unsafeBitCast(sequence, to: CFArray.self), nil))!
    ColorSyncTransformSetProperty(
        transform,
        kColorSyncBestQuality.takeUnretainedValue(),
        kColorSyncDraftQuality.takeUnretainedValue()
    )
    let copied = ColorSyncTransformCopyProperty(
        transform,
        kColorSyncBestQuality.takeUnretainedValue(),
        nil
    )
    precondition(copied != nil)
    _ = copied!.takeRetainedValue()
    let srcSpace = ColorSyncTransformCopyProperty(
        transform,
        kColorSyncTransformSrcSpace.takeUnretainedValue(),
        nil
    )
    precondition(srcSpace != nil)
    _ = srcSpace!.takeRetainedValue()
}

func testColorSyncCreateCodeFragmentFailClosed() {
    let profile = csNamedProfile(kColorSyncSRGBProfile)
    let sequence = [profile] as NSArray
    let fragment = ColorSyncCreateCodeFragment(
        unsafeBitCast(sequence, to: CFArray.self),
        unsafeBitCast(NSDictionary(), to: CFDictionary.self)
    )
    precondition(fragment == nil)
    let transform = csTakeTransform(ColorSyncTransformCreate(unsafeBitCast(sequence, to: CFArray.self), nil))!
    precondition(
        ColorSyncTransformCopyProperty(
            transform,
            kColorSyncTransformFullConversionData.takeUnretainedValue(),
            nil
        ) == nil
    )
}

func testColorSyncTransformCreateNilSequence() {
    let created = ColorSyncTransformCreate(nil, nil)
    precondition(created == nil)
}
