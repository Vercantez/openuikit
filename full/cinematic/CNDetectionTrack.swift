import Foundation

/// A timeline of detections sharing one identifier. Queries are exact stored
/// samples plus, for fixed tracks, a constant disparity sample.
open class CNDetectionTrack: @unchecked Sendable {
    public var detectionType: CNDetectionType { storedType }
    public var detectionID: CNDetectionID { storedDetectionID }
    public var detectionGroupID: CNDetectionGroupID { storedGroupID }
    public var isUserCreated: Bool { storedUserCreated }
    public var isDiscrete: Bool { storedDiscrete }

    let storedType: CNDetectionType
    let storedDetectionID: CNDetectionID
    let storedGroupID: CNDetectionGroupID
    let storedUserCreated: Bool
    let storedDiscrete: Bool
    var storedDetections: [CNDetection]

    init(
        detectionType: CNDetectionType,
        detectionID: CNDetectionID,
        detectionGroupID: CNDetectionGroupID,
        isUserCreated: Bool,
        isDiscrete: Bool,
        detections: [CNDetection]
    ) {
        self.storedType = detectionType
        self.storedDetectionID = detectionID
        self.storedGroupID = detectionGroupID
        self.storedUserCreated = isUserCreated
        self.storedDiscrete = isDiscrete
        self.storedDetections = detections
    }

    public func detection(atOrBefore time: CMTime) -> CNDetection? {
        let sorted = storedDetections.sorted { $0.time.seconds < $1.time.seconds }
        return sorted.last { $0.time.seconds <= time.seconds }
    }

    public func detection(nearest time: CMTime) -> CNDetection? {
        storedDetections.min { lhs, rhs in
            abs(lhs.time.seconds - time.seconds) < abs(rhs.time.seconds - time.seconds)
        }
    }

    public func detections(in timeRange: CMTimeRange) -> [CNDetection] {
        storedDetections
            .filter { timeRange.containsTime($0.time) }
            .sorted { $0.time.seconds < $1.time.seconds }
    }
}

/// Constant-disparity track. `init(focusDisparity:)` uses `.fixedFocus`;
/// `init(originalDetection:)` preserves that detection's type and rect.
public class CNFixedDetectionTrack: CNDetectionTrack, @unchecked Sendable {
    public var originalDetection: CNDetection? { storedOriginal }
    public var focusDisparity: Float { storedFocusDisparity }

    private let storedOriginal: CNDetection?
    private let storedFocusDisparity: Float

    public init(focusDisparity: Float) {
        let detectionID = CNDetectionID(CNIdentifierAllocator.nextID())
        let groupID = CNDetectionGroupID(CNIdentifierAllocator.nextID())
        self.storedOriginal = nil
        self.storedFocusDisparity = focusDisparity
        let sample = CNDetection(
            time: .zero,
            detectionType: .fixedFocus,
            normalizedRect: .zero,
            focusDisparity: focusDisparity,
            detectionID: detectionID,
            detectionGroupID: groupID
        )
        super.init(
            detectionType: .fixedFocus,
            detectionID: detectionID,
            detectionGroupID: groupID,
            isUserCreated: true,
            isDiscrete: false,
            detections: [sample]
        )
    }

    public init(originalDetection: CNDetection) {
        let detectionID = originalDetection.detectionID
            ?? CNDetectionID(CNIdentifierAllocator.nextID())
        let groupID = originalDetection.detectionGroupID
            ?? CNDetectionGroupID(CNIdentifierAllocator.nextID())
        self.storedOriginal = originalDetection
        self.storedFocusDisparity = originalDetection.focusDisparity
        let sample = originalDetection.assigning(
            detectionID: detectionID,
            detectionGroupID: groupID
        )
        super.init(
            detectionType: originalDetection.detectionType,
            detectionID: detectionID,
            detectionGroupID: groupID,
            isUserCreated: true,
            isDiscrete: false,
            detections: [sample]
        )
    }

    public override func detection(atOrBefore time: CMTime) -> CNDetection? {
        guard let prototype = storedDetections.first else { return nil }
        return CNDetection(
            time: time,
            detectionType: prototype.detectionType,
            normalizedRect: prototype.normalizedRect,
            focusDisparity: storedFocusDisparity,
            detectionID: prototype.detectionID,
            detectionGroupID: prototype.detectionGroupID
        )
    }

    public override func detection(nearest time: CMTime) -> CNDetection? {
        detection(atOrBefore: time)
    }
}

/// User-authored detection samples. `smooth` inserts one linearly interpolated
/// midpoint between consecutive samples; that is a Linux interpolator, not
/// Apple's smoother.
public class CNCustomDetectionTrack: CNDetectionTrack, @unchecked Sendable {
    public var allDetections: [CNDetection] { storedDetections }

    public init(detections: [CNDetection], smooth applySmoothing: Bool) {
        let detectionID = CNDetectionID(CNIdentifierAllocator.nextID())
        let groupID = CNDetectionGroupID(CNIdentifierAllocator.nextID())
        let typed = detections.map {
            $0.assigning(detectionID: detectionID, detectionGroupID: groupID)
        }
        let prepared = applySmoothing ? CNCustomDetectionTrack.smoothed(typed) : typed
        super.init(
            detectionType: detections.first?.detectionType ?? .custom,
            detectionID: detectionID,
            detectionGroupID: groupID,
            isUserCreated: true,
            isDiscrete: !applySmoothing,
            detections: prepared
        )
    }

    private static func smoothed(_ detections: [CNDetection]) -> [CNDetection] {
        let sorted = detections.sorted { $0.time.seconds < $1.time.seconds }
        guard sorted.count >= 2 else { return sorted }
        var result: [CNDetection] = []
        for index in 0..<(sorted.count - 1) {
            let a = sorted[index]
            let b = sorted[index + 1]
            result.append(a)
            let midTime = CMTime(
                seconds: (a.time.seconds + b.time.seconds) / 2,
                preferredTimescale: a.time.timescale == 0 ? 600 : a.time.timescale
            )
            let rect = CGRect(
                x: (a.normalizedRect.origin.x + b.normalizedRect.origin.x) / 2,
                y: (a.normalizedRect.origin.y + b.normalizedRect.origin.y) / 2,
                width: (a.normalizedRect.size.width + b.normalizedRect.size.width) / 2,
                height: (a.normalizedRect.size.height + b.normalizedRect.size.height) / 2
            )
            let disparity = a.focusDisparity + (b.focusDisparity - a.focusDisparity) / 2
            result.append(
                CNDetection(
                    time: midTime,
                    detectionType: a.detectionType,
                    normalizedRect: rect,
                    focusDisparity: disparity,
                    detectionID: a.detectionID,
                    detectionGroupID: a.detectionGroupID
                )
            )
        }
        result.append(sorted[sorted.count - 1])
        return result
    }
}
