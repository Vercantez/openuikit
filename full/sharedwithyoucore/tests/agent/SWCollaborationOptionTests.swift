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

func testSWCollaborationOptionClass() {
    let option = SWCollaborationOption(title: "Anyone", identifier: "anyone")
    swcRequireType(option, as: SWCollaborationOption.self)
}

func testSWCollaborationOptionInitTitleIdentifier() {
    let option = SWCollaborationOption(title: "Anyone", identifier: "anyone")
    precondition(option.title == "Anyone")
    precondition(option.identifier == "anyone")
    precondition(option.subtitle == "")
    precondition(option.isSelected == false)
    precondition(option.requiredOptionsIdentifiers.isEmpty)
}

func testSWCollaborationOptionIdentifier() {
    let option = SWCollaborationOption(title: "Only invited", identifier: "invited")
    precondition(option.identifier == "invited")
}

func testSWCollaborationOptionTitle() {
    let option = SWCollaborationOption(title: "Anyone", identifier: "anyone")
    option.title = "Everyone"
    precondition(option.title == "Everyone")
}

func testSWCollaborationOptionSubtitle() {
    let option = SWCollaborationOption(title: "Anyone", identifier: "anyone")
    precondition(option.subtitle == "")
    option.subtitle = "Can edit"
    precondition(option.subtitle == "Can edit")
}

func testSWCollaborationOptionIsSelected() {
    let option = SWCollaborationOption(title: "Anyone", identifier: "anyone")
    precondition(option.isSelected == false)
    option.isSelected = true
    precondition(option.isSelected == true)
}

func testSWCollaborationOptionRequiredOptionsIdentifiers() {
    let option = SWCollaborationOption(title: "Anyone", identifier: "anyone")
    precondition(option.requiredOptionsIdentifiers.isEmpty)
    option.requiredOptionsIdentifiers = ["notify", "confirm"]
    precondition(option.requiredOptionsIdentifiers == ["notify", "confirm"])
}

func testSWCollaborationOptionConvenienceInit() {
    let option = SWCollaborationOption(
        title: "Anyone",
        identifier: "anyone",
        subtitle: "Can edit",
        selected: true,
        requiredOptionsIdentifiers: ["notify"]
    )
    precondition(option.title == "Anyone")
    precondition(option.identifier == "anyone")
    precondition(option.subtitle == "Can edit")
    precondition(option.isSelected)
    precondition(option.requiredOptionsIdentifiers == ["notify"])
    let defaults = SWCollaborationOption(title: "Defaulted", identifier: "defaulted")
    precondition(defaults.subtitle == "")
    precondition(defaults.isSelected == false)
    precondition(defaults.requiredOptionsIdentifiers.isEmpty)
}

func testSWCollaborationOptionInitCoder() {
    let option = SWCollaborationOption(
        title: "Anyone",
        identifier: "anyone",
        subtitle: "Can edit",
        selected: true,
        requiredOptionsIdentifiers: ["notify"]
    )
    let restored = swcArchiveRoundTrip(option)
    precondition(restored.title == "Anyone")
    precondition(restored.identifier == "anyone")
    precondition(restored.subtitle == "Can edit")
    precondition(restored.isSelected)
    precondition(restored.requiredOptionsIdentifiers == ["notify"])
    swcRejectsEmptyCoder(SWCollaborationOption.self)
}
