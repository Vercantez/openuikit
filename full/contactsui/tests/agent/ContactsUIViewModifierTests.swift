@_spi(OpenUIKitHost) import ContactsUI
import Foundation

@MainActor
private func assertModifierTag(_ button: ContactAccessButton, contains needle: String) {
    let tags = ContactsUIHostControl.linuxModifierTags(button)
    precondition(tags.contains { $0.contains(needle) }, "missing \(needle) in \(tags)")
}

@MainActor
func testModifierBrightness() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.brightness(0.25)
    assertModifierTag(modified, contains: "brightness(0.25)")
}

@MainActor
func testModifierMonospaced() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.monospaced(true)
    assertModifierTag(modified, contains: "monospaced(true)")
}

@MainActor
func testModifierSaturation() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.saturation(0.4)
    assertModifierTag(modified, contains: "saturation(0.4)")
}

@MainActor
func testModifierUnredacted() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.unredacted()
    assertModifierTag(modified, contains: "unredacted()")
}

@MainActor
func testModifierColorInvert() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.colorInvert()
    assertModifierTag(modified, contains: "colorInvert()")
}

@MainActor
func testModifierLineSpacing() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.lineSpacing(2)
    assertModifierTag(modified, contains: "lineSpacing(2.0)")
}

@MainActor
func testModifierScaledToFit() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.scaledToFit()
    assertModifierTag(modified, contains: "scaledToFit()")
}

@MainActor
func testModifierSubmitScope() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.submitScope(true)
    assertModifierTag(modified, contains: "submitScope(true)")
}

@MainActor
func testModifierFindDisabled() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.findDisabled(true)
    assertModifierTag(modified, contains: "findDisabled(true)")
}

@MainActor
func testModifierLabelsHidden() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.labelsHidden()
    assertModifierTag(modified, contains: "labelsHidden()")
}

@MainActor
func testModifierMoveDisabled() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.moveDisabled(true)
    assertModifierTag(modified, contains: "moveDisabled(true)")
}

@MainActor
func testModifierScaledToFill() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.scaledToFill()
    assertModifierTag(modified, contains: "scaledToFill()")
}

@MainActor
func testModifierGeometryGroup() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.geometryGroup()
    assertModifierTag(modified, contains: "geometryGroup()")
}

@MainActor
func testModifierBaselineOffset() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.baselineOffset(1)
    assertModifierTag(modified, contains: "baselineOffset(1.0)")
}

@MainActor
func testModifierDeleteDisabled() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.deleteDisabled(true)
    assertModifierTag(modified, contains: "deleteDisabled(true)")
}

@MainActor
func testModifierLayoutPriority() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.layoutPriority(1.5)
    assertModifierTag(modified, contains: "layoutPriority(1.5)")
}

@MainActor
func testModifierListRowSpacing() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.listRowSpacing(4)
    assertModifierTag(modified, contains: "listRowSpacing(4.0)")
}

@MainActor
func testModifierScrollDisabled() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.scrollDisabled(true)
    assertModifierTag(modified, contains: "scrollDisabled(true)")
}

@MainActor
func testModifierGridCellColumns() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.gridCellColumns(2)
    assertModifierTag(modified, contains: "gridCellColumns(2)")
}

@MainActor
func testModifierMonospacedDigit() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.monospacedDigit()
    assertModifierTag(modified, contains: "monospacedDigit()")
}

@MainActor
func testModifierReplaceDisabled() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.replaceDisabled(true)
    assertModifierTag(modified, contains: "replaceDisabled(true)")
}

@MainActor
func testModifierSafeAreaPaddingLength() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.safeAreaPadding(4)
    assertModifierTag(modified, contains: "safeAreaPadding(length:4.0)")
}

@MainActor
func testModifierSafeAreaPaddingInsets() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.safeAreaPadding(EdgeInsets(top: 1, leading: 2, bottom: 3, trailing: 4))
    assertModifierTag(modified, contains: "safeAreaPadding(insets:1.0,2.0,3.0,4.0)")
}

@MainActor
func testModifierSafeAreaPaddingEdges() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.safeAreaPadding(.all, 6)
    assertModifierTag(modified, contains: "safeAreaPadding(edges:15,6.0)")
}

@MainActor
func testModifierStatusBarHidden() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.statusBarHidden(true)
    assertModifierTag(modified, contains: "statusBarHidden(true)")
}

@MainActor
func testModifierAllowsHitTesting() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.allowsHitTesting(false)
    assertModifierTag(modified, contains: "allowsHitTesting(false)")
}

@MainActor
func testModifierAllowsTightening() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.allowsTightening(true)
    assertModifierTag(modified, contains: "allowsTightening(true)")
}

@MainActor
func testModifierCompositingGroup() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.compositingGroup()
    assertModifierTag(modified, contains: "compositingGroup()")
}

@MainActor
func testModifierLuminanceToAlpha() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.luminanceToAlpha()
    assertModifierTag(modified, contains: "luminanceToAlpha()")
}

@MainActor
func testModifierPrivacySensitive() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.privacySensitive(true)
    assertModifierTag(modified, contains: "privacySensitive(true)")
}

@MainActor
func testModifierDefaultAppStorage() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.defaultAppStorage(UserDefaults.standard)
    assertModifierTag(modified, contains: "defaultAppStorage")
}

@MainActor
func testModifierSelectionDisabled() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.selectionDisabled(true)
    assertModifierTag(modified, contains: "selectionDisabled(true)")
}

@MainActor
func testModifierListSectionSpacingLength() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.listSectionSpacing(8)
    assertModifierTag(modified, contains: "listSectionSpacing(length:8.0)")
}

@MainActor
func testModifierListSectionSpacingToken() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.listSectionSpacing(.default)
    assertModifierTag(modified, contains: "listSectionSpacing(token:default)")
}

@MainActor
func testModifierMinimumScaleFactor() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.minimumScaleFactor(0.8)
    assertModifierTag(modified, contains: "minimumScaleFactor(0.8)")
}

@MainActor
func testModifierNavigationDocumentPreviewBoth() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.navigationDocument("doc", preview: SharePreview<String, Int>())
    assertModifierTag(modified, contains: "navigationDocument(preview:String,Int)")
}

@MainActor
func testModifierNavigationDocumentPreviewIcon() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.navigationDocument("doc", preview: SharePreview<String, Never>())
    assertModifierTag(modified, contains: "navigationDocument(preview:String,Never)")
}

@MainActor
func testModifierNavigationDocumentPreviewNeverNever() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.navigationDocument("doc", preview: SharePreview<Never, Never>())
    assertModifierTag(modified, contains: "navigationDocument(preview:Never,Never)")
}

@MainActor
func testModifierNavigationDocumentPreviewLabel() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.navigationDocument("doc", preview: SharePreview<Never, String>())
    assertModifierTag(modified, contains: "navigationDocument(preview:Never,String)")
}

@MainActor
func testModifierNavigationDocumentURL() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.navigationDocument(URL(string: "https://example.com")!)
    assertModifierTag(modified, contains: "navigationDocument(url:https://example.com)")
}

@MainActor
func testModifierNavigationDocumentTransferable() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.navigationDocument("payload")
    assertModifierTag(modified, contains: "navigationDocument(transferable:payload)")
}

@MainActor
func testModifierNavigationBarHidden() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.navigationBarHidden(true)
    assertModifierTag(modified, contains: "navigationBarHidden(true)")
}

@MainActor
func testModifierDisableAutocorrection() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.disableAutocorrection(true)
    assertModifierTag(modified, contains: "disableAutocorrection(true)")
}

@MainActor
func testModifierLabelReservedIconWidth() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.labelReservedIconWidth(12)
    assertModifierTag(modified, contains: "labelReservedIconWidth(12.0)")
}

@MainActor
func testModifierLabelIconToTitleSpacing() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.labelIconToTitleSpacing(4)
    assertModifierTag(modified, contains: "labelIconToTitleSpacing(4.0)")
}

@MainActor
func testModifierBold() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.bold(true)
    assertModifierTag(modified, contains: "bold(true)")
}

@MainActor
func testModifierBadgeLocalizedStringResource() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.badge(LocalizedStringResource("res"))
    assertModifierTag(modified, contains: "badge(resource:res)")
}

@MainActor
func testModifierBadgeLocalizedStringKey() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.badge(LocalizedStringKey("key"))
    assertModifierTag(modified, contains: "badge(key:key)")
}

@MainActor
func testModifierBadgeText() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.badge(Text("hi"))
    assertModifierTag(modified, contains: "badge(text:hi)")
}

@MainActor
func testModifierBadgeInt() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.badge(3)
    assertModifierTag(modified, contains: "badge(count:3)")
}

@MainActor
func testModifierBadgeStringProtocol() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.badge("label" as String?)
    assertModifierTag(modified, contains: "badge(string:label)")
}

@MainActor
func testModifierFrameWidthHeight() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.frame(width: 100, height: 40, alignment: .center)
    assertModifierTag(modified, contains: "frame(width:100.0,height:40.0)")
}

@MainActor
func testModifierFrameMinIdealMax() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.frame(minWidth: 10, idealWidth: 20, maxWidth: 30, minHeight: 40, idealHeight: 50, maxHeight: 60, alignment: .center)
    assertModifierTag(modified, contains: "frame(minIdealMax:10.0,20.0,30.0,40.0,50.0,60.0)")
}

@MainActor
func testModifierFrameEmpty() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.frame()
    assertModifierTag(modified, contains: "frame()")
}

@MainActor
func testModifierHidden() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.hidden()
    assertModifierTag(modified, contains: "hidden()")
}

@MainActor
func testModifierItalic() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.italic(true)
    assertModifierTag(modified, contains: "italic(true)")
}

@MainActor
func testModifierOffsetXY() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.offset(x: 1, y: 2)
    assertModifierTag(modified, contains: "offset(x:1.0,y:2.0)")
}

@MainActor
func testModifierOffsetSize() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.offset(CGSize(width: 3, height: 4))
    assertModifierTag(modified, contains: "offset(size:3.0x4.0)")
}

@MainActor
func testModifierZIndex() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.zIndex(2.5)
    assertModifierTag(modified, contains: "zIndex(2.5)")
}

@MainActor
func testModifierClipped() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.clipped(antialiased: true)
    assertModifierTag(modified, contains: "clipped(antialiased:true)")
}

@MainActor
func testModifierKerning() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.kerning(0.2)
    assertModifierTag(modified, contains: "kerning(0.2)")
}

@MainActor
func testModifierOpacity() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.opacity(0.5)
    assertModifierTag(modified, contains: "opacity(0.5)")
}

@MainActor
func testModifierPaddingLength() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.padding(8)
    assertModifierTag(modified, contains: "padding(length:8.0)")
}

@MainActor
func testModifierPaddingInsets() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.padding(EdgeInsets(top: 1, leading: 1, bottom: 1, trailing: 1))
    assertModifierTag(modified, contains: "padding(insets:1.0,1.0,1.0,1.0)")
}

@MainActor
func testModifierPaddingEdges() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.padding(.all, 8)
    assertModifierTag(modified, contains: "padding(edges:15,8.0)")
}

@MainActor
func testModifierContrast() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.contrast(1.1)
    assertModifierTag(modified, contains: "contrast(1.1)")
}

@MainActor
func testModifierDisabled() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.disabled(true)
    assertModifierTag(modified, contains: "disabled(true)")
}

@MainActor
func testModifierTracking() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.tracking(0.1)
    assertModifierTag(modified, contains: "tracking(0.1)")
}

@MainActor
func testModifierFixedSizeHV() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.fixedSize(horizontal: true, vertical: false)
    assertModifierTag(modified, contains: "fixedSize(horizontal:true,vertical:false)")
}

@MainActor
func testModifierFixedSize() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.fixedSize()
    assertModifierTag(modified, contains: "fixedSize()")
}

@MainActor
func testModifierFocusableInteractions() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.focusable(true, interactions: .automatic)
    assertModifierTag(modified, contains: "focusable(interactions:automatic)")
}

@MainActor
func testModifierFocusable() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.focusable(true)
    assertModifierTag(modified, contains: "focusable(true)")
}

@MainActor
func testModifierGrayscale() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.grayscale(0.2)
    assertModifierTag(modified, contains: "grayscale(0.2)")
}

@MainActor
func testModifierLineLimitReservesSpace() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.lineLimit(2, reservesSpace: true)
    assertModifierTag(modified, contains: "lineLimit(2,reservesSpace:true)")
}

@MainActor
func testModifierLineLimitClosedRange() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.lineLimit(1...3)
    assertModifierTag(modified, contains: "lineLimit(closed:1...3)")
}

@MainActor
func testModifierLineLimitOptionalInt() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.lineLimit(2 as Int?)
    assertModifierTag(modified, contains: "lineLimit(optional:2)")
}

@MainActor
func testModifierLineLimitPartialFrom() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.lineLimit(2...)
    assertModifierTag(modified, contains: "lineLimit(from:2)")
}

@MainActor
func testModifierLineLimitPartialThrough() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.lineLimit(...4)
    assertModifierTag(modified, contains: "lineLimit(through:4)")
}
