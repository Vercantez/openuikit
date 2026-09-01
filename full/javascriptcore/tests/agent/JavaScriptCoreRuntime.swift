import Foundation
import JavaScriptCore

let vm = JSVirtualMachine()
let context = JSContext(virtualMachine: vm)!
context.name = "runtime-probe"
context.isInspectable = false
precondition(context.name == "runtime-probe")
precondition(context.isInspectable == false)
context.isInspectable = true
precondition(context.isInspectable)

let sum = context.evaluateScript("1 + 2 * 3")
precondition(sum?.toInt32() == 7, "arithmetic")
precondition(sum?.isNumber == true)
precondition(sum?.toDouble() == 7)
precondition(sum?.toNumber()?.doubleValue == 7)

let object = context.evaluateScript("({ greeting: 'hello', count: 4 })")
precondition(object?.isObject == true)
precondition(object?.forProperty("greeting")?.toString() == "hello")
object?.setValue(5, forProperty: "count")
precondition(object?.forProperty("count")?.toInt32() == 5)
precondition(object?.hasProperty("greeting") == true)
precondition(object?.deleteProperty("count") == true)
precondition(object?.hasProperty("count") == false)
object?.setValue(5, forProperty: "count")

context["answer"] = JSValue(int32: 42, in: context)
precondition(context.objectForKeyedSubscript("answer")?.toInt32() == 42)

let scripted = context.evaluateScript(
    """
    function add(a, b) { return a + b; }
    add(20, 22);
    """
)
precondition(scripted?.toInt32() == 42, "function call")

let array = JSValue(newArrayIn: context)!
array.setValue("alpha", at: 0)
array.setValue("beta", at: 1)
precondition(array.isArray)
precondition(array.toArray()?.count == 2)
precondition(context.evaluateScript("[1,2,3].map(function(x){ return x * 2; })").toArray()?.count == 3)

let json = context.evaluateScript("JSON.stringify({ok:true, n:1})")
precondition(json?.toString()?.contains("ok") == true)
let parsed = context.evaluateScript("JSON.parse('{\"k\":7}')")
precondition(parsed?.forProperty("k")?.toInt32() == 7)
precondition(parsed?.toDictionary()?["k"] != nil)

let boolValue = JSValue(bool: true, in: context)!
precondition(boolValue.toBool())
let nullValue = JSValue(nullIn: context)!
precondition(nullValue.isNull)
let undef = JSValue(undefinedIn: context)!
precondition(undef.isUndefined)
let err = JSValue(newErrorFromMessage: "nope", in: context)!
precondition(err.toString()?.contains("nope") == true)

let big = JSValue(newBigIntFrom: Int64(99), in: context)
precondition(big?.isBigInt == true)
precondition(big?.compare(Int64(98)) == .greaterThan)
precondition(big?.compare(UInt64(99)) == .equal)
precondition(big?.toInt64() == 99)
precondition(JSValue(newBigIntFrom: UInt64(3), in: context)?.isBigInt == true)
precondition(JSValue(newBigIntFrom: Double(4), in: context)?.isBigInt == true)
precondition(JSValue(newBigIntFrom: "5", in: context)?.isBigInt == true)

context.exception = nil
let failed = context.evaluateScript("not_defined_xyz")
precondition(failed == nil)
precondition(context.exception != nil)

let syntaxOK = context.evaluateScript("if (false) { 1 } else { 2 }")
precondition(syntaxOK?.toInt32() == 2)

let point = JSValue(point: CGPoint(x: 3, y: 4), inContext: context)!
precondition(point.toPoint().x == 3)
let size = JSValue(size: CGSize(width: 5, height: 6), inContext: context)!
precondition(size.toSize().width == 5)
let rect = JSValue(rect: CGRect(x: 1, y: 2, width: 3, height: 4), inContext: context)!
precondition(rect.toRect().width == 3)
let range = JSValue(range: NSRange(location: 1, length: 2), inContext: context)!
precondition(range.toRange().length == 2)

let date = JSValue(object: Date(timeIntervalSince1970: 10), in: context)!
precondition(date.isDate)
precondition(date.toDate()?.timeIntervalSince1970 == 10)

let fresh = JSValue(newObjectIn: context)!
precondition(fresh.isObject)
fresh.setObject("v", forKeyedSubscript: "k" as NSString)
precondition(fresh.objectForKeyedSubscript("k")?.toString() == "v")
fresh.defineProperty("ro", descriptor: ["value": 1, "writable": false])
precondition(fresh.forProperty("ro")?.toInt32() == 1)

let addFn = context.evaluateScript("function mul(a,b){ return a*b; } mul")
precondition(addFn?.call(withArguments: [6, 7])?.toInt32() == 42)
precondition(context.evaluateScript("({ n: function(x){ return x + 1; } })")?.invokeMethod("n", withArguments: [3])?.toInt32() == 4)

let ctor = context.evaluateScript("function Box(v){ this.v = v; } Box")
let constructed = ctor?.construct(withArguments: [9])
precondition(constructed?.forProperty("v")?.toInt32() == 9)
precondition(constructed?.isInstance(of: ctor!) == true)
precondition(JSValue(int32: 1, in: context)?.isEqual(to: JSValue(int32: 1, in: context)) == true)
precondition(JSValue(int32: 1, in: context)?.isEqualWithTypeCoercion(to: JSValue(object: "1", in: context)) == true)

let symbol = JSValue(newSymbolFromDescription: "s", in: context)
precondition(symbol?.isSymbol == true)

let uint32 = JSValue(uInt32: 8, in: context)!
precondition(uint32.toUInt32() == 8)
precondition(uint32.toUInt64() == 8)
precondition(JSValue(double: 2.5, in: context)?.toDouble() == 2.5)

let regexp = JSValue(newRegularExpressionFromPattern: "a+", flags: "", in: context)
precondition(regexp?.isObject == true)

let resolved = JSValue(newPromiseResolvedWithResult: 1, in: context)
precondition(resolved?.isObject == true)
let rejected = JSValue(newPromiseRejectedWithReason: "no", in: context)
precondition(rejected?.isObject == true)
let executed = JSValue(newPromiseIn: context) { resolve, reject in
    _ = reject
    _ = resolve?.call(withArguments: [4])
}
precondition(executed?.isObject == true)

precondition(date.toObject() is Date)
precondition(boolValue.toObject() as? Bool == true)

let sourced = context.evaluateScript("3", withSourceURL: URL(string: "file://probe.js"))
precondition(sourced?.toInt32() == 3)

array.setObject("gamma", atIndexedSubscript: 2)
precondition(array.objectAtIndexedSubscript(2)?.toString() == "gamma")
precondition(array[2]?.toString() == "gamma")

precondition(big?.compare(JSValue(newBigIntFrom: Int64(99), in: context)!) == .equal)
precondition(sum?.compare(7.0) == .equal)

let managed = JSManagedValue(value: object, andOwner: context)!
precondition(managed.value?.isObject == true)
_ = JSManagedValue(value: object)
vm.addManagedReference("token", withOwner: context)
vm.removeManagedReference("token", withOwner: context)

_ = JSValue(undefinedInContext: context)
_ = JSValue(nullInContext: context)
_ = JSContext()

let str = JSStringCreateWithUTF8CString("probe")
precondition(JSStringGetLength(str) == 5)
precondition(JSStringIsEqualToUTF8CString(str, "probe"))
let numberRef = JSValueMakeNumber(context.jsGlobalContextRef, 8)
precondition(JSValueIsNumber(context.jsGlobalContextRef, numberRef))
precondition(JSValueToNumber(context.jsGlobalContextRef, numberRef, nil) == 8)
let fromRef = JSValue(JSValueRef: numberRef, inContext: context)
precondition(fromRef?.toInt32() == 8)
var exception: JSValueRef?
_ = JSEvaluateScript(
    context.jsGlobalContextRef,
    JSStringCreateWithUTF8CString("1+1"),
    nil,
    nil,
    1,
    &exception
)
JSStringRelease(str)

let created = JSStringCreateWithUTF8CString("cf")
let copied = JSStringCopyCFString(nil, created)
let roundTrip = JSStringCreateWithCFString(copied)
precondition(JSStringGetLength(roundTrip) == 2)
JSStringRelease(created)
JSStringRelease(roundTrip)

precondition(JSC_OBJC_API_ENABLED == 0)
precondition(kJSTypeNumber.rawValue == 3)
precondition(kJSTypedArrayTypeUint8Array.rawValue == 4)
precondition(JSRelationCondition.equal.rawValue == 1)
precondition(kJSPropertyAttributeReadOnly == 1 << 1)
_ = kJSClassDefinitionEmpty
_ = JSPropertyDescriptorValueKey
_ = JSPropertyDescriptorWritableKey
_ = JSPropertyDescriptorEnumerableKey
_ = JSPropertyDescriptorConfigurableKey
_ = JSPropertyDescriptorGetKey
_ = JSPropertyDescriptorSetKey
_ = JSExport.self
_ = JSType(rawValue: 3)
_ = JSTypedArrayType(rawValue: 4)
_ = JSStaticValue()
_ = JSStaticFunction()
_ = JSClassDefinition()

_ = JSValue(bool: false, inContext: context)
_ = JSValue(double: 1, inContext: context)
_ = JSValue(int32: 1, inContext: context)
_ = JSValue(newArrayInContext: context)
_ = JSValue(newObjectInContext: context)
_ = JSValue(newErrorFromMessage: "e", inContext: context)
_ = JSValue(newBigIntFromDouble: 1, inContext: context)
_ = JSValue(newBigIntFromInt64: 1, inContext: context)
_ = JSValue(newBigIntFromString: "1", inContext: context)
_ = JSValue(newBigIntFromUInt64: 1, inContext: context)
_ = JSValue(newPromiseResolvedWithResult: 1, inContext: context)
_ = JSValue(newPromiseRejectedWithReason: "x", inContext: context)
_ = JSValue(newPromiseInContext: context, fromExecutor: { _, _ in })
_ = JSValue(newRegularExpressionFromPattern: "a", flags: "", inContext: context)
_ = JSValue(newSymbolFromDescription: "t", inContext: context)
_ = JSValue(object: "x", inContext: context)
_ = JSValue(UInt32: 1, inContext: context)
_ = date.toObjectOf(NSDate.self)

print("JAVASCRIPTCORE_AGENT_RUNTIME_OK")
