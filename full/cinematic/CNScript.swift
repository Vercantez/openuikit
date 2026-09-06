import Foundation

/// In-memory cinematic script: user decisions, detection tracks, and f-number.
/// Loading from an `AVAsset` throws `.unsupported` — Linux has no cinematic
/// sample parser. `host_make` is isolated-host construction.
public final class CNScript: @unchecked Sendable {
    public struct Frame: Sendable {
        public var time: CMTime { storedTime }
        public var focusDisparity: Float { focusDetection.focusDisparity }
        public var focusDetection: CNDetection { storedFocus }
        public var allDetections: [CNDetection] { storedAll }

        private var storedTime: CMTime
        private var storedFocus: CNDetection
        private var storedAll: [CNDetection]

        init(time: CMTime, focusDetection: CNDetection, allDetections: [CNDetection]) {
            self.storedTime = time
            self.storedFocus = focusDetection
            self.storedAll = allDetections
        }

        public func detection(for detectionID: CNDetectionID) -> CNDetection? {
            storedAll.first { $0.detectionID == detectionID }
        }

        public func bestDetection(for detectionGroupID: CNDetectionGroupID) -> CNDetection? {
            storedAll
                .filter { $0.detectionGroupID == detectionGroupID }
                .max { $0.focusDisparity < $1.focusDisparity }
        }
    }

    public struct Changes: Sendable {
        public var fNumber: Float { storedFNumber }
        public var userDecisions: [CNDecision] { storedUser }
        public var addedDetectionTracks: [CNDetectionTrack] { storedTracks }

        private var storedFNumber: Float
        private var storedUser: [CNDecision]
        private var storedTracks: [CNDetectionTrack]

        init(
            fNumber: Float,
            userDecisions: [CNDecision],
            addedDetectionTracks: [CNDetectionTrack]
        ) {
            self.storedFNumber = fNumber
            self.storedUser = userDecisions
            self.storedTracks = addedDetectionTracks
        }

        public var dataRepresentation: Data {
            CNScriptChangesCodec.encode(self)
        }

        public init?(dataRepresentation: Data) {
            guard let decoded = CNScriptChangesCodec.decode(dataRepresentation) else {
                return nil
            }
            self = decoded
        }
    }

    public var timeRange: CMTimeRange { storedTimeRange }
    public var fNumber: Float
    public var addedDetectionTracks: [CNDetectionTrack] { storedAddedTracks }

    private var storedTimeRange: CMTimeRange
    private var baseDecisionList: [CNDecision]
    private var userDecisionList: [CNDecision]
    private var storedAddedTracks: [CNDetectionTrack]
    private var detectionCatalog: [CNDetection]

    public init(
        asset: AVAsset,
        changes: CNScript.Changes? = nil,
        progress: Progress? = nil
    ) async throws {
        _ = asset
        _ = changes
        _ = progress
        throw CNCinematicError(.unsupported)
    }

    /// Isolated-host empty/populated script. Not a parse of a cinematic movie.
    public static func host_make(
        timeRange: CMTimeRange,
        fNumber: Float = 2.8,
        baseDecisions: [CNDecision] = [],
        detections: [CNDetection] = []
    ) -> CNScript {
        CNScript(
            timeRange: timeRange,
            fNumber: fNumber,
            baseDecisions: baseDecisions,
            userDecisions: [],
            addedTracks: [],
            detections: detections
        )
    }

    init(
        timeRange: CMTimeRange,
        fNumber: Float,
        baseDecisions: [CNDecision],
        userDecisions: [CNDecision],
        addedTracks: [CNDetectionTrack],
        detections: [CNDetection]
    ) {
        self.storedTimeRange = timeRange
        self.fNumber = fNumber
        self.baseDecisionList = baseDecisions.sorted { $0.time.seconds < $1.time.seconds }
        self.userDecisionList = userDecisions.sorted { $0.time.seconds < $1.time.seconds }
        self.storedAddedTracks = addedTracks
        self.detectionCatalog = detections
    }

    public func reload(changes: CNScript.Changes?) {
        if let changes {
            fNumber = changes.fNumber
            userDecisionList = changes.userDecisions.sorted { $0.time.seconds < $1.time.seconds }
            storedAddedTracks = changes.addedDetectionTracks
        } else {
            userDecisionList = []
            storedAddedTracks = []
        }
    }

    public func changes() -> CNScript.Changes {
        CNScript.Changes(
            fNumber: fNumber,
            userDecisions: userDecisionList,
            addedDetectionTracks: storedAddedTracks
        )
    }

    public func changes(trimmedBy timeRange: CMTimeRange) -> CNScript.Changes {
        CNScript.Changes(
            fNumber: fNumber,
            userDecisions: userDecisionList.filter { timeRange.containsTime($0.time) },
            addedDetectionTracks: storedAddedTracks
        )
    }

    public func addUserDecision(_ decision: CNDecision) -> Bool {
        guard storedTimeRange.containsTime(decision.time) || storedTimeRange == .zero
            || decision.time.seconds >= storedTimeRange.start.seconds
            && decision.time.seconds <= storedTimeRange.end.seconds
        else {
            return false
        }
        let marked = decision.markingUser(true)
        if let index = userDecisionList.firstIndex(where: {
            $0.time == marked.time && $0.focusDetectionID == marked.focusDetectionID
        }) {
            userDecisionList[index] = marked
            return true
        }
        userDecisionList.append(marked)
        userDecisionList.sort { $0.time.seconds < $1.time.seconds }
        return true
    }

    public func removeUserDecision(_ decision: CNDecision) -> Bool {
        let marked = decision.markingUser(true)
        if let index = userDecisionList.firstIndex(where: {
            $0.time == marked.time && $0.focusDetectionID == marked.focusDetectionID
        }) {
            userDecisionList.remove(at: index)
            return true
        }
        if let index = userDecisionList.firstIndex(where: { $0.time == decision.time }) {
            userDecisionList.remove(at: index)
            return true
        }
        return false
    }

    public func removeAllUserDecisions() {
        userDecisionList = []
    }

    public func addDetectionTrack(_ detectionTrack: CNDetectionTrack) -> CNDetectionID {
        storedAddedTracks.append(detectionTrack)
        return detectionTrack.detectionID
    }

    public func removeDetectionTrack(_ detectionTrack: CNDetectionTrack) -> Bool {
        if let index = storedAddedTracks.firstIndex(where: {
            $0.detectionID == detectionTrack.detectionID
        }) {
            storedAddedTracks.remove(at: index)
            return true
        }
        return false
    }

    public func detectionTrack(for detectionID: CNDetectionID) -> CNDetectionTrack? {
        storedAddedTracks.first { $0.detectionID == detectionID }
    }

    public func detectionTrack(for decision: CNDecision) -> CNDetectionTrack? {
        switch decision.focusDetectionID {
        case let .single(id):
            return detectionTrack(for: id)
        case let .group(group):
            return storedAddedTracks.first { $0.detectionGroupID == group }
        }
    }

    public func userDecisions(in timeRange: CMTimeRange) -> [CNDecision] {
        userDecisionList.filter { timeRange.containsTime($0.time) }
    }

    public func baseDecisions(in timeRange: CMTimeRange) -> [CNDecision] {
        baseDecisionList.filter { timeRange.containsTime($0.time) }
    }

    public func decisions(in timeRange: CMTimeRange) -> [CNDecision] {
        mergedDecisions().filter { timeRange.containsTime($0.time) }
    }

    public func decision(at time: CMTime, tolerance: CMTime) -> CNDecision? {
        let window = abs(tolerance.seconds.isNaN ? 0 : tolerance.seconds)
        return mergedDecisions().min { lhs, rhs in
            abs(lhs.time.seconds - time.seconds) < abs(rhs.time.seconds - time.seconds)
        }.flatMap { candidate in
            abs(candidate.time.seconds - time.seconds) <= window ? candidate : nil
        }
    }

    public func decision(after time: CMTime) -> CNDecision? {
        mergedDecisions().first { $0.time.seconds > time.seconds }
    }

    public func decision(before time: CMTime) -> CNDecision? {
        mergedDecisions().last { $0.time.seconds < time.seconds }
    }

    public func primaryDecision(at time: CMTime) -> CNDecision? {
        let users = userDecisionList.last { $0.time.seconds <= time.seconds }
        if let users { return users }
        return baseDecisionList.last { $0.time.seconds <= time.seconds }
    }

    public func secondaryDecision(at time: CMTime) -> CNDecision? {
        let primary = primaryDecision(at: time)
        if primary?.isUserDecision == true {
            return baseDecisionList.last { $0.time.seconds <= time.seconds }
        }
        return nil
    }

    public func timeRangeOfTransition(after decision: CNDecision) -> CMTimeRange {
        if let next = mergedDecisions().first(where: { $0.time.seconds > decision.time.seconds }) {
            return CMTimeRange(
                start: decision.time,
                duration: CMTime(
                    seconds: next.time.seconds - decision.time.seconds,
                    preferredTimescale: decision.time.timescale == 0 ? 600 : decision.time.timescale
                )
            )
        }
        return CMTimeRange(start: decision.time, duration: .zero)
    }

    public func timeRangeOfTransition(before decision: CNDecision) -> CMTimeRange {
        if let previous = mergedDecisions().last(where: { $0.time.seconds < decision.time.seconds }) {
            return CMTimeRange(
                start: previous.time,
                duration: CMTime(
                    seconds: decision.time.seconds - previous.time.seconds,
                    preferredTimescale: decision.time.timescale == 0 ? 600 : decision.time.timescale
                )
            )
        }
        return CMTimeRange(start: decision.time, duration: .zero)
    }

    public func frame(at time: CMTime, tolerance: CMTime) -> CNScript.Frame? {
        let detections = allDetections(at: time, tolerance: tolerance)
        guard let focus = focusDetection(at: time, among: detections) else { return nil }
        return Frame(time: time, focusDetection: focus, allDetections: detections)
    }

    public func frames(in timeRange: CMTimeRange) -> [CNScript.Frame] {
        let times = Set(
            (detectionCatalog + storedAddedTracks.flatMap { $0.storedDetections })
                .map { $0.time.seconds }
        )
        return times.sorted().compactMap { seconds in
            let time = CMTime(seconds: seconds, preferredTimescale: 600)
            guard timeRange.containsTime(time) else { return nil }
            return frame(at: time, tolerance: CMTime(seconds: 0.001, preferredTimescale: 600))
        }
    }

    private func mergedDecisions() -> [CNDecision] {
        var byTime: [String: CNDecision] = [:]
        for decision in baseDecisionList {
            byTime[CNScript.timeKey(decision.time)] = decision
        }
        for decision in userDecisionList {
            byTime[CNScript.timeKey(decision.time)] = decision
        }
        return byTime.values.sorted { $0.time.seconds < $1.time.seconds }
    }

    private static func timeKey(_ time: CMTime) -> String {
        String(format: "%.6f", time.seconds)
    }

    private func allDetections(at time: CMTime, tolerance: CMTime) -> [CNDetection] {
        let window = abs(tolerance.seconds.isNaN ? 0 : tolerance.seconds)
        var detections = detectionCatalog.filter {
            abs($0.time.seconds - time.seconds) <= window
        }
        for track in storedAddedTracks {
            if let sample = track.detection(nearest: time),
               abs(sample.time.seconds - time.seconds) <= max(window, 0.05) {
                detections.append(sample)
            }
        }
        return detections
    }

    private func focusDetection(at time: CMTime, among detections: [CNDetection]) -> CNDetection? {
        if let decision = primaryDecision(at: time) {
            switch decision.focusDetectionID {
            case let .single(id):
                if let match = detections.first(where: { $0.detectionID == id }) {
                    return match
                }
                for track in storedAddedTracks where track.detectionID == id {
                    return track.detection(atOrBefore: time) ?? detections.first
                }
            case let .group(group):
                if let match = detections
                    .filter({ $0.detectionGroupID == group })
                    .max(by: { $0.focusDisparity < $1.focusDisparity })
                {
                    return match
                }
            }
        }
        return detections.max { $0.focusDisparity < $1.focusDisparity }
    }
}

private enum CNScriptChangesCodec {
    static let format = "openuikit.cinematic.script-changes.v1"

    static func encode(_ changes: CNScript.Changes) -> Data {
        var payload: [String: Any] = [
            "format": format,
            "fNumber": changes.fNumber,
        ]
        payload["userDecisions"] = changes.userDecisions.map(encodeDecision)
        payload["addedTracks"] = changes.addedDetectionTracks.map(encodeTrack)
        return (try? JSONSerialization.data(withJSONObject: payload, options: [])) ?? Data()
    }

    static func decode(_ data: Data) -> CNScript.Changes? {
        guard
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            object["format"] as? String == format,
            let fNumber = (object["fNumber"] as? NSNumber)?.floatValue
        else {
            return nil
        }
        let decisions = (object["userDecisions"] as? [[String: Any]] ?? []).compactMap(decodeDecision)
        let tracks = (object["addedTracks"] as? [[String: Any]] ?? []).compactMap(decodeTrack)
        return CNScript.Changes(
            fNumber: fNumber,
            userDecisions: decisions,
            addedDetectionTracks: tracks
        )
    }

    private static func encodeDecision(_ decision: CNDecision) -> [String: Any] {
        var payload: [String: Any] = [
            "timeValue": decision.time.value,
            "timescale": decision.time.timescale,
            "strong": decision.isStrongDecision,
            "user": true,
        ]
        switch decision.focusDetectionID {
        case let .single(id):
            payload["kind"] = "single"
            payload["id"] = id.rawValue
        case let .group(id):
            payload["kind"] = "group"
            payload["id"] = id.rawValue
        }
        return payload
    }

    private static func decodeDecision(_ payload: [String: Any]) -> CNDecision? {
        guard
            let timeValue = (payload["timeValue"] as? NSNumber)?.int64Value,
            let timescale = (payload["timescale"] as? NSNumber)?.int32Value,
            let kind = payload["kind"] as? String,
            let id = (payload["id"] as? NSNumber)?.int64Value
        else {
            return nil
        }
        let strong = (payload["strong"] as? Bool) ?? false
        let time = CMTime(value: timeValue, timescale: timescale == 0 ? 1 : timescale)
        let decision: CNDecision
        if kind == "group" {
            decision = CNDecision(
                time: time,
                detectionGroupID: CNDetectionGroupID(id),
                strong: strong
            )
        } else {
            decision = CNDecision(
                time: time,
                detectionID: CNDetectionID(id),
                strong: strong
            )
        }
        return decision.markingUser(true)
    }

    private static func encodeTrack(_ track: CNDetectionTrack) -> [String: Any] {
        if let fixed = track as? CNFixedDetectionTrack {
            var payload: [String: Any] = [
                "kind": "fixed",
                "focusDisparity": fixed.focusDisparity,
            ]
            if let original = fixed.originalDetection {
                payload["original"] = encodeDetection(original)
            }
            return payload
        }
        let detections: [CNDetection]
        if let custom = track as? CNCustomDetectionTrack {
            detections = custom.allDetections
        } else {
            detections = track.storedDetections
        }
        return [
            "kind": "custom",
            "smooth": !track.isDiscrete,
            "detections": detections.map(encodeDetection),
        ]
    }

    private static func decodeTrack(_ payload: [String: Any]) -> CNDetectionTrack? {
        let kind = payload["kind"] as? String
        if kind == "fixed" {
            let disparity = (payload["focusDisparity"] as? NSNumber)?.floatValue ?? 0
            if let originalPayload = payload["original"] as? [String: Any],
               let original = decodeDetection(originalPayload)
            {
                return CNFixedDetectionTrack(originalDetection: original)
            }
            return CNFixedDetectionTrack(focusDisparity: disparity)
        }
        let detections = (payload["detections"] as? [[String: Any]] ?? []).compactMap(decodeDetection)
        let smooth = (payload["smooth"] as? Bool) ?? false
        return CNCustomDetectionTrack(detections: detections, smooth: smooth)
    }

    private static func encodeDetection(_ detection: CNDetection) -> [String: Any] {
        [
            "timeValue": detection.time.value,
            "timescale": detection.time.timescale,
            "type": detection.detectionType.rawValue,
            "x": detection.normalizedRect.origin.x,
            "y": detection.normalizedRect.origin.y,
            "w": detection.normalizedRect.size.width,
            "h": detection.normalizedRect.size.height,
            "disparity": detection.focusDisparity,
        ]
    }

    private static func decodeDetection(_ payload: [String: Any]) -> CNDetection? {
        guard
            let timeValue = (payload["timeValue"] as? NSNumber)?.int64Value,
            let timescale = (payload["timescale"] as? NSNumber)?.int32Value,
            let typeRaw = (payload["type"] as? NSNumber)?.intValue,
            let type = CNDetectionType(rawValue: typeRaw)
        else {
            return nil
        }
        let time = CMTime(value: timeValue, timescale: timescale == 0 ? 1 : timescale)
        let x = CGFloat((payload["x"] as? NSNumber)?.doubleValue ?? 0)
        let y = CGFloat((payload["y"] as? NSNumber)?.doubleValue ?? 0)
        let w = CGFloat((payload["w"] as? NSNumber)?.doubleValue ?? 0)
        let h = CGFloat((payload["h"] as? NSNumber)?.doubleValue ?? 0)
        let disparity = (payload["disparity"] as? NSNumber)?.floatValue ?? 0
        return CNDetection(
            time: time,
            detectionType: type,
            normalizedRect: CGRect(x: x, y: y, width: w, height: h),
            focusDisparity: disparity
        )
    }
}
