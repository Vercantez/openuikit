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

private func swcRejectsEmptyCoder<T: NSObject & NSSecureCoding>(_ type: T.Type) {
    do {
        let data = try NSKeyedArchiver.archivedData(
            withRootObject: "swc-malformed",
            requiringSecureCoding: true
        )
        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
        unarchiver.requiresSecureCoding = true
        precondition(type.init(coder: unarchiver) == nil)
    } catch {
        preconditionFailure("malformed archive setup failed: \(error)")
    }
}

func testSWCollaborationOptionsGroupClass() {
    let option = SWCollaborationOption(title: "Anyone", identifier: "anyone")
    let group = SWCollaborationOptionsGroup(identifier: "perm", options: [option])
    swcRequireType(group, as: SWCollaborationOptionsGroup.self)
}

func testSWCollaborationOptionsGroupInitIdentifierOptions() {
    let option = SWCollaborationOption(title: "Anyone", identifier: "anyone")
    let group = SWCollaborationOptionsGroup(identifier: "perm", options: [option])
    precondition(group.identifier == "perm")
    precondition(group.options.count == 1)
    precondition(group.options[0].identifier == "anyone")
    precondition(group.title == "")
    precondition(group.footer == "")
}

func testSWCollaborationOptionsGroupIdentifier() {
    let group = SWCollaborationOptionsGroup(identifier: "access", options: [])
    precondition(group.identifier == "access")
}

func testSWCollaborationOptionsGroupTitle() {
    let group = SWCollaborationOptionsGroup(identifier: "perm", options: [])
    group.title = "Permissions"
    precondition(group.title == "Permissions")
}

func testSWCollaborationOptionsGroupFooter() {
    let group = SWCollaborationOptionsGroup(identifier: "perm", options: [])
    group.footer = "Applies to everyone"
    precondition(group.footer == "Applies to everyone")
}

func testSWCollaborationOptionsGroupOptions() {
    let first = SWCollaborationOption(title: "Anyone", identifier: "anyone")
    let group = SWCollaborationOptionsGroup(identifier: "perm", options: [first])
    precondition(group.options.count == 1)
    let second = SWCollaborationOption(title: "Invite", identifier: "invite")
    group.options = [first, second]
    precondition(group.options.map(\.identifier) == ["anyone", "invite"])
    group.options[0].title = "mutated copy"
    precondition(first.title == "Anyone")
}

func testSWCollaborationOptionsGroupInitCoder() {
    let option = SWCollaborationOption(title: "Anyone", identifier: "anyone")
    let group = SWCollaborationOptionsGroup(identifier: "perm", options: [option])
    group.title = "Permissions"
    group.footer = "Footer"
    let restored = swcArchiveRoundTrip(group)
    precondition(restored.identifier == "perm")
    precondition(restored.title == "Permissions")
    precondition(restored.footer == "Footer")
    precondition(restored.options.count == 1)
    precondition(restored.options[0].identifier == "anyone")
    swcRejectsEmptyCoder(SWCollaborationOptionsGroup.self)
}
