import Foundation

/// SensorKit absolute time. On Linux this is a `CFTimeInterval` measured from
/// the Foundation reference date. That is a host clock, not Apple's mach
/// continuous-time mapping.
public struct SRAbsoluteTime: RawRepresentable, Hashable, Sendable {
    public var rawValue: TimeInterval

    public init(rawValue: TimeInterval) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: TimeInterval) {
        self.rawValue = rawValue
    }

    public static func current() -> SRAbsoluteTime {
        SRAbsoluteTime(Date().timeIntervalSinceReferenceDate)
    }

    public func toCFAbsoluteTime() -> TimeInterval {
        rawValue
    }
}

extension NSDate {
    public var srAbsoluteTime: SRAbsoluteTime {
        SRAbsoluteTime(timeIntervalSinceReferenceDate)
    }

    public convenience init(SRAbsoluteTime time: SRAbsoluteTime) {
        self.init(timeIntervalSinceReferenceDate: time.toCFAbsoluteTime())
    }
}

extension Date {
    public var srAbsoluteTime: SRAbsoluteTime {
        SRAbsoluteTime(timeIntervalSinceReferenceDate)
    }

    public init(SRAbsoluteTime time: SRAbsoluteTime) {
        self.init(timeIntervalSinceReferenceDate: time.toCFAbsoluteTime())
    }
}
