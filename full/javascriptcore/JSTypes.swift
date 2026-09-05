import Foundation

public typealias JSChar = UInt16
public typealias JSClassAttributes = UInt32
public typealias JSClassRef = OpaquePointer
public typealias JSContextGroupRef = OpaquePointer
public typealias JSContextRef = OpaquePointer
public typealias JSGlobalContextRef = OpaquePointer
public typealias JSObjectRef = OpaquePointer
public typealias JSPropertyAttributes = UInt32
public typealias JSPropertyNameAccumulatorRef = OpaquePointer
public typealias JSPropertyNameArrayRef = OpaquePointer
public typealias JSStringRef = OpaquePointer
public typealias JSValueRef = OpaquePointer
public typealias JSValueProperty = AnyObject

public typealias JSObjectCallAsConstructorCallback = (
    JSContextRef?, JSObjectRef?, Int, UnsafePointer<JSValueRef?>?, UnsafeMutablePointer<JSValueRef?>?
) -> JSObjectRef?

public typealias JSObjectCallAsFunctionCallback = (
    JSContextRef?, JSObjectRef?, JSObjectRef?, Int, UnsafePointer<JSValueRef?>?, UnsafeMutablePointer<JSValueRef?>?
) -> JSValueRef?

public typealias JSObjectConvertToTypeCallback = (
    JSContextRef?, JSObjectRef?, JSType, UnsafeMutablePointer<JSValueRef?>?
) -> JSValueRef?

public typealias JSObjectDeletePropertyCallback = (
    JSContextRef?, JSObjectRef?, JSStringRef?, UnsafeMutablePointer<JSValueRef?>?
) -> Bool

public typealias JSObjectFinalizeCallback = (JSObjectRef?) -> Void

public typealias JSObjectGetPropertyCallback = (
    JSContextRef?, JSObjectRef?, JSStringRef?, UnsafeMutablePointer<JSValueRef?>?
) -> JSValueRef?

public typealias JSObjectGetPropertyNamesCallback = (
    JSContextRef?, JSObjectRef?, JSPropertyNameAccumulatorRef?
) -> Void

public typealias JSObjectHasInstanceCallback = (
    JSContextRef?, JSObjectRef?, JSValueRef?, UnsafeMutablePointer<JSValueRef?>?
) -> Bool

public typealias JSObjectHasPropertyCallback = (
    JSContextRef?, JSObjectRef?, JSStringRef?
) -> Bool

public typealias JSObjectInitializeCallback = (JSContextRef?, JSObjectRef?) -> Void

public typealias JSObjectSetPropertyCallback = (
    JSContextRef?, JSObjectRef?, JSStringRef?, JSValueRef?, UnsafeMutablePointer<JSValueRef?>?
) -> Bool

public typealias JSTypedArrayBytesDeallocator = (
    UnsafeMutableRawPointer?, UnsafeMutableRawPointer?
) -> Void

/// C `JSType` from public `JSValueRef.h` (`kJSTypeUndefined` … `kJSTypeBigInt`).
public struct JSType: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: UInt32) {
        self.rawValue = rawValue
    }
}

public var kJSTypeUndefined: JSType { JSType(rawValue: 0) }
public var kJSTypeNull: JSType { JSType(rawValue: 1) }
public var kJSTypeBoolean: JSType { JSType(rawValue: 2) }
public var kJSTypeNumber: JSType { JSType(rawValue: 3) }
public var kJSTypeString: JSType { JSType(rawValue: 4) }
public var kJSTypeObject: JSType { JSType(rawValue: 5) }
public var kJSTypeSymbol: JSType { JSType(rawValue: 6) }
public var kJSTypeBigInt: JSType { JSType(rawValue: 7) }

/// C `JSTypedArrayType` from public `JSValueRef.h`.
public struct JSTypedArrayType: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: UInt32) {
        self.rawValue = rawValue
    }
}

public var kJSTypedArrayTypeNone: JSTypedArrayType { JSTypedArrayType(rawValue: 0) }
public var kJSTypedArrayTypeInt8Array: JSTypedArrayType { JSTypedArrayType(rawValue: 1) }
public var kJSTypedArrayTypeInt16Array: JSTypedArrayType { JSTypedArrayType(rawValue: 2) }
public var kJSTypedArrayTypeInt32Array: JSTypedArrayType { JSTypedArrayType(rawValue: 3) }
public var kJSTypedArrayTypeUint8Array: JSTypedArrayType { JSTypedArrayType(rawValue: 4) }
public var kJSTypedArrayTypeUint8ClampedArray: JSTypedArrayType { JSTypedArrayType(rawValue: 5) }
public var kJSTypedArrayTypeUint16Array: JSTypedArrayType { JSTypedArrayType(rawValue: 6) }
public var kJSTypedArrayTypeUint32Array: JSTypedArrayType { JSTypedArrayType(rawValue: 7) }
public var kJSTypedArrayTypeFloat32Array: JSTypedArrayType { JSTypedArrayType(rawValue: 8) }
public var kJSTypedArrayTypeFloat64Array: JSTypedArrayType { JSTypedArrayType(rawValue: 9) }
public var kJSTypedArrayTypeArrayBuffer: JSTypedArrayType { JSTypedArrayType(rawValue: 10) }
public var kJSTypedArrayTypeBigInt64Array: JSTypedArrayType { JSTypedArrayType(rawValue: 11) }
public var kJSTypedArrayTypeBigUint64Array: JSTypedArrayType { JSTypedArrayType(rawValue: 12) }

/// C `JSRelationCondition` (iOS 18). Sequential C enum starting at 0.
public enum JSRelationCondition: UInt32, Equatable, Hashable, Sendable {
    case undefined = 0
    case equal = 1
    case greaterThan = 2
    case lessThan = 3
}

public var kJSPropertyAttributeNone: Int { 0 }
public var kJSPropertyAttributeReadOnly: Int { 1 << 1 }
public var kJSPropertyAttributeDontEnum: Int { 1 << 2 }
public var kJSPropertyAttributeDontDelete: Int { 1 << 3 }

public var kJSClassAttributeNone: Int { 0 }
public var kJSClassAttributeNoAutomaticPrototype: Int { 1 << 1 }

public let JSPropertyDescriptorWritableKey = "writable"
public let JSPropertyDescriptorEnumerableKey = "enumerable"
public let JSPropertyDescriptorConfigurableKey = "configurable"
public let JSPropertyDescriptorValueKey = "value"
public let JSPropertyDescriptorGetKey = "get"
public let JSPropertyDescriptorSetKey = "set"

public struct JSStaticValue {
    public var name: UnsafePointer<CChar>!
    public var getProperty: JSObjectGetPropertyCallback!
    public var setProperty: JSObjectSetPropertyCallback!
    public var attributes: JSPropertyAttributes

    public init() {
        name = nil
        getProperty = nil
        setProperty = nil
        attributes = 0
    }

    public init(
        name: UnsafePointer<CChar>!,
        getProperty: JSObjectGetPropertyCallback!,
        setProperty: JSObjectSetPropertyCallback!,
        attributes: JSPropertyAttributes
    ) {
        self.name = name
        self.getProperty = getProperty
        self.setProperty = setProperty
        self.attributes = attributes
    }
}

public struct JSStaticFunction {
    public var name: UnsafePointer<CChar>!
    public var callAsFunction: JSObjectCallAsFunctionCallback!
    public var attributes: JSPropertyAttributes

    public init() {
        name = nil
        callAsFunction = nil
        attributes = 0
    }

    public init(
        name: UnsafePointer<CChar>!,
        callAsFunction: JSObjectCallAsFunctionCallback!,
        attributes: JSPropertyAttributes
    ) {
        self.name = name
        self.callAsFunction = callAsFunction
        self.attributes = attributes
    }
}

public struct JSClassDefinition {
    public var version: Int32
    public var attributes: JSClassAttributes
    public var className: UnsafePointer<CChar>!
    public var parentClass: JSClassRef!
    public var staticValues: UnsafePointer<JSStaticValue>!
    public var staticFunctions: UnsafePointer<JSStaticFunction>!
    public var initialize: JSObjectInitializeCallback!
    public var finalize: JSObjectFinalizeCallback!
    public var hasProperty: JSObjectHasPropertyCallback!
    public var getProperty: JSObjectGetPropertyCallback!
    public var setProperty: JSObjectSetPropertyCallback!
    public var deleteProperty: JSObjectDeletePropertyCallback!
    public var getPropertyNames: JSObjectGetPropertyNamesCallback!
    public var callAsFunction: JSObjectCallAsFunctionCallback!
    public var callAsConstructor: JSObjectCallAsConstructorCallback!
    public var hasInstance: JSObjectHasInstanceCallback!
    public var convertToType: JSObjectConvertToTypeCallback!

    public init() {
        version = 0
        attributes = 0
        className = nil
        parentClass = nil
        staticValues = nil
        staticFunctions = nil
        initialize = nil
        finalize = nil
        hasProperty = nil
        getProperty = nil
        setProperty = nil
        deleteProperty = nil
        getPropertyNames = nil
        callAsFunction = nil
        callAsConstructor = nil
        hasInstance = nil
        convertToType = nil
    }

    public init(
        version: Int32,
        attributes: JSClassAttributes,
        className: UnsafePointer<CChar>!,
        parentClass: JSClassRef!,
        staticValues: UnsafePointer<JSStaticValue>!,
        staticFunctions: UnsafePointer<JSStaticFunction>!,
        initialize: JSObjectInitializeCallback!,
        finalize: JSObjectFinalizeCallback!,
        hasProperty: JSObjectHasPropertyCallback!,
        getProperty: JSObjectGetPropertyCallback!,
        setProperty: JSObjectSetPropertyCallback!,
        deleteProperty: JSObjectDeletePropertyCallback!,
        getPropertyNames: JSObjectGetPropertyNamesCallback!,
        callAsFunction: JSObjectCallAsFunctionCallback!,
        callAsConstructor: JSObjectCallAsConstructorCallback!,
        hasInstance: JSObjectHasInstanceCallback!,
        convertToType: JSObjectConvertToTypeCallback!
    ) {
        self.version = version
        self.attributes = attributes
        self.className = className
        self.parentClass = parentClass
        self.staticValues = staticValues
        self.staticFunctions = staticFunctions
        self.initialize = initialize
        self.finalize = finalize
        self.hasProperty = hasProperty
        self.getProperty = getProperty
        self.setProperty = setProperty
        self.deleteProperty = deleteProperty
        self.getPropertyNames = getPropertyNames
        self.callAsFunction = callAsFunction
        self.callAsConstructor = callAsConstructor
        self.hasInstance = hasInstance
        self.convertToType = convertToType
    }
}

public let kJSClassDefinitionEmpty = JSClassDefinition()

/// Linux ships the Swift JSContext/JSValue overlay, matching the iPhoneOS graph.
public var JSC_OBJC_API_ENABLED: Int32 { 1 }

/// Marker protocol matching Apple's empty `JSExport`. Swift classes are not
/// exported onto `JSContext.globalObject` on this port (no ObjC JSExport
/// runtime). Host functions use `JSContext.setObject` with a Swift closure.
public protocol JSExport {}
