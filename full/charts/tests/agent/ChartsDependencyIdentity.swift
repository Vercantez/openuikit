import Foundation
import Charts

/// Future clean EC2 probe. Isolated Linux hosts typecheck Foundation
/// values through public Charts APIs; this file is not compiled by the
/// sealed host gate and must not justify public substitutes for
/// Foundation-owned types.
func chartsDependencyIdentityProbe() {
    let date = Date(timeIntervalSinceReferenceDate: 100)
    let value = PlottableValue.value("day", date)
    precondition(value.value == date)

    let mark = RectangleMark(
        xStart: .value("start", date),
        xEnd: .value("end", date.addingTimeInterval(10)),
        yStart: .value("base", 0),
        yEnd: .value("count", 4)
    )
    precondition(mark.xStart == 100)
    precondition(mark.yEnd == 4)

    _ = Foundation.Date.self
    _ = Foundation.Calendar.Component.day
    _ = ChartProxy()
}
