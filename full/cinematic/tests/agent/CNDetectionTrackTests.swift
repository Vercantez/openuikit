import Foundation
import Cinematic

func testCNCustomDetectionTrackInitAndAllDetections() {
    let a = CNDetection(
        time: CMTime(seconds: 0, preferredTimescale: 600),
        detectionType: .humanFace,
        normalizedRect: CGRect(x: 0.1, y: 0.1, width: 0.2, height: 0.2),
        focusDisparity: 0.4
    )
    let b = CNDetection(
        time: CMTime(seconds: 1, preferredTimescale: 600),
        detectionType: .humanFace,
        normalizedRect: CGRect(x: 0.3, y: 0.3, width: 0.2, height: 0.2),
        focusDisparity: 0.6
    )
    let track = CNCustomDetectionTrack(detections: [a, b], smooth: false)
    precondition(track.allDetections.count == 2)
    precondition(track.detectionType == .humanFace)
    precondition(track.isUserCreated)
    precondition(track.isDiscrete)
    precondition(track.allDetections[0].detectionID == track.detectionID)
    precondition(track.allDetections[0].detectionGroupID == track.detectionGroupID)
}

func testCNCustomDetectionTrackSmoothingInsertsMidpoint() {
    let a = CNDetection(
        time: CMTime(seconds: 0, preferredTimescale: 600),
        detectionType: .dogBody,
        normalizedRect: CGRect(x: 0, y: 0, width: 0.2, height: 0.4),
        focusDisparity: 0.2
    )
    let b = CNDetection(
        time: CMTime(seconds: 2, preferredTimescale: 600),
        detectionType: .dogBody,
        normalizedRect: CGRect(x: 0.4, y: 0.4, width: 0.4, height: 0.8),
        focusDisparity: 0.8
    )
    let track = CNCustomDetectionTrack(detections: [a, b], smooth: true)
    precondition(track.allDetections.count == 3)
    precondition(!track.isDiscrete)
    let mid = track.allDetections[1]
    precondition(abs(mid.time.seconds - 1) < 0.001)
    precondition(abs(mid.focusDisparity - 0.5) < 0.001)
    precondition(abs(mid.normalizedRect.origin.x - 0.2) < 0.001)
}

func testCNDetectionTrackDetectionAtOrBefore() {
    let a = CNDetection(
        time: CMTime(seconds: 1, preferredTimescale: 600),
        detectionType: .humanHead,
        normalizedRect: .zero,
        focusDisparity: 0.1
    )
    let b = CNDetection(
        time: CMTime(seconds: 3, preferredTimescale: 600),
        detectionType: .humanHead,
        normalizedRect: .zero,
        focusDisparity: 0.2
    )
    let track = CNCustomDetectionTrack(detections: [a, b], smooth: false)
    let before = track.detection(atOrBefore: CMTime(seconds: 2, preferredTimescale: 600))
    precondition(before?.time.seconds == 1)
    let exact = track.detection(atOrBefore: CMTime(seconds: 3, preferredTimescale: 600))
    precondition(exact?.time.seconds == 3)
    let none = track.detection(atOrBefore: CMTime(seconds: 0.5, preferredTimescale: 600))
    precondition(none == nil)
}

func testCNDetectionTrackDetectionNearest() {
    let a = CNDetection(
        time: CMTime(seconds: 1, preferredTimescale: 600),
        detectionType: .catBody,
        normalizedRect: .zero,
        focusDisparity: 0.1
    )
    let b = CNDetection(
        time: CMTime(seconds: 4, preferredTimescale: 600),
        detectionType: .catBody,
        normalizedRect: .zero,
        focusDisparity: 0.2
    )
    let track = CNCustomDetectionTrack(detections: [a, b], smooth: false)
    let nearest = track.detection(nearest: CMTime(seconds: 3.5, preferredTimescale: 600))
    precondition(nearest?.time.seconds == 4)
}

func testCNDetectionTrackDetectionsInTimeRange() {
    let samples = [0.0, 1.0, 2.0, 3.0].map { seconds in
        CNDetection(
            time: CMTime(seconds: seconds, preferredTimescale: 600),
            detectionType: .custom,
            normalizedRect: .zero,
            focusDisparity: Float(seconds)
        )
    }
    let track = CNCustomDetectionTrack(detections: samples, smooth: false)
    let range = CMTimeRange(
        start: CMTime(seconds: 1, preferredTimescale: 600),
        duration: CMTime(seconds: 2, preferredTimescale: 600)
    )
    let inside = track.detections(in: range)
    precondition(inside.count == 2)
    precondition(inside[0].time.seconds == 1)
    precondition(inside[1].time.seconds == 2)
}

func testCNFixedDetectionTrackFocusDisparityInit() {
    let track = CNFixedDetectionTrack(focusDisparity: 0.55)
    precondition(track.focusDisparity == 0.55)
    precondition(track.originalDetection == nil)
    precondition(track.detectionType == .fixedFocus)
    precondition(track.isUserCreated)
    precondition(!track.isDiscrete)
    let sample = track.detection(atOrBefore: CMTime(seconds: 5, preferredTimescale: 600))
    precondition(sample?.focusDisparity == 0.55)
    precondition(sample?.detectionType == .fixedFocus)
    precondition(sample?.time.seconds == 5)
}

func testCNFixedDetectionTrackOriginalDetectionInit() {
    let original = CNDetection(
        time: CMTime(seconds: 0.25, preferredTimescale: 600),
        detectionType: .humanTorso,
        normalizedRect: CGRect(x: 0.2, y: 0.2, width: 0.3, height: 0.4),
        focusDisparity: 0.77
    )
    let track = CNFixedDetectionTrack(originalDetection: original)
    precondition(track.originalDetection?.detectionType == .humanTorso)
    precondition(track.focusDisparity == 0.77)
    precondition(track.detectionType == .humanTorso)
    let nearest = track.detection(nearest: CMTime(seconds: 9, preferredTimescale: 600))
    precondition(nearest?.normalizedRect.size.width == 0.3)
    precondition(nearest?.focusDisparity == 0.77)
}

func testCNDetectionTrackIdentifiersAreStable() {
    let track = CNCustomDetectionTrack(
        detections: [
            CNDetection(
                time: .zero,
                detectionType: .unknown,
                normalizedRect: .zero,
                focusDisparity: 0
            ),
        ],
        smooth: false
    )
    precondition(track.detectionID.rawValue != 0)
    precondition(track.detectionGroupID.rawValue != 0)
}
