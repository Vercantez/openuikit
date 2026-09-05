import Foundation
@_spi(OpenUIKitHost) import FamilyControls

func testPickerConstruct() {
    let box = FamilyControlsHostControl.selectionBindingBox(FamilyActivitySelection())
    let binding = FamilyControlsHostControl.binding(to: box)
    let picker = FamilyActivityPicker(selection: binding)
    precondition(type(of: picker) == FamilyActivityPicker.self)
    precondition(picker.hostHeaderText == nil)
    precondition(picker.hostFooterText == nil)
    precondition(box.value.includeEntireCategory == false)
}

func testPickerHeaderFooterInit() {
    let box = FamilyControlsHostControl.selectionBindingBox(
        FamilyActivitySelection(includeEntireCategory: true)
    )
    let binding = FamilyControlsHostControl.binding(to: box)
    let picker = FamilyActivityPicker(
        headerText: "Header",
        footerText: "Footer",
        selection: binding
    )
    precondition(picker.hostHeaderText == "Header")
    precondition(picker.hostFooterText == "Footer")
    let omitted = FamilyActivityPicker(
        headerText: nil,
        footerText: nil,
        selection: binding
    )
    precondition(omitted.hostHeaderText == nil)
    precondition(omitted.hostFooterText == nil)
}

func testPickerBody() {
    let box = FamilyControlsHostControl.selectionBindingBox(FamilyActivitySelection())
    let picker = FamilyActivityPicker(selection: FamilyControlsHostControl.binding(to: box))
    let empty: FamilyActivityPicker.Body = EmptyView()
    let body: FamilyActivityPicker.Body = picker.body
    _ = empty
    _ = body
}

func testPickerFamilyActivityPickerModifier() {
    let box = FamilyControlsHostControl.selectionBindingBox(FamilyActivitySelection())
    let presented = BoolBox(true)
    let picker = FamilyActivityPicker(selection: FamilyControlsHostControl.binding(to: box))
    let modified = picker.familyActivityPicker(
        isPresented: FamilyControlsHostControl.boolBinding(to: presented),
        selection: FamilyControlsHostControl.binding(to: box)
    )
    _ = modified
    precondition(presented.value == true)
    precondition(box.value.includeEntireCategory == false)
}

func testPickerFamilyActivityPickerModifierHeader() {
    let box = FamilyControlsHostControl.selectionBindingBox(FamilyActivitySelection())
    let presented = BoolBox(false)
    let picker = FamilyActivityPicker(selection: FamilyControlsHostControl.binding(to: box))
    let modified = picker.familyActivityPicker(
        headerText: "H",
        footerText: "F",
        isPresented: FamilyControlsHostControl.boolBinding(to: presented),
        selection: FamilyControlsHostControl.binding(to: box)
    )
    _ = modified
    precondition(presented.value == false)
}
