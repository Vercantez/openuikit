import Foundation

enum JSCTokenKind: Equatable {
    case eof
    case ident(String)
    case number(Double)
    case bigint(String)
    case string(String)
    case punct(String)
}

struct JSCToken {
    var kind: JSCTokenKind
    var line: Int32
    var newlineBefore: Bool
}

enum JSCVarKind {
    case `var`
    case `let`
    case `const`
}

indirect enum JSCExpr {
    case ident(String)
    case number(Double)
    case bigint(String)
    case string(String)
    case boolean(Bool)
    case null
    case undefined
    case this
    case array([JSCExpr])
    case object([(String, JSCExpr)])
    case unary(String, JSCExpr, prefix: Bool)
    case binary(String, JSCExpr, JSCExpr)
    case assign(String, JSCExpr, JSCExpr)
    case cond(JSCExpr, JSCExpr, JSCExpr)
    case call(JSCExpr, [JSCExpr])
    case new(JSCExpr, [JSCExpr])
    case member(JSCExpr, String)
    case index(JSCExpr, JSCExpr)
    case function(String?, [String], JSCStmt)
    case comma([JSCExpr])
}

indirect enum JSCStmt {
    case empty
    case block([JSCStmt])
    case expr(JSCExpr)
    case varDecl(JSCVarKind, [(String, JSCExpr?)])
    case function(String, [String], JSCStmt)
    case `return`(JSCExpr?)
    case `throw`(JSCExpr)
    case `if`(JSCExpr, JSCStmt, JSCStmt?)
    case `while`(JSCExpr, JSCStmt)
    case doWhile(JSCStmt, JSCExpr)
    case `for`(JSCStmt?, JSCExpr?, JSCExpr?, JSCStmt)
    case forIn(JSCVarKind?, String, JSCExpr, JSCStmt)
    case `break`
    case `continue`
    case tryCatch(JSCStmt, String?, JSCStmt?, JSCStmt?)
    case switchStmt(JSCExpr, [(JSCExpr?, [JSCStmt])])
}

struct JSCParseError: Error, CustomStringConvertible {
    var message: String
    var line: Int32
    var description: String { "SyntaxError: \(message) (line \(line))" }
}

final class JSCLexer {
    private let scalars: [Unicode.Scalar]
    private var i = 0
    private var line: Int32 = 1
    private var sawNewline = false

    init(_ source: String) {
        scalars = Array(source.unicodeScalars)
    }

    func tokenize() throws -> [JSCToken] {
        var tokens: [JSCToken] = []
        while true {
            let token = try next()
            tokens.append(token)
            if case .eof = token.kind { break }
        }
        return tokens
    }

    private func peekScalar(_ offset: Int = 0) -> Unicode.Scalar? {
        let idx = i + offset
        guard idx < scalars.count else { return nil }
        return scalars[idx]
    }

    private func next() throws -> JSCToken {
        sawNewline = false
        skipIgnorable()
        let startLine = line
        let nl = sawNewline
        guard let ch = peekScalar() else {
            return JSCToken(kind: .eof, line: startLine, newlineBefore: nl)
        }

        if ch == "\"" || ch == "'" {
            return JSCToken(kind: .string(try readString(quote: ch)), line: startLine, newlineBefore: nl)
        }
        if ch == "`" {
            return JSCToken(kind: .string(try readTemplate()), line: startLine, newlineBefore: nl)
        }
        if ch.isJSDigit || (ch == "." && (peekScalar(1)?.isJSDigit ?? false)) {
            return try readNumber(newlineBefore: nl, line: startLine)
        }
        if ch.isJSIdentStart {
            let ident = readIdentifier()
            return JSCToken(kind: .ident(ident), line: startLine, newlineBefore: nl)
        }

        i += 1
        var punct = String(ch)
        if let second = peekScalar() {
            let two = punct + String(second)
            let twoChar = [
                "===", "!==", ">>>", "&&", "||", "==", "!=", "<=", ">=", "<<", ">>",
                "+=", "-=", "*=", "/=", "%=", "&=", "|=", "^=", "??", "**", "=>",
                "++", "--"
            ]
            if twoChar.contains(where: { $0.hasPrefix(two) && $0.count == 2 }) || two == "**"
                || two == "=>" || two == "??" || two == "&&" || two == "||"
                || two == "==" || two == "!=" || two == "<=" || two == ">="
                || two == "<<" || two == ">>" || two == "+=" || two == "-="
                || two == "*=" || two == "/=" || two == "%=" || two == "&="
                || two == "|=" || two == "^=" || two == "++" || two == "--"
            {
                i += 1
                punct = two
                if punct == "==" || punct == "!=" || punct == ">>" {
                    if peekScalar() == "=" || (punct == ">>" && peekScalar() == ">") {
                        if let third = peekScalar() {
                            let three = punct + String(third)
                            if three == "===" || three == "!==" || three == ">>>" {
                                i += 1
                                punct = three
                            }
                        }
                    }
                }
                if punct == "**", peekScalar() == "=" {
                    i += 1
                    punct = "**="
                }
            }
        }
        return JSCToken(kind: .punct(punct), line: startLine, newlineBefore: nl)
    }

    private func skipIgnorable() {
        while let ch = peekScalar() {
            if ch == " " || ch == "\t" || ch == "\u{000B}" || ch == "\u{000C}" || ch == "\r" {
                i += 1
                continue
            }
            if ch == "\n" {
                sawNewline = true
                line += 1
                i += 1
                continue
            }
            if ch == "/", peekScalar(1) == "/" {
                i += 2
                while let cur = peekScalar(), cur != "\n" { i += 1 }
                continue
            }
            if ch == "/", peekScalar(1) == "*" {
                i += 2
                while let cur = peekScalar() {
                    if cur == "*" && peekScalar(1) == "/" {
                        i += 2
                        break
                    }
                    if cur == "\n" { line += 1; sawNewline = true }
                    i += 1
                }
                continue
            }
            break
        }
    }

    private func readIdentifier() -> String {
        var out = ""
        while let ch = peekScalar(), ch.isJSIdentContinue {
            out.unicodeScalars.append(ch)
            i += 1
        }
        return out
    }

    private func readNumber(newlineBefore: Bool, line: Int32) throws -> JSCToken {
        var text = ""
        if peekScalar() == "0", let next = peekScalar(1), next == "x" || next == "X" {
            i += 2
            while let ch = peekScalar(), ch.isHexDigit {
                text.unicodeScalars.append(ch)
                i += 1
            }
            guard let value = UInt64(text, radix: 16) else {
                throw JSCParseError(message: "invalid hex literal", line: line)
            }
            if peekScalar() == "n" {
                i += 1
                let dec = String(value)
                return JSCToken(kind: .bigint(dec), line: line, newlineBefore: newlineBefore)
            }
            return JSCToken(kind: .number(Double(value)), line: line, newlineBefore: newlineBefore)
        }
        while let ch = peekScalar(), ch.isJSDigit {
            text.unicodeScalars.append(ch)
            i += 1
        }
        if peekScalar() == "." {
            text.unicodeScalars.append(".")
            i += 1
            while let ch = peekScalar(), ch.isJSDigit {
                text.unicodeScalars.append(ch)
                i += 1
            }
        }
        if let exp = peekScalar(), exp == "e" || exp == "E" {
            text.unicodeScalars.append(exp)
            i += 1
            if let sign = peekScalar(), sign == "+" || sign == "-" {
                text.unicodeScalars.append(sign)
                i += 1
            }
            while let ch = peekScalar(), ch.isJSDigit {
                text.unicodeScalars.append(ch)
                i += 1
            }
        }
        if peekScalar() == "n" {
            i += 1
            return JSCToken(kind: .bigint(text), line: line, newlineBefore: newlineBefore)
        }
        guard let value = Double(text) else {
            throw JSCParseError(message: "invalid number", line: line)
        }
        return JSCToken(kind: .number(value), line: line, newlineBefore: newlineBefore)
    }

    private func readString(quote: Unicode.Scalar) throws -> String {
        i += 1
        var out = ""
        while let ch = peekScalar() {
            if ch == quote {
                i += 1
                return out
            }
            if ch == "\n" {
                throw JSCParseError(message: "unterminated string", line: line)
            }
            i += 1
            if ch == "\\" {
                out.append(try readEscape())
            } else {
                out.unicodeScalars.append(ch)
            }
        }
        throw JSCParseError(message: "unterminated string", line: line)
    }

    private func readTemplate() throws -> String {
        i += 1
        var out = ""
        while let ch = peekScalar() {
            if ch == "`" {
                i += 1
                return out
            }
            if ch == "$", peekScalar(1) == "{" {
                throw JSCParseError(message: "template interpolation is not implemented", line: line)
            }
            i += 1
            if ch == "\\" {
                out.append(try readEscape())
            } else {
                if ch == "\n" { line += 1 }
                out.unicodeScalars.append(ch)
            }
        }
        throw JSCParseError(message: "unterminated template", line: line)
    }

    private func readEscape() throws -> String {
        guard let ch = peekScalar() else {
            throw JSCParseError(message: "unterminated escape", line: line)
        }
        i += 1
        switch ch {
        case "n": return "\n"
        case "r": return "\r"
        case "t": return "\t"
        case "b": return "\u{0008}"
        case "f": return "\u{000C}"
        case "v": return "\u{000B}"
        case "0": return "\u{0000}"
        case "\\", "'", "\"", "`": return String(ch)
        case "x":
            guard let a = peekScalar(), let b = peekScalar(1), a.isHexDigit, b.isHexDigit else {
                throw JSCParseError(message: "invalid hex escape", line: line)
            }
            i += 2
            let value = Int(String(a), radix: 16)! * 16 + Int(String(b), radix: 16)!
            return String(Unicode.Scalar(value)!)
        case "u":
            if peekScalar() == "{" {
                i += 1
                var hex = ""
                while let h = peekScalar(), h.isHexDigit {
                    hex.unicodeScalars.append(h)
                    i += 1
                }
                guard peekScalar() == "}" else {
                    throw JSCParseError(message: "invalid unicode escape", line: line)
                }
                i += 1
                guard let value = Int(hex, radix: 16), let scalar = Unicode.Scalar(value) else {
                    throw JSCParseError(message: "invalid unicode escape", line: line)
                }
                return String(scalar)
            }
            var hex = ""
            for _ in 0..<4 {
                guard let h = peekScalar(), h.isHexDigit else {
                    throw JSCParseError(message: "invalid unicode escape", line: line)
                }
                hex.unicodeScalars.append(h)
                i += 1
            }
            guard let value = Int(hex, radix: 16), let scalar = Unicode.Scalar(value) else {
                throw JSCParseError(message: "invalid unicode escape", line: line)
            }
            return String(scalar)
        default:
            return String(ch)
        }
    }
}

private extension Unicode.Scalar {
    var isJSDigit: Bool { self >= "0" && self <= "9" }
    var isHexDigit: Bool {
        isJSDigit || (self >= "a" && self <= "f") || (self >= "A" && self <= "F")
    }
    var isJSIdentStart: Bool {
        self == "_" || self == "$" || CharacterSet.letters.contains(self)
    }
    var isJSIdentContinue: Bool { isJSIdentStart || isJSDigit }
}

final class JSCParser {
    private let tokens: [JSCToken]
    private var i = 0

    init(source: String) throws {
        tokens = try JSCLexer(source).tokenize()
    }

    func parseProgram() throws -> JSCStmt {
        var body: [JSCStmt] = []
        while !atEOF {
            body.append(try parseStatement())
        }
        return .block(body)
    }

    func parseProgramAllowingExpression() throws -> JSCStmt {
        let saved = i
        do {
            return try parseProgram()
        } catch {
            i = saved
            let expr = try parseExpression()
            if !atEOF, !matchPunct(";") {
                throw peekError("unexpected token after expression")
            }
            return .expr(expr)
        }
    }

    private var atEOF: Bool {
        if case .eof = peek.kind { return true }
        return false
    }

    private var peek: JSCToken { tokens[i] }

    private func advance() -> JSCToken {
        let token = tokens[i]
        if i < tokens.count - 1 { i += 1 }
        return token
    }

    private func matchPunct(_ value: String) -> Bool {
        if case .punct(value) = peek.kind {
            _ = advance()
            return true
        }
        return false
    }

    private func matchIdent(_ value: String) -> Bool {
        if case .ident(value) = peek.kind {
            _ = advance()
            return true
        }
        return false
    }

    private func expectPunct(_ value: String) throws {
        guard matchPunct(value) else {
            throw peekError("expected '\(value)'")
        }
    }

    private func peekError(_ message: String) -> JSCParseError {
        JSCParseError(message: message, line: peek.line)
    }

    private func parseStatement() throws -> JSCStmt {
        if matchPunct(";") { return .empty }
        if matchPunct("{") { return .block(try parseBlock()) }
        if matchIdent("var") { return try parseVar(.var) }
        if matchIdent("let") { return try parseVar(.let) }
        if matchIdent("const") { return try parseVar(.const) }
        if matchIdent("function") { return try parseFunctionStmt() }
        if matchIdent("return") { return .return(try optionalExprAfterKeyword()) }
        if matchIdent("throw") {
            guard let expr = try optionalExprAfterKeyword() else {
                throw peekError("throw requires an expression")
            }
            return .throw(expr)
        }
        if matchIdent("if") { return try parseIf() }
        if matchIdent("while") { return try parseWhile() }
        if matchIdent("do") { return try parseDoWhile() }
        if matchIdent("for") { return try parseFor() }
        if matchIdent("break") { eatSemicolon(); return .break }
        if matchIdent("continue") { eatSemicolon(); return .continue }
        if matchIdent("try") { return try parseTry() }
        if matchIdent("switch") { return try parseSwitch() }
        if matchIdent("class") || matchIdent("async") || matchIdent("import") || matchIdent("export")
            || matchIdent("yield") || matchIdent("await")
        {
            throw peekError("this JavaScript construct is not implemented")
        }
        let expr = try parseExpression()
        eatSemicolon()
        return .expr(expr)
    }

    private func parseBlock() throws -> [JSCStmt] {
        var body: [JSCStmt] = []
        while !matchPunct("}") {
            if atEOF { throw peekError("unterminated block") }
            body.append(try parseStatement())
        }
        return body
    }

    private func parseVar(_ kind: JSCVarKind) throws -> JSCStmt {
        var decls: [(String, JSCExpr?)] = []
        repeat {
            guard case .ident(let name) = peek.kind else {
                throw peekError("expected identifier")
            }
            _ = advance()
            var initExpr: JSCExpr?
            if matchPunct("=") {
                initExpr = try parseExpressionNoComma()
            } else if kind == .const {
                throw peekError("const declaration requires an initializer")
            }
            decls.append((name, initExpr))
        } while matchPunct(",")
        eatSemicolon()
        return .varDecl(kind, decls)
    }

    private func parseFunctionStmt() throws -> JSCStmt {
        guard case .ident(let name) = peek.kind else {
            throw peekError("expected function name")
        }
        _ = advance()
        let params = try parseParamList()
        try expectPunct("{")
        let body = JSCStmt.block(try parseBlock())
        return .function(name, params, body)
    }

    private func parseParamList() throws -> [String] {
        try expectPunct("(")
        var params: [String] = []
        if !matchPunct(")") {
            repeat {
                guard case .ident(let name) = peek.kind else {
                    throw peekError("expected parameter name")
                }
                _ = advance()
                params.append(name)
            } while matchPunct(",")
            try expectPunct(")")
        }
        return params
    }

    private func parseIf() throws -> JSCStmt {
        try expectPunct("(")
        let test = try parseExpression()
        try expectPunct(")")
        let thenStmt = try parseStatement()
        var elseStmt: JSCStmt?
        if matchIdent("else") {
            elseStmt = try parseStatement()
        }
        return .if(test, thenStmt, elseStmt)
    }

    private func parseWhile() throws -> JSCStmt {
        try expectPunct("(")
        let test = try parseExpression()
        try expectPunct(")")
        return .while(test, try parseStatement())
    }

    private func parseDoWhile() throws -> JSCStmt {
        let body = try parseStatement()
        guard matchIdent("while") else { throw peekError("expected while") }
        try expectPunct("(")
        let test = try parseExpression()
        try expectPunct(")")
        eatSemicolon()
        return .doWhile(body, test)
    }

    private func parseFor() throws -> JSCStmt {
        try expectPunct("(")
        if matchIdent("var") || tokens[max(i - 1, 0)].isIdent("var") {
            // handled below via rewind-less checks
        }
        let saved = i
        if matchIdent("var") || matchIdent("let") || matchIdent("const") {
            let kind: JSCVarKind
            if case .ident(let word) = tokens[i - 1].kind {
                kind = word == "let" ? .let : word == "const" ? .const : .var
            } else {
                kind = .var
            }
            guard case .ident(let name) = peek.kind else { throw peekError("expected identifier") }
            _ = advance()
            if matchIdent("in") {
                let obj = try parseExpression()
                try expectPunct(")")
                return .forIn(kind, name, obj, try parseStatement())
            }
            i = saved
        } else if case .ident(let name) = peek.kind {
            let nameSaved = i
            _ = advance()
            if matchIdent("in") {
                let obj = try parseExpression()
                try expectPunct(")")
                return .forIn(nil, name, obj, try parseStatement())
            }
            i = nameSaved
        }
        _ = saved
        var initStmt: JSCStmt?
        if !matchPunct(";") {
            if matchIdent("var") {
                initStmt = try parseVar(.var)
            } else if matchIdent("let") {
                initStmt = try parseVar(.let)
            } else if matchIdent("const") {
                initStmt = try parseVar(.const)
            } else {
                initStmt = .expr(try parseExpression())
                try expectPunct(";")
            }
        }
        var test: JSCExpr?
        if !matchPunct(";") {
            test = try parseExpression()
            try expectPunct(";")
        }
        var update: JSCExpr?
        if !matchPunct(")") {
            update = try parseExpression()
            try expectPunct(")")
        }
        return .for(initStmt, test, update, try parseStatement())
    }

    private func parseTry() throws -> JSCStmt {
        try expectPunct("{")
        let tryBody = JSCStmt.block(try parseBlock())
        var catchName: String?
        var catchBody: JSCStmt?
        var finallyBody: JSCStmt?
        if matchIdent("catch") {
            if matchPunct("(") {
                guard case .ident(let name) = peek.kind else { throw peekError("expected identifier") }
                _ = advance()
                catchName = name
                try expectPunct(")")
            }
            try expectPunct("{")
            catchBody = .block(try parseBlock())
        }
        if matchIdent("finally") {
            try expectPunct("{")
            finallyBody = .block(try parseBlock())
        }
        if catchBody == nil && finallyBody == nil {
            throw peekError("try requires catch or finally")
        }
        return .tryCatch(tryBody, catchName, catchBody, finallyBody)
    }

    private func parseSwitch() throws -> JSCStmt {
        try expectPunct("(")
        let test = try parseExpression()
        try expectPunct(")")
        try expectPunct("{")
        var cases: [(JSCExpr?, [JSCStmt])] = []
        while !matchPunct("}") {
            if matchIdent("case") {
                let value = try parseExpression()
                try expectPunct(":")
                cases.append((value, try parseSwitchBody()))
            } else if matchIdent("default") {
                try expectPunct(":")
                cases.append((nil, try parseSwitchBody()))
            } else {
                throw peekError("expected case or default")
            }
        }
        return .switchStmt(test, cases)
    }

    private func parseSwitchBody() throws -> [JSCStmt] {
        var body: [JSCStmt] = []
        while true {
            if case .punct("}") = peek.kind { break }
            if case .ident("case") = peek.kind { break }
            if case .ident("default") = peek.kind { break }
            body.append(try parseStatement())
        }
        return body
    }

    private func optionalExprAfterKeyword() throws -> JSCExpr? {
        if peek.newlineBefore || matchPunct(";") { return nil }
        if case .punct("}") = peek.kind { return nil }
        if atEOF { return nil }
        let expr = try parseExpression()
        eatSemicolon()
        return expr
    }

    private func eatSemicolon() {
        if matchPunct(";") { return }
        if peek.newlineBefore { return }
        if case .punct("}") = peek.kind { return }
        if atEOF { return }
    }

    func parseExpression() throws -> JSCExpr {
        var parts = [try parseExpressionNoComma()]
        while matchPunct(",") {
            parts.append(try parseExpressionNoComma())
        }
        if parts.count == 1 { return parts[0] }
        return .comma(parts)
    }

    private func parseExpressionNoComma() throws -> JSCExpr {
        try parseAssign()
    }

    private func parseAssign() throws -> JSCExpr {
        let left = try parseCond()
        let ops = ["=", "+=", "-=", "*=", "/=", "%=", "&=", "|=", "^=", "**="]
        if case .punct(let op) = peek.kind, ops.contains(op) {
            _ = advance()
            return .assign(op, left, try parseAssign())
        }
        return left
    }

    private func parseCond() throws -> JSCExpr {
        let test = try parseBinary(0)
        if matchPunct("?") {
            let cons = try parseAssign()
            try expectPunct(":")
            return .cond(test, cons, try parseAssign())
        }
        return test
    }

    private static let binaryOps: [[String]] = [
        ["||", "??"],
        ["&&"],
        ["|"],
        ["^"],
        ["&"],
        ["===", "!==", "==", "!="],
        ["<", ">", "<=", ">=", "instanceof", "in"],
        ["<<", ">>", ">>>"],
        ["+", "-"],
        ["*", "/", "%"],
        ["**"]
    ]

    private func parseBinary(_ level: Int) throws -> JSCExpr {
        if level >= JSCParser.binaryOps.count {
            return try parseUnary()
        }
        var left = try parseBinary(level + 1)
        while true {
            let ops = JSCParser.binaryOps[level]
            if case .ident("instanceof") = peek.kind, ops.contains("instanceof") {
                _ = advance()
                left = .binary("instanceof", left, try parseBinary(level + 1))
                continue
            }
            if case .ident("in") = peek.kind, ops.contains("in") {
                _ = advance()
                left = .binary("in", left, try parseBinary(level + 1))
                continue
            }
            if case .punct(let op) = peek.kind, ops.contains(op) {
                _ = advance()
                left = .binary(op, left, try parseBinary(level + 1))
                continue
            }
            break
        }
        return left
    }

    private func parseUnary() throws -> JSCExpr {
        if case .punct(let op) = peek.kind, ["+", "-", "!", "~", "++", "--"].contains(op) {
            _ = advance()
            return .unary(op, try parseUnary(), prefix: true)
        }
        if case .ident(let word) = peek.kind, ["typeof", "void", "delete"].contains(word) {
            _ = advance()
            return .unary(word, try parseUnary(), prefix: true)
        }
        var expr = try parsePostfix()
        if case .punct(let op) = peek.kind, (op == "++" || op == "--"), !peek.newlineBefore {
            _ = advance()
            expr = .unary(op, expr, prefix: false)
        }
        return expr
    }

    private func parsePostfix() throws -> JSCExpr {
        var expr = try parsePrimary()
        while true {
            if matchPunct(".") {
                guard case .ident(let name) = peek.kind else { throw peekError("expected property name") }
                _ = advance()
                expr = .member(expr, name)
                continue
            }
            if matchPunct("[") {
                let index = try parseExpression()
                try expectPunct("]")
                expr = .index(expr, index)
                continue
            }
            if matchPunct("(") {
                expr = .call(expr, try parseArgList())
                continue
            }
            break
        }
        return expr
    }

    private func parseArgList() throws -> [JSCExpr] {
        var args: [JSCExpr] = []
        if !matchPunct(")") {
            repeat {
                args.append(try parseExpressionNoComma())
            } while matchPunct(",")
            try expectPunct(")")
        }
        return args
    }

    private func parsePrimary() throws -> JSCExpr {
        if matchIdent("true") { return .boolean(true) }
        if matchIdent("false") { return .boolean(false) }
        if matchIdent("null") { return .null }
        if matchIdent("undefined") { return .undefined }
        if matchIdent("this") { return .this }
        if matchIdent("function") {
            var name: String?
            if case .ident(let ident) = peek.kind {
                name = ident
                _ = advance()
            }
            let params = try parseParamList()
            try expectPunct("{")
            return .function(name, params, .block(try parseBlock()))
        }
        if matchIdent("new") {
            let callee = try parseNewCallee()
            var args: [JSCExpr] = []
            if matchPunct("(") {
                args = try parseArgList()
            }
            return .new(callee, args)
        }
        switch peek.kind {
        case .ident(let name):
            _ = advance()
            return .ident(name)
        case .number(let value):
            _ = advance()
            return .number(value)
        case .bigint(let value):
            _ = advance()
            return .bigint(value)
        case .string(let value):
            _ = advance()
            return .string(value)
        case .punct("["):
            _ = advance()
            var items: [JSCExpr] = []
            if !matchPunct("]") {
                repeat {
                    if case .punct("]") = peek.kind { break }
                    if case .punct(",") = peek.kind {
                        items.append(.undefined)
                        continue
                    }
                    items.append(try parseExpressionNoComma())
                } while matchPunct(",")
                try expectPunct("]")
            }
            return .array(items)
        case .punct("{"):
            return try parseObjectLiteral()
        case .punct("("):
            _ = advance()
            // arrow function (x) => or grouping
            let saved = i
            if case .ident = peek.kind {
                let identTok = advance()
                if matchPunct(")"), matchPunct("=>") {
                    let body = try parseArrowBody()
                    if case .ident(let name) = identTok.kind {
                        return .function(nil, [name], body)
                    }
                }
                i = saved
            } else if matchPunct(")"), matchPunct("=>") {
                return .function(nil, [], try parseArrowBody())
            }
            let expr = try parseExpression()
            try expectPunct(")")
            return expr
        default:
            if case .ident(let name) = peek.kind {
                _ = advance()
                if matchPunct("=>") {
                    return .function(nil, [name], try parseArrowBody())
                }
            }
            throw peekError("unexpected token")
        }
    }

    private func parseNewCallee() throws -> JSCExpr {
        var expr = try parsePrimaryExceptNew()
        while true {
            if matchPunct(".") {
                guard case .ident(let name) = peek.kind else { throw peekError("expected property name") }
                _ = advance()
                expr = .member(expr, name)
                continue
            }
            if matchPunct("[") {
                let index = try parseExpression()
                try expectPunct("]")
                expr = .index(expr, index)
                continue
            }
            break
        }
        return expr
    }

    private func parsePrimaryExceptNew() throws -> JSCExpr {
        if matchIdent("new") {
            throw peekError("nested new in constructor callee is not implemented")
        }
        return try parsePrimary()
    }

    private func parseObjectLiteral() throws -> JSCExpr {
        _ = advance()
        var props: [(String, JSCExpr)] = []
        if !matchPunct("}") {
            repeat {
                if case .punct("}") = peek.kind { break }
                let name: String
                if case .ident(let ident) = peek.kind {
                    name = ident
                    _ = advance()
                } else if case .string(let str) = peek.kind {
                    name = str
                    _ = advance()
                } else if case .number(let num) = peek.kind {
                    name = String(num)
                    _ = advance()
                } else {
                    throw peekError("expected property name")
                }
                if matchPunct(":") {
                    props.append((name, try parseExpressionNoComma()))
                } else {
                    props.append((name, .ident(name)))
                }
            } while matchPunct(",")
            try expectPunct("}")
        }
        return .object(props)
    }

    private func parseArrowBody() throws -> JSCStmt {
        if matchPunct("{") {
            return .block(try parseBlock())
        }
        return .return(try parseExpressionNoComma())
    }
}

private extension JSCToken {
    func isIdent(_ value: String) -> Bool {
        if case .ident(value) = kind { return true }
        return false
    }
}
