@_spi(OpenUIKitHost) import SharedWithYouCore
import Foundation

func testSWCollaborationOptionsPickerGroupClass() {
    let anyone = SWCollaborationOption(title: "Anyone", identifier: "anyone")
    let invite = SWCollaborationOption(title: "Invite", identifier: "invite")
    let picker = SWCollaborationOptionsPickerGroup(identifier: "perm", options: [anyone, invite])
    swcRequireType(picker, as: SWCollaborationOptionsPickerGroup.self)
    swcRequireType(picker, as: SWCollaborationOptionsGroup.self)
}

func testSWCollaborationOptionsPickerGroupSelectedOptionIdentifier() {
    let anyone = SWCollaborationOption(title: "Anyone", identifier: "anyone")
    let invite = SWCollaborationOption(title: "Invite", identifier: "invite")
    let picker = SWCollaborationOptionsPickerGroup(identifier: "perm", options: [anyone, invite])
    precondition(picker.selectedOptionIdentifier == "anyone")
    precondition(picker.options[0].isSelected)
    precondition(picker.options[1].isSelected == false)
    picker.selectedOptionIdentifier = "invite"
    precondition(picker.selectedOptionIdentifier == "invite")
    precondition(picker.options[0].isSelected == false)
    precondition(picker.options[1].isSelected)
}
