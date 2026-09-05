@_spi(PDFKitTesting) import PDFKit
import Foundation

// --- PDFKitFixtures.swift ---

func pdfkitExpect(_ condition: Bool, _ message: String) {
    if !condition {
        fputs("PDFKIT_RUNTIME_FAIL \(message)\n", stderr)
        exit(1)
    }
}

func pdfkitHashProbe<T: Hashable>(_ value: T) {
    _ = value.hashValue
    var hasher = Hasher()
    value.hash(into: &hasher)
    _ = hasher.finalize()
}

final class PDFFixtureBuilder {
    private var items: [(Int, Data)] = []

    func add(_ number: Int, _ body: String) {
        items.append((number, Data(body.utf8)))
    }

    func add(_ number: Int, _ body: Data) {
        items.append((number, body))
    }

    func finish(root: Int, info: Int? = nil, extraTrailer: String = "") -> Data {
        var output = Data("%PDF-1.4\n".utf8)
        output.append(contentsOf: [0x25, 0xE2, 0xE3, 0xCF, 0xD3, 0x0A])
        let maxNumber = items.map(\.0).max() ?? 0
        var offsets = Array(repeating: 0, count: maxNumber + 1)
        var inUse = Array(repeating: false, count: maxNumber + 1)
        for (number, body) in items {
            offsets[number] = output.count
            inUse[number] = true
            output.append(Data("\(number) 0 obj\n".utf8))
            output.append(body)
            if body.last != 0x0A { output.append(0x0A) }
            output.append(Data("endobj\n".utf8))
        }
        let xref = output.count
        var table = "xref\n0 \(maxNumber + 1)\n"
        table += "0000000000 65535 f \n"
        for number in 1...maxNumber {
            if inUse[number] {
                table += String(format: "%010d 00000 n \n", offsets[number])
            } else {
                table += "0000000000 00000 f \n"
            }
        }
        output.append(Data(table.utf8))
        var trailer = "trailer\n<< /Size \(maxNumber + 1) /Root \(root) 0 R"
        if let info {
            trailer += " /Info \(info) 0 R"
        }
        if !extraTrailer.isEmpty {
            trailer += " \(extraTrailer)"
        }
        trailer += " >>\nstartxref\n\(xref)\n%%EOF\n"
        output.append(Data(trailer.utf8))
        return output
    }
}

func pdfkitHelloStream(lengthAsRef: Bool = false, extraInStream: String = "") -> (Data, Int) {
    var body = "BT /F1 12 Tf 72 720 Td (Hello PDFKit) Tj ET"
    body += extraInStream
    let bodyData = Data(body.utf8)
    var stream = Data()
    if lengthAsRef {
        stream.append(Data("<< /Length 6 0 R >>\nstream\n".utf8))
    } else {
        stream.append(Data("<< /Length \(bodyData.count) >>\nstream\n".utf8))
    }
    stream.append(bodyData)
    stream.append(Data("\nendstream".utf8))
    return (stream, bodyData.count)
}

func pdfkitStandardPageTree(
    builder: PDFFixtureBuilder,
    contents: Data,
    inheritBoxes: Bool = false,
    extraPage: String = ""
) {
    builder.add(1, "<< /Title (Runtime Probe) /Producer (OpenUIKit PDFKit) /Author (Depth Pass) >>")
    builder.add(2, "<< /Type /Catalog /Pages 3 0 R >>")
    if inheritBoxes {
        builder.add(
            3,
            "<< /Type /Pages /Kids [4 0 R] /Count 1 /MediaBox [0 0 200 300] /Rotate 90 /Resources << /Font << /F1 << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> >> /ProcSet [/PDF /Text] >> >>"
        )
        builder.add(4, "<< /Type /Page /Parent 3 0 R /Contents 5 0 R \(extraPage)>>")
    } else {
        builder.add(3, "<< /Type /Pages /Kids [4 0 R] /Count 1 >>")
        builder.add(
            4,
            "<< /Type /Page /Parent 3 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> >> >> /Contents 5 0 R \(extraPage)>>"
        )
    }
    builder.add(5, contents)
}

func pdfkitValidHelloPDF() -> Data {
    let builder = PDFFixtureBuilder()
    let (stream, _) = pdfkitHelloStream()
    pdfkitStandardPageTree(builder: builder, contents: stream)
    return builder.finish(root: 2, info: 1)
}

func pdfkitCommittedFixtureURL(_ name: String) -> URL {
    URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("fixtures")
        .appendingPathComponent(name)
}

func pdfkitRequireCommittedFixture(_ name: String) -> Data {
    let url = pdfkitCommittedFixtureURL(name)
    guard let data = try? Data(contentsOf: url) else {
        pdfkitExpect(false, "missing committed fixture \(name)")
        return Data()
    }
    return data
}

func pdfkitMakeTempRoot() -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("pdfkit-depth-\(UUID().uuidString)", isDirectory: true)
    try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

// --- PDFKitEnumTests.swift ---

func testAccessPermissionsRawValues() {
    pdfkitExpect(PDFAccessPermissions.allowsLowQualityPrinting.rawValue == 1 << 0, "low print")
    pdfkitExpect(PDFAccessPermissions.allowsHighQualityPrinting.rawValue == 1 << 1, "high print")
    pdfkitExpect(PDFAccessPermissions.allowsDocumentChanges.rawValue == 1 << 2, "changes")
    pdfkitExpect(PDFAccessPermissions.allowsDocumentAssembly.rawValue == 1 << 3, "assembly")
    pdfkitExpect(PDFAccessPermissions.allowsContentCopying.rawValue == 1 << 4, "copy")
    pdfkitExpect(PDFAccessPermissions.allowsContentAccessibility.rawValue == 1 << 5, "a11y")
    pdfkitExpect(PDFAccessPermissions.allowsCommenting.rawValue == 1 << 6, "comment")
    pdfkitExpect(PDFAccessPermissions.allowsFormFieldEntry.rawValue == 1 << 7, "form")
    let combined = PDFAccessPermissions(rawValue: (1 << 0) | (1 << 6))
    pdfkitExpect(combined.contains(.allowsLowQualityPrinting), "combined low")
    pdfkitExpect(combined.contains(.allowsCommenting), "combined comment")
    pdfkitExpect(combined != .allowsCommenting, "permissions !=")
    pdfkitHashProbe(PDFAccessPermissions.allowsContentCopying)
    _ = PDFAccessPermissions.allowsCommenting
}

func testActionNamedNameRawValues() {
    pdfkitExpect(PDFActionNamedName.none.rawValue == 0, "none")
    pdfkitExpect(PDFActionNamedName.nextPage.rawValue == 1, "next")
    pdfkitExpect(PDFActionNamedName.previousPage.rawValue == 2, "prev")
    pdfkitExpect(PDFActionNamedName.firstPage.rawValue == 3, "first")
    pdfkitExpect(PDFActionNamedName.lastPage.rawValue == 4, "last")
    pdfkitExpect(PDFActionNamedName.goBack.rawValue == 5, "back")
    pdfkitExpect(PDFActionNamedName.goForward.rawValue == 6, "forward")
    pdfkitExpect(PDFActionNamedName.goToPage.rawValue == 7, "goto")
    pdfkitExpect(PDFActionNamedName.find.rawValue == 8, "find")
    pdfkitExpect(PDFActionNamedName.print.rawValue == 9, "print")
    pdfkitExpect(PDFActionNamedName.zoomIn.rawValue == 10, "zoomin")
    pdfkitExpect(PDFActionNamedName.zoomOut.rawValue == 11, "zoomout")
    pdfkitExpect(PDFActionNamedName(rawValue: 8) == .find, "raw init find")
    pdfkitExpect(PDFActionNamedName.nextPage != .previousPage, "named !=")
    pdfkitHashProbe(PDFActionNamedName.find)
}

func testAreaOfInterestOptionSetAlgebra() {
    var area = PDFAreaOfInterest()
    pdfkitExpect(area.isEmpty, "empty")
    area = PDFAreaOfInterest(rawValue: 1 << 0)
    pdfkitExpect(area.contains(.pageArea), "contains page")
    let fromLiteral: PDFAreaOfInterest = [.pageArea, .annotationArea]
    pdfkitExpect(fromLiteral.contains(.annotationArea), "array literal")
    _ = PDFAreaOfInterest([.textArea])
    pdfkitExpect(PDFAreaOfInterest.pageArea.union(.annotationArea).contains(.annotationArea), "union")
    pdfkitExpect(PDFAreaOfInterest.pageArea.intersection(.pageArea).contains(.pageArea), "intersection")
    pdfkitExpect(!PDFAreaOfInterest.pageArea.intersection(.textArea).contains(.textArea), "empty intersection")
    pdfkitExpect(
        PDFAreaOfInterest.pageArea.symmetricDifference(.annotationArea).contains(.annotationArea),
        "symmetricDifference"
    )
    pdfkitExpect(PDFAreaOfInterest.anyArea.contains(.pageArea), "any")
    pdfkitExpect(PDFAreaOfInterest.pageArea.isSubset(of: .anyArea), "subset")
    pdfkitExpect(PDFAreaOfInterest.anyArea.isSuperset(of: .pageArea), "superset")
    pdfkitExpect(PDFAreaOfInterest.pageArea.isStrictSubset(of: .anyArea), "strict subset")
    pdfkitExpect(PDFAreaOfInterest.anyArea.isStrictSuperset(of: .pageArea), "strict superset")
    pdfkitExpect(PDFAreaOfInterest.pageArea.isDisjoint(with: .textArea), "disjoint")
    pdfkitExpect(PDFAreaOfInterest.pageArea.subtracting(.pageArea).isEmpty, "subtracting")
    var mutable = PDFAreaOfInterest.pageArea
    mutable.formUnion(.linkArea)
    pdfkitExpect(mutable.contains(.linkArea), "formUnion")
    mutable.formIntersection(.pageArea)
    pdfkitExpect(!mutable.contains(.linkArea), "formIntersection")
    mutable.formSymmetricDifference(.annotationArea)
    pdfkitExpect(mutable.contains(.annotationArea), "formSymmetricDifference")
    mutable.subtract(.annotationArea)
    _ = mutable.insert(.controlArea)
    _ = mutable.remove(.controlArea)
    _ = mutable.update(with: .iconArea)
    pdfkitExpect(PDFAreaOfInterest.controlArea.rawValue != 0, "control")
    pdfkitExpect(PDFAreaOfInterest.iconArea.rawValue != 0, "icon")
    pdfkitExpect(PDFAreaOfInterest.imageArea.rawValue != 0, "image")
    pdfkitExpect(PDFAreaOfInterest.linkArea.rawValue != 0, "link")
    pdfkitExpect(PDFAreaOfInterest.popupArea.rawValue != 0, "popup")
    pdfkitExpect(PDFAreaOfInterest.textArea.rawValue != 0, "text")
    pdfkitExpect(PDFAreaOfInterest.textFieldArea.rawValue != 0, "text field")
    pdfkitExpect(PDFAreaOfInterest.pageArea != .annotationArea, "area !=")
}

func testDisplayAndLayoutEnumRawValues() {
    pdfkitExpect(PDFDisplayBox.mediaBox.rawValue == 0, "media")
    pdfkitExpect(PDFDisplayBox.cropBox.rawValue == 1, "crop")
    pdfkitExpect(PDFDisplayBox.bleedBox.rawValue == 2, "bleed")
    pdfkitExpect(PDFDisplayBox.trimBox.rawValue == 3, "trim")
    pdfkitExpect(PDFDisplayBox.artBox.rawValue == 4, "art")
    pdfkitExpect(PDFDisplayBox(rawValue: 0) == .mediaBox, "media init")
    pdfkitExpect(PDFDisplayBox.cropBox != .mediaBox, "box !=")
    pdfkitHashProbe(PDFDisplayBox.cropBox)

    pdfkitExpect(PDFDisplayDirection.vertical.rawValue == 0, "vertical")
    pdfkitExpect(PDFDisplayDirection.horizontal.rawValue == 1, "horizontal")
    pdfkitExpect(PDFDisplayDirection(rawValue: 1) == .horizontal, "dir init")
    pdfkitExpect(PDFDisplayDirection.vertical != .horizontal, "dir !=")
    pdfkitHashProbe(PDFDisplayDirection.horizontal)

    pdfkitExpect(PDFDisplayMode.singlePage.rawValue == 0, "single")
    pdfkitExpect(PDFDisplayMode.singlePageContinuous.rawValue == 1, "spc")
    pdfkitExpect(PDFDisplayMode.twoUp.rawValue == 2, "two")
    pdfkitExpect(PDFDisplayMode.twoUpContinuous.rawValue == 3, "tuc")
    pdfkitExpect(PDFDisplayMode(rawValue: 1) == .singlePageContinuous, "mode init")
    pdfkitExpect(PDFDisplayMode.twoUp != .singlePage, "mode !=")
    pdfkitHashProbe(PDFDisplayMode.twoUp)

    pdfkitExpect(PDFThumbnailLayoutMode.vertical.rawValue == 0, "thumb v")
    pdfkitExpect(PDFThumbnailLayoutMode.horizontal.rawValue == 1, "thumb h")
    pdfkitExpect(PDFThumbnailLayoutMode(rawValue: 0) == .vertical, "thumb init")
    pdfkitExpect(PDFThumbnailLayoutMode.vertical != .horizontal, "thumb !=")
    pdfkitHashProbe(PDFThumbnailLayoutMode.horizontal)

    pdfkitExpect(PDFInterpolationQuality.none.rawValue == 0, "iq none")
    pdfkitExpect(PDFInterpolationQuality.low.rawValue == 1, "iq low")
    pdfkitExpect(PDFInterpolationQuality.high.rawValue == 2, "iq high")
    pdfkitExpect(PDFInterpolationQuality(rawValue: 2) == .high, "iq init")
    pdfkitExpect(PDFInterpolationQuality.low != .high, "iq !=")
    pdfkitHashProbe(PDFInterpolationQuality.high)

    pdfkitExpect(PDFDocumentPermissions.none.rawValue == 0, "perms none")
    pdfkitExpect(PDFDocumentPermissions.user.rawValue == 1, "perms user")
    pdfkitExpect(PDFDocumentPermissions.owner.rawValue == 2, "perms owner")
    pdfkitExpect(PDFDocumentPermissions(rawValue: 1) == .user, "perms init")
    pdfkitExpect(PDFDocumentPermissions.user != .owner, "perms !=")
    pdfkitHashProbe(PDFDocumentPermissions.owner)

    pdfkitExpect(PDFSelectionGranularity.character.rawValue == 0, "gran char")
    pdfkitExpect(PDFSelectionGranularity.word.rawValue == 1, "gran word")
    pdfkitExpect(PDFSelectionGranularity.line.rawValue == 2, "gran line")
    pdfkitExpect(PDFSelectionGranularity(rawValue: 1) == .word, "gran init")
    pdfkitExpect(PDFSelectionGranularity.word != .line, "gran !=")
    pdfkitHashProbe(PDFSelectionGranularity.word)
}

func testBorderLineMarkupWidgetEnumRawValues() {
    pdfkitExpect(PDFBorderStyle.solid.rawValue == 0, "solid")
    pdfkitExpect(PDFBorderStyle.dashed.rawValue == 1, "dashed")
    pdfkitExpect(PDFBorderStyle.beveled.rawValue == 2, "beveled")
    pdfkitExpect(PDFBorderStyle.inset.rawValue == 3, "inset")
    pdfkitExpect(PDFBorderStyle.underline.rawValue == 4, "underline")
    pdfkitExpect(PDFBorderStyle(rawValue: 1) == .dashed, "border init")
    pdfkitExpect(PDFBorderStyle.solid != .dashed, "border !=")
    pdfkitHashProbe(PDFBorderStyle.dashed)

    pdfkitExpect(PDFLineStyle.none.rawValue == 0, "ls none")
    pdfkitExpect(PDFLineStyle.square.rawValue == 1, "ls square")
    pdfkitExpect(PDFLineStyle.circle.rawValue == 2, "ls circle")
    pdfkitExpect(PDFLineStyle.diamond.rawValue == 3, "ls diamond")
    pdfkitExpect(PDFLineStyle.openArrow.rawValue == 4, "ls open")
    pdfkitExpect(PDFLineStyle.closedArrow.rawValue == 5, "ls closed")
    pdfkitExpect(PDFLineStyle(rawValue: 2) == .circle, "ls init")
    pdfkitExpect(PDFLineStyle.square != .circle, "ls !=")
    pdfkitHashProbe(PDFLineStyle.diamond)

    pdfkitExpect(PDFMarkupType.highlight.rawValue == 0, "mu hl")
    pdfkitExpect(PDFMarkupType.strikeOut.rawValue == 1, "mu strike")
    pdfkitExpect(PDFMarkupType.underline.rawValue == 2, "mu ul")
    pdfkitExpect(PDFMarkupType.redact.rawValue == 3, "mu redact")
    pdfkitExpect(PDFMarkupType(rawValue: 3) == .redact, "mu init")
    pdfkitExpect(PDFMarkupType.highlight != .redact, "mu !=")
    pdfkitHashProbe(PDFMarkupType.underline)

    pdfkitExpect(PDFTextAnnotationIconType.comment.rawValue == 0, "icon comment")
    pdfkitExpect(PDFTextAnnotationIconType.key.rawValue == 1, "icon key")
    pdfkitExpect(PDFTextAnnotationIconType.note.rawValue == 2, "icon note")
    pdfkitExpect(PDFTextAnnotationIconType.help.rawValue == 3, "icon help")
    pdfkitExpect(PDFTextAnnotationIconType.newParagraph.rawValue == 4, "icon np")
    pdfkitExpect(PDFTextAnnotationIconType.paragraph.rawValue == 5, "icon p")
    pdfkitExpect(PDFTextAnnotationIconType.insert.rawValue == 6, "icon insert")
    pdfkitExpect(PDFTextAnnotationIconType(rawValue: 0) == .comment, "icon init")
    pdfkitExpect(PDFTextAnnotationIconType.comment != .note, "icon !=")
    pdfkitHashProbe(PDFTextAnnotationIconType.help)

    pdfkitExpect(PDFWidgetCellState.mixedState.rawValue == -1, "mixed")
    pdfkitExpect(PDFWidgetCellState.offState.rawValue == 0, "off")
    pdfkitExpect(PDFWidgetCellState.onState.rawValue == 1, "on")
    pdfkitExpect(PDFWidgetCellState(rawValue: 0) == .offState, "cell init")
    pdfkitExpect(PDFWidgetCellState.onState != .offState, "cell !=")
    pdfkitHashProbe(PDFWidgetCellState.onState)

    pdfkitExpect(PDFWidgetControlType.unknownControl.rawValue == -1, "unknown")
    pdfkitExpect(PDFWidgetControlType.pushButtonControl.rawValue == 0, "push")
    pdfkitExpect(PDFWidgetControlType.radioButtonControl.rawValue == 1, "radio")
    pdfkitExpect(PDFWidgetControlType.checkBoxControl.rawValue == 2, "check")
    pdfkitExpect(PDFWidgetControlType(rawValue: 2) == .checkBoxControl, "widget init")
    pdfkitExpect(PDFWidgetControlType.radioButtonControl != .checkBoxControl, "widget !=")
    pdfkitHashProbe(PDFWidgetControlType.checkBoxControl)
}

func testTypedStringKeysAndDestinations() {
    pdfkitExpect(kPDFDestinationUnspecifiedValue < 0, "unspecified sentinel")
    pdfkitExpect(PDFDocumentFoundSelectionKey == "PDFDocumentFoundSelection", "found key")
    pdfkitExpect(PDFDocumentPageIndexKey == "PDFDocumentPageIndex", "page index key")

    pdfkitExpect(PDFDocumentAttribute.titleAttribute.rawValue == "Title", "title")
    pdfkitExpect(PDFDocumentAttribute.authorAttribute.rawValue == "Author", "author")
    pdfkitExpect(PDFDocumentAttribute.subjectAttribute.rawValue == "Subject", "subject")
    pdfkitExpect(PDFDocumentAttribute.creatorAttribute.rawValue == "Creator", "creator")
    pdfkitExpect(PDFDocumentAttribute.producerAttribute.rawValue == "Producer", "producer")
    pdfkitExpect(PDFDocumentAttribute.creationDateAttribute.rawValue == "CreationDate", "creation")
    pdfkitExpect(PDFDocumentAttribute.modificationDateAttribute.rawValue == "ModDate", "mod")
    pdfkitExpect(PDFDocumentAttribute.keywordsAttribute.rawValue == "Keywords", "keywords")
    pdfkitExpect(PDFDocumentAttribute(rawValue: "Title") == .titleAttribute, "attr init")
    pdfkitExpect(PDFDocumentAttribute.titleAttribute != .authorAttribute, "attr !=")
    pdfkitHashProbe(PDFDocumentAttribute.titleAttribute)

    pdfkitExpect(PDFDocumentWriteOption.ownerPasswordOption.rawValue.contains("OwnerPassword"), "owner")
    pdfkitExpect(PDFDocumentWriteOption.userPasswordOption.rawValue.contains("UserPassword"), "user")
    pdfkitExpect(PDFDocumentWriteOption.accessPermissionsOption.rawValue.contains("AccessPermissions"), "perms")
    pdfkitExpect(PDFDocumentWriteOption.burnInAnnotationsOption.rawValue.contains("BurnIn"), "burn")
    pdfkitExpect(PDFDocumentWriteOption.saveTextFromOCROption.rawValue.contains("OCR"), "ocr")
    pdfkitExpect(PDFDocumentWriteOption.saveImagesAsJPEGOption.rawValue.contains("JPEG"), "jpeg")
    pdfkitExpect(PDFDocumentWriteOption.optimizeImagesForScreenOption.rawValue.contains("Screen"), "screen")
    pdfkitExpect(PDFDocumentWriteOption(rawValue: "PDFDocumentOwnerPassword") == .ownerPasswordOption, "write init")
    pdfkitExpect(PDFDocumentWriteOption.ownerPasswordOption != .userPasswordOption, "write !=")
    pdfkitHashProbe(PDFDocumentWriteOption.userPasswordOption)

    pdfkitExpect(PDFPage.ImageInitializationOption.mediaBox.rawValue.contains("MediaBox"), "img media")
    pdfkitExpect(PDFPage.ImageInitializationOption.rotation.rawValue.contains("Rotation"), "img rot")
    pdfkitExpect(PDFPage.ImageInitializationOption.upscaleIfSmaller.rawValue.contains("Upscale"), "img up")
    pdfkitExpect(PDFPage.ImageInitializationOption.compressionQuality.rawValue.contains("Compression"), "img cq")
    pdfkitExpect(
        PDFPage.ImageInitializationOption(rawValue: "PDFPageImageInitializationOptionMediaBox") == .mediaBox,
        "img init"
    )
    pdfkitExpect(
        PDFPage.ImageInitializationOption.mediaBox != .rotation,
        "img !="
    )
    pdfkitHashProbe(PDFPage.ImageInitializationOption.rotation)

    pdfkitExpect(PDFBorderKey.lineWidth.rawValue == "/W", "border W")
    pdfkitExpect(PDFBorderKey.style.rawValue == "/S", "border S")
    pdfkitExpect(PDFBorderKey.dashPattern.rawValue == "/D", "border D")
    pdfkitExpect(PDFBorderKey(rawValue: "/W") == .lineWidth, "border key init")
    pdfkitExpect(PDFBorderKey.lineWidth != .style, "border key !=")
    pdfkitHashProbe(PDFBorderKey.style)

    pdfkitExpect(PDFAppearanceCharacteristicsKey.backgroundColor.rawValue == "/BG", "ack bg")
    pdfkitExpect(PDFAppearanceCharacteristicsKey.borderColor.rawValue == "/BC", "ack bc")
    pdfkitExpect(PDFAppearanceCharacteristicsKey.rotation.rawValue == "/R", "ack r")
    pdfkitExpect(PDFAppearanceCharacteristicsKey.caption.rawValue == "/CA", "ack ca")
    pdfkitExpect(PDFAppearanceCharacteristicsKey.rolloverCaption.rawValue == "/RC", "ack rc")
    pdfkitExpect(PDFAppearanceCharacteristicsKey.downCaption.rawValue == "/AC", "ack ac")
    pdfkitExpect(PDFAppearanceCharacteristicsKey(rawValue: "/CA") == .caption, "ack init")
    pdfkitExpect(PDFAppearanceCharacteristicsKey.caption != .downCaption, "ack !=")
    pdfkitHashProbe(PDFAppearanceCharacteristicsKey.caption)
}

func testNotificationNames() {
    pdfkitExpect(Notification.Name.PDFDocumentDidBeginFind.rawValue.contains("PDFDocumentDidBeginFind"), "begin find")
    pdfkitExpect(Notification.Name.PDFDocumentDidEndFind.rawValue.contains("PDFDocumentDidEndFind"), "end find")
    pdfkitExpect(Notification.Name.PDFDocumentDidBeginPageFind.rawValue.contains("BeginPageFind"), "begin page find")
    pdfkitExpect(Notification.Name.PDFDocumentDidEndPageFind.rawValue.contains("EndPageFind"), "end page find")
    pdfkitExpect(Notification.Name.PDFDocumentDidFindMatch.rawValue.contains("DidFindMatch"), "find match")
    pdfkitExpect(Notification.Name.PDFDocumentDidUnlock.rawValue.contains("DidUnlock"), "unlock")
    pdfkitExpect(Notification.Name.PDFDocumentDidBeginWrite.rawValue.contains("BeginWrite"), "begin write")
    pdfkitExpect(Notification.Name.PDFDocumentDidEndWrite.rawValue.contains("EndWrite"), "end write")
    pdfkitExpect(Notification.Name.PDFDocumentDidBeginPageWrite.rawValue.contains("BeginPageWrite"), "begin page write")
    pdfkitExpect(Notification.Name.PDFDocumentDidEndPageWrite.rawValue.contains("EndPageWrite"), "end page write")
    pdfkitExpect(Notification.Name.PDFViewDocumentChanged.rawValue.contains("PDFViewDocumentChanged"), "doc changed")
    pdfkitExpect(Notification.Name.PDFViewPageChanged.rawValue.contains("PDFViewPageChanged"), "page changed")
    pdfkitExpect(Notification.Name.PDFViewScaleChanged.rawValue.contains("ScaleChanged"), "scale")
    pdfkitExpect(Notification.Name.PDFViewSelectionChanged.rawValue.contains("SelectionChanged"), "sel")
    pdfkitExpect(Notification.Name.PDFViewDisplayBoxChanged.rawValue.contains("DisplayBox"), "box")
    pdfkitExpect(Notification.Name.PDFViewDisplayModeChanged.rawValue.contains("DisplayMode"), "mode")
    pdfkitExpect(Notification.Name.PDFViewChangedHistory.rawValue.contains("ChangedHistory"), "history")
    pdfkitExpect(Notification.Name.PDFViewVisiblePagesChanged.rawValue.contains("VisiblePages"), "visible")
    pdfkitExpect(Notification.Name.PDFViewCopyPermission.rawValue.contains("CopyPermission"), "copy")
    pdfkitExpect(Notification.Name.PDFViewPrintPermission.rawValue.contains("PrintPermission"), "print")
    pdfkitExpect(Notification.Name.PDFViewAnnotationHit.rawValue.contains("AnnotationHit"), "hit")
    pdfkitExpect(Notification.Name.PDFViewAnnotationWillHit.rawValue.contains("AnnotationWillHit"), "will hit")
    pdfkitExpect(Notification.Name.PDFThumbnailViewDocumentEdited.rawValue.contains("ThumbnailViewDocumentEdited"), "thumbs")
}

// --- PDFDocumentParseTests.swift ---

func testDocumentParseValidAndCommittedFixture() {
    let sampleData = pdfkitValidHelloPDF()
    pdfkitExpect(PDFKitTesting.parseStatus(sampleData) == "ok", "valid xref status")
    let sample = PDFDocument(data: sampleData)
    pdfkitExpect(sample != nil, "parse sample PDF")
    pdfkitExpect(sample?.pageCount == 1, "sample page count")
    pdfkitExpect(sample?.page(at: 0)?.bounds(for: .mediaBox).width == 612, "sample media box")
    pdfkitExpect(sample?.string?.contains("Hello PDFKit") == true, "extracted text")
    pdfkitExpect(sample?.majorVersion == 1 && sample?.minorVersion == 4, "version")

    let fixtureData = pdfkitRequireCommittedFixture("minimal.pdf")
    pdfkitExpect(PDFKitTesting.parseStatus(fixtureData) == "ok", "hand-written minimal.pdf status")
    let fixtureDoc = PDFDocument(data: fixtureData)
    pdfkitExpect(fixtureDoc != nil, "minimal.pdf init")
    pdfkitExpect(fixtureDoc?.pageCount == 1, "minimal.pdf page count")
    pdfkitExpect(fixtureDoc?.string?.contains("Hello PDFKit") == true, "minimal.pdf text")
    pdfkitExpect(fixtureDoc?.dataRepresentation() == fixtureData, "unmutated byte round-trip")
}

func testDocumentParseRejectsNonPDFAndBudgets() {
    pdfkitExpect(PDFKitTesting.parseStatus(Data("not a pdf".utf8)) == "notPDF", "not PDF")
    pdfkitExpect(PDFDocument(data: Data("not a pdf".utf8)) == nil, "init nil")

    var oversized = Data("%PDF-1.4\n".utf8)
    oversized.append(Data(repeating: 0x20, count: 8_000_001))
    pdfkitExpect(PDFKitTesting.parseStatus(oversized) == "budgetExceeded", "byte budget")

    let nestBuilder = PDFFixtureBuilder()
    let nested = String(repeating: "[", count: 40) + String(repeating: "]", count: 40)
    nestBuilder.add(1, nested)
    nestBuilder.add(2, "<< /Type /Catalog /Pages 3 0 R >>")
    nestBuilder.add(3, "<< /Type /Pages /Kids [] /Count 0 >>")
    pdfkitExpect(PDFKitTesting.parseStatus(nestBuilder.finish(root: 2)) == "budgetExceeded", "nesting budget")

    var objectBudget = Data("%PDF-1.4\n".utf8)
    objectBudget.append(Data("xref\n0 2000\ntrailer\n<< /Size 2000 /Root 1 0 R >>\nstartxref\n9\n%%EOF\n".utf8))
    pdfkitExpect(PDFKitTesting.parseStatus(objectBudget) == "budgetExceeded", "object-count budget")

    let cyclicBuilder = PDFFixtureBuilder()
    cyclicBuilder.add(2, "<< /Type /Catalog /Pages 3 0 R >>")
    cyclicBuilder.add(3, "<< /Type /Pages /Kids [3 0 R] /Count 1 >>")
    pdfkitExpect(PDFKitTesting.parseStatus(cyclicBuilder.finish(root: 2)) == "cycleDetected", "cyclic page tree")
}

func testDocumentParseIgnoresObjectsInsideStreams() {
    let fakeBuilder = PDFFixtureBuilder()
    let (fakeStream, _) = pdfkitHelloStream(
        extraInStream: "\n99 0 obj\n<< /Type /Page /Parent 3 0 R /MediaBox [0 0 10 10] >>\nendobj\n"
    )
    pdfkitStandardPageTree(builder: fakeBuilder, contents: fakeStream)
    let fakeData = fakeBuilder.finish(root: 2, info: 1)
    pdfkitExpect(PDFKitTesting.parseStatus(fakeData) == "ok", "stream-embedded obj status")
    let fakeDoc = PDFDocument(data: fakeData)
    pdfkitExpect(fakeDoc?.pageCount == 1, "obj tokens inside streams are not objects")
}

func testDocumentParseForwardIndirectLength() {
    let forwardBuilder = PDFFixtureBuilder()
    let (forwardStream, forwardLength) = pdfkitHelloStream(lengthAsRef: true)
    forwardBuilder.add(1, "<< /Title (Forward Length) >>")
    forwardBuilder.add(2, "<< /Type /Catalog /Pages 3 0 R >>")
    forwardBuilder.add(3, "<< /Type /Pages /Kids [4 0 R] /Count 1 >>")
    forwardBuilder.add(4, "<< /Type /Page /Parent 3 0 R /MediaBox [0 0 612 792] /Contents 5 0 R >>")
    forwardBuilder.add(5, forwardStream)
    forwardBuilder.add(6, "\(forwardLength)")
    let forwardData = forwardBuilder.finish(root: 2, info: 1)
    pdfkitExpect(PDFKitTesting.parseStatus(forwardData) == "ok", "forward length status")
    let forwardDoc = PDFDocument(data: forwardData)
    pdfkitExpect(forwardDoc?.string?.contains("Hello PDFKit") == true, "forward indirect /Length")
}

func testDocumentParseContentFilters() {
    let flateBuilder = PDFFixtureBuilder()
    flateBuilder.add(2, "<< /Type /Catalog /Pages 3 0 R >>")
    flateBuilder.add(3, "<< /Type /Pages /Kids [4 0 R] /Count 1 >>")
    flateBuilder.add(4, "<< /Type /Page /Parent 3 0 R /MediaBox [0 0 612 792] /Contents 5 0 R >>")
    let flatePayload = PDFKitTesting.flate(Data("BT /F1 12 Tf 72 720 Td (Hello PDFKit) Tj ET".utf8))
    var flateStream = Data("<< /Length \(flatePayload.count) /Filter /FlateDecode >>\nstream\n".utf8)
    flateStream.append(flatePayload)
    flateStream.append(Data("\nendstream".utf8))
    flateBuilder.add(5, flateStream)
    let flateData = flateBuilder.finish(root: 2)
    pdfkitExpect(PDFKitTesting.parseStatus(flateData) == "ok", "FlateDecode content stream")
    pdfkitExpect(PDFDocument(data: flateData)?.string?.contains("Hello PDFKit") == true, "FlateDecode extracted text")

    let hexBuilder = PDFFixtureBuilder()
    let hexPayload = PDFKitTesting.asciiHex(Data("BT /F1 12 Tf 72 720 Td (Hello PDFKit) Tj ET".utf8))
    hexBuilder.add(2, "<< /Type /Catalog /Pages 3 0 R >>")
    hexBuilder.add(3, "<< /Type /Pages /Kids [4 0 R] /Count 1 >>")
    hexBuilder.add(4, "<< /Type /Page /Parent 3 0 R /MediaBox [0 0 612 792] /Contents 5 0 R >>")
    var hexStream = Data("<< /Length \(hexPayload.count) /Filter /ASCIIHexDecode >>\nstream\n".utf8)
    hexStream.append(hexPayload)
    hexStream.append(Data("\nendstream".utf8))
    hexBuilder.add(5, hexStream)
    pdfkitExpect(PDFDocument(data: hexBuilder.finish(root: 2))?.string?.contains("Hello PDFKit") == true, "ASCIIHexDecode")

    let a85Builder = PDFFixtureBuilder()
    let a85Payload = PDFKitTesting.ascii85(Data("BT /F1 12 Tf 72 720 Td (Hello PDFKit) Tj ET".utf8))
    a85Builder.add(2, "<< /Type /Catalog /Pages 3 0 R >>")
    a85Builder.add(3, "<< /Type /Pages /Kids [4 0 R] /Count 1 >>")
    a85Builder.add(4, "<< /Type /Page /Parent 3 0 R /MediaBox [0 0 612 792] /Contents 5 0 R >>")
    var a85Stream = Data("<< /Length \(a85Payload.count) /Filter /ASCII85Decode >>\nstream\n".utf8)
    a85Stream.append(a85Payload)
    a85Stream.append(Data("\nendstream".utf8))
    a85Builder.add(5, a85Stream)
    pdfkitExpect(PDFDocument(data: a85Builder.finish(root: 2))?.string?.contains("Hello PDFKit") == true, "ASCII85Decode")

    let rlBuilder = PDFFixtureBuilder()
    let rlPayload = PDFKitTesting.runLength(Data("BT /F1 12 Tf 72 720 Td (Hello PDFKit) Tj ET".utf8))
    rlBuilder.add(2, "<< /Type /Catalog /Pages 3 0 R >>")
    rlBuilder.add(3, "<< /Type /Pages /Kids [4 0 R] /Count 1 >>")
    rlBuilder.add(4, "<< /Type /Page /Parent 3 0 R /MediaBox [0 0 612 792] /Contents 5 0 R >>")
    var rlStream = Data("<< /Length \(rlPayload.count) /Filter /RunLengthDecode >>\nstream\n".utf8)
    rlStream.append(rlPayload)
    rlStream.append(Data("\nendstream".utf8))
    rlBuilder.add(5, rlStream)
    pdfkitExpect(PDFDocument(data: rlBuilder.finish(root: 2))?.string?.contains("Hello PDFKit") == true, "RunLengthDecode")

    let unknownFilter = PDFFixtureBuilder()
    unknownFilter.add(2, "<< /Type /Catalog /Pages 3 0 R >>")
    unknownFilter.add(3, "<< /Type /Pages /Kids [4 0 R] /Count 1 >>")
    unknownFilter.add(4, "<< /Type /Page /Parent 3 0 R /MediaBox [0 0 612 792] /Contents 5 0 R >>")
    unknownFilter.add(5, "<< /Length 3 /Filter /UnknownDecode >>\nstream\nabc\nendstream")
    pdfkitExpect(PDFKitTesting.parseStatus(unknownFilter.finish(root: 2)) == "unsupportedFilter", "unknown filter")
}

func testDocumentParseXrefStream() {
    let content = Data("BT /F1 12 Tf 72 720 Td (Hello PDFKit) Tj ET".utf8)
    let objects: [(Int, Data)] = [
        (1, Data("<< /Type /Catalog /Pages 2 0 R >>".utf8)),
        (2, Data("<< /Type /Pages /Kids [3 0 R] /Count 1 >>".utf8)),
        (3, Data("<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> >> >> /Contents 4 0 R >>".utf8)),
        (4, {
            var stream = Data("<< /Length \(content.count) >>\nstream\n".utf8)
            stream.append(content)
            stream.append(Data("\nendstream".utf8))
            return stream
        }())
    ]
    var output = Data("%PDF-1.5\n".utf8)
    output.append(contentsOf: [0x25, 0xE2, 0xE3, 0xCF, 0xD3, 0x0A])
    var offsets = Array(repeating: 0, count: 6)
    for (number, body) in objects {
        offsets[number] = output.count
        output.append(Data("\(number) 0 obj\n".utf8))
        output.append(body)
        if body.last != 0x0A { output.append(0x0A) }
        output.append(Data("endobj\n".utf8))
    }
    var streamBytes = Data()
    for number in 1...5 {
        streamBytes.append(1)
        let offset = UInt16(offsets[number])
        streamBytes.append(UInt8(offset >> 8))
        streamBytes.append(UInt8(offset & 0xFF))
        streamBytes.append(0)
    }
    let xrefAt = output.count
    offsets[5] = xrefAt
    let object5Entry = 4 * 4
    streamBytes[object5Entry] = 1
    streamBytes[object5Entry + 1] = UInt8((UInt16(xrefAt) >> 8) & 0xFF)
    streamBytes[object5Entry + 2] = UInt8(UInt16(xrefAt) & 0xFF)
    streamBytes[object5Entry + 3] = 0
    var xrefObj = Data("5 0 obj\n<< /Type /XRef /Size 6 /W [1 2 1] /Index [1 5] /Root 1 0 R /Length \(streamBytes.count) >>\nstream\n".utf8)
    xrefObj.append(streamBytes)
    xrefObj.append(Data("\nendstream\nendobj\n".utf8))
    output.append(xrefObj)
    output.append(Data("startxref\n\(xrefAt)\n%%EOF\n".utf8))
    pdfkitExpect(PDFKitTesting.parseStatus(output) == "ok", "xref stream")
    pdfkitExpect(PDFDocument(data: output)?.string?.contains("Hello PDFKit") == true, "xref stream text")
}

// --- PDFDocumentTests.swift ---

func testDocumentAttributesAndPermissions() {
    let empty = PDFDocument()
    pdfkitExpect(empty.pageCount == 0, "empty document has no pages")
    pdfkitExpect(empty.allowsCopying, "unlocked document allows copying")
    pdfkitExpect(empty.accessPermissions.contains(.allowsCommenting), "accessPermissions bits")
    pdfkitExpect(empty.allowsPrinting, "unlocked document allows printing")
    pdfkitExpect(empty.allowsCommenting, "commenting")
    pdfkitExpect(empty.allowsContentAccessibility, "a11y")
    pdfkitExpect(empty.allowsDocumentAssembly, "assembly")
    pdfkitExpect(empty.allowsDocumentChanges, "changes")
    pdfkitExpect(empty.allowsFormFieldEntry, "form")
    pdfkitExpect(empty.permissionsStatus == .owner, "new document is owner-permissioned")
    pdfkitExpect(empty.majorVersion == 1 && empty.minorVersion == 4, "default version")
    pdfkitExpect(empty.unlock(withPassword: "secret") == false, "empty unlock fail-closed")
    pdfkitExpect(empty.documentURL == nil, "no url")
    pdfkitExpect(empty.isEncrypted == false, "not encrypted")
    pdfkitExpect(empty.isLocked == false, "not locked")
    pdfkitExpect(empty.isFinding == false, "not finding")
    _ = empty.delegate
    _ = empty.pageClass
    empty.documentAttributes = [
        PDFDocumentAttribute.titleAttribute: "In-memory",
        PDFDocumentAttribute.authorAttribute: "Agent",
        PDFDocumentAttribute.keywordsAttribute: ["pdf", "kit"]
    ]
    pdfkitExpect(empty.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String == "In-memory", "title")

    let sample = PDFDocument(data: pdfkitValidHelloPDF())
    pdfkitExpect(sample?.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String == "Runtime Probe", "info title")
    pdfkitExpect(sample?.documentAttributes?[PDFDocumentAttribute.producerAttribute] as? String == "OpenUIKit PDFKit", "producer")
}

func testDocumentPageTreeMutations() {
    let empty = PDFDocument()
    let page = PDFPage()
    pdfkitExpect(page.bounds(for: .mediaBox).width == 612, "default media box width")
    page.setBounds(CGRect(x: 0, y: 0, width: 400, height: 500), for: .mediaBox)
    page.setBounds(CGRect(x: 10, y: 10, width: 380, height: 480), for: .cropBox)
    empty.insert(page, at: 0)
    pdfkitExpect(empty.pageCount == 1, "inserted page")
    pdfkitExpect(empty.page(at: 0) === page, "page(at:) identity")
    pdfkitExpect(empty.index(for: page) == 0, "index(for:)")
    pdfkitExpect(page.label == "1", "page label")
    pdfkitExpect(page.document === empty, "page.document")
    pdfkitExpect(page.bounds(for: .cropBox).width == 380, "crop box")

    let second = PDFPage()
    empty.insert(second, at: 1)
    pdfkitExpect(empty.pageCount == 2, "second page")
    empty.exchangePage(at: 0, withPageAt: 1)
    pdfkitExpect(empty.page(at: 0) === second, "exchange")
    empty.removePage(at: 0)
    pdfkitExpect(empty.pageCount == 1, "remove page")
    pdfkitExpect(empty.page(at: 0) === page, "remaining page")
    pdfkitExpect(empty.page(at: 9) == nil, "out of range")
}

func testDocumentPageTreeInheritance() {
    let inheritBuilder = PDFFixtureBuilder()
    let (inheritStream, _) = pdfkitHelloStream()
    pdfkitStandardPageTree(builder: inheritBuilder, contents: inheritStream, inheritBoxes: true)
    let inherited = PDFDocument(data: inheritBuilder.finish(root: 2, info: 1))
    pdfkitExpect(inherited?.page(at: 0)?.bounds(for: .mediaBox).width == 200, "inherited MediaBox")
    pdfkitExpect(inherited?.page(at: 0)?.rotation == 90, "inherited Rotate")
    pdfkitExpect(PDFKitTesting.resourceKeyCount(for: inherited!.page(at: 0)!) >= 1, "inherited Resources")
    pdfkitExpect(inherited?.string?.contains("Hello PDFKit") == true, "inherited resources still extract")

    let fixture = pdfkitRequireCommittedFixture("inherited-boxes.pdf")
    let fromFixture = PDFDocument(data: fixture)
    pdfkitExpect(fromFixture?.page(at: 0)?.bounds(for: .mediaBox).width == 200, "fixture inherited MediaBox")
    pdfkitExpect(fromFixture?.page(at: 0)?.rotation == 90, "fixture inherited Rotate")
}

func testDocumentWriteRoundTripAndOptions() {
    let empty = PDFDocument()
    let page = PDFPage()
    empty.insert(page, at: 0)
    empty.documentAttributes = [PDFDocumentAttribute.titleAttribute: "In-memory"]
    let serialized = empty.dataRepresentation()
    pdfkitExpect(serialized != nil, "serialize in-memory document")
    pdfkitExpect(String(data: serialized!, encoding: .isoLatin1)?.hasPrefix("%PDF-") == true, "serialized header")
    pdfkitExpect(PDFKitTesting.parseStatus(serialized!) == "ok", "writer xref parses")
    let writerAgain = PDFDocument(data: serialized!)?.dataRepresentation()
    pdfkitExpect(serialized == writerAgain, "writer re-read byte identity")
    pdfkitExpect(empty.dataRepresentation(options: [:]) != nil, "empty options")

    let sample = PDFDocument(data: pdfkitValidHelloPDF())
    let tempRoot = pdfkitMakeTempRoot()
    defer { try? FileManager.default.removeItem(at: tempRoot) }
    let tempURL = tempRoot.appendingPathComponent("roundtrip.pdf")
    pdfkitExpect(sample?.write(to: tempURL) == true, "write(to:)")
    pdfkitExpect(sample?.write(toFile: tempURL.path) == true, "write(toFile:)")
    let fromURL = PDFDocument(url: tempURL)
    pdfkitExpect(fromURL?.pageCount == 1, "init(url:) page count")
    pdfkitExpect(fromURL?.documentURL == tempURL, "documentURL")
    pdfkitExpect(fromURL?.string?.contains("Hello PDFKit") == true, "url reload text")
    let fromURLAlias = PDFDocument(URL: tempURL)
    pdfkitExpect(fromURLAlias?.pageCount == 1, "init(URL:) alias")
    pdfkitExpect(fromURL?.write(to: tempURL, withOptions: [.ownerPasswordOption: "x"]) == false, "password write refused")
    pdfkitExpect(fromURL?.write(toFile: tempURL.path, withOptions: [.userPasswordOption: "x"]) == false, "file password refused")
    pdfkitExpect(fromURL?.dataRepresentation(options: [PDFDocumentWriteOption.userPasswordOption: "x"]) == nil, "password data refused")
    pdfkitExpect(fromURL?.dataRepresentation(options: [PDFDocumentWriteOption.burnInAnnotationsOption: true]) == nil, "burn-in refused")
    pdfkitExpect(fromURL?.dataRepresentation(options: [PDFDocumentWriteOption.saveTextFromOCROption: true]) == nil, "ocr refused")

    let fixtureData = pdfkitRequireCommittedFixture("minimal.pdf")
    let fixtureDoc = PDFDocument(data: fixtureData)
    pdfkitExpect(fixtureDoc?.dataRepresentation() == fixtureData, "committed fixture unmutated round-trip")
}

func testDocumentEncryptionTrailerAndStandardHandler() {
    let encryptBuilder = PDFFixtureBuilder()
    encryptBuilder.add(1, "<< /Title (Locked) >>")
    encryptBuilder.add(2, "<< /Type /Catalog /Pages 3 0 R >>")
    encryptBuilder.add(3, "<< /Type /Pages /Kids [4 0 R] /Count 1 >>")
    encryptBuilder.add(4, "<< /Type /Page /Parent 3 0 R /MediaBox [0 0 612 792] >>")
    encryptBuilder.add(9, "<< /Filter /Standard /V 1 /R 2 /P -4 >>")
    let encryptData = encryptBuilder.finish(root: 2, info: 1, extraTrailer: "/Encrypt 9 0 R")
    pdfkitExpect(PDFKitTesting.parseStatus(encryptData) == "encrypted", "trailer Encrypt")
    let locked = PDFDocument(data: encryptData)
    pdfkitExpect(locked?.isEncrypted == true, "encrypt flag")
    pdfkitExpect(locked?.isLocked == true, "locked flag")
    pdfkitExpect(locked?.unlock(withPassword: "secret") == false, "wrong password stays locked")
    pdfkitExpect(locked?.pageCount == 0, "encrypted content withheld until unlock")
    pdfkitExpect(locked?.dataRepresentation() == nil, "locked document does not write")
    let tempRoot = pdfkitMakeTempRoot()
    defer { try? FileManager.default.removeItem(at: tempRoot) }
    pdfkitExpect(locked?.write(to: tempRoot.appendingPathComponent("locked.pdf")) == false, "locked write fails")

    let catalogEncrypt = PDFFixtureBuilder()
    let (catalogStream, _) = pdfkitHelloStream()
    catalogEncrypt.add(1, "<< /Title (Not Encrypted) >>")
    catalogEncrypt.add(2, "<< /Type /Catalog /Pages 3 0 R /Encrypt 9 0 R >>")
    catalogEncrypt.add(3, "<< /Type /Pages /Kids [4 0 R] /Count 1 >>")
    catalogEncrypt.add(4, "<< /Type /Page /Parent 3 0 R /MediaBox [0 0 612 792] /Contents 5 0 R >>")
    catalogEncrypt.add(5, catalogStream)
    pdfkitExpect(
        PDFKitTesting.parseStatus(catalogEncrypt.finish(root: 2, info: 1)) == "ok",
        "Encrypt only in catalog is not trailer encryption"
    )

    let encryptInStream = PDFFixtureBuilder()
    let (encryptInStreamBody, _) = pdfkitHelloStream(extraInStream: "\n/Encrypt")
    pdfkitStandardPageTree(builder: encryptInStream, contents: encryptInStreamBody)
    pdfkitExpect(
        PDFKitTesting.parseStatus(encryptInStream.finish(root: 2, info: 1)) == "ok",
        "/Encrypt bytes outside the trailer dictionary are not encryption"
    )

    let encryptedData = PDFKitTesting.standardEncryptedHello(userPassword: "user")
    pdfkitExpect(PDFKitTesting.parseStatus(encryptedData) == "encrypted", "standard handler locked")
    let encryptedDoc = PDFDocument(data: encryptedData)
    pdfkitExpect(encryptedDoc?.isEncrypted == true, "standard encrypted")
    pdfkitExpect(encryptedDoc?.isLocked == true, "standard locked")
    pdfkitExpect(encryptedDoc?.unlock(withPassword: "wrong") == false, "wrong user password")
    pdfkitExpect(encryptedDoc?.unlock(withPassword: "user") == true, "user password Algorithm 6")
    pdfkitExpect(encryptedDoc?.isLocked == false, "unlocked")
    pdfkitExpect(encryptedDoc?.pageCount == 1, "pages after unlock")
    pdfkitExpect(encryptedDoc?.string?.contains("Hello PDFKit") == true, "decrypted text")
}

func testDocumentFindAndDelegate() {
    final class FindSpy: NSObject, PDFDocumentDelegate {
        var began = 0
        var ended = 0
        var matches = 0
        var unlocked = 0
        func didMatchString(_ instance: PDFSelection) {
            _ = instance
            matches += 1
        }
        func documentDidBeginDocumentFind(_ notification: Notification) {
            _ = notification
            began += 1
        }
        func documentDidEndDocumentFind(_ notification: Notification) {
            _ = notification
            ended += 1
        }
        func documentDidUnlock(_ notification: Notification) {
            _ = notification
            unlocked += 1
        }
    }

    let sample = PDFDocument(data: pdfkitValidHelloPDF())
    pdfkitExpect(sample != nil, "sample")
    let spy = FindSpy()
    sample?.delegate = spy
    let matches = sample?.findString("PDFKit", withOptions: []) ?? []
    pdfkitExpect(matches.count == 1, "findString count")
    pdfkitExpect(matches.first?.string?.contains("PDFKit") == true, "findString text")
    let nextFromMatch = sample?.findString("PDFKit", fromSelection: matches.first, withOptions: [])
    pdfkitExpect(nextFromMatch == nil, "no later PDFKit match")
    let ellMatches = sample?.findString("l", withOptions: []) ?? []
    pdfkitExpect(ellMatches.count >= 2, "multiple letter matches")
    let laterEll = sample?.findString("l", fromSelection: ellMatches.first, withOptions: [])
    pdfkitExpect(laterEll != nil, "find next on same page")
    pdfkitExpect(laterEll?.string == "l", "next match text")

    sample?.beginFindString("Hello", withOptions: [])
    pdfkitExpect(sample?.isFinding == false, "synchronous find finished")
    pdfkitExpect(spy.began == 1, "delegate begin")
    pdfkitExpect(spy.ended == 1, "delegate end")
    pdfkitExpect(spy.matches >= 1, "delegate match")
    sample?.beginFindStrings(["Hello"], withOptions: [])
    sample?.cancelFindString()
    pdfkitExpect(sample?.isFinding == false, "cancel")
    _ = spy.classForPage()
    _ = spy.class(forAnnotationType: "Highlight")
    spy.documentDidBeginPageFind(Notification(name: .PDFDocumentDidBeginPageFind))
    spy.documentDidEndPageFind(Notification(name: .PDFDocumentDidEndPageFind))
    spy.documentDidFindMatch(Notification(name: .PDFDocumentDidFindMatch))
}

// --- PDFPageTests.swift ---

func testPageBoundsRotationAndText() {
    let page = PDFPage()
    pdfkitExpect(page.bounds(for: .mediaBox).width == 612, "default media")
    pdfkitExpect(page.characterIndex(at: .zero) == NSNotFound, "empty char index")
    pdfkitExpect(page.characterBounds(at: 0) == .zero, "empty char bounds")
    page.setBounds(CGRect(x: 0, y: 0, width: 400, height: 500), for: .mediaBox)
    page.setBounds(CGRect(x: 10, y: 10, width: 380, height: 480), for: .cropBox)
    page.setBounds(CGRect(x: 5, y: 5, width: 390, height: 490), for: .bleedBox)
    page.setBounds(CGRect(x: 8, y: 8, width: 384, height: 484), for: .trimBox)
    page.setBounds(CGRect(x: 20, y: 20, width: 360, height: 460), for: .artBox)
    page.rotation = 90
    pdfkitExpect(page.bounds(for: .cropBox).width == 380, "crop")
    pdfkitExpect(page.bounds(for: .bleedBox).width == 390, "bleed")
    pdfkitExpect(page.bounds(for: .trimBox).width == 384, "trim")
    pdfkitExpect(page.bounds(for: .artBox).width == 360, "art")
    pdfkitExpect(page.rotation == 90, "rotation")
    page.displaysAnnotations = false
    pdfkitExpect(page.displaysAnnotations == false, "displaysAnnotations")

    let sample = PDFDocument(data: pdfkitValidHelloPDF())
    let samplePage = sample?.page(at: 0)
    pdfkitExpect(samplePage?.string?.contains("Hello PDFKit") == true, "page string")
    pdfkitExpect((samplePage?.numberOfCharacters ?? 0) > 0, "character count")
    _ = samplePage?.attributedString
    _ = samplePage?.dataRepresentation
    let thumb = samplePage?.thumbnail(of: CGSize(width: 32, height: 40), for: .mediaBox)
    pdfkitExpect(thumb?.size.width == 32, "thumbnail width")
    pdfkitExpect(thumb?.size.height == 40, "thumbnail height")

    let fixture = PDFDocument(data: pdfkitRequireCommittedFixture("minimal.pdf"))
    if let page = fixture?.page(at: 0) {
        pdfkitExpect(page.characterBounds(at: 0).width > 0, "character bounds from Tf 12")
        pdfkitExpect(page.bounds(for: .mediaBox).width == 612, "fixture media")
    }

    let imagePage = PDFPage(image: PDFKitImage(size: CGSize(width: 10, height: 10)))
    pdfkitExpect(imagePage != nil, "init(image:)")
    let optionPage = PDFPage(
        image: PDFKitImage(size: CGSize(width: 8, height: 8)),
        options: [
            .mediaBox: CGRect(x: 0, y: 0, width: 50, height: 60),
            .rotation: 180
        ]
    )
    pdfkitExpect(optionPage?.bounds(for: .mediaBox).width == 50, "image media option")
    pdfkitExpect(optionPage?.rotation == 180, "image rotation option")
}

func testPageAnnotationsAndSelection() {
    let document = PDFDocument()
    let page = PDFPage()
    document.insert(page, at: 0)
    let annotation = PDFAnnotation(
        bounds: CGRect(x: 10, y: 10, width: 80, height: 20),
        forType: .highlight,
        withProperties: nil
    )
    page.addAnnotation(annotation)
    pdfkitExpect(page.annotations.count == 1, "annotation attached")
    pdfkitExpect(page.annotation(at: CGPoint(x: 12, y: 12)) === annotation, "hit test")
    pdfkitExpect(annotation.page === page, "annotation.page")
    page.removeAnnotation(annotation)
    pdfkitExpect(page.annotations.isEmpty, "annotation removed")
    page.addAnnotation(annotation)

    let sample = PDFDocument(data: pdfkitValidHelloPDF())
    let samplePage = sample!.page(at: 0)!
    pdfkitExpect(samplePage.selection(for: NSRange(location: 0, length: 5))?.string != nil, "page range")
    pdfkitExpect(samplePage.selectionForWord(at: .zero)?.string != nil, "word selection")
    pdfkitExpect(samplePage.selectionForLine(at: .zero)?.string != nil, "line selection")
    pdfkitExpect(
        samplePage.selection(for: CGRect(x: 0, y: 0, width: 100, height: 100))?.string != nil,
        "rect selection"
    )
    pdfkitExpect(
        samplePage.selection(from: .zero, to: CGPoint(x: 10, y: 10))?.string != nil,
        "point selection"
    )
    pdfkitExpect(
        sample?.selection(
            from: samplePage,
            atCharacterIndex: 0,
            to: samplePage,
            atCharacterIndex: 5
        )?.string != nil,
        "document range selection"
    )
    _ = sample?.selection(from: samplePage, at: .zero, to: samplePage, at: CGPoint(x: 10, y: 10))
    _ = sample?.selection(
        from: samplePage,
        at: .zero,
        to: samplePage,
        at: CGPoint(x: 10, y: 10),
        with: .character
    )
    _ = sample?.selection(
        from: samplePage,
        at: .zero,
        to: samplePage,
        at: CGPoint(x: 10, y: 10),
        with: .word
    )
    _ = sample?.selection(
        from: samplePage,
        at: .zero,
        to: samplePage,
        at: CGPoint(x: 10, y: 10),
        with: .line
    )
    let entire = sample?.selectionForEntireDocument
    pdfkitExpect(entire?.string?.contains("Hello") == true, "entire document")
    entire?.extend(atEnd: 1)
    entire?.extend(atStart: 1)
    entire?.extendForLineBoundaries()
    _ = entire?.numberOfTextRanges(on: samplePage)
    _ = entire?.range(at: 0, on: samplePage)
    _ = entire?.selectionsByLine()
    _ = entire?.bounds(for: samplePage)
    _ = entire?.attributedString
    _ = entire?.pages
    entire?.color = .black
    entire?.draw(for: samplePage, active: true)
    entire?.draw(for: samplePage, with: .mediaBox, active: false)
    let extra = PDFSelection(document: sample!)
    extra.add(entire!)
    extra.add([entire!])
    _ = sample?.outlineItem(for: entire!)
}

// --- PDFAnnotationTests.swift ---

func testAnnotationSubtypeKeysAndSerialization() {
    pdfkitExpect(PDFAnnotation.name(for: .none) == "None", "name none")
    pdfkitExpect(PDFAnnotation.name(for: .square) == "Square", "name square")
    pdfkitExpect(PDFAnnotation.name(for: .circle) == "Circle", "name circle")
    pdfkitExpect(PDFAnnotation.name(for: .diamond) == "Diamond", "name diamond")
    pdfkitExpect(PDFAnnotation.name(for: .openArrow) == "OpenArrow", "name open")
    pdfkitExpect(PDFAnnotation.name(for: .closedArrow) == "ClosedArrow", "name closed")
    pdfkitExpect(PDFAnnotation.lineStyle(fromName: "Square") == .square, "from square")
    pdfkitExpect(PDFAnnotation.lineStyle(fromName: "Circle") == .circle, "from circle")
    pdfkitExpect(PDFAnnotation.lineStyle(fromName: "Diamond") == .diamond, "from diamond")
    pdfkitExpect(PDFAnnotation.lineStyle(fromName: "OpenArrow") == .openArrow, "from open")
    pdfkitExpect(PDFAnnotation.lineStyle(fromName: "ClosedArrow") == .closedArrow, "from closed")
    pdfkitExpect(PDFAnnotation.lineStyle(fromName: "Nope") == .none, "from none")

    pdfkitExpect(PDFAnnotationSubtype.text.rawValue == "/Text", "text")
    pdfkitExpect(PDFAnnotationSubtype.link.rawValue == "/Link", "link")
    pdfkitExpect(PDFAnnotationSubtype.freeText.rawValue == "/FreeText", "freetext")
    pdfkitExpect(PDFAnnotationSubtype.line.rawValue == "/Line", "line")
    pdfkitExpect(PDFAnnotationSubtype.square.rawValue == "/Square", "square")
    pdfkitExpect(PDFAnnotationSubtype.circle.rawValue == "/Circle", "circle")
    pdfkitExpect(PDFAnnotationSubtype.highlight.rawValue == "/Highlight", "highlight")
    pdfkitExpect(PDFAnnotationSubtype.underline.rawValue == "/Underline", "underline")
    pdfkitExpect(PDFAnnotationSubtype.strikeOut.rawValue == "/StrikeOut", "strike")
    pdfkitExpect(PDFAnnotationSubtype.ink.rawValue == "/Ink", "ink")
    pdfkitExpect(PDFAnnotationSubtype.stamp.rawValue == "/Stamp", "stamp")
    pdfkitExpect(PDFAnnotationSubtype.popup.rawValue == "/Popup", "popup")
    pdfkitExpect(PDFAnnotationSubtype.widget.rawValue == "/Widget", "widget")
    pdfkitExpect(PDFAnnotationSubtype(rawValue: "/Highlight") == .highlight, "subtype init")
    pdfkitExpect(PDFAnnotationSubtype.highlight != .underline, "subtype !=")
    pdfkitHashProbe(PDFAnnotationSubtype.link)

    pdfkitExpect(PDFAnnotationHighlightingMode.none.rawValue == "N", "hl none")
    pdfkitExpect(PDFAnnotationHighlightingMode.invert.rawValue == "I", "hl invert")
    pdfkitExpect(PDFAnnotationHighlightingMode.outline.rawValue == "O", "hl outline")
    pdfkitExpect(PDFAnnotationHighlightingMode.push.rawValue == "P", "hl push")
    pdfkitExpect(PDFAnnotationHighlightingMode(rawValue: "I") == .invert, "hl init")
    pdfkitExpect(PDFAnnotationHighlightingMode.none != .push, "hl !=")
    pdfkitHashProbe(PDFAnnotationHighlightingMode.invert)

    pdfkitExpect(PDFAnnotationLineEndingStyle.none.rawValue == "None", "le none")
    pdfkitExpect(PDFAnnotationLineEndingStyle.square.rawValue == "Square", "le square")
    pdfkitExpect(PDFAnnotationLineEndingStyle.circle.rawValue == "Circle", "le circle")
    pdfkitExpect(PDFAnnotationLineEndingStyle.diamond.rawValue == "Diamond", "le diamond")
    pdfkitExpect(PDFAnnotationLineEndingStyle.openArrow.rawValue == "OpenArrow", "le open")
    pdfkitExpect(PDFAnnotationLineEndingStyle.closedArrow.rawValue == "ClosedArrow", "le closed")
    pdfkitExpect(PDFAnnotationLineEndingStyle(rawValue: "Circle") == .circle, "le init")
    pdfkitExpect(PDFAnnotationLineEndingStyle.none != .square, "le !=")
    pdfkitHashProbe(PDFAnnotationLineEndingStyle.diamond)

    pdfkitExpect(PDFAnnotationTextIconType.comment.rawValue == "Comment", "tic comment")
    pdfkitExpect(PDFAnnotationTextIconType.key.rawValue == "Key", "tic key")
    pdfkitExpect(PDFAnnotationTextIconType.note.rawValue == "Note", "tic note")
    pdfkitExpect(PDFAnnotationTextIconType.help.rawValue == "Help", "tic help")
    pdfkitExpect(PDFAnnotationTextIconType.newParagraph.rawValue == "NewParagraph", "tic np")
    pdfkitExpect(PDFAnnotationTextIconType.paragraph.rawValue == "Paragraph", "tic p")
    pdfkitExpect(PDFAnnotationTextIconType.insert.rawValue == "Insert", "tic insert")
    pdfkitExpect(PDFAnnotationTextIconType(rawValue: "Note") == .note, "tic init")
    pdfkitExpect(PDFAnnotationTextIconType.comment != .key, "tic !=")
    pdfkitHashProbe(PDFAnnotationTextIconType.help)

    pdfkitExpect(PDFAnnotationWidgetSubtype.button.rawValue == "/Btn", "w btn")
    pdfkitExpect(PDFAnnotationWidgetSubtype.choice.rawValue == "/Ch", "w ch")
    pdfkitExpect(PDFAnnotationWidgetSubtype.signature.rawValue == "/Sig", "w sig")
    pdfkitExpect(PDFAnnotationWidgetSubtype.text.rawValue == "/Tx", "w tx")
    pdfkitExpect(PDFAnnotationWidgetSubtype(rawValue: "/Tx") == .text, "w init")
    pdfkitExpect(PDFAnnotationWidgetSubtype.button != .text, "w !=")
    pdfkitHashProbe(PDFAnnotationWidgetSubtype.choice)

    let keys: [PDFAnnotationKey] = [
        .appearanceDictionary, .appearanceState, .border, .color, .contents, .flags, .date, .name,
        .page, .rect, .subtype, .action, .additionalActions, .borderStyle, .defaultAppearance,
        .destination, .highlightingMode, .inklist, .interiorColor, .linePoints, .lineEndingStyles,
        .iconName, .open, .parent, .popup, .quadding, .quadPoints, .textLabel,
        .widgetDownCaption, .widgetBorderColor, .widgetBackgroundColor, .widgetCaption,
        .widgetDefaultValue, .widgetFieldFlags, .widgetFieldType, .widgetAppearanceDictionary,
        .widgetMaxLen, .widgetOptions, .widgetRotation, .widgetRolloverCaption,
        .widgetTextLabelUI, .widgetValue
    ]
    pdfkitExpect(keys.count == 42, "all annotation keys")
    pdfkitExpect(PDFAnnotationKey.subtype.rawValue == "/Subtype", "subtype key")
    pdfkitExpect(PDFAnnotationKey.contents.rawValue == "/Contents", "contents key")
    pdfkitExpect(PDFAnnotationKey.action.rawValue == "/A", "A")
    pdfkitExpect(PDFAnnotationKey(rawValue: "/C") == .color, "key init")
    pdfkitExpect(PDFAnnotationKey.color != .contents, "key !=")
    pdfkitHashProbe(PDFAnnotationKey.subtype)
}

func testAnnotationValueSemanticsAndCoding() {
    let highlight = PDFAnnotation(
        bounds: CGRect(x: 10, y: 10, width: 80, height: 20),
        forType: .highlight,
        withProperties: [PDFAnnotationKey.contents.rawValue: "seed"]
    )
    pdfkitExpect(highlight.markupType == .highlight, "highlight subtype")
    pdfkitExpect(highlight.type == "Highlight", "type string")
    pdfkitExpect(highlight.setValue("note", forAnnotationKey: .contents), "set contents")
    pdfkitExpect(highlight.value(forAnnotationKey: .contents) as? String == "note", "get contents")
    pdfkitExpect(highlight.setRect(CGRect(x: 1, y: 2, width: 3, height: 4), forAnnotationKey: .rect), "set rect")
    pdfkitExpect(highlight.bounds.width == 3, "rect assigned")
    pdfkitExpect(highlight.value(forAnnotationKey: .rect) as? CGRect == highlight.bounds, "get rect")
    highlight.setBoolean(true, forAnnotationKey: .open)
    pdfkitExpect(highlight.isOpen, "open flag")
    highlight.removeValue(forAnnotationKey: .contents)
    pdfkitExpect(highlight.contents == nil, "contents removed")
    _ = highlight.annotationKeyValues
    _ = highlight.hasAppearanceStream
    highlight.color = .black
    highlight.setValue(PDFKitColor.black, forAnnotationKey: .color)
    _ = highlight.value(forAnnotationKey: .color)
    highlight.font = PDFKitFont.systemFont(ofSize: 12)
    highlight.fontColor = .black
    highlight.interiorColor = .black
    highlight.backgroundColor = .white
    highlight.alignment = .left
    highlight.userName = "agent"
    highlight.modificationDate = Date(timeIntervalSince1970: 0)
    highlight.shouldDisplay = true
    highlight.shouldPrint = true
    highlight.isHighlighted = false
    highlight.startPoint = CGPoint(x: 1, y: 1)
    highlight.endPoint = CGPoint(x: 2, y: 2)
    highlight.startLineStyle = .openArrow
    highlight.endLineStyle = .closedArrow
    highlight.iconType = .note
    highlight.stampName = "Draft"
    highlight.fieldName = "field"
    highlight.widgetStringValue = "on"
    highlight.widgetDefaultStringValue = "off"
    highlight.widgetControlType = .checkBoxControl
    highlight.widgetFieldType = .button
    highlight.buttonWidgetState = .onState
    highlight.buttonWidgetStateString = "Yes"
    highlight.caption = "OK"
    highlight.choices = ["a", "b"]
    highlight.values = ["a"]
    highlight.maximumLength = 12
    highlight.hasComb = false
    highlight.isListChoice = false
    highlight.isReadOnly = false
    highlight.isMultiline = true
    pdfkitExpect(highlight.isMultiline, "multiline")
    highlight.allowsToggleToOff = true
    highlight.radiosInUnison = false
    highlight.url = URL(string: "https://example.com")
    highlight.action = PDFActionURL(url: URL(string: "https://example.com")!)
    let popup = PDFAnnotation(bounds: .zero, forType: .popup, withProperties: nil)
    highlight.popup = popup
    _ = highlight.isPasswordField
    _ = highlight.isActivatableTextField
    highlight.quadrilateralPoints = nil
    let inkPath = PDFKitBezierPath()
    highlight.add(inkPath)
    highlight.remove(inkPath)
    _ = highlight.paths

    let strike = PDFAnnotation(bounds: .zero, forType: .strikeOut, withProperties: nil)
    pdfkitExpect(strike.markupType == .strikeOut, "strike markup")
    let underline = PDFAnnotation(bounds: .zero, forType: .underline, withProperties: nil)
    pdfkitExpect(underline.markupType == .underline, "underline markup")

    let data = try! NSKeyedArchiver.archivedData(withRootObject: highlight, requiringSecureCoding: true)
    let decoded = try? NSKeyedUnarchiver.unarchivedObject(ofClass: PDFAnnotation.self, from: data)
    pdfkitExpect(decoded?.type == highlight.type, "secure coding type")
    pdfkitExpect(PDFAnnotation.supportsSecureCoding, "supportsSecureCoding")

    let border = PDFBorder()
    border.style = .dashed
    border.lineWidth = 2
    border.dashPattern = [2, 1]
    pdfkitExpect(border.borderKeyValues[PDFBorderKey.style.rawValue] as? Int == PDFBorderStyle.dashed.rawValue, "border keys")
    border.draw(in: CGRect(x: 0, y: 0, width: 10, height: 10))
    let borderData = try! NSKeyedArchiver.archivedData(withRootObject: border, requiringSecureCoding: true)
    let decodedBorder = try? NSKeyedUnarchiver.unarchivedObject(ofClass: PDFBorder.self, from: borderData)
    pdfkitExpect(decodedBorder?.lineWidth == 2, "border coding")
    pdfkitExpect(PDFBorder.supportsSecureCoding, "border supportsSecureCoding")
    highlight.border = border

    let appearance = PDFAppearanceCharacteristics()
    appearance.caption = "OK"
    appearance.rolloverCaption = "Go"
    appearance.downCaption = "Down"
    appearance.rotation = 90
    appearance.backgroundColor = .white
    appearance.borderColor = .black
    appearance.controlType = .pushButtonControl
    pdfkitExpect(
        appearance.appearanceCharacteristicsKeyValues[PDFAppearanceCharacteristicsKey.caption.rawValue] as? String == "OK",
        "appearance caption"
    )
}

// --- PDFOutlineDestinationTests.swift ---

func testActionsDestinationsAndOutlines() {
    let document = PDFDocument()
    let page = PDFPage()
    let other = PDFPage()
    document.insert(page, at: 0)
    document.insert(other, at: 1)

    let destination = PDFDestination(page: page, at: CGPoint(x: 0, y: 100))
    pdfkitExpect(destination.page === page, "dest page")
    pdfkitExpect(destination.point.y == 100, "dest point")
    destination.zoom = kPDFDestinationUnspecifiedValue
    let destAlias = PDFDestination(page: page, atPoint: CGPoint(x: 0, y: 100))
    pdfkitExpect(destAlias.point.y == 100, "atPoint alias")

    let destA = PDFDestination(page: page, at: CGPoint(x: 0, y: 200))
    let destB = PDFDestination(page: page, at: CGPoint(x: 0, y: 10))
    pdfkitExpect(destA.compare(destB) == .orderedAscending, "higher y first")
    let destC = PDFDestination(page: other, at: .zero)
    pdfkitExpect(destA.compare(destC) == .orderedAscending, "earlier page first")
    let destSame = PDFDestination(page: page, at: CGPoint(x: 0, y: 200))
    pdfkitExpect(destA.compare(destSame) == .orderedSame, "same dest")
    let destX = PDFDestination(page: page, at: CGPoint(x: 5, y: 200))
    pdfkitExpect(destA.compare(destX) == .orderedAscending, "smaller x first")

    let goTo = PDFActionGoTo(destination: destination)
    pdfkitExpect(goTo.type == "GoTo", "goto type")
    pdfkitExpect(goTo.destination === destination, "goto dest")
    let named = PDFActionNamed(name: .nextPage)
    pdfkitExpect(named.name == .nextPage, "named action")
    pdfkitExpect(named.type == "Named", "named type")
    let urlAction = PDFActionURL(url: URL(string: "https://example.com")!)
    pdfkitExpect(urlAction.url?.host == "example.com", "url action")
    pdfkitExpect(urlAction.type == "URI", "uri type")
    let urlAlias = PDFActionURL(URL: URL(string: "https://example.org")!)
    pdfkitExpect(urlAlias.url?.host == "example.org", "URL alias")
    let remote = PDFActionRemoteGoTo(
        pageIndex: 2,
        at: CGPoint(x: 1, y: 2),
        fileURL: URL(fileURLWithPath: "/tmp/other.pdf")
    )
    pdfkitExpect(remote.pageIndex == 2, "remote page")
    pdfkitExpect(remote.point.x == 1, "remote point")
    pdfkitExpect(remote.url.path.hasSuffix("other.pdf"), "remote url")
    pdfkitExpect(remote.type == "GoToR", "remote type")
    let remoteAlias = PDFActionRemoteGoTo(
        pageIndex: 1,
        atPoint: .zero,
        fileURL: URL(fileURLWithPath: "/tmp/x.pdf")
    )
    pdfkitExpect(remoteAlias.pageIndex == 1, "remote alias")
    let reset = PDFActionResetForm()
    reset.fields = ["a"]
    reset.fieldsIncludedAreCleared = false
    pdfkitExpect(reset.type == "ResetForm", "reset form")
    pdfkitExpect(PDFAction().type == "Action", "base action")

    let childOutline = PDFOutline()
    childOutline.label = "Section"
    childOutline.isOpen = true
    childOutline.action = named
    let outline = PDFOutline()
    outline.label = "Chapter 1"
    outline.destination = destination
    outline.insertChild(childOutline, at: 0)
    pdfkitExpect(outline.numberOfChildren == 1, "outline child")
    pdfkitExpect(outline.child(at: 0)?.label == "Section", "child label")
    pdfkitExpect(outline.child(at: 0)?.parent === outline, "parent")
    pdfkitExpect(childOutline.index == 0, "child index")
    pdfkitExpect(outline.child(at: 3) == nil, "missing child")
    document.outlineRoot = outline
    pdfkitExpect(document.outlineRoot?.label == "Chapter 1", "outline root")
    pdfkitExpect(document.outlineRoot?.document === document, "outline document")
    pdfkitExpect(document.outlineItem(for: document.selectionForEntireDocument!)?.label == "Chapter 1", "outline item for selection")
    childOutline.removeFromParent()
    pdfkitExpect(outline.numberOfChildren == 0, "removed child")
    outline.insertChild(childOutline, at: 0)

    let serialized = document.dataRepresentation()
    pdfkitExpect(serialized != nil, "write with outlines")
    let reloaded = PDFDocument(data: serialized!)
    pdfkitExpect(reloaded?.outlineRoot?.numberOfChildren == 1, "outline round trip children")
    pdfkitExpect(reloaded?.outlineRoot?.child(at: 0)?.label == "Section", "outline round trip label")

    let fixture = PDFDocument(data: pdfkitRequireCommittedFixture("outline.pdf"))
    pdfkitExpect(fixture?.outlineRoot?.numberOfChildren == 1, "committed outline children")
    pdfkitExpect(fixture?.outlineRoot?.child(at: 0)?.label == "Hello", "committed outline label")
}

// --- PDFViewTests.swift ---

final class PDFViewDelegateSpy: NSObject, PDFViewDelegate {
    var findCount = 0
    var goToPageCount = 0
    var openRemote = 0
    var clicked: URL?
    func pdfViewPerformFind(_ sender: PDFView) {
        _ = sender
        findCount += 1
    }
    func pdfViewPerformGo(toPage sender: PDFView) {
        _ = sender
        goToPageCount += 1
    }
    func pdfViewOpenPDF(_ sender: PDFView, forRemoteGoToAction action: PDFActionRemoteGoTo) {
        _ = sender
        _ = action
        openRemote += 1
    }
    func pdfViewWillClick(onLink sender: PDFView, with url: URL) {
        _ = sender
        clicked = url
    }
}

func testPDFViewAndThumbnailValueSemantics() {
    MainActor.assumeIsolated {
        let empty = PDFDocument()
        let page = PDFPage()
        page.setBounds(CGRect(x: 0, y: 0, width: 400, height: 500), for: .mediaBox)
        empty.insert(page, at: 0)
        let annotation = PDFAnnotation(
            bounds: CGRect(x: 10, y: 10, width: 80, height: 20),
            forType: .link,
            withProperties: nil
        )
        page.addAnnotation(annotation)

        let annotatedView = PDFView(frame: CGRect(x: 0, y: 0, width: 300, height: 400))
        annotatedView.document = empty
        pdfkitExpect(annotatedView.currentPage === page, "in-memory current page")
        pdfkitExpect(
            annotatedView.areaOfInterest(for: CGPoint(x: 12, y: 12)).contains(.annotationArea),
            "annotation area"
        )
        pdfkitExpect(annotatedView.areaOfInterest(forMouse: nil).contains(.pageArea), "mouse area")

        let sample = PDFDocument(data: pdfkitValidHelloPDF())
        let view = PDFView(frame: CGRect(x: 0, y: 0, width: 300, height: 400))
        let spy = PDFViewDelegateSpy()
        view.delegate = spy
        view.document = sample
        pdfkitExpect(view.currentPage != nil, "current page after assign")
        pdfkitExpect(view.canGoToNextPage == false, "single page cannot go next")
        pdfkitExpect(view.canGoToLastPage == false, "already last")
        pdfkitExpect(view.canGoToFirstPage == false, "already first")
        pdfkitExpect(view.canGoToPreviousPage == false, "no previous")
        pdfkitExpect(view.canZoomIn, "can zoom in")
        pdfkitExpect(view.canZoomOut, "default scale 1 is above minScaleFactor")
        view.zoomIn(nil)
        pdfkitExpect(view.scaleFactor > 1, "zoom in changes scale")
        pdfkitExpect(view.canZoomOut, "can zoom out after zoom in")
        view.zoomOut(nil)
        view.goToFirstPage(nil)
        view.perform(PDFActionNamed(name: .nextPage))
        view.perform(PDFActionNamed(name: .previousPage))
        view.perform(PDFActionNamed(name: .firstPage))
        view.perform(PDFActionNamed(name: .lastPage))
        view.perform(PDFActionNamed(name: .goBack))
        view.perform(PDFActionNamed(name: .goForward))
        view.perform(PDFActionNamed(name: .zoomIn))
        view.perform(PDFActionNamed(name: .zoomOut))
        view.perform(PDFActionNamed(name: .find))
        pdfkitExpect(spy.findCount == 1, "find delegate")
        view.perform(PDFActionNamed(name: .print))
        view.perform(PDFActionNamed(name: .goToPage))
        view.perform(PDFActionNamed(name: .none))
        if let current = view.currentPage {
            view.perform(PDFActionGoTo(destination: PDFDestination(page: current, at: .zero)))
        }
        view.perform(PDFActionURL(url: URL(string: "https://example.com")!))
        pdfkitExpect(spy.clicked?.host == "example.com", "url delegate")
        view.perform(
            PDFActionRemoteGoTo(pageIndex: 0, at: .zero, fileURL: URL(fileURLWithPath: "/tmp/x.pdf"))
        )
        pdfkitExpect(spy.openRemote == 1, "remote delegate")
        view.selectAll(nil)
        pdfkitExpect(view.currentSelection?.string?.contains("Hello") == true, "select all")
        view.setCurrentSelection(view.currentSelection, animate: false)
        view.scrollSelectionToVisible(nil)
        view.copy(nil)
        view.clearSelection()
        pdfkitExpect(view.currentSelection == nil, "clear selection")
        let converted = view.convert(CGPoint(x: 10, y: 20), from: view.currentPage!)
        pdfkitExpect(converted.x > 0, "convert from page")
        let back = view.convert(converted, to: view.currentPage!)
        pdfkitExpect(abs(back.x - 10) < 0.01, "convert to page")
        let convertedRect = view.convert(CGRect(x: 0, y: 0, width: 10, height: 10), from: view.currentPage!)
        pdfkitExpect(convertedRect.width > 0, "convert rect from")
        let backRect = view.convert(convertedRect, to: view.currentPage!)
        pdfkitExpect(backRect.width > 0, "convert rect to")
        pdfkitExpect(view.visiblePages.count == 1, "visible pages")
        pdfkitExpect(view.rowSize(for: view.currentPage!).width > 0, "row size")
        view.usePageViewController(true, withViewOptions: nil)
        pdfkitExpect(view.isUsingPageViewController, "page view controller flag")
        view.displayMode = .singlePageContinuous
        pdfkitExpect(view.visiblePages.count == 1, "continuous visible")
        view.displayMode = .twoUp
        view.displayMode = .twoUpContinuous
        view.displayBox = .mediaBox
        view.displayDirection = .horizontal
        view.displaysAsBook = true
        view.displaysPageBreaks = false
        view.displaysRTL = true
        view.enableDataDetectors = true
        view.interpolationQuality = .low
        view.pageShadowsEnabled = false
        view.isInMarkupMode = true
        view.isFindInteractionEnabled = true
        view.minScaleFactor = 0.5
        view.maxScaleFactor = 3
        view.highlightedSelections = view.currentSelection.map { [$0] }
        _ = view.currentDestination
        _ = view.canGoBack
        _ = view.canGoForward
        _ = view.pageBreakMargins
        view.pageBreakMargins = PDFKitEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        _ = view.backgroundColor
        view.backgroundColor = .white
        _ = view.documentView
        _ = view.findInteraction
        view.annotationsChanged(on: view.currentPage!)
        view.layoutDocumentView()
        view.autoScales = true
        pdfkitExpect(view.scaleFactorForSizeToFit > 0, "size to fit")
        view.goToLastPage(nil)
        view.goToNextPage(nil)
        view.goToPreviousPage(nil)
        view.goBack(nil)
        view.goForward(nil)
        if let current = view.currentPage {
            view.go(to: current)
            if let dest = view.currentDestination { view.go(to: dest) }
            if let selection = view.document?.selectionForEntireDocument {
                view.go(to: selection)
            }
            view.go(to: CGRect(x: 0, y: 0, width: 10, height: 10), on: current)
            _ = view.page(for: .zero, nearest: true)
            _ = view.page(for: CGPoint(x: 10_000, y: 10_000), nearest: false)
        }

        let thumbs = PDFThumbnailView(frame: .zero)
        thumbs.pdfView = view
        thumbs.layoutMode = .vertical
        thumbs.thumbnailSize = CGSize(width: 40, height: 50)
        thumbs.contentInset = PDFKitEdgeInsets.zero
        thumbs.backgroundColor = .white
        pdfkitExpect(thumbs.selectedPages?.count == 1, "thumbnail selection")
        thumbs.layoutMode = .horizontal
        pdfkitExpect(thumbs.layoutMode == .horizontal, "thumb layout")
        pdfkitExpect(thumbs.thumbnailSize.height == 50, "thumb size")

        spy.pdfViewPerformGo(toPage: view)
        pdfkitExpect(spy.goToPageCount == 1, "go to page delegate")
    }
}


func pdfkitRunFocusedTests() {
    testAccessPermissionsRawValues()
    testActionNamedNameRawValues()
    testAreaOfInterestOptionSetAlgebra()
    testDisplayAndLayoutEnumRawValues()
    testBorderLineMarkupWidgetEnumRawValues()
    testTypedStringKeysAndDestinations()
    testNotificationNames()
    testDocumentParseValidAndCommittedFixture()
    testDocumentParseRejectsNonPDFAndBudgets()
    testDocumentParseIgnoresObjectsInsideStreams()
    testDocumentParseForwardIndirectLength()
    testDocumentParseContentFilters()
    testDocumentParseXrefStream()
    testDocumentAttributesAndPermissions()
    testDocumentPageTreeMutations()
    testDocumentPageTreeInheritance()
    testDocumentWriteRoundTripAndOptions()
    testDocumentEncryptionTrailerAndStandardHandler()
    testDocumentFindAndDelegate()
    testPageBoundsRotationAndText()
    testPageAnnotationsAndSelection()
    testAnnotationSubtypeKeysAndSerialization()
    testAnnotationValueSemanticsAndCoding()
    testActionsDestinationsAndOutlines()
    testPDFViewAndThumbnailValueSemantics()
}

print("CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean")
pdfkitRunFocusedTests()
print("PDFKIT_AGENT_RUNTIME_OK")
