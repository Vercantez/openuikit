import Foundation
import JavaScriptCore

let vm = JSVirtualMachine()
let context = JSContext(virtualMachine: vm)!
context.name = "runtime-probe"
context.isInspectable = false

let sum = context.evaluateScript("1 + 2 * 3")
precondition(sum?.toInt32() == 7, "arithmetic")
precondition(sum?.isNumber == true)

let object = context.evaluateScript("({ greeting: 'hello', count: 4 })")
precondition(object?.isObject == true)
precondition(object?.forProperty("greeting")?.toString() == "hello")
object?.setValue(5, forProperty: "count")
precondition(object?.forProperty("count")?.toInt32() == 5)

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

context.exception = nil
let failed = context.evaluateScript("not_defined_xyz")
precondition(failed == nil)
precondition(context.exception != nil)

let syntaxOK = context.evaluateScript("if (false) { 1 } else { 2 }")
precondition(syntaxOK?.toInt32() == 2)

let point = JSValue(point: CGPoint(x: 3, y: 4), inContext: context)!
precondition(point.toPoint().x == 3)

let managed = JSManagedValue(value: object, andOwner: context)!
precondition(managed.value?.isObject == true)
vm.addManagedReference("token", withOwner: context)
vm.removeManagedReference("token", withOwner: context)

let str = JSStringCreateWithUTF8CString("probe")
precondition(JSStringGetLength(str) == 5)
precondition(JSStringIsEqualToUTF8CString(str, "probe"))
let numberRef = JSValueMakeNumber(context.jsGlobalContextRef, 8)
precondition(JSValueIsNumber(context.jsGlobalContextRef, numberRef))
precondition(JSValueToNumber(context.jsGlobalContextRef, numberRef, nil) == 8)
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

precondition(JSC_OBJC_API_ENABLED == 1)
precondition(kJSTypeNumber.rawValue == 3)
precondition(kJSTypedArrayTypeUint8Array.rawValue == 4)
precondition(JSRelationCondition.equal.rawValue == 1)
precondition(kJSPropertyAttributeReadOnly == 1 << 1)
_ = kJSClassDefinitionEmpty
_ = JSPropertyDescriptorValueKey
_ = JSExport.self

print("JAVASCRIPTCORE_AGENT_RUNTIME_OK")
