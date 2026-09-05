import CoreFoundation
import Foundation
import CoreText

func ctString(_ value: CFString) -> String {
    unsafeBitCast(value, to: NSString.self) as String
}

func ctCFString(_ value: String) -> CFString {
    unsafeBitCast(value as NSString, to: CFString.self)
}

func ctCFURL(_ url: URL) -> CFURL {
    unsafeBitCast(url as NSURL, to: CFURL.self)
}

func ctCFData(_ data: Data) -> CFData {
    unsafeBitCast(data as NSData, to: CFData.self)
}

func ctNSError(_ error: CFError) -> NSError {
    unsafeBitCast(error, to: NSError.self)
}

func ctNSArray(_ array: CFArray) -> NSArray {
    unsafeBitCast(array, to: NSArray.self)
}

func ctRecognizedFontData() -> Data {
    Data([0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
}

func ctTemporaryFontURL(_ name: String) -> URL {
    FileManager.default.temporaryDirectory
        .appendingPathComponent("coretext-\(name)-\(UUID().uuidString).ttf")
}

func ctRegister(_ url: URL, scope: CTFontManagerScope = .process) -> (Bool, NSError?) {
    var unmanaged: Unmanaged<CFError>?
    let success = CTFontManagerRegisterFontsForURL(ctCFURL(url), scope, &unmanaged)
    let error = unmanaged.map { ctNSError($0.takeRetainedValue()) }
    return (success, error)
}

func ctUnregister(_ url: URL, scope: CTFontManagerScope = .process) -> (Bool, NSError?) {
    var unmanaged: Unmanaged<CFError>?
    let success = CTFontManagerUnregisterFontsForURL(ctCFURL(url), scope, &unmanaged)
    let error = unmanaged.map { ctNSError($0.takeRetainedValue()) }
    return (success, error)
}

func testFontManagerRegisterProcessScope() {
    precondition(ctString(kCTFontManagerErrorDomain) == "com.apple.CoreText.CTFontManagerErrorDomain")
    precondition(ctString(kCTFontManagerErrorFontURLsKey) == "CTFontManagerErrorFontURLs")
    precondition(ctString(kCTFontManagerErrorFontDescriptorsKey) == "CTFontManagerErrorFontDescriptors")
    precondition(ctString(kCTFontManagerErrorFontAssetNameKey) == "CTFontManagerErrorFontAssetName")
    precondition(CTFontManagerScope.none.rawValue == 0)
    precondition(CTFontManagerScope.process.rawValue == 1)
    precondition(CTFontManagerScope.persistent.rawValue == 2)
    precondition(CTFontManagerScope.session.rawValue == 3)
    precondition(CTFontManagerScope.user == .persistent)
    precondition(CTFontManagerError.fileNotFound.rawValue == 101)
    precondition(CTFontManagerError.unrecognizedFormat.rawValue == 103)
    precondition(CTFontManagerError.alreadyRegistered.rawValue == 105)
    precondition(CTFontManagerError.notRegistered.rawValue == 201)
    precondition(CTFontManagerError.invalidFilePath.rawValue == 306)
    precondition(CTFontManagerError.unsupportedScope.rawValue == 307)
    precondition(CTFontManagerError.duplicatedName.rawValue == 305)

    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("coretext-register-\(UUID().uuidString)", isDirectory: true)
    try! FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let first = root.appendingPathComponent("first.ttf")
    let second = root.appendingPathComponent("second.ttf")
    let invalid = root.appendingPathComponent("invalid.ttf")
    let missing = root.appendingPathComponent("missing.ttf")
    try! ctRecognizedFontData().write(to: first)
    try! ctRecognizedFontData().write(to: second)
    try! Data("not a font".utf8).write(to: invalid)

    let initial = ctRegister(first)
    precondition(initial.0 && initial.1 == nil)
    let repeated = ctRegister(first)
    precondition(!repeated.0 && repeated.1?.code == CTFontManagerError.alreadyRegistered.rawValue)
    precondition(repeated.1?.domain == ctString(kCTFontManagerErrorDomain))
    let duplicate = ctRegister(second)
    precondition(duplicate.0 && duplicate.1 == nil)
    let malformed = ctRegister(invalid)
    precondition(!malformed.0 && malformed.1?.code == CTFontManagerError.unrecognizedFormat.rawValue)
    let absent = ctRegister(missing)
    precondition(!absent.0 && absent.1?.code == CTFontManagerError.fileNotFound.rawValue)
    let persistent = ctRegister(first, scope: .persistent)
    precondition(!persistent.0 && persistent.1?.code == CTFontManagerError.unsupportedScope.rawValue)
    if let remote = URL(string: "https://example.invalid/font.ttf") {
        let remoteResult = ctRegister(remote)
        precondition(!remoteResult.0 && remoteResult.1?.code == CTFontManagerError.invalidFilePath.rawValue)
    }

    let families = ctNSArray(CTFontManagerCopyAvailableFontFamilyNames())
    precondition(families.contains("OpenUIKit Portable"))
    let posts = ctNSArray(CTFontManagerCopyAvailablePostScriptNames())
    precondition(posts.contains("OpenUIKitPortable-Regular"))
    let registered = ctNSArray(CTFontManagerCopyRegisteredFontDescriptors(.process, true))
    precondition(registered.count >= 2)

    let fromURL = CTFontManagerCreateFontDescriptorsFromURL(ctCFURL(first))
    precondition(fromURL != nil)
    let fromData = CTFontManagerCreateFontDescriptorFromData(ctCFData(ctRecognizedFontData()))
    precondition(fromData != nil)
    let fromDataArray = ctNSArray(CTFontManagerCreateFontDescriptorsFromData(ctCFData(ctRecognizedFontData())))
    precondition(fromDataArray.count == 1)
    let garbageDescriptors = ctNSArray(CTFontManagerCreateFontDescriptorsFromData(ctCFData(Data("nope".utf8))))
    precondition(garbageDescriptors.count == 0)

    let unregisterFirst = ctUnregister(first)
    precondition(unregisterFirst.0 && unregisterFirst.1 == nil)
    let unregisterMissing = ctUnregister(first)
    precondition(!unregisterMissing.0 && unregisterMissing.1?.code == CTFontManagerError.notRegistered.rawValue)
    _ = ctUnregister(second)
}

func testFontManagerURLBatchAndFailClosedAssets() {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("coretext-batch-\(UUID().uuidString)", isDirectory: true)
    try! FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }
    let url = root.appendingPathComponent("batch.ttf")
    try! ctRecognizedFontData().write(to: url)

    let array = unsafeBitCast([url] as NSArray, to: CFArray.self)
    var errors: Unmanaged<CFArray>?
    let ok = CTFontManagerRegisterFontsForURLs(array, .process, &errors)
    precondition(ok)
    precondition(errors == nil)

    var handlerSeen = false
    CTFontManagerRegisterFontURLs(array, .process, true) { payload, done in
        handlerSeen = true
        _ = (payload, done)
        return true
    }
    precondition(handlerSeen)

    var unregSeen = false
    CTFontManagerUnregisterFontURLs(array, .process) { payload, done in
        unregSeen = true
        _ = (payload, done)
        return true
    }
    precondition(unregSeen)

    var assetFailed = false
    CTFontManagerRegisterFontsWithAssetNames(
        unsafeBitCast(["MissingAsset"] as NSArray, to: CFArray.self),
        nil,
        .process,
        true
    ) { _, done in
        assetFailed = !done
        return false
    }
    precondition(assetFailed)

    var requested: [CTFontDescriptor] = []
    let descriptor = CTFontDescriptorCreateWithNameAndSize(ctCFString("Requested"), 12)
    CTFontManagerRequestFonts(unsafeBitCast([descriptor] as NSArray, to: CFArray.self)) { pending in
        requested = ctNSArray(pending).compactMap { $0 as? CTFontDescriptor }
    }
    precondition(requested.count == 1)

    CTFontManagerRegisterFontDescriptors(
        unsafeBitCast([descriptor] as NSArray, to: CFArray.self),
        .process,
        true,
        nil
    )
    CTFontManagerUnregisterFontDescriptors(
        unsafeBitCast([descriptor] as NSArray, to: CFArray.self),
        .process,
        nil
    )
}

func testCoreTextVersionAndTableTags() {
    precondition(kCTVersionNumber11_0 == 851968)
    precondition(CTGetCoreTextVersion() == UInt32(bitPattern: kCTVersionNumber11_0))
    precondition(kCTVersionNumber10_5 == 131072)
    precondition(kCTFontTableHead == 1751474532)
    precondition(kCTFontTableName == 1851878757)
    precondition(kCTFontClassMaskShift == 28)
    precondition(kCTFontPrioritySystem == 10000)
    precondition(kCTFontPriorityProcess == 60000)
    precondition(kCTRunDelegateCurrentVersion == 1)
    precondition(kLigaturesType == 1)
    precondition(kAllTypographicFeaturesType == 0)
}

func testCharacterCollectionAndFontEnums() {
    precondition(CTCharacterCollection.identityMapping.rawValue == 0)
    precondition(CTCharacterCollection.adobeKorea1.rawValue == 5)
    precondition(CTCharacterCollection.kCTIdentityMappingCharacterCollection == .identityMapping)
    precondition(CTCharacterCollection.kCTAdobeCNS1CharacterCollection == .adobeCNS1)
    precondition(CTFontFormat.unrecognized.rawValue == 0)
    precondition(CTFontFormat.trueType.rawValue == 3)
    precondition(CTFontFormat.bitmap.rawValue == 5)
    precondition(CTFontOrientation.default.rawValue == 0)
    precondition(CTFontOrientation.kCTFontHorizontalOrientation == .horizontal)
    precondition(CTFontUIFontType.none.rawValue == 0xFFFF_FFFF)
    precondition(CTFontUIFontType.system.rawValue == 2)
    precondition(CTFontUIFontType.kCTFontNoFontType == .none)
    precondition(CTFontUIFontType.kCTFontSystemFontType == .system)
    precondition(CTFontDescriptorMatchingState.didBegin.rawValue == 0)
    precondition(CTFontDescriptorMatchingState.didFailWithError.rawValue == 8)
    precondition(CTFontManagerAutoActivationSetting.default.rawValue == 0)
    precondition(CTFontManagerAutoActivationSetting.enabled.rawValue == 2)
    precondition(CTFrameProgression.topToBottom.rawValue == 0)
    precondition(CTFramePathFillRule.evenOdd.rawValue == 0)
    precondition(CTLineBreakMode.byWordWrapping.rawValue == 0)
    precondition(CTLineTruncationType.end.rawValue == 1)
    precondition(CTTextAlignment.natural.rawValue == 4)
    precondition(CTTextAlignment.kCTLeftTextAlignment == .left)
    precondition(CTWritingDirection.natural.rawValue == -1)
    precondition(CTRubyAlignment.auto.rawValue == 0)
    precondition(CTRubyOverhang.none.rawValue == 3)
    precondition(CTRubyPosition.before.rawValue == 0)
    precondition(CTParagraphStyleSpecifier.alignment.rawValue == 0)
    precondition(CTParagraphStyleSpecifier.count.rawValue == 18)
}

func testOptionSetRawValues() {
    precondition(CTFontSymbolicTraits.italicTrait.rawValue == 1)
    precondition(CTFontSymbolicTraits.boldTrait.rawValue == 2)
    precondition(CTFontSymbolicTraits.traitBold == .boldTrait)
    precondition(CTFontSymbolicTraits.classMaskTrait.rawValue == 15 << 28)
    precondition(CTFontStylisticClass.sansSerifClass.rawValue == 8 << 28)
    precondition(CTFontStylisticClass.classOldStyleSerifs == .oldStyleSerifsClass)
    precondition(CTFontOptions.preventAutoActivation.rawValue == 1)
    precondition(CTFontCollectionCopyOptions.unique.rawValue == 1)
    precondition(CTFontCollectionCopyOptions.standardSort.rawValue == 2)
    precondition(CTLineBoundsOptions.excludeTypographicLeading.rawValue == 1)
    precondition(CTRunStatus.rightToLeft.rawValue == 1)
    precondition(CTUnderlineStyle.single.rawValue == 1)
    precondition(CTUnderlineStyle.double.rawValue == 9)
    precondition(CTUnderlineStyleModifiers.patternSolid.rawValue == 0)
    precondition(CTUnderlineStyleModifiers.patternDot.rawValue == 0x0100)
    precondition(CTFontTableOptions().rawValue == 0)
    precondition(CTFontSymbolicTraits.italicTrait.contains(.italicTrait))
    precondition(!CTFontSymbolicTraits.italicTrait.contains(.boldTrait))
}

func testPortableFontMetricsAndNames() {
    let font = CTFont(ctCFString("OpenUIKitPortable-Regular"), size: 12)
    precondition(CTFontGetSize(font) == 12)
    precondition(CTFontGetUnitsPerEm(font) == 1000)
    precondition(CTFontGetAscent(font) == 9.6)
    precondition(CTFontGetDescent(font) == 2.4)
    precondition(CTFontGetLeading(font) == 0)
    precondition(CTFontGetCapHeight(font) == 8.4)
    precondition(CTFontGetXHeight(font) == 6.0)
    precondition(CTFontGetUnderlinePosition(font) == -1.2)
    precondition(CTFontGetUnderlineThickness(font) == 0.6)
    precondition(CTFontGetSlantAngle(font) == 0)
    precondition(CTFontGetGlyphCount(font) == 1)
    precondition(CTFontGetSymbolicTraits(font).isEmpty)
    precondition(ctString(CTFontCopyPostScriptName(font)) == "OpenUIKitPortable-Regular")
    precondition(ctString(CTFontCopyFamilyName(font)) == "OpenUIKit Portable")
    precondition(ctString(CTFontCopyFullName(font)).contains("OpenUIKit"))
    precondition(ctString(CTFontCopyDisplayName(font)).contains("OpenUIKit"))
    precondition(CTFontCopyName(font, kCTFontFamilyNameKey).map { ctString($0) } == "OpenUIKit Portable")
    precondition(CTFontCopyName(font, kCTFontStyleNameKey).map { ctString($0) } == "Regular")
    var language: Unmanaged<CFString>?
    let localized = CTFontCopyLocalizedName(font, kCTFontPostScriptNameKey, &language)
    precondition(localized.map { ctString($0) } == "OpenUIKitPortable-Regular")
    precondition(language == nil)
    precondition(CTFontGetTypeID() == 0x4354_464E)
    let box = CTFontGetBoundingBox(font)
    precondition(box.width == 12.96)
    precondition(box.height == 12)
    precondition(CTFontCopyVariation(font) == nil)
    precondition(CTFontCopyVariationAxes(font) == nil)
    precondition(CTFontCopyFeatures(font) == nil)
    precondition(CTFontHasTable(font, CTFontTableTag(kCTFontTableHead)) == false)
    let ui = CTFontCreateUIFontForLanguage(.system, 0, nil)
    precondition(ui != nil)
    precondition(CTFontGetSize(ui!) == 13)
    let none = CTFontCreateUIFontForLanguage(.none, 12, nil)
    precondition(none == nil)
    let continued = CTFontCreateForString(font, ctCFString("A"), CFRange(location: 0, length: 1))
    precondition(CTFontGetSize(continued) == 12)
    let withLanguage = CTFontCreateForStringWithLanguage(
        font,
        ctCFString("A"),
        CFRange(location: 0, length: 1),
        ctCFString("en")
    )
    precondition(CTFontGetSize(withLanguage) == 12)
}

func testFontDescriptorAndCollection() {
    let descriptor = CTFontDescriptorCreateWithNameAndSize(ctCFString("Portable"), 18)
    let size = CTFontDescriptorCopyAttribute(descriptor, kCTFontSizeAttribute)
    precondition(size != nil)
    let copied = CTFontDescriptorCreateCopyWithAttributes(
        descriptor,
        unsafeBitCast([ctString(kCTFontFamilyNameAttribute): "Copied"] as NSDictionary, to: CFDictionary.self)
    )
    let family = CTFontDescriptorCopyAttribute(copied, kCTFontFamilyNameAttribute)
    precondition(family != nil)
    _ = CTFontDescriptorCreateCopyWithFamily(descriptor, ctCFString("Family"))
    _ = CTFontDescriptorCreateCopyWithSymbolicTraits(descriptor, .boldTrait, .boldTrait)
    let matching = CTFontDescriptorCreateMatchingFontDescriptor(descriptor, nil)
    precondition(matching === descriptor)
    let matches = CTFontDescriptorCreateMatchingFontDescriptors(descriptor, nil)
    precondition(ctNSArray(matches!).count == 1)
    precondition(CTFontDescriptorGetTypeID() == 0x4354_4445)
    var progress: [CTFontDescriptorMatchingState] = []
    let matched = CTFontDescriptorMatchFontDescriptorsWithProgressHandler(
        unsafeBitCast([descriptor] as NSArray, to: CFArray.self),
        nil
    ) { state, _ in
        progress.append(state)
        return true
    }
    precondition(matched)
    precondition(progress == [.didBegin, .didFinish])

    let font = CTFont(descriptor, size: 18)
    precondition(CTFontGetSize(font) == 18)
    let collection = CTFontCollectionCreateWithFontDescriptors(
        unsafeBitCast([descriptor] as NSArray, to: CFArray.self),
        nil
    )
    let listed = CTFontCollectionCreateMatchingFontDescriptors(collection)
    precondition(ctNSArray(listed!).count == 1)
    let available = CTFontCollectionCreateFromAvailableFonts(nil)
    precondition(CTFontCollectionGetTypeID() == 0x4354_434C)
    _ = available
    let copy = CTFontCollectionCreateCopyWithFontDescriptors(collection, nil, nil)
    _ = CTFontCollectionCopyFontAttribute(copy, kCTFontNameAttribute, [])
    _ = CTFontCollectionCopyFontAttributes(
        copy,
        unsafeBitCast(NSSet(array: [ctString(kCTFontNameAttribute)]), to: CFSet.self),
        .unique
    )
    let sorted = CTFontCollectionCreateMatchingFontDescriptorsSortedWithCallback(collection, nil, nil)
    precondition(sorted != nil)
}

func testTypesetterLineAndRun() {
    let font = CTFont(ctCFString("OpenUIKitPortable-Regular"), size: 12)
    let attributes: [NSAttributedString.Key: Any] = [
        NSAttributedString.Key(ctString(kCTFontAttributeName)): font
    ]
    let string = NSAttributedString(string: "Hello world", attributes: attributes)
    let typesetter = CTTypesetterCreateWithAttributedString(string)
    precondition(CTTypesetterGetTypeID() == 0x4354_5453)
    let optionalTypesetter = CTTypesetterCreateWithAttributedStringAndOptions(string, nil)
    precondition(optionalTypesetter != nil)
    let breakIndex = CTTypesetterSuggestLineBreak(typesetter, 0, 18)
    precondition(breakIndex == 3)
    let line = CTTypesetterCreateLine(typesetter, CFRange(location: 0, length: 5))
    precondition(CTLineGetGlyphCount(line) == 5)
    let range = CTLineGetStringRange(line)
    precondition(range.location == 0 && range.length == 5)
    var ascent: CGFloat = 0
    var descent: CGFloat = 0
    var leading: CGFloat = 0
    let width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading)
    precondition(width == 30)
    precondition(ascent == 9.6)
    precondition(descent == 2.4)
    let offset = CTLineGetOffsetForStringIndex(line, 2, nil)
    precondition(offset == 12)
    let index = CTLineGetStringIndexForPosition(line, CGPoint(x: 13, y: 0))
    precondition(index == 2)
    let runs = ctNSArray(CTLineGetGlyphRuns(line))
    precondition(runs.count == 1)
    let run = runs[0] as! CTRun
    precondition(CTRunGetGlyphCount(run) == 5)
    precondition(CTRunGetStatus(run).isEmpty)
    var advances = Array(repeating: CGSize.zero, count: 5)
    CTRunGetAdvances(run, CFRange(location: 0, length: 0), &advances)
    precondition(advances[0].width == 6)
    var positions = Array(repeating: CGPoint.zero, count: 5)
    CTRunGetPositions(run, CFRange(location: 0, length: 0), &positions)
    precondition(positions[1].x == 6)
    var indices = Array(repeating: CFIndex(0), count: 5)
    CTRunGetStringIndices(run, CFRange(location: 0, length: 0), &indices)
    precondition(indices[4] == 4)
    precondition(CTRunGetAdvancesPtr(run) == nil)
    precondition(CTRunGetPositionsPtr(run) == nil)
    precondition(CTRunGetStringIndicesPtr(run) == nil)
    let justified = CTLineCreateJustifiedLine(line, 1, 40)
    precondition(justified != nil)
    let truncated = CTLineCreateTruncatedLine(line, 12, .end, nil)
    precondition(CTLineGetGlyphCount(truncated!) == 2)
    var caretCount = 0
    CTLineEnumerateCaretOffsets(line) { _, _, _, stop in
        caretCount += 1
        if caretCount >= 3 {
            stop.pointee = true
        }
    }
    precondition(caretCount == 3)
    let fromString = CTLineCreateWithAttributedString(string)
    precondition(CTLineGetGlyphCount(fromString) == string.length)
    let framesetter = CTFramesetterCreateWithAttributedString(string)
    _ = CTFramesetterGetTypesetter(framesetter)
    var fit = CFRange(location: 0, length: 0)
    let suggested = CTFramesetterSuggestFrameSizeWithConstraints(
        framesetter,
        CFRange(location: 0, length: string.length),
        nil,
        CGSize(width: 24, height: 100),
        &fit
    )
    precondition(suggested.width > 0)
    precondition(fit.length > 0)
    precondition(CTLineGetTypeID() == 0x4354_4C4E)
    precondition(CTRunGetTypeID() == 0x4354_5255)
    precondition(CTFramesetterGetTypeID() == 0x4354_4653)
    let whitespace = CTLineCreateWithAttributedString(NSAttributedString(string: "A "))
    precondition(CTLineGetTrailingWhitespaceWidth(whitespace) == 6)
}

func testParagraphStyleTabRubyAndGlyphInfo() {
    var alignment = CTTextAlignment.center
    let setting = withUnsafePointer(to: &alignment) { pointer in
        CTParagraphStyleSetting(
            spec: .alignment,
            valueSize: MemoryLayout<UInt8>.size,
            value: UnsafeRawPointer(pointer)
        )
    }
    let style = withUnsafePointer(to: setting) { pointer in
        CTParagraphStyleCreate(pointer, 1)
    }
    var restored = CTTextAlignment.natural
    let ok = withUnsafeMutablePointer(to: &restored) { pointer in
        CTParagraphStyleGetValueForSpecifier(
            style,
            .alignment,
            MemoryLayout<UInt8>.size,
            UnsafeMutableRawPointer(pointer)
        )
    }
    precondition(ok)
    precondition(restored == .center)
    let copy = CTParagraphStyleCreateCopy(style)
    _ = copy
    precondition(CTParagraphStyleGetTypeID() == 0x4354_5053)

    let tab = CTTextTabCreate(.right, 72, nil)
    precondition(CTTextTabGetAlignment(tab) == .right)
    precondition(CTTextTabGetLocation(tab) == 72)
    precondition(CTTextTabGetOptions(tab) == nil)
    precondition(CTTextTabGetTypeID() == 0x4354_5442)

    let ruby = CTRubyAnnotationCreateWithAttributes(
        .center,
        .auto,
        .before,
        ctCFString("ル"),
        nil
    )
    precondition(CTRubyAnnotationGetAlignment(ruby) == .center)
    precondition(CTRubyAnnotationGetOverhang(ruby) == .auto)
    precondition(CTRubyAnnotationGetTextForPosition(ruby, .before).map { ctString($0) } == "ル")
    let rubyCopy = CTRubyAnnotationCreateCopy(ruby)
    precondition(CTRubyAnnotationGetSizeFactor(rubyCopy) == 0.5)
    precondition(CTRubyAnnotationGetTypeID() == 0x4354_5259)

    let font = CTFont(ctCFString("OpenUIKitPortable-Regular"), size: 12)
    let info = CTGlyphInfoCreateWithGlyphName(ctCFString("A"), font, ctCFString("A"))
    precondition(info != nil)
    precondition(CTGlyphInfoGetGlyphName(info!).map { ctString($0) } == "A")
    precondition(CTGlyphInfoGetCharacterCollection(info!) == .identityMapping)
    let cid = CTGlyphInfoCreateWithCharacterIdentifier(7, .adobeJapan1, ctCFString("漢"))
    precondition(CTGlyphInfoGetCharacterIdentifier(cid!) == 7)
    precondition(CTGlyphInfoGetTypeID() == 0x4354_4749)
}

func testRunDelegateAndStringKeys() {
    final class Box: @unchecked Sendable {
        var deallocated = false
    }
    let box = Box()
    let callbacks = CTRunDelegateCallbacks(
        version: CFIndex(kCTRunDelegateCurrentVersion),
        dealloc: { pointer in
            Unmanaged<Box>.fromOpaque(pointer).takeRetainedValue().deallocated = true
        },
        getAscent: { _ in 8 },
        getDescent: { _ in 2 },
        getWidth: { _ in 10 }
    )
    let unmanaged = Unmanaged.passRetained(box)
    do {
        let delegate = withUnsafePointer(to: callbacks) { pointer in
            CTRunDelegateCreate(pointer, unmanaged.toOpaque())
        }
        precondition(delegate != nil)
        precondition(CTRunDelegateGetRefCon(delegate!) == unmanaged.toOpaque())
        precondition(CTRunDelegateGetTypeID() == 0x4354_5244)
    }
    precondition(box.deallocated)

    precondition(ctString(kCTFontAttributeName) == "NSFont")
    precondition(ctString(kCTForegroundColorAttributeName) == "CTForegroundColor")
    precondition(ctString(kCTParagraphStyleAttributeName) == "NSParagraphStyle")
    precondition(ctString(kCTKernAttributeName) == "NSKern")
    precondition(ctString(kCTUnderlineStyleAttributeName) == "NSUnderline")
    precondition(ctString(kCTFontFamilyNameAttribute) == "NSFontFamilyAttribute")
    precondition(ctString(kCTFontNameAttribute) == "NSFontNameAttribute")
    precondition(ctString(kCTFontSizeAttribute) == "NSFontSizeAttribute")
    precondition(ctString(kCTRubyAnnotationAttributeName) == "CTRubyAnnotation")
    precondition(ctString(kCTTrackingAttributeName) == "CTTracking")
}

func testAttributedStringCoreTextExtensions() {
    precondition(AttributedString.TextAlignment.allCases.contains(.left))
    precondition(AttributedString.TextAlignment.center != .right)
    precondition(AttributedString.LineHeight.tight != .loose)
    precondition(AttributedString.LineHeight.normal != .variable)
    let exact = AttributedString.LineHeight.exact(points: 16)
    let leading = AttributedString.LineHeight.leading(increase: 2)
    let multiple = AttributedString.LineHeight.multiple(factor: 1.2)
    precondition(exact != leading)
    precondition(leading != multiple)
    precondition(AttributeScopes.CoreTextAttributes.LineHeightAttribute.name == "SwiftUI.Character.LineHeight")
    precondition(AttributeScopes.CoreTextAttributes.TextAlignmentAttribute.name == "SwiftUI.Character.TextAlignment")
    precondition(AttributeScopes.CoreTextAttributes.LineHeightAttribute.inheritedByAddedText)
    let encoded = try! JSONEncoder().encode(AttributedString.TextAlignment.left)
    let decoded = try! JSONDecoder().decode(AttributedString.TextAlignment.self, from: encoded)
    precondition(decoded == .left)
}

func testClassHashableAndInequality() {
    let a = CTFont(ctCFString("A"), size: 12)
    let b = CTFont(ctCFString("B"), size: 12)
    precondition(a != b)
    var hasher = Hasher()
    a.hash(into: &hasher)
    b.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(CTFontDescriptorCreateWithNameAndSize(ctCFString("A"), 12)
        != CTFontDescriptorCreateWithNameAndSize(ctCFString("B"), 12))
    let collectionA = CTFontCollectionCreateWithFontDescriptors(nil, nil)
    let collectionB = CTFontCollectionCreateWithFontDescriptors(nil, nil)
    precondition(collectionA != collectionB)
    precondition(CTCharacterCollection.adobeGB1 != .adobeCNS1)
    precondition(CTFontSymbolicTraits.boldTrait != .italicTrait)

    let string = NSAttributedString(string: "Hi")
    let typesetterA = CTTypesetterCreateWithAttributedString(string)
    let typesetterB = CTTypesetterCreateWithAttributedString(string)
    precondition(typesetterA != typesetterB)
    precondition(CTLineCreateWithAttributedString(string) != CTLineCreateWithAttributedString(string))
    let framesetterA = CTFramesetterCreateWithAttributedString(string)
    let framesetterB = CTFramesetterCreateWithAttributedString(string)
    precondition(framesetterA != framesetterB)
    let tabA = CTTextTabCreate(.left, 10, nil)
    let tabB = CTTextTabCreate(.left, 10, nil)
    precondition(tabA != tabB)
    let rubyA = CTRubyAnnotationCreateWithAttributes(.auto, .auto, .before, ctCFString("a"), nil)
    let rubyB = CTRubyAnnotationCreateWithAttributes(.auto, .auto, .before, ctCFString("a"), nil)
    precondition(rubyA != rubyB)
    let styleA = CTParagraphStyleCreate(nil, 0)
    let styleB = CTParagraphStyleCreate(nil, 0)
    precondition(styleA != styleB)
    var hasher2 = Hasher()
    typesetterA.hash(into: &hasher2)
    framesetterA.hash(into: &hasher2)
    tabA.hash(into: &hasher2)
    rubyA.hash(into: &hasher2)
    styleA.hash(into: &hasher2)
    _ = hasher2.finalize()
    _ = typesetterA.hashValue
    _ = framesetterA.hashValue
    _ = styleA.hashValue
    precondition(CTFontFormat.unrecognized != .trueType)
    precondition(CTFontManagerError.fileNotFound != .notRegistered)
    precondition(CTParagraphStyleSpecifier.alignment != .count)
    precondition(CTTextAlignment.left != .right)
    precondition(CTWritingDirection.natural != .leftToRight)
}
