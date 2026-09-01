import Foundation

public final class JSValue: NSObject {
    public var context: JSContext!
    var box: JSCBox

    public var jsValueRef: JSValueRef! { JSCRef.unretained(box) }

    init(box: JSCBox, in context: JSContext) {
        self.box = context.intern(box)
        self.context = context
        super.init()
    }

    public init!(bool value: Bool, in context: JSContext!) {
        guard let context else { return nil }
        self.context = context
        self.box = context.intern(JSCBox(.boolean(value)))
        super.init()
    }

    public init!(bool value: Bool, inContext context: JSContext!) {
        guard let context else { return nil }
        self.context = context
        self.box = context.intern(JSCBox(.boolean(value)))
        super.init()
    }

    public init!(double value: Double, in context: JSContext!) {
        guard let context else { return nil }
        self.context = context
        self.box = context.intern(JSCBox(.number(value)))
        super.init()
    }

    public init!(double value: Double, inContext context: JSContext!) {
        guard let context else { return nil }
        self.context = context
        self.box = context.intern(JSCBox(.number(value)))
        super.init()
    }

    public init!(int32 value: Int32, in context: JSContext!) {
        guard let context else { return nil }
        self.context = context
        self.box = context.intern(JSCBox(.number(Double(value))))
        super.init()
    }

    public init!(int32 value: Int32, inContext context: JSContext!) {
        guard let context else { return nil }
        self.context = context
        self.box = context.intern(JSCBox(.number(Double(value))))
        super.init()
    }

    public init!(JSValueRef value: JSValueRef!, inContext context: JSContext!) {
        guard let context else { return nil }
        self.context = context
        self.box = JSCRef.takeUnretained(value, as: JSCBox.self) ?? .undefined
        super.init()
    }

    public init!(newArrayIn context: JSContext!) {
        guard let context else { return nil }
        self.context = context
        self.box = context.makeArray()
        super.init()
    }

    public init!(newArrayInContext context: JSContext!) {
        guard let context else { return nil }
        self.context = context
        self.box = context.makeArray()
        super.init()
    }

    public init?(newBigIntFrom value: Double, in context: JSContext) {
        guard let pair = JSCBigInt.fromDouble(value) else { return nil }
        self.context = context
        self.box = context.intern(JSCBox(.bigInt(sign: pair.0, digits: pair.1)))
        super.init()
    }

    public init?(newBigIntFromDouble value: Double, inContext context: JSContext) {
        guard let pair = JSCBigInt.fromDouble(value) else { return nil }
        self.context = context
        self.box = context.intern(JSCBox(.bigInt(sign: pair.0, digits: pair.1)))
        super.init()
    }

    public init?(newBigIntFrom int64: Int64, in context: JSContext) {
        let pair = JSCBigInt.fromInt64(int64)
        self.context = context
        self.box = context.intern(JSCBox(.bigInt(sign: pair.0, digits: pair.1)))
        super.init()
    }

    public init?(newBigIntFromInt64 int64: Int64, inContext context: JSContext) {
        let pair = JSCBigInt.fromInt64(int64)
        self.context = context
        self.box = context.intern(JSCBox(.bigInt(sign: pair.0, digits: pair.1)))
        super.init()
    }

    public init?(newBigIntFrom string: String, in context: JSContext) {
        guard let pair = JSCBigInt.fromDecimal(string) else { return nil }
        self.context = context
        self.box = context.intern(JSCBox(.bigInt(sign: pair.0, digits: pair.1)))
        super.init()
    }

    public init?(newBigIntFromString string: String, inContext context: JSContext) {
        guard let pair = JSCBigInt.fromDecimal(string) else { return nil }
        self.context = context
        self.box = context.intern(JSCBox(.bigInt(sign: pair.0, digits: pair.1)))
        super.init()
    }

    public init?(newBigIntFrom uint64: UInt64, in context: JSContext) {
        let pair = JSCBigInt.fromUInt64(uint64)
        self.context = context
        self.box = context.intern(JSCBox(.bigInt(sign: pair.0, digits: pair.1)))
        super.init()
    }

    public init?(newBigIntFromUInt64 uint64: UInt64, inContext context: JSContext) {
        let pair = JSCBigInt.fromUInt64(uint64)
        self.context = context
        self.box = context.intern(JSCBox(.bigInt(sign: pair.0, digits: pair.1)))
        super.init()
    }

    public init!(newErrorFromMessage message: String!, in context: JSContext!) {
        guard let context else { return nil }
        self.context = context
        self.box = context.makeError("Error", message ?? "")
        super.init()
    }

    public init!(newErrorFromMessage message: String!, inContext context: JSContext!) {
        guard let context else { return nil }
        self.context = context
        self.box = context.makeError("Error", message ?? "")
        super.init()
    }

    public init!(newObjectIn context: JSContext!) {
        guard let context else { return nil }
        self.context = context
        self.box = context.makeObject()
        super.init()
    }

    public init!(newObjectInContext context: JSContext!) {
        guard let context else { return nil }
        self.context = context
        self.box = context.makeObject()
        super.init()
    }

    public init!(newPromiseIn context: JSContext!, fromExecutor callback: ((JSValue?, JSValue?) -> Void)!) {
        guard let context else { return nil }
        self.context = context
        let promise = context.makeObject()
        promise.object?.isPromise = true
        promise.object?.className = "Promise"
        self.box = promise
        super.init()
        let resolve = JSValue(box: context.makeNativeFunction(name: "resolve") { call in
            context.settle(promise, state: 1, value: call.args.first ?? .undefined)
            return .undefined
        }, in: context)
        let reject = JSValue(box: context.makeNativeFunction(name: "reject") { call in
            context.settle(promise, state: 2, value: call.args.first ?? .undefined)
            return .undefined
        }, in: context)
        callback?(resolve, reject)
    }

    public init!(newPromiseInContext context: JSContext!, fromExecutor callback: ((JSValue?, JSValue?) -> Void)!) {
        guard let context else { return nil }
        self.context = context
        let promise = context.makeObject()
        promise.object?.isPromise = true
        promise.object?.className = "Promise"
        self.box = promise
        super.init()
        let resolve = JSValue(box: context.makeNativeFunction(name: "resolve") { call in
            context.settle(promise, state: 1, value: call.args.first ?? .undefined)
            return .undefined
        }, in: context)
        let reject = JSValue(box: context.makeNativeFunction(name: "reject") { call in
            context.settle(promise, state: 2, value: call.args.first ?? .undefined)
            return .undefined
        }, in: context)
        callback?(resolve, reject)
    }

    public init!(newPromiseRejectedWithReason reason: Any!, in context: JSContext!) {
        guard let context else { return nil }
        self.context = context
        let promise = context.makeObject()
        promise.object?.isPromise = true
        promise.object?.className = "Promise"
        context.settle(promise, state: 2, value: context.box(fromSwift: reason))
        self.box = promise
        super.init()
    }

    public init!(newPromiseRejectedWithReason reason: Any!, inContext context: JSContext!) {
        guard let context else { return nil }
        self.context = context
        let promise = context.makeObject()
        promise.object?.isPromise = true
        promise.object?.className = "Promise"
        context.settle(promise, state: 2, value: context.box(fromSwift: reason))
        self.box = promise
        super.init()
    }

    public init!(newPromiseResolvedWithResult result: Any!, in context: JSContext!) {
        guard let context else { return nil }
        self.context = context
        let promise = context.makeObject()
        promise.object?.isPromise = true
        promise.object?.className = "Promise"
        context.settle(promise, state: 1, value: context.box(fromSwift: result))
        self.box = promise
        super.init()
    }

    public init!(newPromiseResolvedWithResult result: Any!, inContext context: JSContext!) {
        guard let context else { return nil }
        self.context = context
        let promise = context.makeObject()
        promise.object?.isPromise = true
        promise.object?.className = "Promise"
        context.settle(promise, state: 1, value: context.box(fromSwift: result))
        self.box = promise
        super.init()
    }

    public init!(newRegularExpressionFromPattern pattern: String!, flags: String!, in context: JSContext!) {
        guard let context else { return nil }
        self.context = context
        let object = context.makeObject()
        do {
            try context.applyRegExp(object, pattern: pattern ?? "", flags: flags ?? "")
        } catch {
            return nil
        }
        self.box = object
        super.init()
    }

    public init!(newRegularExpressionFromPattern pattern: String!, flags: String!, inContext context: JSContext!) {
        guard let context else { return nil }
        self.context = context
        let object = context.makeObject()
        do {
            try context.applyRegExp(object, pattern: pattern ?? "", flags: flags ?? "")
        } catch {
            return nil
        }
        self.box = object
        super.init()
    }

    public init!(newSymbolFromDescription description: String!, in context: JSContext!) {
        guard let context else { return nil }
        self.context = context
        self.box = context.intern(JSCBox(.symbol(context.virtualMachine.nextSymbolId(), description ?? "")))
        super.init()
    }

    public init!(newSymbolFromDescription description: String!, inContext context: JSContext!) {
        guard let context else { return nil }
        self.context = context
        self.box = context.intern(JSCBox(.symbol(context.virtualMachine.nextSymbolId(), description ?? "")))
        super.init()
    }

    public init!(nullIn context: JSContext!) {
        guard let context else { return nil }
        self.context = context
        self.box = context.intern(JSCBox(.null))
        super.init()
    }

    public init!(nullInContext context: JSContext!) {
        guard let context else { return nil }
        self.context = context
        self.box = context.intern(JSCBox(.null))
        super.init()
    }

    public init!(object value: Any!, in context: JSContext!) {
        guard let context else { return nil }
        self.context = context
        self.box = context.box(fromSwift: value)
        super.init()
    }

    public init!(object value: Any!, inContext context: JSContext!) {
        guard let context else { return nil }
        self.context = context
        self.box = context.box(fromSwift: value)
        super.init()
    }

    public init!(point: CGPoint, inContext context: JSContext!) {
        guard let context else { return nil }
        self.context = context
        let object = context.makeObject()
        object.object?.setOwn("x", context.intern(JSCBox(.number(point.x))))
        object.object?.setOwn("y", context.intern(JSCBox(.number(point.y))))
        self.box = object
        super.init()
    }

    public init!(range: NSRange, inContext context: JSContext!) {
        guard let context else { return nil }
        self.context = context
        let object = context.makeObject()
        object.object?.setOwn("location", context.intern(JSCBox(.number(Double(range.location)))))
        object.object?.setOwn("length", context.intern(JSCBox(.number(Double(range.length)))))
        self.box = object
        super.init()
    }

    public init!(rect: CGRect, inContext context: JSContext!) {
        guard let context else { return nil }
        self.context = context
        let object = context.makeObject()
        object.object?.setOwn("x", context.intern(JSCBox(.number(rect.origin.x))))
        object.object?.setOwn("y", context.intern(JSCBox(.number(rect.origin.y))))
        object.object?.setOwn("width", context.intern(JSCBox(.number(rect.size.width))))
        object.object?.setOwn("height", context.intern(JSCBox(.number(rect.size.height))))
        self.box = object
        super.init()
    }

    public init!(size: CGSize, inContext context: JSContext!) {
        guard let context else { return nil }
        self.context = context
        let object = context.makeObject()
        object.object?.setOwn("width", context.intern(JSCBox(.number(size.width))))
        object.object?.setOwn("height", context.intern(JSCBox(.number(size.height))))
        self.box = object
        super.init()
    }

    public init!(uInt32 value: UInt32, in context: JSContext!) {
        guard let context else { return nil }
        self.context = context
        self.box = context.intern(JSCBox(.number(Double(value))))
        super.init()
    }

    public init!(UInt32 value: UInt32, inContext context: JSContext!) {
        guard let context else { return nil }
        self.context = context
        self.box = context.intern(JSCBox(.number(Double(value))))
        super.init()
    }

    public init!(undefinedIn context: JSContext!) {
        guard let context else { return nil }
        self.context = context
        self.box = .undefined
        super.init()
    }

    public init!(undefinedInContext context: JSContext!) {
        guard let context else { return nil }
        self.context = context
        self.box = .undefined
        super.init()
    }

    public var isUndefined: Bool { box.isUndefined }
    public var isNull: Bool { box.isNull }
    public var isBoolean: Bool { box.isBoolean }
    public var isNumber: Bool { box.isNumber }
    public var isString: Bool { box.isString }
    public var isObject: Bool { box.isObject }
    public var isArray: Bool { box.object?.isArray ?? false }
    public var isDate: Bool { box.object?.isDate ?? false }
    public var isSymbol: Bool { box.isSymbol }
    public var isBigInt: Bool { box.isBigInt }

    public func toBool() -> Bool { box.booleanValue() }
    public func toDouble() -> Double { box.numberValue() }
    public func toInt32() -> Int32 { context.int32(box) }
    public func toUInt32() -> UInt32 { UInt32(bitPattern: toInt32()) }
    public func toInt64() -> Int64 {
        if case .bigInt(let sign, let digits) = box.payload {
            return Int64(digits).map { $0 * Int64(sign) } ?? 0
        }
        return Int64(box.numberValue())
    }
    public func toUInt64() -> UInt64 {
        if case .bigInt(_, let digits) = box.payload {
            return UInt64(digits) ?? 0
        }
        let value = box.numberValue()
        if value < 0 { return 0 }
        return UInt64(value)
    }
    public func toNumber() -> NSNumber! { NSNumber(value: box.numberValue()) }
    public func toString() -> String! { box.stringValue() }

    public func toObject() -> Any! {
        switch box.payload {
        case .undefined: return nil
        case .null: return NSNull()
        case .boolean(let value): return value
        case .number(let value): return value
        case .string(let value): return value
        case .symbol, .bigInt: return box.stringValue()
        case .object(let object):
            if object.isDate { return object.dateValue }
            if object.isArray {
                return toArray()
            }
            if let host = object.hostObject { return host }
            return toDictionary()
        }
    }

    public func toObjectOf(_ expectedClass: AnyClass!) -> Any! {
        let object = toObject()
        guard let expectedClass, let object else { return nil }
        return (object as? NSObject)?.isKind(of: expectedClass) == true ? object : nil
    }

    public func toArray() -> [Any]! {
        guard box.object?.isArray == true else {
            context.fail(context.makeError("TypeError", "not an array"))
            return nil
        }
        return (0..<box.arrayLength()).map { index in
            JSValue(box: box.object?.getOwn(String(index)) ?? .undefined, in: context).toObject() as Any
        }
    }

    public func toDictionary() -> [AnyHashable: Any]! {
        guard let object = box.object else {
            context.fail(context.makeError("TypeError", "not an object"))
            return nil
        }
        var result: [AnyHashable: Any] = [:]
        for name in object.enumerableNames() {
            result[name] = JSValue(box: object.getOwn(name) ?? .undefined, in: context).toObject() as Any
        }
        return result
    }

    public func toDate() -> Date! {
        if let object = box.object, object.isDate { return object.dateValue }
        let millis = box.numberValue()
        if millis.isFinite { return Date(timeIntervalSince1970: millis / 1000) }
        return nil
    }

    public func toPoint() -> CGPoint {
        CGPoint(x: numberProperty("x"), y: numberProperty("y"))
    }

    public func toSize() -> CGSize {
        CGSize(width: numberProperty("width"), height: numberProperty("height"))
    }

    public func toRect() -> CGRect {
        CGRect(x: numberProperty("x"), y: numberProperty("y"), width: numberProperty("width"), height: numberProperty("height"))
    }

    public func toRange() -> NSRange {
        NSRange(location: Int(numberProperty("location")), length: Int(numberProperty("length")))
    }

    public func call(withArguments arguments: [Any]!) -> JSValue! {
        do {
            let args = (arguments ?? []).map { context.box(fromSwift: $0) }
            let result = try context.call(box, this: context.globalBox, args: args, construct: false)
            return JSValue(box: result, in: context)
        } catch let jump as JSCJump {
            if case .thrown(let value) = jump { context.fail(value) }
            return nil
        } catch {
            context.fail(context.makeError("Error", String(describing: error)))
            return nil
        }
    }

    public func construct(withArguments arguments: [Any]!) -> JSValue! {
        do {
            let args = (arguments ?? []).map { context.box(fromSwift: $0) }
            let result = try context.call(box, this: context.makeObject(), args: args, construct: true)
            return JSValue(box: result, in: context)
        } catch let jump as JSCJump {
            if case .thrown(let value) = jump { context.fail(value) }
            return nil
        } catch {
            context.fail(context.makeError("Error", String(describing: error)))
            return nil
        }
    }

    public func invokeMethod(_ method: String!, withArguments arguments: [Any]!) -> JSValue! {
        do {
            let fn = try context.getProperty(box, name: method ?? "")
            let args = (arguments ?? []).map { context.box(fromSwift: $0) }
            let result = try context.call(fn, this: box, args: args, construct: false)
            return JSValue(box: result, in: context)
        } catch let jump as JSCJump {
            if case .thrown(let value) = jump { context.fail(value) }
            return nil
        } catch {
            context.fail(context.makeError("Error", String(describing: error)))
            return nil
        }
    }

    public func compare(_ other: Double) -> JSRelationCondition {
        context.compare(box, context.intern(JSCBox(.number(other))))
    }

    public func compare(_ other: Int64) -> JSRelationCondition {
        let pair = JSCBigInt.fromInt64(other)
        return context.compare(box, context.intern(JSCBox(.bigInt(sign: pair.0, digits: pair.1))))
    }

    public func compare(_ other: JSValue) -> JSRelationCondition {
        context.compare(box, other.box)
    }

    public func compare(_ other: UInt64) -> JSRelationCondition {
        let pair = JSCBigInt.fromUInt64(other)
        return context.compare(box, context.intern(JSCBox(.bigInt(sign: pair.0, digits: pair.1))))
    }

    public func defineProperty(_ property: Any!, descriptor: Any!) {
        let name = context.stringifyKey(property)
        guard let desc = JSValue(object: descriptor, in: context).toDictionary() else { return }
        var value = box.object?.getOwn(name) ?? .undefined
        if let raw = desc[JSPropertyDescriptorValueKey] {
            value = context.box(fromSwift: raw)
        }
        var attributes: JSPropertyAttributes = 0
        if let writable = desc[JSPropertyDescriptorWritableKey] as? Bool, !writable {
            attributes |= JSPropertyAttributes(kJSPropertyAttributeReadOnly)
        }
        if let enumerable = desc[JSPropertyDescriptorEnumerableKey] as? Bool, !enumerable {
            attributes |= JSPropertyAttributes(kJSPropertyAttributeDontEnum)
        }
        if let configurable = desc[JSPropertyDescriptorConfigurableKey] as? Bool, !configurable {
            attributes |= JSPropertyAttributes(kJSPropertyAttributeDontDelete)
        }
        box.object?.setOwn(name, value, attributes: attributes)
    }

    public func deleteProperty(_ property: Any!) -> Bool {
        box.object?.deleteOwn(context.stringifyKey(property)) ?? false
    }

    public func hasProperty(_ property: Any!) -> Bool {
        let name = context.stringifyKey(property)
        if box.object?.hasOwn(name) == true { return true }
        do {
            return try !context.getProperty(box, name: name).isUndefined
        } catch {
            return false
        }
    }

    public func isEqual(to value: Any!) -> Bool {
        context.strictEqual(box, context.box(fromSwift: value))
    }

    public func isEqualWithTypeCoercion(to value: Any!) -> Bool {
        context.looseEqual(box, context.box(fromSwift: value))
    }

    public func isInstance(of value: Any!) -> Bool {
        do {
            return try context.instanceOf(box, context.box(fromSwift: value))
        } catch {
            return false
        }
    }

    public func objectAtIndexedSubscript(_ index: Int) -> JSValue! {
        atIndex(index)
    }

    public func objectForKeyedSubscript(_ key: Any!) -> JSValue! {
        forProperty(key)
    }

    public func setObject(_ object: Any!, atIndexedSubscript index: Int) {
        setValue(object, at: index)
    }

    public func setObject(_ object: Any!, forKeyedSubscript key: Any!) {
        setValue(object, forProperty: key)
    }

    public func setValue(_ value: Any!, at index: Int) {
        try? context.setProperty(box, name: String(index), value: context.box(fromSwift: value))
    }

    public func setValue(_ value: Any!, forProperty property: Any!) {
        try? context.setProperty(box, name: context.stringifyKey(property), value: context.box(fromSwift: value))
    }

    public func atIndex(_ index: Int) -> JSValue! {
        do {
            let value = try context.getProperty(box, name: String(index))
            return JSValue(box: value, in: context)
        } catch {
            return JSValue(undefinedIn: context)
        }
    }

    public func forProperty(_ property: Any!) -> JSValue! {
        do {
            let value = try context.getProperty(box, name: context.stringifyKey(property))
            return JSValue(box: value, in: context)
        } catch {
            return JSValue(undefinedIn: context)
        }
    }

    public subscript(key: String) -> JSValue! {
        get { forProperty(key) }
        set { setValue(newValue, forProperty: key) }
    }

    public subscript(index: Int) -> JSValue! {
        get { atIndex(index) }
        set { setValue(newValue, at: index) }
    }

    private func numberProperty(_ name: String) -> Double {
        (try? context.getProperty(box, name: name).numberValue()) ?? 0
    }
}
