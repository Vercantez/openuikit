import Foundation

public final class MKDistanceFormatter: NSObject {
    public enum Units: UInt, Sendable, Equatable, Hashable {
        case `default` = 0
        case metric = 1
        case imperial = 2
        case imperialWithYards = 3
    }

    public enum DistanceUnitStyle: UInt, Sendable, Equatable, Hashable {
        case `default` = 0
        case abbreviated = 1
        case full = 2
    }

    public var locale: Locale! = Locale(identifier: "en_US_POSIX")
    public var units: Units = .metric
    public var unitStyle: DistanceUnitStyle = .abbreviated

    public func string(fromDistance distance: Double) -> String {
        let resolved = resolvedUnits()
        switch resolved {
        case .imperial, .imperialWithYards:
            let miles = distance / 1609.344
            if abs(miles) >= 0.1 {
                return formatNumber(miles) + (unitStyle == .full ? " miles" : " mi")
            }
            let feet = distance / 0.3048
            if resolved == .imperialWithYards && abs(feet) >= 3 {
                let yards = feet / 3
                return formatNumber(yards) + (unitStyle == .full ? " yards" : " yd")
            }
            return formatNumber(feet) + (unitStyle == .full ? " feet" : " ft")
        default:
            if abs(distance) >= 1000 {
                return formatNumber(distance / 1000) + (unitStyle == .full ? " kilometers" : " km")
            }
            return formatNumber(distance) + (unitStyle == .full ? " meters" : " m")
        }
    }

    /// Linux parser for strings produced by `string(fromDistance:)`. Unrecognized
    /// input returns `0`. Not an Apple locale/parser oracle.
    public func distance(from distance: String) -> Double {
        let trimmed = distance.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let numberPart = trimmed.split { !$0.isNumber && $0 != "." && $0 != "-" && $0 != "+" }
            .first
            .flatMap { Double($0) } ?? 0
        if trimmed.contains("km") || trimmed.contains("kilometer") {
            return numberPart * 1000
        }
        if trimmed.contains("mi") || trimmed.contains("mile") {
            return numberPart * 1609.344
        }
        if trimmed.contains("yd") || trimmed.contains("yard") {
            return numberPart * 0.9144
        }
        if trimmed.contains("ft") || trimmed.contains("feet") || trimmed.contains("foot") {
            return numberPart * 0.3048
        }
        if trimmed.contains("m") || trimmed.contains("meter") {
            return numberPart
        }
        return 0
    }

    private func resolvedUnits() -> Units {
        if units != .default { return units }
        let usesMetric = locale?.usesMetricSystem ?? true
        return usesMetric ? .metric : .imperial
    }

    private func formatNumber(_ value: Double) -> String {
        if value == value.rounded() {
            return String(Int(value.rounded()))
        }
        return String(format: "%.1f", value)
    }
}
