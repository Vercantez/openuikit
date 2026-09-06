import CoreFoundation
import Foundation
import CoreText

func ctFixtureFontURL() -> URL {
    URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .appendingPathComponent("fixtures")
        .appendingPathComponent("OpenUIKitFixture-Regular.ttf")
}

func ctRegisterFixtureFont() -> URL {
    let url = ctFixtureFontURL()
    precondition(FileManager.default.fileExists(atPath: url.path))
    let result = ctRegister(url)
    precondition(result.0, "fixture register failed: \(String(describing: result.1))")
    return url
}

func testFixtureFontMetricsAndNames() {
    let url = ctRegisterFixtureFont()
    defer { _ = ctUnregister(url) }

    let font = CTFontCreateWithName(ctCFString("OpenUIKitFixture-Regular"), 10, nil)
    precondition(CTFontGetSize(font) == 10)
    precondition(CTFontGetUnitsPerEm(font) == 1000)
    precondition(CTFontGetAscent(font) == 8)
    precondition(CTFontGetDescent(font) == 2)
    precondition(CTFontGetLeading(font) == 0.9)
    precondition(CTFontGetCapHeight(font) == 7)
    precondition(CTFontGetXHeight(font) == 5)
    precondition(CTFontGetUnderlinePosition(font) == -0.75)
    precondition(CTFontGetUnderlineThickness(font) == 0.5)
    precondition(CTFontGetGlyphCount(font) == 8)
    precondition(ctString(CTFontCopyPostScriptName(font)) == "OpenUIKitFixture-Regular")
    precondition(ctString(CTFontCopyFamilyName(font)) == "OpenUIKit Fixture")
    precondition(ctString(CTFontCopyFullName(font)) == "OpenUIKit Fixture Regular")
    precondition(ctString(CTFontCopyDisplayName(font)) == "OpenUIKit Fixture Regular")
    precondition(CTFontCopyName(font, kCTFontStyleNameKey).map { ctString($0) } == "Regular")
    precondition(CTFontCopyName(font, kCTFontSubFamilyNameKey).map { ctString($0) } == "Regular")
    let named = CTFont(ctCFString("OpenUIKit Fixture"), size: 10)
    precondition(CTFontGetUnitsPerEm(named) == 1000)
    let fromFamily = CTFontCreateWithName(ctCFString("OpenUIKit Fixture"), 10, nil)
    precondition(CTFontGetGlyphCount(fromFamily) == 8)
    let sizeAttr = CTFontCopyAttribute(font, kCTFontSizeAttribute) as? NSNumber
    precondition(sizeAttr?.doubleValue == 10)
    let nameAttr = CTFontCopyAttribute(font, kCTFontNameAttribute).map {
        ctString(unsafeBitCast($0, to: CFString.self))
    }
    precondition(nameAttr == "OpenUIKitFixture-Regular")
    let urlAttr = CTFontCopyAttribute(font, kCTFontURLAttribute) as? URL
    precondition(urlAttr?.standardizedFileURL == url.standardizedFileURL)
    let traits = unsafeBitCast(CTFontCopyTraits(font), to: NSDictionary.self)
    let symbolic = traits[ctString(kCTFontSymbolicTrait)] as? NSNumber
    precondition(symbolic?.uint32Value == 0)
    let box = CTFontGetBoundingBox(font)
    precondition(box.width == 8)
    precondition(box.height == 8)
    precondition(font != CTFontCreateWithName(ctCFString("OpenUIKitFixture-Regular"), 12, nil))
    _ = font.hashValue
}

func testFixtureGlyphsAdvancesAndBounds() {
    let url = ctRegisterFixtureFont()
    defer { _ = ctUnregister(url) }
    let font = CTFontCreateWithName(ctCFString("OpenUIKitFixture-Regular"), 10, nil)

    let hello: [UniChar] = Array("Hello".utf16)
    var glyphs = [CGGlyph](repeating: 0, count: 5)
    let mapped = hello.withUnsafeBufferPointer { cbuf in
        glyphs.withUnsafeMutableBufferPointer { gbuf in
            CTFontGetGlyphsForCharacters(font, cbuf.baseAddress!, gbuf.baseAddress!, 5)
        }
    }
    precondition(mapped)
    precondition(glyphs == [3, 4, 5, 5, 6])

    var advances = [CGSize](repeating: .zero, count: 5)
    let total = glyphs.withUnsafeBufferPointer { gbuf in
        advances.withUnsafeMutableBufferPointer { abuf in
            CTFontGetAdvancesForGlyphs(font, .horizontal, gbuf.baseAddress!, abuf.baseAddress, 5)
        }
    }
    // Hand-computed: size/UPEM = 0.01; hmtx 700,500,250,250,550
    precondition(abs(total - 22.5) < 1e-9)
    precondition(advances[0].width == 7)
    precondition(advances[1].width == 5)
    precondition(advances[2].width == 2.5)
    precondition(advances[4].width == 5.5)

    var rects = [CGRect](repeating: .zero, count: 5)
    let union = glyphs.withUnsafeBufferPointer { gbuf in
        rects.withUnsafeMutableBufferPointer { rbuf in
            CTFontGetBoundingRectsForGlyphs(font, .horizontal, gbuf.baseAddress!, rbuf.baseAddress, 5)
        }
    }
    // H glyf (40,0,660,700) * 0.01
    precondition(abs(rects[0].origin.x - 0.4) < 1e-9)
    precondition(abs(rects[0].size.width - 6.2) < 1e-9)
    precondition(abs(rects[0].size.height - 7) < 1e-9)
    precondition(union.width > 0)
    precondition(abs(rects[2].size.width - 1.7) < 1e-9)

    let smileString = "\u{1F600}"
    let smileLine = CTLineCreateWithAttributedString(
        NSAttributedString(
            string: smileString,
            attributes: [NSAttributedString.Key(ctString(kCTFontAttributeName)): font]
        )
    )
    precondition(CTLineGetGlyphCount(smileLine) == 1)
    let smileRuns = ctNSArray(CTLineGetGlyphRuns(smileLine))
    let smileRun = smileRuns[0] as! CTRun
    var smileGlyphs = [CGGlyph](repeating: 0, count: 1)
    smileGlyphs.withUnsafeMutableBufferPointer { buf in
        CTRunGetGlyphs(smileRun, CFRange(location: 0, length: 1), buf.baseAddress!)
    }
    precondition(smileGlyphs[0] == 7)
    var smileAdvances = [CGSize](repeating: .zero, count: 1)
    CTRunGetAdvances(smileRun, CFRange(location: 0, length: 1), &smileAdvances)
    precondition(smileAdvances[0].width == 8)
}

func testFixtureFontTablesAndCmap12() {
    let url = ctRegisterFixtureFont()
    defer { _ = ctUnregister(url) }
    let font = CTFontCreateWithName(ctCFString("OpenUIKitFixture-Regular"), 10, nil)
    precondition(CTFontHasTable(font, CTFontTableTag(kCTFontTableHead)))
    precondition(CTFontHasTable(font, CTFontTableTag(kCTFontTableHhea)))
    precondition(CTFontHasTable(font, CTFontTableTag(kCTFontTableHmtx)))
    precondition(CTFontHasTable(font, CTFontTableTag(kCTFontTableCmap)))
    precondition(CTFontHasTable(font, CTFontTableTag(kCTFontTableGlyf)))
    precondition(CTFontHasTable(font, CTFontTableTag(kCTFontTableLoca)))
    precondition(CTFontHasTable(font, CTFontTableTag(kCTFontTableOS2)))
    precondition(CTFontHasTable(font, CTFontTableTag(kCTFontTableName)))
    precondition(CTFontHasTable(font, CTFontTableTag(kCTFontTablePost)))
    precondition(CTFontHasTable(font, CTFontTableTag(kCTFontTableGSUB)))
    precondition(CTFontHasTable(font, CTFontTableTag(kCTFontTableGPOS)))
    precondition(!CTFontHasTable(font, CTFontTableTag(kCTFontTableKern)))

    let head = CTFontCopyTable(font, CTFontTableTag(kCTFontTableHead), [])
    precondition(head != nil)
    let headBytes = unsafeBitCast(head!, to: NSData.self) as Data
    precondition(headBytes.count >= 16)
    precondition(headBytes[12] == 0x5F && headBytes[13] == 0x0F && headBytes[14] == 0x3C && headBytes[15] == 0xF5)

    let available = CTFontCopyAvailableTables(font, [])
    precondition(available != nil)
    let tags = ctNSArray(available!).compactMap { ($0 as? NSNumber)?.uint32Value }
    precondition(tags.contains(UInt32(kCTFontTableHead)))
    precondition(tags.contains(UInt32(kCTFontTableGSUB)))
    precondition(tags.contains(UInt32(kCTFontTableGPOS)))

    let charset = unsafeBitCast(CTFontCopyCharacterSet(font), to: NSCharacterSet.self)
    precondition(charset.characterIsMember(0x48))
    precondition(charset.characterIsMember(0x20))
    precondition(charset.characterIsMember(0x41))
}

func testFixtureFontDescriptorMatchingAndCollection() {
    let url = ctRegisterFixtureFont()
    defer { _ = ctUnregister(url) }

    let query = CTFontDescriptorCreateWithNameAndSize(ctCFString("OpenUIKitFixture-Regular"), 10)
    let matched = CTFontDescriptorCreateMatchingFontDescriptor(query, nil)
    precondition(matched != nil)
    let matchedName = CTFontDescriptorCopyAttribute(matched!, kCTFontNameAttribute).map {
        ctString(unsafeBitCast($0, to: CFString.self))
    }
    precondition(matchedName == "OpenUIKitFixture-Regular")
    let otherQuery = CTFontDescriptorCreateWithNameAndSize(ctCFString("OpenUIKitFixture-Regular"), 12)
    precondition(query != otherQuery)
    _ = query.hashValue
    let matches = CTFontDescriptorCreateMatchingFontDescriptors(query, nil)
    precondition(ctNSArray(matches!).count >= 1)

    let familyQuery = CTFontDescriptorCreateCopyWithFamily(
        CTFontDescriptorCreateWithNameAndSize(ctCFString("x"), 0),
        ctCFString("OpenUIKit Fixture")
    )
    let familyMatches = CTFontDescriptorCreateMatchingFontDescriptors(familyQuery, nil)
    precondition(ctNSArray(familyMatches!).count >= 1)

    let collection = CTFontCollectionCreateFromAvailableFonts(nil)
    _ = collection.hashValue
    let otherCollection = CTFontCollectionCreateFromAvailableFonts(nil)
    precondition(collection != otherCollection)
    let listed = CTFontCollectionCreateMatchingFontDescriptors(collection)
    let names = ctNSArray(listed!).compactMap { desc -> String? in
        guard let desc = desc as? CTFontDescriptor else { return nil }
        return CTFontDescriptorCopyAttribute(desc, kCTFontNameAttribute).map {
            ctString(unsafeBitCast($0, to: CFString.self))
        }
    }
    precondition(names.contains("OpenUIKitFixture-Regular"))

    let registered = ctNSArray(CTFontManagerCopyRegisteredFontDescriptors(.process, true))
    precondition(registered.count >= 1)
    let families = ctNSArray(CTFontManagerCopyAvailableFontFamilyNames())
    precondition(families.contains("OpenUIKit Fixture"))
    let posts = ctNSArray(CTFontManagerCopyAvailablePostScriptNames())
    precondition(posts.contains("OpenUIKitFixture-Regular"))

    let fromURL = CTFontManagerCreateFontDescriptorsFromURL(ctCFURL(url))
    precondition(fromURL != nil)
    let fromURLName = CTFontDescriptorCopyAttribute(
        ctNSArray(fromURL!)[0] as! CTFontDescriptor,
        kCTFontNameAttribute
    ).map { ctString(unsafeBitCast($0, to: CFString.self)) }
    precondition(fromURLName == "OpenUIKitFixture-Regular")

    let data = try! Data(contentsOf: url)
    let fromData = CTFontManagerCreateFontDescriptorFromData(ctCFData(data))
    precondition(fromData != nil)

    let created = CTFontCreateWithFontDescriptor(query, 10, nil)
    precondition(CTFontGetGlyphCount(created) == 8)
    let swiftInit = CTFont(query, size: 10)
    precondition(CTFontGetAscent(swiftInit) == 8)
    let identity = CGAffineTransform.identity
    let withMatrix = withUnsafePointer(to: identity) { pointer in
        CTFontCreateWithFontDescriptorAndOptions(query, 10, pointer, [.preferSystemFont])
    }
    precondition(CTFontGetMatrix(withMatrix).a == 1)
    let namedOptions = withUnsafePointer(to: identity) { pointer in
        CTFontCreateWithNameAndOptions(ctCFString("OpenUIKitFixture-Regular"), 10, pointer, [])
    }
    precondition(CTFontGetGlyphCount(namedOptions) == 8)
}

func testFixtureTypesetterLineRunAdvances() {
    let url = ctRegisterFixtureFont()
    defer { _ = ctUnregister(url) }
    let font = CTFontCreateWithName(ctCFString("OpenUIKitFixture-Regular"), 10, nil)
    let attributes: [NSAttributedString.Key: Any] = [
        NSAttributedString.Key(ctString(kCTFontAttributeName)): font
    ]
    let string = NSAttributedString(string: "Hello", attributes: attributes)
    let line = CTLineCreateWithAttributedString(string)
    var ascent: CGFloat = 0
    var descent: CGFloat = 0
    var leading: CGFloat = 0
    let width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading)
    precondition(abs(width - 22.5) < 1e-9)
    precondition(ascent == 8)
    precondition(descent == 2)
    precondition(abs(leading - 0.9) < 1e-9)
    precondition(CTLineGetGlyphCount(line) == 5)

    let offset2 = CTLineGetOffsetForStringIndex(line, 2, nil)
    precondition(offset2 == 12)
    let index = CTLineGetStringIndexForPosition(line, CGPoint(x: 13, y: 0))
    precondition(index == 2)

    let runs = ctNSArray(CTLineGetGlyphRuns(line))
    precondition(runs.count == 1)
    let run = runs[0] as! CTRun
    precondition(CTRunGetGlyphCount(run) == 5)
    let otherLine = CTLineCreateWithAttributedString(string)
    let otherRun = ctNSArray(CTLineGetGlyphRuns(otherLine))[0] as! CTRun
    precondition(run != otherRun)
    _ = run.hashValue
    _ = line.hashValue
    var advances = [CGSize](repeating: .zero, count: 5)
    CTRunGetAdvances(run, CFRange(location: 0, length: 0), &advances)
    precondition(advances[0].width == 7)
    precondition(advances[1].width == 5)
    var positions = [CGPoint](repeating: .zero, count: 5)
    CTRunGetPositions(run, CFRange(location: 0, length: 0), &positions)
    precondition(positions[0].x == 0)
    precondition(positions[1].x == 7)
    precondition(positions[2].x == 12)
    var glyphs = [CGGlyph](repeating: 0, count: 5)
    glyphs.withUnsafeMutableBufferPointer { buf in
        CTRunGetGlyphs(run, CFRange(location: 0, length: 0), buf.baseAddress!)
    }
    precondition(glyphs == [3, 4, 5, 5, 6])
    let attrs = unsafeBitCast(CTRunGetAttributes(run), to: NSDictionary.self)
    precondition(attrs[ctString(kCTFontAttributeName)] as? CTFont === font)

    let typesetter = CTTypesetterCreateWithAttributedString(string)
    _ = typesetter.hashValue
    let breakIndex = CTTypesetterSuggestLineBreak(typesetter, 0, 12)
    precondition(breakIndex == 2)
}

func testFixtureFramesetterLineBreakInRect() {
    let url = ctRegisterFixtureFont()
    defer { _ = ctUnregister(url) }
    let font = CTFontCreateWithName(ctCFString("OpenUIKitFixture-Regular"), 10, nil)
    let attributes: [NSAttributedString.Key: Any] = [
        NSAttributedString.Key(ctString(kCTFontAttributeName)): font
    ]
    let string = NSAttributedString(string: "AAA", attributes: attributes)
    let framesetter = CTFramesetterCreateWithAttributedString(string)
    let path = ctMakeRectPath(CGRect(x: 0, y: 0, width: 13, height: 40))
    let frame = CTFramesetterCreateFrame(
        framesetter,
        CFRange(location: 0, length: string.length),
        path,
        nil
    )
    let lines = ctNSArray(CTFrameGetLines(frame))
    precondition(lines.count == 2)
    let first = lines[0] as! CTLine
    precondition(CTLineGetGlyphCount(first) == 2)
    let otherFrame = CTFramesetterCreateFrame(
        framesetter,
        CFRange(location: 0, length: string.length),
        path,
        nil
    )
    precondition(frame != otherFrame)
    _ = frame.hashValue
    _ = framesetter.hashValue
    var ascent: CGFloat = 0
    let width = CTLineGetTypographicBounds(first, &ascent, nil, nil)
    precondition(width == 12)
    let visible = CTFrameGetVisibleStringRange(frame)
    precondition(visible.length == 3)
    var origins = [CGPoint](repeating: .zero, count: 2)
    origins.withUnsafeMutableBufferPointer { buf in
        CTFrameGetLineOrigins(frame, CFRange(location: 0, length: 0), buf.baseAddress!)
    }
    precondition(origins[0].y > origins[1].y)
    var fit = CFRange(location: 0, length: 0)
    let suggested = CTFramesetterSuggestFrameSizeWithConstraints(
        framesetter,
        CFRange(location: 0, length: 3),
        nil,
        CGSize(width: 13, height: 100),
        &fit
    )
    precondition(suggested.width == 12)
    precondition(fit.length == 3)
}

func testFixtureTruncationAndJustification() {
    let url = ctRegisterFixtureFont()
    defer { _ = ctUnregister(url) }
    let font = CTFontCreateWithName(ctCFString("OpenUIKitFixture-Regular"), 10, nil)
    let attributes: [NSAttributedString.Key: Any] = [
        NSAttributedString.Key(ctString(kCTFontAttributeName)): font
    ]
    let string = NSAttributedString(string: "Hello", attributes: attributes)
    let line = CTLineCreateWithAttributedString(string)
    let truncated = CTLineCreateTruncatedLine(line, 12, .end, nil)
    precondition(truncated != nil)
    precondition(CTLineGetGlyphCount(truncated!) == 2)
    var tAscent: CGFloat = 0
    let tWidth = CTLineGetTypographicBounds(truncated!, &tAscent, nil, nil)
    precondition(tWidth == 12)

    let justified = CTLineCreateJustifiedLine(line, 1, 30)
    precondition(justified != nil)
    var jAscent: CGFloat = 0
    let jWidth = CTLineGetTypographicBounds(justified!, &jAscent, nil, nil)
    precondition(abs(jWidth - 30) < 1e-9)
    let jRuns = ctNSArray(CTLineGetGlyphRuns(justified!))
    let jRun = jRuns[0] as! CTRun
    var jAdvances = [CGSize](repeating: .zero, count: 5)
    CTRunGetAdvances(jRun, CFRange(location: 0, length: 0), &jAdvances)
    // extra 7.5 distributed across 5 glyphs => +1.5 each; H 7+1.5=8.5
    precondition(abs(jAdvances[0].width - 8.5) < 1e-9)
}

func testLigatureCaretPositionsFailClosed() {
    let url = ctRegisterFixtureFont()
    defer { _ = ctUnregister(url) }
    let font = CTFontCreateWithName(ctCFString("OpenUIKitFixture-Regular"), 10, nil)
    var caret: CGFloat = 99
    let count = CTFontGetLigatureCaretPositions(font, 3, &caret, 4)
    precondition(count == 0)
    precondition(caret == 99)
    let portable = CTFont(ctCFString("OpenUIKitPortable-Regular"), size: 12)
    precondition(CTFontGetLigatureCaretPositions(portable, 65, nil, 0) == 0)
}

func testSwiftFontInitializers() {
    let named = CTFont(ctCFString("OpenUIKitPortable-Regular"), size: 12)
    precondition(CTFontGetSize(named) == 12)
    let descriptor = CTFontDescriptorCreateWithNameAndSize(ctCFString("OpenUIKitPortable-Regular"), 14)
    let fromDesc = CTFont(descriptor, size: 14)
    precondition(CTFontGetSize(fromDesc) == 14)
    let ui = CTFont(.system, size: 17)
    precondition(CTFontGetSize(ui) == 17)
    let forString = CTFont(font: named, string: ctCFString("A"), range: CFRange(location: 0, length: 1))
    precondition(CTFontGetSize(forString) == 12)
    let uiLang = CTFont(.label, size: 0, language: ctCFString("en"))
    precondition(CTFontGetSize(uiLang) == 10)
}

func testFontMatrixInitsScaleAdvancesAndBounds() {
    let url = ctRegisterFixtureFont()
    defer { _ = ctUnregister(url) }

    var scale = CGAffineTransform(a: 2, b: 0, c: 0, d: 2, tx: 0, ty: 0)
    let name = ctCFString("OpenUIKitFixture-Regular")
    let sized = CTFontCreateWithName(name, 10, &scale)
    let matrix = CTFontGetMatrix(sized)
    precondition(matrix.a == 2)
    precondition(matrix.d == 2)
    precondition(CTFontGetSize(sized) == 10)

    let hello: [UniChar] = Array("H".utf16)
    var glyphs = [CGGlyph](repeating: 0, count: 1)
    let mapped = hello.withUnsafeBufferPointer { cbuf in
        glyphs.withUnsafeMutableBufferPointer { gbuf in
            CTFontGetGlyphsForCharacters(sized, cbuf.baseAddress!, gbuf.baseAddress!, 1)
        }
    }
    precondition(mapped)
    precondition(glyphs[0] == 3)

    var advances = [CGSize](repeating: .zero, count: 1)
    let total = glyphs.withUnsafeBufferPointer { gbuf in
        advances.withUnsafeMutableBufferPointer { abuf in
            CTFontGetAdvancesForGlyphs(sized, .horizontal, gbuf.baseAddress!, abuf.baseAddress, 1)
        }
    }
    // Identity 10 pt H advance is 7; matrix.a = 2 → 14
    precondition(abs(total - 14) < 1e-9)
    precondition(abs(advances[0].width - 14) < 1e-9)

    var rects = [CGRect](repeating: .zero, count: 1)
    _ = glyphs.withUnsafeBufferPointer { gbuf in
        rects.withUnsafeMutableBufferPointer { rbuf in
            CTFontGetBoundingRectsForGlyphs(sized, .horizontal, gbuf.baseAddress!, rbuf.baseAddress, 1)
        }
    }
    // Identity H glyf (0.4, 0, 6.2, 7); doubled by matrix a/d
    precondition(abs(rects[0].origin.x - 0.8) < 1e-9)
    precondition(abs(rects[0].size.width - 12.4) < 1e-9)
    precondition(abs(rects[0].size.height - 14) < 1e-9)

    let attributed = NSAttributedString(
        string: "H",
        attributes: [NSAttributedString.Key(ctString(kCTFontAttributeName)): sized]
    )
    let line = CTLineCreateWithAttributedString(attributed)
    precondition(abs(CTLineGetTypographicBounds(line, nil, nil, nil) - 14) < 1e-9)

    let named = CTFont(name, transform: scale)
    precondition(CTFontGetMatrix(named).a == 2)
    precondition(CTFontGetSize(named) == 12)
    var namedGlyphs: [CGGlyph] = [3]
    var namedAdvances = [CGSize](repeating: .zero, count: 1)
    let namedTotal = namedGlyphs.withUnsafeBufferPointer { gbuf in
        namedAdvances.withUnsafeMutableBufferPointer { abuf in
            CTFontGetAdvancesForGlyphs(named, .horizontal, gbuf.baseAddress!, abuf.baseAddress, 1)
        }
    }
    // size 12, H hmtx 700 → 8.4 * matrix.a 2 = 16.8
    precondition(abs(namedTotal - 16.8) < 1e-9)

    let descriptor = CTFontDescriptorCreateWithNameAndSize(name, 10)
    let fromDescriptor = CTFont(descriptor, transform: scale)
    precondition(CTFontGetMatrix(fromDescriptor).a == 2)
    precondition(CTFontGetSize(fromDescriptor) == 10)
    var descAdvances = [CGSize](repeating: .zero, count: 1)
    let descTotal = namedGlyphs.withUnsafeBufferPointer { gbuf in
        descAdvances.withUnsafeMutableBufferPointer { abuf in
            CTFontGetAdvancesForGlyphs(fromDescriptor, .horizontal, gbuf.baseAddress!, abuf.baseAddress, 1)
        }
    }
    precondition(abs(descTotal - 14) < 1e-9)

    let identity = CTFontCreateWithName(name, 10, nil)
    precondition(CTFontGetMatrix(identity).a == 1)
    var identityAdvances = [CGSize](repeating: .zero, count: 1)
    let identityTotal = namedGlyphs.withUnsafeBufferPointer { gbuf in
        identityAdvances.withUnsafeMutableBufferPointer { abuf in
            CTFontGetAdvancesForGlyphs(identity, .horizontal, gbuf.baseAddress!, abuf.baseAddress, 1)
        }
    }
    precondition(abs(identityTotal - 7) < 1e-9)
}
