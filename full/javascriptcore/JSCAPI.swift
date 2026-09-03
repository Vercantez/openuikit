import CoreFoundation
import Foundation

private func writeException(_ slot: UnsafeMutablePointer<JSValueRef?>?, _ value: JSCValue?) {
    guard let slot else { return }
    if let value {
        slot.pointee = jscPointer(value)
    } else {
        slot.pointee = nil
    }
}

private func requireContext(_ ctx: JSContextRef?) -> JSCContext? {
    jscContext(ctx)
}

public func JSContextGroupCreate() -> JSContextGroupRef! {
    jscPointer(JSCGroup())
}

public func JSContextGroupRetain(_ group: JSContextGroupRef!) -> JSContextGroupRef! {
    jscRetain(group)
    return group
}

public func JSContextGroupRelease(_ group: JSContextGroupRef!) {
    jscRelease(group)
}

public func JSGlobalContextCreate(_ globalObjectClass: JSClassRef!) -> JSGlobalContextRef! {
    JSGlobalContextCreateInGroup(nil, globalObjectClass)
}

public func JSGlobalContextCreateInGroup(_ group: JSContextGroupRef!, _ globalObjectClass: JSClassRef!) -> JSGlobalContextRef! {
    let resolved = jscGroup(group) ?? JSCGroup()
    let context = JSCContext(group: resolved)
    if let jsClass = jscClass(globalObjectClass) {
        context.global.object?.jsClass = jsClass
        if let initialize = jsClass.definition.initialize {
            initialize(jscPointer(context), jscPointer(context.global))
        }
    }
    return jscPointer(context)
}

public func JSGlobalContextRetain(_ ctx: JSGlobalContextRef!) -> JSGlobalContextRef! {
    jscRetain(ctx)
    return ctx
}

public func JSGlobalContextRelease(_ ctx: JSGlobalContextRef!) {
    jscRelease(ctx)
}

public func JSContextGetGlobalContext(_ ctx: JSContextRef!) -> JSGlobalContextRef! {
    ctx
}

public func JSContextGetGlobalObject(_ ctx: JSContextRef!) -> JSObjectRef! {
    guard let context = requireContext(ctx) else { return nil }
    return jscPointer(context.global)
}

public func JSContextGetGroup(_ ctx: JSContextRef!) -> JSContextGroupRef! {
    guard let context = requireContext(ctx) else { return nil }
    return jscPointer(context.group)
}

public func JSGlobalContextCopyName(_ ctx: JSGlobalContextRef!) -> JSStringRef! {
    guard let context = requireContext(ctx) else { return nil }
    return jscPointer(JSCString(context.name))
}

public func JSGlobalContextSetName(_ ctx: JSGlobalContextRef!, _ name: JSStringRef!) {
    guard let context = requireContext(ctx) else { return }
    context.name = jscString(name)?.string ?? ""
}

public func JSGlobalContextIsInspectable(_ ctx: JSGlobalContextRef!) -> Bool {
    requireContext(ctx)?.inspectable ?? false
}

public func JSGlobalContextSetInspectable(_ ctx: JSGlobalContextRef!, _ inspectable: Bool) {
    requireContext(ctx)?.inspectable = inspectable
}

public func JSEvaluateScript(
    _ ctx: JSContextRef!,
    _ script: JSStringRef!,
    _ thisObject: JSObjectRef!,
    _ sourceURL: JSStringRef!,
    _ startingLineNumber: Int32,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> JSValueRef! {
    guard let context = requireContext(ctx), let source = jscString(script)?.string else { return nil }
    let thisValue = jscValue(thisObject)
    let result = context.evaluate(source, this: thisValue, sourceURL: jscString(sourceURL)?.string, startingLine: startingLineNumber)
    if let thrown = context.exception {
        writeException(exception, thrown)
    }
    return jscPointer(result)
}

public func JSCheckScriptSyntax(
    _ ctx: JSContextRef!,
    _ script: JSStringRef!,
    _ sourceURL: JSStringRef!,
    _ startingLineNumber: Int32,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> Bool {
    _ = sourceURL
    _ = startingLineNumber
    guard let context = requireContext(ctx), let source = jscString(script)?.string else { return false }
    let ok = context.checkSyntax(source)
    if !ok { writeException(exception, context.exception) }
    return ok
}

public func JSGarbageCollect(_ ctx: JSContextRef!) {
    _ = ctx
}

public func JSValueGetType(_ ctx: JSContextRef!, _ value: JSValueRef!) -> JSType {
    guard let context = requireContext(ctx), let jsValue = jscValue(value) else { return kJSTypeUndefined }
    return context.jsType(jsValue)
}

public func JSValueIsUndefined(_ ctx: JSContextRef!, _ value: JSValueRef!) -> Bool {
    jscValue(value)?.isUndefined ?? true
}

public func JSValueIsNull(_ ctx: JSContextRef!, _ value: JSValueRef!) -> Bool {
    jscValue(value)?.isNull ?? false
}

public func JSValueIsBoolean(_ ctx: JSContextRef!, _ value: JSValueRef!) -> Bool {
    guard let jsValue = jscValue(value), jsValue.object == nil, case .boolean = jsValue.primitive else { return false }
    _ = ctx
    return true
}

public func JSValueIsNumber(_ ctx: JSContextRef!, _ value: JSValueRef!) -> Bool {
    guard let jsValue = jscValue(value), jsValue.object == nil, case .number = jsValue.primitive else { return false }
    _ = ctx
    return true
}

public func JSValueIsString(_ ctx: JSContextRef!, _ value: JSValueRef!) -> Bool {
    guard let jsValue = jscValue(value), jsValue.object == nil, case .string = jsValue.primitive else { return false }
    _ = ctx
    return true
}

public func JSValueIsObject(_ ctx: JSContextRef!, _ value: JSValueRef!) -> Bool {
    _ = ctx
    return jscValue(value)?.isObject ?? false
}

public func JSValueIsSymbol(_ ctx: JSContextRef!, _ value: JSValueRef!) -> Bool {
    guard let jsValue = jscValue(value), jsValue.object == nil, case .symbol = jsValue.primitive else { return false }
    _ = ctx
    return true
}

public func JSValueIsArray(_ ctx: JSContextRef!, _ value: JSValueRef!) -> Bool {
    _ = ctx
    return jscValue(value)?.object?.kind == .array
}

public func JSValueIsDate(_ ctx: JSContextRef!, _ value: JSValueRef!) -> Bool {
    _ = ctx
    return jscValue(value)?.object?.kind == .date
}

public func JSValueIsBigInt(_ ctx: JSContextRef, _ value: JSValueRef) -> Bool {
    guard let jsValue = jscValue(value), jsValue.object == nil, case .bigInt = jsValue.primitive else { return false }
    return true
}

public func JSValueIsObjectOfClass(_ ctx: JSContextRef!, _ value: JSValueRef!, _ jsClass: JSClassRef!) -> Bool {
    _ = ctx
    var current = jscValue(value)?.object?.jsClass
    let target = jscClass(jsClass)
    while let jsClassValue = current {
        if jsClassValue === target { return true }
        current = jsClassValue.parent
    }
    return false
}

public func JSValueIsEqual(
    _ ctx: JSContextRef!,
    _ a: JSValueRef!,
    _ b: JSValueRef!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> Bool {
    _ = exception
    guard let context = requireContext(ctx), let left = jscValue(a), let right = jscValue(b) else { return false }
    let interpreter = JSCInterpreter(context: context, environment: JSCEnvironment(parent: nil))
    return interpreter.abstractEqual(left, right)
}

public func JSValueIsStrictEqual(_ ctx: JSContextRef!, _ a: JSValueRef!, _ b: JSValueRef!) -> Bool {
    guard let context = requireContext(ctx), let left = jscValue(a), let right = jscValue(b) else { return false }
    let interpreter = JSCInterpreter(context: context, environment: JSCEnvironment(parent: nil))
    return interpreter.strictEqual(left, right)
}

public func JSValueIsInstanceOfConstructor(
    _ ctx: JSContextRef!,
    _ value: JSValueRef!,
    _ constructor: JSObjectRef!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> Bool {
    guard let context = requireContext(ctx), let jsValue = jscValue(value), let ctor = jscValue(constructor) else { return false }
    if let callback = ctor.object?.jsClass?.definition.hasInstance {
        var thrown: JSValueRef?
        let result = callback(ctx, constructor, value, &thrown)
        writeException(exception, jscValue(thrown))
        return result
    }
    let prototype = context.getProperty(ctor, "prototype")
    var current = jsValue.object?.prototype
    while let proto = current {
        if proto === prototype { return true }
        current = proto.object?.prototype
    }
    return false
}

private func compareNumbers(_ left: Double, _ right: Double) -> JSRelationCondition {
    if left.isNaN || right.isNaN { return .undefined }
    if left == right { return .equal }
    if left > right { return .greaterThan }
    return .lessThan
}

public func JSValueCompare(
    _ ctx: JSContextRef,
    _ left: JSValueRef,
    _ right: JSValueRef,
    _ exception: UnsafeMutablePointer<JSValueRef?>?
) -> JSRelationCondition {
    _ = exception
    guard let context = requireContext(ctx), let lhs = jscValue(left), let rhs = jscValue(right) else {
        return .undefined
    }
    return compareNumbers(context.toNumber(lhs), context.toNumber(rhs))
}

public func JSValueCompareDouble(
    _ ctx: JSContextRef,
    _ left: JSValueRef,
    _ right: Double,
    _ exception: UnsafeMutablePointer<JSValueRef?>?
) -> JSRelationCondition {
    _ = exception
    guard let context = requireContext(ctx), let lhs = jscValue(left) else { return .undefined }
    return compareNumbers(context.toNumber(lhs), right)
}

public func JSValueCompareInt64(
    _ ctx: JSContextRef,
    _ left: JSValueRef,
    _ right: Int64,
    _ exception: UnsafeMutablePointer<JSValueRef?>?
) -> JSRelationCondition {
    JSValueCompareDouble(ctx, left, Double(right), exception)
}

public func JSValueCompareUInt64(
    _ ctx: JSContextRef,
    _ left: JSValueRef,
    _ right: UInt64,
    _ exception: UnsafeMutablePointer<JSValueRef?>?
) -> JSRelationCondition {
    JSValueCompareDouble(ctx, left, Double(right), exception)
}

public func JSValueMakeUndefined(_ ctx: JSContextRef!) -> JSValueRef! {
    guard let context = requireContext(ctx) else { return nil }
    return jscPointer(JSCValue(primitive: .undefined, context: context))
}

public func JSValueMakeNull(_ ctx: JSContextRef!) -> JSValueRef! {
    guard let context = requireContext(ctx) else { return nil }
    return jscPointer(JSCValue(primitive: .null, context: context))
}

public func JSValueMakeBoolean(_ ctx: JSContextRef!, _ boolean: Bool) -> JSValueRef! {
    guard let context = requireContext(ctx) else { return nil }
    return jscPointer(JSCValue(primitive: .boolean(boolean), context: context))
}

public func JSValueMakeNumber(_ ctx: JSContextRef!, _ number: Double) -> JSValueRef! {
    guard let context = requireContext(ctx) else { return nil }
    return jscPointer(JSCValue(primitive: .number(number), context: context))
}

public func JSValueMakeString(_ ctx: JSContextRef!, _ string: JSStringRef!) -> JSValueRef! {
    guard let context = requireContext(ctx) else { return nil }
    return jscPointer(JSCValue(primitive: .string(jscString(string)?.string ?? ""), context: context))
}

public func JSValueMakeSymbol(_ ctx: JSContextRef!, _ description: JSStringRef!) -> JSValueRef! {
    guard let context = requireContext(ctx) else { return nil }
    return jscPointer(JSCValue(primitive: .symbol(id: context.makeSymbolId(), description: jscString(description)?.string ?? ""), context: context))
}

public func JSValueMakeFromJSONString(_ ctx: JSContextRef!, _ string: JSStringRef!) -> JSValueRef! {
    guard let context = requireContext(ctx) else { return nil }
    return jscPointer(context.parseJSON(jscString(string)?.string ?? ""))
}

public func JSValueCreateJSONString(
    _ ctx: JSContextRef!,
    _ value: JSValueRef!,
    _ indent: UInt32,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> JSStringRef! {
    guard let context = requireContext(ctx), let jsValue = jscValue(value) else { return nil }
    _ = exception
    return jscPointer(JSCString(context.jsonString(jsValue, indent: Int(indent))))
}

public func JSValueToBoolean(_ ctx: JSContextRef!, _ value: JSValueRef!) -> Bool {
    guard let context = requireContext(ctx), let jsValue = jscValue(value) else { return false }
    return context.toBoolean(jsValue)
}

public func JSValueToNumber(
    _ ctx: JSContextRef!,
    _ value: JSValueRef!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> Double {
    guard let context = requireContext(ctx), let jsValue = jscValue(value) else { return Double.nan }
    _ = exception
    return context.toNumber(jsValue)
}

public func JSValueToStringCopy(
    _ ctx: JSContextRef!,
    _ value: JSValueRef!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> JSStringRef! {
    guard let context = requireContext(ctx), let jsValue = jscValue(value) else { return nil }
    _ = exception
    return jscPointer(JSCString(context.toString(jsValue)))
}

public func JSValueToObject(
    _ ctx: JSContextRef!,
    _ value: JSValueRef!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> JSObjectRef! {
    guard let context = requireContext(ctx), let jsValue = jscValue(value) else { return nil }
    if jsValue.isObject { return value }
    if jsValue.isNull || jsValue.isUndefined {
        writeException(exception, context.makeError("cannot convert to object"))
        return nil
    }
    let object = JSCValue.object(JSCObject(kind: .ordinary), context: context)
    return jscPointer(object)
}

public func JSValueToInt32(
    _ ctx: JSContextRef,
    _ value: JSValueRef,
    _ exception: UnsafeMutablePointer<JSValueRef?>?
) -> Int32 {
    let number = JSValueToNumber(ctx, value, exception)
    guard number.isFinite else { return 0 }
    return Int32(truncatingIfNeeded: Int64(number))
}

public func JSValueToUInt32(
    _ ctx: JSContextRef,
    _ value: JSValueRef,
    _ exception: UnsafeMutablePointer<JSValueRef?>?
) -> UInt32 {
    let number = JSValueToNumber(ctx, value, exception)
    guard number.isFinite else { return 0 }
    return UInt32(truncatingIfNeeded: Int64(number))
}

public func JSValueToInt64(
    _ ctx: JSContextRef,
    _ value: JSValueRef,
    _ exception: UnsafeMutablePointer<JSValueRef?>?
) -> Int64 {
    let number = JSValueToNumber(ctx, value, exception)
    guard number.isFinite else { return 0 }
    return Int64(number)
}

public func JSValueToUInt64(
    _ ctx: JSContextRef,
    _ value: JSValueRef,
    _ exception: UnsafeMutablePointer<JSValueRef?>?
) -> UInt64 {
    let number = JSValueToNumber(ctx, value, exception)
    guard number.isFinite else { return 0 }
    return UInt64(number)
}

public func JSValueProtect(_ ctx: JSContextRef!, _ value: JSValueRef!) {
    _ = ctx
    if let jsValue = jscValue(value) {
        jsValue.protectCount += 1
        _ = jscRetain(value)
    }
}

public func JSValueUnprotect(_ ctx: JSContextRef!, _ value: JSValueRef!) {
    _ = ctx
    if let jsValue = jscValue(value), jsValue.protectCount > 0 {
        jsValue.protectCount -= 1
        jscRelease(value)
    }
}

public func JSBigIntCreateWithDouble(_ ctx: JSContextRef, _ value: Double, _ exception: UnsafeMutablePointer<JSValueRef?>?) -> JSValueRef {
    guard let context = requireContext(ctx) else { return JSValueMakeUndefined(ctx) }
    if !value.isFinite {
        writeException(exception, context.makeError("invalid bigint"))
        return JSValueMakeUndefined(ctx)
    }
    return jscPointer(JSCValue(primitive: .bigInt(String(Int64(value))), context: context))
}

public func JSBigIntCreateWithInt64(_ ctx: JSContextRef, _ integer: Int64, _ exception: UnsafeMutablePointer<JSValueRef?>?) -> JSValueRef {
    _ = exception
    guard let context = requireContext(ctx) else { return JSValueMakeUndefined(ctx) }
    return jscPointer(JSCValue(primitive: .bigInt(String(integer)), context: context))
}

public func JSBigIntCreateWithUInt64(_ ctx: JSContextRef, _ integer: UInt64, _ exception: UnsafeMutablePointer<JSValueRef?>?) -> JSValueRef {
    _ = exception
    guard let context = requireContext(ctx) else { return JSValueMakeUndefined(ctx) }
    return jscPointer(JSCValue(primitive: .bigInt(String(integer)), context: context))
}

public func JSBigIntCreateWithString(_ ctx: JSContextRef, _ string: JSStringRef, _ exception: UnsafeMutablePointer<JSValueRef?>?) -> JSValueRef {
    guard let context = requireContext(ctx) else { return JSValueMakeUndefined(ctx) }
    let text = jscString(string)?.string ?? ""
    if text.isEmpty || text.contains(where: { !$0.isNumber && $0 != "-" }) {
        writeException(exception, context.makeError("invalid bigint"))
        return JSValueMakeUndefined(ctx)
    }
    return jscPointer(JSCValue(primitive: .bigInt(text), context: context))
}

public func JSClassCreate(_ definition: UnsafePointer<JSClassDefinition>!) -> JSClassRef! {
    guard let definition else { return nil }
    let def = definition.pointee
    let parent = jscClass(def.parentClass)
    let name = def.className.map { String(cString: $0) } ?? ""
    return jscPointer(JSCClass(definition: def, parent: parent, className: name))
}

public func JSClassRetain(_ jsClass: JSClassRef!) -> JSClassRef! {
    jscRetain(jsClass)
    return jsClass
}

public func JSClassRelease(_ jsClass: JSClassRef!) {
    jscRelease(jsClass)
}

public func JSObjectMake(_ ctx: JSContextRef!, _ jsClass: JSClassRef!, _ data: UnsafeMutableRawPointer!) -> JSObjectRef! {
    guard let context = requireContext(ctx) else { return nil }
    let object = JSCObject(kind: .ordinary)
    object.jsClass = jscClass(jsClass)
    object.privateData = data
    let value = JSCValue.object(object, context: context)
    if let initialize = object.jsClass?.definition.initialize {
        initialize(ctx, jscPointer(value))
    }
    return jscPointer(value)
}

public func JSObjectMakeFunctionWithCallback(
    _ ctx: JSContextRef!,
    _ name: JSStringRef!,
    _ callAsFunction: JSObjectCallAsFunctionCallback!
) -> JSObjectRef! {
    guard let context = requireContext(ctx) else { return nil }
    let object = JSCObject(kind: .function)
    object.functionCallback = callAsFunction
    let value = JSCValue.object(object, context: context)
    context.setProperty(value, "name", JSCValue(primitive: .string(jscString(name)?.string ?? ""), context: context), enumerable: false)
    return jscPointer(value)
}

public func JSObjectMakeConstructor(
    _ ctx: JSContextRef!,
    _ jsClass: JSClassRef!,
    _ callAsConstructor: JSObjectCallAsConstructorCallback!
) -> JSObjectRef! {
    guard let context = requireContext(ctx) else { return nil }
    let object = JSCObject(kind: .constructor)
    object.jsClass = jscClass(jsClass)
    object.constructorCallback = callAsConstructor
    return jscPointer(JSCValue.object(object, context: context))
}

public func JSObjectMakeArray(
    _ ctx: JSContextRef!,
    _ argumentCount: Int,
    _ arguments: UnsafePointer<JSValueRef?>!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> JSObjectRef! {
    guard let context = requireContext(ctx) else { return nil }
    _ = exception
    var values: [JSCValue] = []
    if argumentCount > 0, let arguments {
        for index in 0..<argumentCount {
            values.append(jscValue(arguments[index]) ?? JSCValue(primitive: .undefined, context: context))
        }
    }
    return jscPointer(context.makeArray(values))
}

public func JSObjectMakeDate(
    _ ctx: JSContextRef!,
    _ argumentCount: Int,
    _ arguments: UnsafePointer<JSValueRef?>!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> JSObjectRef! {
    _ = argumentCount
    _ = arguments
    _ = exception
    guard let context = requireContext(ctx) else { return nil }
    let object = JSCObject(kind: .date)
    object.date = Date()
    return jscPointer(JSCValue.object(object, context: context))
}

public func JSObjectMakeError(
    _ ctx: JSContextRef!,
    _ argumentCount: Int,
    _ arguments: UnsafePointer<JSValueRef?>!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> JSObjectRef! {
    _ = exception
    guard let context = requireContext(ctx) else { return nil }
    var message = ""
    if argumentCount > 0, let arguments, let value = jscValue(arguments[0]) {
        message = context.toString(value)
    }
    return jscPointer(context.makeError(message))
}

public func JSObjectMakeRegExp(
    _ ctx: JSContextRef!,
    _ argumentCount: Int,
    _ arguments: UnsafePointer<JSValueRef?>!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> JSObjectRef! {
    _ = exception
    guard let context = requireContext(ctx) else { return nil }
    let pattern = (argumentCount > 0 && arguments != nil) ? context.toString(jscValue(arguments[0]) ?? JSCValue(primitive: .string(""), context: context)) : ""
    let flags = (argumentCount > 1 && arguments != nil) ? context.toString(jscValue(arguments[1]) ?? JSCValue(primitive: .string(""), context: context)) : ""
    let object = JSCObject(kind: .regexp)
    object.regexp = (pattern, flags)
    return jscPointer(JSCValue.object(object, context: context))
}

public func JSObjectMakeFunction(
    _ ctx: JSContextRef!,
    _ name: JSStringRef!,
    _ parameterCount: UInt32,
    _ parameterNames: UnsafePointer<JSStringRef?>!,
    _ body: JSStringRef!,
    _ sourceURL: JSStringRef!,
    _ startingLineNumber: Int32,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> JSObjectRef! {
    _ = sourceURL
    _ = startingLineNumber
    guard let context = requireContext(ctx) else { return nil }
    var params: [String] = []
    if parameterCount > 0, let parameterNames {
        for index in 0..<Int(parameterCount) {
            params.append(jscString(parameterNames[index])?.string ?? "")
        }
    }
    let header = "function \(jscString(name)?.string ?? "")(\(params.joined(separator: ","))) { \(jscString(body)?.string ?? "") }"
    let result = context.evaluate(header, this: nil, sourceURL: nil, startingLine: 0)
    if let thrown = context.exception {
        writeException(exception, thrown)
        return nil
    }
    return jscPointer(result)
}

public func JSObjectMakeDeferredPromise(
    _ ctx: JSContextRef!,
    _ resolve: UnsafeMutablePointer<JSObjectRef?>!,
    _ reject: UnsafeMutablePointer<JSObjectRef?>!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> JSObjectRef! {
    _ = exception
    guard let context = requireContext(ctx) else { return nil }
    let object = JSCObject(kind: .promise)
    let promise = JSCValue.object(object, context: context)
    let resolveFn = context.makeNativeFunction("resolve") { args, _, ctx in
        object.promiseState = .fulfilled(args.first ?? JSCValue(primitive: .undefined, context: ctx))
        return JSCValue(primitive: .undefined, context: ctx)
    }
    let rejectFn = context.makeNativeFunction("reject") { args, _, ctx in
        object.promiseState = .rejected(args.first ?? JSCValue(primitive: .undefined, context: ctx))
        return JSCValue(primitive: .undefined, context: ctx)
    }
    object.promiseState = .pending(resolve: resolveFn, reject: rejectFn)
    if let resolve { resolve.pointee = jscPointer(resolveFn) }
    if let reject { reject.pointee = jscPointer(rejectFn) }
    return jscPointer(promise)
}

public func JSObjectGetPrototype(_ ctx: JSContextRef!, _ object: JSObjectRef!) -> JSValueRef! {
    guard let context = requireContext(ctx), let value = jscValue(object) else { return nil }
    return jscPointer(value.object?.prototype ?? JSCValue(primitive: .null, context: context))
}

public func JSObjectSetPrototype(_ ctx: JSContextRef!, _ object: JSObjectRef!, _ value: JSValueRef!) {
    _ = ctx
    jscValue(object)?.object?.prototype = jscValue(value)
}

public func JSObjectHasProperty(_ ctx: JSContextRef!, _ object: JSObjectRef!, _ propertyName: JSStringRef!) -> Bool {
    guard let context = requireContext(ctx), let value = jscValue(object) else { return false }
    return context.hasProperty(value, jscString(propertyName)?.string ?? "")
}

public func JSObjectGetProperty(
    _ ctx: JSContextRef!,
    _ object: JSObjectRef!,
    _ propertyName: JSStringRef!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> JSValueRef! {
    _ = exception
    guard let context = requireContext(ctx), let value = jscValue(object) else { return nil }
    return jscPointer(context.getProperty(value, jscString(propertyName)?.string ?? ""))
}

public func JSObjectSetProperty(
    _ ctx: JSContextRef!,
    _ object: JSObjectRef!,
    _ propertyName: JSStringRef!,
    _ value: JSValueRef!,
    _ attributes: JSPropertyAttributes,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) {
    _ = exception
    guard let context = requireContext(ctx), let target = jscValue(object), let jsValue = jscValue(value) else { return }
    let enumerable = attributes & UInt32(kJSPropertyAttributeDontEnum) == 0
    let writable = attributes & UInt32(kJSPropertyAttributeReadOnly) == 0
    let configurable = attributes & UInt32(kJSPropertyAttributeDontDelete) == 0
    context.setProperty(target, jscString(propertyName)?.string ?? "", jsValue, enumerable: enumerable, writable: writable, configurable: configurable)
}

public func JSObjectDeleteProperty(
    _ ctx: JSContextRef!,
    _ object: JSObjectRef!,
    _ propertyName: JSStringRef!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> Bool {
    _ = exception
    guard let context = requireContext(ctx), let value = jscValue(object) else { return false }
    return context.deleteProperty(value, jscString(propertyName)?.string ?? "")
}

private func keyString(_ ctx: JSContextRef?, _ key: JSValueRef?) -> String {
    guard let context = requireContext(ctx), let value = jscValue(key) else { return "" }
    return context.toString(value)
}

public func JSObjectHasPropertyForKey(
    _ ctx: JSContextRef!,
    _ object: JSObjectRef!,
    _ propertyKey: JSValueRef!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> Bool {
    _ = exception
    guard let context = requireContext(ctx), let value = jscValue(object) else { return false }
    return context.hasProperty(value, keyString(ctx, propertyKey))
}

public func JSObjectGetPropertyForKey(
    _ ctx: JSContextRef!,
    _ object: JSObjectRef!,
    _ propertyKey: JSValueRef!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> JSValueRef! {
    _ = exception
    guard let context = requireContext(ctx), let value = jscValue(object) else { return nil }
    return jscPointer(context.getProperty(value, keyString(ctx, propertyKey)))
}

public func JSObjectSetPropertyForKey(
    _ ctx: JSContextRef!,
    _ object: JSObjectRef!,
    _ propertyKey: JSValueRef!,
    _ value: JSValueRef!,
    _ attributes: JSPropertyAttributes,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) {
    JSObjectSetProperty(ctx, object, JSValueToStringCopy(ctx, propertyKey, exception), value, attributes, exception)
}

public func JSObjectDeletePropertyForKey(
    _ ctx: JSContextRef!,
    _ object: JSObjectRef!,
    _ propertyKey: JSValueRef!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> Bool {
    JSObjectDeleteProperty(ctx, object, JSValueToStringCopy(ctx, propertyKey, exception), exception)
}

public func JSObjectGetPropertyAtIndex(
    _ ctx: JSContextRef!,
    _ object: JSObjectRef!,
    _ propertyIndex: UInt32,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> JSValueRef! {
    _ = exception
    guard let context = requireContext(ctx), let value = jscValue(object) else { return nil }
    return jscPointer(context.getProperty(value, String(propertyIndex)))
}

public func JSObjectSetPropertyAtIndex(
    _ ctx: JSContextRef!,
    _ object: JSObjectRef!,
    _ propertyIndex: UInt32,
    _ value: JSValueRef!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) {
    _ = exception
    guard let context = requireContext(ctx), let target = jscValue(object), let jsValue = jscValue(value) else { return }
    context.setProperty(target, String(propertyIndex), jsValue, enumerable: true)
}

public func JSObjectGetPrivate(_ object: JSObjectRef!) -> UnsafeMutableRawPointer! {
    jscValue(object)?.object?.privateData
}

public func JSObjectSetPrivate(_ object: JSObjectRef!, _ data: UnsafeMutableRawPointer!) -> Bool {
    guard let jsObject = jscValue(object)?.object else { return false }
    jsObject.privateData = data
    return true
}

public func JSObjectIsFunction(_ ctx: JSContextRef!, _ object: JSObjectRef!) -> Bool {
    _ = ctx
    let kind = jscValue(object)?.object?.kind
    return kind == .function || kind == .constructor
}

public func JSObjectIsConstructor(_ ctx: JSContextRef!, _ object: JSObjectRef!) -> Bool {
    _ = ctx
    return jscValue(object)?.object?.kind == .constructor || jscValue(object)?.object?.kind == .function
}

public func JSObjectCallAsFunction(
    _ ctx: JSContextRef!,
    _ object: JSObjectRef!,
    _ thisObject: JSObjectRef!,
    _ argumentCount: Int,
    _ arguments: UnsafePointer<JSValueRef?>!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> JSValueRef! {
    guard let context = requireContext(ctx), let function = jscValue(object) else { return nil }
    var args: [JSCValue] = []
    if argumentCount > 0, let arguments {
        for index in 0..<argumentCount {
            args.append(jscValue(arguments[index]) ?? JSCValue(primitive: .undefined, context: context))
        }
    }
    do {
        let result = try context.call(function, this: jscValue(thisObject) ?? context.global, arguments: args)
        return jscPointer(result)
    } catch let thrown as JSCThrown {
        writeException(exception, thrown.value)
        return JSValueMakeUndefined(ctx)
    } catch {
        writeException(exception, context.makeError(String(describing: error)))
        return JSValueMakeUndefined(ctx)
    }
}

public func JSObjectCallAsConstructor(
    _ ctx: JSContextRef!,
    _ object: JSObjectRef!,
    _ argumentCount: Int,
    _ arguments: UnsafePointer<JSValueRef?>!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> JSObjectRef! {
    guard let context = requireContext(ctx), let function = jscValue(object) else { return nil }
    var args: [JSCValue] = []
    if argumentCount > 0, let arguments {
        for index in 0..<argumentCount {
            args.append(jscValue(arguments[index]) ?? JSCValue(primitive: .undefined, context: context))
        }
    }
    do {
        return jscPointer(try context.construct(function, arguments: args))
    } catch let thrown as JSCThrown {
        writeException(exception, thrown.value)
        return nil
    } catch {
        writeException(exception, context.makeError(String(describing: error)))
        return nil
    }
}

public func JSObjectCopyPropertyNames(_ ctx: JSContextRef!, _ object: JSObjectRef!) -> JSPropertyNameArrayRef! {
    guard let context = requireContext(ctx), let value = jscValue(object) else { return nil }
    return jscPointer(JSCNameArray(context.propertyNames(value)))
}

public func JSPropertyNameArrayRetain(_ array: JSPropertyNameArrayRef!) -> JSPropertyNameArrayRef! {
    jscRetain(array)
    return array
}

public func JSPropertyNameArrayRelease(_ array: JSPropertyNameArrayRef!) {
    jscRelease(array)
}

public func JSPropertyNameArrayGetCount(_ array: JSPropertyNameArrayRef!) -> Int {
    jscNames(array)?.names.count ?? 0
}

public func JSPropertyNameArrayGetNameAtIndex(_ array: JSPropertyNameArrayRef!, _ index: Int) -> JSStringRef! {
    guard let names = jscNames(array), index >= 0, index < names.names.count else { return nil }
    return jscPointer(names.names[index])
}

public func JSPropertyNameAccumulatorAddName(_ accumulator: JSPropertyNameAccumulatorRef!, _ propertyName: JSStringRef!) {
    guard let names = jscNames(accumulator), let string = jscString(propertyName) else { return }
    names.names.append(JSCString(string.string))
}

public func JSObjectMakeArrayBufferWithBytesNoCopy(
    _ ctx: JSContextRef!,
    _ bytes: UnsafeMutableRawPointer!,
    _ byteLength: Int,
    _ bytesDeallocator: JSTypedArrayBytesDeallocator!,
    _ deallocatorContext: UnsafeMutableRawPointer!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> JSObjectRef! {
    _ = exception
    guard let context = requireContext(ctx), let bytes else { return nil }
    let buffer = JSCArrayBuffer(bytes: bytes, length: byteLength, deallocator: bytesDeallocator, deallocatorContext: deallocatorContext)
    let object = JSCObject(kind: .arrayBuffer)
    object.buffer = buffer
    let value = JSCValue.object(object, context: context)
    buffer.internedBufferObject = value
    return jscPointer(value)
}

public func JSObjectGetArrayBufferBytesPtr(
    _ ctx: JSContextRef!,
    _ object: JSObjectRef!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> UnsafeMutableRawPointer! {
    _ = ctx
    _ = exception
    return jscValue(object)?.object?.buffer?.pointer()
}

public func JSObjectGetArrayBufferByteLength(
    _ ctx: JSContextRef!,
    _ object: JSObjectRef!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> Int {
    _ = ctx
    _ = exception
    return jscValue(object)?.object?.buffer?.length ?? 0
}

public func JSObjectMakeTypedArray(
    _ ctx: JSContextRef!,
    _ arrayType: JSTypedArrayType,
    _ length: Int,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> JSObjectRef! {
    _ = exception
    guard let context = requireContext(ctx) else { return nil }
    let bytesPerElement = typedArrayBytesPerElement(arrayType)
    let buffer = JSCArrayBuffer(length: length * bytesPerElement)
    let bufferObject = JSCObject(kind: .arrayBuffer)
    bufferObject.buffer = buffer
    let bufferValue = JSCValue.object(bufferObject, context: context)
    buffer.internedBufferObject = bufferValue
    let object = JSCObject(kind: .typedArray)
    object.typedArray = JSCTypedArray(type: arrayType, buffer: bufferValue, byteOffset: 0, length: length, bytesPerElement: bytesPerElement)
    object.buffer = buffer
    return jscPointer(JSCValue.object(object, context: context))
}

public func JSObjectMakeTypedArrayWithBytesNoCopy(
    _ ctx: JSContextRef!,
    _ arrayType: JSTypedArrayType,
    _ bytes: UnsafeMutableRawPointer!,
    _ byteLength: Int,
    _ bytesDeallocator: JSTypedArrayBytesDeallocator!,
    _ deallocatorContext: UnsafeMutableRawPointer!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> JSObjectRef! {
    _ = exception
    guard let context = requireContext(ctx), let bytes else { return nil }
    let bytesPerElement = typedArrayBytesPerElement(arrayType)
    let buffer = JSCArrayBuffer(bytes: bytes, length: byteLength, deallocator: bytesDeallocator, deallocatorContext: deallocatorContext)
    let bufferObject = JSCObject(kind: .arrayBuffer)
    bufferObject.buffer = buffer
    let bufferValue = JSCValue.object(bufferObject, context: context)
    buffer.internedBufferObject = bufferValue
    let object = JSCObject(kind: .typedArray)
    object.buffer = buffer
    object.typedArray = JSCTypedArray(
        type: arrayType,
        buffer: bufferValue,
        byteOffset: 0,
        length: bytesPerElement == 0 ? 0 : byteLength / bytesPerElement,
        bytesPerElement: bytesPerElement
    )
    return jscPointer(JSCValue.object(object, context: context))
}

public func JSObjectMakeTypedArrayWithArrayBuffer(
    _ ctx: JSContextRef!,
    _ arrayType: JSTypedArrayType,
    _ buffer: JSObjectRef!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> JSObjectRef! {
    JSObjectMakeTypedArrayWithArrayBufferAndOffset(ctx, arrayType, buffer, 0, 0, exception)
}

public func JSObjectMakeTypedArrayWithArrayBufferAndOffset(
    _ ctx: JSContextRef!,
    _ arrayType: JSTypedArrayType,
    _ buffer: JSObjectRef!,
    _ byteOffset: Int,
    _ length: Int,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> JSObjectRef! {
    _ = exception
    guard let context = requireContext(ctx), let bufferValue = jscValue(buffer), let arrayBuffer = bufferValue.object?.buffer else {
        return nil
    }
    let bytesPerElement = typedArrayBytesPerElement(arrayType)
    let resolvedLength = length == 0 ? max(arrayBuffer.length - byteOffset, 0) / max(bytesPerElement, 1) : length
    let object = JSCObject(kind: .typedArray)
    object.buffer = arrayBuffer
    object.typedArray = JSCTypedArray(
        type: arrayType,
        buffer: bufferValue,
        byteOffset: byteOffset,
        length: resolvedLength,
        bytesPerElement: bytesPerElement
    )
    return jscPointer(JSCValue.object(object, context: context))
}

public func JSObjectGetTypedArrayBytesPtr(
    _ ctx: JSContextRef!,
    _ object: JSObjectRef!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> UnsafeMutableRawPointer! {
    _ = ctx
    _ = exception
    guard let typed = jscValue(object)?.object?.typedArray else { return nil }
    return typed.buffer.object?.buffer?.pointer().advanced(by: typed.byteOffset)
}

public func JSObjectGetTypedArrayLength(
    _ ctx: JSContextRef!,
    _ object: JSObjectRef!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> Int {
    _ = ctx
    _ = exception
    return jscValue(object)?.object?.typedArray?.length ?? 0
}

public func JSObjectGetTypedArrayByteLength(
    _ ctx: JSContextRef!,
    _ object: JSObjectRef!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> Int {
    _ = ctx
    _ = exception
    guard let typed = jscValue(object)?.object?.typedArray else { return 0 }
    return typed.length * typed.bytesPerElement
}

public func JSObjectGetTypedArrayByteOffset(
    _ ctx: JSContextRef!,
    _ object: JSObjectRef!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> Int {
    _ = ctx
    _ = exception
    return jscValue(object)?.object?.typedArray?.byteOffset ?? 0
}

public func JSObjectGetTypedArrayBuffer(
    _ ctx: JSContextRef!,
    _ object: JSObjectRef!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> JSObjectRef! {
    _ = ctx
    _ = exception
    guard let typed = jscValue(object)?.object?.typedArray else { return nil }
    if let interned = typed.buffer.object?.buffer?.internedBufferObject {
        return jscPointer(interned)
    }
    return jscPointer(typed.buffer)
}

public func JSValueGetTypedArrayType(
    _ ctx: JSContextRef!,
    _ value: JSValueRef!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> JSTypedArrayType {
    _ = ctx
    _ = exception
    return jscValue(value)?.object?.typedArray?.type ?? kJSTypedArrayTypeNone
}

public func JSStringCreateWithCharacters(_ chars: UnsafePointer<JSChar>!, _ numChars: Int) -> JSStringRef! {
    guard let chars else { return jscPointer(JSCString("")) }
    let buffer = UnsafeBufferPointer(start: chars, count: numChars)
    return jscPointer(JSCString(String(decoding: buffer, as: UTF16.self)))
}

public func JSStringCreateWithUTF8CString(_ string: UnsafePointer<CChar>!) -> JSStringRef! {
    guard let string else { return jscPointer(JSCString("")) }
    return jscPointer(JSCString(String(cString: string)))
}

public func JSStringCreateWithCFString(_ string: CFString!) -> JSStringRef! {
    guard let string else { return jscPointer(JSCString("")) }
    let length = CFStringGetLength(string)
    let max = CFStringGetMaximumSizeForEncoding(length, CFStringBuiltInEncodings.UTF8.rawValue) + 1
    let buf = UnsafeMutablePointer<CChar>.allocate(capacity: max)
    defer { buf.deallocate() }
    CFStringGetCString(string, buf, max, CFStringBuiltInEncodings.UTF8.rawValue)
    return jscPointer(JSCString(String(cString: buf)))
}

public func JSStringCopyCFString(_ alloc: CFAllocator!, _ string: JSStringRef!) -> CFString! {
    _ = alloc
    let text = jscString(string)?.string ?? ""
    return text.withCString { cstr in
        CFStringCreateWithCString(nil, cstr, CFStringBuiltInEncodings.UTF8.rawValue)
    }
}

public func JSStringRetain(_ string: JSStringRef!) -> JSStringRef! {
    jscRetain(string)
    return string
}

public func JSStringRelease(_ string: JSStringRef!) {
    jscRelease(string)
}

public func JSStringGetLength(_ string: JSStringRef!) -> Int {
    jscString(string)?.count ?? 0
}

public func JSStringGetCharactersPtr(_ string: JSStringRef!) -> UnsafePointer<JSChar>! {
    jscString(string)?.characters
}

public func JSStringGetMaximumUTF8CStringSize(_ string: JSStringRef!) -> Int {
    (jscString(string)?.count ?? 0) * 3 + 1
}

public func JSStringGetUTF8CString(_ string: JSStringRef!, _ buffer: UnsafeMutablePointer<CChar>!, _ bufferSize: Int) -> Int {
    guard let text = jscString(string)?.string, let buffer, bufferSize > 0 else { return 0 }
    return text.withCString { cstr in
        var length = 0
        while cstr[length] != 0 { length += 1 }
        let copy = min(length, bufferSize - 1)
        for index in 0..<copy {
            buffer[index] = cstr[index]
        }
        buffer[copy] = 0
        return copy + 1
    }
}

public func JSStringIsEqual(_ a: JSStringRef!, _ b: JSStringRef!) -> Bool {
    jscString(a)?.string == jscString(b)?.string
}

public func JSStringIsEqualToUTF8CString(_ a: JSStringRef!, _ b: UnsafePointer<CChar>!) -> Bool {
    guard let b else { return jscString(a)?.string.isEmpty ?? true }
    return jscString(a)?.string == String(cString: b)
}
