import CoreFoundation
import Foundation

class JSCRetainable: NSObject {
    var retainCountValue: Int = 1
    var protectCount: Int = 0
}

enum JSCPrimitive {
    case undefined
    case null
    case boolean(Bool)
    case number(Double)
    case string(String)
    case symbol(id: Int, description: String)
    case bigInt(String)
}

enum JSCObjectKind {
    case ordinary
    case array
    case function
    case date
    case error
    case regexp
    case arrayBuffer
    case typedArray
    case promise
    case constructor
}

struct JSCProperty {
    var value: JSCValue
    var writable: Bool
    var enumerable: Bool
    var configurable: Bool
    var getter: JSCValue?
    var setter: JSCValue?
}

final class JSCClass: JSCRetainable {
    var definition: JSClassDefinition
    var parent: JSCClass?
    var className: String

    init(definition: JSClassDefinition, parent: JSCClass?, className: String) {
        self.definition = definition
        self.parent = parent
        self.className = className
        super.init()
    }
}

final class JSCObject {
    var kind: JSCObjectKind
    var properties: [String: JSCProperty] = [:]
    var prototype: JSCValue?
    var privateData: UnsafeMutableRawPointer?
    var jsClass: JSCClass?
    var nativeFunction: (([JSCValue], JSCValue, JSCContext) throws -> JSCValue)?
    var jsFunction: JSCFunctionBody?
    var constructorCallback: JSObjectCallAsConstructorCallback?
    var functionCallback: JSObjectCallAsFunctionCallback?
    var buffer: JSCArrayBuffer?
    var typedArray: JSCTypedArray?
    var date: Date?
    var regexp: (pattern: String, flags: String)?
    var promiseState: JSCPromiseState?
    var hostFunction: ((JSContext, [Any]) -> Any?)?

    init(kind: JSCObjectKind) {
        self.kind = kind
    }
}

struct JSCFunctionBody {
    var name: String
    var parameters: [String]
    var statements: [JSCStmt]
    var environment: JSCEnvironment
}

final class JSCArrayBuffer {
    let bytes: UnsafeMutableRawPointer
    let length: Int
    var deallocator: JSTypedArrayBytesDeallocator?
    var deallocatorContext: UnsafeMutableRawPointer?
    var ownsAllocation: Bool
    weak var internedBufferObject: JSCValue?

    init(length: Int) {
        self.length = length
        self.bytes = UnsafeMutableRawPointer.allocate(byteCount: max(length, 1), alignment: 8)
        self.bytes.initializeMemory(as: UInt8.self, repeating: 0, count: max(length, 1))
        self.ownsAllocation = true
    }

    init(
        bytes: UnsafeMutableRawPointer,
        length: Int,
        deallocator: JSTypedArrayBytesDeallocator?,
        deallocatorContext: UnsafeMutableRawPointer?
    ) {
        self.bytes = bytes
        self.length = length
        self.deallocator = deallocator
        self.deallocatorContext = deallocatorContext
        self.ownsAllocation = false
    }

    func pointer() -> UnsafeMutableRawPointer { bytes }

    deinit {
        if let deallocator {
            deallocator(bytes, deallocatorContext)
        } else if ownsAllocation {
            bytes.deallocate()
        }
    }
}

struct JSCTypedArray {
    var type: JSTypedArrayType
    var buffer: JSCValue
    var byteOffset: Int
    var length: Int
    var bytesPerElement: Int
}

enum JSCPromiseState {
    case pending(resolve: JSCValue, reject: JSCValue)
    case fulfilled(JSCValue)
    case rejected(JSCValue)
}

final class JSCValue: JSCRetainable {
    var primitive: JSCPrimitive
    var object: JSCObject?
    weak var context: JSCContext?

    init(primitive: JSCPrimitive, context: JSCContext?) {
        self.primitive = primitive
        self.context = context
        super.init()
    }

    static func object(_ object: JSCObject, context: JSCContext) -> JSCValue {
        let value = JSCValue(primitive: .null, context: context)
        value.primitive = .null
        value.object = object
        if object.prototype == nil, let proto = context.objectPrototype, object !== proto.object {
            object.prototype = proto
        }
        return value
    }

    var isObject: Bool { object != nil }
    var isUndefined: Bool {
        if object != nil { return false }
        if case .undefined = primitive { return true }
        return false
    }
    var isNull: Bool {
        if object != nil { return false }
        if case .null = primitive { return true }
        return false
    }
}

final class JSCString: JSCRetainable {
    private var storage: UnsafeMutablePointer<UInt16>
    let count: Int

    init(_ string: String) {
        let units = Array(string.utf16)
        self.count = units.count
        self.storage = UnsafeMutablePointer<UInt16>.allocate(capacity: max(units.count, 1))
        if !units.isEmpty {
            storage.update(from: units, count: units.count)
        }
        super.init()
    }

    var utf16: [UInt16] {
        Array(UnsafeBufferPointer(start: storage, count: count))
    }

    var characters: UnsafePointer<JSChar> {
        UnsafePointer(storage)
    }

    var string: String {
        String(decoding: UnsafeBufferPointer(start: storage, count: count), as: UTF16.self)
    }

    deinit {
        storage.deallocate()
    }
}

final class JSCNameArray: JSCRetainable {
    var names: [JSCString]

    init(_ names: [String]) {
        self.names = names.map { JSCString($0) }
        super.init()
    }
}

final class JSCEnvironment {
    var parent: JSCEnvironment?
    var values: [String: JSCValue] = [:]

    init(parent: JSCEnvironment?) {
        self.parent = parent
    }

    func get(_ name: String) -> JSCValue? {
        if let value = values[name] { return value }
        return parent?.get(name)
    }

    func set(_ name: String, _ value: JSCValue) -> Bool {
        if values[name] != nil {
            values[name] = value
            return true
        }
        if let parent {
            return parent.set(name, value)
        }
        return false
    }

    func define(_ name: String, _ value: JSCValue) {
        values[name] = value
    }
}

final class JSCGroup: JSCRetainable {
    let lock = NSLock()
    var nextSymbolId = 1

    func withLock<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }
}

final class JSCContext: JSCRetainable {
    let group: JSCGroup
    var global: JSCValue!
    var objectPrototype: JSCValue?
    var name: String = ""
    var inspectable = false
    weak var overlay: JSContext?
    var exception: JSCValue?

    func makeSymbolId() -> Int {
        group.nextSymbolId += 1
        return group.nextSymbolId
    }

    init(group: JSCGroup) {
        self.group = group
        super.init()
        let globalObject = JSCObject(kind: .ordinary)
        global = JSCValue.object(globalObject, context: self)
        installBuiltins()
    }

    func installBuiltins() {
        let objectCtor = makeNativeConstructor("Object") { [weak self] args, _, _ in
            guard let self else { return JSCValue(primitive: .undefined, context: nil) }
            if let first = args.first, first.isObject { return first }
            return JSCValue.object(JSCObject(kind: .ordinary), context: self)
        }
        setGlobal("Object", objectCtor)

        let arrayCtor = makeNativeConstructor("Array") { [weak self] args, _, _ in
            guard let self else { return JSCValue(primitive: .undefined, context: nil) }
            let array = JSCValue.object(JSCObject(kind: .array), context: self)
            for (index, arg) in args.enumerated() {
                self.setProperty(array, String(index), arg, enumerable: true)
            }
            self.setProperty(array, "length", JSCValue(primitive: .number(Double(args.count)), context: self), enumerable: false)
            return array
        }
        setGlobal("Array", arrayCtor)

        let dateCtor = makeNativeConstructor("Date") { [weak self] _, _, _ in
            guard let self else { return JSCValue(primitive: .undefined, context: nil) }
            let object = JSCObject(kind: .date)
            object.date = Date()
            return JSCValue.object(object, context: self)
        }
        setGlobal("Date", dateCtor)

        let errorCtor = makeNativeConstructor("Error") { [weak self] args, _, _ in
            guard let self else { return JSCValue(primitive: .undefined, context: nil) }
            return self.makeError(args.first.map { self.toString($0) } ?? "")
        }
        setGlobal("Error", errorCtor)

        let json = JSCValue.object(JSCObject(kind: .ordinary), context: self)
        let parse = makeNativeFunction("parse") { [weak self] args, _, _ in
            guard let self else { return JSCValue(primitive: .undefined, context: nil) }
            let text = args.first.map { self.toString($0) } ?? ""
            return self.parseJSON(text)
        }
        let stringify = makeNativeFunction("stringify") { [weak self] args, _, _ in
            guard let self else { return JSCValue(primitive: .undefined, context: nil) }
            let indent = args.count > 1 ? Int(self.toNumber(args[1])) : 0
            return JSCValue(primitive: .string(self.jsonString(args.first, indent: indent)), context: self)
        }
        setProperty(json, "parse", parse, enumerable: true)
        setProperty(json, "stringify", stringify, enumerable: true)
        setGlobal("JSON", json)

        let math = JSCValue.object(JSCObject(kind: .ordinary), context: self)
        setProperty(math, "PI", JSCValue(primitive: .number(Double.pi), context: self), enumerable: true)
        let absFn = makeNativeFunction("abs") { [weak self] args, _, _ in
            guard let self else { return JSCValue(primitive: .undefined, context: nil) }
            return JSCValue(primitive: .number(abs(self.toNumber(args.first ?? JSCValue(primitive: .undefined, context: self)))), context: self)
        }
        setProperty(math, "abs", absFn, enumerable: true)
        setGlobal("Math", math)

        setGlobal("undefined", JSCValue(primitive: .undefined, context: self))
        setGlobal("NaN", JSCValue(primitive: .number(Double.nan), context: self))
        setGlobal("Infinity", JSCValue(primitive: .number(Double.infinity), context: self))

        let objectProto = JSCValue.object(JSCObject(kind: .ordinary), context: self)
        objectPrototype = objectProto
        let toString = makeNativeFunction("toString") { [weak self] _, thisArg, _ in
            guard let self else { return JSCValue(primitive: .undefined, context: nil) }
            return JSCValue(primitive: .string(self.toString(thisArg)), context: self)
        }
        setProperty(objectProto, "toString", toString, enumerable: false)
        global.object?.prototype = objectProto
        setProperty(objectCtor, "prototype", objectProto, enumerable: false)
    }

    func setGlobal(_ name: String, _ value: JSCValue) {
        setProperty(global, name, value, enumerable: true)
    }

    func makeNativeFunction(_ name: String, _ body: @escaping ([JSCValue], JSCValue, JSCContext) throws -> JSCValue) -> JSCValue {
        let object = JSCObject(kind: .function)
        object.nativeFunction = body
        setProperty(JSCValue.object(object, context: self), "name", JSCValue(primitive: .string(name), context: self), enumerable: false)
        let fn = JSCValue.object(object, context: self)
        setProperty(fn, "length", JSCValue(primitive: .number(0), context: self), enumerable: false)
        return fn
    }

    func makeNativeConstructor(_ name: String, _ body: @escaping ([JSCValue], JSCValue, JSCContext) throws -> JSCValue) -> JSCValue {
        let value = makeNativeFunction(name, body)
        value.object?.kind = .constructor
        return value
    }

    func makeError(_ message: String) -> JSCValue {
        let object = JSCObject(kind: .error)
        let value = JSCValue.object(object, context: self)
        setProperty(value, "message", JSCValue(primitive: .string(message), context: self), enumerable: true)
        setProperty(value, "name", JSCValue(primitive: .string("Error"), context: self), enumerable: true)
        return value
    }

    func setProperty(_ objectValue: JSCValue, _ name: String, _ value: JSCValue, enumerable: Bool, writable: Bool = true, configurable: Bool = true) {
        guard let object = objectValue.object else { return }
        object.properties[name] = JSCProperty(
            value: value,
            writable: writable,
            enumerable: enumerable,
            configurable: configurable
        )
    }

    func getProperty(_ objectValue: JSCValue, _ name: String) -> JSCValue {
        var current: JSCValue? = objectValue
        while let object = current?.object {
            if name == "__proto__" {
                return object.prototype ?? JSCValue(primitive: .null, context: self)
            }
            if let property = object.properties[name] {
                if let getter = property.getter {
                    return (try? call(getter, this: objectValue, arguments: [])) ?? JSCValue(primitive: .undefined, context: self)
                }
                return property.value
            }
            if let jsClass = object.jsClass {
                if let callback = jsClass.definition.getProperty ?? jsClass.parent?.definition.getProperty {
                    let ctxRef = jscPointer(self)
                    let objRef = jscPointer(objectValue)
                    let nameRef = jscPointer(JSCString(name))
                    defer { jscRelease(nameRef) }
                    var exception: JSValueRef?
                    if let result = callback(ctxRef, objRef, nameRef, &exception) {
                        if let exception, let thrown = jscValue(exception) {
                            self.exception = thrown
                        }
                        return jscValue(result) ?? JSCValue(primitive: .undefined, context: self)
                    }
                }
            }
            current = object.prototype
        }
        return JSCValue(primitive: .undefined, context: self)
    }

    func hasProperty(_ objectValue: JSCValue, _ name: String) -> Bool {
        var current: JSCValue? = objectValue
        while let object = current?.object {
            if object.properties[name] != nil { return true }
            current = object.prototype
        }
        return false
    }

    func deleteProperty(_ objectValue: JSCValue, _ name: String) -> Bool {
        guard let object = objectValue.object else { return false }
        guard let property = object.properties[name] else { return true }
        guard property.configurable else { return false }
        object.properties.removeValue(forKey: name)
        return true
    }

    func propertyNames(_ objectValue: JSCValue) -> [String] {
        guard let object = objectValue.object else { return [] }
        return object.properties.compactMap { key, property in
            property.enumerable ? key : nil
        }.sorted()
    }

    func toBoolean(_ value: JSCValue) -> Bool {
        if let object = value.object {
            _ = object
            return true
        }
        switch value.primitive {
        case .undefined, .null: return false
        case .boolean(let flag): return flag
        case .number(let number): return number != 0 && !number.isNaN
        case .string(let string): return !string.isEmpty
        case .symbol, .bigInt: return true
        }
    }

    func toNumber(_ value: JSCValue) -> Double {
        if value.object != nil {
            return Double.nan
        }
        switch value.primitive {
        case .undefined: return Double.nan
        case .null: return 0
        case .boolean(let flag): return flag ? 1 : 0
        case .number(let number): return number
        case .string(let string): return Double(string.trimmingCharacters(in: .whitespacesAndNewlines)) ?? Double.nan
        case .symbol: return Double.nan
        case .bigInt(let text): return Double(text) ?? Double.nan
        }
    }

    func toString(_ value: JSCValue) -> String {
        if let object = value.object {
            switch object.kind {
            case .array:
                let length = Int(toNumber(getProperty(value, "length")))
                return (0..<max(length, 0)).map { toString(getProperty(value, String($0))) }.joined(separator: ",")
            case .function:
                let name = toString(getProperty(value, "name"))
                return name.isEmpty ? "function () { [native code] }" : "function \(name)() { [native code] }"
            case .date:
                return (object.date ?? Date()).description
            case .error:
                return "Error: \(toString(getProperty(value, "message")))"
            case .regexp:
                let pattern = object.regexp?.pattern ?? ""
                let flags = object.regexp?.flags ?? ""
                return "/\(pattern)/\(flags)"
            default:
                return "[object Object]"
            }
        }
        switch value.primitive {
        case .undefined: return "undefined"
        case .null: return "null"
        case .boolean(let flag): return flag ? "true" : "false"
        case .number(let number):
            if number.isNaN { return "NaN" }
            if number.isInfinite { return number > 0 ? "Infinity" : "-Infinity" }
            if number == number.rounded(.towardZero) && abs(number) < 1e15 {
                return String(Int64(number))
            }
            return String(number)
        case .string(let string): return string
        case .symbol(_, let description): return "Symbol(\(description))"
        case .bigInt(let text): return text
        }
    }

    func jsType(_ value: JSCValue) -> JSType {
        if value.object != nil { return kJSTypeObject }
        switch value.primitive {
        case .undefined: return kJSTypeUndefined
        case .null: return kJSTypeNull
        case .boolean: return kJSTypeBoolean
        case .number: return kJSTypeNumber
        case .string: return kJSTypeString
        case .symbol: return kJSTypeSymbol
        case .bigInt: return kJSTypeBigInt
        }
    }

    func call(_ function: JSCValue, this: JSCValue, arguments: [JSCValue]) throws -> JSCValue {
        guard let object = function.object else {
            throw JSCThrown(value: makeError("not a function"))
        }
        if let native = object.nativeFunction {
            return try native(arguments, this, self)
        }
        if let host = object.hostFunction, let overlay {
            let bridged = arguments.map { JSValue(engineValue: $0, context: overlay) as Any }
            JSContextTLS.push(context: overlay, this: JSValue(engineValue: this, context: overlay), arguments: bridged, callee: JSValue(engineValue: function, context: overlay))
            defer { JSContextTLS.pop() }
            let result = host(overlay, bridged)
            return overlay.engineValue(from: result)
        }
        if let callback = object.functionCallback {
            let ctxRef = jscPointer(self)
            let objectRef = jscPointer(function)
            let thisRef = jscPointer(this)
            let refs = arguments.map { jscPointer($0) as JSValueRef? }
            var exception: JSValueRef?
            let result = refs.withUnsafeBufferPointer { buffer in
                callback(ctxRef, objectRef, thisRef, arguments.count, buffer.baseAddress, &exception)
            }
            if let exception, let thrown = jscValue(exception) {
                throw JSCThrown(value: thrown)
            }
            return jscValue(result) ?? JSCValue(primitive: .undefined, context: self)
        }
        if let body = object.jsFunction {
            let env = JSCEnvironment(parent: body.environment)
            for (index, name) in body.parameters.enumerated() {
                env.define(name, index < arguments.count ? arguments[index] : JSCValue(primitive: .undefined, context: self))
            }
            env.define("this", this)
            env.define("arguments", makeArray(arguments))
            let interpreter = JSCInterpreter(context: self, environment: env, thisValue: this)
            do {
                try interpreter.run(body.statements)
                return interpreter.returnValue ?? JSCValue(primitive: .undefined, context: self)
            } catch let thrown as JSCReturn {
                return thrown.value ?? JSCValue(primitive: .undefined, context: self)
            }
        }
        throw JSCThrown(value: makeError("not a function"))
    }

    func construct(_ function: JSCValue, arguments: [JSCValue]) throws -> JSCValue {
        let created = JSCValue.object(JSCObject(kind: .ordinary), context: self)
        created.object?.prototype = getProperty(function, "prototype")
        if let object = function.object, let callback = object.constructorCallback {
            let ctxRef = jscPointer(self)
            let refs = arguments.map { jscPointer($0) as JSValueRef? }
            var exception: JSValueRef?
            let result = refs.withUnsafeBufferPointer { buffer in
                callback(ctxRef, jscPointer(function), arguments.count, buffer.baseAddress, &exception)
            }
            if let exception, let thrown = jscValue(exception) {
                throw JSCThrown(value: thrown)
            }
            return jscValue(result) ?? created
        }
        let result = try call(function, this: created, arguments: arguments)
        return result.isObject ? result : created
    }

    func makeArray(_ values: [JSCValue]) -> JSCValue {
        let array = JSCValue.object(JSCObject(kind: .array), context: self)
        for (index, value) in values.enumerated() {
            setProperty(array, String(index), value, enumerable: true)
        }
        setProperty(array, "length", JSCValue(primitive: .number(Double(values.count)), context: self), enumerable: false)
        return array
    }

    func parseJSON(_ text: String) -> JSCValue {
        let data = Data(text.utf8)
        guard let object = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) else {
            exception = makeError("JSON parse error")
            return JSCValue(primitive: .undefined, context: self)
        }
        return bridgeJSON(object)
    }

    func bridgeJSON(_ object: Any) -> JSCValue {
        switch object {
        case let flag as Bool:
            return JSCValue(primitive: .boolean(flag), context: self)
        case let number as NSNumber:
            let typeID = CFGetTypeID(number)
            if typeID == CFBooleanGetTypeID() {
                return JSCValue(primitive: .boolean(number.boolValue), context: self)
            }
            return JSCValue(primitive: .number(number.doubleValue), context: self)
        case let string as String:
            return JSCValue(primitive: .string(string), context: self)
        case let array as [Any]:
            return makeArray(array.map(bridgeJSON))
        case let dict as [String: Any]:
            let jsObject = JSCValue.object(JSCObject(kind: .ordinary), context: self)
            for (key, value) in dict {
                setProperty(jsObject, key, bridgeJSON(value), enumerable: true)
            }
            return jsObject
        case is NSNull:
            return JSCValue(primitive: .null, context: self)
        default:
            return JSCValue(primitive: .null, context: self)
        }
    }

    func jsonString(_ value: JSCValue?, indent: Int) -> String {
        guard let value else { return "null" }
        let bridged = unbridgeJSON(value)
        guard JSONSerialization.isValidJSONObject(bridged) || bridged is String || bridged is NSNumber || bridged is NSNull else {
            return "null"
        }
        let options: JSONSerialization.WritingOptions = indent > 0 ? [.prettyPrinted] : []
        if let data = try? JSONSerialization.data(withJSONObject: bridged is String || bridged is NSNumber || bridged is NSNull ? [bridged] : bridged, options: options) {
            if bridged is String || bridged is NSNumber || bridged is NSNull {
                if let array = try? JSONSerialization.jsonObject(with: data) as? [Any], let first = array.first,
                   let piece = try? JSONSerialization.data(withJSONObject: [first], options: options),
                   let text = String(data: piece, encoding: .utf8) {
                    let trimmed = text.dropFirst().dropLast()
                    return String(trimmed).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            return String(data: data, encoding: .utf8) ?? "null"
        }
        return stringifyValue(value)
    }

    func stringifyValue(_ value: JSCValue) -> String {
        if value.object != nil {
            if value.object?.kind == .array {
                let length = Int(toNumber(getProperty(value, "length")))
                let items = (0..<max(length, 0)).map { stringifyValue(getProperty(value, String($0))) }
                return "[\(items.joined(separator: ","))]"
            }
            let pairs = propertyNames(value).map { key in
                "\"\(key)\":\(stringifyValue(getProperty(value, key)))"
            }
            return "{\(pairs.joined(separator: ","))}"
        }
        switch value.primitive {
        case .undefined, .symbol: return "null"
        case .null: return "null"
        case .boolean(let flag): return flag ? "true" : "false"
        case .number(let number):
            if number.isFinite { return String(number) }
            return "null"
        case .string(let string):
            let escaped = string.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
            return "\"\(escaped)\""
        case .bigInt(let text): return text
        }
    }

    func unbridgeJSON(_ value: JSCValue) -> Any {
        if let object = value.object {
            if object.kind == .array {
                let length = Int(toNumber(getProperty(value, "length")))
                return (0..<max(length, 0)).map { unbridgeJSON(getProperty(value, String($0))) }
            }
            var dict: [String: Any] = [:]
            for name in propertyNames(value) {
                dict[name] = unbridgeJSON(getProperty(value, name))
            }
            return dict
        }
        switch value.primitive {
        case .undefined, .symbol: return NSNull()
        case .null: return NSNull()
        case .boolean(let flag): return flag
        case .number(let number): return number
        case .string(let string): return string
        case .bigInt(let text): return text
        }
    }

    func evaluate(_ script: String, this: JSCValue?, sourceURL: String?, startingLine: Int32) -> JSCValue {
        exception = nil
        do {
            let program = try JSCParser(source: script).parseProgram()
            let env = JSCEnvironment(parent: nil)
            env.define("this", this ?? global)
            let interpreter = JSCInterpreter(context: self, environment: env, thisValue: this ?? global)
            try interpreter.run(program)
            return interpreter.returnValue ?? JSCValue(primitive: .undefined, context: self)
        } catch let thrown as JSCThrown {
            exception = thrown.value
            return JSCValue(primitive: .undefined, context: self)
        } catch let thrown as JSCReturn {
            return thrown.value ?? JSCValue(primitive: .undefined, context: self)
        } catch {
            exception = makeError(String(describing: error))
            return JSCValue(primitive: .undefined, context: self)
        }
    }

    func checkSyntax(_ script: String) -> Bool {
        exception = nil
        do {
            _ = try JSCParser(source: script).parseProgram()
            return true
        } catch {
            exception = makeError(String(describing: error))
            return false
        }
    }
}

struct JSCThrown: Error {
    var value: JSCValue
}

struct JSCReturn: Error {
    var value: JSCValue?
}

indirect enum JSCExpr {
    case literal(JSCPrimitive)
    case ident(String)
    case this
    case unary(String, JSCExpr)
    case binary(String, JSCExpr, JSCExpr)
    case assign(JSCExpr, JSCExpr)
    case member(JSCExpr, String)
    case index(JSCExpr, JSCExpr)
    case call(JSCExpr, [JSCExpr])
    case construct(JSCExpr, [JSCExpr])
    case array([JSCExpr])
    case object([(String, JSCExpr)])
    case function(String?, [String], [JSCStmt])
    case cond(JSCExpr, JSCExpr, JSCExpr)
}

indirect enum JSCStmt {
    case block([JSCStmt])
    case expr(JSCExpr)
    case varDecl(String, String, JSCExpr?)
    case ifStmt(JSCExpr, JSCStmt, JSCStmt?)
    case whileStmt(JSCExpr, JSCStmt)
    case returnStmt(JSCExpr?)
    case throwStmt(JSCExpr)
    case functionDecl(String, [String], [JSCStmt])
    case empty
}

enum JSCToken: Equatable {
    case number(Double)
    case string(String)
    case ident(String)
    case punct(String)
    case eof
}

final class JSCLexer {
    let source: [Character]
    var index = 0

    init(source: String) {
        self.source = Array(source)
    }

    func peek() -> Character? {
        index < source.count ? source[index] : nil
    }

    func advance() -> Character? {
        guard index < source.count else { return nil }
        let character = source[index]
        index += 1
        return character
    }

    func skip() {
        while let character = peek() {
            if character == "/" && index + 1 < source.count && source[index + 1] == "/" {
                while let next = peek(), next != "\n" { _ = advance() }
                continue
            }
            if character == "/" && index + 1 < source.count && source[index + 1] == "*" {
                _ = advance(); _ = advance()
                while let next = peek() {
                    _ = advance()
                    if next == "*" && peek() == "/" {
                        _ = advance()
                        break
                    }
                }
                continue
            }
            if character.isWhitespace {
                _ = advance()
                continue
            }
            break
        }
    }

    func next() throws -> JSCToken {
        skip()
        guard let character = peek() else { return .eof }
        if character.isLetter || character == "_" || character == "$" {
            var text = ""
            while let next = peek(), next.isLetter || next.isNumber || next == "_" || next == "$" {
                text.append(advance()!)
            }
            return .ident(text)
        }
        if character.isNumber || (character == "." && index + 1 < source.count && source[index + 1].isNumber) {
            var text = ""
            while let next = peek(), next.isNumber || next == "." || next == "e" || next == "E" || next == "+" || next == "-" && text.last == "e" || text.last == "E" {
                if (next == "+" || next == "-") && text.last != "e" && text.last != "E" { break }
                text.append(advance()!)
            }
            guard let value = Double(text) else { throw JSCParseError("invalid number \(text)") }
            return .number(value)
        }
        if character == "\"" || character == "'" {
            let quote = advance()!
            var text = ""
            while let next = peek(), next != quote {
                _ = advance()
                if next == "\\" {
                    guard let escaped = advance() else { break }
                    switch escaped {
                    case "n": text.append("\n")
                    case "t": text.append("\t")
                    case "r": text.append("\r")
                    case "\\": text.append("\\")
                    case "\"": text.append("\"")
                    case "'": text.append("'")
                    default: text.append(escaped)
                    }
                } else {
                    text.append(next)
                }
            }
            _ = advance()
            return .string(text)
        }
        let two: [String] = ["===", "!==", "&&", "||", "==", "!=", "<=", ">=", "++", "--"]
        let remaining = String(source[index...])
        for op in two where remaining.hasPrefix(op) {
            index += op.count
            return .punct(op)
        }
        _ = advance()
        return .punct(String(character))
    }
}

struct JSCParseError: Error, CustomStringConvertible {
    var description: String
    init(_ description: String) { self.description = description }
}

final class JSCParser {
    var tokens: [JSCToken] = []
    var index = 0

    init(source: String) throws {
        let lexer = JSCLexer(source: source)
        while true {
            let token = try lexer.next()
            tokens.append(token)
            if token == .eof { break }
        }
    }

    func peek() -> JSCToken { tokens[index] }

    func advance() -> JSCToken {
        let token = tokens[index]
        if index < tokens.count - 1 { index += 1 }
        return token
    }

    func match(_ punct: String) -> Bool {
        if case .punct(let value) = peek(), value == punct {
            _ = advance()
            return true
        }
        return false
    }

    func matchIdent(_ ident: String) -> Bool {
        if case .ident(let value) = peek(), value == ident {
            _ = advance()
            return true
        }
        return false
    }

    func parseProgram() throws -> [JSCStmt] {
        var statements: [JSCStmt] = []
        while peek() != .eof {
            if match(";") { continue }
            statements.append(try parseStatement())
        }
        return statements
    }

    func parseStatement() throws -> JSCStmt {
        if match("{") {
            var statements: [JSCStmt] = []
            while !match("}") {
                if peek() == .eof { throw JSCParseError("unterminated block") }
                statements.append(try parseStatement())
            }
            return .block(statements)
        }
        if matchIdent("if") {
            try expect("(")
            let test = try parseExpression()
            try expect(")")
            let consequent = try parseStatement()
            var alternate: JSCStmt?
            if matchIdent("else") { alternate = try parseStatement() }
            return .ifStmt(test, consequent, alternate)
        }
        if matchIdent("while") {
            try expect("(")
            let test = try parseExpression()
            try expect(")")
            return .whileStmt(test, try parseStatement())
        }
        if matchIdent("return") {
            if match(";") { return .returnStmt(nil) }
            let value = try parseExpression()
            _ = match(";")
            return .returnStmt(value)
        }
        if matchIdent("throw") {
            let value = try parseExpression()
            _ = match(";")
            return .throwStmt(value)
        }
        if matchIdent("function") {
            guard case .ident(let name) = advance() else { throw JSCParseError("function name") }
            let (params, body) = try parseFunctionRest()
            return .functionDecl(name, params, body)
        }
        if case .ident(let keyword) = peek(), ["var", "let", "const"].contains(keyword) {
            _ = advance()
            guard case .ident(let name) = advance() else { throw JSCParseError("binding name") }
            var expr: JSCExpr?
            if match("=") { expr = try parseExpression() }
            _ = match(";")
            return .varDecl(keyword, name, expr)
        }
        let expr = try parseExpression()
        _ = match(";")
        return .expr(expr)
    }

    func parseFunctionRest() throws -> ([String], [JSCStmt]) {
        try expect("(")
        var params: [String] = []
        if !match(")") {
            while true {
                guard case .ident(let name) = advance() else { throw JSCParseError("parameter") }
                params.append(name)
                if match(")") { break }
                try expect(",")
            }
        }
        try expect("{")
        var body: [JSCStmt] = []
        while !match("}") {
            if peek() == .eof { throw JSCParseError("unterminated function") }
            body.append(try parseStatement())
        }
        return (params, body)
    }

    func expect(_ punct: String) throws {
        guard match(punct) else { throw JSCParseError("expected \(punct)") }
    }

    func parseExpression() throws -> JSCExpr { try parseAssignment() }

    func parseAssignment() throws -> JSCExpr {
        let left = try parseConditional()
        if match("=") {
            return .assign(left, try parseAssignment())
        }
        return left
    }

    func parseConditional() throws -> JSCExpr {
        let test = try parseOr()
        if match("?") {
            let consequent = try parseExpression()
            try expect(":")
            return .cond(test, consequent, try parseAssignment())
        }
        return test
    }

    func parseOr() throws -> JSCExpr { try parseBinary(["||"], parseAnd) }
    func parseAnd() throws -> JSCExpr { try parseBinary(["&&"], parseEquality) }
    func parseEquality() throws -> JSCExpr { try parseBinary(["===", "!==", "==", "!="], parseRelation) }
    func parseRelation() throws -> JSCExpr { try parseBinary(["<=", ">=", "<", ">"], parseAdd) }
    func parseAdd() throws -> JSCExpr { try parseBinary(["+", "-"], parseMul) }
    func parseMul() throws -> JSCExpr { try parseBinary(["*", "/", "%"], parseUnary) }

    func parseBinary(_ ops: [String], _ next: () throws -> JSCExpr) throws -> JSCExpr {
        var expr = try next()
        while case .punct(let op) = peek(), ops.contains(op) {
            _ = advance()
            expr = .binary(op, expr, try next())
        }
        return expr
    }

    func parseUnary() throws -> JSCExpr {
        if matchIdent("typeof") { return .unary("typeof", try parseUnary()) }
        if matchIdent("new") {
            let callee = try parseMember()
            var args: [JSCExpr] = []
            if match("(") { args = try parseArgList() }
            return .construct(callee, args)
        }
        if match("!") { return .unary("!", try parseUnary()) }
        if match("-") { return .unary("-", try parseUnary()) }
        if match("+") { return .unary("+", try parseUnary()) }
        return try parseMember()
    }

    func parseMember() throws -> JSCExpr {
        var expr = try parsePrimary()
        while true {
            if match(".") {
                guard case .ident(let name) = advance() else { throw JSCParseError("member") }
                expr = .member(expr, name)
                continue
            }
            if match("[") {
                let index = try parseExpression()
                try expect("]")
                expr = .index(expr, index)
                continue
            }
            if match("(") {
                expr = .call(expr, try parseArgList())
                continue
            }
            break
        }
        return expr
    }

    func parseArgList() throws -> [JSCExpr] {
        var args: [JSCExpr] = []
        if match(")") { return args }
        while true {
            args.append(try parseExpression())
            if match(")") { return args }
            try expect(",")
        }
    }

    func parsePrimary() throws -> JSCExpr {
        switch peek() {
        case .number(let value):
            _ = advance()
            return .literal(.number(value))
        case .string(let value):
            _ = advance()
            return .literal(.string(value))
        case .ident(let ident):
            _ = advance()
            switch ident {
            case "true": return .literal(.boolean(true))
            case "false": return .literal(.boolean(false))
            case "null": return .literal(.null)
            case "undefined": return .literal(.undefined)
            case "this": return .this
            case "function":
                var name: String?
                if case .ident(let fnName) = peek() {
                    _ = advance()
                    name = fnName
                }
                let (params, body) = try parseFunctionRest()
                return .function(name, params, body)
            default:
                return .ident(ident)
            }
        default:
            break
        }
        if match("(") {
            let expr = try parseExpression()
            try expect(")")
            return expr
        }
        if match("[") {
            var items: [JSCExpr] = []
            if !match("]") {
                while true {
                    items.append(try parseExpression())
                    if match("]") { break }
                    try expect(",")
                }
            }
            return .array(items)
        }
        if match("{") {
            var pairs: [(String, JSCExpr)] = []
            if !match("}") {
                while true {
                    let key: String
                    switch peek() {
                    case .ident(let ident):
                        _ = advance(); key = ident
                    case .string(let string):
                        _ = advance(); key = string
                    case .number(let number):
                        _ = advance(); key = String(number)
                    default:
                        throw JSCParseError("object key")
                    }
                    try expect(":")
                    pairs.append((key, try parseExpression()))
                    if match("}") { break }
                    try expect(",")
                }
            }
            return .object(pairs)
        }
        throw JSCParseError("unexpected token \(peek())")
    }
}

final class JSCInterpreter {
    let context: JSCContext
    var environment: JSCEnvironment
    var thisValue: JSCValue
    var returnValue: JSCValue?

    init(context: JSCContext, environment: JSCEnvironment, thisValue: JSCValue? = nil) {
        self.context = context
        self.environment = environment
        self.thisValue = thisValue ?? context.global
    }

    func run(_ statements: [JSCStmt]) throws {
        for statement in statements {
            try exec(statement)
        }
    }

    func exec(_ statement: JSCStmt) throws {
        switch statement {
        case .block(let statements):
            let child = JSCEnvironment(parent: environment)
            let previous = environment
            environment = child
            defer { environment = previous }
            try run(statements)
        case .expr(let expr):
            returnValue = try eval(expr)
        case .varDecl(_, let name, let expr):
            let value = try expr.map { try eval($0) } ?? JSCValue(primitive: .undefined, context: context)
            environment.define(name, value)
            context.setProperty(context.global, name, value, enumerable: true)
        case .ifStmt(let test, let consequent, let alternate):
            if context.toBoolean(try eval(test)) {
                try exec(consequent)
            } else if let alternate {
                try exec(alternate)
            }
        case .whileStmt(let test, let body):
            var hops = 0
            while context.toBoolean(try eval(test)) {
                hops += 1
                if hops > 100_000 { throw JSCThrown(value: context.makeError("infinite loop")) }
                try exec(body)
            }
        case .returnStmt(let expr):
            throw JSCReturn(value: try expr.map { try eval($0) })
        case .throwStmt(let expr):
            throw JSCThrown(value: try eval(expr))
        case .functionDecl(let name, let params, let body):
            let fn = makeFunction(name: name, params: params, body: body)
            environment.define(name, fn)
            context.setProperty(context.global, name, fn, enumerable: true)
        case .empty:
            break
        }
    }

    func makeFunction(name: String?, params: [String], body: [JSCStmt]) -> JSCValue {
        let object = JSCObject(kind: .function)
        object.jsFunction = JSCFunctionBody(name: name ?? "", parameters: params, statements: body, environment: environment)
        let fn = JSCValue.object(object, context: context)
        context.setProperty(fn, "name", JSCValue(primitive: .string(name ?? ""), context: context), enumerable: false)
        context.setProperty(fn, "length", JSCValue(primitive: .number(Double(params.count)), context: context), enumerable: false)
        context.setProperty(fn, "prototype", JSCValue.object(JSCObject(kind: .ordinary), context: context), enumerable: false)
        return fn
    }

    func eval(_ expr: JSCExpr) throws -> JSCValue {
        switch expr {
        case .literal(let primitive):
            return JSCValue(primitive: primitive, context: context)
        case .ident(let name):
            if let local = environment.get(name) { return local }
            if context.hasProperty(context.global, name) {
                return context.getProperty(context.global, name)
            }
            throw JSCThrown(value: context.makeError("\(name) is not defined"))
        case .this:
            return thisValue
        case .unary(let op, let valueExpr):
            let value = try eval(valueExpr)
            switch op {
            case "!": return JSCValue(primitive: .boolean(!context.toBoolean(value)), context: context)
            case "-": return JSCValue(primitive: .number(-context.toNumber(value)), context: context)
            case "+": return JSCValue(primitive: .number(context.toNumber(value)), context: context)
            case "typeof":
                if value.object != nil {
                    if value.object?.kind == .function || value.object?.kind == .constructor {
                        return JSCValue(primitive: .string("function"), context: context)
                    }
                    return JSCValue(primitive: .string("object"), context: context)
                }
                switch value.primitive {
                case .undefined: return JSCValue(primitive: .string("undefined"), context: context)
                case .null: return JSCValue(primitive: .string("object"), context: context)
                case .boolean: return JSCValue(primitive: .string("boolean"), context: context)
                case .number: return JSCValue(primitive: .string("number"), context: context)
                case .string: return JSCValue(primitive: .string("string"), context: context)
                case .symbol: return JSCValue(primitive: .string("symbol"), context: context)
                case .bigInt: return JSCValue(primitive: .string("bigint"), context: context)
                }
            default:
                return JSCValue(primitive: .undefined, context: context)
            }
        case .binary(let op, let leftExpr, let rightExpr):
            if op == "&&" {
                let left = try eval(leftExpr)
                return context.toBoolean(left) ? try eval(rightExpr) : left
            }
            if op == "||" {
                let left = try eval(leftExpr)
                return context.toBoolean(left) ? left : try eval(rightExpr)
            }
            let left = try eval(leftExpr)
            let right = try eval(rightExpr)
            switch op {
            case "+":
                if case .string = left.primitive, left.object == nil {
                    return JSCValue(primitive: .string(context.toString(left) + context.toString(right)), context: context)
                }
                if case .string = right.primitive, right.object == nil {
                    return JSCValue(primitive: .string(context.toString(left) + context.toString(right)), context: context)
                }
                return JSCValue(primitive: .number(context.toNumber(left) + context.toNumber(right)), context: context)
            case "-": return JSCValue(primitive: .number(context.toNumber(left) - context.toNumber(right)), context: context)
            case "*": return JSCValue(primitive: .number(context.toNumber(left) * context.toNumber(right)), context: context)
            case "/": return JSCValue(primitive: .number(context.toNumber(left) / context.toNumber(right)), context: context)
            case "%": return JSCValue(primitive: .number(context.toNumber(left).truncatingRemainder(dividingBy: context.toNumber(right))), context: context)
            case "==": return JSCValue(primitive: .boolean(abstractEqual(left, right)), context: context)
            case "!=": return JSCValue(primitive: .boolean(!abstractEqual(left, right)), context: context)
            case "===": return JSCValue(primitive: .boolean(strictEqual(left, right)), context: context)
            case "!==": return JSCValue(primitive: .boolean(!strictEqual(left, right)), context: context)
            case "<": return JSCValue(primitive: .boolean(context.toNumber(left) < context.toNumber(right)), context: context)
            case ">": return JSCValue(primitive: .boolean(context.toNumber(left) > context.toNumber(right)), context: context)
            case "<=": return JSCValue(primitive: .boolean(context.toNumber(left) <= context.toNumber(right)), context: context)
            case ">=": return JSCValue(primitive: .boolean(context.toNumber(left) >= context.toNumber(right)), context: context)
            default: return JSCValue(primitive: .undefined, context: context)
            }
        case .assign(let leftExpr, let rightExpr):
            let value = try eval(rightExpr)
            switch leftExpr {
            case .ident(let name):
                if !environment.set(name, value) {
                    environment.define(name, value)
                    context.setProperty(context.global, name, value, enumerable: true)
                } else if context.hasProperty(context.global, name) {
                    context.setProperty(context.global, name, value, enumerable: true)
                }
            case .member(let objectExpr, let name):
                let object = try eval(objectExpr)
                context.setProperty(object, name, value, enumerable: true)
            case .index(let objectExpr, let indexExpr):
                let object = try eval(objectExpr)
                let name = context.toString(try eval(indexExpr))
                context.setProperty(object, name, value, enumerable: true)
            default:
                throw JSCThrown(value: context.makeError("invalid assignment"))
            }
            return value
        case .member(let objectExpr, let name):
            return context.getProperty(try eval(objectExpr), name)
        case .index(let objectExpr, let indexExpr):
            return context.getProperty(try eval(objectExpr), context.toString(try eval(indexExpr)))
        case .call(let calleeExpr, let args):
            var thisArg: JSCValue = context.global!
            let callee: JSCValue
            switch calleeExpr {
            case .member(let objectExpr, let name):
                thisArg = try eval(objectExpr)
                callee = context.getProperty(thisArg, name)
            case .index(let objectExpr, let indexExpr):
                thisArg = try eval(objectExpr)
                callee = context.getProperty(thisArg, context.toString(try eval(indexExpr)))
            default:
                callee = try eval(calleeExpr)
            }
            return try context.call(callee, this: thisArg, arguments: try args.map { try eval($0) })
        case .construct(let calleeExpr, let args):
            return try context.construct(try eval(calleeExpr), arguments: try args.map { try eval($0) })
        case .array(let items):
            return context.makeArray(try items.map { try eval($0) })
        case .object(let pairs):
            let object = JSCValue.object(JSCObject(kind: .ordinary), context: context)
            for (key, valueExpr) in pairs {
                context.setProperty(object, key, try eval(valueExpr), enumerable: true)
            }
            return object
        case .function(let name, let params, let body):
            return makeFunction(name: name, params: params, body: body)
        case .cond(let test, let consequent, let alternate):
            return context.toBoolean(try eval(test)) ? try eval(consequent) : try eval(alternate)
        }
    }

    func strictEqual(_ left: JSCValue, _ right: JSCValue) -> Bool {
        if left.object != nil || right.object != nil {
            return left.object === right.object
        }
        switch (left.primitive, right.primitive) {
        case (.undefined, .undefined), (.null, .null): return true
        case (.boolean(let a), .boolean(let b)): return a == b
        case (.number(let a), .number(let b)): return a == b
        case (.string(let a), .string(let b)): return a == b
        case (.symbol(let a, _), .symbol(let b, _)): return a == b
        case (.bigInt(let a), .bigInt(let b)): return a == b
        default: return false
        }
    }

    func abstractEqual(_ left: JSCValue, _ right: JSCValue) -> Bool {
        if strictEqual(left, right) { return true }
        if left.isNull && right.isUndefined { return true }
        if left.isUndefined && right.isNull { return true }
        return context.toNumber(left) == context.toNumber(right)
    }
}

enum JSContextTLS {
    private static var stack: [(JSContext?, JSValue?, [Any]?, JSValue?)] = []

    static func push(context: JSContext?, this: JSValue?, arguments: [Any]?, callee: JSValue?) {
        stack.append((context, this, arguments, callee))
    }

    static func pop() {
        _ = stack.popLast()
    }

    static var current: (JSContext?, JSValue?, [Any]?, JSValue?) {
        stack.last ?? (nil, nil, nil, nil)
    }
}

func jscPointer(_ object: JSCRetainable) -> OpaquePointer {
    OpaquePointer(Unmanaged.passRetained(object).toOpaque())
}

func jscValue(_ pointer: OpaquePointer?) -> JSCValue? {
    guard let pointer else { return nil }
    return Unmanaged<JSCRetainable>.fromOpaque(UnsafeRawPointer(pointer)).takeUnretainedValue() as? JSCValue
}

func jscString(_ pointer: OpaquePointer?) -> JSCString? {
    guard let pointer else { return nil }
    return Unmanaged<JSCRetainable>.fromOpaque(UnsafeRawPointer(pointer)).takeUnretainedValue() as? JSCString
}

func jscContext(_ pointer: OpaquePointer?) -> JSCContext? {
    guard let pointer else { return nil }
    return Unmanaged<JSCRetainable>.fromOpaque(UnsafeRawPointer(pointer)).takeUnretainedValue() as? JSCContext
}

func jscGroup(_ pointer: OpaquePointer?) -> JSCGroup? {
    guard let pointer else { return nil }
    return Unmanaged<JSCRetainable>.fromOpaque(UnsafeRawPointer(pointer)).takeUnretainedValue() as? JSCGroup
}

func jscClass(_ pointer: OpaquePointer?) -> JSCClass? {
    guard let pointer else { return nil }
    return Unmanaged<JSCRetainable>.fromOpaque(UnsafeRawPointer(pointer)).takeUnretainedValue() as? JSCClass
}

func jscNames(_ pointer: OpaquePointer?) -> JSCNameArray? {
    guard let pointer else { return nil }
    return Unmanaged<JSCRetainable>.fromOpaque(UnsafeRawPointer(pointer)).takeUnretainedValue() as? JSCNameArray
}

@discardableResult
func jscRetain(_ pointer: OpaquePointer?) -> OpaquePointer? {
    guard let pointer else { return nil }
    let box = Unmanaged<JSCRetainable>.fromOpaque(UnsafeRawPointer(pointer)).takeUnretainedValue()
    box.retainCountValue += 1
    _ = Unmanaged<JSCRetainable>.fromOpaque(UnsafeRawPointer(pointer)).retain()
    return pointer
}

func jscRelease(_ pointer: OpaquePointer?) {
    guard let pointer else { return }
    let box = Unmanaged<JSCRetainable>.fromOpaque(UnsafeRawPointer(pointer)).takeUnretainedValue()
    box.retainCountValue -= 1
    Unmanaged<JSCRetainable>.fromOpaque(UnsafeRawPointer(pointer)).release()
}

func typedArrayBytesPerElement(_ type: JSTypedArrayType) -> Int {
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
        return 1
    }
}
