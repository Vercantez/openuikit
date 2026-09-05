import PencilKit
import Foundation

final class PickerProbe: PKToolPickerObserver {
    var selected = 0
    var selectedItem = 0
    var ruler = 0
    var visible = 0
    var frames = 0

    func toolPickerSelectedToolDidChange(_ toolPicker: PKToolPicker) { selected += 1 }
    func toolPickerSelectedToolItemDidChange(_ toolPicker: PKToolPicker) { selectedItem += 1 }
    func toolPickerIsRulerActiveDidChange(_ toolPicker: PKToolPicker) { ruler += 1 }
    func toolPickerVisibilityDidChange(_ toolPicker: PKToolPicker) { visible += 1 }
    func toolPickerFramesObscuredDidChange(_ toolPicker: PKToolPicker) { frames += 1 }
}

func testPKToolPickerDefaultItems() {
    let items = PKToolPicker.defaultToolItems
    pkExpectEqual(items.count, 6, "default count")
    let picker = PKToolPicker()
    pkExpectEqual(picker.toolItems.count, 6, "init items")
    pkExpect(!picker.isVisible, "hidden")
    pkExpectEqual(picker.colorMaximumLinearExposure, 1, "exposure")
    pkExpectEqual(picker.colorUserInterfaceStyle, .unspecified, "color style")
    pkExpectEqual(picker.overrideUserInterfaceStyle, .unspecified, "override")
    pkExpect(picker.showsDrawingPolicyControls, "policy chrome")
    pkExpectEqual(picker.maximumSupportedContentVersion, .latest, "version")
    pkExpect(picker.accessoryItem == nil, "accessory")
    pkExpect(picker.stateAutosaveName == nil, "autosave")
    pkExpect(picker.delegate == nil, "delegate")
}

func testPKToolPickerSelectionAndObservers() {
    let picker = PKToolPicker()
    let probe = PickerProbe()
    picker.addObserver(probe)
    let original = picker.selectedToolItemIdentifier
    if let next = picker.toolItems.dropFirst().first {
        picker.selectedToolItem = next
        pkExpectEqual(picker.selectedToolItemIdentifier, next.identifier, "selected id")
        pkExpectEqual(probe.selected, 1, "selected tool")
        pkExpectEqual(probe.selectedItem, 1, "selected item")
    }
    picker.selectedToolItemIdentifier = original
    picker.selectedTool = PKLassoTool()
    pkExpect(picker.selectedTool is PKLassoTool, "lasso selected")
    picker.isRulerActive = true
    pkExpectEqual(probe.ruler, 1, "ruler")
    picker.removeObserver(probe)
    picker.isRulerActive = false
    pkExpectEqual(probe.ruler, 1, "removed observer silent")
}

func testPKToolPickerVisibilityPerResponder() {
    let picker = PKToolPicker()
    let probe = PickerProbe()
    picker.addObserver(probe)
    let responder = PencilKitResponder()
    picker.setVisible(true, forFirstResponder: responder)
    pkExpect(picker.isVisible, "visible")
    pkExpectEqual(probe.visible, 1, "visibility callback")
    pkExpectEqual(probe.frames, 1, "frames callback")
    picker.setVisible(false, forFirstResponder: responder)
    pkExpect(!picker.isVisible, "hidden again")
}

func testPKToolPickerCustomItem() {
    var configuration = PKToolPickerCustomItem.Configuration(identifier: "custom.brush", name: "Brush")
    pkExpectEqual(configuration.identifier, "custom.brush", "id")
    pkExpectEqual(configuration.name, "Brush", "name")
    configuration.defaultWidth = 7
    configuration.allowsColorSelection = false
    configuration.toolAttributeControls = [.width]
    configuration.widthVariants = [7: PencilKitImage(size: CGSize(width: 8, height: 8))]
    configuration.imageProvider = { _ in PencilKitImage(size: CGSize(width: 4, height: 4)) }
    configuration.viewControllerProvider = { _ in PencilKitViewController() }
    let item = PKToolPickerCustomItem(configuration: configuration)
    pkExpectEqual(item.identifier, "custom.brush", "item id")
    pkExpectEqual(item.width, 7, "width")
    pkExpect(!item.allowsColorSelection, "color")
    item.reloadImage()
    pkExpectEqual(item.imageReloadCount, 1, "reload")
    item.color = .white
    item.width = 9
    item.allowsColorSelection = true
    _ = item.configuration
    _ = item.tool
}

func testPKToolPickerEraserInkingLassoRulerScribble() {
    let eraser = PKToolPickerEraserItem(type: .bitmap)
    pkExpectEqual(eraser.eraserTool.eraserType, .bitmap, "eraser")
    let sized = PKToolPickerEraserItem(type: .vector, width: 14)
    pkExpectEqual(sized.eraserTool.width, 14, "eraser width")
    let ink = PKToolPickerInkingItem(type: .fountainPen, color: .black, width: 6, identifier: "ink.custom")
    pkExpectEqual(ink.identifier, "ink.custom", "ink id")
    pkExpectEqual(ink.inkingTool.width, 6, "ink width")
    pkExpect(ink.allowsColorSelection, "allows color")
    let azimuth = PKToolPickerInkingItem(
        type: .pen,
        color: .black,
        width: 4,
        azimuth: 0.5,
        identifier: nil
    )
    pkExpectEqual(azimuth.inkingTool.azimuth, 0.5, "azimuth")
    let lasso = PKToolPickerLassoItem()
    pkExpect(lasso.lassoTool == PKLassoTool(), "lasso")
    _ = PKToolPickerRulerItem()
    _ = PKToolPickerScribbleItem()
    let customPicker = PKToolPicker(toolItems: [ink, eraser, lasso])
    pkExpectEqual(customPicker.toolItems.count, 3, "custom items")
}

func testPKToolPickerSharedWindow() {
    let window = PencilKitWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
    let first = PKToolPicker.shared(for: window)
    let second = PKToolPicker.shared(for: window)
    pkExpect(first != nil, "shared exists")
    pkExpect(first === second, "same instance")
}

func testPKToolPickerFrameObscuredFailClosed() {
    let picker = PKToolPicker()
    let view = PencilKitView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
    pkExpectEqual(picker.frameObscured(in: view), .zero, "no chrome")
}

func testPKResponderState() {
    let state = PKResponderState()
    pkExpect(state.activeToolPicker == nil, "no picker")
    pkExpect(state.toolPickerVisibility == nil, "no visibility")
    let picker = PKToolPicker()
    state.activeToolPicker = picker
    state.toolPickerVisibility = .visible
    pkExpect(state.activeToolPicker === picker, "picker set")
    pkExpectEqual(state.toolPickerVisibility, .visible, "visibility")
    let responder = PencilKitResponder()
    _ = responder.pencilKitResponderState
    pkExpect(responder.becomeFirstResponder(), "become")
    pkExpect(responder.isFirstResponder, "first")
    pkExpect(responder.resignFirstResponder(), "resign")
}
