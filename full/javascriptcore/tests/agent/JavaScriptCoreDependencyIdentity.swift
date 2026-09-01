import Foundation
import JavaScriptCore

let foundationDate = Date(timeIntervalSince1970: 1)
let foundationPoint = CGPoint(x: 3, y: 4)
let foundationString: NSString = "identity"

let vm = JSVirtualMachine()
let context = JSContext(virtualMachine: vm)!
let dateValue = JSValue(object: foundationDate, in: context)!
precondition(dateValue.isDate, "Foundation.Date projects through JSValue")
precondition(dateValue.toDate()?.timeIntervalSince1970 == 1)

let pointValue = JSValue(point: foundationPoint, inContext: context)!
precondition(pointValue.toPoint().x == 3)
precondition(pointValue.toPoint().y == 4)

let stringValue = JSValue(object: foundationString, in: context)!
precondition(stringValue.toString() == "identity")
precondition(JSC_OBJC_API_ENABLED == 0, "no ObjC JSExport projection")

print("JAVASCRIPTCORE_DEPENDENCY_IDENTITY_OK")
