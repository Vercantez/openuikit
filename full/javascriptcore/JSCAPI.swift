import CoreFoundation
import Foundation

private let cfStringUTF8: CFStringEncoding = 0x08000100

private func context(from ref: JSContextRef?) -> JSContext? {
    JSCRef.takeUnretained(ref, as: JSContext.self)
}

private func box(from ref: JSValueRef?) -> JSCBox? {
    JSCRef.takeUnretained(ref, as: JSCBox.self)
}

private func storeException(_ pointer: UnsafeMutablePointer<JSValueRef?>?, _ value: JSCBox?) {
    pointer?.pointee = value.map { JSCRef.unretained($0) }
}

@_cdecl("JSContextGroupCreate")
public func JSContextGroupCreate() -> JSContextGroupRef! {
    JSCRef.retained(JSVirtualMachine())
}

@_cdecl("JSContextGroupRetain")
public func JSContextGroupRetain(_ group: JSContextGroupRef!) -> JSContextGroupRef! {
    JSCRef.retain(group)
}

@_cdecl("JSContextGroupRelease")
public func JSContextGroupRelease(_ group: JSContextGroupRef!) {
    JSCRef.release(group)
}

@_cdecl("JSGlobalContextCreate")
public func JSGlobalContextCreate(_ globalObjectClass: JSClassRef!) -> JSGlobalContextRef! {
    JSGlobalContextCreateInGroup(nil, globalObjectClass)
}

@_cdecl("JSGlobalContextCreateInGroup")
public func JSGlobalContextCreateInGroup(_ group: JSContextGroupRef!, _ globalObjectClass: JSClassRef!) -> JSGlobalContextRef! {
    let vm = JSCRef.takeUnretained(group, as: JSVirtualMachine.self) ?? JSVirtualMachine()
    let ctx = JSContext(virtualMachine: vm)!
    if let globalObjectClass, let jsClass = JSCRef.takeUnretained(globalObjectClass, as: JSCClass.self) {
        ctx.globalBox.object?.jsClass = jsClass
        if let initialize = jsClass.definition.initialize {
            initialize(JSCRef.unretained(ctx), JSCRef.unretained(ctx.globalBox))
        }
    }
    return JSCRef.retained(ctx)
}

@_cdecl("JSGlobalContextRetain")
public func JSGlobalContextRetain(_ ctx: JSGlobalContextRef!) -> JSGlobalContextRef! {
    JSCRef.retain(ctx)
}

@_cdecl("JSGlobalContextRelease")
public func JSGlobalContextRelease(_ ctx: JSGlobalContextRef!) {
    JSCRef.release(ctx)
}

@_cdecl("JSContextGetGlobalContext")
public func JSContextGetGlobalContext(_ ctx: JSContextRef!) -> JSGlobalContextRef! {
    ctx
}

@_cdecl("JSContextGetGlobalObject")
public func JSContextGetGlobalObject(_ ctx: JSContextRef!) -> JSObjectRef! {
    guard let context = context(from: ctx) else { return nil }
    return JSCRef.unretained(context.globalBox)
}

@_cdecl("JSContextGetGroup")
public func JSContextGetGroup(_ ctx: JSContextRef!) -> JSContextGroupRef! {
    guard let context = context(from: ctx) else { return nil }
    return JSCRef.unretained(context.virtualMachine!)
}

@_cdecl("JSGlobalContextCopyName")
public func JSGlobalContextCopyName(_ ctx: JSGlobalContextRef!) -> JSStringRef! {
    guard let context = context(from: ctx) else { return nil }
    return JSCRef.retained(context.virtualMachine.intern(JSCString(context.name ?? "")))
}

@_cdecl("JSGlobalContextSetName")
public func JSGlobalContextSetName(_ ctx: JSGlobalContextRef!, _ name: JSStringRef!) {
    context(from: ctx)?.name = JSCRef.takeUnretained(name, as: JSCString.self)?.swiftString
}

@_cdecl("JSGlobalContextIsInspectable")
public func JSGlobalContextIsInspectable(_ ctx: JSGlobalContextRef!) -> Bool {
    context(from: ctx)?.isInspectable ?? false
}

@_cdecl("JSGlobalContextSetInspectable")
public func JSGlobalContextSetInspectable(_ ctx: JSGlobalContextRef!, _ inspectable: Bool) {
    context(from: ctx)?.isInspectable = inspectable
}

@_cdecl("JSEvaluateScript")
public func JSEvaluateScript(
    _ ctx: JSContextRef!,
    _ script: JSStringRef!,
    _ thisObject: JSObjectRef!,
    _ sourceURL: JSStringRef!,
    _ startingLineNumber: Int32,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> JSValueRef! {
    _ = startingLineNumber
    _ = sourceURL
    guard let context = context(from: ctx) else { return nil }
    let text = JSCRef.takeUnretained(script, as: JSCString.self)?.swiftString ?? ""
    let this = box(from: thisObject) ?? context.globalBox
    do {
        let program = try JSCParser(source: text).parseProgram()
        let result = try context.exec(program, env: context.globalEnv, this: this)
        return JSCRef.unretained(result)
    } catch let jump as JSCJump {
        if case .thrown(let value) = jump {
            storeException(exception, value)
        }
        return nil
    } catch let error as JSCParseError {
        storeException(exception, context.makeError("SyntaxError", error.message))
        return nil
    } catch {
        storeException(exception, context.makeError("Error", String(describing: error)))
        return nil
    }
}

@_cdecl("JSCheckScriptSyntax")
public func JSCheckScriptSyntax(
    _ ctx: JSContextRef!,
    _ script: JSStringRef!,
    _ sourceURL: JSStringRef!,
    _ startingLineNumber: Int32,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> Bool {
    _ = sourceURL
    _ = startingLineNumber
    let text = JSCRef.takeUnretained(script, as: JSCString.self)?.swiftString ?? ""
    do {
        _ = try JSCParser(source: text).parseProgram()
        return true
    } catch let error as JSCParseError {
        if let context = context(from: ctx) {
            storeException(exception, context.makeError("SyntaxError", error.message))
        }
        return false
    } catch {
        return false
    }
}

@_cdecl("JSGarbageCollect")
public func JSGarbageCollect(_ ctx: JSContextRef!) {
    context(from: ctx)?.collectGarbage()
}

public func JSValueGetType(_ ctx: JSContextRef!, _ value: JSValueRef!) -> JSType {
    _ = ctx
    return box(from: value)?.jsType ?? kJSTypeUndefined
}

@_cdecl("JSValueIsUndefined")
public func JSValueIsUndefined(_ ctx: JSContextRef!, _ value: JSValueRef!) -> Bool {
    _ = ctx
    return box(from: value)?.isUndefined ?? true
}

@_cdecl("JSValueIsNull")
public func JSValueIsNull(_ ctx: JSContextRef!, _ value: JSValueRef!) -> Bool {
    _ = ctx
    return box(from: value)?.isNull ?? false
}

@_cdecl("JSValueIsBoolean")
public func JSValueIsBoolean(_ ctx: JSContextRef!, _ value: JSValueRef!) -> Bool {
    _ = ctx
    return box(from: value)?.isBoolean ?? false
}

@_cdecl("JSValueIsNumber")
public func JSValueIsNumber(_ ctx: JSContextRef!, _ value: JSValueRef!) -> Bool {
    _ = ctx
    return box(from: value)?.isNumber ?? false
}

@_cdecl("JSValueIsString")
public func JSValueIsString(_ ctx: JSContextRef!, _ value: JSValueRef!) -> Bool {
    _ = ctx
    return box(from: value)?.isString ?? false
}

@_cdecl("JSValueIsObject")
public func JSValueIsObject(_ ctx: JSContextRef!, _ value: JSValueRef!) -> Bool {
    _ = ctx
    return box(from: value)?.isObject ?? false
}

@_cdecl("JSValueIsSymbol")
public func JSValueIsSymbol(_ ctx: JSContextRef!, _ value: JSValueRef!) -> Bool {
    _ = ctx
    return box(from: value)?.isSymbol ?? false
}

@_cdecl("JSValueIsBigInt")
public func JSValueIsBigInt(_ ctx: JSContextRef, _ value: JSValueRef) -> Bool {
    _ = ctx
    return box(from: value)?.isBigInt ?? false
}

@_cdecl("JSValueIsArray")
public func JSValueIsArray(_ ctx: JSContextRef!, _ value: JSValueRef!) -> Bool {
    _ = ctx
    return box(from: value)?.object?.isArray ?? false
}

@_cdecl("JSValueIsDate")
public func JSValueIsDate(_ ctx: JSContextRef!, _ value: JSValueRef!) -> Bool {
    _ = ctx
    return box(from: value)?.object?.isDate ?? false
}

@_cdecl("JSValueIsObjectOfClass")
public func JSValueIsObjectOfClass(_ ctx: JSContextRef!, _ value: JSValueRef!, _ jsClass: JSClassRef!) -> Bool {
    _ = ctx
    guard let object = box(from: value)?.object, let jsClass = JSCRef.takeUnretained(jsClass, as: JSCClass.self) else {
        return false
    }
    var current = object.jsClass
    while let candidate = current {
        if candidate === jsClass { return true }
        current = candidate.parent
    }
    return false
}

@_cdecl("JSValueIsEqual")
public func JSValueIsEqual(
    _ ctx: JSContextRef!,
    _ a: JSValueRef!,
    _ b: JSValueRef!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> Bool {
    _ = exception
    guard let context = context(from: ctx), let left = box(from: a), let right = box(from: b) else { return false }
    return context.looseEqual(left, right)
}

@_cdecl("JSValueIsStrictEqual")
public func JSValueIsStrictEqual(_ ctx: JSContextRef!, _ a: JSValueRef!, _ b: JSValueRef!) -> Bool {
    guard let context = context(from: ctx), let left = box(from: a), let right = box(from: b) else { return false }
    return context.strictEqual(left, right)
}

@_cdecl("JSValueIsInstanceOfConstructor")
public func JSValueIsInstanceOfConstructor(
    _ ctx: JSContextRef!,
    _ value: JSValueRef!,
    _ constructor: JSObjectRef!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> Bool {
    guard let context = context(from: ctx), let value = box(from: value), let constructor = box(from: constructor) else {
        return false
    }
    do {
        return try context.instanceOf(value, constructor)
    } catch let jump as JSCJump {
        if case .thrown(let thrown) = jump { storeException(exception, thrown) }
        return false
    } catch {
        return false
    }
}

@_cdecl("JSValueMakeUndefined")
public func JSValueMakeUndefined(_ ctx: JSContextRef!) -> JSValueRef! {
    _ = ctx
    return JSCRef.unretained(JSCBox.undefined)
}

@_cdecl("JSValueMakeNull")
public func JSValueMakeNull(_ ctx: JSContextRef!) -> JSValueRef! {
    guard let context = context(from: ctx) else { return nil }
    return JSCRef.unretained(context.intern(JSCBox(.null)))
}

@_cdecl("JSValueMakeBoolean")
public func JSValueMakeBoolean(_ ctx: JSContextRef!, _ boolean: Bool) -> JSValueRef! {
    guard let context = context(from: ctx) else { return nil }
    return JSCRef.unretained(context.intern(JSCBox(.boolean(boolean))))
}

@_cdecl("JSValueMakeNumber")
public func JSValueMakeNumber(_ ctx: JSContextRef!, _ number: Double) -> JSValueRef! {
    guard let context = context(from: ctx) else { return nil }
    return JSCRef.unretained(context.intern(JSCBox(.number(number))))
}

@_cdecl("JSValueMakeString")
public func JSValueMakeString(_ ctx: JSContextRef!, _ string: JSStringRef!) -> JSValueRef! {
    guard let context = context(from: ctx) else { return nil }
    let text = JSCRef.takeUnretained(string, as: JSCString.self)?.swiftString ?? ""
    return JSCRef.unretained(context.intern(JSCBox(.string(text))))
}

@_cdecl("JSValueMakeSymbol")
public func JSValueMakeSymbol(_ ctx: JSContextRef!, _ description: JSStringRef!) -> JSValueRef! {
    guard let context = context(from: ctx) else { return nil }
    let text = JSCRef.takeUnretained(description, as: JSCString.self)?.swiftString ?? ""
    return JSCRef.unretained(context.intern(JSCBox(.symbol(context.virtualMachine.nextSymbolId(), text))))
}

@_cdecl("JSValueMakeFromJSONString")
public func JSValueMakeFromJSONString(_ ctx: JSContextRef!, _ string: JSStringRef!) -> JSValueRef! {
    guard let context = context(from: ctx) else { return nil }
    let text = JSCRef.takeUnretained(string, as: JSCString.self)?.swiftString ?? ""
    do {
        let object = try JSCJSON.parse(text)
        return JSCRef.unretained(context.box(fromSwift: object))
    } catch {
        return nil
    }
}

@_cdecl("JSValueCreateJSONString")
public func JSValueCreateJSONString(
    _ ctx: JSContextRef!,
    _ value: JSValueRef!,
    _ indent: UInt32,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> JSStringRef! {
    guard let context = context(from: ctx), let value = box(from: value) else { return nil }
    do {
        let text = try JSCJSON.stringify(value, indent: indent)
        return JSCRef.retained(context.virtualMachine.intern(JSCString(text)))
    } catch {
        storeException(exception, context.makeError("Error", String(describing: error)))
        return nil
    }
}

@_cdecl("JSValueToBoolean")
public func JSValueToBoolean(_ ctx: JSContextRef!, _ value: JSValueRef!) -> Bool {
    _ = ctx
    return box(from: value)?.booleanValue() ?? false
}

@_cdecl("JSValueToNumber")
public func JSValueToNumber(
    _ ctx: JSContextRef!,
    _ value: JSValueRef!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> Double {
    guard let context = context(from: ctx), let value = box(from: value) else { return .nan }
    if value.isObject {
        do {
            if let converted = try context.convertObject(value, to: kJSTypeNumber) {
                return converted.numberValue()
            }
        } catch let jump as JSCJump {
            if case .thrown(let thrown) = jump { storeException(exception, thrown) }
            return .nan
        } catch {
            return .nan
        }
    }
    return value.numberValue()
}

@_cdecl("JSValueToStringCopy")
public func JSValueToStringCopy(
    _ ctx: JSContextRef!,
    _ value: JSValueRef!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> JSStringRef! {
    guard let context = context(from: ctx), let value = box(from: value) else { return nil }
    var text = value.stringValue()
    if value.isObject {
        do {
            if let converted = try context.convertObject(value, to: kJSTypeString) {
                text = converted.stringValue()
            }
        } catch let jump as JSCJump {
            if case .thrown(let thrown) = jump { storeException(exception, thrown) }
            return nil
        } catch {
            return nil
        }
    }
    return JSCRef.retained(context.virtualMachine.intern(JSCString(text)))
}

@_cdecl("JSValueToObject")
public func JSValueToObject(
    _ ctx: JSContextRef!,
    _ value: JSValueRef!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> JSObjectRef! {
    guard let context = context(from: ctx), let value = box(from: value) else { return nil }
    if value.isObject { return JSCRef.unretained(value) }
    if value.isUndefined || value.isNull {
        storeException(exception, context.makeError("TypeError", "cannot convert to object"))
        return nil
    }
    let object = context.makeObject()
    object.object?.setOwn("valueOf", value)
    return JSCRef.unretained(object)
}

@_cdecl("JSValueToInt32")
public func JSValueToInt32(
    _ ctx: JSContextRef,
    _ value: JSValueRef,
    _ exception: UnsafeMutablePointer<JSValueRef?>?
) -> Int32 {
    _ = exception
    guard let context = context(from: ctx), let value = box(from: value) else { return 0 }
    return context.int32(value)
}

@_cdecl("JSValueToUInt32")
public func JSValueToUInt32(
    _ ctx: JSContextRef,
    _ value: JSValueRef,
    _ exception: UnsafeMutablePointer<JSValueRef?>?
) -> UInt32 {
    UInt32(bitPattern: JSValueToInt32(ctx, value, exception))
}

@_cdecl("JSValueToInt64")
public func JSValueToInt64(
    _ ctx: JSContextRef,
    _ value: JSValueRef,
    _ exception: UnsafeMutablePointer<JSValueRef?>?
) -> Int64 {
    _ = exception
    guard let value = box(from: value) else { return 0 }
    if case .bigInt(let sign, let digits) = value.payload {
        return Int64(digits).map { $0 * Int64(sign) } ?? 0
    }
    return Int64(value.numberValue())
}

@_cdecl("JSValueToUInt64")
public func JSValueToUInt64(
    _ ctx: JSContextRef,
    _ value: JSValueRef,
    _ exception: UnsafeMutablePointer<JSValueRef?>?
) -> UInt64 {
    _ = exception
    guard let value = box(from: value) else { return 0 }
    if case .bigInt(_, let digits) = value.payload {
        return UInt64(digits) ?? 0
    }
    let number = value.numberValue()
    return number < 0 ? 0 : UInt64(number)
}

public func JSValueCompare(
    _ ctx: JSContextRef,
    _ left: JSValueRef,
    _ right: JSValueRef,
    _ exception: UnsafeMutablePointer<JSValueRef?>?
) -> JSRelationCondition {
    _ = exception
    guard let context = context(from: ctx), let left = box(from: left), let right = box(from: right) else {
        return .undefined
    }
    return context.compare(left, right)
}

public func JSValueCompareDouble(
    _ ctx: JSContextRef,
    _ left: JSValueRef,
    _ right: Double,
    _ exception: UnsafeMutablePointer<JSValueRef?>?
) -> JSRelationCondition {
    _ = exception
    guard let context = context(from: ctx), let left = box(from: left) else { return .undefined }
    return context.compare(left, context.intern(JSCBox(.number(right))))
}

public func JSValueCompareInt64(
    _ ctx: JSContextRef,
    _ left: JSValueRef,
    _ right: Int64,
    _ exception: UnsafeMutablePointer<JSValueRef?>?
) -> JSRelationCondition {
    _ = exception
    guard let context = context(from: ctx), let left = box(from: left) else { return .undefined }
    let pair = JSCBigInt.fromInt64(right)
    return context.compare(left, context.intern(JSCBox(.bigInt(sign: pair.0, digits: pair.1))))
}

public func JSValueCompareUInt64(
    _ ctx: JSContextRef,
    _ left: JSValueRef,
    _ right: UInt64,
    _ exception: UnsafeMutablePointer<JSValueRef?>?
) -> JSRelationCondition {
    _ = exception
    guard let context = context(from: ctx), let left = box(from: left) else { return .undefined }
    let pair = JSCBigInt.fromUInt64(right)
    return context.compare(left, context.intern(JSCBox(.bigInt(sign: pair.0, digits: pair.1))))
}

@_cdecl("JSValueProtect")
public func JSValueProtect(_ ctx: JSContextRef!, _ value: JSValueRef!) {
    guard let box = box(from: value) else { return }
    _ = context(from: ctx)?.intern(box)
    box.protectCount += 1
}

@_cdecl("JSValueUnprotect")
public func JSValueUnprotect(_ ctx: JSContextRef!, _ value: JSValueRef!) {
    _ = ctx
    guard let box = box(from: value), box.protectCount > 0 else { return }
    box.protectCount -= 1
}

@_cdecl("JSBigIntCreateWithDouble")
public func JSBigIntCreateWithDouble(_ ctx: JSContextRef, _ value: Double, _ exception: UnsafeMutablePointer<JSValueRef?>?) -> JSValueRef {
    guard let context = context(from: ctx), let pair = JSCBigInt.fromDouble(value) else {
        storeException(exception, context(from: ctx)?.makeError("RangeError", "cannot convert Double to BigInt"))
        return JSCRef.unretained(JSCBox.undefined)
    }
    return JSCRef.unretained(context.intern(JSCBox(.bigInt(sign: pair.0, digits: pair.1))))
}

@_cdecl("JSBigIntCreateWithInt64")
public func JSBigIntCreateWithInt64(_ ctx: JSContextRef, _ integer: Int64, _ exception: UnsafeMutablePointer<JSValueRef?>?) -> JSValueRef {
    _ = exception
    let context = context(from: ctx)!
    let pair = JSCBigInt.fromInt64(integer)
    return JSCRef.unretained(context.intern(JSCBox(.bigInt(sign: pair.0, digits: pair.1))))
}

@_cdecl("JSBigIntCreateWithUInt64")
public func JSBigIntCreateWithUInt64(_ ctx: JSContextRef, _ integer: UInt64, _ exception: UnsafeMutablePointer<JSValueRef?>?) -> JSValueRef {
    _ = exception
    let context = context(from: ctx)!
    let pair = JSCBigInt.fromUInt64(integer)
    return JSCRef.unretained(context.intern(JSCBox(.bigInt(sign: pair.0, digits: pair.1))))
}

@_cdecl("JSBigIntCreateWithString")
public func JSBigIntCreateWithString(_ ctx: JSContextRef, _ string: JSStringRef, _ exception: UnsafeMutablePointer<JSValueRef?>?) -> JSValueRef {
    let context = context(from: ctx)!
    let text = JSCRef.takeUnretained(string, as: JSCString.self)?.swiftString ?? ""
    guard let pair = JSCBigInt.fromDecimal(text) else {
        storeException(exception, context.makeError("SyntaxError", "cannot convert string to BigInt"))
        return JSCRef.unretained(JSCBox.undefined)
    }
    return JSCRef.unretained(context.intern(JSCBox(.bigInt(sign: pair.0, digits: pair.1))))
}

public func JSClassCreate(_ definition: UnsafePointer<JSClassDefinition>!) -> JSClassRef! {
    guard let definition else { return nil }
    let parent = JSCRef.takeUnretained(definition.pointee.parentClass, as: JSCClass.self)
    return JSCRef.retained(JSCClass(definition: definition.pointee, parent: parent))
}

@_cdecl("JSClassRetain")
public func JSClassRetain(_ jsClass: JSClassRef!) -> JSClassRef! {
    JSCRef.retain(jsClass)
}

@_cdecl("JSClassRelease")
public func JSClassRelease(_ jsClass: JSClassRef!) {
    JSCRef.release(jsClass)
}

@_cdecl("JSObjectMake")
public func JSObjectMake(_ ctx: JSContextRef!, _ jsClass: JSClassRef!, _ data: UnsafeMutableRawPointer!) -> JSObjectRef! {
    guard let context = context(from: ctx) else { return nil }
    let object = context.makeObject()
    if let jsClass = JSCRef.takeUnretained(jsClass, as: JSCClass.self) {
        object.object?.jsClass = jsClass
        context.initializeClassObject(object, jsClass: jsClass, ctx: ctx)
    }
    object.object?.privateData = data
    return JSCRef.unretained(object)
}

@_cdecl("JSObjectMakeFunctionWithCallback")
public func JSObjectMakeFunctionWithCallback(
    _ ctx: JSContextRef!,
    _ name: JSStringRef!,
    _ callAsFunction: JSObjectCallAsFunctionCallback!
) -> JSObjectRef! {
    guard let context = context(from: ctx), let callAsFunction else { return nil }
    let object = JSCObject()
    object.function = .cFunction(callAsFunction)
    object.isConstructor = false
    object.className = "Function"
    let text = JSCRef.takeUnretained(name, as: JSCString.self)?.swiftString ?? ""
    object.setOwn("name", context.intern(JSCBox(.string(text))))
    return JSCRef.unretained(context.intern(JSCBox(.object(object))))
}

@_cdecl("JSObjectMakeConstructor")
public func JSObjectMakeConstructor(
    _ ctx: JSContextRef!,
    _ jsClass: JSClassRef!,
    _ callAsConstructor: JSObjectCallAsConstructorCallback!
) -> JSObjectRef! {
    guard let context = context(from: ctx) else { return nil }
    let object = JSCObject()
    if let callAsConstructor {
        object.function = .cConstructor(callAsConstructor)
    }
    object.isConstructor = true
    object.jsClass = JSCRef.takeUnretained(jsClass, as: JSCClass.self)
    object.className = "Function"
    return JSCRef.unretained(context.intern(JSCBox(.object(object))))
}

@_cdecl("JSObjectMakeArray")
public func JSObjectMakeArray(
    _ ctx: JSContextRef!,
    _ argumentCount: Int,
    _ arguments: UnsafePointer<JSValueRef?>!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> JSObjectRef! {
    _ = exception
    guard let context = context(from: ctx) else { return nil }
    var items: [JSCBox] = []
    if let arguments {
        for index in 0..<argumentCount {
            items.append(box(from: arguments.advanced(by: index).pointee) ?? .undefined)
        }
    }
    return JSCRef.unretained(context.makeArray(items))
}

@_cdecl("JSObjectMakeDate")
public func JSObjectMakeDate(
    _ ctx: JSContextRef!,
    _ argumentCount: Int,
    _ arguments: UnsafePointer<JSValueRef?>!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> JSObjectRef! {
    _ = exception
    guard let context = context(from: ctx) else { return nil }
    let millis = argumentCount > 0 ? (box(from: arguments.pointee)?.numberValue() ?? Date().timeIntervalSince1970 * 1000) : Date().timeIntervalSince1970 * 1000
    return JSCRef.unretained(context.makeDate(Date(timeIntervalSince1970: millis / 1000)))
}

@_cdecl("JSObjectMakeError")
public func JSObjectMakeError(
    _ ctx: JSContextRef!,
    _ argumentCount: Int,
    _ arguments: UnsafePointer<JSValueRef?>!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> JSObjectRef! {
    _ = exception
    guard let context = context(from: ctx) else { return nil }
    let message = argumentCount > 0 ? (box(from: arguments.pointee)?.stringValue() ?? "") : ""
    return JSCRef.unretained(context.makeError("Error", message))
}

@_cdecl("JSObjectMakeRegExp")
public func JSObjectMakeRegExp(
    _ ctx: JSContextRef!,
    _ argumentCount: Int,
    _ arguments: UnsafePointer<JSValueRef?>!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> JSObjectRef! {
    guard let context = context(from: ctx) else { return nil }
    let pattern = argumentCount > 0 ? (box(from: arguments.pointee)?.stringValue() ?? "") : ""
    let flags = argumentCount > 1 ? (box(from: arguments.advanced(by: 1).pointee)?.stringValue() ?? "") : ""
    let object = context.makeObject()
    do {
        try context.applyRegExp(object, pattern: pattern, flags: flags)
        return JSCRef.unretained(object)
    } catch let jump as JSCJump {
        if case .thrown(let value) = jump { storeException(exception, value) }
        return nil
    } catch {
        return nil
    }
}

@_cdecl("JSObjectMakeFunction")
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
    guard let context = context(from: ctx) else { return nil }
    var params: [String] = []
    if let parameterNames {
        for index in 0..<Int(parameterCount) {
            params.append(JSCRef.takeUnretained(parameterNames.advanced(by: index).pointee, as: JSCString.self)?.swiftString ?? "")
        }
    }
    let bodyText = JSCRef.takeUnretained(body, as: JSCString.self)?.swiftString ?? ""
    do {
        let parser = try JSCParser(source: bodyText)
        let program = try parser.parseProgram()
        let fnName = JSCRef.takeUnretained(name, as: JSCString.self)?.swiftString
        return JSCRef.unretained(context.makeFunction(name: fnName, params: params, body: program, env: context.globalEnv))
    } catch let error as JSCParseError {
        storeException(exception, context.makeError("SyntaxError", error.message))
        return nil
    } catch {
        storeException(exception, context.makeError("Error", String(describing: error)))
        return nil
    }
}

@_cdecl("JSObjectMakeDeferredPromise")
public func JSObjectMakeDeferredPromise(
    _ ctx: JSContextRef!,
    _ resolve: UnsafeMutablePointer<JSObjectRef?>!,
    _ reject: UnsafeMutablePointer<JSObjectRef?>!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> JSObjectRef! {
    _ = exception
    guard let context = context(from: ctx) else { return nil }
    let promise = context.makeObject()
    promise.object?.isPromise = true
    promise.object?.className = "Promise"
    let resolveFn = context.makeNativeFunction(name: "resolve") { call in
        context.settle(promise, state: 1, value: call.args.first ?? .undefined)
        return .undefined
    }
    let rejectFn = context.makeNativeFunction(name: "reject") { call in
        context.settle(promise, state: 2, value: call.args.first ?? .undefined)
        return .undefined
    }
    resolve?.pointee = JSCRef.unretained(resolveFn)
    reject?.pointee = JSCRef.unretained(rejectFn)
    return JSCRef.unretained(promise)
}

@_cdecl("JSObjectGetPrototype")
public func JSObjectGetPrototype(_ ctx: JSContextRef!, _ object: JSObjectRef!) -> JSValueRef! {
    _ = ctx
    return box(from: object)?.object?.prototype.map { JSCRef.unretained($0) }
}

@_cdecl("JSObjectSetPrototype")
public func JSObjectSetPrototype(_ ctx: JSContextRef!, _ object: JSObjectRef!, _ value: JSValueRef!) {
    _ = ctx
    box(from: object)?.object?.prototype = box(from: value)
}

@_cdecl("JSObjectHasProperty")
public func JSObjectHasProperty(_ ctx: JSContextRef!, _ object: JSObjectRef!, _ propertyName: JSStringRef!) -> Bool {
    guard let context = context(from: ctx), let object = box(from: object) else { return false }
    let name = JSCRef.takeUnretained(propertyName, as: JSCString.self)?.swiftString ?? ""
    if object.object?.hasOwn(name) == true { return true }
    if let jsObject = object.object {
        if context.staticValueEntry(jsObject, name: name) != nil { return true }
        if context.staticFunctionEntry(jsObject, name: name) != nil { return true }
        for cls in context.classChain(jsObject) {
            if let has = cls.definition.hasProperty {
                return has(ctx, JSCRef.unretained(object), propertyName)
            }
        }
    }
    return (try? context.getProperty(object, name: name).isUndefined) == false
}

@_cdecl("JSObjectGetProperty")
public func JSObjectGetProperty(
    _ ctx: JSContextRef!,
    _ object: JSObjectRef!,
    _ propertyName: JSStringRef!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> JSValueRef! {
    guard let context = context(from: ctx), let object = box(from: object) else { return nil }
    let name = JSCRef.takeUnretained(propertyName, as: JSCString.self)?.swiftString ?? ""
    do {
        return JSCRef.unretained(try context.getProperty(object, name: name))
    } catch let jump as JSCJump {
        if case .thrown(let value) = jump { storeException(exception, value) }
        return nil
    } catch {
        return nil
    }
}

@_cdecl("JSObjectSetProperty")
public func JSObjectSetProperty(
    _ ctx: JSContextRef!,
    _ object: JSObjectRef!,
    _ propertyName: JSStringRef!,
    _ value: JSValueRef!,
    _ attributes: JSPropertyAttributes,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) {
    guard let context = context(from: ctx), let object = box(from: object), let value = box(from: value) else { return }
    let name = JSCRef.takeUnretained(propertyName, as: JSCString.self)?.swiftString ?? ""
    do {
        try context.setProperty(object, name: name, value: value, attributes: attributes)
    } catch let jump as JSCJump {
        if case .thrown(let thrown) = jump { storeException(exception, thrown) }
    } catch {}
}

@_cdecl("JSObjectDeleteProperty")
public func JSObjectDeleteProperty(
    _ ctx: JSContextRef!,
    _ object: JSObjectRef!,
    _ propertyName: JSStringRef!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> Bool {
    guard let context = context(from: ctx), let object = box(from: object) else { return false }
    let name = JSCRef.takeUnretained(propertyName, as: JSCString.self)?.swiftString ?? ""
    if let jsObject = object.object {
        if let staticValue = context.staticValueEntry(jsObject, name: name),
           staticValue.attributes & JSPropertyAttributes(kJSPropertyAttributeDontDelete) != 0
        {
            return false
        }
        for cls in context.classChain(jsObject) {
            if let delete = cls.definition.deleteProperty {
                var thrown: JSValueRef?
                let result = delete(ctx, JSCRef.unretained(object), propertyName, &thrown)
                if let thrown { storeException(exception, box(from: thrown)) }
                return result
            }
        }
    }
    return object.object?.deleteOwn(name) ?? false
}

@_cdecl("JSObjectHasPropertyForKey")
public func JSObjectHasPropertyForKey(
    _ ctx: JSContextRef!,
    _ object: JSObjectRef!,
    _ propertyKey: JSValueRef!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> Bool {
    _ = exception
    guard let context = context(from: ctx), let object = box(from: object), let key = box(from: propertyKey) else {
        return false
    }
    return (try? context.getProperty(object, name: key.stringValue()).isUndefined) == false
}

@_cdecl("JSObjectGetPropertyForKey")
public func JSObjectGetPropertyForKey(
    _ ctx: JSContextRef!,
    _ object: JSObjectRef!,
    _ propertyKey: JSValueRef!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> JSValueRef! {
    guard let context = context(from: ctx), let object = box(from: object), let key = box(from: propertyKey) else {
        return nil
    }
    do {
        return JSCRef.unretained(try context.getProperty(object, name: key.stringValue()))
    } catch let jump as JSCJump {
        if case .thrown(let value) = jump { storeException(exception, value) }
        return nil
    } catch {
        return nil
    }
}

@_cdecl("JSObjectSetPropertyForKey")
public func JSObjectSetPropertyForKey(
    _ ctx: JSContextRef!,
    _ object: JSObjectRef!,
    _ propertyKey: JSValueRef!,
    _ value: JSValueRef!,
    _ attributes: JSPropertyAttributes,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) {
    guard let context = context(from: ctx), let object = box(from: object), let key = box(from: propertyKey),
          let value = box(from: value)
    else { return }
    do {
        try context.setProperty(object, name: key.stringValue(), value: value, attributes: attributes)
    } catch let jump as JSCJump {
        if case .thrown(let thrown) = jump { storeException(exception, thrown) }
    } catch {}
}

@_cdecl("JSObjectDeletePropertyForKey")
public func JSObjectDeletePropertyForKey(
    _ ctx: JSContextRef!,
    _ object: JSObjectRef!,
    _ propertyKey: JSValueRef!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> Bool {
    _ = ctx
    _ = exception
    guard let object = box(from: object), let key = box(from: propertyKey) else { return false }
    return object.object?.deleteOwn(key.stringValue()) ?? false
}

@_cdecl("JSObjectGetPropertyAtIndex")
public func JSObjectGetPropertyAtIndex(
    _ ctx: JSContextRef!,
    _ object: JSObjectRef!,
    _ propertyIndex: UInt32,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> JSValueRef! {
    guard let context = context(from: ctx), let object = box(from: object) else { return nil }
    do {
        return JSCRef.unretained(try context.getProperty(object, name: String(propertyIndex)))
    } catch let jump as JSCJump {
        if case .thrown(let value) = jump { storeException(exception, value) }
        return nil
    } catch {
        return nil
    }
}

@_cdecl("JSObjectSetPropertyAtIndex")
public func JSObjectSetPropertyAtIndex(
    _ ctx: JSContextRef!,
    _ object: JSObjectRef!,
    _ propertyIndex: UInt32,
    _ value: JSValueRef!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) {
    guard let context = context(from: ctx), let object = box(from: object), let value = box(from: value) else { return }
    do {
        try context.setProperty(object, name: String(propertyIndex), value: value)
    } catch let jump as JSCJump {
        if case .thrown(let thrown) = jump { storeException(exception, thrown) }
    } catch {}
}

@_cdecl("JSObjectGetPrivate")
public func JSObjectGetPrivate(_ object: JSObjectRef!) -> UnsafeMutableRawPointer! {
    box(from: object)?.object?.privateData
}

@_cdecl("JSObjectSetPrivate")
public func JSObjectSetPrivate(_ object: JSObjectRef!, _ data: UnsafeMutableRawPointer!) -> Bool {
    guard let jsObject = box(from: object)?.object else { return false }
    jsObject.privateData = data
    return true
}

@_cdecl("JSObjectIsFunction")
public func JSObjectIsFunction(_ ctx: JSContextRef!, _ object: JSObjectRef!) -> Bool {
    _ = ctx
    guard let jsObject = box(from: object)?.object else { return false }
    if case .none = jsObject.function {
        return jsObject.jsClass?.definition.callAsFunction != nil
    }
    return true
}

@_cdecl("JSObjectIsConstructor")
public func JSObjectIsConstructor(_ ctx: JSContextRef!, _ object: JSObjectRef!) -> Bool {
    _ = ctx
    guard let jsObject = box(from: object)?.object else { return false }
    if jsObject.isConstructor { return true }
    return jsObject.jsClass?.definition.callAsConstructor != nil
}

@_cdecl("JSObjectCallAsFunction")
public func JSObjectCallAsFunction(
    _ ctx: JSContextRef!,
    _ object: JSObjectRef!,
    _ thisObject: JSObjectRef!,
    _ argumentCount: Int,
    _ arguments: UnsafePointer<JSValueRef?>!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> JSValueRef! {
    guard let context = context(from: ctx), let callee = box(from: object) else { return nil }
    let this = box(from: thisObject) ?? context.globalBox
    var args: [JSCBox] = []
    if let arguments {
        for index in 0..<argumentCount {
            args.append(box(from: arguments.advanced(by: index).pointee) ?? .undefined)
        }
    }
    do {
        return JSCRef.unretained(try context.call(callee, this: this, args: args, construct: false))
    } catch let jump as JSCJump {
        if case .thrown(let value) = jump { storeException(exception, value) }
        return nil
    } catch {
        return nil
    }
}

@_cdecl("JSObjectCallAsConstructor")
public func JSObjectCallAsConstructor(
    _ ctx: JSContextRef!,
    _ object: JSObjectRef!,
    _ argumentCount: Int,
    _ arguments: UnsafePointer<JSValueRef?>!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> JSObjectRef! {
    guard let context = context(from: ctx), let callee = box(from: object) else { return nil }
    var args: [JSCBox] = []
    if let arguments {
        for index in 0..<argumentCount {
            args.append(box(from: arguments.advanced(by: index).pointee) ?? .undefined)
        }
    }
    do {
        return JSCRef.unretained(try context.call(callee, this: context.makeObject(), args: args, construct: true))
    } catch let jump as JSCJump {
        if case .thrown(let value) = jump { storeException(exception, value) }
        return nil
    } catch {
        return nil
    }
}

@_cdecl("JSObjectCopyPropertyNames")
public func JSObjectCopyPropertyNames(_ ctx: JSContextRef!, _ object: JSObjectRef!) -> JSPropertyNameArrayRef! {
    guard let context = context(from: ctx), let box = box(from: object) else { return nil }
    let array = JSCNameArray()
    if let jsObject = box.object {
        for name in jsObject.enumerableNames() {
            array.names.append(JSCString(name))
        }
        for cls in context.classChain(jsObject) {
            if let pointer = cls.definition.staticValues {
                var index = 0
                while true {
                    let entry = pointer.advanced(by: index).pointee
                    guard let namePointer = entry.name else { break }
                    if entry.attributes & JSPropertyAttributes(kJSPropertyAttributeDontEnum) == 0 {
                        array.names.append(JSCString(String(cString: namePointer)))
                    }
                    index += 1
                }
            }
            if let pointer = cls.definition.staticFunctions {
                var index = 0
                while true {
                    let entry = pointer.advanced(by: index).pointee
                    guard let namePointer = entry.name else { break }
                    if entry.attributes & JSPropertyAttributes(kJSPropertyAttributeDontEnum) == 0 {
                        array.names.append(JSCString(String(cString: namePointer)))
                    }
                    index += 1
                }
            }
            cls.definition.getPropertyNames?(
                ctx,
                JSCRef.unretained(box),
                JSCRef.unretained(array)
            )
        }
    }
    return JSCRef.retained(context.virtualMachine.intern(array))
}

@_cdecl("JSPropertyNameArrayRetain")
public func JSPropertyNameArrayRetain(_ array: JSPropertyNameArrayRef!) -> JSPropertyNameArrayRef! {
    JSCRef.retain(array)
}

@_cdecl("JSPropertyNameArrayRelease")
public func JSPropertyNameArrayRelease(_ array: JSPropertyNameArrayRef!) {
    JSCRef.release(array)
}

@_cdecl("JSPropertyNameArrayGetCount")
public func JSPropertyNameArrayGetCount(_ array: JSPropertyNameArrayRef!) -> Int {
    JSCRef.takeUnretained(array, as: JSCNameArray.self)?.names.count ?? 0
}

@_cdecl("JSPropertyNameArrayGetNameAtIndex")
public func JSPropertyNameArrayGetNameAtIndex(_ array: JSPropertyNameArrayRef!, _ index: Int) -> JSStringRef! {
    guard let names = JSCRef.takeUnretained(array, as: JSCNameArray.self)?.names, index >= 0, index < names.count else {
        return nil
    }
    return JSCRef.unretained(names[index])
}

@_cdecl("JSPropertyNameAccumulatorAddName")
public func JSPropertyNameAccumulatorAddName(_ accumulator: JSPropertyNameAccumulatorRef!, _ propertyName: JSStringRef!) {
    guard let array = JSCRef.takeUnretained(accumulator, as: JSCNameArray.self),
          let name = JSCRef.takeUnretained(propertyName, as: JSCString.self)
    else { return }
    array.names.append(name)
}

@_cdecl("JSObjectGetTypedArrayLength")
public func JSObjectGetTypedArrayLength(
    _ ctx: JSContextRef!,
    _ object: JSObjectRef!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> Int {
    _ = ctx
    _ = exception
    return box(from: object)?.object?.typedLength ?? 0
}

@_cdecl("JSObjectGetTypedArrayByteLength")
public func JSObjectGetTypedArrayByteLength(
    _ ctx: JSContextRef!,
    _ object: JSObjectRef!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> Int {
    _ = ctx
    _ = exception
    return box(from: object)?.object?.bufferLength ?? 0
}

@_cdecl("JSObjectGetTypedArrayByteOffset")
public func JSObjectGetTypedArrayByteOffset(
    _ ctx: JSContextRef!,
    _ object: JSObjectRef!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> Int {
    _ = ctx
    _ = exception
    return box(from: object)?.object?.byteOffset ?? 0
}

@_cdecl("JSObjectGetTypedArrayBuffer")
public func JSObjectGetTypedArrayBuffer(
    _ ctx: JSContextRef!,
    _ object: JSObjectRef!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> JSObjectRef! {
    _ = exception
    guard let context = context(from: ctx), let object = box(from: object) else { return nil }
    guard let buffer = context.internedTypedArrayBuffer(object) else { return nil }
    return JSCRef.unretained(buffer)
}

@_cdecl("JSObjectGetTypedArrayBytesPtr")
public func JSObjectGetTypedArrayBytesPtr(
    _ ctx: JSContextRef!,
    _ object: JSObjectRef!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> UnsafeMutableRawPointer! {
    _ = ctx
    _ = exception
    return box(from: object)?.object?.buffer
}

@_cdecl("JSObjectGetArrayBufferByteLength")
public func JSObjectGetArrayBufferByteLength(
    _ ctx: JSContextRef!,
    _ object: JSObjectRef!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> Int {
    _ = ctx
    _ = exception
    return box(from: object)?.object?.bufferLength ?? 0
}

@_cdecl("JSObjectGetArrayBufferBytesPtr")
public func JSObjectGetArrayBufferBytesPtr(
    _ ctx: JSContextRef!,
    _ object: JSObjectRef!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> UnsafeMutableRawPointer! {
    _ = ctx
    _ = exception
    return box(from: object)?.object?.buffer
}

public func JSValueGetTypedArrayType(
    _ ctx: JSContextRef!,
    _ value: JSValueRef!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> JSTypedArrayType {
    _ = ctx
    _ = exception
    return box(from: value)?.object?.typedArrayType ?? kJSTypedArrayTypeNone
}

public func JSObjectMakeTypedArray(
    _ ctx: JSContextRef!,
    _ arrayType: JSTypedArrayType,
    _ length: Int,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> JSObjectRef! {
    guard let context = context(from: ctx) else { return nil }
    do {
        return JSCRef.unretained(try context.makeTypedArray(type: arrayType, length: length))
    } catch let jump as JSCJump {
        if case .thrown(let value) = jump { storeException(exception, value) }
        return nil
    } catch {
        return nil
    }
}

public func JSObjectMakeTypedArrayWithArrayBuffer(
    _ ctx: JSContextRef!,
    _ arrayType: JSTypedArrayType,
    _ buffer: JSObjectRef!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> JSObjectRef! {
    guard let context = context(from: ctx), let buffer = box(from: buffer) else { return nil }
    let size = JSCTypedArray.elementSize(arrayType)
    let length = size == 0 ? 0 : (buffer.object?.bufferLength ?? 0) / size
    do {
        return JSCRef.unretained(try context.makeTypedArray(type: arrayType, length: length, buffer: buffer))
    } catch let jump as JSCJump {
        if case .thrown(let value) = jump { storeException(exception, value) }
        return nil
    } catch {
        return nil
    }
}

public func JSObjectMakeTypedArrayWithArrayBufferAndOffset(
    _ ctx: JSContextRef!,
    _ arrayType: JSTypedArrayType,
    _ buffer: JSObjectRef!,
    _ byteOffset: Int,
    _ length: Int,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> JSObjectRef! {
    guard let context = context(from: ctx), let buffer = box(from: buffer) else { return nil }
    do {
        return JSCRef.unretained(try context.makeTypedArray(type: arrayType, length: length, buffer: buffer, offset: byteOffset))
    } catch let jump as JSCJump {
        if case .thrown(let value) = jump { storeException(exception, value) }
        return nil
    } catch {
        return nil
    }
}

@_cdecl("JSObjectMakeArrayBufferWithBytesNoCopy")
public func JSObjectMakeArrayBufferWithBytesNoCopy(
    _ ctx: JSContextRef!,
    _ bytes: UnsafeMutableRawPointer!,
    _ byteLength: Int,
    _ bytesDeallocator: JSTypedArrayBytesDeallocator!,
    _ deallocatorContext: UnsafeMutableRawPointer!,
    _ exception: UnsafeMutablePointer<JSValueRef?>!
) -> JSObjectRef! {
    _ = exception
    guard let context = context(from: ctx) else { return nil }
    let object = JSCObject()
    object.isArrayBuffer = true
    object.buffer = bytes
    object.bufferLength = byteLength
    object.ownsBuffer = true
    object.bytesDeallocator = bytesDeallocator
    object.deallocatorContext = deallocatorContext
    object.setOwn("byteLength", context.intern(JSCBox(.number(Double(byteLength)))))
    return JSCRef.unretained(context.intern(JSCBox(.object(object))))
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
    guard let context = context(from: ctx) else { return nil }
    let size = JSCTypedArray.elementSize(arrayType)
    let length = size == 0 ? 0 : byteLength / size
    let buffer = JSObjectMakeArrayBufferWithBytesNoCopy(ctx, bytes, byteLength, bytesDeallocator, deallocatorContext, exception)
    do {
        return JSCRef.unretained(try context.makeTypedArray(type: arrayType, length: length, buffer: box(from: buffer), offset: 0))
    } catch {
        return nil
    }
}

@_cdecl("JSStringCreateWithCharacters")
public func JSStringCreateWithCharacters(_ chars: UnsafePointer<JSChar>!, _ numChars: Int) -> JSStringRef! {
    let units = (0..<numChars).map { chars.advanced(by: $0).pointee }
    return JSCRef.retained(JSCString(String(utf16CodeUnits: units, count: numChars)))
}

@_cdecl("JSStringCreateWithUTF8CString")
public func JSStringCreateWithUTF8CString(_ string: UnsafePointer<CChar>!) -> JSStringRef! {
    guard let string else { return JSCRef.retained(JSCString("")) }
    return JSCRef.retained(JSCString(String(cString: string)))
}

public func JSStringCreateWithCFString(_ string: CFString!) -> JSStringRef! {
    guard let string else { return JSCRef.retained(JSCString("")) }
    let length = CFStringGetLength(string)
    let capacity = CFStringGetMaximumSizeForEncoding(length, cfStringUTF8) + 1
    let buffer = UnsafeMutablePointer<CChar>.allocate(capacity: capacity)
    defer { buffer.deallocate() }
    if CFStringGetCString(string, buffer, capacity, cfStringUTF8) {
        return JSCRef.retained(JSCString(String(cString: buffer)))
    }
    return JSCRef.retained(JSCString(""))
}

public func JSStringCopyCFString(_ alloc: CFAllocator!, _ string: JSStringRef!) -> CFString! {
    _ = alloc
    let text = JSCRef.takeUnretained(string, as: JSCString.self)?.swiftString ?? ""
    return CFStringCreateWithCString(kCFAllocatorDefault, text, cfStringUTF8)
}

@_cdecl("JSStringRetain")
public func JSStringRetain(_ string: JSStringRef!) -> JSStringRef! {
    JSCRef.retain(string)
}

@_cdecl("JSStringRelease")
public func JSStringRelease(_ string: JSStringRef!) {
    JSCRef.release(string)
}

@_cdecl("JSStringGetLength")
public func JSStringGetLength(_ string: JSStringRef!) -> Int {
    JSCRef.takeUnretained(string, as: JSCString.self)?.length ?? 0
}

@_cdecl("JSStringGetCharactersPtr")
public func JSStringGetCharactersPtr(_ string: JSStringRef!) -> UnsafePointer<JSChar>! {
    guard let value = JSCRef.takeUnretained(string, as: JSCString.self) else { return nil }
    return UnsafePointer(value.buffer)
}

@_cdecl("JSStringGetMaximumUTF8CStringSize")
public func JSStringGetMaximumUTF8CStringSize(_ string: JSStringRef!) -> Int {
    (JSCRef.takeUnretained(string, as: JSCString.self)?.length ?? 0) * 3 + 1
}

@_cdecl("JSStringGetUTF8CString")
public func JSStringGetUTF8CString(_ string: JSStringRef!, _ buffer: UnsafeMutablePointer<CChar>!, _ bufferSize: Int) -> Int {
    guard let value = JSCRef.takeUnretained(string, as: JSCString.self), let buffer, bufferSize > 0 else { return 0 }
    let bytes = value.utf8CString
    let count = min(bufferSize, bytes.count)
    for index in 0..<count {
        buffer[index] = bytes[index]
    }
    if count < bytes.count {
        buffer[bufferSize - 1] = 0
    }
    return count
}

@_cdecl("JSStringIsEqual")
public func JSStringIsEqual(_ a: JSStringRef!, _ b: JSStringRef!) -> Bool {
    guard let left = JSCRef.takeUnretained(a, as: JSCString.self),
          let right = JSCRef.takeUnretained(b, as: JSCString.self)
    else { return false }
    return left.isEqual(to: right)
}

@_cdecl("JSStringIsEqualToUTF8CString")
public func JSStringIsEqualToUTF8CString(_ a: JSStringRef!, _ b: UnsafePointer<CChar>!) -> Bool {
    guard let left = JSCRef.takeUnretained(a, as: JSCString.self), let b else { return false }
    return left.swiftString == String(cString: b)
}
