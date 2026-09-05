import Foundation

open class PDFAnnotation: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public weak var page: PDFPage?
    open var bounds: CGRect
    open var type: String?
    open var contents: String?
    open var userName: String?
    open var modificationDate: Date?
    open var color: PDFKitColor = .black
    open var font: PDFKitFont?
    open var fontColor: PDFKitColor?
    open var interiorColor: PDFKitColor?
    open var backgroundColor: PDFKitColor?
    open var alignment: PDFKitTextAlignment = .left
    public private(set) var paths: [PDFKitBezierPath]?
    open var border: PDFBorder?
    open var action: PDFAction?
    open var url: URL?
    open var destination: PDFDestination?
    open var popup: PDFAnnotation?
    open var shouldDisplay = true
    open var shouldPrint = true
    open var isHighlighted = false
    open var hasAppearanceStream: Bool { false }
    open var isActivatableTextField: Bool { widgetFieldType == .text && !isReadOnly }

    open var startPoint: CGPoint = .zero
    open var endPoint: CGPoint = .zero
    open var startLineStyle: PDFLineStyle = .none
    open var endLineStyle: PDFLineStyle = .none
    open var iconType: PDFTextAnnotationIconType = .comment
    open var markupType: PDFMarkupType = .highlight
    open var isOpen = false
    open var stampName: String?
    open var fieldName: String?
    open var widgetStringValue: String?
    open var widgetDefaultStringValue: String?
    open var widgetControlType: PDFWidgetControlType = .unknownControl
    open var widgetFieldType: PDFAnnotationWidgetSubtype = .text
    open var buttonWidgetState: PDFWidgetCellState = .offState
    open var buttonWidgetStateString = "Off"
    open var caption: String?
    open var choices: [String]?
    open var values: [String]?
    open var maximumLength: Int = 0
    open var hasComb = false
    open var isListChoice = false
    open var isPasswordField: Bool { false }
    open var isReadOnly = false
    open var isMultiline = false
    open var allowsToggleToOff = true
    open var radiosInUnison = false
    open var quadrilateralPoints: [NSValue]?

    private var storedValues: [String: Any] = [:]

    public init(
        bounds: CGRect,
        forType annotationType: PDFAnnotationSubtype,
        withProperties properties: [AnyHashable: Any]?
    ) {
        self.bounds = bounds
        self.type = annotationType.rawValue.hasPrefix("/")
            ? String(annotationType.rawValue.dropFirst())
            : annotationType.rawValue
        super.init()
        storedValues[PDFAnnotationKey.subtype.rawValue] = annotationType.rawValue
        storedValues[PDFAnnotationKey.rect.rawValue] = bounds
        if let properties {
            for (key, value) in properties {
                storedValues["\(key)"] = value
            }
        }
        applyMarkupType(from: annotationType)
    }

    public required init?(coder: NSCoder) {
        bounds = coder.decodeCGRect(forKey: "bounds")
        type = coder.decodeObject(of: NSString.self, forKey: "type") as String?
        contents = coder.decodeObject(of: NSString.self, forKey: "contents") as String?
        super.init()
    }

    open func encode(with coder: NSCoder) {
        coder.encode(bounds, forKey: "bounds")
        coder.encode(type as NSString?, forKey: "type")
        coder.encode(contents as NSString?, forKey: "contents")
    }

    open var annotationKeyValues: [AnyHashable: Any] { storedValues }

    open func value(forAnnotationKey key: PDFAnnotationKey) -> Any? {
        switch key {
        case .contents: return contents
        case .rect: return bounds
        case .subtype: return type.map { "/\($0)" } ?? storedValues[key.rawValue]
        case .color: return color
        default: return storedValues[key.rawValue]
        }
    }

    @discardableResult
    open func setValue(_ value: Any, forAnnotationKey key: PDFAnnotationKey) -> Bool {
        storedValues[key.rawValue] = value
        switch key {
        case .contents:
            contents = value as? String
        case .rect:
            if let rect = value as? CGRect { bounds = rect }
        case .subtype:
            if let name = value as? String {
                type = name.hasPrefix("/") ? String(name.dropFirst()) : name
            }
        case .color:
            if let colorValue = value as? PDFKitColor { color = colorValue }
        default:
            break
        }
        return true
    }

    @discardableResult
    open func setBoolean(_ value: Bool, forAnnotationKey key: PDFAnnotationKey) -> Bool {
        storedValues[key.rawValue] = value
        if key == .open { isOpen = value }
        return true
    }

    @discardableResult
    open func setRect(_ value: CGRect, forAnnotationKey key: PDFAnnotationKey) -> Bool {
        storedValues[key.rawValue] = value
        if key == .rect { bounds = value }
        return true
    }

    open func removeValue(forAnnotationKey key: PDFAnnotationKey) {
        storedValues.removeValue(forKey: key.rawValue)
        if key == .contents { contents = nil }
    }

    open func add(_ path: PDFKitBezierPath) {
        var current = paths ?? []
        current.append(path)
        paths = current
    }

    open func remove(_ path: PDFKitBezierPath) {
        paths = paths?.filter { $0 !== path }
    }

    #if canImport(CoreGraphics)
    open func draw(with box: PDFDisplayBox, in context: CGContext) {
        _ = box
        context.saveGState()
        context.setFillColor(red: 1, green: 1, blue: 0, alpha: 0.3)
        context.fill(bounds)
        if let border {
            context.setStrokeColor(red: 0, green: 0, blue: 0, alpha: 1)
            context.setLineWidth(border.lineWidth)
            context.stroke(bounds)
        }
        context.restoreGState()
    }
    #endif

    open class func lineStyle(fromName name: String) -> PDFLineStyle {
        switch name {
        case "Square": return .square
        case "Circle": return .circle
        case "Diamond": return .diamond
        case "OpenArrow": return .openArrow
        case "ClosedArrow": return .closedArrow
        default: return .none
        }
    }

    open class func name(for style: PDFLineStyle) -> String {
        switch style {
        case .none: return "None"
        case .square: return "Square"
        case .circle: return "Circle"
        case .diamond: return "Diamond"
        case .openArrow: return "OpenArrow"
        case .closedArrow: return "ClosedArrow"
        }
    }

    private func applyMarkupType(from subtype: PDFAnnotationSubtype) {
        switch subtype {
        case .highlight: markupType = .highlight
        case .strikeOut: markupType = .strikeOut
        case .underline: markupType = .underline
        default: break
        }
    }
}

private extension NSCoder {
    func decodeCGRect(forKey key: String) -> CGRect {
        let array = decodeObject(of: [NSArray.self, NSNumber.self], forKey: key) as? [NSNumber]
        guard let array, array.count == 4 else { return .zero }
        return CGRect(
            x: CGFloat(Double(truncating: array[0])),
            y: CGFloat(Double(truncating: array[1])),
            width: CGFloat(Double(truncating: array[2])),
            height: CGFloat(Double(truncating: array[3]))
        )
    }

    func encode(_ rect: CGRect, forKey key: String) {
        encode(
            [
                NSNumber(value: Double(rect.origin.x)),
                NSNumber(value: Double(rect.origin.y)),
                NSNumber(value: Double(rect.size.width)),
                NSNumber(value: Double(rect.size.height))
            ] as NSArray,
            forKey: key
        )
    }
}
