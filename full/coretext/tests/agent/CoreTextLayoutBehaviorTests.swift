import CoreFoundation
import Foundation
import CoreText

func testRunDelegateWidthInLineAndBreak() {
    let url = ctRegisterFixtureFont()
    defer { _ = ctUnregister(url) }
    let font = CTFontCreateWithName(ctCFString("OpenUIKitFixture-Regular"), 10, nil)
    let callbacks = CTRunDelegateCallbacks(
        version: CFIndex(kCTRunDelegateCurrentVersion),
        dealloc: { _ in },
        getAscent: { _ in 11 },
        getDescent: { _ in 3 },
        getWidth: { _ in 9 }
    )
    let delegate = withUnsafePointer(to: callbacks) { pointer in
        CTRunDelegateCreate(pointer, UnsafeMutableRawPointer(bitPattern: 0x11))
    }!
    let object = NSMutableAttributedString(string: "H\u{FFFC}e")
    object.addAttribute(
        NSAttributedString.Key(ctString(kCTFontAttributeName)),
        value: font,
        range: NSRange(location: 0, length: object.length)
    )
    object.addAttribute(
        NSAttributedString.Key(ctString(kCTRunDelegateAttributeName)),
        value: delegate,
        range: NSRange(location: 1, length: 1)
    )
    let line = CTLineCreateWithAttributedString(object)
    var ascent: CGFloat = 0
    var descent: CGFloat = 0
    let width = CTLineGetTypographicBounds(line, &ascent, &descent, nil)
    // H=7, delegate=9, e=5 → 21; ascent max(8, 11)=11
    precondition(abs(width - 21) < 1e-9)
    precondition(ascent == 11)
    precondition(descent == 3)
    let typesetter = CTTypesetterCreateWithAttributedString(object)
    // 7+9=16 fits in 16, next 5 does not → break after replacement
    precondition(CTTypesetterSuggestLineBreak(typesetter, 0, 16) == 2)
}

func testKernAttributeAddsToAdvances() {
    let url = ctRegisterFixtureFont()
    defer { _ = ctUnregister(url) }
    let font = CTFontCreateWithName(ctCFString("OpenUIKitFixture-Regular"), 10, nil)
    let string = NSMutableAttributedString(
        string: "He",
        attributes: [NSAttributedString.Key(ctString(kCTFontAttributeName)): font]
    )
    string.addAttribute(
        NSAttributedString.Key(ctString(kCTKernAttributeName)),
        value: NSNumber(value: 1.5),
        range: NSRange(location: 0, length: 2)
    )
    precondition(ctString(kCTKernAttributeName) == "NSKern")
    let line = CTLineCreateWithAttributedString(string)
    var ascent: CGFloat = 0
    let width = CTLineGetTypographicBounds(line, &ascent, nil, nil)
    // (7+1.5)+(5+1.5)=15
    precondition(abs(width - 15) < 1e-9)
    let runs = ctNSArray(CTLineGetGlyphRuns(line))
    let run = runs[0] as! CTRun
    var advances = [CGSize](repeating: .zero, count: 2)
    CTRunGetAdvances(run, CFRange(location: 0, length: 0), &advances)
    precondition(abs(advances[0].width - 8.5) < 1e-9)
    precondition(abs(advances[1].width - 6.5) < 1e-9)
}

func testMixedFontRunsAndGlyphNameFromCmap() {
    let url = ctRegisterFixtureFont()
    defer { _ = ctUnregister(url) }
    let fixture = CTFontCreateWithName(ctCFString("OpenUIKitFixture-Regular"), 10, nil)
    let portable = CTFont(ctCFString("OpenUIKitPortable-Regular"), size: 10)
    let string = NSMutableAttributedString(string: "HA")
    string.addAttribute(
        NSAttributedString.Key(ctString(kCTFontAttributeName)),
        value: fixture,
        range: NSRange(location: 0, length: 1)
    )
    string.addAttribute(
        NSAttributedString.Key(ctString(kCTFontAttributeName)),
        value: portable,
        range: NSRange(location: 1, length: 1)
    )
    let line = CTLineCreateWithAttributedString(string)
    let runs = ctNSArray(CTLineGetGlyphRuns(line))
    precondition(runs.count == 2)
    let first = runs[0] as! CTRun
    let second = runs[1] as! CTRun
    precondition(CTRunGetGlyphCount(first) == 1)
    precondition(CTRunGetGlyphCount(second) == 1)
    var g0 = [CGGlyph](repeating: 0, count: 1)
    var g1 = [CGGlyph](repeating: 0, count: 1)
    g0.withUnsafeMutableBufferPointer { CTRunGetGlyphs(first, CFRange(location: 0, length: 0), $0.baseAddress!) }
    g1.withUnsafeMutableBufferPointer { CTRunGetGlyphs(second, CFRange(location: 0, length: 0), $0.baseAddress!) }
    precondition(g0[0] == 3)
    precondition(g1[0] == 65)
    var a0: CGFloat = 0
    let w0 = CTRunGetTypographicBounds(first, CFRange(location: 0, length: 0), &a0, nil, nil)
    precondition(abs(w0 - 7) < 1e-9)
    var positions = [CGPoint](repeating: .zero, count: 1)
    CTRunGetPositions(second, CFRange(location: 0, length: 0), &positions)
    precondition(abs(positions[0].x - 7) < 1e-9)
    precondition(CTFontGetGlyphWithName(fixture, ctCFString("H")) == 3)
    precondition(CTFontGetGlyphWithName(fixture, ctCFString("space")) == 1 || CTFontGetGlyphWithName(fixture, ctCFString(" ")) != 0)
}

func testOpticalBoundsCopyTraitsAndCollectionAttributes() {
    let url = ctRegisterFixtureFont()
    defer { _ = ctUnregister(url) }
    let font = CTFontCreateWithName(ctCFString("OpenUIKitFixture-Regular"), 10, nil)
    let hello: [UniChar] = Array("H".utf16)
    var glyphs = [CGGlyph](repeating: 0, count: 1)
    _ = hello.withUnsafeBufferPointer { cbuf in
        glyphs.withUnsafeMutableBufferPointer { gbuf in
            CTFontGetGlyphsForCharacters(font, cbuf.baseAddress!, gbuf.baseAddress!, 1)
        }
    }
    var optical = [CGRect](repeating: .zero, count: 1)
    let union = glyphs.withUnsafeBufferPointer { gbuf in
        optical.withUnsafeMutableBufferPointer { rbuf in
            CTFontGetOpticalBoundsForGlyphs(font, gbuf.baseAddress!, rbuf.baseAddress, 1, 0)
        }
    }
    precondition(abs(optical[0].origin.x - 0.4) < 1e-9)
    precondition(abs(optical[0].size.width - 6.2) < 1e-9)
    precondition(union.width > 0)

    let line = CTLineCreateWithAttributedString(
        NSAttributedString(
            string: "H",
            attributes: [NSAttributedString.Key(ctString(kCTFontAttributeName)): font]
        )
    )
    let pathBounds = CTLineGetBoundsWithOptions(line, [.useGlyphPathBounds])
    precondition(abs(pathBounds.origin.x - 0.4) < 1e-9)
    let withLeading = CTLineGetBoundsWithOptions(line, [])
    let withoutLeading = CTLineGetBoundsWithOptions(line, [.excludeTypographicLeading])
    precondition(withLeading.height >= withoutLeading.height)

    let bold = CTFontCreateCopyWithSymbolicTraits(font, 10, nil, .boldTrait, .boldTrait)
    precondition(bold != nil)
    precondition(CTFontGetSymbolicTraits(bold!).contains(.boldTrait))
    precondition(CTFontGetGlyphCount(bold!) == 8)

    let collection = CTFontCollectionCreateFromAvailableFonts(nil)
    let names = ctNSArray(CTFontCollectionCopyFontAttribute(collection, kCTFontNameAttribute, []))
    precondition(names.contains("OpenUIKitFixture-Regular"))
    let attrs = ctNSArray(
        CTFontCollectionCopyFontAttributes(
            collection,
            unsafeBitCast(NSSet(array: [unsafeBitCast(kCTFontNameAttribute, to: NSString.self)]), to: CFSet.self),
            .unique
        )
    )
    precondition(attrs.count >= 1)
    var compared = 0
    let sorted = CTFontCollectionCreateMatchingFontDescriptorsSortedWithCallback(collection, { left, right, _ in
        compared += 1
        let l = CTFontDescriptorCopyAttribute(left, kCTFontNameAttribute).map {
            ctString(unsafeBitCast($0, to: CFString.self))
        } ?? ""
        let r = CTFontDescriptorCopyAttribute(right, kCTFontNameAttribute).map {
            ctString(unsafeBitCast($0, to: CFString.self))
        } ?? ""
        if l == r { return .compareEqualTo }
        return l < r ? .compareLessThan : .compareGreaterThan
    }, nil)
    precondition(ctNSArray(sorted!).count >= 1)
    _ = compared

    let identity = CGAffineTransform.identity
    let copied = withUnsafePointer(to: identity) { pointer in
        CTFontCreateCopyWithAttributes(font, 12, pointer, nil)
    }
    precondition(CTFontGetSize(copied) == 12)
    let family = CTFontCreateCopyWithFamily(font, 10, nil, ctCFString("OpenUIKit Fixture"))
    precondition(family != nil)
    precondition(CTFontGetGlyphCount(family!) == 8)
}

func testParagraphStyleSettingAndRunDelegateCallbackInits() {
    var alignment = CTTextAlignment.justified
    let setting = withUnsafePointer(to: &alignment) { pointer in
        CTParagraphStyleSetting(
            spec: .firstLineHeadIndent,
            valueSize: MemoryLayout<UInt8>.size,
            value: UnsafeRawPointer(pointer)
        )
    }
    precondition(setting.spec == .firstLineHeadIndent)
    precondition(setting.valueSize == MemoryLayout<UInt8>.size)
    var indent: CGFloat = 18
    let indentSetting = withUnsafePointer(to: &indent) { pointer in
        CTParagraphStyleSetting(spec: .headIndent, valueSize: MemoryLayout<CGFloat>.size, value: UnsafeRawPointer(pointer))
    }
    let style = withUnsafePointer(to: indentSetting) { pointer in
        CTParagraphStyleCreate(pointer, 1)
    }
    var restored: CGFloat = 0
    let ok = withUnsafeMutablePointer(to: &restored) { pointer in
        CTParagraphStyleGetValueForSpecifier(
            style,
            .headIndent,
            MemoryLayout<CGFloat>.size,
            UnsafeMutableRawPointer(pointer)
        )
    }
    precondition(ok)
    precondition(restored == 18)

    let callbacks = CTRunDelegateCallbacks(
        version: CFIndex(kCTRunDelegateVersion1),
        dealloc: { _ in },
        getAscent: { _ in 1 },
        getDescent: { _ in 2 },
        getWidth: { _ in 3 }
    )
    precondition(callbacks.version == CFIndex(kCTRunDelegateVersion1))
    precondition(callbacks.getWidth(UnsafeMutableRawPointer(bitPattern: 1)!) == 3)
}

func testSFNTNamePlatformAndTableTagConstants() {
    precondition(kFontCopyrightName == 0)
    precondition(kFontFamilyName == 1)
    precondition(kFontStyleName == 2)
    precondition(kFontUniqueName == 3)
    precondition(kFontFullName == 4)
    precondition(kFontVersionName == 5)
    precondition(kFontPostscriptName == 6)
    precondition(kFontTrademarkName == 7)
    precondition(kFontManufacturerName == 8)
    precondition(kFontDesignerName == 9)
    precondition(kFontDescriptionName == 10)
    precondition(kFontVendorURLName == 11)
    precondition(kFontDesignerURLName == 12)
    precondition(kFontLicenseDescriptionName == 13)
    precondition(kFontLicenseInfoURLName == 14)
    precondition(kFontPreferredFamilyName == 16)
    precondition(kFontPreferredSubfamilyName == 17)
    precondition(kFontMacCompatibleFullName == 18)
    precondition(kFontSampleTextName == 19)
    precondition(kFontPostScriptCIDName == 20)
    precondition(kFontLastReservedName == 255)
    precondition(kFontUnicodePlatform == 0)
    precondition(kFontMacintoshPlatform == 1)
    precondition(kFontReservedPlatform == 2)
    precondition(kFontMicrosoftPlatform == 3)
    precondition(kFontCustomPlatform == 4)
    precondition(kFontUnicodeDefaultSemantics == 0)
    precondition(kFontUnicodeV1_1Semantics == 1)
    precondition(kFontISO10646_1993Semantics == 2)
    precondition(kFontUnicodeV2_0BMPOnlySemantics == 3)
    precondition(kFontUnicodeV2_0FullCoverageSemantics == 4)
    precondition(kFontUnicodeV4_0VariationSequenceSemantics == 5)
    precondition(kFontUnicode_FullRepertoire == 6)
    precondition(kFontMicrosoftSymbolScript == 0)
    precondition(kFontMicrosoftStandardScript == 1)
    precondition(kFontMicrosoftUCS4Script == 10)
    precondition(kFontNoPlatformCode == 0xFFFF_FFFF)
    precondition(kFontNoScriptCode == 0xFFFF_FFFF)
    precondition(kFontNoLanguageCode == 0xFFFF_FFFF)
    precondition(kFontNoNameCode == 0xFFFF_FFFF)
    precondition(kMORTTag == kCTFontTableMort)
    precondition(kMORXTag == kCTFontTableMorx)
    precondition(kPROPTag == kCTFontTableProp)
    precondition(kKERNTag == kCTFontTableKern)
    precondition(kKERXTag == kCTFontTableKerx)
    precondition(kBSLNTag == kCTFontTableBsln)
    precondition(kJUSTTag == kCTFontTableJust)
    precondition(kLCARTag == kCTFontTableLcar)
    precondition(kOPBDTag == kCTFontTableOpbd)
    precondition(kTRAKTag == kCTFontTableTrak)
    precondition(nameFontTableTag == kCTFontTableName)
    precondition(os2FontTableTag == kCTFontTableOS2)
    precondition(variationFontTableTag == kCTFontTableFvar)
    precondition(ATSFONTREF_DEFINED == 1)
    precondition(kCTWritingDirectionEmbedding == 0)
    precondition(kCTWritingDirectionOverride == 2)
}
