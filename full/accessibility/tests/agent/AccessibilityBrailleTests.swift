import Foundation
import Accessibility

private final class BrailleHost: NSObject, AXBrailleMapRenderer {
    var accessibilityBrailleMapRenderRegion = CGRect.zero
    var accessibilityBrailleMapRenderer: (AXBrailleMap) -> Void = { _ in }
}

func testBrailleMapHeights() {
    let map = AXBrailleMap(dimensions: CGSize(width: 4, height: 2))
    precondition(map.dimensions.width == 4)
    precondition(map.dimensions.height == 2)
    precondition(map.height(at: CGPoint(x: 0, y: 0)) == 0)
    map.setHeight(0.5, at: CGPoint(x: 1, y: 1))
    precondition(map.height(at: CGPoint(x: 1, y: 1)) == 0.5)
    map[CGPoint(x: 2, y: 0)] = 1
    precondition(map[CGPoint(x: 2, y: 0)] == 1)
    map.present(CGImage())
    let copy = map.copy() as! AXBrailleMap
    precondition(copy.height(at: CGPoint(x: 1, y: 1)) == 0.5)
    let data = try! NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
    let decoded = try! NSKeyedUnarchiver.unarchivedObject(ofClass: AXBrailleMap.self, from: data)
    precondition(decoded?.dimensions.width == 4)
    precondition(decoded?.height(at: CGPoint(x: 1, y: 1)) == 0.5)
}

func testBrailleMapRenderer() {
    let host = BrailleHost()
    host.accessibilityBrailleMapRenderRegion = CGRect(x: 0, y: 0, width: 10, height: 10)
    precondition(host.accessibilityBrailleMapRenderRegion.width == 10)
    var seen = false
    host.accessibilityBrailleMapRenderer = { map in
        seen = true
        precondition(map.dimensions.width == 1)
    }
    host.accessibilityBrailleMapRenderer(AXBrailleMap(dimensions: CGSize(width: 1, height: 1)))
    precondition(seen)
}

func testBrailleTableCatalogFailClosed() {
    precondition(AXBrailleTable.languageAgnosticTables().isEmpty)
    precondition(AXBrailleTable.supportedLocales().isEmpty)
    precondition(AXBrailleTable.defaultTable(for: Locale(identifier: "en_US")) == nil)
    precondition(AXBrailleTable.tables(for: Locale(identifier: "en_US")).isEmpty)
    precondition(AXBrailleTable(identifier: "") == nil)
    let table = AXBrailleTable(identifier: "en-us-g1")
    precondition(table?.identifier == "en-us-g1")
    precondition(table?.localizedName == "en-us-g1")
    precondition(table?.providerIdentifier == "")
    precondition(table?.localizedProviderName == "")
    precondition(table?.locales.isEmpty == true)
    precondition(table?.isEightDot == false)
    _ = table?.language
    let data = try! NSKeyedArchiver.archivedData(withRootObject: table!, requiringSecureCoding: true)
    let decoded = try! NSKeyedUnarchiver.unarchivedObject(ofClass: AXBrailleTable.self, from: data)
    precondition(decoded?.identifier == "en-us-g1")
    let copy = table?.copy() as? AXBrailleTable
    precondition(copy?.identifier == "en-us-g1")
}

func testBrailleTranslationResult() {
    let result = AXBrailleTranslationResult(resultString: "abc", locationMap: [0, 1, 2])
    precondition(result.resultString == "abc")
    let idx = result.resultString.index(result.resultString.startIndex, offsetBy: 1)
    _ = result.inputIndex(forResultIndex: idx)
    let data = try! NSKeyedArchiver.archivedData(withRootObject: result, requiringSecureCoding: true)
    let decoded = try! NSKeyedUnarchiver.unarchivedObject(ofClass: AXBrailleTranslationResult.self, from: data)
    precondition(decoded?.resultString == "abc")
    let copy = result.copy() as! AXBrailleTranslationResult
    precondition(copy.resultString == "abc")
}

func testBrailleTranslatorFailClosed() {
    let table = AXBrailleTable(identifier: "placeholder")!
    let translator = AXBrailleTranslator(brailleTable: table)
    precondition(translator.brailleTable.identifier == "placeholder")
    let printResult = translator.translatePrintText("hello")
    precondition(printResult.resultString.isEmpty)
    let back = translator.backTranslateBraille("⠓")
    precondition(back.resultString.isEmpty)
}
