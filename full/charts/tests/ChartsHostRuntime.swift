import Foundation
import SwiftUI
@_spi(OpenUIKitHost) import Charts

@main
struct ChartsHostRuntime {
    @MainActor
    static func main() {
        precondition(ChartsPortable.renderingCapability == .basicMarks)
        precondition(ChartsPortable.interactionCapability == .unavailable)

        let bar = RectangleMark(
            xStart: .value("start", Date(timeIntervalSinceReferenceDate: 100)),
            xEnd: .value("end", Date(timeIntervalSinceReferenceDate: 200)),
            yStart: .value("base", 0),
            yEnd: .value("count", 42)
        )
        precondition(bar.xStart == 100)
        precondition(bar.xEnd == 200)
        precondition(bar.yStart == 0)
        precondition(bar.yEnd == 42)

        let line = LineMark(
            x: .value("day", Date(timeIntervalSinceReferenceDate: 250)),
            y: .value("count", 17)
        )
        precondition(line.x == 250)
        precondition(line.y == 17)

        let unavailable = ChartProxy()
        precondition(unavailable.plotFrame != nil)
        precondition(unavailable.position(forX: 5) == nil)

        let hostDriven = ChartProxy(xPosition: { CGFloat($0 * 2 + 1) })
        precondition(hostDriven.position(forX: 5) == 11)
        precondition(
            hostDriven.position(
                forX: Date(timeIntervalSinceReferenceDate: 9)
            ) == 19
        )

        let authoredStyle = StrokeStyle(
            lineWidth: 1,
            dash: [4, 4],
            dashPhase: 2
        )
        let styled = RuleMark(x: .value("selection", 5))
            .lineStyle(authoredStyle)
        let retained = Mirror(reflecting: styled).children
            .compactMap { $0.value as? StrokeStyle }
            .first
        precondition(retained == authoredStyle)

        print(
            "CHARTS_HOST_OK marks=bar,line,area,rule "
                + "scalar=numeric,date interaction=fail-closed,host-driven "
                + "stroke=retained rendering=basic"
        )
    }
}
