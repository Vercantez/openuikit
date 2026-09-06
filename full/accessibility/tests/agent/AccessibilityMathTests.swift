import Foundation
import Accessibility

private final class MathHost: NSObject, AXMathExpressionProvider {
    var stored: AXMathExpression?
    func accessibilityMathExpression() -> AXMathExpression? { stored }
}

func testMathExpressionProvider() {
    let host = MathHost()
    precondition(host.accessibilityMathExpression() == nil)
    host.stored = AXMathExpressionNumber(content: "1")
    precondition(host.accessibilityMathExpression() is AXMathExpressionNumber)
}

func testMathNumber() {
    let number = AXMathExpressionNumber(content: "42")
    precondition(number.content == "42")
    _ = number as AXMathExpression
}

func testMathIdentifier() {
    let identifier = AXMathExpressionIdentifier(content: "x")
    precondition(identifier.content == "x")
}

func testMathOperator() {
    let op = AXMathExpressionOperator(content: "+")
    precondition(op.content == "+")
}

func testMathText() {
    let text = AXMathExpressionText(content: "plus")
    precondition(text.content == "plus")
}

func testMathFenced() {
    let inner = AXMathExpressionNumber(content: "1")
    let fenced = AXMathExpressionFenced(expressions: [inner], openString: "(", closeString: ")")
    precondition(fenced.openString == "(")
    precondition(fenced.closeString == ")")
    precondition(fenced.expressions.count == 1)
    let aliased = AXMathExpressionFenced(expressions: [inner], open: "[", close: "]")
    precondition(aliased.openString == "[")
    precondition(aliased.closeString == "]")
}

func testMathRow() {
    let row = AXMathExpressionRow(expressions: [AXMathExpressionNumber(content: "1")])
    precondition(row.expressions.count == 1)
}

func testMathTable() {
    let table = AXMathExpressionTable(expressions: [AXMathExpressionTableRow(expressions: [])])
    precondition(table.expressions.count == 1)
}

func testMathTableRow() {
    let row = AXMathExpressionTableRow(expressions: [AXMathExpressionTableCell(expressions: [])])
    precondition(row.expressions.count == 1)
}

func testMathTableCell() {
    let cell = AXMathExpressionTableCell(expressions: [AXMathExpressionNumber(content: "0")])
    precondition(cell.expressions.count == 1)
}

func testMathUnderOver() {
    let expr = AXMathExpressionUnderOver(
        baseExpression: AXMathExpressionIdentifier(content: "x"),
        underExpression: AXMathExpressionNumber(content: "0"),
        overExpression: AXMathExpressionNumber(content: "1")
    )
    precondition((expr.baseExpression as? AXMathExpressionIdentifier)?.content == "x")
    precondition((expr.underExpression as? AXMathExpressionNumber)?.content == "0")
    precondition((expr.overExpression as? AXMathExpressionNumber)?.content == "1")
}

func testMathSubSuperscript() {
    let expr = AXMathExpressionSubSuperscript(
        baseExpression: [AXMathExpressionIdentifier(content: "a")],
        subscriptExpressions: [AXMathExpressionNumber(content: "i")],
        superscriptExpressions: [AXMathExpressionNumber(content: "2")]
    )
    precondition((expr.baseExpression as? AXMathExpressionIdentifier)?.content == "a")
    precondition(expr.subscriptExpressions.count == 1)
    precondition(expr.superscriptExpressions.count == 1)
    let empty = AXMathExpressionSubSuperscript(
        baseExpression: [],
        subscriptExpressions: [],
        superscriptExpressions: []
    )
    _ = empty.baseExpression
}

func testMathFraction() {
    let fraction = AXMathExpressionFraction(
        numeratorExpression: AXMathExpressionNumber(content: "1"),
        denimonatorExpression: AXMathExpressionNumber(content: "2")
    )
    precondition((fraction.numeratorExpression as? AXMathExpressionNumber)?.content == "1")
    precondition((fraction.denimonatorExpression as? AXMathExpressionNumber)?.content == "2")
}

func testMathMultiscript() {
    let sub = AXMathExpressionSubSuperscript(
        baseExpression: [AXMathExpressionIdentifier(content: "x")],
        subscriptExpressions: [],
        superscriptExpressions: []
    )
    let multi = AXMathExpressionMultiscript(
        baseExpression: AXMathExpressionIdentifier(content: "M"),
        prescriptExpressions: [sub],
        postscriptExpressions: []
    )
    precondition((multi.baseExpression as? AXMathExpressionIdentifier)?.content == "M")
    precondition(multi.prescriptExpressions.count == 1)
    precondition(multi.postscriptExpressions.isEmpty)
}

func testMathRoot() {
    let root = AXMathExpressionRoot(
        radicandExpressions: [AXMathExpressionNumber(content: "9")],
        rootIndexExpression: AXMathExpressionNumber(content: "2")
    )
    precondition(root.radicandExpressions.count == 1)
    precondition((root.rootIndexExpression as? AXMathExpressionNumber)?.content == "2")
}
