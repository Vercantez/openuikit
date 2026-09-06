import CoreFoundation

enum GSSLinuxMinor {
    static let success: OM_uint32 = 0
    static let unavailable: OM_uint32 = 1
    static let invalidArgument: OM_uint32 = 2
    static let noMemory: OM_uint32 = 3
}

enum GSSAlloc {
    static var pointers: Set<UInt> = []

    static func allocate(_ byteCount: Int) -> UnsafeMutableRawPointer? {
        guard byteCount > 0 else { return nil }
        let pointer = UnsafeMutableRawPointer.allocate(byteCount: byteCount, alignment: 1)
        pointers.insert(UInt(bitPattern: pointer))
        return pointer
    }

    static func free(_ pointer: UnsafeMutableRawPointer?) {
        guard let pointer else { return }
        let key = UInt(bitPattern: pointer)
        if pointers.remove(key) != nil {
            pointer.deallocate()
        }
    }

    static func owns(_ pointer: UnsafeMutableRawPointer?) -> Bool {
        guard let pointer else { return false }
        return pointers.contains(UInt(bitPattern: pointer))
    }
}

func gssMajor(_ value: UInt) -> OM_uint32 {
    OM_uint32(truncatingIfNeeded: value)
}

func gssComplete(_ minor_status: UnsafeMutablePointer<OM_uint32>) -> OM_uint32 {
    minor_status.pointee = GSSLinuxMinor.success
    return 0
}

func gssFail(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ major: UInt,
    minor: OM_uint32 = GSSLinuxMinor.unavailable
) -> OM_uint32 {
    minor_status.pointee = minor
    return gssMajor(major)
}

func gssCopyBytes(_ source: UnsafeRawPointer?, count: Int) -> UnsafeMutableRawPointer? {
    guard count > 0, let source else { return nil }
    guard let dest = GSSAlloc.allocate(count) else { return nil }
    dest.copyMemory(from: source, byteCount: count)
    return dest
}

func gssFillBuffer(_ buffer: gss_buffer_t, bytes: [UInt8]) -> OM_uint32 {
    buffer.pointee.length = 0
    buffer.pointee.value = nil
    guard !bytes.isEmpty else { return 0 }
    guard let dest = GSSAlloc.allocate(bytes.count) else { return gssMajor(GSS_S_FAILURE) }
    bytes.withUnsafeBytes { raw in
        dest.copyMemory(from: raw.baseAddress!, byteCount: bytes.count)
    }
    buffer.pointee.value = dest
    buffer.pointee.length = bytes.count
    return 0
}

func gssReadBuffer(_ buffer: gss_const_buffer_t) -> [UInt8] {
    let length = buffer.pointee.length
    guard length > 0, let value = buffer.pointee.value else { return [] }
    return Array(UnsafeRawBufferPointer(start: value, count: length))
}

func gssReadMutableBuffer(_ buffer: gss_buffer_t) -> [UInt8] {
    gssReadBuffer(UnsafePointer(buffer))
}


func gssDERLength(_ value: Int) -> [UInt8] {
    precondition(value >= 0)
    if value < 128 {
        return [UInt8(value)]
    }
    var remainder = value
    var body: [UInt8] = []
    while remainder > 0 {
        body.append(UInt8(remainder & 0xff))
        remainder >>= 8
    }
    body.reverse()
    return [0x80 | UInt8(body.count)] + body
}

func gssParseDERLength(_ bytes: [UInt8], offset: inout Int) -> Int? {
    guard offset < bytes.count else { return nil }
    let first = bytes[offset]
    offset += 1
    if first < 128 {
        return Int(first)
    }
    let count = Int(first & 0x7f)
    guard count > 0, count <= 4, offset + count <= bytes.count else { return nil }
    var value = 0
    for _ in 0..<count {
        value = (value << 8) | Int(bytes[offset])
        offset += 1
    }
    return value
}

func gssMakeCFString(_ string: String) -> CFString {
    string.withCString { pointer in
        CFStringCreateWithCString(
            kCFAllocatorDefault,
            pointer,
            CFStringBuiltInEncodings.UTF8.rawValue
        )!
    }
}

func gssCFStringBytes(_ string: CFString) -> [UInt8]? {
    let nsLen = CFStringGetLength(string)
    let range = CFRange(location: 0, length: nsLen)
    var used: CFIndex = 0
    let maxBytes = nsLen * 4 + 1
    var buffer = [UInt8](repeating: 0, count: maxBytes)
    let ok = buffer.withUnsafeMutableBufferPointer { dest in
        CFStringGetBytes(
            string,
            range,
            CFStringBuiltInEncodings.UTF8.rawValue,
            0,
            false,
            dest.baseAddress,
            dest.count,
            &used
        )
    }
    guard ok > 0 || nsLen == 0 else { return nil }
    return Array(buffer.prefix(used))
}

final class GSSNameBox {
    var display: [UInt8]
    var nameType: [UInt8]
    var isMN: Bool
    var oidStorage: gss_OID_desc_struct
    var oidBytes: UnsafeMutableRawPointer?

    init(display: [UInt8], nameType: [UInt8], isMN: Bool = false) {
        self.display = display
        self.nameType = nameType
        self.isMN = isMN
        if !nameType.isEmpty, let bytes = GSSAlloc.allocate(nameType.count) {
            nameType.withUnsafeBytes { raw in
                bytes.copyMemory(from: raw.baseAddress!, byteCount: nameType.count)
            }
            self.oidBytes = bytes
            self.oidStorage = gss_OID_desc_struct(
                length: OM_uint32(nameType.count),
                elements: bytes
            )
        } else {
            self.oidBytes = nil
            self.oidStorage = gss_OID_desc_struct()
        }
    }

    deinit {
        GSSAlloc.free(oidBytes)
    }
}

enum GSSNameStore {
    static var boxes: [UInt: GSSNameBox] = [:]

    static func retain(_ box: GSSNameBox) -> gss_name_t {
        let unmanaged = Unmanaged.passRetained(box)
        let raw = unmanaged.toOpaque()
        let key = UInt(bitPattern: raw)
        boxes[key] = box
        return OpaquePointer(raw)
    }

    static func lookup(_ name: gss_name_t?) -> GSSNameBox? {
        guard let name else { return nil }
        let key = UInt(bitPattern: UnsafeRawPointer(name))
        return boxes[key]
    }

    static func release(_ name: gss_name_t) {
        let key = UInt(bitPattern: UnsafeRawPointer(name))
        if boxes.removeValue(forKey: key) != nil {
            Unmanaged<GSSNameBox>.fromOpaque(UnsafeRawPointer(name)).release()
        }
    }
}

func gssOIDBytes(_ oid: gss_const_OID?) -> [UInt8]? {
    guard let oid else { return nil }
    let length = Int(oid.pointee.length)
    guard length >= 0 else { return nil }
    if length == 0 {
        return []
    }
    guard let elements = oid.pointee.elements else { return nil }
    return Array(UnsafeRawBufferPointer(start: elements, count: length))
}

func gssOIDsEqual(_ a: [UInt8], _ b: [UInt8]) -> Bool {
    a == b
}

func gssDecodeOIDArcs(_ bytes: [UInt8]) -> [UInt64]? {
    guard !bytes.isEmpty else { return [] }
    let first = bytes[0]
    var arcs: [UInt64]
    if first < 80 {
        arcs = [UInt64(first / 40), UInt64(first % 40)]
    } else {
        arcs = [2, UInt64(first) - 80]
    }
    var value: UInt64 = 0
    var index = 1
    while index < bytes.count {
        let byte = bytes[index]
        value = (value << 7) | UInt64(byte & 0x7f)
        if byte & 0x80 == 0 {
            arcs.append(value)
            value = 0
        }
        index += 1
    }
    return arcs
}
