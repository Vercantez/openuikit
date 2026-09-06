import CoreFoundation
import Foundation
import GSS

func gssRequire(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func gssRequireStatus(_ actual: OM_uint32, _ expected: UInt, _ message: String) {
    gssRequire(actual == OM_uint32(truncatingIfNeeded: expected), message)
}

func gssWithOID<T>(_ bytes: [UInt8], _ body: (gss_OID) -> T) -> T {
    var storage = bytes
    let count = bytes.count
    return storage.withUnsafeMutableBytes { raw in
        var oid = gss_OID_desc_struct(
            length: OM_uint32(count),
            elements: raw.baseAddress
        )
        return withUnsafeMutablePointer(to: &oid, body)
    }
}

func gssWithConstOID<T>(_ bytes: [UInt8], _ body: (gss_const_OID) -> T) -> T {
    gssWithOID(bytes) { oid in
        body(UnsafePointer(oid))
    }
}

let gssNTUserNameOID: [UInt8] = [
    0x2a, 0x86, 0x48, 0x86, 0xf7, 0x12, 0x01, 0x02, 0x01, 0x01
]
let gssKRB5MechOID: [UInt8] = [
    0x2a, 0x86, 0x48, 0x86, 0xf7, 0x12, 0x01, 0x02, 0x02
]

func gssImportUser(_ text: String) -> gss_name_t {
    var bytes = Array(text.utf8)
    let count = bytes.count
    var minor: OM_uint32 = 0
    var name: gss_name_t? = nil
    let major: OM_uint32 = bytes.withUnsafeMutableBytes { raw in
        var buffer = gss_buffer_desc_struct(length: count, value: raw.baseAddress)
        return gssWithConstOID(gssNTUserNameOID) { oid in
            gss_import_name(&minor, &buffer, oid, &name)
        }
    }
    gssRequire(major == 0, "import \(text)")
    gssRequire(name != nil, "name pointer")
    return name!
}

func testGSSScalarTypealiases() {
    gssRequire(MemoryLayout<OM_uint32>.size == 4, "OM_uint32")
    gssRequire(MemoryLayout<OM_uint64>.size == 8, "OM_uint64")
    gssRequire(MemoryLayout<gss_uint32>.size == 4, "gss_uint32")
    gssRequire(MemoryLayout<gss_qop_t>.size == 4, "gss_qop_t")
    gssRequire(MemoryLayout<gss_cred_usage_t>.size == 4, "gss_cred_usage_t")
}

func testGSSHandleTypealiases() {
    gssRequire(MemoryLayout<gss_name_t>.size == MemoryLayout<OpaquePointer>.size, "gss_name_t")
    gssRequire(MemoryLayout<gss_const_name_t>.size == MemoryLayout<OpaquePointer>.size, "gss_const_name_t")
    gssRequire(MemoryLayout<gss_cred_id_t>.size == MemoryLayout<OpaquePointer>.size, "gss_cred_id_t")
    gssRequire(MemoryLayout<gss_const_cred_id_t>.size == MemoryLayout<OpaquePointer>.size, "gss_const_cred_id_t")
    gssRequire(MemoryLayout<gss_ctx_id_t>.size == MemoryLayout<OpaquePointer>.size, "gss_ctx_id_t")
    gssRequire(MemoryLayout<gss_auth_identity_t>.size == MemoryLayout<OpaquePointer>.size, "gss_auth_identity_t")
}

func testGSSPointerTypealiases() {
    gssRequire(MemoryLayout<gss_OID>.size == MemoryLayout<UnsafeMutablePointer<gss_OID_desc_struct>>.size, "gss_OID")
    gssRequire(MemoryLayout<gss_OID_desc>.size == MemoryLayout<gss_OID_desc_struct>.size, "gss_OID_desc")
    gssRequire(MemoryLayout<gss_OID_set>.size == MemoryLayout<UnsafeMutablePointer<gss_OID_set_desc_struct>>.size, "gss_OID_set")
    gssRequire(MemoryLayout<gss_OID_set_desc>.size == MemoryLayout<gss_OID_set_desc_struct>.size, "gss_OID_set_desc")
    gssRequire(MemoryLayout<gss_const_OID>.size == MemoryLayout<UnsafePointer<gss_OID_desc>>.size, "gss_const_OID")
    gssRequire(MemoryLayout<gss_const_OID_set>.size == MemoryLayout<UnsafePointer<gss_OID_set_desc>>.size, "gss_const_OID_set")
    gssRequire(MemoryLayout<gss_buffer_desc>.size == MemoryLayout<gss_buffer_desc_struct>.size, "gss_buffer_desc")
    gssRequire(MemoryLayout<gss_buffer_t>.size == MemoryLayout<UnsafeMutablePointer<gss_buffer_desc_struct>>.size, "gss_buffer_t")
    gssRequire(MemoryLayout<gss_const_buffer_t>.size == MemoryLayout<UnsafePointer<gss_buffer_desc>>.size, "gss_const_buffer_t")
    gssRequire(MemoryLayout<gss_buffer_set_desc>.size == MemoryLayout<gss_buffer_set_desc_struct>.size, "gss_buffer_set_desc")
    gssRequire(MemoryLayout<gss_buffer_set_t>.size == MemoryLayout<UnsafeMutablePointer<gss_buffer_set_desc_struct>>.size, "gss_buffer_set_t")
    gssRequire(MemoryLayout<gss_channel_bindings_t>.size == MemoryLayout<UnsafeMutablePointer<gss_channel_bindings_struct>>.size, "gss_channel_bindings_t")
    gssRequire(MemoryLayout<gss_const_channel_bindings_t>.size == MemoryLayout<UnsafePointer<gss_channel_bindings_struct>>.size, "gss_const_channel_bindings_t")
    gssRequire(MemoryLayout<gss_iov_buffer_desc>.size == MemoryLayout<gss_iov_buffer_desc_struct>.size, "gss_iov_buffer_desc")
    gssRequire(MemoryLayout<gss_iov_buffer_t>.size == MemoryLayout<UnsafeMutablePointer<gss_iov_buffer_desc_struct>>.size, "gss_iov_buffer_t")
    gssRequire(MemoryLayout<gss_status_id_t>.size == MemoryLayout<UnsafeMutablePointer<OM_uint32>>.size, "gss_status_id_t")
}

func testGSSOIDDescStruct() {
    let empty = gss_OID_desc_struct()
    gssRequire(empty.length == 0, "empty length")
    gssRequire(empty.elements == nil, "empty elements")
    var bytes: [UInt8] = [0x2a, 0x86]
    bytes.withUnsafeMutableBytes { raw in
        var oid = gss_OID_desc_struct(length: 2, elements: raw.baseAddress)
        gssRequire(oid.length == 2, "memberwise length")
        gssRequire(oid.elements != nil, "memberwise elements")
        oid.length = 1
        gssRequire(oid.length == 1, "mutate length")
    }
}

func testGSSOIDSetDescStruct() {
    let empty = gss_OID_set_desc_struct()
    gssRequire(empty.count == 0, "empty count")
    gssRequire(empty.elements == nil, "empty elements")
    var oid = gss_OID_desc_struct()
    withUnsafeMutablePointer(to: &oid) { pointer in
        var set = gss_OID_set_desc_struct(count: 1, elements: pointer)
        gssRequire(set.count == 1, "memberwise count")
        gssRequire(set.elements != nil, "memberwise elements")
        set.count = 0
        gssRequire(set.count == 0, "mutate count")
    }
}

func testGSSBufferDescStruct() {
    let empty = gss_buffer_desc_struct()
    gssRequire(empty.length == 0, "empty length")
    gssRequire(empty.value == nil, "empty value")
    var payload: [UInt8] = [1, 2, 3]
    payload.withUnsafeMutableBytes { raw in
        var buffer = gss_buffer_desc_struct(length: 3, value: raw.baseAddress)
        gssRequire(buffer.length == 3, "memberwise length")
        gssRequire(buffer.value != nil, "memberwise value")
        buffer.length = 0
        gssRequire(buffer.length == 0, "mutate length")
    }
}

func testGSSBufferSetDescStruct() {
    let empty = gss_buffer_set_desc_struct()
    gssRequire(empty.count == 0, "empty count")
    gssRequire(empty.elements == nil, "empty elements")
    var element = gss_buffer_desc()
    withUnsafeMutablePointer(to: &element) { pointer in
        var set = gss_buffer_set_desc_struct(count: 1, elements: pointer)
        gssRequire(set.count == 1, "memberwise count")
        gssRequire(set.elements != nil, "memberwise elements")
        set.count = 2
        gssRequire(set.count == 2, "mutate count")
    }
}

func testGSSChannelBindingsStruct() {
    let empty = gss_channel_bindings_struct()
    gssRequire(empty.initiator_addrtype == 0, "empty initiator type")
    gssRequire(empty.acceptor_addrtype == 0, "empty acceptor type")
    gssRequire(empty.initiator_address.length == 0, "empty initiator addr")
    gssRequire(empty.acceptor_address.length == 0, "empty acceptor addr")
    gssRequire(empty.application_data.length == 0, "empty app data")
    let initiator = gss_buffer_desc_struct(length: 1, value: nil)
    let acceptor = gss_buffer_desc_struct(length: 2, value: nil)
    let app = gss_buffer_desc_struct(length: 3, value: nil)
    var bindings = gss_channel_bindings_struct(
        initiator_addrtype: OM_uint32(GSS_C_AF_INET),
        initiator_address: initiator,
        acceptor_addrtype: OM_uint32(GSS_C_AF_INET6),
        acceptor_address: acceptor,
        application_data: app
    )
    gssRequire(bindings.initiator_addrtype == OM_uint32(GSS_C_AF_INET), "inet")
    gssRequire(bindings.acceptor_addrtype == OM_uint32(GSS_C_AF_INET6), "inet6")
    gssRequire(bindings.initiator_address.length == 1, "initiator length")
    gssRequire(bindings.acceptor_address.length == 2, "acceptor length")
    gssRequire(bindings.application_data.length == 3, "app length")
    bindings.initiator_addrtype = OM_uint32(GSS_C_AF_UNSPEC)
    gssRequire(bindings.initiator_addrtype == 0, "mutate")
}

func testGSSIOVBufferDescStruct() {
    let empty = gss_iov_buffer_desc_struct()
    gssRequire(empty.type == 0, "empty type")
    gssRequire(empty.buffer.length == 0, "empty buffer")
    var iov = gss_iov_buffer_desc_struct(
        type: OM_uint32(GSS_IOV_BUFFER_TYPE_HEADER),
        buffer: gss_buffer_desc_struct(length: 8, value: nil)
    )
    gssRequire(iov.type == OM_uint32(GSS_IOV_BUFFER_TYPE_HEADER), "header type")
    gssRequire(iov.buffer.length == 8, "buffer length")
    iov.type = OM_uint32(GSS_IOV_BUFFER_TYPE_DATA)
    gssRequire(iov.type == OM_uint32(GSS_IOV_BUFFER_TYPE_DATA), "mutate type")
}
