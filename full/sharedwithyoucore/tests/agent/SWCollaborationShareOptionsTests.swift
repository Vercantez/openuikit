@_spi(OpenUIKitHost) import SharedWithYouCore
import Foundation

private func swcArchiveRoundTrip<T: NSObject & NSSecureCoding>(_ value: T) -> T {
    let data: Data
    do {
        data = try NSKeyedArchiver.archivedData(withRootObject: value, requiringSecureCoding: true)
    } catch {
        preconditionFailure("archive failed: \(error)")
    }
    do {
        guard let restored = try NSKeyedUnarchiver.unarchivedObject(ofClass: T.self, from: data) else {
            preconditionFailure("expected restored \(T.self)")
        }
        return restored
    } catch {
        preconditionFailure("unarchive failed: \(error)")
    }
}

func testSWCollaborationShareOptionsClass() {
    let share = SWCollaborationShareOptions(optionsGroups: [])
    swcRequireType(share, as: SWCollaborationShareOptions.self)
}

func testSWCollaborationShareOptionsInitOptionsGroupsSummary() {
    let option = SWCollaborationOption(title: "Anyone", identifier: "anyone")
    let group = SWCollaborationOptionsGroup(identifier: "perm", options: [option])
    let share = SWCollaborationShareOptions(optionsGroups: [group], summary: "Anyone can edit")
    precondition(share.optionsGroups.count == 1)
    precondition(share.summary == "Anyone can edit")
}

func testSWCollaborationShareOptionsInitOptionsGroups() {
    let option = SWCollaborationOption(title: "Anyone", identifier: "anyone")
    let group = SWCollaborationOptionsGroup(identifier: "perm", options: [option])
    let share = SWCollaborationShareOptions(optionsGroups: [group])
    precondition(share.optionsGroups.count == 1)
    precondition(share.summary == "")
}

func testSWCollaborationShareOptionsOptionsGroups() {
    let option = SWCollaborationOption(title: "Anyone", identifier: "anyone")
    let group = SWCollaborationOptionsGroup(identifier: "perm", options: [option])
    let share = SWCollaborationShareOptions(optionsGroups: [])
    precondition(share.optionsGroups.isEmpty)
    share.optionsGroups = [group]
    precondition(share.optionsGroups[0].identifier == "perm")
}

func testSWCollaborationShareOptionsSummary() {
    let share = SWCollaborationShareOptions(optionsGroups: [], summary: "Initial")
    precondition(share.summary == "Initial")
    share.summary = "Updated"
    precondition(share.summary == "Updated")
}

func testSWCollaborationShareOptionsInitCoder() {
    let option = SWCollaborationOption(title: "Anyone", identifier: "anyone")
    let group = SWCollaborationOptionsGroup(identifier: "perm", options: [option])
    let share = SWCollaborationShareOptions(optionsGroups: [group], summary: "Anyone can edit")
    let restored = swcArchiveRoundTrip(share)
    precondition(restored.summary == "Anyone can edit")
    precondition(restored.optionsGroups.count == 1)
    precondition(restored.optionsGroups[0].identifier == "perm")
}
