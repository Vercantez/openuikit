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

var jsClassInitCount: Int32 = 0
var jsClassFinalizeCount: Int32 = 0
var jsClassConverted = false

func testJSClassDispatch() throws {
    _ = JSStaticValue()
    _ = JSStaticFunction()
    _ = JSClassDefinition()
    _ = kJSClassDefinitionEmpty
    jsClassInitCount = 0
    jsClassFinalizeCount = 0
    jsClassConverted = false
    let ctx = JSGlobalContextCreate(nil)!
    defer { JSGlobalContextRelease(ctx) }
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
                        let _: JSClassRef = jsClass
                        let _: JSObjectInitializeCallback = definition.initialize
                        let _: JSObjectFinalizeCallback = definition.finalize
                        let _: JSObjectHasPropertyCallback = definition.hasProperty
                        let _: JSObjectGetPropertyCallback = definition.getProperty
                        let _: JSObjectSetPropertyCallback = definition.setProperty
                        let _: JSObjectDeletePropertyCallback = definition.deleteProperty
                        let _: JSObjectGetPropertyNamesCallback = definition.getPropertyNames
                        let _: JSObjectCallAsFunctionCallback = definition.callAsFunction
                        let _: JSObjectCallAsConstructorCallback = definition.callAsConstructor
                        let _: JSObjectHasInstanceCallback = definition.hasInstance
                        let _: JSObjectConvertToTypeCallback = definition.convertToType
                    }
                }
            }
        }
    }
}
