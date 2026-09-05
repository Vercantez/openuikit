@_spi(PDFKitTesting) import PDFKit
import Foundation

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
