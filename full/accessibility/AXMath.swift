import Foundation

public protocol AXMathExpressionProvider: NSObjectProtocol {
    func accessibilityMathExpression() -> AXMathExpression?
}

public class AXMathExpression: NSObject {
    public override init() {
        super.init()
    }
}

public class AXMathExpressionNumber: AXMathExpression {
    public let content: String

    public init(content: String) {
        self.content = content
        super.init()
    }
}

public class AXMathExpressionIdentifier: AXMathExpression {
    public let content: String

    public init(content: String) {
        self.content = content
        super.init()
    }
}

public class AXMathExpressionOperator: AXMathExpression {
    public let content: String

    public init(content: String) {
        self.content = content
        super.init()
    }
}

public class AXMathExpressionText: AXMathExpression {
    public let content: String

    public init(content: String) {
        self.content = content
        super.init()
    }
}

public class AXMathExpressionFenced: AXMathExpression {
    public let expressions: [AXMathExpression]
    public let openString: String
    public let closeString: String

    public init(expressions: [AXMathExpression], openString: String, closeString: String) {
        self.expressions = expressions
        self.openString = openString
        self.closeString = closeString
        super.init()
    }

    public convenience init(expressions: [AXMathExpression], open openString: String, close closeString: String) {
        self.init(expressions: expressions, openString: openString, closeString: closeString)
    }
}

public class AXMathExpressionRow: AXMathExpression {
    public let expressions: [AXMathExpression]

    public init(expressions: [AXMathExpression]) {
        self.expressions = expressions
        super.init()
    }
}

public class AXMathExpressionTable: AXMathExpression {
    public let expressions: [AXMathExpression]

    public init(expressions: [AXMathExpression]) {
        self.expressions = expressions
        super.init()
    }
}

public class AXMathExpressionTableRow: AXMathExpression {
    public let expressions: [AXMathExpression]

    public init(expressions: [AXMathExpression]) {
        self.expressions = expressions
        super.init()
    }
}

public class AXMathExpressionTableCell: AXMathExpression {
    public let expressions: [AXMathExpression]

    public init(expressions: [AXMathExpression]) {
        self.expressions = expressions
        super.init()
    }
}

public class AXMathExpressionUnderOver: AXMathExpression {
    public let baseExpression: AXMathExpression
    public let underExpression: AXMathExpression
    public let overExpression: AXMathExpression

    public init(
        baseExpression: AXMathExpression,
        underExpression: AXMathExpression,
        overExpression: AXMathExpression
    ) {
        self.baseExpression = baseExpression
        self.underExpression = underExpression
        self.overExpression = overExpression
        super.init()
    }
}

public class AXMathExpressionSubSuperscript: AXMathExpression {
    private let baseExpressions: [AXMathExpression]
    public let subscriptExpressions: [AXMathExpression]
    public let superscriptExpressions: [AXMathExpression]

    /// The Swift overlay stores an array in `init` and a singular
    /// `baseExpression` property. The first child is exposed; an empty array
    /// yields an empty base node. Apple's exact empty-array behavior is unobserved.
    public var baseExpression: AXMathExpression {
        baseExpressions.first ?? AXMathExpression()
    }

    public init(
        baseExpression: [AXMathExpression],
        subscriptExpressions: [AXMathExpression],
        superscriptExpressions: [AXMathExpression]
    ) {
        self.baseExpressions = baseExpression
        self.subscriptExpressions = subscriptExpressions
        self.superscriptExpressions = superscriptExpressions
        super.init()
    }
}

public class AXMathExpressionFraction: AXMathExpression {
    public let numeratorExpression: AXMathExpression
    /// Apple's overlay spells this `denimonatorExpression`.
    public let denimonatorExpression: AXMathExpression

    public init(numeratorExpression: AXMathExpression, denimonatorExpression: AXMathExpression) {
        self.numeratorExpression = numeratorExpression
        self.denimonatorExpression = denimonatorExpression
        super.init()
    }
}

public class AXMathExpressionMultiscript: AXMathExpression {
    public let baseExpression: AXMathExpression
    public let prescriptExpressions: [AXMathExpressionSubSuperscript]
    public let postscriptExpressions: [AXMathExpressionSubSuperscript]

    public init(
        baseExpression: AXMathExpression,
        prescriptExpressions: [AXMathExpressionSubSuperscript],
        postscriptExpressions: [AXMathExpressionSubSuperscript]
    ) {
        self.baseExpression = baseExpression
        self.prescriptExpressions = prescriptExpressions
        self.postscriptExpressions = postscriptExpressions
        super.init()
    }
}

public class AXMathExpressionRoot: AXMathExpression {
    public let radicandExpressions: [AXMathExpression]
    public let rootIndexExpression: AXMathExpression

    public init(radicandExpressions: [AXMathExpression], rootIndexExpression: AXMathExpression) {
        self.radicandExpressions = radicandExpressions
        self.rootIndexExpression = rootIndexExpression
        super.init()
    }
}
