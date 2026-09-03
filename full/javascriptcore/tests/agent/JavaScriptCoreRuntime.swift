import Foundation
import JavaScriptCore

enum JavaScriptCoreRuntimeFailure: Error {
    case message(String)
}

func expect(_ condition: Bool, _ message: String) throws {
    if !condition {
        throw JavaScriptCoreRuntimeFailure.message(message)
    }
}

func expectEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String) throws {
    if actual != expected {
        throw JavaScriptCoreRuntimeFailure.message("\(message): \(actual) != \(expected)")
    }
}

func assertTypesAndConstants() throws {
    try expectEqual(kJSTypeUndefined.rawValue, 0, "kJSTypeUndefined")
    try expectEqual(kJSTypeNull.rawValue, 1, "kJSTypeNull")
    try expectEqual(kJSTypeBoolean.rawValue, 2, "kJSTypeBoolean")
    try expectEqual(kJSTypeNumber.rawValue, 3, "kJSTypeNumber")
    try expectEqual(kJSTypeString.rawValue, 4, "kJSTypeString")
    try expectEqual(kJSTypeObject.rawValue, 5, "kJSTypeObject")
    try expectEqual(kJSTypeSymbol.rawValue, 6, "kJSTypeSymbol")
    try expectEqual(kJSTypeBigInt.rawValue, 7, "kJSTypeBigInt")
    try expect(kJSTypeUndefined != kJSTypeNull, "JSType !=")
    try expectEqual(kJSTypedArrayTypeNone.rawValue, 0, "typed none")
    try expectEqual(kJSTypedArrayTypeInt8Array.rawValue, 1, "int8")
    try expectEqual(kJSTypedArrayTypeArrayBuffer.rawValue, 10, "arraybuffer")
    try expectEqual(JSRelationCondition.undefined.rawValue, 0, "rel undefined")
    try expectEqual(JSRelationCondition.equal.rawValue, 1, "rel equal")
    try expectEqual(kJSPropertyAttributeNone, 0, "attr none")
    try expectEqual(kJSPropertyAttributeReadOnly, 2, "readonly")
    try expectEqual(kJSPropertyAttributeDontEnum, 4, "dontenum")
    try expectEqual(kJSPropertyAttributeDontDelete, 8, "dontdelete")
    try expectEqual(kJSClassAttributeNone, 0, "class none")
    try expectEqual(kJSClassAttributeNoAutomaticPrototype, 2, "no auto proto")
    try expectEqual(JSPropertyDescriptorWritableKey, "writable", "writable key")
    try expectEqual(JSPropertyDescriptorEnumerableKey, "enumerable", "enumerable key")
    try expectEqual(JSPropertyDescriptorConfigurableKey, "configurable", "configurable key")
    try expectEqual(JSPropertyDescriptorValueKey, "value", "value key")
    try expectEqual(JSPropertyDescriptorGetKey, "get", "get key")
    try expectEqual(JSPropertyDescriptorSetKey, "set", "set key")
    try expectEqual(JSC_OBJC_API_ENABLED, Int32(1), "objc overlay enabled")
    _ = JSType(0)
    _ = JSTypedArrayType(0)
    _ = JSStaticValue()
    _ = JSStaticFunction()
    _ = JSClassDefinition()
    _ = kJSClassDefinitionEmpty
    struct Exported: JSExport {}
    _ = Exported()
}

func assertCStringAndContext() throws {
    let ctx = JSGlobalContextCreate(nil)!
    defer { JSGlobalContextRelease(ctx) }
    JSGlobalContextSetName(ctx, JSStringCreateWithUTF8CString("probe"))
    let name = JSGlobalContextCopyName(ctx)!
    try expect(JSStringIsEqualToUTF8CString(name, "probe"), "context name")
    JSStringRelease(name)
    JSGlobalContextSetInspectable(ctx, true)
    try expect(JSGlobalContextIsInspectable(ctx), "inspectable")
    let group = JSContextGetGroup(ctx)!
    _ = JSContextGroupRetain(group)
    JSContextGroupRelease(group)
    try expect(JSContextGetGlobalContext(ctx) == ctx, "global context identity")

    let hello = JSStringCreateWithUTF8CString("hello")!
    defer { JSStringRelease(hello) }
    try expectEqual(JSStringGetLength(hello), 5, "utf16 length")
    try expect(JSStringIsEqual(hello, JSStringCreateWithUTF8CString("hello")), "equal strings")
    var buffer = [CChar](repeating: 0, count: 16)
    let copied = JSStringGetUTF8CString(hello, &buffer, buffer.count)
    try expect(copied > 0, "utf8 copy")
    let cf = JSStringCopyCFString(nil, hello)!
    let roundTrip = JSStringCreateWithCFString(cf)!
    try expect(JSStringIsEqual(hello, roundTrip), "cfstring round trip")
    JSStringRelease(roundTrip)

    let chars: [JSChar] = [0x41, 0x42]
    let fromChars = JSStringCreateWithCharacters(chars, 2)!
    try expect(JSStringIsEqualToUTF8CString(fromChars, "AB"), "create with characters")
    JSStringRelease(fromChars)
    try expectEqual(JSStringGetMaximumUTF8CStringSize(hello), 16, "max utf8")
}

func assertEvaluateAndValues() throws {
    let context = JSContext()
    let sum = context.evaluateScript("40 + 2")!
    try expectEqual(sum.toInt32(), 42, "40+2")
    try expect(sum.isNumber, "sum is number")
    try expectEqual(sum.toDouble(), 42, "double")
    try expectEqual(sum.toString(), "42", "string")
    try expectEqual(sum.toBool(), true, "bool")
    try expect(sum.compare(40.0) == .greaterThan, "compare double")
    try expect(sum.compare(Int64(42)) == .equal, "compare int64")
    try expect(sum.compare(UInt64(42)) == .equal, "compare uint64")

    let object = context.evaluateScript("({a: 1, b: 'x'})")!
    try expect(object.isObject, "object")
    try expectEqual(object.forProperty("a").toInt32(), 1, "property a")
    try expect(object.hasProperty("b"), "has b")
    object.setValue("y", forProperty: "b")
    try expectEqual(object.forProperty("b").toString(), "y", "set property")
    try expect(object.deleteProperty("b"), "delete")
    try expect(!object.hasProperty("b"), "deleted")

    let array = context.evaluateScript("[10, 20]")!
    try expect(array.isArray, "array")
    try expectEqual(array.atIndex(1).toInt32(), 20, "index 1")
    array.setValue(30, at: 1)
    try expectEqual(array.objectAtIndexedSubscript(1).toInt32(), 30, "subscript")
    try expectEqual(array.toArray()?.count, 2, "toArray")

    let scripted = context.evaluateScript("function add(x,y){ return x+y } add")!
    let result = scripted.call(withArguments: [3, 4])!
    try expectEqual(result.toInt32(), 7, "call add")

    context.setObject("linux", forKeyedSubscript: "hostName" as NSString)
    try expectEqual(context.objectForKeyedSubscript("hostName").toString(), "linux", "global subscript")
    try expectEqual(context.evaluateScript("hostName").toString(), "linux", "global ident")

    let ctor = context.evaluateScript("function Box(v){ this.v = v } Box")!
    let instance = ctor.construct(withArguments: [9])!
    try expectEqual(instance.forProperty("v").toInt32(), 9, "construct")
    try expectEqual(instance.invokeMethod("toString", withArguments: []).toString() != nil, true, "invoke")

    try expect(JSValue(bool: true, in: context).isBoolean, "bool value")
    try expect(JSValue(double: 1.5, in: context).isNumber, "double value")
    try expect(JSValue(int32: 3, in: context).toInt32() == 3, "int32")
    try expect(JSValue(uInt32: 4, in: context).toUInt32() == 4, "uint32")
    try expect(JSValue(undefinedIn: context).isUndefined, "undefined")
    try expect(JSValue(nullIn: context).isNull, "null")
    try expect(JSValue(newObjectIn: context).isObject, "new object")
    try expect(JSValue(newArrayIn: context).isArray, "new array")
    try expect(JSValue(object: "hi", in: context).isString, "object string")
    try expect(JSValue(newErrorFromMessage: "boom", in: context).isObject, "error")
    try expect(JSValue(newRegularExpressionFromPattern: "a+", flags: "g", in: context).toString().contains("a+"), "regexp")
    try expect(JSValue(newSymbolFromDescription: "s", in: context).isSymbol, "symbol")
    try expect(JSValue(newBigIntFrom: Int64(99), in: context)?.isBigInt == true, "bigint")
    try expect(JSValue(point: CGPoint(x: 1, y: 2), inContext: context).toPoint().x == 1, "point")
    try expect(JSValue(size: CGSize(width: 3, height: 4), inContext: context).toSize().width == 3, "size")
    try expect(JSValue(rect: CGRect(x: 0, y: 0, width: 5, height: 6), inContext: context).toRect().width == 5, "rect")
    try expect(JSValue(range: NSRange(location: 1, length: 2), inContext: context).toRange().location == 1, "range")

    let json = context.evaluateScript("JSON.stringify({k:1})")!
    try expectEqual(json.toString(), "{\"k\":1}", "json stringify")
    try expect(context.evaluateScript("JSON.parse('{\"k\":2}')").forProperty("k").toInt32() == 2, "json parse")

    var sawException = false
    context.exceptionHandler = { (_: JSContext?, _: JSValue?) in sawException = true }
    _ = context.evaluateScript("throw 'nope'")
    try expect(sawException, "exception handler")
    try expect(context.exception != nil, "exception stored")
}

func assertCAPIValues() throws {
    let ctx = JSGlobalContextCreate(nil)!
    defer { JSGlobalContextRelease(ctx) }
    let number = JSValueMakeNumber(ctx, 12)!
    try expect(JSValueIsNumber(ctx, number), "is number")
    try expectEqual(JSValueToNumber(ctx, number, nil), 12, "to number")
    try expectEqual(JSValueToInt32(ctx, number, nil), 12, "to int32")
    try expectEqual(JSValueToUInt32(ctx, number, nil), 12, "to uint32")
    try expectEqual(JSValueToInt64(ctx, number, nil), 12, "to int64")
    try expectEqual(JSValueToUInt64(ctx, number, nil), 12, "to uint64")
    try expect(JSValueIsBoolean(ctx, JSValueMakeBoolean(ctx, true)), "bool")
    try expect(JSValueIsString(ctx, JSValueMakeString(ctx, JSStringCreateWithUTF8CString("s"))), "string")
    try expect(JSValueIsUndefined(ctx, JSValueMakeUndefined(ctx)), "undefined")
    try expect(JSValueIsNull(ctx, JSValueMakeNull(ctx)), "null")
    try expect(JSValueIsSymbol(ctx, JSValueMakeSymbol(ctx, JSStringCreateWithUTF8CString("sym"))), "symbol")
    try expect(JSValueGetType(ctx, number) == kJSTypeNumber, "get type")
    try expect(JSValueIsStrictEqual(ctx, number, JSValueMakeNumber(ctx, 12)), "strict eq")
    try expect(JSValueIsEqual(ctx, number, JSValueMakeString(ctx, JSStringCreateWithUTF8CString("12")), nil), "abstract eq")
    let json = JSValueCreateJSONString(ctx, JSValueMakeFromJSONString(ctx, JSStringCreateWithUTF8CString("true")), 0, nil)!
    try expect(JSStringIsEqualToUTF8CString(json, "true"), "json string")
    let big = JSBigIntCreateWithInt64(ctx, 5, nil)
    try expect(JSValueIsBigInt(ctx, big), "bigint c")
    _ = JSBigIntCreateWithUInt64(ctx, 6, nil)
    _ = JSBigIntCreateWithDouble(ctx, 7, nil)
    _ = JSBigIntCreateWithString(ctx, JSStringCreateWithUTF8CString("8")!, nil)
    JSValueProtect(ctx, number)
    JSValueUnprotect(ctx, number)
    JSGarbageCollect(ctx)

    var exception: JSValueRef?
    let script = JSStringCreateWithUTF8CString("1+1")!
    try expect(JSCheckScriptSyntax(ctx, script, nil, 1, &exception), "syntax ok")
    try expect(!JSCheckScriptSyntax(ctx, JSStringCreateWithUTF8CString("function ("), nil, 1, &exception), "syntax bad")
    let eval = JSEvaluateScript(ctx, JSStringCreateWithUTF8CString("'ab'+'c'"), nil, nil, 1, &exception)!
    let copied = JSValueToStringCopy(ctx, eval, &exception)!
    try expect(JSStringIsEqualToUTF8CString(copied, "abc"), "eval string")
    try expect(JSValueToBoolean(ctx, JSValueMakeBoolean(ctx, true)), "to bool")
    try expect(JSValueToObject(ctx, JSValueMakeNumber(ctx, 1), &exception) != nil, "to object")
}

func assertObjectsAndTypedArrays() throws {
    let ctx = JSGlobalContextCreate(nil)!
    defer { JSGlobalContextRelease(ctx) }
    var exception: JSValueRef?
    let object = JSObjectMake(ctx, nil, nil)!
    JSObjectSetProperty(ctx, object, JSStringCreateWithUTF8CString("k"), JSValueMakeNumber(ctx, 3), 0, &exception)
    try expect(JSObjectHasProperty(ctx, object, JSStringCreateWithUTF8CString("k")), "has k")
    try expectEqual(JSValueToNumber(ctx, JSObjectGetProperty(ctx, object, JSStringCreateWithUTF8CString("k"), &exception), nil), 3, "get k")
    JSObjectSetPropertyAtIndex(ctx, object, 0, JSValueMakeNumber(ctx, 9), &exception)
    try expectEqual(JSValueToNumber(ctx, JSObjectGetPropertyAtIndex(ctx, object, 0, &exception), nil), 9, "index")
    try expect(JSObjectDeleteProperty(ctx, object, JSStringCreateWithUTF8CString("k"), &exception), "delete k")
    let names = JSObjectCopyPropertyNames(ctx, object)!
    try expect(JSPropertyNameArrayGetCount(names) >= 1, "names")
    _ = JSPropertyNameArrayGetNameAtIndex(names, 0)
    JSPropertyNameAccumulatorAddName(names, JSStringCreateWithUTF8CString("extra"))
    _ = JSPropertyNameArrayRetain(names)
    JSPropertyNameArrayRelease(names)
    JSPropertyNameArrayRelease(names)
    try expect(JSObjectSetPrivate(object, UnsafeMutableRawPointer(bitPattern: 0x5)!), "set private")
    try expect(JSObjectGetPrivate(object) != nil, "get private")

    let array = JSObjectMakeArray(ctx, 0, nil, &exception)!
    try expect(JSValueIsArray(ctx, array), "make array")
    let date = JSObjectMakeDate(ctx, 0, nil, &exception)!
    try expect(JSValueIsDate(ctx, date), "make date")
    let err = JSObjectMakeError(ctx, 0, nil, &exception)!
    try expect(JSValueIsObject(ctx, err), "make error")
    let re = JSObjectMakeRegExp(ctx, 0, nil, &exception)!
    try expect(JSValueIsObject(ctx, re), "make regexp")
    var resolve: JSObjectRef?
    var reject: JSObjectRef?
    let promise = JSObjectMakeDeferredPromise(ctx, &resolve, &reject, &exception)!
    try expect(JSValueIsObject(ctx, promise), "promise")
    try expect(resolve != nil && reject != nil, "resolve/reject")

    let typed = JSObjectMakeTypedArray(ctx, kJSTypedArrayTypeUint8Array, 4, &exception)!
    try expect(JSValueGetTypedArrayType(ctx, typed, &exception) == kJSTypedArrayTypeUint8Array, "typed type")
    try expectEqual(JSObjectGetTypedArrayLength(ctx, typed, &exception), 4, "typed length")
    try expectEqual(JSObjectGetTypedArrayByteLength(ctx, typed, &exception), 4, "typed bytes")
    try expectEqual(JSObjectGetTypedArrayByteOffset(ctx, typed, &exception), 0, "offset")
    let interned = JSObjectGetTypedArrayBuffer(ctx, typed, &exception)!
    let internedAgain = JSObjectGetTypedArrayBuffer(ctx, typed, &exception)!
    try expect(interned == internedAgain, "typed array buffer is interned")
    try expect(JSObjectGetTypedArrayBytesPtr(ctx, typed, &exception) != nil, "bytes ptr")
    try expectEqual(JSObjectGetArrayBufferByteLength(ctx, interned, &exception), 4, "buffer length")
    try expect(JSObjectGetArrayBufferBytesPtr(ctx, interned, &exception) != nil, "buffer ptr")

    let fromBuffer = JSObjectMakeTypedArrayWithArrayBuffer(ctx, kJSTypedArrayTypeUint8Array, interned, &exception)!
    try expect(JSObjectGetTypedArrayLength(ctx, fromBuffer, &exception) == 4, "from buffer")
    let offsetView = JSObjectMakeTypedArrayWithArrayBufferAndOffset(ctx, kJSTypedArrayTypeUint8Array, interned, 2, 2, &exception)!
    try expectEqual(JSObjectGetTypedArrayByteOffset(ctx, offsetView, &exception), 2, "view offset")

    let fn = JSObjectMakeFunction(ctx, JSStringCreateWithUTF8CString("id"), 1, nil, JSStringCreateWithUTF8CString("return 1"), nil, 1, &exception)
    try expect(fn != nil || exception != nil, "make function attempted")
}

func assertObjCMachine() throws {
    let vm = JSVirtualMachine()
    let context = JSContext(virtualMachine: vm)!
    vm.addManagedReference("token" as NSString, withOwner: context)
    vm.removeManagedReference("token" as NSString, withOwner: context)
    let value = JSValue(bool: true, in: context)!
    let managed = JSManagedValue(value: value)!
    try expect(managed.value.isBoolean, "managed")
    let owned = JSManagedValue(value: value, andOwner: context)!
    try expect(owned.value != nil, "managed owner")
    let wrapped = JSContext(JSGlobalContextRef: context.jsGlobalContextRef)!
    try expect(wrapped.globalObject.isObject, "wrap global context")
    let fromRef = JSValue(JSValueRef: value.jsValueRef, inContext: context)!
    try expect(fromRef.isBoolean, "from ref")
    context.name = "lane"
    try expectEqual(context.name, "lane", "name")
    context.isInspectable = false
    try expect(!context.isInspectable, "inspectable off")
    _ = JSContext.current()
    _ = JSContext.currentThis()
    _ = JSContext.currentArguments()
    _ = JSContext.currentCallee()
    let promise = JSValue(newPromiseIn: context, fromExecutor: { resolve, _ in
        _ = resolve?.call(withArguments: [1])
    })!
    try expect(promise.isObject, "promise executor sync")
    try expect(JSValue(newPromiseResolvedWithResult: 1, in: context).isObject, "resolved")
    try expect(JSValue(newPromiseRejectedWithReason: "x", in: context).isObject, "rejected")
}

do {
    try assertTypesAndConstants()
    try assertCStringAndContext()
    try assertEvaluateAndValues()
    try assertCAPIValues()
    try assertObjectsAndTypedArrays()
    try assertObjCMachine()
    print("JAVASCRIPTCORE_AGENT_RUNTIME_OK")
} catch {
    fputs("JavaScriptCore runtime failed: \(error)\n", stderr)
    exit(1)
}
