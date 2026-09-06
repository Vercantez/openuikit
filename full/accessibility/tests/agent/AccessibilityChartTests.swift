import Foundation
import Accessibility

private final class ChartHost: NSObject, AXChart {
    var accessibilityChartDescriptor: AXChartDescriptor?
}

func testChartProtocol() {
    let host = ChartHost()
    precondition(host.accessibilityChartDescriptor == nil)
    let xAxis = AXCategoricalDataAxisDescriptor(title: "x", categoryOrder: ["a"])
    let series = AXDataSeriesDescriptor(name: "s", isContinuous: false, dataPoints: [])
    let descriptor = AXChartDescriptor(title: "t", xAxis: xAxis, series: [series])
    host.accessibilityChartDescriptor = descriptor
    precondition(host.accessibilityChartDescriptor?.title == "t")
}

func testChartDescriptor() {
    let xAxis = AXCategoricalDataAxisDescriptor(title: "months", categoryOrder: ["Jan", "Feb"])
    let yAxis = AXNumericDataAxisDescriptor(
        title: "value",
        range: 0...10,
        gridlinePositions: [0, 5, 10],
        valueDescriptionProvider: { "\($0)" }
    )
    let extra = AXCategoricalDataAxisDescriptor(title: "extra", categoryOrder: ["q"])
    let point = AXDataPoint(x: 1.0, y: 2.0, label: "pt")
    let series = AXDataSeriesDescriptor(name: "series", isContinuous: true, dataPoints: [point])
    let chart = AXChartDescriptor(
        title: "Revenue",
        summary: "Monthly",
        xAxis: xAxis,
        yAxis: yAxis,
        additionalAxes: [extra],
        series: [series]
    )
    precondition(chart.title == "Revenue")
    precondition(chart.attributedTitle?.string == "Revenue")
    precondition(chart.summary == "Monthly")
    precondition(chart.contentDirection == .leftToRight)
    precondition(chart.contentFrame == .zero)
    chart.contentDirection = .topToBottom
    chart.contentFrame = CGRect(x: 1, y: 2, width: 3, height: 4)
    precondition(chart.contentDirection == .topToBottom)
    precondition(chart.contentFrame.width == 3)
    chart.attributedTitle = NSAttributedString(string: "Sales")
    precondition(chart.title == "Sales")
    precondition(chart.xAxis.title == "months")
    precondition(chart.yAxis?.range == 0...10)
    precondition(chart.additionalAxes.count == 1)
    precondition(chart.series.count == 1)

    let attributed = AXChartDescriptor(
        attributedTitle: NSAttributedString(string: "Attr"),
        summary: nil,
        xAxis: xAxis,
        yAxis: nil,
        additionalAxes: [],
        series: [series]
    )
    precondition(attributed.title == "Attr")

    let copy = chart.copy() as! AXChartDescriptor
    precondition(copy !== chart)
    precondition(copy.title == "Sales")
    precondition(copy.contentDirection == .topToBottom)
}

func testCategoricalAxis() {
    let axis = AXCategoricalDataAxisDescriptor(title: "cats", categoryOrder: ["a", "b"])
    precondition(axis.title == "cats")
    precondition(axis.attributedTitle.string == "cats")
    precondition(axis.categoryOrder == ["a", "b"])
    axis.categoryOrder = ["x"]
    precondition(axis.categoryOrder == ["x"])
    let attributed = AXCategoricalDataAxisDescriptor(
        attributedTitle: NSAttributedString(string: "attr"),
        categoryOrder: ["z"]
    )
    precondition(attributed.title == "attr")
    let copy = axis.copy() as! AXCategoricalDataAxisDescriptor
    precondition(copy.categoryOrder == ["x"])
}

func testNumericAxis() {
    var captured = 0.0
    let axis = AXNumericDataAxisDescriptor(
        title: "y",
        range: -1...1,
        gridlinePositions: [0],
        valueDescriptionProvider: { value in
            captured = value
            return "v\(value)"
        }
    )
    precondition(axis.scaleType == .linear)
    axis.scaleType = .log10
    precondition(axis.scaleType == .log10)
    precondition(axis.range == -1...1)
    axis.range = 0...100
    precondition(axis.range.upperBound == 100)
    axis.gridlinePositions = [0, 50]
    precondition(axis.gridlinePositions == [0, 50])
    precondition(axis.valueDescriptionProvider(7).contains("7"))
    _ = captured
    let attributed = AXNumericDataAxisDescriptor(
        attributedTitle: NSAttributedString(string: "attr-y"),
        range: 1...2,
        gridlinePositions: [],
        valueDescriptionProvider: { _ in "n" }
    )
    precondition(attributed.title == "attr-y")
    let copy = axis.copy() as! AXNumericDataAxisDescriptor
    precondition(copy.scaleType == .log10)
}

func testDataSeries() {
    let point = AXDataPoint(x: "cat", y: 3)
    let series = AXDataSeriesDescriptor(name: "s", isContinuous: false, dataPoints: [point])
    precondition(series.name == "s")
    precondition(series.attributedName.string == "s")
    precondition(series.isContinuous == false)
    precondition(series.dataPoints.count == 1)
    series.isContinuous = true
    precondition(series.isContinuous)
    let attributed = AXDataSeriesDescriptor(
        attributedName: NSAttributedString(string: "attr-s"),
        isContinuous: true,
        dataPoints: []
    )
    precondition(attributed.name == "attr-s")
    let copy = series.copy() as! AXDataSeriesDescriptor
    precondition(copy.isContinuous)
}

func testDataPoint() {
    let numeric = AXDataPoint(x: 1.5, y: 2.5, additionalValues: [.number(9), .category("extra")], label: "n")
    precondition(numeric.xValue.isNumeric)
    precondition(numeric.xValue.number == 1.5)
    precondition(numeric.yValue?.number == 2.5)
    precondition(numeric.label == "n")
    precondition(numeric.attributedLabel?.string == "n")
    numeric.label = "n2"
    precondition(numeric.attributedLabel?.string == "n2")

    let categorical = AXDataPoint(x: "bucket", y: nil, additionalValues: [], label: nil)
    precondition(!categorical.xValue.isNumeric)
    precondition(categorical.xValue.category == "bucket")
    precondition(categorical.yValue == nil)

    switch AXDataPoint.Value.number(3) {
    case .number(let value):
        precondition(value == 3)
    case .category:
        preconditionFailure("expected number")
    }
    switch AXDataPoint.Value.category("c") {
    case .category(let value):
        precondition(value == "c")
    case .number:
        preconditionFailure("expected category")
    }

    let copy = numeric.copy() as! AXDataPoint
    precondition(copy.label == "n2")
    _ = AXDataPointValue.number(1)
    _ = AXDataPointValue.category("z")
}
