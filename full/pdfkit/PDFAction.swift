import Foundation

open class PDFAction: NSObject {
    open var type: String { "Action" }

    public override init() {
        super.init()
    }
}

open class PDFActionGoTo: PDFAction {
    open var destination: PDFDestination

    public init(destination: PDFDestination) {
        self.destination = destination
        super.init()
    }

    open override var type: String { "GoTo" }
}

open class PDFActionNamed: PDFAction {
    open var name: PDFActionNamedName

    public init(name: PDFActionNamedName) {
        self.name = name
        super.init()
    }

    open override var type: String { "Named" }
}

open class PDFActionRemoteGoTo: PDFAction {
    open var pageIndex: Int
    open var point: CGPoint
    open var url: URL

    public init(pageIndex: Int, at point: CGPoint, fileURL url: URL) {
        self.pageIndex = pageIndex
        self.point = point
        self.url = url
        super.init()
    }

    public convenience init(pageIndex: Int, atPoint point: CGPoint, fileURL url: URL) {
        self.init(pageIndex: pageIndex, at: point, fileURL: url)
    }

    open override var type: String { "GoToR" }
}

open class PDFActionResetForm: PDFAction {
    open var fields: [String]?
    open var fieldsIncludedAreCleared = true

    public override init() {
        super.init()
    }

    open override var type: String { "ResetForm" }
}

open class PDFActionURL: PDFAction {
    open var url: URL?

    public init(url: URL) {
        self.url = url
        super.init()
    }

    public convenience init(URL url: URL) {
        self.init(url: url)
    }

    open override var type: String { "URI" }
}

open class PDFDestination: NSObject {
    public private(set) weak var page: PDFPage?
    public private(set) var point: CGPoint
    open var zoom: CGFloat = kPDFDestinationUnspecifiedValue

    public init(page: PDFPage, at point: CGPoint) {
        self.page = page
        self.point = point
        super.init()
    }

    public convenience init(page: PDFPage, atPoint point: CGPoint) {
        self.init(page: page, at: point)
    }

    open func compare(_ destination: PDFDestination) -> ComparisonResult {
        let leftPage = page.flatMap { $0.document?.index(for: $0) } ?? -1
        let rightPage = destination.page.flatMap { $0.document?.index(for: $0) } ?? -1
        if leftPage != rightPage {
            return leftPage < rightPage ? .orderedAscending : .orderedDescending
        }
        if point.y != destination.point.y {
            return point.y > destination.point.y ? .orderedAscending : .orderedDescending
        }
        if point.x != destination.point.x {
            return point.x < destination.point.x ? .orderedAscending : .orderedDescending
        }
        return .orderedSame
    }
}

open class PDFBorder: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    open var style: PDFBorderStyle = .solid
    open var lineWidth: CGFloat = 1
    open var dashPattern: [Any]?

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        style = PDFBorderStyle(rawValue: coder.decodeInteger(forKey: "style")) ?? .solid
        lineWidth = CGFloat(coder.decodeDouble(forKey: "lineWidth"))
        dashPattern = coder.decodeObject(forKey: "dashPattern") as? [Any]
        super.init()
    }

    open func encode(with coder: NSCoder) {
        coder.encode(style.rawValue, forKey: "style")
        coder.encode(Double(lineWidth), forKey: "lineWidth")
        coder.encode(dashPattern, forKey: "dashPattern")
    }

    open var borderKeyValues: [AnyHashable: Any] {
        var values: [AnyHashable: Any] = [
            PDFBorderKey.style.rawValue: style.rawValue,
            PDFBorderKey.lineWidth.rawValue: lineWidth
        ]
        if let dashPattern {
            values[PDFBorderKey.dashPattern.rawValue] = dashPattern
        }
        return values
    }

    open func draw(in rect: CGRect) {
        #if canImport(UIKit)
        UIGraphicsGetCurrentContext()?.setLineWidth(lineWidth)
        UIGraphicsGetCurrentContext()?.stroke(rect)
        #else
        _ = rect
        #endif
    }
}

open class PDFAppearanceCharacteristics: NSObject {
    open var backgroundColor: PDFKitColor?
    open var borderColor: PDFKitColor?
    open var rotation: Int = 0
    open var caption: String?
    open var rolloverCaption: String?
    open var downCaption: String?
    open var controlType: PDFWidgetControlType = .unknownControl

    public override init() {
        super.init()
    }

    open var appearanceCharacteristicsKeyValues: [AnyHashable: Any] {
        var values: [AnyHashable: Any] = [
            PDFAppearanceCharacteristicsKey.rotation.rawValue: rotation,
            "controlType": controlType.rawValue
        ]
        if let caption { values[PDFAppearanceCharacteristicsKey.caption.rawValue] = caption }
        if let rolloverCaption {
            values[PDFAppearanceCharacteristicsKey.rolloverCaption.rawValue] = rolloverCaption
        }
        if let downCaption {
            values[PDFAppearanceCharacteristicsKey.downCaption.rawValue] = downCaption
        }
        return values
    }
}
