import Foundation

public final class JSVirtualMachine: NSObject {
    var heap: [JSCBox] = []
    var strings: [JSCString] = []
    var classes: [JSCClass] = []
    var nameArrays: [JSCNameArray] = []
    var managed: [(object: Any, owner: Any)] = []
    var symbolCounter = 0
    let lock = NSLock()

    public override init() {
        super.init()
    }

    public func addManagedReference(_ object: Any!, withOwner owner: Any!) {
        guard let object, let owner else { return }
        lock.lock()
        managed.append((object, owner))
        lock.unlock()
    }

    public func removeManagedReference(_ object: Any!, withOwner owner: Any!) {
        lock.lock()
        if let index = managed.firstIndex(where: {
            ($0.object as AnyObject) === (object as AnyObject)
                && ($0.owner as AnyObject) === (owner as AnyObject)
        }) {
            managed.remove(at: index)
        }
        lock.unlock()
    }

    func intern(_ box: JSCBox) -> JSCBox {
        lock.lock()
        heap.append(box)
        lock.unlock()
        return box
    }

    func intern(_ string: JSCString) -> JSCString {
        lock.lock()
        strings.append(string)
        lock.unlock()
        return string
    }

    func intern(_ jsClass: JSCClass) -> JSCClass {
        lock.lock()
        classes.append(jsClass)
        lock.unlock()
        return jsClass
    }

    func intern(_ array: JSCNameArray) -> JSCNameArray {
        lock.lock()
        nameArrays.append(array)
        lock.unlock()
        return array
    }

    func nextSymbolId() -> Int {
        lock.lock()
        defer { lock.unlock() }
        symbolCounter += 1
        return symbolCounter
    }
}

public final class JSManagedValue: NSObject {
    private weak var stored: JSValue?

    public init!(value: JSValue!) {
        stored = value
        super.init()
    }

    public init!(value: JSValue!, andOwner owner: Any!) {
        stored = value
        super.init()
        if let vm = value?.context?.virtualMachine, let owner {
            vm.addManagedReference(self, withOwner: owner)
        }
    }

    public var value: JSValue! { stored }
}

public final class JSContext: NSObject {
    public private(set) var virtualMachine: JSVirtualMachine!
    public var exception: JSValue!
    public var exceptionHandler: ((JSContext?, JSValue?) -> Void)!
    public var name: String!
    public var isInspectable = false
    public private(set) var globalObject: JSValue!
    public var jsGlobalContextRef: JSGlobalContextRef! { JSCRef.unretained(self) }

    var globalBox: JSCBox
    var globalEnv: JSCEnvironment
    private var objectPrototype: JSCBox
    private var arrayPrototype: JSCBox
    private var functionPrototype: JSCBox

    public override init() {
        let vm = JSVirtualMachine()
        virtualMachine = vm
        let objectProto = JSCObject()
        objectProto.className = "Object"
        objectPrototype = vm.intern(JSCBox(.object(objectProto)))
        let arrayProto = JSCObject()
        arrayProto.className = "Array"
        arrayProto.prototype = objectPrototype
        arrayPrototype = vm.intern(JSCBox(.object(arrayProto)))
        let fnProto = JSCObject()
        fnProto.className = "Function"
        fnProto.prototype = objectPrototype
        functionPrototype = vm.intern(JSCBox(.object(fnProto)))
        let global = JSCObject()
        global.className = "Object"
        global.prototype = objectPrototype
        globalBox = vm.intern(JSCBox(.object(global)))
        globalEnv = JSCEnvironment(parent: nil, isFunction: true)
        super.init()
        name = "JavaScriptCore"
        exceptionHandler = { context, value in
            context?.exception = value
        }
        globalObject = JSValue(box: globalBox, in: self)
        installBuiltins()
    }

    public init!(virtualMachine: JSVirtualMachine!) {
        let vm = virtualMachine ?? JSVirtualMachine()
        self.virtualMachine = vm
        let objectProto = JSCObject()
        objectProto.className = "Object"
        objectPrototype = vm.intern(JSCBox(.object(objectProto)))
        let arrayProto = JSCObject()
        arrayProto.className = "Array"
        arrayProto.prototype = objectPrototype
        arrayPrototype = vm.intern(JSCBox(.object(arrayProto)))
        let fnProto = JSCObject()
        fnProto.className = "Function"
        fnProto.prototype = objectPrototype
        functionPrototype = vm.intern(JSCBox(.object(fnProto)))
        let global = JSCObject()
        global.className = "Object"
        global.prototype = objectPrototype
        globalBox = vm.intern(JSCBox(.object(global)))
        globalEnv = JSCEnvironment(parent: nil, isFunction: true)
        super.init()
        name = "JavaScriptCore"
        exceptionHandler = { context, value in
            context?.exception = value
        }
        globalObject = JSValue(box: globalBox, in: self)
        installBuiltins()
    }

    public init!(JSGlobalContextRef jsGlobalContextRef: JSGlobalContextRef!) {
        guard let existing = JSCRef.takeUnretained(jsGlobalContextRef, as: JSContext.self) else {
            self.virtualMachine = JSVirtualMachine()
            let objectProto = JSCObject()
            objectPrototype = JSCBox(.object(objectProto))
            arrayPrototype = objectPrototype
            functionPrototype = objectPrototype
            globalBox = JSCBox(.undefined)
            globalEnv = JSCEnvironment(parent: nil, isFunction: true)
            super.init()
            return
        }
        self.virtualMachine = existing.virtualMachine
        self.globalBox = existing.globalBox
        self.globalEnv = existing.globalEnv
        self.objectPrototype = existing.objectPrototype
        self.arrayPrototype = existing.arrayPrototype
        self.functionPrototype = existing.functionPrototype
        super.init()
        self.name = existing.name
        self.exception = existing.exception
        self.exceptionHandler = existing.exceptionHandler
        self.isInspectable = existing.isInspectable
        self.globalObject = existing.globalObject
    }

    public class func current() -> JSContext! { JSCThread.context }
    public class func currentThis() -> JSValue! { JSCThread.thisValue }
    public class func currentCallee() -> JSValue! { JSCThread.callee }
    public class func currentArguments() -> [Any]! { JSCThread.arguments }

    public func evaluateScript(_ script: String!) -> JSValue! {
        evaluateScript(script, withSourceURL: nil)
    }

    public func evaluateScript(_ script: String!, withSourceURL sourceURL: URL!) -> JSValue! {
        exception = nil
        let previous = JSCThread.context
        JSCThread.context = self
        defer { JSCThread.context = previous }
        do {
            let program = try JSCParser(source: script ?? "").parseProgram()
            let result = try exec(program, env: globalEnv, this: globalBox)
            return JSValue(box: result, in: self)
        } catch let jump as JSCJump {
            if case .thrown(let value) = jump {
                fail(value)
                return nil
            }
            if case .returnValue(let value) = jump {
                return JSValue(box: value, in: self)
            }
            fail(makeError("SyntaxError", "illegal break or continue"))
            return nil
        } catch let error as JSCParseError {
            fail(makeError("SyntaxError", error.message))
            return nil
        } catch let error as JSCEngineError {
            fail(makeError("Error", error.message))
            return nil
        } catch {
            fail(makeError("Error", String(describing: error)))
            return nil
        }
    }

    public func objectForKeyedSubscript(_ key: Any!) -> JSValue! {
        do {
            let value = try getProperty(globalBox, name: stringifyKey(key))
            return JSValue(box: value, in: self)
        } catch let jump as JSCJump {
            if case .thrown(let value) = jump { fail(value) }
            return JSValue(box: .undefined, in: self)
        } catch {
            return JSValue(box: .undefined, in: self)
        }
    }

    public func setObject(_ object: Any!, forKeyedSubscript key: (any NSCopying & NSObjectProtocol)!) {
        let box = box(fromSwift: object)
        do {
            try setProperty(globalBox, name: stringifyKey(key), value: box)
        } catch let jump as JSCJump {
            if case .thrown(let value) = jump { fail(value) }
        } catch {
            fail(makeError("Error", String(describing: error)))
        }
    }

    public subscript(key: String) -> JSValue! {
        get { objectForKeyedSubscript(key) }
        set { setObject(newValue, forKeyedSubscript: key as NSString) }
    }

    func intern(_ box: JSCBox) -> JSCBox {
        virtualMachine.intern(box)
    }

    func box(fromSwift value: Any?) -> JSCBox {
        guard let value else { return intern(JSCBox(.undefined)) }
        if let jsValue = value as? JSValue { return jsValue.box }
        if value is NSNull { return intern(JSCBox(.null)) }
        if let flag = value as? Bool { return intern(JSCBox(.boolean(flag))) }
        if let number = value as? NSNumber {
            let objCType = String(cString: number.objCType)
            if objCType == "c" || objCType == "B" {
                return intern(JSCBox(.boolean(number.boolValue)))
            }
            return intern(JSCBox(.number(number.doubleValue)))
        }
        if let number = value as? Double { return intern(JSCBox(.number(number))) }
        if let number = value as? Float { return intern(JSCBox(.number(Double(number)))) }
        if let number = value as? Int { return intern(JSCBox(.number(Double(number)))) }
        if let number = value as? Int32 { return intern(JSCBox(.number(Double(number)))) }
        if let number = value as? Int64 { return intern(JSCBox(.number(Double(number)))) }
        if let number = value as? UInt32 { return intern(JSCBox(.number(Double(number)))) }
        if let number = value as? UInt64 { return intern(JSCBox(.number(Double(number)))) }
        if let string = value as? String { return intern(JSCBox(.string(string))) }
        if let string = value as? NSString { return intern(JSCBox(.string(string as String))) }
        if let date = value as? Date { return intern(makeDate(date)) }
        if let array = value as? [Any] {
            return intern(makeArray(array.map { box(fromSwift: $0) }))
        }
        if let dict = value as? [String: Any] {
            let object = makeObject()
            for (key, item) in dict {
                object.object?.setOwn(key, box(fromSwift: item))
            }
            return intern(object)
        }
        if let dict = value as? [AnyHashable: Any] {
            let object = makeObject()
            for (key, item) in dict {
                object.object?.setOwn(String(describing: key), box(fromSwift: item))
            }
            return intern(object)
        }
        let host = makeObject()
        host.object?.hostObject = value
        host.object?.className = "HostObject"
        return intern(host)
    }

    func stringifyKey(_ key: Any?) -> String {
        if let string = key as? String { return string }
        if let string = key as? NSString { return string as String }
        if let value = key as? JSValue { return value.box.stringValue() }
        if let key { return String(describing: key) }
        return "undefined"
    }

    func makeObject() -> JSCBox {
        let object = JSCObject()
        object.prototype = objectPrototype
        object.className = "Object"
        return intern(JSCBox(.object(object)))
    }

    func makeArray(_ items: [JSCBox] = []) -> JSCBox {
        let object = JSCObject()
        object.isArray = true
        object.prototype = arrayPrototype
        object.className = "Array"
        for (index, item) in items.enumerated() {
            object.setOwn(String(index), item)
        }
        object.setOwn("length", intern(JSCBox(.number(Double(items.count)))))
        return intern(JSCBox(.object(object)))
    }

    func makeDate(_ date: Date) -> JSCBox {
        let object = JSCObject()
        object.isDate = true
        object.dateValue = date
        object.prototype = objectPrototype
        object.className = "Date"
        return intern(JSCBox(.object(object)))
    }

    func makeError(_ name: String, _ message: String) -> JSCBox {
        let object = makeObject()
        object.object?.isError = true
        object.object?.className = name
        object.object?.setOwn("name", intern(JSCBox(.string(name))))
        object.object?.setOwn("message", intern(JSCBox(.string(message))))
        return object
    }

    func makeFunction(name: String?, params: [String], body: JSCStmt, env: JSCEnvironment) -> JSCBox {
        let object = JSCObject()
        object.prototype = functionPrototype
        object.className = "Function"
        object.function = .script(params: params, body: body, name: name, environment: env)
        object.isConstructor = true
        let box = intern(JSCBox(.object(object)))
        object.setOwn("length", intern(JSCBox(.number(Double(params.count)))))
        object.setOwn("name", intern(JSCBox(.string(name ?? ""))))
        let proto = makeObject()
        proto.object?.setOwn("constructor", box)
        object.setOwn("prototype", proto)
        return box
    }

    func makeNativeFunction(name: String, ctor: Bool = false, _ body: @escaping (JSCCall) throws -> JSCBox) -> JSCBox {
        let object = JSCObject()
        object.prototype = functionPrototype
        object.className = "Function"
        object.function = .native(body)
        object.isConstructor = ctor
        object.setOwn("name", intern(JSCBox(.string(name))))
        return intern(JSCBox(.object(object)))
    }

    func fail(_ box: JSCBox) {
        let value = JSValue(box: box, in: self)
        exceptionHandler?(self, value)
        if exception == nil { exception = value }
    }

    func getProperty(_ target: JSCBox, name: String) throws -> JSCBox {
        if name == "__proto__" { return target.object?.prototype ?? .undefined }
        var current: JSCBox? = target
        while let box = current {
            if let object = box.object {
                if let own = object.getOwn(name) { return own }
                if let jsClass = object.jsClass, let callback = jsClass.definition.getProperty {
                    var exception: JSValueRef?
                    let ref = callback(
                        JSCRef.unretained(self),
                        JSCRef.unretained(box),
                        JSCRef.unretained(virtualMachine.intern(JSCString(name))),
                        &exception
                    )
                    if let exception, let thrown = JSCRef.takeUnretained(exception, as: JSCBox.self) {
                        throw JSCJump.thrown(thrown)
                    }
                    if let ref, let value = JSCRef.takeUnretained(ref, as: JSCBox.self) {
                        return value
                    }
                }
                current = object.prototype
            } else {
                break
            }
        }
        return .undefined
    }

    func setProperty(_ target: JSCBox, name: String, value: JSCBox, attributes: JSPropertyAttributes = 0) throws {
        if name == "__proto__" {
            target.object?.prototype = value
            return
        }
        guard let object = target.object else {
            throw JSCJump.thrown(makeError("TypeError", "cannot set property of non-object"))
        }
        let flags = object.attrs[name] ?? 0
        if flags & JSPropertyAttributes(kJSPropertyAttributeReadOnly) != 0 {
            throw JSCJump.thrown(makeError("TypeError", "property is read-only"))
        }
        object.setOwn(name, value, attributes: attributes == 0 ? nil : attributes)
        if object.isArray, name != "length", let index = Int(name), index >= object.getOwn("length").map({ Int($0.numberValue()) }) ?? 0 {
            object.setOwn("length", intern(JSCBox(.number(Double(index + 1)))))
        }
    }

    func exec(_ stmt: JSCStmt, env: JSCEnvironment, this: JSCBox) throws -> JSCBox {
        switch stmt {
        case .empty:
            return .undefined
        case .block(let body):
            let child = JSCEnvironment(parent: env)
            var result: JSCBox = .undefined
            for item in body {
                result = try exec(item, env: child, this: this)
            }
            return result
        case .expr(let expr):
            return try eval(expr, env: env, this: this)
        case .varDecl(let kind, let decls):
            for (name, initExpr) in decls {
                let value = try initExpr.map { try eval($0, env: env, this: this) } ?? .undefined
                env.declare(name, kind: kind, value: value)
                if env.parent == nil || env === globalEnv {
                    try setProperty(globalBox, name: name, value: value)
                }
            }
            return .undefined
        case .function(let name, let params, let body):
            let fn = makeFunction(name: name, params: params, body: body, env: env)
            env.declare(name, kind: .var, value: fn)
            try setProperty(globalBox, name: name, value: fn)
            return .undefined
        case .return(let expr):
            throw JSCJump.returnValue(try expr.map { try eval($0, env: env, this: this) } ?? .undefined)
        case .throw(let expr):
            throw JSCJump.thrown(try eval(expr, env: env, this: this))
        case .if(let test, let thenStmt, let elseStmt):
            if try eval(test, env: env, this: this).booleanValue() {
                return try exec(thenStmt, env: env, this: this)
            }
            if let elseStmt { return try exec(elseStmt, env: env, this: this) }
            return .undefined
        case .while(let test, let body):
            var result: JSCBox = .undefined
            while try eval(test, env: env, this: this).booleanValue() {
                do {
                    result = try exec(body, env: env, this: this)
                } catch JSCJump.continueLoop {
                    continue
                } catch JSCJump.breakLoop {
                    break
                }
            }
            return result
        case .doWhile(let body, let test):
            var result: JSCBox = .undefined
            repeat {
                do {
                    result = try exec(body, env: env, this: this)
                } catch JSCJump.continueLoop {
                    continue
                } catch JSCJump.breakLoop {
                    break
                }
            } while try eval(test, env: env, this: this).booleanValue()
            return result
        case .for(let initStmt, let test, let update, let body):
            if let initStmt { _ = try exec(initStmt, env: env, this: this) }
            var result: JSCBox = .undefined
            while true {
                if let test, try !eval(test, env: env, this: this).booleanValue() { break }
                do {
                    result = try exec(body, env: env, this: this)
                } catch JSCJump.continueLoop {
                    if let update { _ = try eval(update, env: env, this: this) }
                    continue
                } catch JSCJump.breakLoop {
                    break
                }
                if let update { _ = try eval(update, env: env, this: this) }
            }
            return result
        case .forIn(let kind, let name, let objectExpr, let body):
            let object = try eval(objectExpr, env: env, this: this)
            var result: JSCBox = .undefined
            for key in object.object?.enumerableNames() ?? [] {
                let value = intern(JSCBox(.string(key)))
                if let kind {
                    env.declare(name, kind: kind, value: value)
                } else if !env.set(name, value) {
                    env.declare(name, kind: .var, value: value)
                    try setProperty(globalBox, name: name, value: value)
                }
                do {
                    result = try exec(body, env: env, this: this)
                } catch JSCJump.continueLoop {
                    continue
                } catch JSCJump.breakLoop {
                    break
                }
            }
            return result
        case .break:
            throw JSCJump.breakLoop
        case .continue:
            throw JSCJump.continueLoop
        case .tryCatch(let tryBody, let catchName, let catchBody, let finallyBody):
            var result: JSCBox = .undefined
            var pending: Error?
            do {
                result = try exec(tryBody, env: env, this: this)
            } catch let jump as JSCJump {
                if case .thrown(let value) = jump, let catchBody {
                    let child = JSCEnvironment(parent: env)
                    if let catchName { child.declare(catchName, kind: .let, value: value) }
                    result = try exec(catchBody, env: child, this: this)
                } else {
                    pending = jump
                }
            } catch {
                pending = error
            }
            if let finallyBody {
                _ = try exec(finallyBody, env: env, this: this)
            }
            if let pending { throw pending }
            return result
        case .switchStmt(let testExpr, let cases):
            let test = try eval(testExpr, env: env, this: this)
            var matched = false
            var result: JSCBox = .undefined
            var defaultIndex: Int?
            for (index, entry) in cases.enumerated() {
                if entry.0 == nil { defaultIndex = index }
                if let expr = entry.0, try strictEqual(test, eval(expr, env: env, this: this)) {
                    matched = true
                    do {
                        for stmt in entry.1 { result = try exec(stmt, env: env, this: this) }
                        for later in cases[(index + 1)...] {
                            for stmt in later.1 { result = try exec(stmt, env: env, this: this) }
                        }
                    } catch JSCJump.breakLoop {
                        return result
                    }
                    break
                }
            }
            if !matched, let defaultIndex {
                do {
                    for later in cases[defaultIndex...] {
                        for stmt in later.1 { result = try exec(stmt, env: env, this: this) }
                    }
                } catch JSCJump.breakLoop {
                    return result
                }
            }
            return result
        }
    }

    func eval(_ expr: JSCExpr, env: JSCEnvironment, this: JSCBox) throws -> JSCBox {
        switch expr {
        case .ident(let name):
            if name == "undefined" { return .undefined }
            if name == "NaN" { return intern(JSCBox(.number(.nan))) }
            if name == "Infinity" { return intern(JSCBox(.number(.infinity))) }
            if let value = env.get(name) { return value }
            let global = try getProperty(globalBox, name: name)
            if global.isUndefined && env.get(name) == nil && globalBox.object?.hasOwn(name) != true {
                throw JSCJump.thrown(makeError("ReferenceError", "\(name) is not defined"))
            }
            return global
        case .number(let value):
            return intern(JSCBox(.number(value)))
        case .bigint(let digits):
            let parsed = JSCBigInt.fromDecimal(digits) ?? (1, "0")
            return intern(JSCBox(.bigInt(sign: parsed.0, digits: parsed.1)))
        case .string(let value):
            return intern(JSCBox(.string(value)))
        case .boolean(let value):
            return intern(JSCBox(.boolean(value)))
        case .null:
            return intern(JSCBox(.null))
        case .undefined:
            return .undefined
        case .this:
            return this
        case .array(let items):
            return makeArray(try items.map { try eval($0, env: env, this: this) })
        case .object(let props):
            let object = makeObject()
            for (name, value) in props {
                try setProperty(object, name: name, value: try eval(value, env: env, this: this))
            }
            return object
        case .unary(let op, let valueExpr, let prefix):
            return try evalUnary(op, valueExpr, prefix: prefix, env: env, this: this)
        case .binary(let op, let leftExpr, let rightExpr):
            return try evalBinary(op, leftExpr, rightExpr, env: env, this: this)
        case .assign(let op, let leftExpr, let rightExpr):
            return try evalAssign(op, leftExpr, rightExpr, env: env, this: this)
        case .cond(let test, let cons, let alt):
            if try eval(test, env: env, this: this).booleanValue() {
                return try eval(cons, env: env, this: this)
            }
            return try eval(alt, env: env, this: this)
        case .call(let calleeExpr, let args):
            return try evalCall(calleeExpr, args, env: env, this: this, construct: false)
        case .new(let calleeExpr, let args):
            return try evalCall(calleeExpr, args, env: env, this: this, construct: true)
        case .member(let objectExpr, let name):
            return try getProperty(eval(objectExpr, env: env, this: this), name: name)
        case .index(let objectExpr, let indexExpr):
            let object = try eval(objectExpr, env: env, this: this)
            let name = try eval(indexExpr, env: env, this: this).stringValue()
            return try getProperty(object, name: name)
        case .function(let name, let params, let body):
            return makeFunction(name: name, params: params, body: body, env: env)
        case .comma(let parts):
            var result: JSCBox = .undefined
            for part in parts { result = try eval(part, env: env, this: this) }
            return result
        }
    }

    private func evalUnary(_ op: String, _ expr: JSCExpr, prefix: Bool, env: JSCEnvironment, this: JSCBox) throws -> JSCBox {
        if op == "++" || op == "--" {
            let current = try lvalue(expr, env: env, this: this)
            let next = intern(JSCBox(.number(current.get.numberValue() + (op == "++" ? 1 : -1))))
            try current.set(next)
            return prefix ? next : current.get
        }
        let value = try eval(expr, env: env, this: this)
        switch op {
        case "+": return intern(JSCBox(.number(value.numberValue())))
        case "-": return intern(JSCBox(.number(-value.numberValue())))
        case "!": return intern(JSCBox(.boolean(!value.booleanValue())))
        case "~": return intern(JSCBox(.number(Double(~Int32(truncatingIfNeeded: Int64(value.numberValue()))))) )
        case "typeof": return intern(JSCBox(.string(value.typeofText())))
        case "void": return .undefined
        case "delete":
            if case .member(let objectExpr, let name) = expr {
                let object = try eval(objectExpr, env: env, this: this)
                return intern(JSCBox(.boolean(object.object?.deleteOwn(name) ?? true)))
            }
            if case .index(let objectExpr, let indexExpr) = expr {
                let object = try eval(objectExpr, env: env, this: this)
                let name = try eval(indexExpr, env: env, this: this).stringValue()
                return intern(JSCBox(.boolean(object.object?.deleteOwn(name) ?? true)))
            }
            return intern(JSCBox(.boolean(true)))
        default:
            throw JSCJump.thrown(makeError("SyntaxError", "unsupported unary operator"))
        }
    }

    private func evalBinary(_ op: String, _ leftExpr: JSCExpr, _ rightExpr: JSCExpr, env: JSCEnvironment, this: JSCBox) throws -> JSCBox {
        if op == "&&" {
            let left = try eval(leftExpr, env: env, this: this)
            return left.booleanValue() ? try eval(rightExpr, env: env, this: this) : left
        }
        if op == "||" {
            let left = try eval(leftExpr, env: env, this: this)
            return left.booleanValue() ? left : try eval(rightExpr, env: env, this: this)
        }
        if op == "??" {
            let left = try eval(leftExpr, env: env, this: this)
            return left.isNull || left.isUndefined ? try eval(rightExpr, env: env, this: this) : left
        }
        let left = try eval(leftExpr, env: env, this: this)
        let right = try eval(rightExpr, env: env, this: this)
        switch op {
        case "+":
            if left.isString || right.isString {
                return intern(JSCBox(.string(left.stringValue() + right.stringValue())))
            }
            return intern(JSCBox(.number(left.numberValue() + right.numberValue())))
        case "-": return intern(JSCBox(.number(left.numberValue() - right.numberValue())))
        case "*": return intern(JSCBox(.number(left.numberValue() * right.numberValue())))
        case "/": return intern(JSCBox(.number(left.numberValue() / right.numberValue())))
        case "%": return intern(JSCBox(.number(left.numberValue().truncatingRemainder(dividingBy: right.numberValue()))))
        case "**": return intern(JSCBox(.number(pow(left.numberValue(), right.numberValue()))))
        case "|": return intern(JSCBox(.number(Double(int32(left) | int32(right)))))
        case "&": return intern(JSCBox(.number(Double(int32(left) & int32(right)))))
        case "^": return intern(JSCBox(.number(Double(int32(left) ^ int32(right)))))
        case "<<": return intern(JSCBox(.number(Double(int32(left) << (int32(right) & 31)))))
        case ">>": return intern(JSCBox(.number(Double(int32(left) >> (int32(right) & 31)))))
        case ">>>":
            let value = UInt32(bitPattern: int32(left)) >> UInt32(bitPattern: int32(right) & 31)
            return intern(JSCBox(.number(Double(value))))
        case "===": return intern(JSCBox(.boolean(strictEqual(left, right))))
        case "!==": return intern(JSCBox(.boolean(!strictEqual(left, right))))
        case "==": return intern(JSCBox(.boolean(looseEqual(left, right))))
        case "!=": return intern(JSCBox(.boolean(!looseEqual(left, right))))
        case "<": return intern(JSCBox(.boolean(compare(left, right) == .lessThan)))
        case ">": return intern(JSCBox(.boolean(compare(left, right) == .greaterThan)))
        case "<=":
            let rel = compare(left, right)
            return intern(JSCBox(.boolean(rel == .lessThan || rel == .equal)))
        case ">=":
            let rel = compare(left, right)
            return intern(JSCBox(.boolean(rel == .greaterThan || rel == .equal)))
        case "in":
            let found = try getProperty(right, name: left.stringValue())
            let hasOwn = right.object?.hasOwn(left.stringValue()) ?? false
            return intern(JSCBox(.boolean(!found.isUndefined || hasOwn)))
        case "instanceof":
            return intern(JSCBox(.boolean(try instanceOf(left, right))))
        default:
            throw JSCJump.thrown(makeError("SyntaxError", "unsupported operator \(op)"))
        }
    }

    private func evalAssign(_ op: String, _ leftExpr: JSCExpr, _ rightExpr: JSCExpr, env: JSCEnvironment, this: JSCBox) throws -> JSCBox {
        let right = try eval(rightExpr, env: env, this: this)
        let slot = try lvalue(leftExpr, env: env, this: this)
        if op == "=" {
            try slot.set(right)
            return right
        }
        let binaryOp = String(op.dropLast())
        let combined = try evalBinary(binaryOp, .ident("__lhs"), .ident("__rhs"), env: {
            let child = JSCEnvironment(parent: env)
            child.declare("__lhs", kind: .let, value: slot.get)
            child.declare("__rhs", kind: .let, value: right)
            return child
        }(), this: this)
        try slot.set(combined)
        return combined
    }

    private struct LValue {
        var get: JSCBox
        var set: (JSCBox) throws -> Void
    }

    private func lvalue(_ expr: JSCExpr, env: JSCEnvironment, this: JSCBox) throws -> LValue {
        switch expr {
        case .ident(let name):
            let current = try env.get(name) ?? getProperty(globalBox, name: name)
            return LValue(get: current) { value in
                if !env.set(name, value) {
                    env.declare(name, kind: .var, value: value)
                }
                try self.setProperty(self.globalBox, name: name, value: value)
            }
        case .member(let objectExpr, let name):
            let object = try eval(objectExpr, env: env, this: this)
            return LValue(get: try getProperty(object, name: name)) { value in
                try self.setProperty(object, name: name, value: value)
            }
        case .index(let objectExpr, let indexExpr):
            let object = try eval(objectExpr, env: env, this: this)
            let name = try eval(indexExpr, env: env, this: this).stringValue()
            return LValue(get: try getProperty(object, name: name)) { value in
                try self.setProperty(object, name: name, value: value)
            }
        default:
            throw JSCJump.thrown(makeError("ReferenceError", "invalid assignment target"))
        }
    }

    func evalCall(_ calleeExpr: JSCExpr, _ argExprs: [JSCExpr], env: JSCEnvironment, this: JSCBox, construct: Bool) throws -> JSCBox {
        var thisValue = globalBox
        let callee: JSCBox
        switch calleeExpr {
        case .member(let objectExpr, let name):
            thisValue = try eval(objectExpr, env: env, this: this)
            callee = try getProperty(thisValue, name: name)
        case .index(let objectExpr, let indexExpr):
            thisValue = try eval(objectExpr, env: env, this: this)
            callee = try getProperty(thisValue, name: try eval(indexExpr, env: env, this: this).stringValue())
        default:
            callee = try eval(calleeExpr, env: env, this: this)
        }
        let args = try argExprs.map { try eval($0, env: env, this: this) }
        return try call(callee, this: construct ? makeObject() : thisValue, args: args, construct: construct)
    }

    func call(_ callee: JSCBox, this: JSCBox, args: [JSCBox], construct: Bool) throws -> JSCBox {
        guard let object = callee.object else {
            throw JSCJump.thrown(makeError("TypeError", "value is not a function"))
        }
        if construct && !object.isConstructor {
            switch object.function {
            case .none:
                throw JSCJump.thrown(makeError("TypeError", "value is not a constructor"))
            default:
                break
            }
        }
        let constructed = construct ? this : this
        if construct, constructed.object?.prototype == nil {
            constructed.object?.prototype = try getProperty(callee, name: "prototype")
        }
        let previousContext = JSCThread.context
        let previousThis = JSCThread.thisValue
        let previousCallee = JSCThread.callee
        let previousArgs = JSCThread.arguments
        JSCThread.context = self
        JSCThread.thisValue = JSValue(box: constructed, in: self)
        JSCThread.callee = JSValue(box: callee, in: self)
        JSCThread.arguments = args.map { JSValue(box: $0, in: self) as Any }
        defer {
            JSCThread.context = previousContext
            JSCThread.thisValue = previousThis
            JSCThread.callee = previousCallee
            JSCThread.arguments = previousArgs
        }
        switch object.function {
        case .none:
            throw JSCJump.thrown(makeError("TypeError", "value is not a function"))
        case .script(let params, let body, _, let environment):
            let child = JSCEnvironment(parent: environment, isFunction: true)
            for (index, param) in params.enumerated() {
                child.declare(param, kind: .var, value: index < args.count ? args[index] : .undefined)
            }
            child.declare("arguments", kind: .var, value: makeArray(args))
            do {
                _ = try exec(body, env: child, this: constructed)
                return construct ? constructed : .undefined
            } catch let jump as JSCJump {
                if case .returnValue(let value) = jump {
                    if construct && !value.isObject { return constructed }
                    return value
                }
                throw jump
            }
        case .native(let body):
            let result = try body(JSCCall(vm: virtualMachine, context: self, this: constructed, args: args, callee: callee))
            return construct && !result.isObject ? constructed : result
        case .cFunction(let callback):
            return try invokeCFunction(callback, this: constructed, args: args, callee: callee)
        case .cConstructor(let callback):
            return try invokeCConstructor(callback, args: args, callee: callee)
        }
    }

    func invokeCFunction(
        _ callback: JSObjectCallAsFunctionCallback,
        this: JSCBox,
        args: [JSCBox],
        callee: JSCBox
    ) throws -> JSCBox {
        var refs = args.map { Optional(JSCRef.unretained($0)) }
        var exception: JSValueRef?
        let result = refs.withUnsafeMutableBufferPointer { buffer in
            callback(
                JSCRef.unretained(self),
                JSCRef.unretained(callee),
                JSCRef.unretained(this),
                args.count,
                buffer.baseAddress,
                &exception
            )
        }
        if let exception, let thrown = JSCRef.takeUnretained(exception, as: JSCBox.self) {
            throw JSCJump.thrown(thrown)
        }
        return JSCRef.takeUnretained(result, as: JSCBox.self) ?? .undefined
    }

    func invokeCConstructor(
        _ callback: JSObjectCallAsConstructorCallback,
        args: [JSCBox],
        callee: JSCBox
    ) throws -> JSCBox {
        var refs = args.map { Optional(JSCRef.unretained($0)) }
        var exception: JSValueRef?
        let result = refs.withUnsafeMutableBufferPointer { buffer in
            callback(
                JSCRef.unretained(self),
                JSCRef.unretained(callee),
                args.count,
                buffer.baseAddress,
                &exception
            )
        }
        if let exception, let thrown = JSCRef.takeUnretained(exception, as: JSCBox.self) {
            throw JSCJump.thrown(thrown)
        }
        return JSCRef.takeUnretained(result, as: JSCBox.self) ?? .undefined
    }

    func strictEqual(_ left: JSCBox, _ right: JSCBox) -> Bool {
        switch (left.payload, right.payload) {
        case (.undefined, .undefined), (.null, .null): return true
        case (.boolean(let a), .boolean(let b)): return a == b
        case (.number(let a), .number(let b)): return a == b
        case (.string(let a), .string(let b)): return a == b
        case (.symbol(let a, _), .symbol(let b, _)): return a == b
        case (.bigInt(let sa, let da), .bigInt(let sb, let db)): return sa == sb && da == db
        case (.object(let a), .object(let b)): return a === b
        default: return false
        }
    }

    func looseEqual(_ left: JSCBox, _ right: JSCBox) -> Bool {
        if strictEqual(left, right) { return true }
        if (left.isNull && right.isUndefined) || (left.isUndefined && right.isNull) { return true }
        if left.isNumber && right.isString { return left.numberValue() == right.numberValue() }
        if left.isString && right.isNumber { return left.numberValue() == right.numberValue() }
        if left.isBoolean { return looseEqual(intern(JSCBox(.number(left.numberValue()))), right) }
        if right.isBoolean { return looseEqual(left, intern(JSCBox(.number(right.numberValue())))) }
        return false
    }

    func compare(_ left: JSCBox, _ right: JSCBox) -> JSRelationCondition {
        if left.isBigInt || right.isBigInt {
            let l = bigintPair(left)
            let r = bigintPair(right)
            return JSCBigInt.compare(l, r)
        }
        let a = left.numberValue()
        let b = right.numberValue()
        if a.isNaN || b.isNaN { return .undefined }
        if a == b { return .equal }
        return a < b ? .lessThan : .greaterThan
    }

    func bigintPair(_ box: JSCBox) -> (Int, String) {
        switch box.payload {
        case .bigInt(let sign, let digits): return (sign, digits)
        case .number(let value): return JSCBigInt.fromDouble(value) ?? (1, "0")
        case .string(let text): return JSCBigInt.fromDecimal(text) ?? (1, "0")
        case .boolean(let value): return value ? (1, "1") : (1, "0")
        default: return (1, "0")
        }
    }

    func instanceOf(_ value: JSCBox, _ ctor: JSCBox) throws -> Bool {
        guard let proto = try getProperty(ctor, name: "prototype").object else { return false }
        var current = value.object?.prototype
        while let object = current?.object {
            if object === proto { return true }
            current = object.prototype
        }
        return false
    }

    func int32(_ box: JSCBox) -> Int32 {
        Int32(truncatingIfNeeded: Int64(box.numberValue()))
    }

    func checkSyntax(_ script: String) -> Bool {
        do {
            _ = try JSCParser(source: script).parseProgram()
            return true
        } catch {
            return false
        }
    }

    private func installBuiltins() {
        globalBox.object?.setOwn("undefined", .undefined)
        globalBox.object?.setOwn("NaN", intern(JSCBox(.number(.nan))))
        globalBox.object?.setOwn("Infinity", intern(JSCBox(.number(.infinity))))
        globalBox.object?.setOwn("globalThis", globalBox)
        installObject()
        installArray()
        installFunction()
        installJSON()
        installMath()
        installDate()
        installError()
        installRegExp()
        installPromise()
        installConsole()
        installTypedArrays()
        globalBox.object?.setOwn("parseInt", makeNativeFunction(name: "parseInt") { call in
            let text = call.args.first?.stringValue() ?? ""
            let radix = call.args.count > 1 ? Int(call.args[1].numberValue()) : 10
            let parsed = Int64(text.trimmingCharacters(in: .whitespaces), radix: max(radix, 0) == 0 ? 10 : radix)
            return self.intern(JSCBox(.number(parsed.map(Double.init) ?? .nan)))
        })
        globalBox.object?.setOwn("parseFloat", makeNativeFunction(name: "parseFloat") { call in
            let text = call.args.first?.stringValue() ?? ""
            return self.intern(JSCBox(.number(Double(text.trimmingCharacters(in: .whitespaces)) ?? .nan)))
        })
        globalBox.object?.setOwn("isNaN", makeNativeFunction(name: "isNaN") { call in
            self.intern(JSCBox(.boolean(call.args.first?.numberValue().isNaN ?? true)))
        })
        globalBox.object?.setOwn("isFinite", makeNativeFunction(name: "isFinite") { call in
            self.intern(JSCBox(.boolean(call.args.first?.numberValue().isFinite ?? false)))
        })
        globalBox.object?.setOwn("Number", makeNativeFunction(name: "Number", ctor: true) { call in
            let value = call.args.first?.numberValue() ?? 0
            if call.this.object?.className == "Number" || true {
                return self.intern(JSCBox(.number(value)))
            }
            return self.intern(JSCBox(.number(value)))
        })
        globalBox.object?.setOwn("String", makeNativeFunction(name: "String", ctor: true) { call in
            self.intern(JSCBox(.string(call.args.first?.stringValue() ?? "")))
        })
        globalBox.object?.setOwn("Boolean", makeNativeFunction(name: "Boolean", ctor: true) { call in
            self.intern(JSCBox(.boolean(call.args.first?.booleanValue() ?? false)))
        })
        globalBox.object?.setOwn("Symbol", makeNativeFunction(name: "Symbol") { call in
            let description = call.args.first?.stringValue() ?? ""
            return self.intern(JSCBox(.symbol(self.virtualMachine.nextSymbolId(), description)))
        })
        globalBox.object?.setOwn("BigInt", makeNativeFunction(name: "BigInt") { call in
            guard let arg = call.args.first else {
                throw JSCJump.thrown(self.makeError("TypeError", "BigInt requires an argument"))
            }
            if case .bigInt = arg.payload { return arg }
            if let parsed = JSCBigInt.fromDecimal(arg.stringValue()) {
                return self.intern(JSCBox(.bigInt(sign: parsed.0, digits: parsed.1)))
            }
            throw JSCJump.thrown(self.makeError("SyntaxError", "Cannot convert to BigInt"))
        })
        try? setProperty(globalBox, name: "Object", value: makeNativeFunction(name: "Object", ctor: true) { call in
            if let first = call.args.first, first.isObject { return first }
            if let first = call.args.first, !first.isNull && !first.isUndefined {
                let object = self.makeObject()
                object.object?.setOwn("valueOf", first)
                return object
            }
            return call.this.isObject ? call.this : self.makeObject()
        })
    }

    private func installObject() {
        let proto = objectPrototype
        proto.object?.setOwn("toString", makeNativeFunction(name: "toString") { call in
            self.intern(JSCBox(.string(call.this.stringValue())))
        })
        proto.object?.setOwn("valueOf", makeNativeFunction(name: "valueOf") { call in
            call.this
        })
        proto.object?.setOwn("hasOwnProperty", makeNativeFunction(name: "hasOwnProperty") { call in
            let name = call.args.first?.stringValue() ?? ""
            return self.intern(JSCBox(.boolean(call.this.object?.hasOwn(name) ?? false)))
        })
    }

    private func installArray() {
        let proto = arrayPrototype
        proto.object?.setOwn("push", makeNativeFunction(name: "push") { call in
            guard let object = call.this.object else { return .undefined }
            var length = Int(object.getOwn("length")?.numberValue() ?? 0)
            for arg in call.args {
                object.setOwn(String(length), arg)
                length += 1
            }
            let box = self.intern(JSCBox(.number(Double(length))))
            object.setOwn("length", box)
            return box
        })
        proto.object?.setOwn("pop", makeNativeFunction(name: "pop") { call in
            guard let object = call.this.object else { return .undefined }
            var length = Int(object.getOwn("length")?.numberValue() ?? 0)
            guard length > 0 else { return .undefined }
            length -= 1
            let value = object.getOwn(String(length)) ?? .undefined
            _ = object.deleteOwn(String(length))
            object.setOwn("length", self.intern(JSCBox(.number(Double(length)))))
            return value
        })
        proto.object?.setOwn("join", makeNativeFunction(name: "join") { call in
            let sep = call.args.first?.stringValue() ?? ","
            let length = call.this.arrayLength()
            let parts = (0..<length).map { call.this.object?.getOwn(String($0))?.stringValue() ?? "" }
            return self.intern(JSCBox(.string(parts.joined(separator: sep))))
        })
        proto.object?.setOwn("slice", makeNativeFunction(name: "slice") { call in
            let length = call.this.arrayLength()
            var start = Int(call.args.first?.numberValue() ?? 0)
            var end = call.args.count > 1 ? Int(call.args[1].numberValue()) : length
            if start < 0 { start = max(length + start, 0) }
            if end < 0 { end = max(length + end, 0) }
            start = min(start, length)
            end = min(end, length)
            let items = (start..<max(start, end)).map { call.this.object?.getOwn(String($0)) ?? .undefined }
            return self.makeArray(items)
        })
        proto.object?.setOwn("map", makeNativeFunction(name: "map") { call in
            guard let fn = call.args.first else { return self.makeArray() }
            let length = call.this.arrayLength()
            var items: [JSCBox] = []
            for index in 0..<length {
                let value = call.this.object?.getOwn(String(index)) ?? .undefined
                items.append(try self.call(fn, this: call.args.count > 1 ? call.args[1] : .undefined, args: [value, self.intern(JSCBox(.number(Double(index)))), call.this], construct: false))
            }
            return self.makeArray(items)
        })
        proto.object?.setOwn("filter", makeNativeFunction(name: "filter") { call in
            guard let fn = call.args.first else { return self.makeArray() }
            let length = call.this.arrayLength()
            var items: [JSCBox] = []
            for index in 0..<length {
                let value = call.this.object?.getOwn(String(index)) ?? .undefined
                let keep = try self.call(fn, this: .undefined, args: [value, self.intern(JSCBox(.number(Double(index))))], construct: false)
                if keep.booleanValue() { items.append(value) }
            }
            return self.makeArray(items)
        })
        proto.object?.setOwn("toString", makeNativeFunction(name: "toString") { call in
            self.intern(JSCBox(.string(call.this.stringValue())))
        })
        let arrayCtor = makeNativeFunction(name: "Array", ctor: true) { call in
            if call.args.count == 1, call.args[0].isNumber {
                let length = Int(call.args[0].numberValue())
                let array = self.makeArray()
                array.object?.setOwn("length", self.intern(JSCBox(.number(Double(length)))))
                return array
            }
            return self.makeArray(call.args)
        }
        arrayCtor.object?.setOwn("isArray", makeNativeFunction(name: "isArray") { call in
            self.intern(JSCBox(.boolean(call.args.first?.object?.isArray ?? false)))
        })
        arrayCtor.object?.setOwn("prototype", arrayPrototype)
        globalBox.object?.setOwn("Array", arrayCtor)
        arrayPrototype.object?.setOwn("constructor", arrayCtor)
    }

    private func installFunction() {
        functionPrototype.object?.setOwn("call", makeNativeFunction(name: "call") { call in
            let thisValue = call.args.first ?? .undefined
            let args = Array(call.args.dropFirst())
            return try self.call(call.this, this: thisValue, args: args, construct: false)
        })
        functionPrototype.object?.setOwn("apply", makeNativeFunction(name: "apply") { call in
            let thisValue = call.args.first ?? .undefined
            var args: [JSCBox] = []
            if call.args.count > 1, let object = call.args[1].object, object.isArray {
                for index in 0..<call.args[1].arrayLength() {
                    args.append(object.getOwn(String(index)) ?? .undefined)
                }
            }
            return try self.call(call.this, this: thisValue, args: args, construct: false)
        })
    }

    private func installJSON() {
        let json = makeObject()
        json.object?.className = "JSON"
        json.object?.setOwn("stringify", makeNativeFunction(name: "stringify") { call in
            guard let value = call.args.first else { return .undefined }
            let indent = call.args.count > 2 ? UInt32(call.args[2].numberValue()) : 0
            let text = try JSCJSON.stringify(value, indent: indent)
            return self.intern(JSCBox(.string(text)))
        })
        json.object?.setOwn("parse", makeNativeFunction(name: "parse") { call in
            let text = call.args.first?.stringValue() ?? ""
            let object = try JSCJSON.parse(text)
            return self.box(fromSwift: object)
        })
        globalBox.object?.setOwn("JSON", json)
    }

    private func installMath() {
        let math = makeObject()
        math.object?.className = "Math"
        func num(_ name: String, _ body: @escaping ([Double]) -> Double) -> Void {
            math.object?.setOwn(name, makeNativeFunction(name: name) { call in
                self.intern(JSCBox(.number(body(call.args.map { $0.numberValue() }))))
            })
        }
        num("abs") { abs($0.first ?? .nan) }
        num("floor") { Foundation.floor($0.first ?? .nan) }
        num("ceil") { Foundation.ceil($0.first ?? .nan) }
        num("round") { Foundation.round($0.first ?? .nan) }
        num("sqrt") { ($0.first ?? .nan).squareRoot() }
        num("pow") { pow($0.first ?? .nan, $0.count > 1 ? $0[1] : .nan) }
        num("max") { $0.max() ?? -.infinity }
        num("min") { $0.min() ?? .infinity }
        math.object?.setOwn("PI", intern(JSCBox(.number(Double.pi))))
        math.object?.setOwn("E", intern(JSCBox(.number(M_E))))
        math.object?.setOwn("random", makeNativeFunction(name: "random") { _ in
            self.intern(JSCBox(.number(Double.random(in: 0..<1))))
        })
        globalBox.object?.setOwn("Math", math)
    }

    private func installDate() {
        let ctor = makeNativeFunction(name: "Date", ctor: true) { call in
            let date: Date
            if call.args.isEmpty {
                date = Date()
            } else if let number = call.args.first, number.isNumber {
                date = Date(timeIntervalSince1970: number.numberValue() / 1000)
            } else if let text = call.args.first?.stringValue(), let parsed = ISO8601DateFormatter().date(from: text) {
                date = parsed
            } else {
                date = Date()
            }
            if call.this.object != nil {
                call.this.object?.isDate = true
                call.this.object?.dateValue = date
                call.this.object?.className = "Date"
                return call.this
            }
            return self.makeDate(date)
        }
        ctor.object?.setOwn("now", makeNativeFunction(name: "now") { _ in
            self.intern(JSCBox(.number(Date().timeIntervalSince1970 * 1000)))
        })
        objectPrototype.object?.setOwn("getTime", makeNativeFunction(name: "getTime") { call in
            guard let object = call.this.object, object.isDate else {
                throw JSCJump.thrown(self.makeError("TypeError", "not a Date"))
            }
            return self.intern(JSCBox(.number(object.dateValue.timeIntervalSince1970 * 1000)))
        })
        globalBox.object?.setOwn("Date", ctor)
    }

    private func installError() {
        func errorCtor(_ name: String) -> JSCBox {
            makeNativeFunction(name: name, ctor: true) { call in
                let message = call.args.first?.stringValue() ?? ""
                let object = call.this.isObject ? call.this : self.makeObject()
                object.object?.isError = true
                object.object?.className = name
                object.object?.setOwn("name", self.intern(JSCBox(.string(name))))
                object.object?.setOwn("message", self.intern(JSCBox(.string(message))))
                return object
            }
        }
        globalBox.object?.setOwn("Error", errorCtor("Error"))
        globalBox.object?.setOwn("TypeError", errorCtor("TypeError"))
        globalBox.object?.setOwn("SyntaxError", errorCtor("SyntaxError"))
        globalBox.object?.setOwn("RangeError", errorCtor("RangeError"))
        globalBox.object?.setOwn("ReferenceError", errorCtor("ReferenceError"))
    }

    private func installRegExp() {
        let ctor = makeNativeFunction(name: "RegExp", ctor: true) { call in
            let pattern = call.args.first?.stringValue() ?? ""
            let flags = call.args.count > 1 ? call.args[1].stringValue() : ""
            let object = call.this.isObject ? call.this : self.makeObject()
            try self.applyRegExp(object, pattern: pattern, flags: flags)
            return object
        }
        arrayPrototype.object?.setOwn("test", makeNativeFunction(name: "test") { call in
            guard let object = call.this.object, object.isRegExp, let regexp = object.regexp else {
                return self.intern(JSCBox(.boolean(false)))
            }
            let text = call.args.first?.stringValue() ?? ""
            return self.intern(JSCBox(.boolean(regexp.firstMatch(in: text, range: NSRange(location: 0, length: (text as NSString).length)) != nil)))
        })
        globalBox.object?.setOwn("RegExp", ctor)
    }

    func applyRegExp(_ box: JSCBox, pattern: String, flags: String) throws {
        var options: NSRegularExpression.Options = []
        if flags.contains("i") { options.insert(.caseInsensitive) }
        if flags.contains("m") { options.insert(.anchorsMatchLines) }
        if flags.contains("s") { options.insert(.dotMatchesLineSeparators) }
        do {
            let regexp = try NSRegularExpression(pattern: pattern, options: options)
            box.object?.isRegExp = true
            box.object?.regexp = regexp
            box.object?.regexpSource = pattern
            box.object?.regexpFlags = flags
            box.object?.className = "RegExp"
        } catch {
            throw JSCJump.thrown(makeError("SyntaxError", "invalid regular expression"))
        }
    }

    private func installPromise() {
        let ctor = makeNativeFunction(name: "Promise", ctor: true) { call in
            let promise = call.this.isObject ? call.this : self.makeObject()
            promise.object?.isPromise = true
            promise.object?.className = "Promise"
            let resolve = self.makeNativeFunction(name: "resolve") { inner in
                self.settle(promise, state: 1, value: inner.args.first ?? .undefined)
                return .undefined
            }
            let reject = self.makeNativeFunction(name: "reject") { inner in
                self.settle(promise, state: 2, value: inner.args.first ?? .undefined)
                return .undefined
            }
            if let executor = call.args.first {
                _ = try self.call(executor, this: .undefined, args: [resolve, reject], construct: false)
            }
            return promise
        }
        ctor.object?.setOwn("resolve", makeNativeFunction(name: "resolve") { call in
            let promise = self.makeObject()
            promise.object?.isPromise = true
            promise.object?.className = "Promise"
            self.settle(promise, state: 1, value: call.args.first ?? .undefined)
            return promise
        })
        ctor.object?.setOwn("reject", makeNativeFunction(name: "reject") { call in
            let promise = self.makeObject()
            promise.object?.isPromise = true
            promise.object?.className = "Promise"
            self.settle(promise, state: 2, value: call.args.first ?? .undefined)
            return promise
        })
        objectPrototype.object?.setOwn("then", makeNativeFunction(name: "then") { call in
            guard call.this.object?.isPromise == true else { return call.this }
            let successor = self.makeObject()
            successor.object?.isPromise = true
            successor.object?.className = "Promise"
            call.this.object?.thenQueue.append((call.args.first, call.args.count > 1 ? call.args[1] : nil, successor))
            if call.this.object?.promiseState != 0 {
                self.flushPromise(call.this)
            }
            return successor
        })
        objectPrototype.object?.setOwn("catch", makeNativeFunction(name: "catch") { call in
            try self.call(try self.getProperty(call.this, name: "then"), this: call.this, args: [.undefined, call.args.first ?? .undefined], construct: false)
        })
        globalBox.object?.setOwn("Promise", ctor)
    }

    func settle(_ promise: JSCBox, state: Int, value: JSCBox) {
        guard let object = promise.object, object.promiseState == 0 else { return }
        object.promiseState = state
        object.promiseResult = value
        flushPromise(promise)
    }

    private func flushPromise(_ promise: JSCBox) {
        guard let object = promise.object, object.promiseState != 0 else { return }
        let queue = object.thenQueue
        object.thenQueue.removeAll()
        for item in queue {
            let callback = object.promiseState == 1 ? item.onFulfilled : item.onRejected
            do {
                if let callback {
                    let result = try call(callback, this: .undefined, args: [object.promiseResult ?? .undefined], construct: false)
                    settle(item.successor, state: 1, value: result)
                } else {
                    settle(item.successor, state: object.promiseState, value: object.promiseResult ?? .undefined)
                }
            } catch let jump as JSCJump {
                if case .thrown(let value) = jump {
                    settle(item.successor, state: 2, value: value)
                }
            } catch {
                settle(item.successor, state: 2, value: makeError("Error", String(describing: error)))
            }
        }
    }

    private func installConsole() {
        let console = makeObject()
        console.object?.className = "console"
        console.object?.setOwn("log", makeNativeFunction(name: "log") { _ in .undefined })
        console.object?.setOwn("warn", makeNativeFunction(name: "warn") { _ in .undefined })
        console.object?.setOwn("error", makeNativeFunction(name: "error") { _ in .undefined })
        globalBox.object?.setOwn("console", console)
    }

    private func installTypedArrays() {
        globalBox.object?.setOwn("ArrayBuffer", makeNativeFunction(name: "ArrayBuffer", ctor: true) { call in
            let length = Int(call.args.first?.numberValue() ?? 0)
            return self.makeArrayBuffer(byteLength: max(length, 0))
        })
    }

    func makeArrayBuffer(byteLength: Int) -> JSCBox {
        let object = JSCObject()
        object.isArrayBuffer = true
        object.className = "ArrayBuffer"
        object.bufferLength = byteLength
        if byteLength > 0 {
            object.buffer = .allocate(byteCount: byteLength, alignment: 1)
            object.buffer?.initializeMemory(as: UInt8.self, repeating: 0, count: byteLength)
            object.ownsBuffer = true
        }
        object.setOwn("byteLength", intern(JSCBox(.number(Double(byteLength)))))
        return intern(JSCBox(.object(object)))
    }

    func makeTypedArray(type: JSTypedArrayType, length: Int, buffer: JSCBox? = nil, offset: Int = 0) throws -> JSCBox {
        let elementSize = JSCTypedArray.elementSize(type)
        guard elementSize > 0 else {
            throw JSCJump.thrown(makeError("TypeError", "not a typed array type"))
        }
        let backing: JSCBox
        if let buffer {
            backing = buffer
        } else {
            backing = makeArrayBuffer(byteLength: length * elementSize)
        }
        let object = JSCObject()
        object.typedArrayType = type
        object.arrayBuffer = backing.object
        object.byteOffset = offset
        object.typedLength = length
        object.buffer = backing.object?.buffer?.advanced(by: offset)
        object.bufferLength = length * elementSize
        object.className = JSCTypedArray.name(type)
        object.prototype = objectPrototype
        object.setOwn("length", intern(JSCBox(.number(Double(length)))))
        object.setOwn("byteLength", intern(JSCBox(.number(Double(object.bufferLength)))))
        object.setOwn("byteOffset", intern(JSCBox(.number(Double(offset)))))
        object.setOwn("buffer", backing)
        return intern(JSCBox(.object(object)))
    }
}

enum JSCTypedArray {
    static func elementSize(_ type: JSTypedArrayType) -> Int {
        switch type {
        case kJSTypedArrayTypeInt8Array, kJSTypedArrayTypeUint8Array, kJSTypedArrayTypeUint8ClampedArray:
            return 1
        case kJSTypedArrayTypeInt16Array, kJSTypedArrayTypeUint16Array:
            return 2
        case kJSTypedArrayTypeInt32Array, kJSTypedArrayTypeUint32Array, kJSTypedArrayTypeFloat32Array:
            return 4
        case kJSTypedArrayTypeFloat64Array, kJSTypedArrayTypeBigInt64Array, kJSTypedArrayTypeBigUint64Array:
            return 8
        default:
            return 0
        }
    }

    static func name(_ type: JSTypedArrayType) -> String {
        switch type {
        case kJSTypedArrayTypeInt8Array: return "Int8Array"
        case kJSTypedArrayTypeInt16Array: return "Int16Array"
        case kJSTypedArrayTypeInt32Array: return "Int32Array"
        case kJSTypedArrayTypeUint8Array: return "Uint8Array"
        case kJSTypedArrayTypeUint8ClampedArray: return "Uint8ClampedArray"
        case kJSTypedArrayTypeUint16Array: return "Uint16Array"
        case kJSTypedArrayTypeUint32Array: return "Uint32Array"
        case kJSTypedArrayTypeFloat32Array: return "Float32Array"
        case kJSTypedArrayTypeFloat64Array: return "Float64Array"
        case kJSTypedArrayTypeBigInt64Array: return "BigInt64Array"
        case kJSTypedArrayTypeBigUint64Array: return "BigUint64Array"
        case kJSTypedArrayTypeArrayBuffer: return "ArrayBuffer"
        default: return "TypedArray"
        }
    }
}
