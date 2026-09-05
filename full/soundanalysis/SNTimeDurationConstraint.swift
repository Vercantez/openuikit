import Foundation

/// Window-duration restriction published by a classify-sound request.
/// Associated CoreMedia values are the isolated-host stand-ins when the
/// real `CoreMedia` module is not imported.
public enum SNTimeDurationConstraint: Equatable, Sendable {
    case enumeratedDurations([CMTime])
    case durationRange(CMTimeRange)
}
