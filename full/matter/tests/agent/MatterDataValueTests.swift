import Foundation
import Matter

func testDataValueDictionary() {
    let boolv = MTRMakeDataValue(type: MTRBooleanValueType, value: true)
    mtrRequire(boolv[MTRTypeKey] as? String == MTRBooleanValueType, "type")
    mtrRequire(boolv[MTRValueKey] as? Bool == true, "value")
    let nullv = MTRMakeDataValue(type: MTRNullValueType, value: "ignored")
    mtrRequire(nullv[MTRValueKey] == nil, "null omits value")
    let path = MTRAttributePath(endpointID: n(1), clusterID: n(6), attributeID: n(0))
    let attr = MTRMakeAttributeResponse(path: path, data: boolv)
    mtrRequire(attr[MTRAttributePathKey] as? MTRAttributePath === path, "attr path")
    mtrRequire(attr[MTRDataKey] != nil, "data")
    let event = MTREventPath(endpointID: n(1), clusterID: n(0x28), eventID: n(0))
    let ev = MTRMakeEventResponse(path: event, data: boolv)
    mtrRequire(ev[MTREventPathKey] as? MTREventPath === event, "ev path")
    let cmd = MTRCommandPath(endpointID: n(1), clusterID: n(6), commandID: n(1))
    let cr = MTRMakeCommandResponse(path: cmd, data: boolv)
    mtrRequire(cr[MTRCommandPathKey] as? MTRCommandPath === cmd, "cmd")
    let er = MTRMakeErrorResponse(error: MTRError(.notFound))
    mtrRequire((er[MTRErrorKey] as? MTRError)?.code == .notFound, "err")
    let uintv = MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))
    mtrRequire(uintv[MTRTypeKey] as? String == MTRUnsignedIntegerValueType, "uint")
    let strv = MTRMakeDataValue(type: MTRUTF8StringValueType, value: "hi")
    mtrRequire(strv[MTRValueKey] as? String == "hi", "utf8")
    let oct = MTRMakeDataValue(type: MTROctetStringValueType, value: Data([1]))
    mtrRequire((oct[MTRValueKey] as? Data)?.count == 1, "oct")
}
