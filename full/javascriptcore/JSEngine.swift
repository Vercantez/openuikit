import Foundation

enum JSCJump: Error {
    case returnValue(JSCBox)
    case breakLoop
    case continueLoop
    case thrown(JSCBox)
}

final class JSCString {
    let length: Int
    let buffer: UnsafeMutablePointer<JSChar>
    private let utf8: [CChar]

    init(_ string: String) {
        let units = Array(string.utf16)
        length = units.count
        buffer = .allocate(capacity: max(length, 1))
        for (index, unit) in units.enumerated() {
            buffer[index] = unit
        }
        var bytes = Array(string.utf8CString)
        if bytes.isEmpty { bytes = [0] }
        utf8 = bytes
    }

    deinit {
        buffer.deallocate()
    }

    var swiftString: String {
        let ptr = UnsafeBufferPointer(start: buffer, count: length)
        return String(utf16CodeUnits: Array(ptr), count: length)
    }

    var utf8CString: [CChar] { utf8 }

    func isEqual(to other: JSCString) -> Bool {
        guard length == other.length else { return false }
        for index in 0..<length where buffer[index] != other.buffer[index] {
            return false
        }
        return true
    }
}

final class JSCNameArray {
    var names: [JSCString]
    init(_ names: [JSCString] = []) { self.names = names }
}

final class JSCClass {
    var definition: JSClassDefinition
    var parent: JSCClass?
    var name: String
    init(definition: JSClassDefinition, parent: JSCClass?) {
        self.definition = definition
        self.parent = parent
        if let pointer = definition.className {
            name = String(cString: pointer)
        } else {
            name = ""
        }
    }
}

enum JSCFunctionKind {
    case none
    case script(params: [String], body: JSCStmt, name: String?, environment: JSCEnvironment)
    case native((JSCCall) throws -> JSCBox)
    case cFunction(JSObjectCallAsFunctionCallback)
    case cConstructor(JSObjectCallAsConstructorCallback)
}

struct JSCCall {
    var vm: JSVirtualMachine
    var context: JSContext
    var this: JSCBox
    var args: [JSCBox]
    var callee: JSCBox
}

final class JSCObject {
    var prototype: JSCBox?
    var keys: [String] = []
    var values: [String: JSCBox] = [:]
    var attrs: [String: JSPropertyAttributes] = [:]
    var privateData: UnsafeMutableRawPointer?
    var jsClass: JSCClass?
    var function: JSCFunctionKind = .none
    var isArray = false
    var isDate = false
    var dateValue = Date(timeIntervalSince1970: 0)
    var isError = false
    var isRegExp = false
    var regexp: NSRegularExpression?
    var regexpSource = ""
    var regexpFlags = ""
    var lastIndex = 0
    var isArrayBuffer = false
    var buffer: UnsafeMutableRawPointer?
    var bufferLength = 0
    var ownsBuffer = false
    var bytesDeallocator: JSTypedArrayBytesDeallocator?
    var deallocatorContext: UnsafeMutableRawPointer?
    var typedArrayType = kJSTypedArrayTypeNone
    var byteOffset = 0
    var typedLength = 0
    var arrayBuffer: JSCObject?
    var arrayBufferBox: JSCBox?
    var didFinalize = false
    var hostObject: Any?
    var isConstructor = false
    var isPromise = false
    var promiseState = 0
    var promiseResult: JSCBox?
    var thenQueue: [(onFulfilled: JSCBox?, onRejected: JSCBox?, successor: JSCBox)] = []
    var className = "Object"

    deinit {
        if ownsBuffer, let buffer {
            if let bytesDeallocator {
                bytesDeallocator(buffer, deallocatorContext)
            } else {
                buffer.deallocate()
            }
        }
    }

    func finalizeClassIfNeeded(_ box: JSCBox) {
        guard !didFinalize else { return }
        didFinalize = true
        var current = jsClass
        var chain: [JSCClass] = []
        while let cls = current {
            chain.append(cls)
            current = cls.parent
        }
        for cls in chain {
            cls.definition.finalize?(JSCRef.unretained(box))
        }
    }

    func hasOwn(_ name: String) -> Bool { values[name] != nil }

    func getOwn(_ name: String) -> JSCBox? { values[name] }

    func setOwn(_ name: String, _ value: JSCBox, attributes: JSPropertyAttributes? = nil) {
        if values[name] == nil { keys.append(name) }
        values[name] = value
        if let attributes { attrs[name] = attributes }
    }

    func deleteOwn(_ name: String) -> Bool {
        let flags = attrs[name] ?? 0
        if flags & JSPropertyAttributes(kJSPropertyAttributeDontDelete) != 0 { return false }
        values.removeValue(forKey: name)
        attrs.removeValue(forKey: name)
        keys.removeAll { $0 == name }
        return true
    }

    func enumerableNames() -> [String] {
        keys.filter { name in
            let flags = attrs[name] ?? 0
            return flags & JSPropertyAttributes(kJSPropertyAttributeDontEnum) == 0
        }
    }
}

final class JSCBox {
    enum Payload {
        case undefined
        case null
        case boolean(Bool)
        case number(Double)
        case string(String)
        case symbol(Int, String)
        case bigInt(sign: Int, digits: String)
        case object(JSCObject)
    }

    var payload: Payload
    var interned = false
    var protectCount = 0

    init(_ payload: Payload) {
        self.payload = payload
    }

    deinit {
        object?.finalizeClassIfNeeded(self)
    }

    static let undefined = JSCBox(.undefined)
    static let null = JSCBox(.null)

    var isUndefined: Bool { if case .undefined = payload { return true }; return false }
    var isNull: Bool { if case .null = payload { return true }; return false }
    var isBoolean: Bool { if case .boolean = payload { return true }; return false }
    var isNumber: Bool { if case .number = payload { return true }; return false }
    var isString: Bool { if case .string = payload { return true }; return false }
    var isSymbol: Bool { if case .symbol = payload { return true }; return false }
    var isBigInt: Bool { if case .bigInt = payload { return true }; return false }
    var isObject: Bool { if case .object = payload { return true }; return false }

    var object: JSCObject? {
        if case .object(let object) = payload { return object }
        return nil
    }

    var jsType: JSType {
        switch payload {
        case .undefined: return kJSTypeUndefined
        case .null: return kJSTypeNull
        case .boolean: return kJSTypeBoolean
        case .number: return kJSTypeNumber
        case .string: return kJSTypeString
        case .symbol: return kJSTypeSymbol
        case .bigInt: return kJSTypeBigInt
        case .object: return kJSTypeObject
        }
    }

    func booleanValue() -> Bool {
        switch payload {
        case .undefined, .null: return false
        case .boolean(let value): return value
        case .number(let value): return value != 0 && !value.isNaN
        case .string(let value): return !value.isEmpty
        case .symbol, .bigInt, .object: return true
        }
    }

    func numberValue() -> Double {
        switch payload {
        case .undefined: return .nan
        case .null: return 0
        case .boolean(let value): return value ? 1 : 0
        case .number(let value): return value
        case .string(let value):
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { return 0 }
            return Double(trimmed) ?? .nan
        case .symbol: return .nan
        case .bigInt(let sign, let digits):
            return Double(sign) * (Double(digits) ?? .nan)
        case .object(let object):
            if object.isDate { return object.dateValue.timeIntervalSince1970 * 1000 }
            if let primitive = object.values["valueOf"] { return primitive.numberValue() }
            return .nan
        }
    }

    func stringValue() -> String {
        switch payload {
        case .undefined: return "undefined"
        case .null: return "null"
        case .boolean(let value): return value ? "true" : "false"
        case .number(let value):
            if value.isNaN { return "NaN" }
            if value == .infinity { return "Infinity" }
            if value == -.infinity { return "-Infinity" }
            if value.rounded(.towardZero) == value && abs(value) < 1e21 {
                return String(Int64(value))
            }
            return String(value)
        case .string(let value): return value
        case .symbol(_, let description): return "Symbol(\(description))"
        case .bigInt(let sign, let digits): return (sign < 0 ? "-" : "") + digits
        case .object(let object):
            if object.isArray {
                return (0..<arrayLength()).map { index in
                    object.getOwn(String(index))?.stringValue() ?? ""
                }.joined(separator: ",")
            }
            if object.isDate {
                return ISO8601DateFormatter().string(from: object.dateValue)
            }
            if object.isError {
                let name = object.getOwn("name")?.stringValue() ?? "Error"
                let message = object.getOwn("message")?.stringValue() ?? ""
                return message.isEmpty ? name : "\(name): \(message)"
            }
            if object.isRegExp {
                return "/\(object.regexpSource)/\(object.regexpFlags)"
            }
            if case .script(let params, _, let name, _) = object.function {
                let label = name ?? "anonymous"
                return "function \(label)(\(params.joined(separator: ", "))) { [native code] }"
            }
            if case .native = object.function { return "function () { [native code] }" }
            return "[object \(object.className)]"
        }
    }

    func arrayLength() -> Int {
        guard let object, object.isArray else { return 0 }
        return Int(object.getOwn("length")?.numberValue() ?? 0)
    }

    func typeofText() -> String {
        switch payload {
        case .undefined: return "undefined"
        case .null: return "object"
        case .boolean: return "boolean"
        case .number: return "number"
        case .string: return "string"
        case .symbol: return "symbol"
        case .bigInt: return "bigint"
        case .object(let object):
            switch object.function {
            case .none: return "object"
            default: return "function"
            }
        }
    }
}

final class JSCEnvironment {
    weak var parent: JSCEnvironment?
    var values: [String: JSCBox] = [:]
    var kinds: [String: JSCVarKind] = [:]
    var isFunction = false

    init(parent: JSCEnvironment?, isFunction: Bool = false) {
        self.parent = parent
        self.isFunction = isFunction
    }

    func get(_ name: String) -> JSCBox? {
        if let value = values[name] { return value }
        return parent?.get(name)
    }

    func declare(_ name: String, kind: JSCVarKind, value: JSCBox) {
        if kind == .var {
            var scope: JSCEnvironment? = self
            while let current = scope, !current.isFunction { scope = current.parent }
            (scope ?? self).values[name] = value
            (scope ?? self).kinds[name] = kind
            return
        }
        values[name] = value
        kinds[name] = kind
    }

    func set(_ name: String, _ value: JSCBox) -> Bool {
        if values[name] != nil {
            if kinds[name] == .const { return false }
            values[name] = value
            return true
        }
        if let parent {
            return parent.set(name, value)
        }
        return false
    }
}

enum JSCRef {
    static func retained(_ object: AnyObject) -> OpaquePointer {
        OpaquePointer(Unmanaged.passRetained(object).toOpaque())
    }

    static func unretained(_ object: AnyObject) -> OpaquePointer {
        OpaquePointer(Unmanaged.passUnretained(object).toOpaque())
    }

    static func takeUnretained<T: AnyObject>(_ ref: OpaquePointer?, as type: T.Type) -> T? {
        guard let ref else { return nil }
        return Unmanaged<T>.fromOpaque(UnsafeRawPointer(ref)).takeUnretainedValue()
    }

    static func retain(_ ref: OpaquePointer?) -> OpaquePointer? {
        guard let ref else { return nil }
        _ = Unmanaged<AnyObject>.fromOpaque(UnsafeRawPointer(ref)).retain()
        return ref
    }

    static func release(_ ref: OpaquePointer?) {
        guard let ref else { return }
        Unmanaged<AnyObject>.fromOpaque(UnsafeRawPointer(ref)).release()
    }
}

enum JSCThread {
    private static let contextKey = "JavaScriptCore.JSContext.current"
    private static let thisKey = "JavaScriptCore.JSContext.currentThis"
    private static let calleeKey = "JavaScriptCore.JSContext.currentCallee"
    private static let argsKey = "JavaScriptCore.JSContext.currentArguments"

    static var context: JSContext? {
        get { Thread.current.threadDictionary[contextKey] as? JSContext }
        set { store(contextKey, newValue) }
    }

    static var thisValue: JSValue? {
        get { Thread.current.threadDictionary[thisKey] as? JSValue }
        set { store(thisKey, newValue) }
    }

    static var callee: JSValue? {
        get { Thread.current.threadDictionary[calleeKey] as? JSValue }
        set { store(calleeKey, newValue) }
    }

    static var arguments: [Any]? {
        get { Thread.current.threadDictionary[argsKey] as? [Any] }
        set { store(argsKey, newValue) }
    }

    private static func store(_ key: String, _ value: Any?) {
        if let value {
            Thread.current.threadDictionary[key] = value
        } else {
            Thread.current.threadDictionary.removeObject(forKey: key)
        }
    }
}

enum JSCBigInt {
    static func fromDecimal(_ text: String) -> (sign: Int, digits: String)? {
        var s = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return nil }
        var sign = 1
        if s.hasPrefix("-") {
            sign = -1
            s.removeFirst()
        } else if s.hasPrefix("+") {
            s.removeFirst()
        }
        if s.hasSuffix("n") { s.removeLast() }
        guard !s.isEmpty, s.allSatisfy(\.isNumber) else { return nil }
        while s.count > 1 && s.hasPrefix("0") { s.removeFirst() }
        if s == "0" { sign = 1 }
        return (sign, s)
    }

    static func fromInt64(_ value: Int64) -> (Int, String) {
        if value < 0 { return (-1, String(-value)) }
        return (1, String(value))
    }

    static func fromUInt64(_ value: UInt64) -> (Int, String) {
        (1, String(value))
    }

    static func fromDouble(_ value: Double) -> (Int, String)? {
        guard value.isFinite else { return nil }
        let truncated = value.rounded(.towardZero)
        if truncated < Double(Int64.min) || truncated > Double(Int64.max) {
            let sign = truncated < 0 ? -1 : 1
            let digits = String(format: "%.0f", abs(truncated))
            return (sign, digits)
        }
        return fromInt64(Int64(truncated))
    }

    static func compare(_ left: (Int, String), _ right: (Int, String)) -> JSRelationCondition {
        if left.0 != right.0 {
            if left.1 == "0" && right.1 == "0" { return .equal }
            return left.0 < 0 ? .lessThan : .greaterThan
        }
        if left.1.count != right.1.count {
            let longerIsGreater = left.1.count > right.1.count
            if left.0 < 0 {
                return longerIsGreater ? .lessThan : .greaterThan
            }
            return longerIsGreater ? .greaterThan : .lessThan
        }
        if left.1 == right.1 { return .equal }
        let digitsGreater = left.1 > right.1
        if left.0 < 0 {
            return digitsGreater ? .lessThan : .greaterThan
        }
        return digitsGreater ? .greaterThan : .lessThan
    }
}

struct JSCEngineError: Error, CustomStringConvertible {
    var message: String
    var description: String { message }
}

enum JSCJSON {
    static func stringify(_ box: JSCBox, indent: UInt32) throws -> String {
        let object = try jsonObject(box)
        if indent == 0 {
            let data = try JSONSerialization.data(withJSONObject: object, options: [.fragmentsAllowed])
            return String(data: data, encoding: .utf8) ?? "null"
        }
        let data = try JSONSerialization.data(
            withJSONObject: object,
            options: [.fragmentsAllowed, .prettyPrinted]
        )
        return String(data: data, encoding: .utf8) ?? "null"
    }

    static func parse(_ text: String) throws -> Any {
        guard let data = text.data(using: .utf8) else {
            throw JSCEngineError(message: "JSON.parse input is not UTF-8")
        }
        return try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
    }

    private static func jsonObject(_ box: JSCBox) throws -> Any {
        switch box.payload {
        case .undefined, .symbol:
            throw JSCEngineError(message: "JSON.stringify cannot encode this value")
        case .null: return NSNull()
        case .boolean(let value): return value
        case .number(let value):
            if !value.isFinite { return NSNull() }
            return value
        case .string(let value): return value
        case .bigInt:
            throw JSCEngineError(message: "JSON.stringify cannot encode BigInt")
        case .object(let object):
            if object.isArray {
                return (0..<box.arrayLength()).map { index -> Any in
                    (try? jsonObject(object.getOwn(String(index)) ?? .undefined)) ?? NSNull()
                }
            }
            var dict: [String: Any] = [:]
            for name in object.enumerableNames() {
                guard let value = object.getOwn(name), !value.isUndefined, !value.isSymbol else { continue }
                dict[name] = (try? jsonObject(value)) ?? NSNull()
            }
            return dict
        }
    }
}
