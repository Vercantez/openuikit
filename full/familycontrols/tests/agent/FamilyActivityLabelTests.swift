import Foundation
@_spi(OpenUIKitHost) import FamilyControls

func testLabelApplicationToken() {
    let token = ApplicationToken()
    let label = Label<FamilyActivityTitleView, FamilyActivityIconView>(token)
    _ = label.body
    precondition(type(of: label) == Label<FamilyActivityTitleView, FamilyActivityIconView>.self)
}

func testLabelCategoryToken() {
    let token = ActivityCategoryToken()
    let label = Label<FamilyActivityTitleView, FamilyActivityIconView>(token)
    _ = label.body
}

func testLabelWebDomainToken() {
    let token = WebDomainToken()
    let label = Label<FamilyActivityTitleView, FamilyActivityIconView>(token)
    _ = label.body
}

func testFamilyActivityPickerModifier() {
    let box = FamilyControlsHostControl.selectionBindingBox(FamilyActivitySelection())
    let presented = BoolBox(true)
    let view = EmptyView().familyActivityPicker(
        isPresented: FamilyControlsHostControl.boolBinding(to: presented),
        selection: FamilyControlsHostControl.binding(to: box)
    )
    _ = view
    precondition(presented.value == true)
}

func testFamilyActivityPickerModifierWithHeader() {
    let box = FamilyControlsHostControl.selectionBindingBox(
        FamilyActivitySelection(includeEntireCategory: true)
    )
    let presented = BoolBox(false)
    let view = EmptyView().familyActivityPicker(
        headerText: "Choose",
        footerText: "Done",
        isPresented: FamilyControlsHostControl.boolBinding(to: presented),
        selection: FamilyControlsHostControl.binding(to: box)
    )
    _ = view
    precondition(box.value.includeEntireCategory == true)
}
