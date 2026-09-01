#include "JavaScriptCore.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int g_parent_init;
static int g_child_init;
static int g_parent_final;
static int g_child_final;
static int g_has;
static int g_get;
static int g_set;
static int g_delete;
static int g_names;
static int g_call;
static int g_ctor;
static int g_has_instance;
static int g_convert;
static int g_static_get;
static int g_static_set;
static int g_static_fn;
static int g_fn_callback;
static int g_count;
static int g_stash;
static char g_init_order[8];
static int g_init_order_n;
static char g_final_order[8];
static int g_final_order_n;

static void fail(const char *message) {
    fprintf(stderr, "JAVASCRIPTCORE_CABI_PROBE_FAIL: %s\n", message);
    abort();
}

static void expect(int condition, const char *message) {
    if (!condition) {
        fail(message);
    }
}

static JSStringRef str(const char *text) {
    return JSStringCreateWithUTF8CString(text);
}

static void ParentInitialize(JSContextRef ctx, JSObjectRef object) {
    (void)ctx;
    (void)object;
    g_parent_init += 1;
    if (g_init_order_n < (int)sizeof(g_init_order) - 1) {
        g_init_order[g_init_order_n++] = 'P';
    }
}

static void ChildInitialize(JSContextRef ctx, JSObjectRef object) {
    (void)ctx;
    (void)object;
    g_child_init += 1;
    if (g_init_order_n < (int)sizeof(g_init_order) - 1) {
        g_init_order[g_init_order_n++] = 'C';
    }
}

static void ParentFinalize(JSObjectRef object) {
    (void)object;
    g_parent_final += 1;
    if (g_final_order_n < (int)sizeof(g_final_order) - 1) {
        g_final_order[g_final_order_n++] = 'P';
    }
}

static void ChildFinalize(JSObjectRef object) {
    (void)object;
    g_child_final += 1;
    if (g_final_order_n < (int)sizeof(g_final_order) - 1) {
        g_final_order[g_final_order_n++] = 'C';
    }
}

static bool HasProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyName) {
    (void)ctx;
    (void)object;
    g_has += 1;
    return JSStringIsEqualToUTF8CString(propertyName, "hidden")
        || JSStringIsEqualToUTF8CString(propertyName, "magic")
        || JSStringIsEqualToUTF8CString(propertyName, "stash");
}

static JSValueRef GetProperty(
    JSContextRef ctx,
    JSObjectRef object,
    JSStringRef propertyName,
    JSValueRef *exception
) {
    (void)object;
    (void)exception;
    g_get += 1;
    if (JSStringIsEqualToUTF8CString(propertyName, "magic")) {
        return JSValueMakeNumber(ctx, 99);
    }
    if (JSStringIsEqualToUTF8CString(propertyName, "stash")) {
        return JSValueMakeNumber(ctx, (double)g_stash);
    }
    return NULL;
}

static bool SetProperty(
    JSContextRef ctx,
    JSObjectRef object,
    JSStringRef propertyName,
    JSValueRef value,
    JSValueRef *exception
) {
    (void)object;
    g_set += 1;
    if (JSStringIsEqualToUTF8CString(propertyName, "stash")) {
        g_stash = (int)JSValueToNumber(ctx, value, exception);
        return true;
    }
    return false;
}

static bool DeleteProperty(
    JSContextRef ctx,
    JSObjectRef object,
    JSStringRef propertyName,
    JSValueRef *exception
) {
    (void)ctx;
    (void)object;
    (void)exception;
    g_delete += 1;
    if (JSStringIsEqualToUTF8CString(propertyName, "stash")) {
        g_stash = 0;
        return true;
    }
    return false;
}

static void GetPropertyNames(
    JSContextRef ctx,
    JSObjectRef object,
    JSPropertyNameAccumulatorRef accumulator
) {
    (void)ctx;
    (void)object;
    g_names += 1;
    JSStringRef name = str("magic");
    JSPropertyNameAccumulatorAddName(accumulator, name);
    JSStringRelease(name);
}

static JSValueRef CallAsFunction(
    JSContextRef ctx,
    JSObjectRef function,
    JSObjectRef thisObject,
    size_t argumentCount,
    const JSValueRef arguments[],
    JSValueRef *exception
) {
    (void)function;
    (void)thisObject;
    (void)argumentCount;
    (void)arguments;
    (void)exception;
    g_call += 1;
    return JSValueMakeNumber(ctx, 7);
}

static JSObjectRef CallAsConstructor(
    JSContextRef ctx,
    JSObjectRef constructor,
    size_t argumentCount,
    const JSValueRef arguments[],
    JSValueRef *exception
) {
    (void)constructor;
    (void)argumentCount;
    (void)arguments;
    (void)exception;
    g_ctor += 1;
    return JSObjectMake(ctx, NULL, NULL);
}

static bool HasInstance(
    JSContextRef ctx,
    JSObjectRef constructor,
    JSValueRef possibleInstance,
    JSValueRef *exception
) {
    (void)constructor;
    (void)exception;
    g_has_instance += 1;
    return JSValueIsObject(ctx, possibleInstance);
}

static JSValueRef ConvertToType(
    JSContextRef ctx,
    JSObjectRef object,
    JSType type,
    JSValueRef *exception
) {
    (void)object;
    (void)exception;
    g_convert += 1;
    if (type == kJSTypeNumber) {
        return JSValueMakeNumber(ctx, 123);
    }
    if (type == kJSTypeString) {
        JSStringRef text = str("converted");
        JSValueRef value = JSValueMakeString(ctx, text);
        JSStringRelease(text);
        return value;
    }
    return NULL;
}

static JSValueRef GetCount(
    JSContextRef ctx,
    JSObjectRef object,
    JSStringRef propertyName,
    JSValueRef *exception
) {
    (void)object;
    (void)propertyName;
    (void)exception;
    g_static_get += 1;
    return JSValueMakeNumber(ctx, (double)g_count);
}

static bool SetCount(
    JSContextRef ctx,
    JSObjectRef object,
    JSStringRef propertyName,
    JSValueRef value,
    JSValueRef *exception
) {
    (void)object;
    (void)propertyName;
    g_static_set += 1;
    g_count = (int)JSValueToNumber(ctx, value, exception);
    return true;
}

static JSValueRef AddFn(
    JSContextRef ctx,
    JSObjectRef function,
    JSObjectRef thisObject,
    size_t argumentCount,
    const JSValueRef arguments[],
    JSValueRef *exception
) {
    (void)function;
    (void)thisObject;
    g_static_fn += 1;
    double left = argumentCount > 0 ? JSValueToNumber(ctx, arguments[0], exception) : 0;
    double right = argumentCount > 1 ? JSValueToNumber(ctx, arguments[1], exception) : 0;
    return JSValueMakeNumber(ctx, left + right);
}

static JSValueRef CallbackFn(
    JSContextRef ctx,
    JSObjectRef function,
    JSObjectRef thisObject,
    size_t argumentCount,
    const JSValueRef arguments[],
    JSValueRef *exception
) {
    (void)function;
    (void)thisObject;
    (void)argumentCount;
    (void)arguments;
    (void)exception;
    g_fn_callback += 1;
    return JSValueMakeNumber(ctx, 11);
}

static JSStaticValue kStaticValues[] = {
    { "count", GetCount, SetCount, kJSPropertyAttributeNone },
    { NULL, NULL, NULL, 0 }
};

static JSStaticFunction kStaticFunctions[] = {
    { "add", AddFn, kJSPropertyAttributeNone },
    { NULL, NULL, 0 }
};

static void DeallocBytes(void *bytes, void *deallocatorContext) {
    (void)deallocatorContext;
    free(bytes);
}

int main(void) {
    JSContextGroupRef group = JSContextGroupCreate();
    expect(group != NULL, "JSContextGroupCreate");
    JSContextGroupRetain(group);

    JSGlobalContextRef created = JSGlobalContextCreate(NULL);
    expect(created != NULL, "JSGlobalContextCreate");
    JSGlobalContextRetain(created);
    JSGlobalContextRelease(created);
    JSGlobalContextRelease(created);

    JSGlobalContextRef ctx = JSGlobalContextCreateInGroup(group, NULL);
    expect(ctx != NULL, "JSGlobalContextCreateInGroup");
    expect(JSContextGetGlobalContext(ctx) == ctx, "JSContextGetGlobalContext");
    expect(JSContextGetGroup(ctx) != NULL, "JSContextGetGroup");
    expect(JSContextGetGlobalObject(ctx) != NULL, "JSContextGetGlobalObject");

    JSStringRef name = str("cabi-probe");
    JSGlobalContextSetName(ctx, name);
    JSStringRef copiedName = JSGlobalContextCopyName(ctx);
    expect(JSStringIsEqual(name, copiedName), "JSGlobalContextCopyName");
    JSStringRelease(name);
    JSStringRelease(copiedName);

    JSGlobalContextSetInspectable(ctx, true);
    expect(JSGlobalContextIsInspectable(ctx), "JSGlobalContextIsInspectable");
    JSGlobalContextSetInspectable(ctx, false);

    JSValueRef exception = NULL;
    JSStringRef script = str("1 + 2 * 3");
    JSValueRef sum = JSEvaluateScript(ctx, script, NULL, NULL, 1, &exception);
    expect(exception == NULL, "JSEvaluateScript exception");
    expect(JSValueIsNumber(ctx, sum), "sum is number");
    expect(JSValueToNumber(ctx, sum, &exception) == 7, "1+2*3");
    expect(JSValueGetType(ctx, sum) == kJSTypeNumber, "JSValueGetType number");
    JSStringRelease(script);

    JSStringRef syntax = str("function ok() { return 1; }");
    expect(JSCheckScriptSyntax(ctx, syntax, NULL, 1, &exception), "JSCheckScriptSyntax");
    JSStringRelease(syntax);

    JSValueRef undef = JSValueMakeUndefined(ctx);
    JSValueRef nul = JSValueMakeNull(ctx);
    JSValueRef flag = JSValueMakeBoolean(ctx, true);
    JSValueRef num = JSValueMakeNumber(ctx, 8);
    JSStringRef hello = str("hello");
    JSValueRef text = JSValueMakeString(ctx, hello);
    JSValueRef sym = JSValueMakeSymbol(ctx, hello);
    expect(JSValueIsUndefined(ctx, undef), "undefined");
    expect(JSValueIsNull(ctx, nul), "null");
    expect(JSValueIsBoolean(ctx, flag) && JSValueToBoolean(ctx, flag), "boolean");
    expect(JSValueIsNumber(ctx, num), "number");
    expect(JSValueIsString(ctx, text), "string");
    expect(JSValueIsSymbol(ctx, sym), "symbol");
    expect(JSValueIsStrictEqual(ctx, num, JSValueMakeNumber(ctx, 8)), "strict equal");
    expect(JSValueIsEqual(ctx, num, JSValueMakeNumber(ctx, 8), &exception), "loose equal");
    expect(JSValueCompare(ctx, num, JSValueMakeNumber(ctx, 3), &exception) == kJSRelationConditionGreaterThan, "compare");
    expect(JSValueCompareDouble(ctx, num, 8, &exception) == kJSRelationConditionEqual, "compare double");
    expect(JSValueCompareInt64(ctx, num, 8, &exception) == kJSRelationConditionEqual, "compare int64");
    expect(JSValueCompareUInt64(ctx, num, 8, &exception) == kJSRelationConditionEqual, "compare uint64");
    expect(JSValueToInt32(ctx, num, &exception) == 8, "to int32");
    expect(JSValueToUInt32(ctx, num, &exception) == 8, "to uint32");
    expect(JSValueToInt64(ctx, num, &exception) == 8, "to int64");
    expect(JSValueToUInt64(ctx, num, &exception) == 8, "to uint64");

    JSStringRef jsonIn = str("{\"k\":7}");
    JSValueRef parsed = JSValueMakeFromJSONString(ctx, jsonIn);
    expect(JSValueIsObject(ctx, parsed), "json object");
    JSStringRef jsonOut = JSValueCreateJSONString(ctx, parsed, 0, &exception);
    expect(jsonOut != NULL, "JSValueCreateJSONString");
    JSStringRelease(jsonIn);
    JSStringRelease(jsonOut);

    JSValueRef big = JSBigIntCreateWithInt64(ctx, 99, &exception);
    expect(JSValueIsBigInt(ctx, big), "bigint int64");
    expect(JSValueIsBigInt(ctx, JSBigIntCreateWithUInt64(ctx, 1, &exception)), "bigint uint64");
    expect(JSValueIsBigInt(ctx, JSBigIntCreateWithDouble(ctx, 2, &exception)), "bigint double");
    JSStringRef bigText = str("123");
    expect(JSValueIsBigInt(ctx, JSBigIntCreateWithString(ctx, bigText, &exception)), "bigint string");
    JSStringRelease(bigText);

    JSClassDefinition parentDef;
    memset(&parentDef, 0, sizeof(parentDef));
    parentDef.initialize = ParentInitialize;
    parentDef.finalize = ParentFinalize;
    JSClassRef parentClass = JSClassCreate(&parentDef);
    expect(parentClass != NULL, "parent JSClassCreate");
    JSClassRetain(parentClass);

    JSClassDefinition childDef;
    memset(&childDef, 0, sizeof(childDef));
    childDef.className = "Probe";
    childDef.parentClass = parentClass;
    childDef.staticValues = kStaticValues;
    childDef.staticFunctions = kStaticFunctions;
    childDef.initialize = ChildInitialize;
    childDef.finalize = ChildFinalize;
    childDef.hasProperty = HasProperty;
    childDef.getProperty = GetProperty;
    childDef.setProperty = SetProperty;
    childDef.deleteProperty = DeleteProperty;
    childDef.getPropertyNames = GetPropertyNames;
    childDef.callAsFunction = CallAsFunction;
    childDef.callAsConstructor = CallAsConstructor;
    childDef.hasInstance = HasInstance;
    childDef.convertToType = ConvertToType;
    JSClassRef childClass = JSClassCreate(&childDef);
    expect(childClass != NULL, "child JSClassCreate");

    int cookie = 42;
    JSObjectRef probe = JSObjectMake(ctx, childClass, &cookie);
    expect(probe != NULL, "JSObjectMake");
    expect(g_parent_init == 1 && g_child_init == 1, "initialize counts");
    expect(g_init_order_n == 2 && g_init_order[0] == 'P' && g_init_order[1] == 'C', "initialize parent first");
    expect(JSObjectGetPrivate(probe) == &cookie, "JSObjectGetPrivate");
    expect(JSObjectSetPrivate(probe, &g_count), "JSObjectSetPrivate");
    expect(JSValueIsObjectOfClass(ctx, probe, childClass), "JSValueIsObjectOfClass");
    expect(JSObjectIsFunction(ctx, probe), "class callAsFunction => function");
    expect(JSObjectIsConstructor(ctx, probe), "class callAsConstructor => constructor");

    JSStringRef countName = str("count");
    JSObjectSetProperty(ctx, probe, countName, JSValueMakeNumber(ctx, 5), kJSPropertyAttributeNone, &exception);
    JSValueRef countValue = JSObjectGetProperty(ctx, probe, countName, &exception);
    expect(JSValueToNumber(ctx, countValue, &exception) == 5, "staticValues get/set");
    expect(g_static_get > 0 && g_static_set > 0, "staticValues callbacks");
    expect(JSObjectHasProperty(ctx, probe, countName), "has static value");
    JSStringRelease(countName);

    JSStringRef addName = str("add");
    JSValueRef addFn = JSObjectGetProperty(ctx, probe, addName, &exception);
    JSValueRef addArgs[2] = { JSValueMakeNumber(ctx, 20), JSValueMakeNumber(ctx, 22) };
    JSValueRef addResult = JSObjectCallAsFunction(ctx, (JSObjectRef)addFn, probe, 2, addArgs, &exception);
    expect(JSValueToNumber(ctx, addResult, &exception) == 42, "staticFunctions call");
    expect(g_static_fn == 1, "staticFunctions callback");
    JSStringRelease(addName);

    JSStringRef magicName = str("magic");
    expect(JSObjectHasProperty(ctx, probe, magicName), "hasProperty magic");
    JSValueRef magic = JSObjectGetProperty(ctx, probe, magicName, &exception);
    expect(JSValueToNumber(ctx, magic, &exception) == 99, "getProperty magic");
    JSStringRef stashName = str("stash");
    JSObjectSetProperty(ctx, probe, stashName, JSValueMakeNumber(ctx, 8), kJSPropertyAttributeNone, &exception);
    expect(g_stash == 8, "setProperty stash");
    expect(JSObjectDeleteProperty(ctx, probe, stashName, &exception), "deleteProperty stash");
    expect(g_stash == 0, "delete cleared stash");
    JSStringRelease(magicName);
    JSStringRelease(stashName);

    JSPropertyNameArrayRef names = JSObjectCopyPropertyNames(ctx, probe);
    expect(JSPropertyNameArrayGetCount(names) > 0, "JSPropertyNameArrayGetCount");
    JSStringRef firstName = JSPropertyNameArrayGetNameAtIndex(names, 0);
    expect(firstName != NULL, "JSPropertyNameArrayGetNameAtIndex");
    JSPropertyNameArrayRetain(names);
    JSPropertyNameArrayRelease(names);
    JSPropertyNameArrayRelease(names);
    expect(g_names > 0, "getPropertyNames");

    JSValueRef called = JSObjectCallAsFunction(ctx, probe, NULL, 0, NULL, &exception);
    expect(JSValueToNumber(ctx, called, &exception) == 7, "callAsFunction");
    JSObjectRef constructed = JSObjectCallAsConstructor(ctx, probe, 0, NULL, &exception);
    expect(JSValueIsObject(ctx, constructed), "callAsConstructor");
    expect(g_call == 1 && g_ctor == 1, "call callbacks");
    expect(JSValueIsInstanceOfConstructor(ctx, constructed, probe, &exception), "hasInstance");
    expect(g_has_instance > 0, "hasInstance callback");

    expect(JSValueToNumber(ctx, probe, &exception) == 123, "convertToType number");
    JSStringRef converted = JSValueToStringCopy(ctx, probe, &exception);
    expect(JSStringIsEqualToUTF8CString(converted, "converted"), "convertToType string");
    JSStringRelease(converted);
    expect(g_convert >= 2, "convertToType callbacks");

    JSObjectRef proto = JSObjectMake(ctx, NULL, NULL);
    JSObjectSetPrototype(ctx, probe, proto);
    expect(JSValueIsObject(ctx, JSObjectGetPrototype(ctx, probe)), "prototype");

    JSStringRef idxName = str("0");
    JSObjectSetPropertyAtIndex(ctx, probe, 0, JSValueMakeNumber(ctx, 1), &exception);
    expect(JSValueToNumber(ctx, JSObjectGetPropertyAtIndex(ctx, probe, 0, &exception), &exception) == 1, "index");
    JSValueRef key = JSValueMakeString(ctx, idxName);
    expect(JSObjectHasPropertyForKey(ctx, probe, key, &exception), "has for key");
    JSObjectSetPropertyForKey(ctx, probe, JSValueMakeString(ctx, hello), JSValueMakeNumber(ctx, 3), kJSPropertyAttributeNone, &exception);
    expect(JSValueToNumber(ctx, JSObjectGetPropertyForKey(ctx, probe, JSValueMakeString(ctx, hello), &exception), &exception) == 3, "get for key");
    JSObjectDeletePropertyForKey(ctx, probe, JSValueMakeString(ctx, hello), &exception);
    JSStringRelease(idxName);

    JSObjectRef arr = JSObjectMakeArray(ctx, 2, addArgs, &exception);
    expect(JSValueIsArray(ctx, arr), "JSObjectMakeArray");
    JSObjectRef date = JSObjectMakeDate(ctx, 0, NULL, &exception);
    expect(JSValueIsDate(ctx, date), "JSObjectMakeDate");
    JSObjectRef err = JSObjectMakeError(ctx, 0, NULL, &exception);
    expect(JSValueIsObject(ctx, err), "JSObjectMakeError");
    JSStringRef pattern = str("a+");
    JSValueRef regexpArgs[1] = { JSValueMakeString(ctx, pattern) };
    JSObjectRef regexp = JSObjectMakeRegExp(ctx, 1, regexpArgs, &exception);
    expect(JSValueIsObject(ctx, regexp), "JSObjectMakeRegExp");
    JSStringRelease(pattern);

    JSStringRef body = str("return a + b;");
    JSStringRef p0 = str("a");
    JSStringRef p1 = str("b");
    JSStringRef params[2] = { p0, p1 };
    JSObjectRef scriptFn = JSObjectMakeFunction(ctx, str("add"), 2, params, body, NULL, 1, &exception);
    JSValueRef scriptResult = JSObjectCallAsFunction(ctx, scriptFn, NULL, 2, addArgs, &exception);
    expect(JSValueToNumber(ctx, scriptResult, &exception) == 42, "JSObjectMakeFunction");
    JSStringRelease(body);
    JSStringRelease(p0);
    JSStringRelease(p1);

    JSObjectRef cb = JSObjectMakeFunctionWithCallback(ctx, str("cb"), CallbackFn);
    JSValueRef cbResult = JSObjectCallAsFunction(ctx, cb, NULL, 0, NULL, &exception);
    expect(JSValueToNumber(ctx, cbResult, &exception) == 11, "JSObjectMakeFunctionWithCallback");
    expect(g_fn_callback == 1, "function callback");

    JSObjectRef ctor = JSObjectMakeConstructor(ctx, childClass, CallAsConstructor);
    JSObjectRef ctorResult = JSObjectCallAsConstructor(ctx, ctor, 0, NULL, &exception);
    expect(JSValueIsObject(ctx, ctorResult), "JSObjectMakeConstructor");

    JSObjectRef resolve = NULL;
    JSObjectRef reject = NULL;
    JSObjectRef promise = JSObjectMakeDeferredPromise(ctx, &resolve, &reject, &exception);
    expect(promise != NULL && resolve != NULL && reject != NULL, "JSObjectMakeDeferredPromise");

    JSObjectRef ta = JSObjectMakeTypedArray(ctx, kJSTypedArrayTypeUint8Array, 4, &exception);
    expect(JSValueGetTypedArrayType(ctx, ta, &exception) == kJSTypedArrayTypeUint8Array, "typed array type");
    expect(JSObjectGetTypedArrayLength(ctx, ta, &exception) == 4, "typed length");
    expect(JSObjectGetTypedArrayByteLength(ctx, ta, &exception) == 4, "typed byte length");
    expect(JSObjectGetTypedArrayByteOffset(ctx, ta, &exception) == 0, "typed offset");
    JSObjectRef buffer1 = JSObjectGetTypedArrayBuffer(ctx, ta, &exception);
    JSObjectRef buffer2 = JSObjectGetTypedArrayBuffer(ctx, ta, &exception);
    expect(buffer1 != NULL && buffer1 == buffer2, "typed-array buffer interned identity");
    unsigned char *bytes = JSObjectGetTypedArrayBytesPtr(ctx, ta, &exception);
    expect(bytes != NULL, "typed bytes");
    bytes[0] = 42;
    unsigned char *bufferBytes = JSObjectGetArrayBufferBytesPtr(ctx, buffer1, &exception);
    expect(bufferBytes != NULL && bufferBytes[0] == 42, "buffer shares storage");
    expect(JSObjectGetArrayBufferByteLength(ctx, buffer1, &exception) >= 4, "buffer length");

    JSObjectRef view = JSObjectMakeTypedArrayWithArrayBuffer(ctx, kJSTypedArrayTypeUint8Array, buffer1, &exception);
    expect(JSObjectGetTypedArrayBuffer(ctx, view, &exception) == buffer1, "view buffer identity");
    JSObjectRef view2 = JSObjectMakeTypedArrayWithArrayBufferAndOffset(ctx, kJSTypedArrayTypeUint8Array, buffer1, 1, 2, &exception);
    expect(JSObjectGetTypedArrayByteOffset(ctx, view2, &exception) == 1, "offset view");
    expect(JSObjectGetTypedArrayLength(ctx, view2, &exception) == 2, "offset length");

    void *raw = malloc(8);
    expect(raw != NULL, "malloc");
    memset(raw, 0, 8);
    JSObjectRef noCopy = JSObjectMakeArrayBufferWithBytesNoCopy(ctx, raw, 8, DeallocBytes, NULL, &exception);
    expect(JSObjectGetArrayBufferByteLength(ctx, noCopy, &exception) == 8, "no-copy buffer");
    JSObjectRef noCopyView = JSObjectMakeTypedArrayWithBytesNoCopy(
        ctx,
        kJSTypedArrayTypeUint8Array,
        malloc(4),
        4,
        DeallocBytes,
        NULL,
        &exception
    );
    expect(JSObjectGetTypedArrayLength(ctx, noCopyView, &exception) == 4, "no-copy typed array");

    JSStringRef taName = str("ta");
    JSObjectSetProperty(ctx, JSContextGetGlobalObject(ctx), taName, ta, kJSPropertyAttributeNone, &exception);
    JSStringRelease(taName);
    JSValueProtect(ctx, buffer1);
    JSGarbageCollect(ctx);
    expect(JSObjectGetTypedArrayBuffer(ctx, ta, &exception) == buffer1, "buffer survives GC while protected/rooted");
    unsigned char *still = JSObjectGetArrayBufferBytesPtr(ctx, buffer1, &exception);
    expect(still != NULL && still[0] == 42, "buffer bytes live after GC");
    JSValueUnprotect(ctx, buffer1);

    JSClassDefinition gcDef;
    memset(&gcDef, 0, sizeof(gcDef));
    gcDef.parentClass = parentClass;
    gcDef.initialize = ChildInitialize;
    gcDef.finalize = ChildFinalize;
    JSClassRef gcClass = JSClassCreate(&gcDef);
    g_parent_init = 0;
    g_child_init = 0;
    g_parent_final = 0;
    g_child_final = 0;
    g_final_order_n = 0;
    memset(g_final_order, 0, sizeof(g_final_order));
    JSObjectRef doomed = JSObjectMake(ctx, gcClass, NULL);
    expect(g_parent_init == 1 && g_child_init == 1, "gc object initialize");
    JSValueProtect(ctx, doomed);
    JSGarbageCollect(ctx);
    expect(g_child_final == 0 && g_parent_final == 0, "protect keeps object across GC");
    JSValueUnprotect(ctx, doomed);
    JSGarbageCollect(ctx);
    expect(g_child_final == 1 && g_parent_final == 1, "unprotect+GC finalizes");
    expect(g_final_order_n == 2 && g_final_order[0] == 'C' && g_final_order[1] == 'P', "finalize derived first");
    JSGarbageCollect(ctx);
    expect(g_child_final == 1 && g_parent_final == 1, "finalize exactly once");
    JSClassRelease(gcClass);

    JSValueRef objectValue = JSValueToObject(ctx, JSValueMakeNumber(ctx, 1), &exception);
    expect(JSValueIsObject(ctx, objectValue), "JSValueToObject");

    JSChar chars[3] = { 'a', 'b', 'c' };
    JSStringRef fromChars = JSStringCreateWithCharacters(chars, 3);
    expect(JSStringGetLength(fromChars) == 3, "JSStringCreateWithCharacters");
    expect(JSStringGetCharactersPtr(fromChars)[0] == 'a', "JSStringGetCharactersPtr");
    char utf8[8];
    expect(JSStringGetUTF8CString(fromChars, utf8, sizeof(utf8)) > 0, "JSStringGetUTF8CString");
    expect(JSStringGetMaximumUTF8CStringSize(fromChars) >= 4, "JSStringGetMaximumUTF8CStringSize");
    JSStringRetain(fromChars);
    JSStringRelease(fromChars);
    JSStringRelease(fromChars);
    JSStringRelease(hello);

#if __has_include(<CoreFoundation/CoreFoundation.h>)
    {
        CFStringRef cf = CFStringCreateWithCString(kCFAllocatorDefault, "cf", kCFStringEncodingUTF8);
        expect(cf != NULL, "CFStringCreateWithCString");
        JSStringRef fromCF = JSStringCreateWithCFString(cf);
        expect(JSStringGetLength(fromCF) == 2, "JSStringCreateWithCFString");
        CFStringRef copy = JSStringCopyCFString(NULL, fromCF);
        expect(copy != NULL, "JSStringCopyCFString");
        CFRelease(cf);
        CFRelease(copy);
        JSStringRelease(fromCF);
    }
#endif

    JSClassRelease(childClass);
    JSClassRelease(parentClass);
    JSClassRelease(parentClass);
    JSGlobalContextRelease(ctx);
    JSContextGroupRelease(group);
    JSContextGroupRelease(group);

    puts("JAVASCRIPTCORE_CABI_PROBE_OK");
    return 0;
}
