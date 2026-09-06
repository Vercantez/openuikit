import Foundation
@_spi(OpenUIKitHost) import FamilyControls

func testIconViewConstruct() {
    let view = FamilyActivityIconView()
    precondition(type(of: view) == FamilyActivityIconView.self)
}

func testIconViewBody() {
    let view = FamilyActivityIconView()
    let empty: FamilyActivityIconView.Body = EmptyView()
    let body: FamilyActivityIconView.Body = view.body
    _ = empty
    _ = body
}

func testIconViewFamilyActivityPickerModifier() {
    let box = FamilyControlsHostControl.selectionBindingBox(FamilyActivitySelection())
    let presented = BoolBox(false)
    let modified = FamilyActivityIconView().familyActivityPicker(
        isPresented: FamilyControlsHostControl.boolBinding(to: presented),
        selection: FamilyControlsHostControl.binding(to: box)
    )
    _ = modified
}

func testIconViewFamilyActivityPickerModifierHeader() {
    let box = FamilyControlsHostControl.selectionBindingBox(FamilyActivitySelection())
    let presented = BoolBox(true)
    let modified = FamilyActivityIconView().familyActivityPicker(
        headerText: "Apps",
        footerText: nil,
        isPresented: FamilyControlsHostControl.boolBinding(to: presented),
        selection: FamilyControlsHostControl.binding(to: box)
    )
    _ = modified
    precondition(presented.value == true)
}

func testTitleViewConstruct() {
    let view = FamilyActivityTitleView()
    precondition(type(of: view) == FamilyActivityTitleView.self)
}

func testTitleViewBody() {
    let view = FamilyActivityTitleView()
    let empty: FamilyActivityTitleView.Body = EmptyView()
    let body: FamilyActivityTitleView.Body = view.body
    _ = empty
    _ = body
}

func testTitleViewFamilyActivityPickerModifier() {
    let box = FamilyControlsHostControl.selectionBindingBox(FamilyActivitySelection())
    let presented = BoolBox(false)
    let modified = FamilyActivityTitleView().familyActivityPicker(
        isPresented: FamilyControlsHostControl.boolBinding(to: presented),
        selection: FamilyControlsHostControl.binding(to: box)
    )
    _ = modified
}

func testTitleViewFamilyActivityPickerModifierHeader() {
    let box = FamilyControlsHostControl.selectionBindingBox(FamilyActivitySelection())
    let presented = BoolBox(false)
    let modified = FamilyActivityTitleView().familyActivityPicker(
        headerText: nil,
        footerText: "Footer",
        isPresented: FamilyControlsHostControl.boolBinding(to: presented),
        selection: FamilyControlsHostControl.binding(to: box)
    )
    _ = modified
}
