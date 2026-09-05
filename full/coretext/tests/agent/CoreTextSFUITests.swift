import CoreFoundation
import Foundation
import CoreText

#if canImport(CoreGraphics)
import CoreGraphics
#endif

func ctMakeRectPath(_ rect: CGRect) -> CGPath {
    CGPath(rect: rect, transform: nil)
}

func ctMakeContext() -> CGContext {
#if canImport(CoreGraphics)
    let space = CGColorSpaceCreateDeviceRGB()
    return CGContext(
        data: nil,
        width: 8,
        height: 8,
        bitsPerComponent: 8,
        bytesPerRow: 32,
        space: space,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
#else
    return CGContext()
#endif
}

func testSFUISystemFontMetricsAndHelloWidth() {
    // font_metrics_ios.json system-regular-17.0, harvested Tools/oracle2/fontprobe
    // iOS 26.1. Hello advances 12.185546875 + 9.2802734375 + 3.8681640625 * 2
    // + 9.6123046875 = 38.814453125, matching FontEngine.measure / UILabel
    // on the iOS cut (macOS table 40.35009765625 minus 5 * 37 * 17 / 2048).
    let font = CTFontCreateUIFontForLanguage(.system, 17, nil)
    precondition(font != nil)
    let sf = font!
    precondition(CTFontGetSize(sf) == 17)
    precondition(CTFontGetUnitsPerEm(sf) == 2048)
    precondition(abs(CTFontGetAscent(sf) - 16.1865234375) < 1e-9)
    precondition(abs(CTFontGetDescent(sf) - 4.1005859375) < 1e-9)
    precondition(CTFontGetLeading(sf) == 0)
    precondition(abs(CTFontGetCapHeight(sf) - 11.97802734375) < 1e-9)
    precondition(abs(CTFontGetXHeight(sf) - 8.9482421875) < 1e-9)
    precondition(ctString(CTFontCopyPostScriptName(sf)) == ".SFUI-Regular")
    precondition(ctString(CTFontCopyFamilyName(sf)) == ".AppleSystemUIFont")
    precondition(ctString(CTFontCopyFullName(sf)) == "System Font Regular")

    let named = CTFontCreateWithName(ctCFString(".SFUI-Regular"), 17, nil)
    precondition(abs(CTFontGetAscent(named) - CTFontGetAscent(sf)) < 1e-9)
    let identity = CGAffineTransform.identity
    let withMatrix = withUnsafePointer(to: identity) { pointer in
        CTFontCreateWithNameAndOptions(ctCFString(".AppleSystemUIFont"), 17, pointer, [])
    }
    precondition(CTFontGetMatrix(withMatrix).a == 1)
    precondition(CTFontGetMatrix(withMatrix).d == 1)

    let attributes: [NSAttributedString.Key: Any] = [
        NSAttributedString.Key(ctString(kCTFontAttributeName)): sf
    ]
    let hello = NSAttributedString(string: "Hello", attributes: attributes)
    let line = CTLineCreateWithAttributedString(hello)
    var ascent: CGFloat = 0
    var descent: CGFloat = 0
    var leading: CGFloat = 0
    let width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading)
    precondition(abs(width - 38.814453125) < 1e-9)
    precondition(abs(ascent - 16.1865234375) < 1e-9)
    precondition(abs(descent - 4.1005859375) < 1e-9)
    precondition(CTLineGetGlyphCount(line) == 5)

    let chars: [UniChar] = Array("Hello".utf16)
    var glyphs = [CGGlyph](repeating: 0, count: 5)
    let mapped = chars.withUnsafeBufferPointer { cbuf in
        glyphs.withUnsafeMutableBufferPointer { gbuf in
            CTFontGetGlyphsForCharacters(sf, cbuf.baseAddress!, gbuf.baseAddress!, 5)
        }
    }
    precondition(mapped)
    precondition(glyphs[0] == 72)
    precondition(glyphs[1] == 101)
    var advances = [CGSize](repeating: .zero, count: 5)
    let total = glyphs.withUnsafeBufferPointer { gbuf in
        advances.withUnsafeMutableBufferPointer { abuf in
            CTFontGetAdvancesForGlyphs(sf, .horizontal, gbuf.baseAddress!, abuf.baseAddress, 5)
        }
    }
    precondition(abs(total - 38.814453125) < 1e-9)
    precondition(abs(advances[0].width - 12.185546875) < 1e-9)
    precondition(abs(advances[4].width - 9.6123046875) < 1e-9)

    var rects = [CGRect](repeating: .zero, count: 5)
    let union = glyphs.withUnsafeBufferPointer { gbuf in
        rects.withUnsafeMutableBufferPointer { rbuf in
            CTFontGetBoundingRectsForGlyphs(sf, .default, gbuf.baseAddress!, rbuf.baseAddress, 5)
        }
    }
    precondition(union.width > 0)
    let optical = glyphs.withUnsafeBufferPointer { gbuf in
        CTFontGetOpticalBoundsForGlyphs(sf, gbuf.baseAddress!, nil, 5, 0)
    }
    precondition(optical.width > 0)

    let copy = CTFontCreateCopyWithSymbolicTraits(sf, 0, nil, .boldTrait, .boldTrait)
    precondition(copy != nil)
    precondition(CTFontGetSymbolicTraits(copy!).contains(.boldTrait))
    precondition(ctString(CTFontCopyPostScriptName(copy!)) == ".SFUI-Bold")
    let traits = unsafeBitCast(CTFontCopyTraits(copy!), to: NSDictionary.self)
    let weight = traits[ctString(kCTFontWeightTrait)] as? NSNumber
    precondition(weight != nil)
    precondition(abs(weight!.doubleValue - 0.4) < 1e-5)

    let sized = CTFontCreateCopyWithAttributes(sf, 13, nil, nil)
    precondition(CTFontGetSize(sized) == 13)
    let family = CTFontCreateCopyWithFamily(sf, 17, nil, ctCFString(".AppleSystemUIFont"))
    precondition(family != nil)

    let defaultSystem = CTFontCreateUIFontForLanguage(.system, 0, nil)!
    precondition(CTFontGetSize(defaultSystem) == 13)
    let small = CTFontCreateUIFontForLanguage(.smallSystem, 0, nil)!
    precondition(CTFontGetSize(small) == 11)
    let mini = CTFontCreateUIFontForLanguage(.miniSystem, 0, nil)!
    precondition(CTFontGetSize(mini) == 9)
    let label = CTFontCreateUIFontForLanguage(.label, 0, nil)!
    precondition(CTFontGetSize(label) == 10)
}

func testFramesetterFrameDrawAndRunGlyphs() {
    let font = CTFontCreateUIFontForLanguage(.system, 17, nil)!
    let attributes: [NSAttributedString.Key: Any] = [
        NSAttributedString.Key(ctString(kCTFontAttributeName)): font
    ]
    let string = NSAttributedString(string: "Hello world", attributes: attributes)
    let framesetter = CTFramesetterCreateWithAttributedString(string)
    _ = CTFramesetterCreateWithTypesetter(CTFramesetterGetTypesetter(framesetter))
    let path = ctMakeRectPath(CGRect(x: 0, y: 0, width: 200, height: 100))
    let frame = CTFramesetterCreateFrame(
        framesetter,
        CFRange(location: 0, length: string.length),
        path,
        nil
    )
    precondition(CTFrameGetPath(frame).boundingBoxOfPath.width == 200)
    let lines = ctNSArray(CTFrameGetLines(frame))
    precondition(lines.count >= 1)
    let visible = CTFrameGetVisibleStringRange(frame)
    precondition(visible.length > 0)
    _ = CTFrameGetStringRange(frame)
    _ = CTFrameGetFrameAttributes(frame)
    var origins = [CGPoint](repeating: .zero, count: lines.count)
    origins.withUnsafeMutableBufferPointer { buf in
        CTFrameGetLineOrigins(frame, CFRange(location: 0, length: 0), buf.baseAddress!)
    }
    precondition(origins[0].y != 0 || lines.count == 1)

    let ctx = ctMakeContext()
    CTFrameDraw(frame, ctx)
    let first = lines[0] as! CTLine
    CTLineDraw(first, ctx)
    _ = CTLineGetImageBounds(first, ctx)
    _ = CTLineGetBoundsWithOptions(first, [.excludeTypographicLeading])
    _ = CTLineGetPenOffsetForFlush(first, 0.5, 200)

    let runs = ctNSArray(CTLineGetGlyphRuns(first))
    let run = runs[0] as! CTRun
    var glyphs = [CGGlyph](repeating: 0, count: CTRunGetGlyphCount(run))
    glyphs.withUnsafeMutableBufferPointer { buf in
        CTRunGetGlyphs(run, CFRange(location: 0, length: 0), buf.baseAddress!)
    }
    precondition(glyphs[0] == 72)
    precondition(CTRunGetGlyphsPtr(run) == nil)
    _ = CTRunGetTextMatrix(run)
    _ = CTRunGetImageBounds(run, ctx, CFRange(location: 0, length: 0))
    CTRunDraw(run, ctx, CFRange(location: 0, length: 0))
    _ = CTRunGetStringRange(run)
    _ = CTRunGetAttributes(run)
    var ascent: CGFloat = 0
    _ = CTRunGetTypographicBounds(run, CFRange(location: 0, length: 0), &ascent, nil, nil)
    var baseAdv = [CGSize](repeating: .zero, count: 1)
    var baseOri = [CGPoint](repeating: .zero, count: 1)
    CTRunGetBaseAdvancesAndOrigins(
        run,
        CFRange(location: 0, length: 1),
        &baseAdv,
        &baseOri
    )

    _ = CTTypesetterSuggestLineBreakWithOffset(CTFramesetterGetTypesetter(framesetter), 0, 40, 0)
    _ = CTTypesetterSuggestClusterBreak(CTFramesetterGetTypesetter(framesetter), 0, 40)
    _ = CTTypesetterSuggestClusterBreakWithOffset(CTFramesetterGetTypesetter(framesetter), 0, 40, 0)
    let typesetter = CTFramesetterGetTypesetter(framesetter)
    _ = CTTypesetterCreateLineWithOffset(typesetter, CFRange(location: 0, length: 5), 0)

    let translations = [CGSize](repeating: .zero, count: 1)
    var trans = translations
    trans.withUnsafeMutableBufferPointer { buf in
        glyphs.withUnsafeBufferPointer { gbuf in
            CTFontGetVerticalTranslationsForGlyphs(font, gbuf.baseAddress!, buf.baseAddress!, 1)
        }
    }
    var caret: CGFloat = 0
    _ = CTFontGetLigatureCaretPositions(font, glyphs[0], &caret, 1)
    _ = CTFontGetGlyphWithName(font, ctCFString("H"))
    _ = CTFontCopyNameForGlyph(font, 72)
    _ = CTFontCreatePathForGlyph(font, 72, nil)
    let pos = [CGPoint](repeating: .zero, count: 1)
    glyphs.withUnsafeBufferPointer { gbuf in
        pos.withUnsafeBufferPointer { pbuf in
            CTFontDrawGlyphs(font, gbuf.baseAddress!, pbuf.baseAddress!, 1, ctx)
        }
    }
    var unused: Unmanaged<CTFontDescriptor>?
    let cgFont = CTFontCopyGraphicsFont(font, &unused)
    _ = unused?.takeRetainedValue()
    _ = CTFontCreateWithGraphicsFont(cgFont, 17, nil, nil)
    var gfxErr: Unmanaged<CFError>?
    precondition(CTFontManagerRegisterGraphicsFont(cgFont, &gfxErr) == false)
    _ = gfxErr?.takeRetainedValue()
    precondition(CTFontManagerUnregisterGraphicsFont(cgFont, nil) == false)

    let info = CTGlyphInfoCreateWithGlyph(72, font, ctCFString("H"))
    precondition(info != nil)
    precondition(CTGlyphInfoGetGlyph(info!) == 72)
    _ = CTFontDescriptorCreateWithAttributes(
        unsafeBitCast([ctString(kCTFontNameAttribute): ".SFUI-Regular"] as NSDictionary, to: CFDictionary.self)
    )
    _ = CTFontDescriptorCopyAttributes(CTFontCopyFontDescriptor(font))
    _ = CTFontDescriptorCopyLocalizedAttribute(CTFontCopyFontDescriptor(font), kCTFontNameAttribute, nil)
    _ = CTFontCopyAttribute(font, kCTFontNameAttribute)
    _ = CTFontGetStringEncoding(font)
    _ = CTFontCopyCharacterSet(font)
    _ = CTFontCopySupportedLanguages(font)
    _ = CTFontCopyAvailableTables(font, [])
    _ = CTFontCopyTable(font, CTFontTableTag(kCTFontTableHead), [])
    _ = CTFontCopyFeatureSettings(font)
    _ = CTFontCopyDefaultCascadeListForLanguages(font, nil)
    _ = CTFontGetTypographicBoundsForAdaptiveImageProvider(font, nil)
    struct CatalogAdaptiveProvider: CTAdaptiveImageProviding {}
    CTFontDrawImageFromAdaptiveImageProviderAtPoint(
        font,
        CatalogAdaptiveProvider(),
        .zero,
        ctx
    )
    var rubySlots: [Unmanaged<CFString>?] = [
        Unmanaged.passRetained(ctCFString("ル")),
        nil,
        nil,
        nil
    ]
    let createdRuby = rubySlots.withUnsafeMutableBufferPointer { buffer in
        CTRubyAnnotationCreate(.auto, .auto, 0.5, buffer.baseAddress!)
    }
    rubySlots[0]?.release()
    precondition(createdRuby != nil)
    _ = CTFontCollectionCreateMatchingFontDescriptorsWithOptions(
        CTFontCollectionCreateFromAvailableFonts(nil),
        nil
    )
    _ = CTFontManagerUnregisterFontsForURLs(
        unsafeBitCast([] as NSArray, to: CFArray.self),
        .process,
        nil
    )
    _ = CTFontDescriptorCreateCopyWithVariation(
        CTFontCopyFontDescriptor(font),
        unsafeBitCast(NSNumber(value: 0), to: CFNumber.self),
        0
    )
    _ = CTFontDescriptorCreateCopyWithFeature(
        CTFontCopyFontDescriptor(font),
        unsafeBitCast(NSNumber(value: 0), to: CFNumber.self),
        unsafeBitCast(NSNumber(value: 0), to: CFNumber.self)
    )
}

func testDeclaredStringKeyPayloads() {
    precondition(ctString(kCTAdaptiveImageProviderAttributeName) == "CTAdaptiveImageProvider")
    precondition(ctString(kCTBackgroundColorAttributeName) == "CTBackgroundColor")
    precondition(ctString(kCTBaselineClassAttributeName) == "CTBaselineClass")
    precondition(ctString(kCTBaselineClassHanging) == "CTBaselineClassHanging")
    precondition(ctString(kCTBaselineClassIdeographicCentered) == "CTBaselineClassIdeographicCentered")
    precondition(ctString(kCTBaselineClassIdeographicHigh) == "CTBaselineClassIdeographicHigh")
    precondition(ctString(kCTBaselineClassIdeographicLow) == "CTBaselineClassIdeographicLow")
    precondition(ctString(kCTBaselineClassMath) == "CTBaselineClassMath")
    precondition(ctString(kCTBaselineClassRoman) == "CTBaselineClassRoman")
    precondition(ctString(kCTBaselineInfoAttributeName) == "CTBaselineInfo")
    precondition(ctString(kCTBaselineOffsetAttributeName) == "CTBaselineOffset")
    precondition(ctString(kCTBaselineOriginalFont) == "CTBaselineOriginalFont")
    precondition(ctString(kCTBaselineReferenceFont) == "CTBaselineReferenceFont")
    precondition(ctString(kCTBaselineReferenceInfoAttributeName) == "CTBaselineReferenceInfo")
    precondition(ctString(kCTCharacterShapeAttributeName) == "NSCharacterShape")
    precondition(ctString(kCTFontBaselineAdjustAttribute) == "NSCTFontBaselineAdjustAttribute")
    precondition(ctString(kCTFontCascadeListAttribute) == "NSCTFontCascadeListAttribute")
    precondition(ctString(kCTFontCharacterSetAttribute) == "NSCTFontCharacterSetAttribute")
    precondition(ctString(kCTFontCollectionRemoveDuplicatesOption) == "NSCTFontCollectionRemoveDuplicatesOption")
    precondition(ctString(kCTFontCopyrightNameKey) == "CTFontCopyrightName")
    precondition(ctString(kCTFontDescriptionNameKey) == "CTFontDescriptionName")
    precondition(ctString(kCTFontDescriptorMatchingCurrentAssetSize) == "CTFontDescriptorMatchingCurrentAssetSize")
    precondition(ctString(kCTFontDescriptorMatchingDescriptors) == "CTFontDescriptorMatchingDescriptors")
    precondition(ctString(kCTFontDescriptorMatchingError) == "CTFontDescriptorMatchingError")
    precondition(ctString(kCTFontDescriptorMatchingPercentage) == "CTFontDescriptorMatchingPercentage")
    precondition(ctString(kCTFontDescriptorMatchingResult) == "CTFontDescriptorMatchingResult")
    precondition(ctString(kCTFontDescriptorMatchingSourceDescriptor) == "CTFontDescriptorMatchingSourceDescriptor")
    precondition(ctString(kCTFontDescriptorMatchingTotalAssetSize) == "CTFontDescriptorMatchingTotalAssetSize")
    precondition(ctString(kCTFontDescriptorMatchingTotalDownloadedSize) == "CTFontDescriptorMatchingTotalDownloadedSize")
    precondition(ctString(kCTFontDesignerNameKey) == "CTFontDesignerName")
    precondition(ctString(kCTFontDesignerURLNameKey) == "CTFontDesignerURLName")
    precondition(ctString(kCTFontDisplayNameAttribute) == "NSFontVisibleNameAttribute")
    precondition(ctString(kCTFontDownloadableAttribute) == "NSCTFontDownloadableAttribute")
    precondition(ctString(kCTFontDownloadedAttribute) == "NSCTFontDownloadedAttribute")
    precondition(ctString(kCTFontEnabledAttribute) == "NSCTFontEnabledAttribute")
    precondition(ctString(kCTFontFamilyNameKey) == "CTFontFamilyName")
    precondition(ctString(kCTFontFeatureSampleTextKey) == "CTFeatureSampleText")
    precondition(ctString(kCTFontFeatureSelectorDefaultKey) == "CTFeatureSelectorDefault")
    precondition(ctString(kCTFontFeatureSelectorIdentifierKey) == "CTFeatureSelectorIdentifier")
    precondition(ctString(kCTFontFeatureSelectorNameKey) == "CTFeatureSelectorName")
    precondition(ctString(kCTFontFeatureSelectorSettingKey) == "CTFeatureSelectorSetting")
    precondition(ctString(kCTFontFeatureSettingsAttribute) == "NSCTFontFeatureSettingsAttribute")
    precondition(ctString(kCTFontFeatureTooltipTextKey) == "CTFeatureTooltipText")
    precondition(ctString(kCTFontFeatureTypeExclusiveKey) == "CTFeatureTypeExclusive")
    precondition(ctString(kCTFontFeatureTypeIdentifierKey) == "CTFeatureTypeIdentifier")
    precondition(ctString(kCTFontFeatureTypeNameKey) == "CTFeatureTypeName")
    precondition(ctString(kCTFontFeatureTypeSelectorsKey) == "CTFeatureTypeSelectors")
    precondition(ctString(kCTFontFeaturesAttribute) == "NSCTFontFeaturesAttribute")
    precondition(ctString(kCTFontFixedAdvanceAttribute) == "NSCTFontFixedAdvanceAttribute")
    precondition(ctString(kCTFontFormatAttribute) == "NSCTFontFormatAttribute")
    precondition(ctString(kCTFontFullNameKey) == "CTFontFullName")
    precondition(ctString(kCTFontLanguagesAttribute) == "NSCTFontLanguagesAttribute")
    precondition(ctString(kCTFontLicenseNameKey) == "CTFontLicenseNameName")
    precondition(ctString(kCTFontLicenseURLNameKey) == "CTFontLicenseURLName")
    precondition(ctString(kCTFontMacintoshEncodingsAttribute) == "NSCTFontMacintoshEncodingsAttribute")
    precondition(ctString(kCTFontManagerRegisteredFontsChangedNotification) == "CTFontManagerFontChangedNotification")
    precondition(ctString(kCTFontManufacturerNameKey) == "CTFontManufacturerName")
    precondition(ctString(kCTFontMatrixAttribute) == "NSCTFontMatrixAttribute")
    precondition(ctString(kCTFontOpenTypeFeatureTag) == "CTFeatureOpenTypeTag")
    precondition(ctString(kCTFontOpenTypeFeatureValue) == "CTFeatureOpenTypeValue")
    precondition(ctString(kCTFontOpticalSizeAttribute) == "NSCTFontOpticalSizeAttribute")
    precondition(ctString(kCTFontOrientationAttribute) == "NSCTFontOrientationAttribute")
    precondition(ctString(kCTFontPostScriptCIDNameKey) == "CTFontPostScriptCIDName")
    precondition(ctString(kCTFontPostScriptNameKey) == "CTFontPostScriptName")
    precondition(ctString(kCTFontPriorityAttribute) == "NSCTFontPriorityAttribute")
    precondition(ctString(kCTFontRegistrationScopeAttribute) == "NSCTFontRegistrationScopeAttribute")
    precondition(ctString(kCTFontRegistrationUserInfoAttribute) == "NSCTFontRegistrationUserInfoAttribute")
    precondition(ctString(kCTFontSampleTextNameKey) == "CTFontSampleTextName")
    precondition(ctString(kCTFontSlantTrait) == "NSCTFontSlantTrait")
    precondition(ctString(kCTFontStyleNameAttribute) == "NSFontFaceAttribute")
    precondition(ctString(kCTFontStyleNameKey) == "CTFontSubFamilyName")
    precondition(ctString(kCTFontSubFamilyNameKey) == "CTFontSubFamilyName")
    precondition(ctString(kCTFontSymbolicTrait) == "NSCTFontSymbolicTrait")
    precondition(ctString(kCTFontTrademarkNameKey) == "CTFontTrademarkName")
    precondition(ctString(kCTFontTraitsAttribute) == "NSCTFontTraitsAttribute")
    precondition(ctString(kCTFontURLAttribute) == "NSCTFontFileURLAttribute")
    precondition(ctString(kCTFontUniqueNameKey) == "CTFontUniqueName")
    precondition(ctString(kCTFontVariationAttribute) == "NSCTFontVariationAttribute")
    precondition(ctString(kCTFontVariationAxesAttribute) == "NSCTFontVariationAxesAttribute")
    precondition(ctString(kCTFontVariationAxisDefaultValueKey) == "NSCTVariationAxisDefaultValue")
    precondition(ctString(kCTFontVariationAxisHiddenKey) == "NSCTVariationAxisHidden")
    precondition(ctString(kCTFontVariationAxisIdentifierKey) == "NSCTVariationAxisIdentifier")
    precondition(ctString(kCTFontVariationAxisMaximumValueKey) == "NSCTVariationAxisMaximumValue")
    precondition(ctString(kCTFontVariationAxisMinimumValueKey) == "NSCTVariationAxisMinimumValue")
    precondition(ctString(kCTFontVariationAxisNameKey) == "NSCTVariationAxisName")
    precondition(ctString(kCTFontVendorURLNameKey) == "CTFontVendorURLName")
    precondition(ctString(kCTFontVersionNameKey) == "CTFontVersionName")
    precondition(ctString(kCTFontWeightTrait) == "NSCTFontWeightTrait")
    precondition(ctString(kCTFontWidthTrait) == "NSCTFontProportionTrait")
    precondition(ctString(kCTForegroundColorFromContextAttributeName) == "CTForegroundColorFromContext")
    precondition(ctString(kCTFrameClippingPathsAttributeName) == "CTFrameClippingPaths")
    precondition(ctString(kCTFramePathClippingPathAttributeName) == "CTFramePathClippingPath")
    precondition(ctString(kCTFramePathFillRuleAttributeName) == "CTFramePathFillRule")
    precondition(ctString(kCTFramePathWidthAttributeName) == "CTFramePathWidth")
    precondition(ctString(kCTFrameProgressionAttributeName) == "CTFrameProgression")
    precondition(ctString(kCTGlyphInfoAttributeName) == "NSGlyphInfo")
    precondition(ctString(kCTHorizontalInVerticalFormsAttributeName) == "CTHorizontalInVerticalForms")
    precondition(ctString(kCTLanguageAttributeName) == "NSLanguage")
    precondition(ctString(kCTLigatureAttributeName) == "NSLigature")
    precondition(ctString(kCTRubyAnnotationScaleToFitAttributeName) == "CTRubyAnnotationScaleToFit")
    precondition(ctString(kCTRubyAnnotationSizeFactorAttributeName) == "CTRubyAnnotationSizeFactor")
    precondition(ctString(kCTRunDelegateAttributeName) == "CTRunDelegate")
    precondition(ctString(kCTStrokeColorAttributeName) == "CTStrokeColor")
    precondition(ctString(kCTStrokeWidthAttributeName) == "NSStrokeWidth")
    precondition(ctString(kCTSuperscriptAttributeName) == "CTSuperscript")
    precondition(ctString(kCTTabColumnTerminatorsAttributeName) == "NSTabColumnTerminatorsAttributeName")
    precondition(ctString(kCTTypesetterOptionAllowUnboundedLayout) == "CTTypesetterOptionAllowUnboundedLayout")
    precondition(ctString(kCTTypesetterOptionForcedEmbeddingLevel) == "CTTypesetterOptionForcedEmbeddingLevel")
    precondition(ctString(kCTUnderlineColorAttributeName) == "CTUnderlineColor")
    precondition(ctString(kCTVerticalFormsAttributeName) == "CTVerticalForms")
    precondition(ctString(kCTWritingDirectionAttributeName) == "NSWritingDirection")
}
