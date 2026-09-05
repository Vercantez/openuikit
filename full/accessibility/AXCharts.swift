import Foundation

public protocol AXChart: NSObjectProtocol {
    var accessibilityChartDescriptor: AXChartDescriptor? { get set }
}

public protocol AXDataAxisDescriptor: NSCopying {
    var title: String { get set }
    var attributedTitle: NSAttributedString { get set }
}

public class AXCategoricalDataAxisDescriptor: NSObject, AXDataAxisDescriptor {
    private var _title: String
    private var _attributedTitle: NSAttributedString

    public var title: String {
        get { _title }
        set {
            _title = newValue
            _attributedTitle = NSAttributedString(string: newValue)
        }
    }
    public var attributedTitle: NSAttributedString {
        get { _attributedTitle }
        set {
            _attributedTitle = NSAttributedString(attributedString: newValue)
            _title = newValue.string
        }
    }
    public var categoryOrder: [String]

    public init(title: String, categoryOrder: [String]) {
        self._title = title
        self._attributedTitle = NSAttributedString(string: title)
        self.categoryOrder = categoryOrder
        super.init()
    }

    public init(attributedTitle: NSAttributedString, categoryOrder: [String]) {
        self._attributedTitle = NSAttributedString(attributedString: attributedTitle)
        self._title = attributedTitle.string
        self.categoryOrder = categoryOrder
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        AXCategoricalDataAxisDescriptor(
            attributedTitle: attributedTitle,
            categoryOrder: categoryOrder
        )
    }
}

public class AXNumericDataAxisDescriptor: NSObject, AXDataAxisDescriptor {
    public enum ScaleType: Int, Equatable, Hashable, Sendable {
        case linear = 0
        case log10 = 1
        case ln = 2
    }

    private var _title: String
    private var _attributedTitle: NSAttributedString

    public var title: String {
        get { _title }
        set {
            _title = newValue
            _attributedTitle = NSAttributedString(string: newValue)
        }
    }
    public var attributedTitle: NSAttributedString {
        get { _attributedTitle }
        set {
            _attributedTitle = NSAttributedString(attributedString: newValue)
            _title = newValue.string
        }
    }
    public var scaleType: ScaleType
    public var range: ClosedRange<Double>
    public var gridlinePositions: [Double]
    public var valueDescriptionProvider: (Double) -> String

    public convenience init(
        title: String,
        range: ClosedRange<Double>,
        gridlinePositions: [Double],
        valueDescriptionProvider: @escaping (Double) -> String
    ) {
        self.init(
            attributedTitle: NSAttributedString(string: title),
            range: range,
            gridlinePositions: gridlinePositions,
            valueDescriptionProvider: valueDescriptionProvider
        )
    }

    public init(
        attributedTitle: NSAttributedString,
        range: ClosedRange<Double>,
        gridlinePositions: [Double],
        valueDescriptionProvider: @escaping (Double) -> String
    ) {
        self._attributedTitle = NSAttributedString(attributedString: attributedTitle)
        self._title = attributedTitle.string
        self.range = range
        self.gridlinePositions = gridlinePositions
        self.valueDescriptionProvider = valueDescriptionProvider
        self.scaleType = .linear
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = AXNumericDataAxisDescriptor(
            attributedTitle: attributedTitle,
            range: range,
            gridlinePositions: gridlinePositions,
            valueDescriptionProvider: valueDescriptionProvider
        )
        copy.scaleType = scaleType
        return copy
    }
}

public class AXDataPointValue: NSObject, NSCopying {
    public let number: Double
    public let category: String
    public let isNumeric: Bool

    public static func number(_ value: Double) -> AXDataPointValue {
        AXDataPointValue(number: value, category: "", isNumeric: true)
    }

    public static func category(_ value: String) -> AXDataPointValue {
        AXDataPointValue(number: 0, category: value, isNumeric: false)
    }

    private init(number: Double, category: String, isNumeric: Bool) {
        self.number = number
        self.category = category
        self.isNumeric = isNumeric
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        AXDataPointValue(number: number, category: category, isNumeric: isNumeric)
    }
}

public class AXDataPoint: NSObject, NSCopying {
    public enum Value: Equatable, Hashable, Sendable {
        case number(Double)
        case category(String)
    }

    public var xValue: AXDataPointValue
    public var yValue: AXDataPointValue?
    public var additionalValues: [AXDataPointValue]
    private var _label: String?
    private var _attributedLabel: NSAttributedString?
    public var label: String? {
        get { _label }
        set {
            _label = newValue
            _attributedLabel = axAttributed(newValue)
        }
    }
    public var attributedLabel: NSAttributedString? {
        get { _attributedLabel }
        set {
            _attributedLabel = axCopyAttributed(newValue)
            _label = newValue?.string
        }
    }

    public convenience init(
        x: String,
        y: Double? = nil,
        additionalValues: [AXDataPoint.Value] = [],
        label: String? = nil
    ) {
        self.init(
            xValue: .category(x),
            yValue: y.map { .number($0) },
            additional: additionalValues.map(Self.bridge),
            label: label
        )
    }

    public convenience init(
        x: Double,
        y: Double? = nil,
        additionalValues: [AXDataPoint.Value] = [],
        label: String? = nil
    ) {
        self.init(
            xValue: .number(x),
            yValue: y.map { .number($0) },
            additional: additionalValues.map(Self.bridge),
            label: label
        )
    }

    private init(
        xValue: AXDataPointValue,
        yValue: AXDataPointValue?,
        additional: [AXDataPointValue],
        label: String?
    ) {
        self.xValue = xValue
        self.yValue = yValue
        self.additionalValues = additional
        self._label = label
        self._attributedLabel = axAttributed(label)
        super.init()
    }

    private static func bridge(_ value: Value) -> AXDataPointValue {
        switch value {
        case .number(let number):
            return .number(number)
        case .category(let category):
            return .category(category)
        }
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = AXDataPoint(
            xValue: xValue.copy() as! AXDataPointValue,
            yValue: yValue.flatMap { $0.copy() as? AXDataPointValue },
            additional: additionalValues.compactMap { $0.copy() as? AXDataPointValue },
            label: label
        )
        copy.attributedLabel = axCopyAttributed(attributedLabel)
        return copy
    }
}

public class AXDataSeriesDescriptor: NSObject, NSCopying {
    private var _name: String?
    private var _attributedName: NSAttributedString
    public var name: String? {
        get { _name }
        set {
            _name = newValue
            if let newValue {
                _attributedName = NSAttributedString(string: newValue)
            }
        }
    }
    public var attributedName: NSAttributedString {
        get { _attributedName }
        set {
            _attributedName = NSAttributedString(attributedString: newValue)
            _name = newValue.string
        }
    }
    public var isContinuous: Bool
    public var dataPoints: [AXDataPoint]

    public init(name: String, isContinuous: Bool, dataPoints: [AXDataPoint]) {
        self._name = name
        self._attributedName = NSAttributedString(string: name)
        self.isContinuous = isContinuous
        self.dataPoints = dataPoints
        super.init()
    }

    public init(attributedName: NSAttributedString, isContinuous: Bool, dataPoints: [AXDataPoint]) {
        self._attributedName = NSAttributedString(attributedString: attributedName)
        self._name = attributedName.string
        self.isContinuous = isContinuous
        self.dataPoints = dataPoints
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        AXDataSeriesDescriptor(
            attributedName: attributedName,
            isContinuous: isContinuous,
            dataPoints: dataPoints.compactMap { $0.copy() as? AXDataPoint }
        )
    }
}

public class AXChartDescriptor: NSObject, NSCopying {
    public enum ContentDirection: Int, Equatable, Hashable, Sendable {
        case leftToRight = 0
        case rightToLeft = 1
        case topToBottom = 2
        case bottomToTop = 3
        case radialClockwise = 4
        case radialCounterClockwise = 5
    }

    private var _title: String?
    private var _attributedTitle: NSAttributedString?
    public var title: String? {
        get { _title }
        set {
            _title = newValue
            _attributedTitle = axAttributed(newValue)
        }
    }
    public var attributedTitle: NSAttributedString? {
        get { _attributedTitle }
        set {
            _attributedTitle = axCopyAttributed(newValue)
            _title = newValue?.string
        }
    }
    public var summary: String?
    public var contentDirection: ContentDirection
    public var contentFrame: CGRect
    public var series: [AXDataSeriesDescriptor]
    public var xAxis: any AXDataAxisDescriptor
    public var yAxis: AXNumericDataAxisDescriptor?
    public var additionalAxes: [any AXDataAxisDescriptor]

    public convenience init(
        title: String? = nil,
        summary: String? = nil,
        xAxis: any AXDataAxisDescriptor,
        yAxis: AXNumericDataAxisDescriptor? = nil,
        additionalAxes: [any AXDataAxisDescriptor] = [],
        series: [AXDataSeriesDescriptor]
    ) {
        self.init(
            attributedTitle: axAttributed(title),
            summary: summary,
            xAxis: xAxis,
            yAxis: yAxis,
            additionalAxes: additionalAxes,
            series: series
        )
    }

    public init(
        attributedTitle: NSAttributedString? = nil,
        summary: String? = nil,
        xAxis: any AXDataAxisDescriptor,
        yAxis: AXNumericDataAxisDescriptor? = nil,
        additionalAxes: [any AXDataAxisDescriptor] = [],
        series: [AXDataSeriesDescriptor]
    ) {
        self._attributedTitle = axCopyAttributed(attributedTitle)
        self._title = attributedTitle?.string
        self.summary = summary
        self.xAxis = xAxis.copy() as! any AXDataAxisDescriptor
        self.yAxis = yAxis.flatMap { $0.copy() as? AXNumericDataAxisDescriptor }
        self.additionalAxes = additionalAxes.compactMap { $0.copy() as? any AXDataAxisDescriptor }
        self.series = series
        self.contentDirection = .leftToRight
        self.contentFrame = .zero
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = AXChartDescriptor(
            attributedTitle: attributedTitle,
            summary: summary,
            xAxis: xAxis,
            yAxis: yAxis,
            additionalAxes: additionalAxes,
            series: series.compactMap { $0.copy() as? AXDataSeriesDescriptor }
        )
        copy.contentDirection = contentDirection
        copy.contentFrame = contentFrame
        return copy
    }
}
