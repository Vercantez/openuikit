// Shim matching Darwin's ObjectiveC ABI shape: Selector wraps a pointer.
public struct Selector: ExpressibleByStringLiteral, Equatable {
    public var ptr: OpaquePointer
    public init(_ ptr: OpaquePointer) { self.ptr = ptr }
    public init(stringLiteral value: String) {
        self.ptr = OpaquePointer(bitPattern: 1)!
    }
}
public struct ObjCBool {
    public var value: Int8
    public init(_ b: Bool) { value = b ? 1 : 0 }
    public var boolValue: Bool { value != 0 }
}
