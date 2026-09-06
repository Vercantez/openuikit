import Foundation

/// A cinematic focus decision at a timeline time. Newly constructed decisions
/// are not user decisions; `CNScript.addUserDecision` copies them as user
/// edits. `isUserDecision` on Apple's inits is an oracle question.
public struct CNDecision: Equatable, Sendable {
    public enum FocusDetectionID: Equatable, Sendable {
        case group(CNDetectionGroupID)
        case single(CNDetectionID)
    }

    public var time: CMTime { storedTime }
    public var isStrongDecision: Bool { storedStrong }
    public var isUserDecision: Bool { storedUser }
    public var focusDetectionID: FocusDetectionID { storedFocus }

    private var storedTime: CMTime
    private var storedStrong: Bool
    private var storedUser: Bool
    private var storedFocus: FocusDetectionID

    public init(time: CMTime, detectionID: CNDetectionID, strong isStrong: Bool) {
        self.storedTime = time
        self.storedStrong = isStrong
        self.storedUser = false
        self.storedFocus = .single(detectionID)
    }

    public init(time: CMTime, detectionGroupID: CNDetectionGroupID, strong isStrong: Bool) {
        self.storedTime = time
        self.storedStrong = isStrong
        self.storedUser = false
        self.storedFocus = .group(detectionGroupID)
    }

    func markingUser(_ isUser: Bool) -> CNDecision {
        var copy = self
        copy.storedUser = isUser
        return copy
    }

    public static func == (a: CNDecision, b: CNDecision) -> Bool {
        a.storedTime == b.storedTime
            && a.storedStrong == b.storedStrong
            && a.storedUser == b.storedUser
            && a.storedFocus == b.storedFocus
    }
}

extension CNDecision.FocusDetectionID {
    public static func == (
        a: CNDecision.FocusDetectionID,
        b: CNDecision.FocusDetectionID
    ) -> Bool {
        switch (a, b) {
        case let (.single(lhs), .single(rhs)):
            return lhs == rhs
        case let (.group(lhs), .group(rhs)):
            return lhs == rhs
        default:
            return false
        }
    }
}
