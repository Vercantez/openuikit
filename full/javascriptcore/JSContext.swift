import CoreFoundation
import Foundation

public final class JSVirtualMachine: NSObject {
    let group: JSCGroup
    private var managed: [(owner: ObjectIdentifier, object: AnyObject)] = []

    public override init() {
        self.group = JSCGroup()
        super.init()
    }

    public func addManagedReference(_ object: Any!, withOwner owner: Any!) {
        guard let object = object as AnyObject?, let owner = owner as AnyObject? else { return }
        managed.append((ObjectIdentifier(owner), object))
    }

    public func removeManagedReference(_ object: Any!, withOwner owner: Any!) {
        guard let object = object as AnyObject?, let owner = owner as AnyObject? else { return }
        let ownerId = ObjectIdentifier(owner)
        let objectId = ObjectIdentifier(object)
        managed.removeAll { $0.owner == ownerId && ObjectIdentifier($0.object) == objectId }
    }
}

public final class JSManagedValue: NSObject {
    private weak var stored: JSValue?
    private var owned: JSValue?

    public init!(value: JSValue!) {
        self.owned = value
        self.stored = value
        super.init()
    }

    public init!(value: JSValue!, andOwner owner: Any!) {
        _ = owner
        self.stored = value
        super.init()
    }

    public var value: JSValue! { stored ?? owned }
}

public final class JSContext: NSObject {
    public let virtualMachine: JSVirtualMachine!
    let engine: JSCContext
    public var exception: JSValue!
    public var exceptionHandler: ((JSContext?, JSValue?) -> Void)!
    public var name: String! {
        get { engine.name }
        set { engine.name = newValue ?? "" }
    }
    public var isInspectable: Bool {
        get { engine.inspectable }
        set { engine.inspectable = newValue }
    }

    public override init() {
        let vm = JSVirtualMachine()
        self.virtualMachine = vm
        self.engine = JSCContext(group: vm.group)
        super.init()
        engine.overlay = self
    }

    public init!(virtualMachine: JSVirtualMachine!) {
        let vm = virtualMachine ?? JSVirtualMachine()
        self.virtualMachine = vm
        self.engine = JSCContext(group: vm.group)
        super.init()
        engine.overlay = self
    }

    public init!(JSGlobalContextRef jsGlobalContextRef: JSGlobalContextRef!) {
        guard let context = jscContext(jsGlobalContextRef) else {
            self.virtualMachine = JSVirtualMachine()
            self.engine = JSCContext(group: self.virtualMachine.group)
            super.init()
            engine.overlay = self
            return
        }
        let vm = JSVirtualMachine()
        // Share the existing group by retaining the provided context.
        self.virtualMachine = vm
        self.engine = context
        super.init()
        engine.overlay = self
    }

    public var jsGlobalContextRef: JSGlobalContextRef! { jscPointer(engine) }

    public var globalObject: JSValue! {
        JSValue(engineValue: engine.global, context: self)
    }

    public func evaluateScript(_ script: String!) -> JSValue! {
        evaluateScript(script, withSourceURL: nil)
    }

    public func evaluateScript(_ script: String!, withSourceURL sourceURL: URL!) -> JSValue! {
        JSContextTLS.push(context: self, this: globalObject, arguments: nil, callee: nil)
        defer { JSContextTLS.pop() }
        let result = engine.evaluate(script ?? "", this: engine.global, sourceURL: sourceURL?.absoluteString, startingLine: 1)
        if let thrown = engine.exception {
            let jsThrown = JSValue(engineValue: thrown, context: self)
            exception = jsThrown
            exceptionHandler?(self, jsThrown)
            return JSValue(undefinedIn: self)
        }
        exception = nil
        return JSValue(engineValue: result, context: self)
    }

    public func objectForKeyedSubscript(_ key: Any!) -> JSValue! {
        let name = stringifyKey(key)
        return JSValue(engineValue: engine.getProperty(engine.global, name), context: self)
    }

    public func setObject(_ object: Any!, forKeyedSubscript key: (any NSCopying & NSObjectProtocol)!) {
        let name = stringifyKey(key)
        engine.setProperty(engine.global, name, engineValue(from: object, functionName: name), enumerable: true)
    }

    public class func current() -> JSContext! { JSContextTLS.current.0 }
    public class func currentThis() -> JSValue! { JSContextTLS.current.1 }
    public class func currentArguments() -> [Any]! { JSContextTLS.current.2 }
    public class func currentCallee() -> JSValue! { JSContextTLS.current.3 }

    func engineValue(from object: Any?, functionName: String = "host") -> JSCValue {
        guard let object else { return JSCValue(primitive: .null, context: engine) }
        if object is NSNull { return JSCValue(primitive: .null, context: engine) }
        if let value = object as? JSValue { return value.engineValue }
        if let fn = makeHostFunction(from: object, name: functionName) { return fn }
        if let flag = object as? Bool { return JSCValue(primitive: .boolean(flag), context: engine) }
        if let number = object as? NSNumber {
            let typeID = CFGetTypeID(number)
            if typeID == CFBooleanGetTypeID() {
                return JSCValue(primitive: .boolean(number.boolValue), context: engine)
            }
            return JSCValue(primitive: .number(number.doubleValue), context: engine)
        }
        if let value = object as? Double { return JSCValue(primitive: .number(value), context: engine) }
        if let value = object as? Float { return JSCValue(primitive: .number(Double(value)), context: engine) }
        if let value = object as? Int { return JSCValue(primitive: .number(Double(value)), context: engine) }
        if let value = object as? Int32 { return JSCValue(primitive: .number(Double(value)), context: engine) }
        if let value = object as? UInt32 { return JSCValue(primitive: .number(Double(value)), context: engine) }
        if let value = object as? Int64 { return JSCValue(primitive: .number(Double(value)), context: engine) }
        if let value = object as? UInt64 { return JSCValue(primitive: .number(Double(value)), context: engine) }
        if let string = object as? String { return JSCValue(primitive: .string(string), context: engine) }
        if let date = object as? Date {
            let jsObject = JSCObject(kind: .date)
            jsObject.date = date
            return JSCValue.object(jsObject, context: engine)
        }
        if let array = object as? [Any] { return engine.makeArray(array.map { engineValue(from: $0) }) }
        if let dict = object as? [AnyHashable: Any] {
            let jsObject = JSCValue.object(JSCObject(kind: .ordinary), context: engine)
            for (key, value) in dict {
                engine.setProperty(jsObject, String(describing: key), engineValue(from: value), enumerable: true)
            }
            return jsObject
        }
        return JSCValue(primitive: .undefined, context: engine)
    }

    /// Swift closure bridge used where the port has no ObjC JSExport class export.
    /// Accepted signatures: `() -> Any`, `(Any) -> Any`, `(Any, Any) -> Any`,
    /// `(Any, Any, Any) -> Any`, `([Any]) -> Any`.
    func makeHostFunction(from object: Any, name: String) -> JSCValue? {
        if let block = object as? ([Any]) -> Any {
            return engine.makeNativeFunction(name) { [weak self] args, _, _ in
                guard let self else { return JSCValue(primitive: .undefined, context: nil) }
                let bridged = args.map { JSValue(engineValue: $0, context: self) as Any }
                return self.engineValue(from: block(bridged))
            }
        }
        if let block = object as? () -> Any {
            return engine.makeNativeFunction(name) { [weak self] _, _, _ in
                guard let self else { return JSCValue(primitive: .undefined, context: nil) }
                return self.engineValue(from: block())
            }
        }
        if let block = object as? (Any) -> Any {
            return engine.makeNativeFunction(name) { [weak self] args, _, _ in
                guard let self else { return JSCValue(primitive: .undefined, context: nil) }
                let arg: Any = args.first.map { JSValue(engineValue: $0, context: self) as Any } ?? NSNull()
                return self.engineValue(from: block(arg))
            }
        }
        if let block = object as? (Any, Any) -> Any {
            return engine.makeNativeFunction(name) { [weak self] args, _, _ in
                guard let self else { return JSCValue(primitive: .undefined, context: nil) }
                func arg(_ index: Int) -> Any {
                    index < args.count ? JSValue(engineValue: args[index], context: self) as Any : NSNull()
                }
                return self.engineValue(from: block(arg(0), arg(1)))
            }
        }
        if let block = object as? (Any, Any, Any) -> Any {
            return engine.makeNativeFunction(name) { [weak self] args, _, _ in
                guard let self else { return JSCValue(primitive: .undefined, context: nil) }
                func arg(_ index: Int) -> Any {
                    index < args.count ? JSValue(engineValue: args[index], context: self) as Any : NSNull()
                }
                return self.engineValue(from: block(arg(0), arg(1), arg(2)))
            }
        }
        return nil
    }
}

private func stringifyKey(_ key: Any?) -> String {
    if let string = key as? String { return string }
    if let value = key as? JSValue { return value.toString() }
    if let key { return String(describing: key) }
    return ""
}

public final class JSValue: NSObject {
    public unowned(unsafe) var context: JSContext!
    let engineValue: JSCValue

    init(engineValue: JSCValue, context: JSContext) {
        self.engineValue = engineValue
        self.context = context
        super.init()
    }

    public init!(JSValueRef value: JSValueRef!, inContext context: JSContext!) {
        guard let context, let jsValue = jscValue(value) else {
            return nil
        }
        self.context = context
        self.engineValue = jsValue
        super.init()
    }

    public var jsValueRef: JSValueRef! { jscPointer(engineValue) }

    public override var description: String {
        guard context != nil else { return super.description }
        return context.engine.toString(engineValue)
    }

    public convenience init!(bool value: Bool, in context: JSContext!) {
        self.init(bool: value, inContext: context)
    }
    public init!(bool value: Bool, inContext context: JSContext!) {
        guard let context else { return nil }
        self.context = context
        self.engineValue = JSCValue(primitive: .boolean(value), context: context.engine)
        super.init()
    }

    public convenience init!(double value: Double, in context: JSContext!) {
        self.init(double: value, inContext: context)
    }
    public init!(double value: Double, inContext context: JSContext!) {
        guard let context else { return nil }
        self.context = context
        self.engineValue = JSCValue(primitive: .number(value), context: context.engine)
        super.init()
    }

    public convenience init!(int32 value: Int32, in context: JSContext!) {
        self.init(int32: value, inContext: context)
    }
    public convenience init!(int32 value: Int32, inContext context: JSContext!) {
        self.init(double: Double(value), inContext: context)
    }

    public convenience init!(uInt32 value: UInt32, in context: JSContext!) {
        self.init(UInt32: value, inContext: context)
    }
    public convenience init!(UInt32 value: UInt32, inContext context: JSContext!) {
        self.init(double: Double(value), inContext: context)
    }

    public convenience init!(undefinedIn context: JSContext!) {
        self.init(undefinedInContext: context)
    }
    public init!(undefinedInContext context: JSContext!) {
        guard let context else { return nil }
        self.context = context
        self.engineValue = JSCValue(primitive: .undefined, context: context.engine)
        super.init()
    }

    public convenience init!(nullIn context: JSContext!) {
        self.init(nullInContext: context)
    }
    public init!(nullInContext context: JSContext!) {
        guard let context else { return nil }
        self.context = context
        self.engineValue = JSCValue(primitive: .null, context: context.engine)
        super.init()
    }

    public convenience init!(newObjectIn context: JSContext!) {
        self.init(newObjectInContext: context)
    }
    public init!(newObjectInContext context: JSContext!) {
        guard let context else { return nil }
        self.context = context
        self.engineValue = JSCValue.object(JSCObject(kind: .ordinary), context: context.engine)
        super.init()
    }

    public convenience init!(newArrayIn context: JSContext!) {
        self.init(newArrayInContext: context)
    }
    public init!(newArrayInContext context: JSContext!) {
        guard let context else { return nil }
        self.context = context
        self.engineValue = context.engine.makeArray([])
        super.init()
    }

    public convenience init!(object value: Any!, in context: JSContext!) {
        self.init(object: value, inContext: context)
    }
    public init!(object value: Any!, inContext context: JSContext!) {
        guard let context else { return nil }
        self.context = context
        self.engineValue = context.engineValue(from: value)
        super.init()
    }

    public convenience init!(newErrorFromMessage message: String!, in context: JSContext!) {
        self.init(newErrorFromMessage: message, inContext: context)
    }
    public init!(newErrorFromMessage message: String!, inContext context: JSContext!) {
        guard let context else { return nil }
        self.context = context
        self.engineValue = context.engine.makeError(message ?? "")
        super.init()
    }

    public convenience init!(newRegularExpressionFromPattern pattern: String!, flags: String!, in context: JSContext!) {
        self.init(newRegularExpressionFromPattern: pattern, flags: flags, inContext: context)
    }
    public init!(newRegularExpressionFromPattern pattern: String!, flags: String!, inContext context: JSContext!) {
        guard let context else { return nil }
        self.context = context
        let object = JSCObject(kind: .regexp)
        object.regexp = (pattern ?? "", flags ?? "")
        self.engineValue = JSCValue.object(object, context: context.engine)
        super.init()
    }

    public convenience init!(newSymbolFromDescription description: String!, in context: JSContext!) {
        self.init(newSymbolFromDescription: description, inContext: context)
    }
    public init!(newSymbolFromDescription description: String!, inContext context: JSContext!) {
        guard let context else { return nil }
        self.context = context
        self.engineValue = JSCValue(
            primitive: .symbol(id: context.engine.makeSymbolId(), description: description ?? ""),
            context: context.engine
        )
        super.init()
    }

    public convenience init?(newBigIntFrom value: Double, in context: JSContext) {
        self.init(newBigIntFromDouble: value, inContext: context)
    }
    public init?(newBigIntFromDouble value: Double, inContext context: JSContext) {
        guard value.isFinite else { return nil }
        self.context = context
        self.engineValue = JSCValue(primitive: .bigInt(String(Int64(value))), context: context.engine)
        super.init()
    }

    public convenience init?(newBigIntFrom int64: Int64, in context: JSContext) {
        self.init(newBigIntFromInt64: int64, inContext: context)
    }
    public init?(newBigIntFromInt64 int64: Int64, inContext context: JSContext) {
        self.context = context
        self.engineValue = JSCValue(primitive: .bigInt(String(int64)), context: context.engine)
        super.init()
    }

    public convenience init?(newBigIntFrom uint64: UInt64, in context: JSContext) {
        self.init(newBigIntFromUInt64: uint64, inContext: context)
    }
    public init?(newBigIntFromUInt64 uint64: UInt64, inContext context: JSContext) {
        self.context = context
        self.engineValue = JSCValue(primitive: .bigInt(String(uint64)), context: context.engine)
        super.init()
    }

    public convenience init?(newBigIntFrom string: String, in context: JSContext) {
        self.init(newBigIntFromString: string, inContext: context)
    }
    public init?(newBigIntFromString string: String, inContext context: JSContext) {
        guard !string.isEmpty else { return nil }
        self.context = context
        self.engineValue = JSCValue(primitive: .bigInt(string), context: context.engine)
        super.init()
    }

    public convenience init!(newPromiseIn context: JSContext!, fromExecutor callback: ((JSValue?, JSValue?) -> Void)!) {
        self.init(newPromiseInContext: context, fromExecutor: callback)
    }
    public init!(newPromiseInContext context: JSContext!, fromExecutor callback: ((JSValue?, JSValue?) -> Void)!) {
        guard let context else { return nil }
        self.context = context
        var resolveRef: JSObjectRef?
        var rejectRef: JSObjectRef?
        var exception: JSValueRef?
        let promise = JSObjectMakeDeferredPromise(context.jsGlobalContextRef, &resolveRef, &rejectRef, &exception)
        self.engineValue = jscValue(promise) ?? JSCValue.object(JSCObject(kind: .promise), context: context.engine)
        super.init()
        let resolve = JSValue(JSValueRef: resolveRef, inContext: context)
        let reject = JSValue(JSValueRef: rejectRef, inContext: context)
        callback?(resolve, reject)
    }

    public convenience init!(newPromiseResolvedWithResult result: Any!, in context: JSContext!) {
        self.init(newPromiseResolvedWithResult: result, inContext: context)
    }
    public convenience init!(newPromiseResolvedWithResult result: Any!, inContext context: JSContext!) {
        self.init(newPromiseInContext: context, fromExecutor: { resolve, _ in
            _ = resolve?.call(withArguments: [result as Any])
        })
    }

    public convenience init!(newPromiseRejectedWithReason reason: Any!, in context: JSContext!) {
        self.init(newPromiseRejectedWithReason: reason, inContext: context)
    }
    public convenience init!(newPromiseRejectedWithReason reason: Any!, inContext context: JSContext!) {
        self.init(newPromiseInContext: context, fromExecutor: { _, reject in
            _ = reject?.call(withArguments: [reason as Any])
        })
    }

    public init!(point: CGPoint, inContext context: JSContext!) {
        guard let context else { return nil }
        self.context = context
        let object = JSCValue.object(JSCObject(kind: .ordinary), context: context.engine)
        context.engine.setProperty(object, "x", JSCValue(primitive: .number(Double(point.x)), context: context.engine), enumerable: true)
        context.engine.setProperty(object, "y", JSCValue(primitive: .number(Double(point.y)), context: context.engine), enumerable: true)
        self.engineValue = object
        super.init()
    }

    public init!(size: CGSize, inContext context: JSContext!) {
        guard let context else { return nil }
        self.context = context
        let object = JSCValue.object(JSCObject(kind: .ordinary), context: context.engine)
        context.engine.setProperty(object, "width", JSCValue(primitive: .number(Double(size.width)), context: context.engine), enumerable: true)
        context.engine.setProperty(object, "height", JSCValue(primitive: .number(Double(size.height)), context: context.engine), enumerable: true)
        self.engineValue = object
        super.init()
    }

    public init!(rect: CGRect, inContext context: JSContext!) {
        guard let context else { return nil }
        self.context = context
        let object = JSCValue.object(JSCObject(kind: .ordinary), context: context.engine)
        context.engine.setProperty(object, "x", JSCValue(primitive: .number(Double(rect.origin.x)), context: context.engine), enumerable: true)
        context.engine.setProperty(object, "y", JSCValue(primitive: .number(Double(rect.origin.y)), context: context.engine), enumerable: true)
        context.engine.setProperty(object, "width", JSCValue(primitive: .number(Double(rect.size.width)), context: context.engine), enumerable: true)
        context.engine.setProperty(object, "height", JSCValue(primitive: .number(Double(rect.size.height)), context: context.engine), enumerable: true)
        self.engineValue = object
        super.init()
    }

    public init!(range: NSRange, inContext context: JSContext!) {
        guard let context else { return nil }
        self.context = context
        let object = JSCValue.object(JSCObject(kind: .ordinary), context: context.engine)
        context.engine.setProperty(object, "location", JSCValue(primitive: .number(Double(range.location)), context: context.engine), enumerable: true)
        context.engine.setProperty(object, "length", JSCValue(primitive: .number(Double(range.length)), context: context.engine), enumerable: true)
        self.engineValue = object
        super.init()
    }

    public var isUndefined: Bool { engineValue.isUndefined }
    public var isNull: Bool { engineValue.isNull }
    public var isBoolean: Bool {
        if engineValue.object != nil { return false }
        if case .boolean = engineValue.primitive { return true }
        return false
    }
    public var isNumber: Bool {
        if engineValue.object != nil { return false }
        if case .number = engineValue.primitive { return true }
        return false
    }
    public var isString: Bool {
        if engineValue.object != nil { return false }
        if case .string = engineValue.primitive { return true }
        return false
    }
    public var isObject: Bool { engineValue.isObject }
    public var isArray: Bool { engineValue.object?.kind == .array }
    public var isDate: Bool { engineValue.object?.kind == .date }
    public var isSymbol: Bool {
        if engineValue.object != nil { return false }
        if case .symbol = engineValue.primitive { return true }
        return false
    }
    public var isBigInt: Bool {
        if engineValue.object != nil { return false }
        if case .bigInt = engineValue.primitive { return true }
        return false
    }

    public func toBool() -> Bool { context.engine.toBoolean(engineValue) }
    public func toDouble() -> Double { context.engine.toNumber(engineValue) }
    public func toInt32() -> Int32 {
        let number = toDouble()
        guard number.isFinite else { return 0 }
        return Int32(truncatingIfNeeded: Int64(number))
    }
    public func toUInt32() -> UInt32 {
        let number = toDouble()
        guard number.isFinite else { return 0 }
        return UInt32(truncatingIfNeeded: Int64(number))
    }
    public func toInt64() -> Int64 {
        let number = toDouble()
        guard number.isFinite else { return 0 }
        return Int64(number)
    }
    public func toUInt64() -> UInt64 {
        let number = toDouble()
        guard number.isFinite else { return 0 }
        return UInt64(number)
    }
    public func toNumber() -> NSNumber! { NSNumber(value: toDouble()) }
    public func toString() -> String! { context.engine.toString(engineValue) }
    public func toDate() -> Date! { engineValue.object?.date ?? Date(timeIntervalSince1970: toDouble() / 1000) }
    public func toArray() -> [Any]! {
        guard isArray else { return nil }
        let length = Int(context.engine.toNumber(context.engine.getProperty(engineValue, "length")))
        return (0..<max(length, 0)).map { atIndex($0)?.toObject() as Any }
    }
    public func toDictionary() -> [AnyHashable: Any]! {
        guard isObject else { return nil }
        var dict: [AnyHashable: Any] = [:]
        for name in context.engine.propertyNames(engineValue) {
            dict[name] = forProperty(name)?.toObject()
        }
        return dict
    }
    public func toObject() -> Any! {
        if isUndefined || isNull { return nil }
        if isBoolean { return NSNumber(value: toBool()) }
        if isNumber { return NSNumber(value: toDouble()) }
        if isString { return toString() as NSString }
        if isDate { return (engineValue.object?.date ?? Date()) as NSDate }
        if isArray { return toArray() as NSArray }
        if isObject { return toDictionary() as NSDictionary }
        return toString() as NSString
    }
    public func toObjectOf(_ expectedClass: AnyClass!) -> Any! {
        let object = toObject()
        guard let expectedClass, let object else { return nil }
        if let nsObject = object as? NSObject {
            return nsObject.isKind(of: expectedClass) ? object : nil
        }
        return nil
    }
    public func toPoint() -> CGPoint {
        CGPoint(
            x: forProperty("x")?.toDouble() ?? 0,
            y: forProperty("y")?.toDouble() ?? 0
        )
    }
    public func toSize() -> CGSize {
        CGSize(
            width: forProperty("width")?.toDouble() ?? 0,
            height: forProperty("height")?.toDouble() ?? 0
        )
    }
    public func toRect() -> CGRect {
        CGRect(origin: toPoint(), size: toSize())
    }
    public func toRange() -> NSRange {
        NSRange(
            location: Int(forProperty("location")?.toDouble() ?? 0),
            length: Int(forProperty("length")?.toDouble() ?? 0)
        )
    }

    public func forProperty(_ property: Any!) -> JSValue! {
        JSValue(engineValue: context.engine.getProperty(engineValue, stringifyKey(property)), context: context)
    }
    public func setValue(_ value: Any!, forProperty property: Any!) {
        context.engine.setProperty(engineValue, stringifyKey(property), context.engineValue(from: value), enumerable: true)
    }
    public func deleteProperty(_ property: Any!) -> Bool {
        context.engine.deleteProperty(engineValue, stringifyKey(property))
    }
    public func hasProperty(_ property: Any!) -> Bool {
        context.engine.hasProperty(engineValue, stringifyKey(property))
    }
    public func defineProperty(_ property: Any!, descriptor: Any!) {
        guard let dict = (descriptor as? [AnyHashable: Any]) ?? (descriptor as? JSValue)?.toDictionary() else { return }
        var stored = JSCProperty(
            value: context.engineValue(from: dict[JSPropertyDescriptorValueKey]),
            writable: (dict[JSPropertyDescriptorWritableKey] as? Bool) ?? true,
            enumerable: (dict[JSPropertyDescriptorEnumerableKey] as? Bool) ?? true,
            configurable: (dict[JSPropertyDescriptorConfigurableKey] as? Bool) ?? true
        )
        if let getter = dict[JSPropertyDescriptorGetKey] {
            stored.getter = context.engineValue(from: getter)
        }
        if let setter = dict[JSPropertyDescriptorSetKey] {
            stored.setter = context.engineValue(from: setter)
        }
        engineValue.object?.properties[stringifyKey(property)] = stored
    }

    public func atIndex(_ index: Int) -> JSValue! { forProperty(String(index)) }
    public func setValue(_ value: Any!, at index: Int) { setValue(value, forProperty: String(index)) }
    public func objectAtIndexedSubscript(_ index: Int) -> JSValue! { atIndex(index) }
    public func setObject(_ object: Any!, atIndexedSubscript index: Int) { setValue(object, at: index) }
    public func objectForKeyedSubscript(_ key: Any!) -> JSValue! { forProperty(key) }
    public func setObject(_ object: Any!, forKeyedSubscript key: Any!) { setValue(object, forProperty: key) }

    public func call(withArguments arguments: [Any]!) -> JSValue! {
        do {
            let args = (arguments ?? []).map { context.engineValue(from: $0) }
            let result = try context.engine.call(engineValue, this: context.engine.global, arguments: args)
            return JSValue(engineValue: result, context: context)
        } catch let thrown as JSCThrown {
            context.exception = JSValue(engineValue: thrown.value, context: context)
            context.exceptionHandler?(context, context.exception)
            return JSValue(undefinedIn: context)
        } catch {
            return JSValue(undefinedIn: context)
        }
    }

    public func construct(withArguments arguments: [Any]!) -> JSValue! {
        do {
            let args = (arguments ?? []).map { context.engineValue(from: $0) }
            return JSValue(engineValue: try context.engine.construct(engineValue, arguments: args), context: context)
        } catch let thrown as JSCThrown {
            context.exception = JSValue(engineValue: thrown.value, context: context)
            return JSValue(undefinedIn: context)
        } catch {
            return JSValue(undefinedIn: context)
        }
    }

    public func invokeMethod(_ method: String!, withArguments arguments: [Any]!) -> JSValue! {
        let function = forProperty(method)!
        do {
            let args = (arguments ?? []).map { context.engineValue(from: $0) }
            let result = try context.engine.call(function.engineValue, this: engineValue, arguments: args)
            return JSValue(engineValue: result, context: context)
        } catch let thrown as JSCThrown {
            context.exception = JSValue(engineValue: thrown.value, context: context)
            return JSValue(undefinedIn: context)
        } catch {
            return JSValue(undefinedIn: context)
        }
    }

#if os(Linux)
    public func isEqual(to value: Any!) -> Bool {
        let other = context.engineValue(from: value)
        return JSCInterpreter(context: context.engine, environment: JSCEnvironment(parent: nil)).strictEqual(engineValue, other)
    }
#else
    public override func isEqual(to value: Any!) -> Bool {
        let other = context.engineValue(from: value)
        return JSCInterpreter(context: context.engine, environment: JSCEnvironment(parent: nil)).strictEqual(engineValue, other)
    }
#endif

    public func isEqualWithTypeCoercion(to value: Any!) -> Bool {
        let other = context.engineValue(from: value)
        return JSCInterpreter(context: context.engine, environment: JSCEnvironment(parent: nil)).abstractEqual(engineValue, other)
    }

    public func isInstance(of value: Any!) -> Bool {
        JSValueIsInstanceOfConstructor(context.jsGlobalContextRef, jsValueRef, JSValue(object: value, in: context).jsValueRef, nil)
    }

    public func compare(_ other: JSValue) -> JSRelationCondition {
        JSValueCompare(context.jsGlobalContextRef, jsValueRef, other.jsValueRef, nil)
    }
    public func compare(_ other: Double) -> JSRelationCondition {
        JSValueCompareDouble(context.jsGlobalContextRef, jsValueRef, other, nil)
    }
    public func compare(_ other: Int64) -> JSRelationCondition {
        JSValueCompareInt64(context.jsGlobalContextRef, jsValueRef, other, nil)
    }
    public func compare(_ other: UInt64) -> JSRelationCondition {
        JSValueCompareUInt64(context.jsGlobalContextRef, jsValueRef, other, nil)
    }
}
