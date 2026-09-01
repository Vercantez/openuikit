import Charts
import Foundation
import SwiftUI

private struct DailyMetric: Identifiable {
    let dayStart: Date
    let count: Int
    var id: Date { dayStart }
}

private struct IceCubesChartsConsumer: View {
    @State private var selectedDate: Date?
    let dailyData: [DailyMetric]

    var body: some View {
        Chart {
            ForEach(dailyData) { data in
                RectangleMark(
                    xStart: .value(
                        "DayStart",
                        data.dayStart.addingTimeInterval(-100)
                    ),
                    xEnd: .value(
                        "DayEnd",
                        data.dayStart.addingTimeInterval(100)
                    ),
                    yStart: .value("Base", 0),
                    yEnd: .value("Count", data.count)
                )
                .foregroundStyle(Color.blue)
            }

            selectedRuleMark
        }
        .chartXSelection(value: $selectedDate)
        .chartXScale(
            range: .plotDimension(startPadding: 12, endPadding: 12)
        )
        .chartYScale(domain: 0...100)
        .chartXAxis {
            AxisMarks(values: dailyData.map(\.dayStart)) { _ in
                AxisValueLabel(
                    format: .dateTime.month(.abbreviated).day(),
                    centered: true
                )
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                let position = selectedDate.flatMap {
                    proxy.position(forX: $0)
                } ?? 0
                let plotArea = proxy.plotFrame.map { geometry[$0] } ?? .zero
                Text("\(position),\(plotArea.minX)")
            }
        }
    }

    @ChartContentBuilder
    private var selectedRuleMark: some ChartContent {
        ForEach(dailyData.prefix(1)) { data in
            RuleMark(x: .value("Selected", data.dayStart))
                .foregroundStyle(Color.secondary.opacity(0.35))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
        }
    }
}

private struct TagChartConsumer: View {
    let values: [Int]

    var body: some View {
        Chart(values.indices, id: \.self) { index in
            AreaMark(
                x: .value("day", index),
                y: .value("uses", values[index])
            )
            .interpolationMethod(.catmullRom)
        }
        .chartLegend(.hidden)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
    }
}
