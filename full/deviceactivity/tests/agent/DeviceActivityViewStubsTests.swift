import DeviceActivity
import Foundation

func testDeviceActivityReportStubNavigationViewStyle() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.navigationViewStyle(0)
    deviceActivityRequire(styled.context == report.context, "navigationViewStyle preserves context")
    deviceActivityRequire(styled.filter == report.filter, "navigationViewStyle preserves filter")
}

func testDeviceActivityReportStubNavigationSplitViewColumnWidth() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.navigationSplitViewColumnWidth(0)
    deviceActivityRequire(styled.context == report.context, "navigationSplitViewColumnWidth preserves context")
    deviceActivityRequire(styled.filter == report.filter, "navigationSplitViewColumnWidth preserves filter")
}

func testDeviceActivityReportStubNavigationSplitViewStyle() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.navigationSplitViewStyle(0)
    deviceActivityRequire(styled.context == report.context, "navigationSplitViewStyle preserves context")
    deviceActivityRequire(styled.filter == report.filter, "navigationSplitViewStyle preserves filter")
}

func testDeviceActivityReportStubTabViewCustomization() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.tabViewCustomization(0)
    deviceActivityRequire(styled.context == report.context, "tabViewCustomization preserves context")
    deviceActivityRequire(styled.filter == report.filter, "tabViewCustomization preserves filter")
}

func testDeviceActivityReportStubTabViewSidebarFooter() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.tabViewSidebarFooter(0)
    deviceActivityRequire(styled.context == report.context, "tabViewSidebarFooter preserves context")
    deviceActivityRequire(styled.filter == report.filter, "tabViewSidebarFooter preserves filter")
}

func testDeviceActivityReportStubTabViewSidebarHeader() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.tabViewSidebarHeader(0)
    deviceActivityRequire(styled.context == report.context, "tabViewSidebarHeader preserves context")
    deviceActivityRequire(styled.filter == report.filter, "tabViewSidebarHeader preserves filter")
}

func testDeviceActivityReportStubTabViewBottomAccessory() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.tabViewBottomAccessory(0)
    deviceActivityRequire(styled.context == report.context, "tabViewBottomAccessory preserves context")
    deviceActivityRequire(styled.filter == report.filter, "tabViewBottomAccessory preserves filter")
}

func testDeviceActivityReportStubTabViewSearchActivation() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.tabViewSearchActivation(0)
    deviceActivityRequire(styled.context == report.context, "tabViewSearchActivation preserves context")
    deviceActivityRequire(styled.filter == report.filter, "tabViewSearchActivation preserves filter")
}

func testDeviceActivityReportStubTabViewSidebarBottomBar() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.tabViewSidebarBottomBar(0)
    deviceActivityRequire(styled.context == report.context, "tabViewSidebarBottomBar preserves context")
    deviceActivityRequire(styled.filter == report.filter, "tabViewSidebarBottomBar preserves filter")
}

func testDeviceActivityReportStubTabViewStyle() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.tabViewStyle(0)
    deviceActivityRequire(styled.context == report.context, "tabViewStyle preserves context")
    deviceActivityRequire(styled.filter == report.filter, "tabViewStyle preserves filter")
}

func testDeviceActivityReportStubIndexViewStyle() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.indexViewStyle(0)
    deviceActivityRequire(styled.context == report.context, "indexViewStyle preserves context")
    deviceActivityRequire(styled.filter == report.filter, "indexViewStyle preserves filter")
}

func testDeviceActivityReportStubProgressViewStyle() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.progressViewStyle(0)
    deviceActivityRequire(styled.context == report.context, "progressViewStyle preserves context")
    deviceActivityRequire(styled.filter == report.filter, "progressViewStyle preserves filter")
}

func testDeviceActivityReportStubBackground() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.background(0)
    deviceActivityRequire(styled.context == report.context, "background preserves context")
    deviceActivityRequire(styled.filter == report.filter, "background preserves filter")
}

func testDeviceActivityReportStubBrightness() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.brightness(0)
    deviceActivityRequire(styled.context == report.context, "brightness preserves context")
    deviceActivityRequire(styled.filter == report.filter, "brightness preserves filter")
}

func testDeviceActivityReportStubDialogIcon() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.dialogIcon(0)
    deviceActivityRequire(styled.context == report.context, "dialogIcon preserves context")
    deviceActivityRequire(styled.filter == report.filter, "dialogIcon preserves filter")
}

func testDeviceActivityReportStubFontDesign() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.fontDesign(0)
    deviceActivityRequire(styled.context == report.context, "fontDesign preserves context")
    deviceActivityRequire(styled.filter == report.filter, "fontDesign preserves filter")
}

func testDeviceActivityReportStubFontWeight() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.fontWeight(0)
    deviceActivityRequire(styled.context == report.context, "fontWeight preserves context")
    deviceActivityRequire(styled.filter == report.filter, "fontWeight preserves filter")
}

func testDeviceActivityReportStubGaugeStyle() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.gaugeStyle(0)
    deviceActivityRequire(styled.context == report.context, "gaugeStyle preserves context")
    deviceActivityRequire(styled.filter == report.filter, "gaugeStyle preserves filter")
}

func testDeviceActivityReportStubImageScale() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.imageScale(0)
    deviceActivityRequire(styled.context == report.context, "imageScale preserves context")
    deviceActivityRequire(styled.filter == report.filter, "imageScale preserves filter")
}

func testDeviceActivityReportStubLabelStyle() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.labelStyle(0)
    deviceActivityRequire(styled.context == report.context, "labelStyle preserves context")
    deviceActivityRequire(styled.filter == report.filter, "labelStyle preserves filter")
}

func testDeviceActivityReportStubLineHeight() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.lineHeight(0)
    deviceActivityRequire(styled.context == report.context, "lineHeight preserves context")
    deviceActivityRequire(styled.filter == report.filter, "lineHeight preserves filter")
}

func testDeviceActivityReportStubMonospaced() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.monospaced(0)
    deviceActivityRequire(styled.context == report.context, "monospaced preserves context")
    deviceActivityRequire(styled.filter == report.filter, "monospaced preserves filter")
}

func testDeviceActivityReportStubOnKeyPress() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.onKeyPress(0)
    deviceActivityRequire(styled.context == report.context, "onKeyPress preserves context")
    deviceActivityRequire(styled.filter == report.filter, "onKeyPress preserves filter")
}

func testDeviceActivityReportStubPreference() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.preference(0)
    deviceActivityRequire(styled.context == report.context, "preference preserves context")
    deviceActivityRequire(styled.filter == report.filter, "preference preserves filter")
}

func testDeviceActivityReportStubSaturation() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.saturation(0)
    deviceActivityRequire(styled.context == report.context, "saturation preserves context")
    deviceActivityRequire(styled.filter == report.filter, "saturation preserves filter")
}

func testDeviceActivityReportStubSearchable() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.searchable(0)
    deviceActivityRequire(styled.context == report.context, "searchable preserves context")
    deviceActivityRequire(styled.filter == report.filter, "searchable preserves filter")
}

func testDeviceActivityReportStubTableStyle() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.tableStyle(0)
    deviceActivityRequire(styled.context == report.context, "tableStyle preserves context")
    deviceActivityRequire(styled.filter == report.filter, "tableStyle preserves filter")
}

func testDeviceActivityReportStubTransition() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.transition(0)
    deviceActivityRequire(styled.context == report.context, "transition preserves context")
    deviceActivityRequire(styled.filter == report.filter, "transition preserves filter")
}

func testDeviceActivityReportStubUnredacted() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.unredacted(0)
    deviceActivityRequire(styled.context == report.context, "unredacted preserves context")
    deviceActivityRequire(styled.filter == report.filter, "unredacted preserves filter")
}

func testDeviceActivityReportStubAccentColor() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.accentColor(0)
    deviceActivityRequire(styled.context == report.context, "accentColor preserves context")
    deviceActivityRequire(styled.filter == report.filter, "accentColor preserves filter")
}

func testDeviceActivityReportStubActionSheet() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.actionSheet(0)
    deviceActivityRequire(styled.context == report.context, "actionSheet preserves context")
    deviceActivityRequire(styled.filter == report.filter, "actionSheet preserves filter")
}

func testDeviceActivityReportStubAspectRatio() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.aspectRatio(0)
    deviceActivityRequire(styled.context == report.context, "aspectRatio preserves context")
    deviceActivityRequire(styled.filter == report.filter, "aspectRatio preserves filter")
}

func testDeviceActivityReportStubButtonStyle() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.buttonStyle(0)
    deviceActivityRequire(styled.context == report.context, "buttonStyle preserves context")
    deviceActivityRequire(styled.filter == report.filter, "buttonStyle preserves filter")
}

func testDeviceActivityReportStubColorEffect() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.colorEffect(0)
    deviceActivityRequire(styled.context == report.context, "colorEffect preserves context")
    deviceActivityRequire(styled.filter == report.filter, "colorEffect preserves filter")
}

func testDeviceActivityReportStubColorInvert() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.colorInvert(0)
    deviceActivityRequire(styled.context == report.context, "colorInvert preserves context")
    deviceActivityRequire(styled.filter == report.filter, "colorInvert preserves filter")
}

func testDeviceActivityReportStubColorScheme() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.colorScheme(0)
    deviceActivityRequire(styled.context == report.context, "colorScheme preserves context")
    deviceActivityRequire(styled.filter == report.filter, "colorScheme preserves filter")
}

func testDeviceActivityReportStubContextMenu() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.contextMenu(0)
    deviceActivityRequire(styled.context == report.context, "contextMenu preserves context")
    deviceActivityRequire(styled.filter == report.filter, "contextMenu preserves filter")
}

func testDeviceActivityReportStubControlSize() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.controlSize(0)
    deviceActivityRequire(styled.context == report.context, "controlSize preserves context")
    deviceActivityRequire(styled.filter == report.filter, "controlSize preserves filter")
}

func testDeviceActivityReportStubEnvironment() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.environment(0)
    deviceActivityRequire(styled.context == report.context, "environment preserves context")
    deviceActivityRequire(styled.filter == report.filter, "environment preserves filter")
}

func testDeviceActivityReportStubGlassEffect() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.glassEffect(0)
    deviceActivityRequire(styled.context == report.context, "glassEffect preserves context")
    deviceActivityRequire(styled.filter == report.filter, "glassEffect preserves filter")
}

func testDeviceActivityReportStubHoverEffect() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.hoverEffect(0)
    deviceActivityRequire(styled.context == report.context, "hoverEffect preserves context")
    deviceActivityRequire(styled.filter == report.filter, "hoverEffect preserves filter")
}

func testDeviceActivityReportStubHueRotation() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.hueRotation(0)
    deviceActivityRequire(styled.context == report.context, "hueRotation preserves context")
    deviceActivityRequire(styled.filter == report.filter, "hueRotation preserves filter")
}

func testDeviceActivityReportStubLayerEffect() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.layerEffect(0)
    deviceActivityRequire(styled.context == report.context, "layerEffect preserves context")
    deviceActivityRequire(styled.filter == report.filter, "layerEffect preserves filter")
}

func testDeviceActivityReportStubLayoutValue() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.layoutValue(0)
    deviceActivityRequire(styled.context == report.context, "layoutValue preserves context")
    deviceActivityRequire(styled.filter == report.filter, "layoutValue preserves filter")
}

func testDeviceActivityReportStubLineSpacing() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.lineSpacing(0)
    deviceActivityRequire(styled.context == report.context, "lineSpacing preserves context")
    deviceActivityRequire(styled.filter == report.filter, "lineSpacing preserves filter")
}

func testDeviceActivityReportStubOnDisappear() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.onDisappear(0)
    deviceActivityRequire(styled.context == report.context, "onDisappear preserves context")
    deviceActivityRequire(styled.filter == report.filter, "onDisappear preserves filter")
}

func testDeviceActivityReportStubPickerStyle() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.pickerStyle(0)
    deviceActivityRequire(styled.context == report.context, "pickerStyle preserves context")
    deviceActivityRequire(styled.filter == report.filter, "pickerStyle preserves filter")
}

func testDeviceActivityReportStubRefreshable() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.refreshable(0)
    deviceActivityRequire(styled.context == report.context, "refreshable preserves context")
    deviceActivityRequire(styled.filter == report.filter, "refreshable preserves filter")
}

func testDeviceActivityReportStubSafeAreaBar() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.safeAreaBar(0)
    deviceActivityRequire(styled.context == report.context, "safeAreaBar preserves context")
    deviceActivityRequire(styled.filter == report.filter, "safeAreaBar preserves filter")
}

func testDeviceActivityReportStubScaleEffect() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.scaleEffect(0)
    deviceActivityRequire(styled.context == report.context, "scaleEffect preserves context")
    deviceActivityRequire(styled.filter == report.filter, "scaleEffect preserves filter")
}

func testDeviceActivityReportStubScaledToFit() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.scaledToFit(0)
    deviceActivityRequire(styled.context == report.context, "scaledToFit preserves context")
    deviceActivityRequire(styled.filter == report.filter, "scaledToFit preserves filter")
}

func testDeviceActivityReportStubSubmitLabel() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.submitLabel(0)
    deviceActivityRequire(styled.context == report.context, "submitLabel preserves context")
    deviceActivityRequire(styled.filter == report.filter, "submitLabel preserves filter")
}

func testDeviceActivityReportStubSubmitScope() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.submitScope(0)
    deviceActivityRequire(styled.context == report.context, "submitScope preserves context")
    deviceActivityRequire(styled.filter == report.filter, "submitScope preserves filter")
}

func testDeviceActivityReportStubToggleStyle() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.toggleStyle(0)
    deviceActivityRequire(styled.context == report.context, "toggleStyle preserves context")
    deviceActivityRequire(styled.filter == report.filter, "toggleStyle preserves filter")
}

func testDeviceActivityReportStubToolbarRole() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.toolbarRole(0)
    deviceActivityRequire(styled.context == report.context, "toolbarRole preserves context")
    deviceActivityRequire(styled.filter == report.filter, "toolbarRole preserves filter")
}

func testDeviceActivityReportStubTransaction() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.transaction(0)
    deviceActivityRequire(styled.context == report.context, "transaction preserves context")
    deviceActivityRequire(styled.filter == report.filter, "transaction preserves filter")
}

func testDeviceActivityReportStubButtonSizing() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.buttonSizing(0)
    deviceActivityRequire(styled.context == report.context, "buttonSizing preserves context")
    deviceActivityRequire(styled.filter == report.filter, "buttonSizing preserves filter")
}

func testDeviceActivityReportStubContentShape() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.contentShape(0)
    deviceActivityRequire(styled.context == report.context, "contentShape preserves context")
    deviceActivityRequire(styled.filter == report.filter, "contentShape preserves filter")
}

func testDeviceActivityReportStubCornerRadius() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.cornerRadius(0)
    deviceActivityRequire(styled.context == report.context, "cornerRadius preserves context")
    deviceActivityRequire(styled.filter == report.filter, "cornerRadius preserves filter")
}

func testDeviceActivityReportStubDefaultFocus() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.defaultFocus(0)
    deviceActivityRequire(styled.context == report.context, "defaultFocus preserves context")
    deviceActivityRequire(styled.filter == report.filter, "defaultFocus preserves filter")
}

func testDeviceActivityReportStubDrawingGroup() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.drawingGroup(0)
    deviceActivityRequire(styled.context == report.context, "drawingGroup preserves context")
    deviceActivityRequire(styled.filter == report.filter, "drawingGroup preserves filter")
}

func testDeviceActivityReportStubFileExporter() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.fileExporter(0)
    deviceActivityRequire(styled.context == report.context, "fileExporter preserves context")
    deviceActivityRequire(styled.filter == report.filter, "fileExporter preserves filter")
}

func testDeviceActivityReportStubFileImporter() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.fileImporter(0)
    deviceActivityRequire(styled.context == report.context, "fileImporter preserves context")
    deviceActivityRequire(styled.filter == report.filter, "fileImporter preserves filter")
}

func testDeviceActivityReportStubFindDisabled() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.findDisabled(0)
    deviceActivityRequire(styled.context == report.context, "findDisabled preserves context")
    deviceActivityRequire(styled.filter == report.filter, "findDisabled preserves filter")
}

func testDeviceActivityReportStubFocusedValue() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.focusedValue(0)
    deviceActivityRequire(styled.context == report.context, "focusedValue preserves context")
    deviceActivityRequire(styled.filter == report.filter, "focusedValue preserves filter")
}

func testDeviceActivityReportStubItemProvider() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.itemProvider(0)
    deviceActivityRequire(styled.context == report.context, "itemProvider preserves context")
    deviceActivityRequire(styled.filter == report.filter, "itemProvider preserves filter")
}

func testDeviceActivityReportStubKeyboardType() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.keyboardType(0)
    deviceActivityRequire(styled.context == report.context, "keyboardType preserves context")
    deviceActivityRequire(styled.filter == report.filter, "keyboardType preserves filter")
}

func testDeviceActivityReportStubLabelsHidden() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.labelsHidden(0)
    deviceActivityRequire(styled.context == report.context, "labelsHidden preserves context")
    deviceActivityRequire(styled.filter == report.filter, "labelsHidden preserves filter")
}

func testDeviceActivityReportStubListItemTint() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.listItemTint(0)
    deviceActivityRequire(styled.context == report.context, "listItemTint preserves context")
    deviceActivityRequire(styled.filter == report.filter, "listItemTint preserves filter")
}

func testDeviceActivityReportStubMoveDisabled() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.moveDisabled(0)
    deviceActivityRequire(styled.context == report.context, "moveDisabled preserves context")
    deviceActivityRequire(styled.filter == report.filter, "moveDisabled preserves filter")
}

func testDeviceActivityReportStubOnTapGesture() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.onTapGesture(0)
    deviceActivityRequire(styled.context == report.context, "onTapGesture preserves context")
    deviceActivityRequire(styled.filter == report.filter, "onTapGesture preserves filter")
}

func testDeviceActivityReportStubRenameAction() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.renameAction(0)
    deviceActivityRequire(styled.context == report.context, "renameAction preserves context")
    deviceActivityRequire(styled.filter == report.filter, "renameAction preserves filter")
}

func testDeviceActivityReportStubScaledToFill() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.scaledToFill(0)
    deviceActivityRequire(styled.context == report.context, "scaledToFill preserves context")
    deviceActivityRequire(styled.filter == report.filter, "scaledToFill preserves filter")
}

func testDeviceActivityReportStubScenePadding() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.scenePadding(0)
    deviceActivityRequire(styled.context == report.context, "scenePadding preserves context")
    deviceActivityRequire(styled.filter == report.filter, "scenePadding preserves filter")
}

func testDeviceActivityReportStubSearchScopes() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.searchScopes(0)
    deviceActivityRequire(styled.context == report.context, "searchScopes preserves context")
    deviceActivityRequire(styled.filter == report.filter, "searchScopes preserves filter")
}

func testDeviceActivityReportStubSwipeActions() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.swipeActions(0)
    deviceActivityRequire(styled.context == report.context, "swipeActions preserves context")
    deviceActivityRequire(styled.filter == report.filter, "swipeActions preserves filter")
}

func testDeviceActivityReportStubSymbolEffect() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.symbolEffect(0)
    deviceActivityRequire(styled.context == report.context, "symbolEffect preserves context")
    deviceActivityRequire(styled.filter == report.filter, "symbolEffect preserves filter")
}

func testDeviceActivityReportStubTextRenderer() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.textRenderer(0)
    deviceActivityRequire(styled.context == report.context, "textRenderer preserves context")
    deviceActivityRequire(styled.filter == report.filter, "textRenderer preserves filter")
}

func testDeviceActivityReportStubUserActivity() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.userActivity(0)
    deviceActivityRequire(styled.context == report.context, "userActivity preserves context")
    deviceActivityRequire(styled.filter == report.filter, "userActivity preserves filter")
}

func testDeviceActivityReportStubVisualEffect() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.visualEffect(0)
    deviceActivityRequire(styled.context == report.context, "visualEffect preserves context")
    deviceActivityRequire(styled.filter == report.filter, "visualEffect preserves filter")
}

func testDeviceActivityReportStubAccessibility() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.accessibility(0)
    deviceActivityRequire(styled.context == report.context, "accessibility preserves context")
    deviceActivityRequire(styled.filter == report.filter, "accessibility preserves filter")
}

func testDeviceActivityReportStubColorMultiply() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.colorMultiply(0)
    deviceActivityRequire(styled.context == report.context, "colorMultiply preserves context")
    deviceActivityRequire(styled.filter == report.filter, "colorMultiply preserves filter")
}

func testDeviceActivityReportStubFindNavigator() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.findNavigator(0)
    deviceActivityRequire(styled.context == report.context, "findNavigator preserves context")
    deviceActivityRequire(styled.filter == report.filter, "findNavigator preserves filter")
}

func testDeviceActivityReportStubFocusedObject() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.focusedObject(0)
    deviceActivityRequire(styled.context == report.context, "focusedObject preserves context")
    deviceActivityRequire(styled.filter == report.filter, "focusedObject preserves filter")
}

func testDeviceActivityReportStubGeometryGroup() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.geometryGroup(0)
    deviceActivityRequire(styled.context == report.context, "geometryGroup preserves context")
    deviceActivityRequire(styled.filter == report.filter, "geometryGroup preserves filter")
}

func testDeviceActivityReportStubGlassEffectID() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.glassEffectID(0)
    deviceActivityRequire(styled.context == report.context, "glassEffectID preserves context")
    deviceActivityRequire(styled.filter == report.filter, "glassEffectID preserves filter")
}

func testDeviceActivityReportStubGroupBoxStyle() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.groupBoxStyle(0)
    deviceActivityRequire(styled.context == report.context, "groupBoxStyle preserves context")
    deviceActivityRequire(styled.filter == report.filter, "groupBoxStyle preserves filter")
}

func testDeviceActivityReportStubListRowInsets() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.listRowInsets(0)
    deviceActivityRequire(styled.context == report.context, "listRowInsets preserves context")
    deviceActivityRequire(styled.filter == report.filter, "listRowInsets preserves filter")
}

func testDeviceActivityReportStubMenuIndicator() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.menuIndicator(0)
    deviceActivityRequire(styled.context == report.context, "menuIndicator preserves context")
    deviceActivityRequire(styled.filter == report.filter, "menuIndicator preserves filter")
}

func testDeviceActivityReportStubPhaseAnimator() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.phaseAnimator(0)
    deviceActivityRequire(styled.context == report.context, "phaseAnimator preserves context")
    deviceActivityRequire(styled.filter == report.filter, "phaseAnimator preserves filter")
}

func testDeviceActivityReportStubPreviewDevice() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.previewDevice(0)
    deviceActivityRequire(styled.context == report.context, "previewDevice preserves context")
    deviceActivityRequire(styled.filter == report.filter, "previewDevice preserves filter")
}

func testDeviceActivityReportStubPreviewLayout() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.previewLayout(0)
    deviceActivityRequire(styled.context == report.context, "previewLayout preserves context")
    deviceActivityRequire(styled.filter == report.filter, "previewLayout preserves filter")
}

func testDeviceActivityReportStubSafeAreaInset() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.safeAreaInset(0)
    deviceActivityRequire(styled.context == report.context, "safeAreaInset preserves context")
    deviceActivityRequire(styled.filter == report.filter, "safeAreaInset preserves filter")
}

func testDeviceActivityReportStubSearchFocused() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.searchFocused(0)
    deviceActivityRequire(styled.context == report.context, "searchFocused preserves context")
    deviceActivityRequire(styled.filter == report.filter, "searchFocused preserves filter")
}

func testDeviceActivityReportStubStrikethrough() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.strikethrough(0)
    deviceActivityRequire(styled.context == report.context, "strikethrough preserves context")
    deviceActivityRequire(styled.filter == report.filter, "strikethrough preserves filter")
}

func testDeviceActivityReportStubSymbolVariant() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.symbolVariant(0)
    deviceActivityRequire(styled.context == report.context, "symbolVariant preserves context")
    deviceActivityRequire(styled.filter == report.filter, "symbolVariant preserves filter")
}

func testDeviceActivityReportStubTextSelection() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.textSelection(0)
    deviceActivityRequire(styled.context == report.context, "textSelection preserves context")
    deviceActivityRequire(styled.filter == report.filter, "textSelection preserves filter")
}

func testDeviceActivityReportStubAlignmentGuide() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.alignmentGuide(0)
    deviceActivityRequire(styled.context == report.context, "alignmentGuide preserves context")
    deviceActivityRequire(styled.filter == report.filter, "alignmentGuide preserves filter")
}

func testDeviceActivityReportStubBaselineOffset() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.baselineOffset(0)
    deviceActivityRequire(styled.context == report.context, "baselineOffset preserves context")
    deviceActivityRequire(styled.filter == report.filter, "baselineOffset preserves filter")
}

func testDeviceActivityReportStubContainerShape() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.containerShape(0)
    deviceActivityRequire(styled.context == report.context, "containerShape preserves context")
    deviceActivityRequire(styled.filter == report.filter, "containerShape preserves filter")
}

func testDeviceActivityReportStubContainerValue() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.containerValue(0)
    deviceActivityRequire(styled.context == report.context, "containerValue preserves context")
    deviceActivityRequire(styled.filter == report.filter, "containerValue preserves filter")
}

func testDeviceActivityReportStubContentMargins() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.contentMargins(0)
    deviceActivityRequire(styled.context == report.context, "contentMargins preserves context")
    deviceActivityRequire(styled.filter == report.filter, "contentMargins preserves filter")
}

func testDeviceActivityReportStubContentToolbar() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.contentToolbar(0)
    deviceActivityRequire(styled.context == report.context, "contentToolbar preserves context")
    deviceActivityRequire(styled.filter == report.filter, "contentToolbar preserves filter")
}

func testDeviceActivityReportStubDeleteDisabled() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.deleteDisabled(0)
    deviceActivityRequire(styled.context == report.context, "deleteDisabled preserves context")
    deviceActivityRequire(styled.filter == report.filter, "deleteDisabled preserves filter")
}

func testDeviceActivityReportStubGridCellAnchor() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.gridCellAnchor(0)
    deviceActivityRequire(styled.context == report.context, "gridCellAnchor preserves context")
    deviceActivityRequire(styled.filter == report.filter, "gridCellAnchor preserves filter")
}

func testDeviceActivityReportStubLayoutPriority() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.layoutPriority(0)
    deviceActivityRequire(styled.context == report.context, "layoutPriority preserves context")
    deviceActivityRequire(styled.filter == report.filter, "layoutPriority preserves filter")
}

func testDeviceActivityReportStubListRowSpacing() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.listRowSpacing(0)
    deviceActivityRequire(styled.context == report.context, "listRowSpacing preserves context")
    deviceActivityRequire(styled.filter == report.filter, "listRowSpacing preserves filter")
}

func testDeviceActivityReportStubPreviewContext() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.previewContext(0)
    deviceActivityRequire(styled.context == report.context, "previewContext preserves context")
    deviceActivityRequire(styled.filter == report.filter, "previewContext preserves filter")
}

func testDeviceActivityReportStubRotationEffect() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.rotationEffect(0)
    deviceActivityRequire(styled.context == report.context, "rotationEffect preserves context")
    deviceActivityRequire(styled.filter == report.filter, "rotationEffect preserves filter")
}

func testDeviceActivityReportStubScrollDisabled() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.scrollDisabled(0)
    deviceActivityRequire(styled.context == report.context, "scrollDisabled preserves context")
    deviceActivityRequire(styled.filter == report.filter, "scrollDisabled preserves filter")
}

func testDeviceActivityReportStubScrollPosition() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.scrollPosition(0)
    deviceActivityRequire(styled.context == report.context, "scrollPosition preserves context")
    deviceActivityRequire(styled.filter == report.filter, "scrollPosition preserves filter")
}

func testDeviceActivityReportStubSectionActions() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.sectionActions(0)
    deviceActivityRequire(styled.context == report.context, "sectionActions preserves context")
    deviceActivityRequire(styled.filter == report.filter, "sectionActions preserves filter")
}

func testDeviceActivityReportStubTextFieldStyle() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.textFieldStyle(0)
    deviceActivityRequire(styled.context == report.context, "textFieldStyle preserves context")
    deviceActivityRequire(styled.filter == report.filter, "textFieldStyle preserves filter")
}

func testDeviceActivityReportStubTruncationMode() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.truncationMode(0)
    deviceActivityRequire(styled.context == report.context, "truncationMode preserves context")
    deviceActivityRequire(styled.filter == report.filter, "truncationMode preserves filter")
}

func testDeviceActivityReportStubBackgroundStyle() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.backgroundStyle(0)
    deviceActivityRequire(styled.context == report.context, "backgroundStyle preserves context")
    deviceActivityRequire(styled.filter == report.filter, "backgroundStyle preserves filter")
}

func testDeviceActivityReportStubBadgeProminence() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.badgeProminence(0)
    deviceActivityRequire(styled.context == report.context, "badgeProminence preserves context")
    deviceActivityRequire(styled.filter == report.filter, "badgeProminence preserves filter")
}

func testDeviceActivityReportStubCoordinateSpace() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.coordinateSpace(0)
    deviceActivityRequire(styled.context == report.context, "coordinateSpace preserves context")
    deviceActivityRequire(styled.filter == report.filter, "coordinateSpace preserves filter")
}

func testDeviceActivityReportStubDatePickerStyle() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.datePickerStyle(0)
    deviceActivityRequire(styled.context == report.context, "datePickerStyle preserves context")
    deviceActivityRequire(styled.filter == report.filter, "datePickerStyle preserves filter")
}

func testDeviceActivityReportStubDropDestination() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.dropDestination(0)
    deviceActivityRequire(styled.context == report.context, "dropDestination preserves context")
    deviceActivityRequire(styled.filter == report.filter, "dropDestination preserves filter")
}

func testDeviceActivityReportStubDynamicTypeSize() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.dynamicTypeSize(0)
    deviceActivityRequire(styled.context == report.context, "dynamicTypeSize preserves context")
    deviceActivityRequire(styled.filter == report.filter, "dynamicTypeSize preserves filter")
}

func testDeviceActivityReportStubForegroundColor() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.foregroundColor(0)
    deviceActivityRequire(styled.context == report.context, "foregroundColor preserves context")
    deviceActivityRequire(styled.filter == report.filter, "foregroundColor preserves filter")
}

func testDeviceActivityReportStubForegroundStyle() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.foregroundStyle(0)
    deviceActivityRequire(styled.context == report.context, "foregroundStyle preserves context")
    deviceActivityRequire(styled.filter == report.filter, "foregroundStyle preserves filter")
}

func testDeviceActivityReportStubFullScreenCover() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.fullScreenCover(0)
    deviceActivityRequire(styled.context == report.context, "fullScreenCover preserves context")
    deviceActivityRequire(styled.filter == report.filter, "fullScreenCover preserves filter")
}

func testDeviceActivityReportStubGridCellColumns() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.gridCellColumns(0)
    deviceActivityRequire(styled.context == report.context, "gridCellColumns preserves context")
    deviceActivityRequire(styled.filter == report.filter, "gridCellColumns preserves filter")
}

func testDeviceActivityReportStubIgnoresSafeArea() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.ignoresSafeArea(0)
    deviceActivityRequire(styled.context == report.context, "ignoresSafeArea preserves context")
    deviceActivityRequire(styled.filter == report.filter, "ignoresSafeArea preserves filter")
}

func testDeviceActivityReportStubMonospacedDigit() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.monospacedDigit(0)
    deviceActivityRequire(styled.context == report.context, "monospacedDigit preserves context")
    deviceActivityRequire(styled.filter == report.filter, "monospacedDigit preserves filter")
}

func testDeviceActivityReportStubNavigationTitle() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.navigationTitle(0)
    deviceActivityRequire(styled.context == report.context, "navigationTitle preserves context")
    deviceActivityRequire(styled.filter == report.filter, "navigationTitle preserves filter")
}

func testDeviceActivityReportStubOnPencilSqueeze() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.onPencilSqueeze(0)
    deviceActivityRequire(styled.context == report.context, "onPencilSqueeze preserves context")
    deviceActivityRequire(styled.filter == report.filter, "onPencilSqueeze preserves filter")
}

func testDeviceActivityReportStubReplaceDisabled() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.replaceDisabled(0)
    deviceActivityRequire(styled.context == report.context, "replaceDisabled preserves context")
    deviceActivityRequire(styled.filter == report.filter, "replaceDisabled preserves filter")
}

func testDeviceActivityReportStubSafeAreaPadding() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.safeAreaPadding(0)
    deviceActivityRequire(styled.context == report.context, "safeAreaPadding preserves context")
    deviceActivityRequire(styled.filter == report.filter, "safeAreaPadding preserves filter")
}

func testDeviceActivityReportStubSearchSelection() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.searchSelection(0)
    deviceActivityRequire(styled.context == report.context, "searchSelection preserves context")
    deviceActivityRequire(styled.filter == report.filter, "searchSelection preserves filter")
}

func testDeviceActivityReportStubSensoryFeedback() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.sensoryFeedback(0)
    deviceActivityRequire(styled.context == report.context, "sensoryFeedback preserves context")
    deviceActivityRequire(styled.filter == report.filter, "sensoryFeedback preserves filter")
}

func testDeviceActivityReportStubStatusBarHidden() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.statusBarHidden(0)
    deviceActivityRequire(styled.context == report.context, "statusBarHidden preserves context")
    deviceActivityRequire(styled.filter == report.filter, "statusBarHidden preserves filter")
}

func testDeviceActivityReportStubTextContentType() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.textContentType(0)
    deviceActivityRequire(styled.context == report.context, "textContentType preserves context")
    deviceActivityRequire(styled.filter == report.filter, "textContentType preserves filter")
}

func testDeviceActivityReportStubTextEditorStyle() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.textEditorStyle(0)
    deviceActivityRequire(styled.context == report.context, "textEditorStyle preserves context")
    deviceActivityRequire(styled.filter == report.filter, "textEditorStyle preserves filter")
}

func testDeviceActivityReportStubTransformEffect() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.transformEffect(0)
    deviceActivityRequire(styled.context == report.context, "transformEffect preserves context")
    deviceActivityRequire(styled.filter == report.filter, "transformEffect preserves filter")
}

func testDeviceActivityReportStubAllowsHitTesting() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.allowsHitTesting(0)
    deviceActivityRequire(styled.context == report.context, "allowsHitTesting preserves context")
    deviceActivityRequire(styled.filter == report.filter, "allowsHitTesting preserves filter")
}

func testDeviceActivityReportStubAllowsTightening() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.allowsTightening(0)
    deviceActivityRequire(styled.context == report.context, "allowsTightening preserves context")
    deviceActivityRequire(styled.filter == report.filter, "allowsTightening preserves filter")
}

func testDeviceActivityReportStubAnchorPreference() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.anchorPreference(0)
    deviceActivityRequire(styled.context == report.context, "anchorPreference preserves context")
    deviceActivityRequire(styled.filter == report.filter, "anchorPreference preserves filter")
}

func testDeviceActivityReportStubCompositingGroup() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.compositingGroup(0)
    deviceActivityRequire(styled.context == report.context, "compositingGroup preserves context")
    deviceActivityRequire(styled.filter == report.filter, "compositingGroup preserves filter")
}

func testDeviceActivityReportStubDistortionEffect() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.distortionEffect(0)
    deviceActivityRequire(styled.context == report.context, "distortionEffect preserves context")
    deviceActivityRequire(styled.filter == report.filter, "distortionEffect preserves filter")
}

func testDeviceActivityReportStubGlassEffectUnion() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.glassEffectUnion(0)
    deviceActivityRequire(styled.context == report.context, "glassEffectUnion preserves context")
    deviceActivityRequire(styled.filter == report.filter, "glassEffectUnion preserves filter")
}

func testDeviceActivityReportStubHeaderProminence() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.headerProminence(0)
    deviceActivityRequire(styled.context == report.context, "headerProminence preserves context")
    deviceActivityRequire(styled.filter == report.filter, "headerProminence preserves filter")
}

func testDeviceActivityReportStubKeyboardShortcut() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.keyboardShortcut(0)
    deviceActivityRequire(styled.context == report.context, "keyboardShortcut preserves context")
    deviceActivityRequire(styled.filter == report.filter, "keyboardShortcut preserves filter")
}

func testDeviceActivityReportStubKeyframeAnimator() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.keyframeAnimator(0)
    deviceActivityRequire(styled.context == report.context, "keyframeAnimator preserves context")
    deviceActivityRequire(styled.filter == report.filter, "keyframeAnimator preserves filter")
}

func testDeviceActivityReportStubLabelsVisibility() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.labelsVisibility(0)
    deviceActivityRequire(styled.context == report.context, "labelsVisibility preserves context")
    deviceActivityRequire(styled.filter == report.filter, "labelsVisibility preserves filter")
}

func testDeviceActivityReportStubListRowSeparator() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.listRowSeparator(0)
    deviceActivityRequire(styled.context == report.context, "listRowSeparator preserves context")
    deviceActivityRequire(styled.filter == report.filter, "listRowSeparator preserves filter")
}

func testDeviceActivityReportStubLuminanceToAlpha() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.luminanceToAlpha(0)
    deviceActivityRequire(styled.context == report.context, "luminanceToAlpha preserves context")
    deviceActivityRequire(styled.filter == report.filter, "luminanceToAlpha preserves filter")
}

func testDeviceActivityReportStubOnGeometryChange() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.onGeometryChange(0)
    deviceActivityRequire(styled.context == report.context, "onGeometryChange preserves context")
    deviceActivityRequire(styled.filter == report.filter, "onGeometryChange preserves filter")
}

func testDeviceActivityReportStubPrivacySensitive() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.privacySensitive(0)
    deviceActivityRequire(styled.context == report.context, "privacySensitive preserves context")
    deviceActivityRequire(styled.filter == report.filter, "privacySensitive preserves filter")
}

func testDeviceActivityReportStubProjectionEffect() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.projectionEffect(0)
    deviceActivityRequire(styled.context == report.context, "projectionEffect preserves context")
    deviceActivityRequire(styled.filter == report.filter, "projectionEffect preserves filter")
}

func testDeviceActivityReportStubRotation3DEffect() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.rotation3DEffect(0)
    deviceActivityRequire(styled.context == report.context, "rotation3DEffect preserves context")
    deviceActivityRequire(styled.filter == report.filter, "rotation3DEffect preserves filter")
}

func testDeviceActivityReportStubScrollIndicators() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.scrollIndicators(0)
    deviceActivityRequire(styled.context == report.context, "scrollIndicators preserves context")
    deviceActivityRequire(styled.filter == report.filter, "scrollIndicators preserves filter")
}

func testDeviceActivityReportStubScrollTransition() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.scrollTransition(0)
    deviceActivityRequire(styled.context == report.context, "scrollTransition preserves context")
    deviceActivityRequire(styled.filter == report.filter, "scrollTransition preserves filter")
}

func testDeviceActivityReportStubSearchCompletion() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.searchCompletion(0)
    deviceActivityRequire(styled.context == report.context, "searchCompletion preserves context")
    deviceActivityRequire(styled.filter == report.filter, "searchCompletion preserves filter")
}

func testDeviceActivityReportStubToolbarTitleMenu() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.toolbarTitleMenu(0)
    deviceActivityRequire(styled.context == report.context, "toolbarTitleMenu preserves context")
    deviceActivityRequire(styled.filter == report.filter, "toolbarTitleMenu preserves filter")
}

func testDeviceActivityReportStubWritingDirection() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.writingDirection(0)
    deviceActivityRequire(styled.context == report.context, "writingDirection preserves context")
    deviceActivityRequire(styled.filter == report.filter, "writingDirection preserves filter")
}

func testDeviceActivityReportStubAccessibilityHint() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.accessibilityHint(0)
    deviceActivityRequire(styled.context == report.context, "accessibilityHint preserves context")
    deviceActivityRequire(styled.filter == report.filter, "accessibilityHint preserves filter")
}

func testDeviceActivityReportStubButtonBorderShape() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.buttonBorderShape(0)
    deviceActivityRequire(styled.context == report.context, "buttonBorderShape preserves context")
    deviceActivityRequire(styled.filter == report.filter, "buttonBorderShape preserves filter")
}

func testDeviceActivityReportStubContentTransition() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.contentTransition(0)
    deviceActivityRequire(styled.context == report.context, "contentTransition preserves context")
    deviceActivityRequire(styled.filter == report.filter, "contentTransition preserves filter")
}

func testDeviceActivityReportStubControlGroupStyle() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.controlGroupStyle(0)
    deviceActivityRequire(styled.context == report.context, "controlGroupStyle preserves context")
    deviceActivityRequire(styled.filter == report.filter, "controlGroupStyle preserves filter")
}

func testDeviceActivityReportStubDefaultAppStorage() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.defaultAppStorage(0)
    deviceActivityRequire(styled.context == report.context, "defaultAppStorage preserves context")
    deviceActivityRequire(styled.filter == report.filter, "defaultAppStorage preserves filter")
}

func testDeviceActivityReportStubEnvironmentObject() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.environmentObject(0)
    deviceActivityRequire(styled.context == report.context, "environmentObject preserves context")
    deviceActivityRequire(styled.filter == report.filter, "environmentObject preserves filter")
}

func testDeviceActivityReportStubFileDialogMessage() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.fileDialogMessage(0)
    deviceActivityRequire(styled.context == report.context, "fileDialogMessage preserves context")
    deviceActivityRequire(styled.filter == report.filter, "fileDialogMessage preserves filter")
}

func testDeviceActivityReportStubFocusedSceneValue() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.focusedSceneValue(0)
    deviceActivityRequire(styled.context == report.context, "focusedSceneValue preserves context")
    deviceActivityRequire(styled.filter == report.filter, "focusedSceneValue preserves filter")
}

func testDeviceActivityReportStubListRowBackground() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.listRowBackground(0)
    deviceActivityRequire(styled.context == report.context, "listRowBackground preserves context")
    deviceActivityRequire(styled.filter == report.filter, "listRowBackground preserves filter")
}

func testDeviceActivityReportStubOnContinuousHover() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.onContinuousHover(0)
    deviceActivityRequire(styled.context == report.context, "onContinuousHover preserves context")
    deviceActivityRequire(styled.filter == report.filter, "onContinuousHover preserves filter")
}

func testDeviceActivityReportStubOnPencilDoubleTap() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.onPencilDoubleTap(0)
    deviceActivityRequire(styled.context == report.context, "onPencilDoubleTap preserves context")
    deviceActivityRequire(styled.filter == report.filter, "onPencilDoubleTap preserves filter")
}

func testDeviceActivityReportStubSearchSuggestions() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.searchSuggestions(0)
    deviceActivityRequire(styled.context == report.context, "searchSuggestions preserves context")
    deviceActivityRequire(styled.filter == report.filter, "searchSuggestions preserves filter")
}

func testDeviceActivityReportStubSectionIndexLabel() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.sectionIndexLabel(0)
    deviceActivityRequire(styled.context == report.context, "sectionIndexLabel preserves context")
    deviceActivityRequire(styled.filter == report.filter, "sectionIndexLabel preserves filter")
}

func testDeviceActivityReportStubSelectionDisabled() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.selectionDisabled(0)
    deviceActivityRequire(styled.context == report.context, "selectionDisabled preserves context")
    deviceActivityRequire(styled.filter == report.filter, "selectionDisabled preserves filter")
}

func testDeviceActivityReportStubToolbarBackground() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.toolbarBackground(0)
    deviceActivityRequire(styled.context == report.context, "toolbarBackground preserves context")
    deviceActivityRequire(styled.filter == report.filter, "toolbarBackground preserves filter")
}

func testDeviceActivityReportStubToolbarVisibility() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.toolbarVisibility(0)
    deviceActivityRequire(styled.context == report.context, "toolbarVisibility preserves context")
    deviceActivityRequire(styled.filter == report.filter, "toolbarVisibility preserves filter")
}

func testDeviceActivityReportStubAccessibilityLabel() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.accessibilityLabel(0)
    deviceActivityRequire(styled.context == report.context, "accessibilityLabel preserves context")
    deviceActivityRequire(styled.filter == report.filter, "accessibilityLabel preserves filter")
}

func testDeviceActivityReportStubAccessibilityRotor() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.accessibilityRotor(0)
    deviceActivityRequire(styled.context == report.context, "accessibilityRotor preserves context")
    deviceActivityRequire(styled.filter == report.filter, "accessibilityRotor preserves filter")
}

func testDeviceActivityReportStubAccessibilityValue() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.accessibilityValue(0)
    deviceActivityRequire(styled.context == report.context, "accessibilityValue preserves context")
    deviceActivityRequire(styled.filter == report.filter, "accessibilityValue preserves filter")
}

func testDeviceActivityReportStubAutocapitalization() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.autocapitalization(0)
    deviceActivityRequire(styled.context == report.context, "autocapitalization preserves context")
    deviceActivityRequire(styled.filter == report.filter, "autocapitalization preserves filter")
}

func testDeviceActivityReportStubConfirmationDialog() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.confirmationDialog(0)
    deviceActivityRequire(styled.context == report.context, "confirmationDialog preserves context")
    deviceActivityRequire(styled.filter == report.filter, "confirmationDialog preserves filter")
}

func testDeviceActivityReportStubDefaultHoverEffect() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.defaultHoverEffect(0)
    deviceActivityRequire(styled.context == report.context, "defaultHoverEffect preserves context")
    deviceActivityRequire(styled.filter == report.filter, "defaultHoverEffect preserves filter")
}

func testDeviceActivityReportStubFocusedSceneObject() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.focusedSceneObject(0)
    deviceActivityRequire(styled.context == report.context, "focusedSceneObject preserves context")
    deviceActivityRequire(styled.filter == report.filter, "focusedSceneObject preserves filter")
}

func testDeviceActivityReportStubListSectionMargins() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.listSectionMargins(0)
    deviceActivityRequire(styled.context == report.context, "listSectionMargins preserves context")
    deviceActivityRequire(styled.filter == report.filter, "listSectionMargins preserves filter")
}

func testDeviceActivityReportStubListSectionSpacing() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.listSectionSpacing(0)
    deviceActivityRequire(styled.context == report.context, "listSectionSpacing preserves context")
    deviceActivityRequire(styled.filter == report.filter, "listSectionSpacing preserves filter")
}

func testDeviceActivityReportStubMinimumScaleFactor() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.minimumScaleFactor(0)
    deviceActivityRequire(styled.context == report.context, "minimumScaleFactor preserves context")
    deviceActivityRequire(styled.filter == report.filter, "minimumScaleFactor preserves filter")
}

func testDeviceActivityReportStubNavigationBarItems() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.navigationBarItems(0)
    deviceActivityRequire(styled.context == report.context, "navigationBarItems preserves context")
    deviceActivityRequire(styled.filter == report.filter, "navigationBarItems preserves filter")
}

func testDeviceActivityReportStubNavigationBarTitle() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.navigationBarTitle(0)
    deviceActivityRequire(styled.context == report.context, "navigationBarTitle preserves context")
    deviceActivityRequire(styled.filter == report.filter, "navigationBarTitle preserves filter")
}

func testDeviceActivityReportStubNavigationDocument() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.navigationDocument(0)
    deviceActivityRequire(styled.context == report.context, "navigationDocument preserves context")
    deviceActivityRequire(styled.filter == report.filter, "navigationDocument preserves filter")
}

func testDeviceActivityReportStubNavigationSubtitle() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.navigationSubtitle(0)
    deviceActivityRequire(styled.context == report.context, "navigationSubtitle preserves context")
    deviceActivityRequire(styled.filter == report.filter, "navigationSubtitle preserves filter")
}

func testDeviceActivityReportStubOnLongPressGesture() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.onLongPressGesture(0)
    deviceActivityRequire(styled.context == report.context, "onLongPressGesture preserves context")
    deviceActivityRequire(styled.filter == report.filter, "onLongPressGesture preserves filter")
}

func testDeviceActivityReportStubOnPreferenceChange() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.onPreferenceChange(0)
    deviceActivityRequire(styled.context == report.context, "onPreferenceChange preserves context")
    deviceActivityRequire(styled.filter == report.filter, "onPreferenceChange preserves filter")
}

func testDeviceActivityReportStubPresentationSizing() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.presentationSizing(0)
    deviceActivityRequire(styled.context == report.context, "presentationSizing preserves context")
    deviceActivityRequire(styled.filter == report.filter, "presentationSizing preserves filter")
}

func testDeviceActivityReportStubPreviewDisplayName() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.previewDisplayName(0)
    deviceActivityRequire(styled.context == report.context, "previewDisplayName preserves context")
    deviceActivityRequire(styled.filter == report.filter, "previewDisplayName preserves filter")
}

func testDeviceActivityReportStubScrollClipDisabled() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.scrollClipDisabled(0)
    deviceActivityRequire(styled.context == report.context, "scrollClipDisabled preserves context")
    deviceActivityRequire(styled.filter == report.filter, "scrollClipDisabled preserves filter")
}

func testDeviceActivityReportStubScrollTargetLayout() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.scrollTargetLayout(0)
    deviceActivityRequire(styled.context == report.context, "scrollTargetLayout preserves context")
    deviceActivityRequire(styled.filter == report.filter, "scrollTargetLayout preserves filter")
}

func testDeviceActivityReportStubTableColumnHeaders() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.tableColumnHeaders(0)
    deviceActivityRequire(styled.context == report.context, "tableColumnHeaders preserves context")
    deviceActivityRequire(styled.filter == report.filter, "tableColumnHeaders preserves filter")
}

func testDeviceActivityReportStubToolbarColorScheme() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.toolbarColorScheme(0)
    deviceActivityRequire(styled.context == report.context, "toolbarColorScheme preserves context")
    deviceActivityRequire(styled.filter == report.filter, "toolbarColorScheme preserves filter")
}

func testDeviceActivityReportStubAccessibilityAction() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.accessibilityAction(0)
    deviceActivityRequire(styled.context == report.context, "accessibilityAction preserves context")
    deviceActivityRequire(styled.filter == report.filter, "accessibilityAction preserves filter")
}

func testDeviceActivityReportStubAccessibilityHidden() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.accessibilityHidden(0)
    deviceActivityRequire(styled.context == report.context, "accessibilityHidden preserves context")
    deviceActivityRequire(styled.filter == report.filter, "accessibilityHidden preserves filter")
}

func testDeviceActivityReportStubAllowedDynamicRange() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.allowedDynamicRange(0)
    deviceActivityRequire(styled.context == report.context, "allowedDynamicRange preserves context")
    deviceActivityRequire(styled.filter == report.filter, "allowedDynamicRange preserves filter")
}

func testDeviceActivityReportStubContainerBackground() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.containerBackground(0)
    deviceActivityRequire(styled.context == report.context, "containerBackground preserves context")
    deviceActivityRequire(styled.filter == report.filter, "containerBackground preserves filter")
}

func testDeviceActivityReportStubDefaultScrollAnchor() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.defaultScrollAnchor(0)
    deviceActivityRequire(styled.context == report.context, "defaultScrollAnchor preserves context")
    deviceActivityRequire(styled.filter == report.filter, "defaultScrollAnchor preserves filter")
}

func testDeviceActivityReportStubFocusEffectDisabled() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.focusEffectDisabled(0)
    deviceActivityRequire(styled.context == report.context, "focusEffectDisabled preserves context")
    deviceActivityRequire(styled.filter == report.filter, "focusEffectDisabled preserves filter")
}

func testDeviceActivityReportStubGridCellUnsizedAxes() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.gridCellUnsizedAxes(0)
    deviceActivityRequire(styled.context == report.context, "gridCellUnsizedAxes preserves context")
    deviceActivityRequire(styled.filter == report.filter, "gridCellUnsizedAxes preserves filter")
}

func testDeviceActivityReportStubGridColumnAlignment() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.gridColumnAlignment(0)
    deviceActivityRequire(styled.context == report.context, "gridColumnAlignment preserves context")
    deviceActivityRequire(styled.filter == report.filter, "gridColumnAlignment preserves filter")
}

func testDeviceActivityReportStubHandGestureShortcut() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.handGestureShortcut(0)
    deviceActivityRequire(styled.context == report.context, "handGestureShortcut preserves context")
    deviceActivityRequire(styled.filter == report.filter, "handGestureShortcut preserves filter")
}

func testDeviceActivityReportStubHighPriorityGesture() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.highPriorityGesture(0)
    deviceActivityRequire(styled.context == report.context, "highPriorityGesture preserves context")
    deviceActivityRequire(styled.filter == report.filter, "highPriorityGesture preserves filter")
}

func testDeviceActivityReportStubHoverEffectDisabled() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.hoverEffectDisabled(0)
    deviceActivityRequire(styled.context == report.context, "hoverEffectDisabled preserves context")
    deviceActivityRequire(styled.filter == report.filter, "hoverEffectDisabled preserves filter")
}

func testDeviceActivityReportStubLabeledContentStyle() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.labeledContentStyle(0)
    deviceActivityRequire(styled.context == report.context, "labeledContentStyle preserves context")
    deviceActivityRequire(styled.filter == report.filter, "labeledContentStyle preserves filter")
}

func testDeviceActivityReportStubNavigationBarHidden() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.navigationBarHidden(0)
    deviceActivityRequire(styled.context == report.context, "navigationBarHidden preserves context")
    deviceActivityRequire(styled.filter == report.filter, "navigationBarHidden preserves filter")
}

func testDeviceActivityReportStubOnScrollPhaseChange() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.onScrollPhaseChange(0)
    deviceActivityRequire(styled.context == report.context, "onScrollPhaseChange preserves context")
    deviceActivityRequire(styled.filter == report.filter, "onScrollPhaseChange preserves filter")
}

func testDeviceActivityReportStubPresentationDetents() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.presentationDetents(0)
    deviceActivityRequire(styled.context == report.context, "presentationDetents preserves context")
    deviceActivityRequire(styled.filter == report.filter, "presentationDetents preserves filter")
}

func testDeviceActivityReportStubScrollInputBehavior() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.scrollInputBehavior(0)
    deviceActivityRequire(styled.context == report.context, "scrollInputBehavior preserves context")
    deviceActivityRequire(styled.filter == report.filter, "scrollInputBehavior preserves filter")
}

func testDeviceActivityReportStubSimultaneousGesture() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.simultaneousGesture(0)
    deviceActivityRequire(styled.context == report.context, "simultaneousGesture preserves context")
    deviceActivityRequire(styled.filter == report.filter, "simultaneousGesture preserves filter")
}

func testDeviceActivityReportStubSpeechAdjustedPitch() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.speechAdjustedPitch(0)
    deviceActivityRequire(styled.context == report.context, "speechAdjustedPitch preserves context")
    deviceActivityRequire(styled.filter == report.filter, "speechAdjustedPitch preserves filter")
}

func testDeviceActivityReportStubSymbolRenderingMode() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.symbolRenderingMode(0)
    deviceActivityRequire(styled.context == report.context, "symbolRenderingMode preserves context")
    deviceActivityRequire(styled.filter == report.filter, "symbolRenderingMode preserves filter")
}

func testDeviceActivityReportStubTransformPreference() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.transformPreference(0)
    deviceActivityRequire(styled.context == report.context, "transformPreference preserves context")
    deviceActivityRequire(styled.filter == report.filter, "transformPreference preserves filter")
}

func testDeviceActivityReportStubTypesettingLanguage() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.typesettingLanguage(0)
    deviceActivityRequire(styled.context == report.context, "typesettingLanguage preserves context")
    deviceActivityRequire(styled.filter == report.filter, "typesettingLanguage preserves filter")
}

func testDeviceActivityReportStubAccessibilityActions() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.accessibilityActions(0)
    deviceActivityRequire(styled.context == report.context, "accessibilityActions preserves context")
    deviceActivityRequire(styled.filter == report.filter, "accessibilityActions preserves filter")
}

func testDeviceActivityReportStubAccessibilityElement() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.accessibilityElement(0)
    deviceActivityRequire(styled.context == report.context, "accessibilityElement preserves context")
    deviceActivityRequire(styled.filter == report.filter, "accessibilityElement preserves filter")
}

func testDeviceActivityReportStubAccessibilityFocused() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.accessibilityFocused(0)
    deviceActivityRequire(styled.context == report.context, "accessibilityFocused preserves context")
    deviceActivityRequire(styled.filter == report.filter, "accessibilityFocused preserves filter")
}

func testDeviceActivityReportStubAccessibilityHeading() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.accessibilityHeading(0)
    deviceActivityRequire(styled.context == report.context, "accessibilityHeading preserves context")
    deviceActivityRequire(styled.filter == report.filter, "accessibilityHeading preserves filter")
}

func testDeviceActivityReportStubButtonRepeatBehavior() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.buttonRepeatBehavior(0)
    deviceActivityRequire(styled.context == report.context, "buttonRepeatBehavior preserves context")
    deviceActivityRequire(styled.filter == report.filter, "buttonRepeatBehavior preserves filter")
}

func testDeviceActivityReportStubDefersSystemGestures() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.defersSystemGestures(0)
    deviceActivityRequire(styled.context == report.context, "defersSystemGestures preserves context")
    deviceActivityRequire(styled.filter == report.filter, "defersSystemGestures preserves filter")
}

func testDeviceActivityReportStubDisclosureGroupStyle() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.disclosureGroupStyle(0)
    deviceActivityRequire(styled.context == report.context, "disclosureGroupStyle preserves context")
    deviceActivityRequire(styled.filter == report.filter, "disclosureGroupStyle preserves filter")
}

func testDeviceActivityReportStubFileDialogURLEnabled() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.fileDialogURLEnabled(0)
    deviceActivityRequire(styled.context == report.context, "fileDialogURLEnabled preserves context")
    deviceActivityRequire(styled.filter == report.filter, "fileDialogURLEnabled preserves filter")
}

func testDeviceActivityReportStubInspectorColumnWidth() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.inspectorColumnWidth(0)
    deviceActivityRequire(styled.context == report.context, "inspectorColumnWidth preserves context")
    deviceActivityRequire(styled.filter == report.filter, "inspectorColumnWidth preserves filter")
}

func testDeviceActivityReportStubInvalidatableContent() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.invalidatableContent(0)
    deviceActivityRequire(styled.context == report.context, "invalidatableContent preserves context")
    deviceActivityRequire(styled.filter == report.filter, "invalidatableContent preserves filter")
}

func testDeviceActivityReportStubListRowSeparatorTint() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.listRowSeparatorTint(0)
    deviceActivityRequire(styled.context == report.context, "listRowSeparatorTint preserves context")
    deviceActivityRequire(styled.filter == report.filter, "listRowSeparatorTint preserves filter")
}

func testDeviceActivityReportStubListSectionSeparator() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.listSectionSeparator(0)
    deviceActivityRequire(styled.context == report.context, "listSectionSeparator preserves context")
    deviceActivityRequire(styled.filter == report.filter, "listSectionSeparator preserves filter")
}

func testDeviceActivityReportStubNavigationTransition() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.navigationTransition(0)
    deviceActivityRequire(styled.context == report.context, "navigationTransition preserves context")
    deviceActivityRequire(styled.filter == report.filter, "navigationTransition preserves filter")
}

func testDeviceActivityReportStubPreferredColorScheme() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.preferredColorScheme(0)
    deviceActivityRequire(styled.context == report.context, "preferredColorScheme preserves context")
    deviceActivityRequire(styled.filter == report.filter, "preferredColorScheme preserves filter")
}

func testDeviceActivityReportStubScrollBounceBehavior() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.scrollBounceBehavior(0)
    deviceActivityRequire(styled.context == report.context, "scrollBounceBehavior preserves context")
    deviceActivityRequire(styled.filter == report.filter, "scrollBounceBehavior preserves filter")
}

func testDeviceActivityReportStubScrollTargetBehavior() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.scrollTargetBehavior(0)
    deviceActivityRequire(styled.context == report.context, "scrollTargetBehavior preserves context")
    deviceActivityRequire(styled.filter == report.filter, "scrollTargetBehavior preserves filter")
}

func testDeviceActivityReportStubSymbolEffectsRemoved() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.symbolEffectsRemoved(0)
    deviceActivityRequire(styled.context == report.context, "symbolEffectsRemoved preserves context")
    deviceActivityRequire(styled.filter == report.filter, "symbolEffectsRemoved preserves filter")
}

func testDeviceActivityReportStubTransformEnvironment() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.transformEnvironment(0)
    deviceActivityRequire(styled.context == report.context, "transformEnvironment preserves context")
    deviceActivityRequire(styled.filter == report.filter, "transformEnvironment preserves filter")
}

func testDeviceActivityReportStubTypeSelectEquivalent() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.typeSelectEquivalent(0)
    deviceActivityRequire(styled.context == report.context, "typeSelectEquivalent preserves context")
    deviceActivityRequire(styled.filter == report.filter, "typeSelectEquivalent preserves filter")
}

func testDeviceActivityReportStubWritingToolsBehavior() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.writingToolsBehavior(0)
    deviceActivityRequire(styled.context == report.context, "writingToolsBehavior preserves context")
    deviceActivityRequire(styled.filter == report.filter, "writingToolsBehavior preserves filter")
}

func testDeviceActivityReportStubAccessibilityChildren() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.accessibilityChildren(0)
    deviceActivityRequire(styled.context == report.context, "accessibilityChildren preserves context")
    deviceActivityRequire(styled.filter == report.filter, "accessibilityChildren preserves filter")
}

func testDeviceActivityReportStubContainerCornerOffset() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.containerCornerOffset(0)
    deviceActivityRequire(styled.context == report.context, "containerCornerOffset preserves context")
    deviceActivityRequire(styled.filter == report.filter, "containerCornerOffset preserves filter")
}

func testDeviceActivityReportStubDisableAutocorrection() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.disableAutocorrection(0)
    deviceActivityRequire(styled.context == report.context, "disableAutocorrection preserves context")
    deviceActivityRequire(styled.filter == report.filter, "disableAutocorrection preserves filter")
}

func testDeviceActivityReportStubEdgesIgnoringSafeArea() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.edgesIgnoringSafeArea(0)
    deviceActivityRequire(styled.context == report.context, "edgesIgnoringSafeArea preserves context")
    deviceActivityRequire(styled.filter == report.filter, "edgesIgnoringSafeArea preserves filter")
}

func testDeviceActivityReportStubGlassEffectTransition() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.glassEffectTransition(0)
    deviceActivityRequire(styled.context == report.context, "glassEffectTransition preserves context")
    deviceActivityRequire(styled.filter == report.filter, "glassEffectTransition preserves filter")
}

func testDeviceActivityReportStubHandlesExternalEvents() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.handlesExternalEvents(0)
    deviceActivityRequire(styled.context == report.context, "handlesExternalEvents preserves context")
    deviceActivityRequire(styled.filter == report.filter, "handlesExternalEvents preserves filter")
}

func testDeviceActivityReportStubMatchedGeometryEffect() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.matchedGeometryEffect(0)
    deviceActivityRequire(styled.context == report.context, "matchedGeometryEffect preserves context")
    deviceActivityRequire(styled.filter == report.filter, "matchedGeometryEffect preserves filter")
}

func testDeviceActivityReportStubNavigationDestination() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.navigationDestination(0)
    deviceActivityRequire(styled.context == report.context, "navigationDestination preserves context")
    deviceActivityRequire(styled.filter == report.filter, "navigationDestination preserves filter")
}

func testDeviceActivityReportStubScrollEdgeEffectStyle() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.scrollEdgeEffectStyle(0)
    deviceActivityRequire(styled.context == report.context, "scrollEdgeEffectStyle preserves context")
    deviceActivityRequire(styled.filter == report.filter, "scrollEdgeEffectStyle preserves filter")
}

func testDeviceActivityReportStubScrollIndicatorsFlash() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.scrollIndicatorsFlash(0)
    deviceActivityRequire(styled.context == report.context, "scrollIndicatorsFlash preserves context")
    deviceActivityRequire(styled.filter == report.filter, "scrollIndicatorsFlash preserves filter")
}

func testDeviceActivityReportStubSearchToolbarBehavior() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.searchToolbarBehavior(0)
    deviceActivityRequire(styled.context == report.context, "searchToolbarBehavior preserves context")
    deviceActivityRequire(styled.filter == report.filter, "searchToolbarBehavior preserves filter")
}

func testDeviceActivityReportStubSliderThumbVisibility() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.sliderThumbVisibility(0)
    deviceActivityRequire(styled.context == report.context, "sliderThumbVisibility preserves context")
    deviceActivityRequire(styled.filter == report.filter, "sliderThumbVisibility preserves filter")
}

func testDeviceActivityReportStubSpringLoadingBehavior() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.springLoadingBehavior(0)
    deviceActivityRequire(styled.context == report.context, "springLoadingBehavior preserves context")
    deviceActivityRequire(styled.filter == report.filter, "springLoadingBehavior preserves filter")
}

func testDeviceActivityReportStubTextSelectionAffinity() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.textSelectionAffinity(0)
    deviceActivityRequire(styled.context == report.context, "textSelectionAffinity preserves context")
    deviceActivityRequire(styled.filter == report.filter, "textSelectionAffinity preserves filter")
}

func testDeviceActivityReportStubAccessibilityAddTraits() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.accessibilityAddTraits(0)
    deviceActivityRequire(styled.context == report.context, "accessibilityAddTraits preserves context")
    deviceActivityRequire(styled.filter == report.filter, "accessibilityAddTraits preserves filter")
}

func testDeviceActivityReportStubAccessibilityDragPoint() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.accessibilityDragPoint(0)
    deviceActivityRequire(styled.context == report.context, "accessibilityDragPoint preserves context")
    deviceActivityRequire(styled.filter == report.filter, "accessibilityDragPoint preserves filter")
}

func testDeviceActivityReportStubAccessibilityDropPoint() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.accessibilityDropPoint(0)
    deviceActivityRequire(styled.context == report.context, "accessibilityDropPoint preserves context")
    deviceActivityRequire(styled.filter == report.filter, "accessibilityDropPoint preserves filter")
}

func testDeviceActivityReportStubAutocorrectionDisabled() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.autocorrectionDisabled(0)
    deviceActivityRequire(styled.context == report.context, "autocorrectionDisabled preserves context")
    deviceActivityRequire(styled.filter == report.filter, "autocorrectionDisabled preserves filter")
}

func testDeviceActivityReportStubContainerRelativeFrame() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.containerRelativeFrame(0)
    deviceActivityRequire(styled.context == report.context, "containerRelativeFrame preserves context")
    deviceActivityRequire(styled.filter == report.filter, "containerRelativeFrame preserves filter")
}

func testDeviceActivityReportStubLabelReservedIconWidth() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.labelReservedIconWidth(0)
    deviceActivityRequire(styled.context == report.context, "labelReservedIconWidth preserves context")
    deviceActivityRequire(styled.filter == report.filter, "labelReservedIconWidth preserves filter")
}

func testDeviceActivityReportStubMultilineTextAlignment() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.multilineTextAlignment(0)
    deviceActivityRequire(styled.context == report.context, "multilineTextAlignment preserves context")
    deviceActivityRequire(styled.filter == report.filter, "multilineTextAlignment preserves filter")
}

func testDeviceActivityReportStubOnContinueUserActivity() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.onContinueUserActivity(0)
    deviceActivityRequire(styled.context == report.context, "onContinueUserActivity preserves context")
    deviceActivityRequire(styled.filter == report.filter, "onContinueUserActivity preserves filter")
}

func testDeviceActivityReportStubOnScrollGeometryChange() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.onScrollGeometryChange(0)
    deviceActivityRequire(styled.context == report.context, "onScrollGeometryChange preserves context")
    deviceActivityRequire(styled.filter == report.filter, "onScrollGeometryChange preserves filter")
}

func testDeviceActivityReportStubOverlayPreferenceValue() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.overlayPreferenceValue(0)
    deviceActivityRequire(styled.context == report.context, "overlayPreferenceValue preserves context")
    deviceActivityRequire(styled.filter == report.filter, "overlayPreferenceValue preserves filter")
}

func testDeviceActivityReportStubPaletteSelectionEffect() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.paletteSelectionEffect(0)
    deviceActivityRequire(styled.context == report.context, "paletteSelectionEffect preserves context")
    deviceActivityRequire(styled.filter == report.filter, "paletteSelectionEffect preserves filter")
}

func testDeviceActivityReportStubPresentationBackground() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.presentationBackground(0)
    deviceActivityRequire(styled.context == report.context, "presentationBackground preserves context")
    deviceActivityRequire(styled.filter == report.filter, "presentationBackground preserves filter")
}

func testDeviceActivityReportStubScrollEdgeEffectHidden() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.scrollEdgeEffectHidden(0)
    deviceActivityRequire(styled.context == report.context, "scrollEdgeEffectHidden preserves context")
    deviceActivityRequire(styled.filter == report.filter, "scrollEdgeEffectHidden preserves filter")
}

func testDeviceActivityReportStubTabBarMinimizeBehavior() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.tabBarMinimizeBehavior(0)
    deviceActivityRequire(styled.context == report.context, "tabBarMinimizeBehavior preserves context")
    deviceActivityRequire(styled.filter == report.filter, "tabBarMinimizeBehavior preserves filter")
}

func testDeviceActivityReportStubToolbarForegroundStyle() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.toolbarForegroundStyle(0)
    deviceActivityRequire(styled.context == report.context, "toolbarForegroundStyle preserves context")
    deviceActivityRequire(styled.filter == report.filter, "toolbarForegroundStyle preserves filter")
}

func testDeviceActivityReportStubAccessibilityIdentifier() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.accessibilityIdentifier(0)
    deviceActivityRequire(styled.context == report.context, "accessibilityIdentifier preserves context")
    deviceActivityRequire(styled.filter == report.filter, "accessibilityIdentifier preserves filter")
}

func testDeviceActivityReportStubAccessibilityRotorEntry() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.accessibilityRotorEntry(0)
    deviceActivityRequire(styled.context == report.context, "accessibilityRotorEntry preserves context")
    deviceActivityRequire(styled.filter == report.filter, "accessibilityRotorEntry preserves filter")
}

func testDeviceActivityReportStubAccessibilityZoomAction() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.accessibilityZoomAction(0)
    deviceActivityRequire(styled.context == report.context, "accessibilityZoomAction preserves context")
    deviceActivityRequire(styled.filter == report.filter, "accessibilityZoomAction preserves filter")
}

func testDeviceActivityReportStubDialogSuppressionToggle() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.dialogSuppressionToggle(0)
    deviceActivityRequire(styled.context == report.context, "dialogSuppressionToggle preserves context")
    deviceActivityRequire(styled.filter == report.filter, "dialogSuppressionToggle preserves filter")
}

func testDeviceActivityReportStubLabelIconToTitleSpacing() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.labelIconToTitleSpacing(0)
    deviceActivityRequire(styled.context == report.context, "labelIconToTitleSpacing preserves context")
    deviceActivityRequire(styled.filter == report.filter, "labelIconToTitleSpacing preserves filter")
}

func testDeviceActivityReportStubLayoutDirectionBehavior() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.layoutDirectionBehavior(0)
    deviceActivityRequire(styled.context == report.context, "layoutDirectionBehavior preserves context")
    deviceActivityRequire(styled.filter == report.filter, "layoutDirectionBehavior preserves filter")
}

func testDeviceActivityReportStubMatchedTransitionSource() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.matchedTransitionSource(0)
    deviceActivityRequire(styled.context == report.context, "matchedTransitionSource preserves context")
    deviceActivityRequire(styled.filter == report.filter, "matchedTransitionSource preserves filter")
}

func testDeviceActivityReportStubScrollContentBackground() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.scrollContentBackground(0)
    deviceActivityRequire(styled.context == report.context, "scrollContentBackground preserves context")
    deviceActivityRequire(styled.filter == report.filter, "scrollContentBackground preserves filter")
}

func testDeviceActivityReportStubScrollDismissesKeyboard() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.scrollDismissesKeyboard(0)
    deviceActivityRequire(styled.context == report.context, "scrollDismissesKeyboard preserves context")
    deviceActivityRequire(styled.filter == report.filter, "scrollDismissesKeyboard preserves filter")
}

func testDeviceActivityReportStubSearchDictationBehavior() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.searchDictationBehavior(0)
    deviceActivityRequire(styled.context == report.context, "searchDictationBehavior preserves context")
    deviceActivityRequire(styled.filter == report.filter, "searchDictationBehavior preserves filter")
}

func testDeviceActivityReportStubSymbolVariableValueMode() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.symbolVariableValueMode(0)
    deviceActivityRequire(styled.context == report.context, "symbolVariableValueMode preserves context")
    deviceActivityRequire(styled.filter == report.filter, "symbolVariableValueMode preserves filter")
}

func testDeviceActivityReportStubToolbarTitleDisplayMode() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.toolbarTitleDisplayMode(0)
    deviceActivityRequire(styled.context == report.context, "toolbarTitleDisplayMode preserves context")
    deviceActivityRequire(styled.filter == report.filter, "toolbarTitleDisplayMode preserves filter")
}

func testDeviceActivityReportStubAccessibilityDirectTouch() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.accessibilityDirectTouch(0)
    deviceActivityRequire(styled.context == report.context, "accessibilityDirectTouch preserves context")
    deviceActivityRequire(styled.filter == report.filter, "accessibilityDirectTouch preserves filter")
}

func testDeviceActivityReportStubAccessibilityInputLabels() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.accessibilityInputLabels(0)
    deviceActivityRequire(styled.context == report.context, "accessibilityInputLabels preserves context")
    deviceActivityRequire(styled.filter == report.filter, "accessibilityInputLabels preserves filter")
}

func testDeviceActivityReportStubAccessibilityLabeledPair() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.accessibilityLabeledPair(0)
    deviceActivityRequire(styled.context == report.context, "accessibilityLabeledPair preserves context")
    deviceActivityRequire(styled.filter == report.filter, "accessibilityLabeledPair preserves filter")
}

func testDeviceActivityReportStubAccessibilityLinkedGroup() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.accessibilityLinkedGroup(0)
    deviceActivityRequire(styled.context == report.context, "accessibilityLinkedGroup preserves context")
    deviceActivityRequire(styled.filter == report.filter, "accessibilityLinkedGroup preserves filter")
}

func testDeviceActivityReportStubFileDialogBrowserOptions() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.fileDialogBrowserOptions(0)
    deviceActivityRequire(styled.context == report.context, "fileDialogBrowserOptions preserves context")
    deviceActivityRequire(styled.filter == report.filter, "fileDialogBrowserOptions preserves filter")
}

func testDeviceActivityReportStubListSectionSeparatorTint() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.listSectionSeparatorTint(0)
    deviceActivityRequire(styled.context == report.context, "listSectionSeparatorTint preserves context")
    deviceActivityRequire(styled.filter == report.filter, "listSectionSeparatorTint preserves filter")
}

func testDeviceActivityReportStubMaterialActiveAppearance() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.materialActiveAppearance(0)
    deviceActivityRequire(styled.context == report.context, "materialActiveAppearance preserves context")
    deviceActivityRequire(styled.filter == report.filter, "materialActiveAppearance preserves filter")
}

func testDeviceActivityReportStubOnScrollVisibilityChange() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.onScrollVisibilityChange(0)
    deviceActivityRequire(styled.context == report.context, "onScrollVisibilityChange preserves context")
    deviceActivityRequire(styled.filter == report.filter, "onScrollVisibilityChange preserves filter")
}

func testDeviceActivityReportStubPersistentSystemOverlays() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.persistentSystemOverlays(0)
    deviceActivityRequire(styled.context == report.context, "persistentSystemOverlays preserves context")
    deviceActivityRequire(styled.filter == report.filter, "persistentSystemOverlays preserves filter")
}

func testDeviceActivityReportStubPresentationCornerRadius() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.presentationCornerRadius(0)
    deviceActivityRequire(styled.context == report.context, "presentationCornerRadius preserves context")
    deviceActivityRequire(styled.filter == report.filter, "presentationCornerRadius preserves filter")
}

func testDeviceActivityReportStubSymbolColorRenderingMode() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.symbolColorRenderingMode(0)
    deviceActivityRequire(styled.context == report.context, "symbolColorRenderingMode preserves context")
    deviceActivityRequire(styled.filter == report.filter, "symbolColorRenderingMode preserves filter")
}

func testDeviceActivityReportStubAccessibilityDefaultFocus() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.accessibilityDefaultFocus(0)
    deviceActivityRequire(styled.context == report.context, "accessibilityDefaultFocus preserves context")
    deviceActivityRequire(styled.filter == report.filter, "accessibilityDefaultFocus preserves filter")
}

func testDeviceActivityReportStubAccessibilityRemoveTraits() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.accessibilityRemoveTraits(0)
    deviceActivityRequire(styled.context == report.context, "accessibilityRemoveTraits preserves context")
    deviceActivityRequire(styled.filter == report.filter, "accessibilityRemoveTraits preserves filter")
}

func testDeviceActivityReportStubAccessibilityScrollAction() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.accessibilityScrollAction(0)
    deviceActivityRequire(styled.context == report.context, "accessibilityScrollAction preserves context")
    deviceActivityRequire(styled.filter == report.filter, "accessibilityScrollAction preserves filter")
}

func testDeviceActivityReportStubAccessibilityScrollStatus() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.accessibilityScrollStatus(0)
    deviceActivityRequire(styled.context == report.context, "accessibilityScrollStatus preserves context")
    deviceActivityRequire(styled.filter == report.filter, "accessibilityScrollStatus preserves filter")
}

func testDeviceActivityReportStubAccessibilitySortPriority() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.accessibilitySortPriority(0)
    deviceActivityRequire(styled.context == report.context, "accessibilitySortPriority preserves context")
    deviceActivityRequire(styled.filter == report.filter, "accessibilitySortPriority preserves filter")
}

func testDeviceActivityReportStubBackgroundExtensionEffect() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.backgroundExtensionEffect(0)
    deviceActivityRequire(styled.context == report.context, "backgroundExtensionEffect preserves context")
    deviceActivityRequire(styled.filter == report.filter, "backgroundExtensionEffect preserves filter")
}

func testDeviceActivityReportStubBackgroundPreferenceValue() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.backgroundPreferenceValue(0)
    deviceActivityRequire(styled.context == report.context, "backgroundPreferenceValue preserves context")
    deviceActivityRequire(styled.filter == report.filter, "backgroundPreferenceValue preserves filter")
}

func testDeviceActivityReportStubFileDialogCustomizationID() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.fileDialogCustomizationID(0)
    deviceActivityRequire(styled.context == report.context, "fileDialogCustomizationID preserves context")
    deviceActivityRequire(styled.filter == report.filter, "fileDialogCustomizationID preserves filter")
}

func testDeviceActivityReportStubFileExporterFilenameLabel() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.fileExporterFilenameLabel(0)
    deviceActivityRequire(styled.context == report.context, "fileExporterFilenameLabel preserves context")
    deviceActivityRequire(styled.filter == report.filter, "fileExporterFilenameLabel preserves filter")
}

func testDeviceActivityReportStubMenuActionDismissBehavior() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.menuActionDismissBehavior(0)
    deviceActivityRequire(styled.context == report.context, "menuActionDismissBehavior preserves context")
    deviceActivityRequire(styled.filter == report.filter, "menuActionDismissBehavior preserves filter")
}

func testDeviceActivityReportStubOnInteractiveResizeChange() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.onInteractiveResizeChange(0)
    deviceActivityRequire(styled.context == report.context, "onInteractiveResizeChange preserves context")
    deviceActivityRequire(styled.filter == report.filter, "onInteractiveResizeChange preserves filter")
}

func testDeviceActivityReportStubPresentationDragIndicator() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.presentationDragIndicator(0)
    deviceActivityRequire(styled.context == report.context, "presentationDragIndicator preserves context")
    deviceActivityRequire(styled.filter == report.filter, "presentationDragIndicator preserves filter")
}

func testDeviceActivityReportStubSpeechAnnouncementsQueued() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.speechAnnouncementsQueued(0)
    deviceActivityRequire(styled.context == report.context, "speechAnnouncementsQueued preserves context")
    deviceActivityRequire(styled.filter == report.filter, "speechAnnouncementsQueued preserves filter")
}

func testDeviceActivityReportStubSpeechSpellsOutCharacters() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.speechSpellsOutCharacters(0)
    deviceActivityRequire(styled.context == report.context, "speechSpellsOutCharacters preserves context")
    deviceActivityRequire(styled.filter == report.filter, "speechSpellsOutCharacters preserves filter")
}

func testDeviceActivityReportStubTransformAnchorPreference() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.transformAnchorPreference(0)
    deviceActivityRequire(styled.context == report.context, "transformAnchorPreference preserves context")
    deviceActivityRequire(styled.filter == report.filter, "transformAnchorPreference preserves filter")
}

func testDeviceActivityReportStubAccessibilityCustomContent() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.accessibilityCustomContent(0)
    deviceActivityRequire(styled.context == report.context, "accessibilityCustomContent preserves context")
    deviceActivityRequire(styled.filter == report.filter, "accessibilityCustomContent preserves filter")
}

func testDeviceActivityReportStubDocumentBrowserContextMenu() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.documentBrowserContextMenu(0)
    deviceActivityRequire(styled.context == report.context, "documentBrowserContextMenu preserves context")
    deviceActivityRequire(styled.filter == report.filter, "documentBrowserContextMenu preserves filter")
}

func testDeviceActivityReportStubFileDialogDefaultDirectory() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.fileDialogDefaultDirectory(0)
    deviceActivityRequire(styled.context == report.context, "fileDialogDefaultDirectory preserves context")
    deviceActivityRequire(styled.filter == report.filter, "fileDialogDefaultDirectory preserves filter")
}

func testDeviceActivityReportStubInteractiveDismissDisabled() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.interactiveDismissDisabled(0)
    deviceActivityRequire(styled.context == report.context, "interactiveDismissDisabled preserves context")
    deviceActivityRequire(styled.filter == report.filter, "interactiveDismissDisabled preserves filter")
}

func testDeviceActivityReportStubListSectionIndexVisibility() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.listSectionIndexVisibility(0)
    deviceActivityRequire(styled.context == report.context, "listSectionIndexVisibility preserves context")
    deviceActivityRequire(styled.filter == report.filter, "listSectionIndexVisibility preserves filter")
}

func testDeviceActivityReportStubAccessibilityRepresentation() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.accessibilityRepresentation(0)
    deviceActivityRequire(styled.context == report.context, "accessibilityRepresentation preserves context")
    deviceActivityRequire(styled.filter == report.filter, "accessibilityRepresentation preserves filter")
}

func testDeviceActivityReportStubFileDialogConfirmationLabel() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.fileDialogConfirmationLabel(0)
    deviceActivityRequire(styled.context == report.context, "fileDialogConfirmationLabel preserves context")
    deviceActivityRequire(styled.filter == report.filter, "fileDialogConfirmationLabel preserves filter")
}

func testDeviceActivityReportStubPreviewInterfaceOrientation() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.previewInterfaceOrientation(0)
    deviceActivityRequire(styled.context == report.context, "previewInterfaceOrientation preserves context")
    deviceActivityRequire(styled.filter == report.filter, "previewInterfaceOrientation preserves filter")
}

func testDeviceActivityReportStubTextInputAutocapitalization() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.textInputAutocapitalization(0)
    deviceActivityRequire(styled.context == report.context, "textInputAutocapitalization preserves context")
    deviceActivityRequire(styled.filter == report.filter, "textInputAutocapitalization preserves filter")
}

func testDeviceActivityReportStubToolbarBackgroundVisibility() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.toolbarBackgroundVisibility(0)
    deviceActivityRequire(styled.context == report.context, "toolbarBackgroundVisibility preserves context")
    deviceActivityRequire(styled.filter == report.filter, "toolbarBackgroundVisibility preserves filter")
}

func testDeviceActivityReportStubAccessibilityActivationPoint() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.accessibilityActivationPoint(0)
    deviceActivityRequire(styled.context == report.context, "accessibilityActivationPoint preserves context")
    deviceActivityRequire(styled.filter == report.filter, "accessibilityActivationPoint preserves filter")
}

func testDeviceActivityReportStubAccessibilityChartDescriptor() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.accessibilityChartDescriptor(0)
    deviceActivityRequire(styled.context == report.context, "accessibilityChartDescriptor preserves context")
    deviceActivityRequire(styled.filter == report.filter, "accessibilityChartDescriptor preserves filter")
}

func testDeviceActivityReportStubAccessibilityTextContentType() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.accessibilityTextContentType(0)
    deviceActivityRequire(styled.context == report.context, "accessibilityTextContentType preserves context")
    deviceActivityRequire(styled.filter == report.filter, "accessibilityTextContentType preserves filter")
}

func testDeviceActivityReportStubAllowsWindowActivationEvents() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.allowsWindowActivationEvents(0)
    deviceActivityRequire(styled.context == report.context, "allowsWindowActivationEvents preserves context")
    deviceActivityRequire(styled.filter == report.filter, "allowsWindowActivationEvents preserves filter")
}

func testDeviceActivityReportStubAccessibilityAdjustableAction() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.accessibilityAdjustableAction(0)
    deviceActivityRequire(styled.context == report.context, "accessibilityAdjustableAction preserves context")
    deviceActivityRequire(styled.filter == report.filter, "accessibilityAdjustableAction preserves filter")
}

func testDeviceActivityReportStubAssistiveAccessNavigationIcon() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.assistiveAccessNavigationIcon(0)
    deviceActivityRequire(styled.context == report.context, "assistiveAccessNavigationIcon preserves context")
    deviceActivityRequire(styled.filter == report.filter, "assistiveAccessNavigationIcon preserves filter")
}

func testDeviceActivityReportStubNavigationBarBackButtonHidden() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.navigationBarBackButtonHidden(0)
    deviceActivityRequire(styled.context == report.context, "navigationBarBackButtonHidden preserves context")
    deviceActivityRequire(styled.filter == report.filter, "navigationBarBackButtonHidden preserves filter")
}

func testDeviceActivityReportStubNavigationBarTitleDisplayMode() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.navigationBarTitleDisplayMode(0)
    deviceActivityRequire(styled.context == report.context, "navigationBarTitleDisplayMode preserves context")
    deviceActivityRequire(styled.filter == report.filter, "navigationBarTitleDisplayMode preserves filter")
}

func testDeviceActivityReportStubPresentationCompactAdaptation() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.presentationCompactAdaptation(0)
    deviceActivityRequire(styled.context == report.context, "presentationCompactAdaptation preserves context")
    deviceActivityRequire(styled.filter == report.filter, "presentationCompactAdaptation preserves filter")
}

func testDeviceActivityReportStubId() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.id(0)
    deviceActivityRequire(styled.context == report.context, "id preserves context")
    deviceActivityRequire(styled.filter == report.filter, "id preserves filter")
}

func testDeviceActivityReportStubInteractionActivityTrackingTag() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.interactionActivityTrackingTag(0)
    deviceActivityRequire(styled.context == report.context, "interactionActivityTrackingTag preserves context")
    deviceActivityRequire(styled.filter == report.filter, "interactionActivityTrackingTag preserves filter")
}

func testDeviceActivityReportStubOnScrollTargetVisibilityChange() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.onScrollTargetVisibilityChange(0)
    deviceActivityRequire(styled.context == report.context, "onScrollTargetVisibilityChange preserves context")
    deviceActivityRequire(styled.filter == report.filter, "onScrollTargetVisibilityChange preserves filter")
}

func testDeviceActivityReportStubPresentationContentInteraction() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.presentationContentInteraction(0)
    deviceActivityRequire(styled.context == report.context, "presentationContentInteraction preserves context")
    deviceActivityRequire(styled.filter == report.filter, "presentationContentInteraction preserves filter")
}

func testDeviceActivityReportStubDefaultAdaptableTabBarPlacement() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.defaultAdaptableTabBarPlacement(0)
    deviceActivityRequire(styled.context == report.context, "defaultAdaptableTabBarPlacement preserves context")
    deviceActivityRequire(styled.filter == report.filter, "defaultAdaptableTabBarPlacement preserves filter")
}

func testDeviceActivityReportStubSpeechAlwaysIncludesPunctuation() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.speechAlwaysIncludesPunctuation(0)
    deviceActivityRequire(styled.context == report.context, "speechAlwaysIncludesPunctuation preserves context")
    deviceActivityRequire(styled.filter == report.filter, "speechAlwaysIncludesPunctuation preserves filter")
}

func testDeviceActivityReportStubAccessibilityIgnoresInvertColors() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.accessibilityIgnoresInvertColors(0)
    deviceActivityRequire(styled.context == report.context, "accessibilityIgnoresInvertColors preserves context")
    deviceActivityRequire(styled.filter == report.filter, "accessibilityIgnoresInvertColors preserves filter")
}

func testDeviceActivityReportStubWritingToolsAffordanceVisibility() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.writingToolsAffordanceVisibility(0)
    deviceActivityRequire(styled.context == report.context, "writingToolsAffordanceVisibility preserves context")
    deviceActivityRequire(styled.filter == report.filter, "writingToolsAffordanceVisibility preserves filter")
}

func testDeviceActivityReportStubNavigationLinkIndicatorVisibility() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.navigationLinkIndicatorVisibility(0)
    deviceActivityRequire(styled.context == report.context, "navigationLinkIndicatorVisibility preserves context")
    deviceActivityRequire(styled.filter == report.filter, "navigationLinkIndicatorVisibility preserves filter")
}

func testDeviceActivityReportStubPresentationBackgroundInteraction() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.presentationBackgroundInteraction(0)
    deviceActivityRequire(styled.context == report.context, "presentationBackgroundInteraction preserves context")
    deviceActivityRequire(styled.filter == report.filter, "presentationBackgroundInteraction preserves filter")
}

func testDeviceActivityReportStubSearchPresentationToolbarBehavior() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.searchPresentationToolbarBehavior(0)
    deviceActivityRequire(styled.context == report.context, "searchPresentationToolbarBehavior preserves context")
    deviceActivityRequire(styled.filter == report.filter, "searchPresentationToolbarBehavior preserves filter")
}

func testDeviceActivityReportStubWindowToolbarFullScreenVisibility() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.windowToolbarFullScreenVisibility(0)
    deviceActivityRequire(styled.context == report.context, "windowToolbarFullScreenVisibility preserves context")
    deviceActivityRequire(styled.filter == report.filter, "windowToolbarFullScreenVisibility preserves filter")
}

func testDeviceActivityReportStubAttributedTextFormattingDefinition() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.attributedTextFormattingDefinition(0)
    deviceActivityRequire(styled.context == report.context, "attributedTextFormattingDefinition preserves context")
    deviceActivityRequire(styled.filter == report.filter, "attributedTextFormattingDefinition preserves filter")
}

func testDeviceActivityReportStubFileDialogImportsUnresolvedAliases() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.fileDialogImportsUnresolvedAliases(0)
    deviceActivityRequire(styled.context == report.context, "fileDialogImportsUnresolvedAliases preserves context")
    deviceActivityRequire(styled.filter == report.filter, "fileDialogImportsUnresolvedAliases preserves filter")
}

func testDeviceActivityReportStubFlipsForRightToLeftLayoutDirection() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.flipsForRightToLeftLayoutDirection(0)
    deviceActivityRequire(styled.context == report.context, "flipsForRightToLeftLayoutDirection preserves context")
    deviceActivityRequire(styled.filter == report.filter, "flipsForRightToLeftLayoutDirection preserves filter")
}

func testDeviceActivityReportStubAccessibilityShowsLargeContentViewer() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.accessibilityShowsLargeContentViewer(0)
    deviceActivityRequire(styled.context == report.context, "accessibilityShowsLargeContentViewer preserves context")
    deviceActivityRequire(styled.filter == report.filter, "accessibilityShowsLargeContentViewer preserves filter")
}

func testDeviceActivityReportStubTextInputFormattingControlVisibility() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.textInputFormattingControlVisibility(0)
    deviceActivityRequire(styled.context == report.context, "textInputFormattingControlVisibility preserves context")
    deviceActivityRequire(styled.filter == report.filter, "textInputFormattingControlVisibility preserves filter")
}

func testDeviceActivityReportStubAccessibilityRespondsToUserInteraction() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.accessibilityRespondsToUserInteraction(0)
    deviceActivityRequire(styled.context == report.context, "accessibilityRespondsToUserInteraction preserves context")
    deviceActivityRequire(styled.filter == report.filter, "accessibilityRespondsToUserInteraction preserves filter")
}

func testDeviceActivityReportStubTag() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.tag(0)
    deviceActivityRequire(styled.context == report.context, "tag preserves context")
    deviceActivityRequire(styled.filter == report.filter, "tag preserves filter")
}

func testDeviceActivityReportStubBlur() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.blur(0)
    deviceActivityRequire(styled.context == report.context, "blur preserves context")
    deviceActivityRequire(styled.filter == report.filter, "blur preserves filter")
}

func testDeviceActivityReportStubBold() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.bold(0)
    deviceActivityRequire(styled.context == report.context, "bold preserves context")
    deviceActivityRequire(styled.filter == report.filter, "bold preserves filter")
}

func testDeviceActivityReportStubFont() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.font(0)
    deviceActivityRequire(styled.context == report.context, "font preserves context")
    deviceActivityRequire(styled.filter == report.filter, "font preserves filter")
}

func testDeviceActivityReportStubHelp() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.help(0)
    deviceActivityRequire(styled.context == report.context, "help preserves context")
    deviceActivityRequire(styled.filter == report.filter, "help preserves filter")
}

func testDeviceActivityReportStubMask() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.mask(0)
    deviceActivityRequire(styled.context == report.context, "mask preserves context")
    deviceActivityRequire(styled.filter == report.filter, "mask preserves filter")
}

func testDeviceActivityReportStubTask() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.task(0)
    deviceActivityRequire(styled.context == report.context, "task preserves context")
    deviceActivityRequire(styled.filter == report.filter, "task preserves filter")
}

func testDeviceActivityReportStubTint() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.tint(0)
    deviceActivityRequire(styled.context == report.context, "tint preserves context")
    deviceActivityRequire(styled.filter == report.filter, "tint preserves filter")
}

func testDeviceActivityReportStubAlert() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.alert(0)
    deviceActivityRequire(styled.context == report.context, "alert preserves context")
    deviceActivityRequire(styled.filter == report.filter, "alert preserves filter")
}

func testDeviceActivityReportStubBadge() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.badge(0)
    deviceActivityRequire(styled.context == report.context, "badge preserves context")
    deviceActivityRequire(styled.filter == report.filter, "badge preserves filter")
}

func testDeviceActivityReportStubFrame() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.frame(0)
    deviceActivityRequire(styled.context == report.context, "frame preserves context")
    deviceActivityRequire(styled.filter == report.filter, "frame preserves filter")
}

func testDeviceActivityReportStubSheet() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.sheet(0)
    deviceActivityRequire(styled.context == report.context, "sheet preserves context")
    deviceActivityRequire(styled.filter == report.filter, "sheet preserves filter")
}

func testDeviceActivityReportStubBorder() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.border(0)
    deviceActivityRequire(styled.context == report.context, "border preserves context")
    deviceActivityRequire(styled.filter == report.filter, "border preserves filter")
}

func testDeviceActivityReportStubHidden() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.hidden(0)
    deviceActivityRequire(styled.context == report.context, "hidden preserves context")
    deviceActivityRequire(styled.filter == report.filter, "hidden preserves filter")
}

func testDeviceActivityReportStubItalic() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.italic(0)
    deviceActivityRequire(styled.context == report.context, "italic preserves context")
    deviceActivityRequire(styled.filter == report.filter, "italic preserves filter")
}

func testDeviceActivityReportStubOffset() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.offset(0)
    deviceActivityRequire(styled.context == report.context, "offset preserves context")
    deviceActivityRequire(styled.filter == report.filter, "offset preserves filter")
}

func testDeviceActivityReportStubOnDrag() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.onDrag(0)
    deviceActivityRequire(styled.context == report.context, "onDrag preserves context")
    deviceActivityRequire(styled.filter == report.filter, "onDrag preserves filter")
}

func testDeviceActivityReportStubOnDrop() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.onDrop(0)
    deviceActivityRequire(styled.context == report.context, "onDrop preserves context")
    deviceActivityRequire(styled.filter == report.filter, "onDrop preserves filter")
}

func testDeviceActivityReportStubShadow() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.shadow(0)
    deviceActivityRequire(styled.context == report.context, "shadow preserves context")
    deviceActivityRequire(styled.filter == report.filter, "shadow preserves filter")
}

func testDeviceActivityReportStubZIndex() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.zIndex(0)
    deviceActivityRequire(styled.context == report.context, "zIndex preserves context")
    deviceActivityRequire(styled.filter == report.filter, "zIndex preserves filter")
}

func testDeviceActivityReportStubClipped() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.clipped(0)
    deviceActivityRequire(styled.context == report.context, "clipped preserves context")
    deviceActivityRequire(styled.filter == report.filter, "clipped preserves filter")
}

func testDeviceActivityReportStubFocused() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.focused(0)
    deviceActivityRequire(styled.context == report.context, "focused preserves context")
    deviceActivityRequire(styled.filter == report.filter, "focused preserves filter")
}

func testDeviceActivityReportStubGesture() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.gesture(0)
    deviceActivityRequire(styled.context == report.context, "gesture preserves context")
    deviceActivityRequire(styled.filter == report.filter, "gesture preserves filter")
}

func testDeviceActivityReportStubKerning() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.kerning(0)
    deviceActivityRequire(styled.context == report.context, "kerning preserves context")
    deviceActivityRequire(styled.filter == report.filter, "kerning preserves filter")
}

func testDeviceActivityReportStubOnHover() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.onHover(0)
    deviceActivityRequire(styled.context == report.context, "onHover preserves context")
    deviceActivityRequire(styled.filter == report.filter, "onHover preserves filter")
}

func testDeviceActivityReportStubOpacity() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.opacity(0)
    deviceActivityRequire(styled.context == report.context, "opacity preserves context")
    deviceActivityRequire(styled.filter == report.filter, "opacity preserves filter")
}

func testDeviceActivityReportStubOverlay() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.overlay(0)
    deviceActivityRequire(styled.context == report.context, "overlay preserves context")
    deviceActivityRequire(styled.filter == report.filter, "overlay preserves filter")
}

func testDeviceActivityReportStubPadding() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.padding(0)
    deviceActivityRequire(styled.context == report.context, "padding preserves context")
    deviceActivityRequire(styled.filter == report.filter, "padding preserves filter")
}

func testDeviceActivityReportStubPopover() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.popover(0)
    deviceActivityRequire(styled.context == report.context, "popover preserves context")
    deviceActivityRequire(styled.filter == report.filter, "popover preserves filter")
}

func testDeviceActivityReportStubTabItem() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.tabItem(0)
    deviceActivityRequire(styled.context == report.context, "tabItem preserves context")
    deviceActivityRequire(styled.filter == report.filter, "tabItem preserves filter")
}

func testDeviceActivityReportStubToolbar() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.toolbar(0)
    deviceActivityRequire(styled.context == report.context, "toolbar preserves context")
    deviceActivityRequire(styled.filter == report.filter, "toolbar preserves filter")
}

func testDeviceActivityReportStubContrast() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.contrast(0)
    deviceActivityRequire(styled.context == report.context, "contrast preserves context")
    deviceActivityRequire(styled.filter == report.filter, "contrast preserves filter")
}

func testDeviceActivityReportStubDisabled() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.disabled(0)
    deviceActivityRequire(styled.context == report.context, "disabled preserves context")
    deviceActivityRequire(styled.filter == report.filter, "disabled preserves filter")
}

func testDeviceActivityReportStubModifier() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.modifier(0)
    deviceActivityRequire(styled.context == report.context, "modifier preserves context")
    deviceActivityRequire(styled.filter == report.filter, "modifier preserves filter")
}

func testDeviceActivityReportStubOnAppear() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.onAppear(0)
    deviceActivityRequire(styled.context == report.context, "onAppear preserves context")
    deviceActivityRequire(styled.filter == report.filter, "onAppear preserves filter")
}

func testDeviceActivityReportStubOnChange() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.onChange(0)
    deviceActivityRequire(styled.context == report.context, "onChange preserves context")
    deviceActivityRequire(styled.filter == report.filter, "onChange preserves filter")
}

func testDeviceActivityReportStubOnSubmit() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.onSubmit(0)
    deviceActivityRequire(styled.context == report.context, "onSubmit preserves context")
    deviceActivityRequire(styled.filter == report.filter, "onSubmit preserves filter")
}

func testDeviceActivityReportStubPosition() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.position(0)
    deviceActivityRequire(styled.context == report.context, "position preserves context")
    deviceActivityRequire(styled.filter == report.filter, "position preserves filter")
}

func testDeviceActivityReportStubRedacted() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.redacted(0)
    deviceActivityRequire(styled.context == report.context, "redacted preserves context")
    deviceActivityRequire(styled.filter == report.filter, "redacted preserves filter")
}

func testDeviceActivityReportStubTextCase() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.textCase(0)
    deviceActivityRequire(styled.context == report.context, "textCase preserves context")
    deviceActivityRequire(styled.filter == report.filter, "textCase preserves filter")
}

func testDeviceActivityReportStubTracking() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.tracking(0)
    deviceActivityRequire(styled.context == report.context, "tracking preserves context")
    deviceActivityRequire(styled.filter == report.filter, "tracking preserves filter")
}

func testDeviceActivityReportStubAnimation() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.animation(0)
    deviceActivityRequire(styled.context == report.context, "animation preserves context")
    deviceActivityRequire(styled.filter == report.filter, "animation preserves filter")
}

func testDeviceActivityReportStubBlendMode() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.blendMode(0)
    deviceActivityRequire(styled.context == report.context, "blendMode preserves context")
    deviceActivityRequire(styled.filter == report.filter, "blendMode preserves filter")
}

func testDeviceActivityReportStubClipShape() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.clipShape(0)
    deviceActivityRequire(styled.context == report.context, "clipShape preserves context")
    deviceActivityRequire(styled.filter == report.filter, "clipShape preserves filter")
}

func testDeviceActivityReportStubDraggable() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.draggable(0)
    deviceActivityRequire(styled.context == report.context, "draggable preserves context")
    deviceActivityRequire(styled.filter == report.filter, "draggable preserves filter")
}

func testDeviceActivityReportStubFileMover() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.fileMover(0)
    deviceActivityRequire(styled.context == report.context, "fileMover preserves context")
    deviceActivityRequire(styled.filter == report.filter, "fileMover preserves filter")
}

func testDeviceActivityReportStubFixedSize() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.fixedSize(0)
    deviceActivityRequire(styled.context == report.context, "fixedSize preserves context")
    deviceActivityRequire(styled.filter == report.filter, "fixedSize preserves filter")
}

func testDeviceActivityReportStubFocusable() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.focusable(0)
    deviceActivityRequire(styled.context == report.context, "focusable preserves context")
    deviceActivityRequire(styled.filter == report.filter, "focusable preserves filter")
}

func testDeviceActivityReportStubFontWidth() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.fontWidth(0)
    deviceActivityRequire(styled.context == report.context, "fontWidth preserves context")
    deviceActivityRequire(styled.filter == report.filter, "fontWidth preserves filter")
}

func testDeviceActivityReportStubFormStyle() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.formStyle(0)
    deviceActivityRequire(styled.context == report.context, "formStyle preserves context")
    deviceActivityRequire(styled.filter == report.filter, "formStyle preserves filter")
}

func testDeviceActivityReportStubGrayscale() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.grayscale(0)
    deviceActivityRequire(styled.context == report.context, "grayscale preserves context")
    deviceActivityRequire(styled.filter == report.filter, "grayscale preserves filter")
}

func testDeviceActivityReportStubInspector() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.inspector(0)
    deviceActivityRequire(styled.context == report.context, "inspector preserves context")
    deviceActivityRequire(styled.filter == report.filter, "inspector preserves filter")
}

func testDeviceActivityReportStubLineLimit() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.lineLimit(0)
    deviceActivityRequire(styled.context == report.context, "lineLimit preserves context")
    deviceActivityRequire(styled.filter == report.filter, "lineLimit preserves filter")
}

func testDeviceActivityReportStubListStyle() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.listStyle(0)
    deviceActivityRequire(styled.context == report.context, "listStyle preserves context")
    deviceActivityRequire(styled.filter == report.filter, "listStyle preserves filter")
}

func testDeviceActivityReportStubMenuOrder() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.menuOrder(0)
    deviceActivityRequire(styled.context == report.context, "menuOrder preserves context")
    deviceActivityRequire(styled.filter == report.filter, "menuOrder preserves filter")
}

func testDeviceActivityReportStubMenuStyle() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.menuStyle(0)
    deviceActivityRequire(styled.context == report.context, "menuStyle preserves context")
    deviceActivityRequire(styled.filter == report.filter, "menuStyle preserves filter")
}

func testDeviceActivityReportStubOnOpenURL() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.onOpenURL(0)
    deviceActivityRequire(styled.context == report.context, "onOpenURL preserves context")
    deviceActivityRequire(styled.filter == report.filter, "onOpenURL preserves filter")
}

func testDeviceActivityReportStubOnReceive() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.onReceive(0)
    deviceActivityRequire(styled.context == report.context, "onReceive preserves context")
    deviceActivityRequire(styled.filter == report.filter, "onReceive preserves filter")
}

func testDeviceActivityReportStubStatusBar() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.statusBar(0)
    deviceActivityRequire(styled.context == report.context, "statusBar preserves context")
    deviceActivityRequire(styled.filter == report.filter, "statusBar preserves filter")
}

func testDeviceActivityReportStubTextScale() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.textScale(0)
    deviceActivityRequire(styled.context == report.context, "textScale preserves context")
    deviceActivityRequire(styled.filter == report.filter, "textScale preserves filter")
}

func testDeviceActivityReportStubUnderline() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    let styled = report.underline(0)
    deviceActivityRequire(styled.context == report.context, "underline preserves context")
    deviceActivityRequire(styled.filter == report.filter, "underline preserves filter")
}
private struct DeviceActivityStubScene: DeviceActivityReportScene {
    typealias Configuration = String
    typealias Content = String

    var context: DeviceActivityReport.Context
    var content: (Configuration) -> Content

    func makeConfiguration(
        representing data: DeviceActivityResults<DeviceActivityData>
    ) async -> Configuration {
        "stub-configuration"
    }
}

private struct DeviceActivityStubExtension: DeviceActivityReportExtension {
    typealias Body = DeviceActivityStubScene

    var body: Body
}

func testDeviceActivityReportStubSceneSurface() {
    let scene = DeviceActivityStubScene(
        context: DeviceActivityReport.Context("scene"),
        content: { "rendered:\($0)" }
    )
    deviceActivityRequire(scene.context.rawValue == "scene", "scene context")
    deviceActivityRequire(scene.content("cfg") == "rendered:cfg", "scene content")
    deviceActivityRequire(scene.body.context == scene.context, "scene body default")
    deviceActivityRequire(
        DeviceActivityStubScene.Configuration.self == String.self,
        "scene Configuration"
    )
    deviceActivityRequire(
        DeviceActivityStubScene.Content.self == String.self,
        "scene Content"
    )
    let asExistential: any DeviceActivityReportScene = scene
    deviceActivityRequire(
        asExistential.context.rawValue == "scene",
        "scene protocol existential"
    )
}

func testDeviceActivityReportStubExtensionSurface() {
    let scene = DeviceActivityStubScene(
        context: DeviceActivityReport.Context("extension"),
        content: { $0 }
    )
    let ext = DeviceActivityStubExtension(body: scene)
    deviceActivityRequire(
        DeviceActivityStubExtension.Body.self == DeviceActivityStubScene.self,
        "extension Body"
    )
    deviceActivityRequire(ext.body.context.rawValue == "extension", "extension body")
    deviceActivityRequire(
        ext.configuration == ext.body.context,
        "extension configuration default"
    )
}
