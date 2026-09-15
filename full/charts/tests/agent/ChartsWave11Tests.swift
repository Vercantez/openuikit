import Foundation
@_spi(OpenUIKitHost) import Charts

// Wave-11 leftover sweep: the remaining `declared` ChartContent /
// Chart3DContent / AxisMark / AxisContent modifiers already had real
// retention implementations (record stamping / attributed wrappers) but no
// top-level `test*` caller, so the census left their `Never`-witness rows
// `declared`. Each batch below calls those modifiers directly on concrete
// mark types and pins the retained state. The two
// `PrimitivePlottableProtocol` `Never` witnesses and
// `AnyChartSymbolShape.animatableData` stay `declared`: `Never` is
// uninhabited and the isolated host has no `Animatable` conformance to pin.

private func wave11Bar() -> BarMark {
    BarMark(x: .value("Day", 1), y: .value("Val", 2))
}

func testWave11ChartContentBatch01() {
    let annotated = wave11Bar()
        .annotation(position: .top, alignment: .center, spacing: 4.0) { Text("a1") }
    precondition(annotated.chartPlotRecords.count == 1)
    precondition(annotated.chartPlotRecords[0].annotationPosition == "top")
    let annotatedOverflow = wave11Bar()
        .annotation(
            position: .overlay,
            alignment: .center,
            spacing: 1.0,
            overflowResolution: AnnotationOverflowResolution()
        ) { Text("a2") }
    precondition(annotatedOverflow.chartPlotRecords[0].annotationPosition == "overlay")
    let annotatedContext = wave11Bar()
        .annotation(position: .bottom, alignment: .center, spacing: 2.0) { _ in Text("a3") }
    precondition(annotatedContext.chartPlotRecords[0].annotationPosition == "bottom")
    let annotatedContextOverflow = wave11Bar()
        .annotation(
            position: .leading,
            alignment: .center,
            spacing: 2.0,
            overflowResolution: AnnotationOverflowResolution()
        ) { _ in Text("a4") }
    precondition(annotatedContextOverflow.chartPlotRecords[0].annotationPosition == "leading")
    let bySize = wave11Bar().symbolSize(by: .value("size", 4))
    precondition(bySize.chartPlotRecords[0].layout.symbolBy == "size")
    let areaSize = wave11Bar().symbolSize(12.0)
    precondition(areaSize.chartPlotRecords[0].layout.symbolSize == 12)
    let whSize = wave11Bar().symbolSize(CGSize(width: 3.0, height: 3.0))
    precondition(whSize.chartPlotRecords[0].layout.symbolSize == 9)
    let layered = wave11Bar().compositingLayer()
    precondition(layered.chartPlotRecords[0].layout.compositing == "layer")
    let styledLayer = wave11Bar().compositingLayer { _ in Color.blue }
    precondition(styledLayer.chartPlotRecords[0].layout.compositing == "style")
    let aligned = wave11Bar().alignsMarkStylesWithPlotArea(true)
    precondition(aligned.chartPlotRecords[0].layout.alignsMarkStyles == true)
    let interpolated: _ChartInterpolationContent<BarMark> = wave11Bar().interpolationMethod(.monotone)
    precondition(interpolated.method == .monotone)
    let lineBy = wave11Bar().lineStyle(by: .value("stroke", "dash"))
    precondition(lineBy.chartPlotRecords[0].layout.lineStyleBy == "stroke")
    let lineSolid: _ChartLineStyleContent<BarMark> = wave11Bar().lineStyle(StrokeStyle(lineWidth: 2.0))
    precondition(lineSolid.style.lineWidth == 2.0)
}

func testWave11ChartContentBatch02() {
    let rounded = wave11Bar().cornerRadius(3.0, style: .continuous)
    precondition(rounded.chartPlotRecords[0].layout.cornerRadius == 3)
    let styled = wave11Bar().foregroundStyle(Color.blue)
    precondition(styled.chartPlotRecords[0].foregroundStyleName != nil)
    let styledBy = wave11Bar().foregroundStyle(by: .value("series", "one"))
    precondition(styledBy.chartPlotRecords[0].foregroundStyleName == "series")
    let labeledResource = wave11Bar().accessibilityLabel(LocalizedStringResource("label"))
    precondition(labeledResource.chartPlotRecords[0].layout.accessibilityLabel == "label")
    let labeledKey = wave11Bar().accessibilityLabel(LocalizedStringKey("key"))
    precondition(labeledKey.chartPlotRecords[0].layout.accessibilityLabel == "key")
    let labeledText = wave11Bar().accessibilityLabel(Text("text"))
    precondition(labeledText.chartPlotRecords[0].layout.accessibilityLabel == "text")
    let labeledString = wave11Bar().accessibilityLabel("string")
    precondition(labeledString.chartPlotRecords[0].layout.accessibilityLabel == "string")
    let valuedResource = wave11Bar().accessibilityValue(LocalizedStringResource("value"))
    precondition(valuedResource.chartPlotRecords[0].layout.accessibilityValue == "value")
    let valuedKey = wave11Bar().accessibilityValue(LocalizedStringKey("vkey"))
    precondition(valuedKey.chartPlotRecords[0].layout.accessibilityValue == "vkey")
    let valuedText = wave11Bar().accessibilityValue(Text("vtext"))
    precondition(valuedText.chartPlotRecords[0].layout.accessibilityValue == "vtext")
    let valuedString = wave11Bar().accessibilityValue("vstring")
    precondition(valuedString.chartPlotRecords[0].layout.accessibilityValue == "vstring")
    let hidden = wave11Bar().accessibilityHidden(true)
    precondition(hidden.chartPlotRecords[0].layout.accessibilityHidden == true)
    let identified = wave11Bar().accessibilityIdentifier("id")
    precondition(identified.chartPlotRecords[0].layout.accessibilityIdentifier == "id")
    let blurred = wave11Bar().blur(radius: 1.0)
    precondition(blurred.chartPlotRecords[0].layout.blurRadius == 1)
    let masked = wave11Bar().mask {
        RectangleMark(
            xStart: .value("a", 0),
            xEnd: .value("b", 1),
            yStart: .value("c", 0),
            yEnd: .value("d", 1)
        )
    }
    precondition(masked.chartPlotRecords[0].layout.maskName == "mask")
    let shadowed = wave11Bar().shadow(radius: 2.0)
    precondition(shadowed.chartPlotRecords[0].layout.shadowRadius == 2)
}

func testWave11ChartContentBatch03() {
    let symbolBy = wave11Bar().symbol(by: .value("sym", "circle"))
    precondition(symbolBy.chartPlotRecords[0].layout.symbolBy == "sym")
    let symbolView = wave11Bar().symbol { Circle() }
    precondition(symbolView.chartPlotRecords[0].symbolName == "view")
    let symbolShape = wave11Bar().symbol(BasicChartSymbolShape.square)
    precondition(symbolShape.chartPlotRecords[0].symbolName != nil)
    let indexed = wave11Bar().zIndex(3.0)
    precondition(indexed.chartPlotRecords[0].layout.zIndex == 3)
    let faded = wave11Bar().opacity(0.5)
    precondition(faded.chartPlotRecords[0].opacity == 0.5)
    let positioned = wave11Bar().position(by: .value("pos", 1), axis: .horizontal, span: .automatic)
    precondition(positioned.chartPlotRecords[0].layout.positionBy != nil)
    let clipped = wave11Bar().clipShape(Circle(), style: FillStyle())
    precondition(clipped.chartPlotRecords[0].layout.clipShapeName != nil)
    let offsetXY = wave11Bar().offset(x: 10.0, y: 4.0)
    precondition(offsetXY.chartPlotRecords[0].layout.offsetX == 10)
    precondition(offsetXY.chartPlotRecords[0].layout.offsetY == 4)
    let offsetSize = wave11Bar().offset(CGSize(width: 1.0, height: 2.0))
    precondition(offsetSize.chartPlotRecords[0].layout.offsetX == 1)
    precondition(offsetSize.chartPlotRecords[0].layout.offsetY == 2)
    let offsetYSpan = wave11Bar().offset(x: 0.0, yStart: 2.0, yEnd: 3.0)
    precondition(offsetYSpan.chartPlotRecords[0].layout.offsetYStart == 2)
    precondition(offsetYSpan.chartPlotRecords[0].layout.offsetYEnd == 3)
    let offsetXSpan = wave11Bar().offset(xStart: 1.0, xEnd: 2.0, y: 0.0)
    precondition(offsetXSpan.chartPlotRecords[0].layout.offsetXStart == 1)
    precondition(offsetXSpan.chartPlotRecords[0].layout.offsetXEnd == 2)
    let offsetBothSpans = wave11Bar().offset(xStart: 0.0, xEnd: 1.0, yStart: 0.0, yEnd: 1.0)
    precondition(offsetBothSpans.chartPlotRecords[0].layout.offsetYEnd == 1)
}

func testWave11Chart3DAndAxisBatch04() {
    let sized3D = SurfacePlot().symbolSize(8)
    precondition(sized3D.symbolSize == 8)
    let styledBy3D = SurfacePlot().foregroundStyle(by: .value("k", 1))
    precondition(styledBy3D.foregroundStyleName == "k")
    let styled3D = SurfacePlot().foregroundStyle(Color.blue)
    precondition(styled3D.foregroundStyleName != nil)
    let surfaced3D = SurfacePlot().foregroundStyle(BasicChart3DSurfaceStyle())
    precondition(surfaced3D.surfaceStyleName != nil)
    let shaped3D = SurfacePlot().symbol(BasicChart3DSymbolShape.sphere)
    precondition(shaped3D.symbolName != nil)
    let markStyled = AxisValueLabel("Jan").foregroundStyle(Color.blue)
    precondition(markStyled.foregroundStyleName != nil)
    let markFonted = AxisValueLabel("Jan").font(Font.body)
    precondition(markFonted.fontName != nil)
    let markOffset = AxisValueLabel("Jan").offset(x: 1.0, y: 2.0)
    precondition(markOffset.offsetX == 1)
    precondition(markOffset.offsetY == 2)
    let markOffsetSize = AxisValueLabel("Jan").offset(CGSize(width: 3.0, height: 4.0))
    precondition(markOffsetSize.offsetX == 3)
    precondition(markOffsetSize.offsetY == 4)
    let axisLayered = ChartAxisContent().compositingLayer()
    precondition(axisLayered.compositing == "layer")
    let axisStyledLayer = ChartAxisContent().compositingLayer { _ in Color.blue }
    precondition(axisStyledLayer.compositing == "style")
    _ = SurfacePlot().body
}
