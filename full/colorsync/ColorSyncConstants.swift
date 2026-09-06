import CoreFoundation
import Foundation

// Named profile identifiers documented as `com.apple.ColorSync.*` in
// ColorSyncProfile.h comments. ICC four-character signatures are the ICC.1
// tag/class/space codes stored as CFString. CMM code-fragment keys use the
// `com.apple.cmm.*` payloads documented next to those declarations.

public var kColorSyncGenericGrayProfile: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.GenericGray") }
public var kColorSyncGenericGrayGamma22Profile: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.GenericGrayGamma2.2") }
public var kColorSyncGenericRGBProfile: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.GenericRGB") }
public var kColorSyncGenericCMYKProfile: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.GenericCMYK") }
public var kColorSyncDisplayP3Profile: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.DisplayP3") }
public var kColorSyncSRGBProfile: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.sRGB") }
public var kColorSyncAdobeRGB1998Profile: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.AdobeRGB1998") }
public var kColorSyncGenericLabProfile: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.GenericLab") }
public var kColorSyncGenericXYZProfile: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.GenericXYZ") }
public var kColorSyncACESCGLinearProfile: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.ACESCGLinear") }
public var kColorSyncDCIP3Profile: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.DCIP3") }
public var kColorSyncITUR709Profile: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.ITUR709") }
public var kColorSyncITUR2020Profile: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.ITUR2020") }
public var kColorSyncROMMRGBProfile: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.ROMMRGB") }
public var kColorSyncWebSafeColorsProfile: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.WebSafeColors") }

public var kColorSyncProfileHeader: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.ProfileHeader") }
public var kColorSyncProfileClass: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.ProfileClass") }
public var kColorSyncProfileColorSpace: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.ProfileColorSpace") }
public var kColorSyncProfilePCS: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.PCS") }
public var kColorSyncProfileURL: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.ProfileURL") }
public var kColorSyncProfileDescription: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.ProfileDescription") }
public var kColorSyncProfileMD5Digest: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.ProfileMD5Digest") }
public var kColorSyncProfileIsValid: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.ProfileIsValid") }
public var kColorSyncProfileCacheSeed: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.ProfileCacheSeed") }

public var kColorSyncSigAToB0Tag: Unmanaged<CFString>! { _csConstant("A2B0") }
public var kColorSyncSigAToB1Tag: Unmanaged<CFString>! { _csConstant("A2B1") }
public var kColorSyncSigAToB2Tag: Unmanaged<CFString>! { _csConstant("A2B2") }
public var kColorSyncSigBToA0Tag: Unmanaged<CFString>! { _csConstant("B2A0") }
public var kColorSyncSigBToA1Tag: Unmanaged<CFString>! { _csConstant("B2A1") }
public var kColorSyncSigBToA2Tag: Unmanaged<CFString>! { _csConstant("B2A2") }
public var kColorSyncSigCmykData: Unmanaged<CFString>! { _csConstant("CMYK") }
public var kColorSyncSigGrayData: Unmanaged<CFString>! { _csConstant("GRAY") }
public var kColorSyncSigLabData: Unmanaged<CFString>! { _csConstant("Lab ") }
public var kColorSyncSigRgbData: Unmanaged<CFString>! { _csConstant("RGB ") }
public var kColorSyncSigXYZData: Unmanaged<CFString>! { _csConstant("XYZ ") }
public var kColorSyncSigAbstractClass: Unmanaged<CFString>! { _csConstant("abst") }
public var kColorSyncSigBlueTRCTag: Unmanaged<CFString>! { _csConstant("bTRC") }
public var kColorSyncSigBlueColorantTag: Unmanaged<CFString>! { _csConstant("bXYZ") }
public var kColorSyncSigMediaBlackPointTag: Unmanaged<CFString>! { _csConstant("bkpt") }
public var kColorSyncSigCopyrightTag: Unmanaged<CFString>! { _csConstant("cprt") }
public var kColorSyncSigProfileDescriptionTag: Unmanaged<CFString>! { _csConstant("desc") }
public var kColorSyncSigDeviceModelDescTag: Unmanaged<CFString>! { _csConstant("dmdd") }
public var kColorSyncSigDeviceMfgDescTag: Unmanaged<CFString>! { _csConstant("dmnd") }
public var kColorSyncSigGreenTRCTag: Unmanaged<CFString>! { _csConstant("gTRC") }
public var kColorSyncSigGreenColorantTag: Unmanaged<CFString>! { _csConstant("gXYZ") }
public var kColorSyncSigGamutTag: Unmanaged<CFString>! { _csConstant("gamt") }
public var kColorSyncSigGrayTRCTag: Unmanaged<CFString>! { _csConstant("kTRC") }
public var kColorSyncSigLinkClass: Unmanaged<CFString>! { _csConstant("link") }
public var kColorSyncSigDisplayClass: Unmanaged<CFString>! { _csConstant("mntr") }
public var kColorSyncSigNamedColor2Tag: Unmanaged<CFString>! { _csConstant("ncl2") }
public var kColorSyncSigNamedColorClass: Unmanaged<CFString>! { _csConstant("nmcl") }
public var kColorSyncSigPreview0Tag: Unmanaged<CFString>! { _csConstant("pre0") }
public var kColorSyncSigPreview1Tag: Unmanaged<CFString>! { _csConstant("pre1") }
public var kColorSyncSigPreview2Tag: Unmanaged<CFString>! { _csConstant("pre2") }
public var kColorSyncSigOutputClass: Unmanaged<CFString>! { _csConstant("prtr") }
public var kColorSyncSigProfileSequenceDescTag: Unmanaged<CFString>! { _csConstant("pseq") }
public var kColorSyncSigRedTRCTag: Unmanaged<CFString>! { _csConstant("rTRC") }
public var kColorSyncSigRedColorantTag: Unmanaged<CFString>! { _csConstant("rXYZ") }
public var kColorSyncSigInputClass: Unmanaged<CFString>! { _csConstant("scnr") }
public var kColorSyncSigColorSpaceClass: Unmanaged<CFString>! { _csConstant("spac") }
public var kColorSyncSigTechnologyTag: Unmanaged<CFString>! { _csConstant("tech") }
public var kColorSyncSigViewingConditionsTag: Unmanaged<CFString>! { _csConstant("view") }
public var kColorSyncSigViewingCondDescTag: Unmanaged<CFString>! { _csConstant("vued") }
public var kColorSyncSigMediaWhitePointTag: Unmanaged<CFString>! { _csConstant("wtpt") }

public var kColorSyncProfile: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.Profile") }
public var kColorSyncRenderingIntent: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.RenderingIntent") }
public var kColorSyncRenderingIntentPerceptual: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.Perceptual") }
public var kColorSyncRenderingIntentRelative: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.RelativeColorimetric") }
public var kColorSyncRenderingIntentSaturation: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.Saturation") }
public var kColorSyncRenderingIntentAbsolute: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.AbsoluteColorimetric") }
public var kColorSyncRenderingIntentUseProfileHeader: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.UseProfileHeader") }
public var kColorSyncTransformTag: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.TransformTag") }
public var kColorSyncTransformDeviceToPCS: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.TransformDeviceToPCS") }
public var kColorSyncTransformPCSToPCS: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.TransformPCSToPCS") }
public var kColorSyncTransformPCSToDevice: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.TransformPCSToDevice") }
public var kColorSyncTransformDeviceToDevice: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.TransformDeviceToDevice") }
public var kColorSyncTransformGamutCheck: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.TransformGamutCheck") }
public var kColorSyncBlackPointCompensation: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.BlackPointCompensation") }
public var kColorSyncPreferredCMM: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.PreferredCMM") }
public var kColorSyncConvertQuality: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.ConvertQuality") }
public var kColorSyncBestQuality: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.BestQuality") }
public var kColorSyncNormalQuality: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.NormalQuality") }
public var kColorSyncDraftQuality: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.DraftQuality") }
public var kColorSyncConvertUseExtendedRange: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.ConvertUseExtendedRange") }
public var kColorSyncDoNotSubstituteProfiles: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.DoNotSubstituteProfiles") }
public var kColorSyncExtendedRange: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.ExtendedRange") }
public var kColorSyncHDRDerivative: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.HDRDerivative") }
public var kColorSyncPQDerivative: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.PQDerivative") }
public var kColorSyncHLGDerivative: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.HLGDerivative") }

public var kColorSyncTransformInfo: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.TransformInfo") }
public var kColorSyncTransformCreator: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.TransformCreator") }
public var kColorSyncTransformSrcSpace: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.TransformSrcSpace") }
public var kColorSyncTransformDstSpace: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.TransformDstSpace") }
public var kColorSyncTransformUseITU709OETF: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.TransformUseITU709OETF") }
public var kColorSyncTransformProfileSequnce: Unmanaged<CFString>! { _csConstant("com.apple.ColorSync.TransformProfileSequnce") }

public var kColorSyncTransformCodeFragmentType: Unmanaged<CFString>! { _csConstant("com.apple.cmm.CodeFragmentType") }
public var kColorSyncTransformCodeFragmentMD5: Unmanaged<CFString>! { _csConstant("com.apple.cmm.CodeFragmentMD5") }
public var kColorSyncTransformFullConversionData: Unmanaged<CFString>! { _csConstant("com.apple.cmm.FullConversion") }
public var kColorSyncTransformSimplifiedConversionData: Unmanaged<CFString>! { _csConstant("com.apple.cmm.SimplifiedConversion") }
public var kColorSyncTransformParametricConversionData: Unmanaged<CFString>! { _csConstant("com.apple.cmm.ParametricConversion") }
public var kColorSyncConversionMatrix: Unmanaged<CFString>! { _csConstant("com.apple.cmm.Matrix") }
public var kColorSyncConversionParamCurve0: Unmanaged<CFString>! { _csConstant("com.apple.cmm.ParamCurve0") }
public var kColorSyncConversionParamCurve1: Unmanaged<CFString>! { _csConstant("com.apple.cmm.ParamCurve1") }
public var kColorSyncConversionParamCurve2: Unmanaged<CFString>! { _csConstant("com.apple.cmm.ParamCurve2") }
public var kColorSyncConversionParamCurve3: Unmanaged<CFString>! { _csConstant("com.apple.cmm.ParamCurve3") }
public var kColorSyncConversionParamCurve4: Unmanaged<CFString>! { _csConstant("com.apple.cmm.ParamCurve4") }
public var kColorSyncConversion1DLut: Unmanaged<CFString>! { _csConstant("com.apple.cmm.1D-LUT") }
public var kColorSyncConversionGridPoints: Unmanaged<CFString>! { _csConstant("com.apple.cmm.GridPointCount") }
public var kColorSyncConversionChannelID: Unmanaged<CFString>! { _csConstant("com.apple.cmm.ChannelID") }
public var kColorSyncConversion3DLut: Unmanaged<CFString>! { _csConstant("com.apple.cmm.3D-LUT") }
public var kColorSyncConversionNDLut: Unmanaged<CFString>! { _csConstant("com.apple.cmm.ND-LUT") }
public var kColorSyncConversionInpChan: Unmanaged<CFString>! { _csConstant("com.apple.cmm.InputChannels") }
public var kColorSyncConversionOutChan: Unmanaged<CFString>! { _csConstant("com.apple.cmm.OutputChannels") }
public var kColorSyncConversionBPC: Unmanaged<CFString>! { _csConstant("com.apple.cmm.BPC") }
public var kColorSyncFixedPointRange: Unmanaged<CFString>! { _csConstant("com.apple.cmm.FixedPointRange") }
