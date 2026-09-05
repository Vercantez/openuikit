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
    try expect(jscIndexOfProbe(JSValue(newRegularExpressionFromPattern: "a+", flags: "g", in: context).toString(), "a+") != nil, "regexp")
    try expect(JSValue(newSymbolFromDescription: "s", in: context).isSymbol, "symbol")
    try expect(JSValue(newBigIntFrom: Int64(99), in: context)?.isBigInt == true, "bigint")
    try expect(JSValue(point: CGPoint(x: 1, y: 2), inContext: context).toPoint().x == 1, "point")
    try expect(JSValue(size: CGSize(width: 3, height: 4), inContext: context).toSize().width == 3, "size")
    try expect(JSValue(rect: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 5, height: 6)), inContext: context).toRect().size.width == 5, "rect")
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

func assertInterpreterSubset() throws {
    let context = JSContext()
    try expectEqual(context.evaluateScript("typeof 1").toString(), "number", "typeof number")
    try expectEqual(context.evaluateScript("1 + '2'").toString(), "12", "ToPrimitive string concat ECMA-262 13.8")
    try expectEqual(context.evaluateScript("'2' * '3'").toInt32(), 6, "ToNumber multiply ECMA-262 7.1.3")
    try expect(context.evaluateScript("null == undefined").toBool(), "abstract eq null/undefined ECMA-262 7.2.14")
    try expect(context.evaluateScript("'12' == 12").toBool(), "abstract eq string/number")
    try expect(!context.evaluateScript("'12' === 12").toBool(), "strict eq")
    try expectEqual(context.evaluateScript("false || 'x'").toString(), "x", "logical or")
    try expectEqual(context.evaluateScript("1 && 2").toInt32(), 2, "logical and")
    try expectEqual(context.evaluateScript("if (1) { 8 } else { 9 }").toInt32(), 8, "if")
    try expectEqual(context.evaluateScript("var s=0; for (var i=0; i<3; i=i+1) { s=s+i } s").toInt32(), 3, "for")
    try expectEqual(context.evaluateScript("var n=0; var i=3; while (i) { n=n+i; i=i-1 } n").toInt32(), 6, "while")
    try expectEqual(context.evaluateScript("var x=1; x+=2; x").toInt32(), 3, "+=")
    try expectEqual(context.evaluateScript("var y=1; ++y").toInt32(), 2, "prefix ++")
    try expectEqual(context.evaluateScript("Math.floor(1.9)").toInt32(), 1, "Math.floor")
    try expectEqual(context.evaluateScript("Math.max(1,4,2)").toInt32(), 4, "Math.max")
    try expectEqual(context.evaluateScript("Math.pow(2,3)").toInt32(), 8, "Math.pow")
    try expectEqual(context.evaluateScript("'hello'.charAt(1)").toString(), "e", "String.charAt")
    try expectEqual(context.evaluateScript("'hello'.length").toInt32(), 5, "String.length utf16")
    try expectEqual(context.evaluateScript("'ab'.concat('c')").toString(), "abc", "String.concat")
    try expectEqual(context.evaluateScript("'HELLO'.toLowerCase()").toString(), "hello", "toLowerCase")
    try expectEqual(context.evaluateScript("[1,2].push(3)").toInt32(), 3, "Array.push length")
    try expectEqual(context.evaluateScript("var a=[1,2]; a.push(3); a.join('-')").toString(), "1-2-3", "Array.join")
    try expectEqual(context.evaluateScript("[10,20,30].slice(1,2)[0]").toInt32(), 20, "Array.slice")
    try expectEqual(context.evaluateScript("[1,2].concat([3]).length").toInt32(), 3, "Array.concat")
    try expect(context.evaluateScript("({a:1}) instanceof Object").toBool(), "instanceof")
    _ = context.evaluateScript("1+1", withSourceURL: URL(string: "https://example.test/app.js"))
    try expectEqual(context.evaluateScript("40+2")!.description, "42", "JSValue.description")

    func expectGap(_ script: String, contains fragment: String, _ message: String) throws {
        context.exception = nil
        _ = context.evaluateScript(script)
        let text = context.exception?.toString() ?? ""
        try expect(context.exception != nil, "\(message) should throw")
        try expect(jscIndexOfProbe(text, fragment) != nil, "\(message): \(text)")
        try expect(context.exception.forProperty("line").isNumber, "\(message) line")
        try expect(context.exception.forProperty("column").isNumber, "\(message) column")
        try expectEqual(context.exception.forProperty("name").toString(), "SyntaxError", "\(message) SyntaxError")
    }
    try expectGap("class Foo {}", contains: "class", "class gap")
    try expectGap("async function f(){}", contains: "async", "async gap")
    try expectGap("/a+/", contains: "regular expression", "regex gap")
    try expectGap("x => x", contains: "arrow", "arrow gap")
    try expectGap("`hi`", contains: "template", "template gap")

    _ = context.evaluateScript("\nclass Foo {}")
    try expectEqual(context.exception.forProperty("line").toInt32(), 2, "syntax line is 2")
}

func jscIndexOfProbe(_ haystack: String, _ needle: String) -> Int? {
    let hay = Array(haystack)
    let need = Array(needle)
    if need.isEmpty { return 0 }
    if need.count > hay.count { return nil }
    for index in 0...(hay.count - need.count) {
        var matched = true
        for offset in 0..<need.count {
            if hay[index + offset] != need[offset] {
                matched = false
                break
            }
        }
        if matched { return index }
    }
    return nil
}

func assertRemainingValueAPI() throws {
    let context = JSContext()
    try expect(JSValue(newBigIntFrom: 8.0, in: context)?.isBigInt == true, "bigint double")
    try expect(JSValue(newBigIntFromDouble: 8.0, inContext: context)?.isBigInt == true, "bigint double inContext")
    try expect(JSValue(newBigIntFrom: "77", in: context)?.isBigInt == true, "bigint string")
    try expect(JSValue(newBigIntFromString: "77", inContext: context)?.isBigInt == true, "bigint string inContext")
    try expect(JSValue(newBigIntFrom: UInt64(5), in: context)?.isBigInt == true, "bigint uint64")
    try expect(JSValue(newBigIntFromUInt64: 5, inContext: context)?.isBigInt == true, "bigint uint64 inContext")

    let left = JSValue(double: 3, in: context)!
    let right = JSValue(double: 9, in: context)!
    try expect(left.compare(right) == .lessThan, "compare JSValue lessThan")
    try expect(!left.isEqual(to: right), "isEqual to")
    try expect(JSValue(object: "12", in: context).isEqualWithTypeCoercion(to: 12), "coercion equal")
    let ctor = context.evaluateScript("function Box(v){ this.v = v } Box")!
    let instance = ctor.construct(withArguments: [1])!
    try expect(instance.isInstance(of: ctor), "isInstanceOf")
    try expect(instance.isDate == false, "not date")
    let dateValue = JSValue(object: Date(timeIntervalSince1970: 1), in: context)!
    try expect(dateValue.isDate, "isDate")
    try expect(dateValue.toDate() != nil, "toDate")
    try expectEqual(dateValue.toInt64(), 1000, "date ToNumber ms")
    try expectEqual(dateValue.toUInt64(), 1000, "toUInt64")
    try expectEqual(JSValue(int32: 4, in: context).toNumber().intValue, 4, "toNumber NSNumber")
    try expect(JSValue(undefinedIn: context).toObject() == nil, "undefined toObject nil")
    try expect(JSValue(object: "hi", in: context).toObjectOf(NSString.self) != nil, "toObjectOf NSString")
    let dictValue = context.evaluateScript("({k:1, z:2})")!
    try expectEqual(dictValue.toDictionary()?.count, 2, "toDictionary")
    dictValue.defineProperty("hidden", descriptor: [
        JSPropertyDescriptorValueKey: 9,
        JSPropertyDescriptorEnumerableKey: false,
        JSPropertyDescriptorWritableKey: true,
        JSPropertyDescriptorConfigurableKey: true
    ] as [AnyHashable: Any])
    try expectEqual(dictValue.forProperty("hidden").toInt32(), 9, "defineProperty")
    dictValue.setObject(8, forKeyedSubscript: "k")
    try expectEqual(dictValue.objectForKeyedSubscript("k").toInt32(), 8, "keyed set")
    let array = context.evaluateScript("[1,2]")!
    array.setObject(5, atIndexedSubscript: 0)
    try expectEqual(array.objectAtIndexedSubscript(0).toInt32(), 5, "indexed set")

    let add: ([Any]) -> Any = { args in
        let values = args.compactMap { ($0 as? JSValue)?.toDouble() }
        return values.reduce(0, +)
    }
    context.setObject(add, forKeyedSubscript: "hostAdd" as NSString)
    try expectEqual(context.evaluateScript("hostAdd(2, 3)").toInt32(), 5, "closure [Any]->Any")
    let ping: () -> Any = { "pong" }
    context.setObject(ping, forKeyedSubscript: "hostPing" as NSString)
    try expectEqual(context.evaluateScript("hostPing()").toString(), "pong", "closure ()->Any")
}

func assertClassAndRemainingCAPI() throws {
    try expect(JSRelationCondition.lessThan != JSRelationCondition.equal, "rel !=")
    try expect(kJSTypedArrayTypeFloat32Array != kJSTypedArrayTypeNone, "typed !=")
    try expect(JSType(rawValue: 3) == kJSTypeNumber, "JSType rawValue init")
    try expect(JSTypedArrayType(rawValue: 8) == kJSTypedArrayTypeFloat32Array, "typed rawValue init")
    try expect(JSRelationCondition(rawValue: 3) == .lessThan, "rel rawValue init")
    var hasher = Hasher()
    kJSTypeNumber.hash(into: &hasher)
    kJSTypedArrayTypeInt8Array.hash(into: &hasher)
    JSRelationCondition.equal.hash(into: &hasher)
    _ = kJSTypeNumber.hashValue
    _ = kJSTypedArrayTypeInt8Array.hashValue
    _ = JSRelationCondition.equal.hashValue
    let classAttrs: JSClassAttributes = JSClassAttributes(kJSClassAttributeNone)
    let propAttrs: JSPropertyAttributes = JSPropertyAttributes(kJSPropertyAttributeReadOnly)
    try expect(classAttrs == 0, "JSClassAttributes")
    try expect(propAttrs != 0, "JSPropertyAttributes")
    let _: JSValueProperty? = nil

    let ctx = JSGlobalContextCreate(nil)!
    defer { JSGlobalContextRelease(ctx) }
    let group = JSContextGroupCreate()!
    _ = JSContextGroupRetain(group)
    let grouped = JSGlobalContextCreateInGroup(group, nil)!
    _ = JSGlobalContextRetain(grouped)
    try expect(JSContextGetGlobalObject(grouped) != nil, "global object")
    JSGlobalContextRelease(grouped)
    JSContextGroupRelease(group)
    JSContextGroupRelease(group)

    let hello = JSStringCreateWithUTF8CString("hello")!
    _ = JSStringRetain(hello)
    try expect(JSStringGetCharactersPtr(hello) != nil, "chars ptr")
    JSStringRelease(hello)
    JSStringRelease(hello)

    var exception: JSValueRef?
    let object = JSObjectMake(ctx, nil, nil)!
    JSObjectSetProperty(ctx, object, JSStringCreateWithUTF8CString("k"), JSValueMakeNumber(ctx, 3), 0, &exception)
    let key = JSValueMakeString(ctx, JSStringCreateWithUTF8CString("k"))
    try expect(JSObjectHasPropertyForKey(ctx, object, key, &exception), "has for key")
    try expectEqual(JSValueToNumber(ctx, JSObjectGetPropertyForKey(ctx, object, key, &exception), nil), 3, "get for key")
    JSObjectSetPropertyForKey(ctx, object, JSValueMakeString(ctx, JSStringCreateWithUTF8CString("n")), JSValueMakeNumber(ctx, 4), 0, &exception)
    try expect(JSObjectDeletePropertyForKey(ctx, object, JSValueMakeString(ctx, JSStringCreateWithUTF8CString("n")), &exception), "delete for key")
    let proto = JSObjectMake(ctx, nil, nil)!
    JSObjectSetPrototype(ctx, object, proto)
    try expect(JSObjectGetPrototype(ctx, object) != nil, "prototype")

    let ctor = JSEvaluateScript(ctx, JSStringCreateWithUTF8CString("function Box(v){ this.v = v } Box"), nil, nil, 1, &exception)!
    try expect(JSObjectIsFunction(ctx, ctor), "is function")
    try expect(JSObjectIsConstructor(ctx, ctor), "is constructor")
    let ctorArgs: [JSValueRef?] = [JSValueMakeNumber(ctx, 9)]
    let constructed = ctorArgs.withUnsafeBufferPointer {
        JSObjectCallAsConstructor(ctx, ctor, 1, $0.baseAddress, &exception)
    }!
    try expect(JSValueIsInstanceOfConstructor(ctx, constructed, ctor, &exception), "instance of")
    let fn = JSEvaluateScript(ctx, JSStringCreateWithUTF8CString("function id(x){ return x } id"), nil, nil, 1, &exception)!
    let fnArgs: [JSValueRef?] = [JSValueMakeNumber(ctx, 6)]
    let called = fnArgs.withUnsafeBufferPointer {
        JSObjectCallAsFunction(ctx, fn, nil, 1, $0.baseAddress, &exception)
    }!
    try expectEqual(JSValueToNumber(ctx, called, nil), 6, "call as function")
    try expect(JSValueCompare(ctx, JSValueMakeNumber(ctx, 1), JSValueMakeNumber(ctx, 2), nil) == .lessThan, "JSValueCompare")
    try expect(JSValueCompareDouble(ctx, JSValueMakeNumber(ctx, 3), 3, nil) == .equal, "compare double c")
    try expect(JSValueCompareInt64(ctx, JSValueMakeNumber(ctx, 3), 4, nil) == .lessThan, "compare int64 c")
    try expect(JSValueCompareUInt64(ctx, JSValueMakeNumber(ctx, 5), 4, nil) == .greaterThan, "compare uint64 c")

    let types: [JSTypedArrayType] = [
        kJSTypedArrayTypeInt16Array, kJSTypedArrayTypeInt32Array,
        kJSTypedArrayTypeUint16Array, kJSTypedArrayTypeUint32Array,
        kJSTypedArrayTypeUint8ClampedArray, kJSTypedArrayTypeFloat32Array,
        kJSTypedArrayTypeFloat64Array, kJSTypedArrayTypeBigInt64Array,
        kJSTypedArrayTypeBigUint64Array
    ]
    for type in types {
        let view = JSObjectMakeTypedArray(ctx, type, 2, &exception)!
        try expect(JSValueGetTypedArrayType(ctx, view, &exception) == type, "typed \(type.rawValue)")
    }

    let dealloc: JSTypedArrayBytesDeallocator = { _, _ in }
    let raw = UnsafeMutableRawPointer.allocate(byteCount: 8, alignment: 8)
    raw.initializeMemory(as: UInt8.self, repeating: 0, count: 8)
    let noCopy = JSObjectMakeArrayBufferWithBytesNoCopy(ctx, raw, 8, dealloc, nil, &exception)!
    try expectEqual(JSObjectGetArrayBufferByteLength(ctx, noCopy, &exception), 8, "nocopy buffer")
    let typedNoCopy = JSObjectMakeTypedArrayWithBytesNoCopy(ctx, kJSTypedArrayTypeUint8Array, raw, 8, dealloc, nil, &exception)!
    try expectEqual(JSObjectGetTypedArrayLength(ctx, typedNoCopy, &exception), 8, "typed nocopy")

    let made = JSObjectMakeFunction(ctx, JSStringCreateWithUTF8CString("id"), 1, nil, JSStringCreateWithUTF8CString("return 7"), nil, 1, &exception)
    try expect(made != nil, "make function")
    try expectEqual(JSValueToNumber(ctx, JSObjectCallAsFunction(ctx, made, nil, 0, nil, &exception), nil), 7, "made function body")

    try assertJSClassDispatch(ctx)
}

private var jsClassInitCount: Int32 = 0
private var jsClassFinalizeCount: Int32 = 0
private var jsClassConverted = false

func assertJSClassDispatch(_ ctx: JSGlobalContextRef) throws {
    let answerChars = Array("answer".utf8CString)
    let pingChars = Array("ping".utf8CString)
    let classNameChars = Array("Probe".utf8CString)
    try answerChars.withUnsafeBufferPointer { answerBuf in
        try pingChars.withUnsafeBufferPointer { pingBuf in
            try classNameChars.withUnsafeBufferPointer { classBuf in
                let staticValues = [
                    JSStaticValue(
                        name: answerBuf.baseAddress,
                        getProperty: { ctx, _, _, _ in JSValueMakeNumber(ctx, 11) },
                        setProperty: { _, _, _, _, _ in true },
                        attributes: 0
                    ),
                    JSStaticValue()
                ]
                let staticFunctions = [
                    JSStaticFunction(
                        name: pingBuf.baseAddress,
                        callAsFunction: { ctx, _, _, _, _, _ in JSValueMakeString(ctx, JSStringCreateWithUTF8CString("pong")) },
                        attributes: 0
                    ),
                    JSStaticFunction()
                ]
                var definition = JSClassDefinition(
                    version: 0,
                    attributes: JSClassAttributes(kJSClassAttributeNone),
                    className: classBuf.baseAddress,
                    parentClass: nil,
                    staticValues: nil,
                    staticFunctions: nil,
                    initialize: { _, _ in jsClassInitCount += 1 },
                    finalize: { _ in jsClassFinalizeCount += 1 },
                    hasProperty: { _, _, _ in true },
                    getProperty: { ctx, _, name, _ in
                        if JSStringIsEqualToUTF8CString(name, "dynamic") {
                            return JSValueMakeNumber(ctx, 13)
                        }
                        return nil
                    },
                    setProperty: { ctx, object, name, value, _ in
                        if JSStringIsEqualToUTF8CString(name, "dynamic") {
                            JSObjectSetProperty(ctx, object, JSStringCreateWithUTF8CString("_dyn"), value, 0, nil)
                            return true
                        }
                        return false
                    },
                    deleteProperty: { _, _, _, _ in true },
                    getPropertyNames: { _, _, accumulator in
                        JSPropertyNameAccumulatorAddName(accumulator, JSStringCreateWithUTF8CString("dynamic"))
                    },
                    callAsFunction: { ctx, _, _, _, _, _ in JSValueMakeNumber(ctx, 15) },
                    callAsConstructor: { ctx, _, _, _, _ in JSObjectMake(ctx, nil, nil) },
                    hasInstance: { _, _, _, _ in true },
                    convertToType: { ctx, _, type, _ in
                        jsClassConverted = true
                        if type == kJSTypeNumber { return JSValueMakeNumber(ctx, 1) }
                        return JSValueMakeString(ctx, JSStringCreateWithUTF8CString("probe"))
                    }
                )
                try staticValues.withUnsafeBufferPointer { valuesBuf in
                    try staticFunctions.withUnsafeBufferPointer { fnBuf in
                        definition.staticValues = valuesBuf.baseAddress
                        definition.staticFunctions = fnBuf.baseAddress
                        try expectEqual(definition.version, 0, "definition version")
                        try expectEqual(definition.attributes, 0, "definition attributes")
                        try expect(definition.className != nil, "className")
                        try expect(definition.parentClass == nil, "parentClass")
                        try expect(definition.staticValues != nil, "staticValues")
                        try expect(definition.staticFunctions != nil, "staticFunctions")
                        try expect(definition.initialize != nil, "initialize")
                        try expect(definition.finalize != nil, "finalize")
                        try expect(definition.hasProperty != nil, "hasProperty")
                        try expect(definition.getProperty != nil, "getProperty")
                        try expect(definition.setProperty != nil, "setProperty")
                        try expect(definition.deleteProperty != nil, "deleteProperty")
                        try expect(definition.getPropertyNames != nil, "getPropertyNames")
                        try expect(definition.callAsFunction != nil, "callAsFunction field")
                        try expect(definition.callAsConstructor != nil, "callAsConstructor field")
                        try expect(definition.hasInstance != nil, "hasInstance")
                        try expect(definition.convertToType != nil, "convertToType")
                        try expect(staticValues[0].name != nil, "static value name")
                        try expect(staticValues[0].getProperty != nil, "static get")
                        try expect(staticValues[0].setProperty != nil, "static set")
                        try expect(staticValues[0].attributes == 0, "static attrs")
                        try expect(staticFunctions[0].name != nil, "static fn name")
                        try expect(staticFunctions[0].callAsFunction != nil, "static fn call")
                        try expect(staticFunctions[0].attributes == 0, "static fn attrs")

                        let jsClass: JSClassRef = JSClassCreate(&definition)!
                        _ = JSClassRetain(jsClass)
                        let object = JSObjectMake(ctx, jsClass, nil)!
                        try expect(jsClassInitCount > 0, "initialize ran")
                        try expect(JSValueIsObjectOfClass(ctx, object, jsClass), "is object of class")
                        try expectEqual(JSValueToNumber(ctx, JSObjectGetProperty(ctx, object, JSStringCreateWithUTF8CString("dynamic"), nil), nil), 13, "class getProperty")
                        try expectEqual(JSValueToNumber(ctx, JSObjectGetProperty(ctx, object, JSStringCreateWithUTF8CString("answer"), nil), nil), 11, "static value")
                        try expect(JSObjectHasProperty(ctx, object, JSStringCreateWithUTF8CString("dynamic")), "hasProperty callback")
                        JSObjectSetProperty(ctx, object, JSStringCreateWithUTF8CString("dynamic"), JSValueMakeNumber(ctx, 1), 0, nil)
                        try expect(JSObjectDeleteProperty(ctx, object, JSStringCreateWithUTF8CString("gone"), nil), "deleteProperty callback")
                        let names = JSObjectCopyPropertyNames(ctx, object)!
                        try expect(JSPropertyNameArrayGetCount(names) >= 1, "getPropertyNames")
                        JSPropertyNameArrayRelease(names)
                        let ping = JSObjectGetProperty(ctx, object, JSStringCreateWithUTF8CString("ping"), nil)
                        try expect(JSObjectIsFunction(ctx, ping), "static function")
                        var exception: JSValueRef?
                        let pingResult = JSObjectCallAsFunction(ctx, ping, object, 0, nil, &exception)!
                        try expect(JSStringIsEqualToUTF8CString(JSValueToStringCopy(ctx, pingResult, nil), "pong"), "static fn result")

                        let callbackFn = JSObjectMakeFunctionWithCallback(ctx, JSStringCreateWithUTF8CString("cb"), { ctx, _, _, _, _, _ in
                            JSValueMakeNumber(ctx, 21)
                        })!
                        try expectEqual(JSValueToNumber(ctx, JSObjectCallAsFunction(ctx, callbackFn, nil, 0, nil, &exception), nil), 21, "function with callback")
                        let jsCtor = JSObjectMakeConstructor(ctx, jsClass, { ctx, _, _, _, _ in
                            JSObjectMake(ctx, nil, nil)
                        })!
                        let built = JSObjectCallAsConstructor(ctx, jsCtor, 0, nil, &exception)!
                        try expect(JSValueIsObject(ctx, built), "make constructor")
                        try expect(JSValueIsInstanceOfConstructor(ctx, object, jsCtor, &exception), "hasInstance")
                        _ = JSValueToNumber(ctx, object, &exception)
                        try expect(jsClassConverted, "convertToType")

                        JSClassRelease(jsClass)
                        JSClassRelease(jsClass)
                    }
                }
            }
        }
    }
}

do {
    try assertTypesAndConstants()
    try assertCStringAndContext()
    try assertEvaluateAndValues()
    try assertCAPIValues()
    try assertObjectsAndTypedArrays()
    try assertObjCMachine()
    try assertInterpreterSubset()
    try assertRemainingValueAPI()
    try assertClassAndRemainingCAPI()
    print("JAVASCRIPTCORE_AGENT_RUNTIME_OK")
} catch {
    fputs("JavaScriptCore runtime failed: \(error)\n", stderr)
    exit(1)
}
