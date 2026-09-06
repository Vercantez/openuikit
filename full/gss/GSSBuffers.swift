/// OID-set, buffer-set, buffer release, OID compare/print, and RFC 2743
/// token encapsulate/decapsulate.

public func gss_release_buffer(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ buffer: gss_buffer_t
) -> OM_uint32 {
    GSSAlloc.free(buffer.pointee.value)
    buffer.pointee.value = nil
    buffer.pointee.length = 0
    return gssComplete(minor_status)
}

public func gss_create_empty_oid_set(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ oid_set: UnsafeMutablePointer<gss_OID_set?>
) -> OM_uint32 {
    let set = UnsafeMutablePointer<gss_OID_set_desc_struct>.allocate(capacity: 1)
    set.initialize(to: gss_OID_set_desc_struct())
    oid_set.pointee = set
    return gssComplete(minor_status)
}

public func gss_release_oid_set(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ set: UnsafeMutablePointer<gss_OID_set?>
) -> OM_uint32 {
    minor_status.pointee = GSSLinuxMinor.success
    guard let handle = set.pointee else {
        return 0
    }
    if handle.pointee.count > 0, let elements = handle.pointee.elements {
        for index in 0..<handle.pointee.count {
            GSSAlloc.free(elements.advanced(by: index).pointee.elements)
        }
        elements.deallocate()
    }
    handle.deinitialize(count: 1)
    handle.deallocate()
    set.pointee = nil
    return 0
}

public func gss_add_oid_set_member(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ member_oid: gss_const_OID,
    _ oid_set: UnsafeMutablePointer<gss_OID_set>
) -> OM_uint32 {
    guard let bytes = gssOIDBytes(member_oid) else {
        return gssFail(minor_status, GSS_S_FAILURE, minor: GSSLinuxMinor.invalidArgument)
    }
    let handle = oid_set.pointee
    if handle.pointee.count > 0, let elements = handle.pointee.elements {
        for index in 0..<handle.pointee.count {
            let existing = elements.advanced(by: index)
            if let existingBytes = gssOIDBytes(UnsafePointer(existing)), existingBytes == bytes {
                return gssComplete(minor_status)
            }
        }
    }
    let newCount = handle.pointee.count + 1
    let newElements = UnsafeMutablePointer<gss_OID_desc_struct>.allocate(capacity: newCount)
    if handle.pointee.count > 0, let old = handle.pointee.elements {
        for index in 0..<handle.pointee.count {
            newElements.advanced(by: index).initialize(to: old.advanced(by: index).pointee)
        }
        old.deallocate()
    }
    var copied = gss_OID_desc_struct()
    copied.length = OM_uint32(bytes.count)
    if bytes.isEmpty {
        copied.elements = nil
    } else if let storage = GSSAlloc.allocate(bytes.count) {
        bytes.withUnsafeBytes { raw in
            storage.copyMemory(from: raw.baseAddress!, byteCount: bytes.count)
        }
        copied.elements = storage
    } else {
        newElements.deinitialize(count: handle.pointee.count)
        newElements.deallocate()
        return gssFail(minor_status, GSS_S_FAILURE, minor: GSSLinuxMinor.noMemory)
    }
    newElements.advanced(by: handle.pointee.count).initialize(to: copied)
    handle.pointee.elements = newElements
    handle.pointee.count = newCount
    return gssComplete(minor_status)
}

public func gss_test_oid_set_member(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ member: gss_const_OID,
    _ set: gss_OID_set,
    _ present: UnsafeMutablePointer<Int32>
) -> OM_uint32 {
    guard let bytes = gssOIDBytes(member) else {
        present.pointee = 0
        return gssFail(minor_status, GSS_S_FAILURE, minor: GSSLinuxMinor.invalidArgument)
    }
    present.pointee = 0
    if set.pointee.count > 0, let elements = set.pointee.elements {
        for index in 0..<set.pointee.count {
            let existing = elements.advanced(by: index)
            if let existingBytes = gssOIDBytes(UnsafePointer(existing)), existingBytes == bytes {
                present.pointee = 1
                break
            }
        }
    }
    return gssComplete(minor_status)
}

public func gss_oid_equal(_ a: gss_const_OID?, _ b: gss_const_OID?) -> Int32 {
    if a == nil && b == nil { return 1 }
    if a == nil || b == nil { return 0 }
    if a == b { return 1 }
    guard let left = gssOIDBytes(a), let right = gssOIDBytes(b) else { return 0 }
    return left == right ? 1 : 0
}

public func gss_oid_to_str(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ oid: gss_OID,
    _ oid_str: gss_buffer_t
) -> OM_uint32 {
    oid_str.pointee.length = 0
    oid_str.pointee.value = nil
    guard let bytes = gssOIDBytes(UnsafePointer(oid)), let arcs = gssDecodeOIDArcs(bytes) else {
        return gssFail(minor_status, GSS_S_FAILURE, minor: GSSLinuxMinor.invalidArgument)
    }
    let body = arcs.map(String.init).joined(separator: " ")
    let rendered = "{ \(body) }"
    let encoded = Array(rendered.utf8)
    if gssFillBuffer(oid_str, bytes: encoded) != 0 {
        return gssFail(minor_status, GSS_S_FAILURE, minor: GSSLinuxMinor.noMemory)
    }
    return gssComplete(minor_status)
}

public func gss_create_empty_buffer_set(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ buffer_set: UnsafeMutablePointer<gss_buffer_set_t?>
) -> OM_uint32 {
    let set = UnsafeMutablePointer<gss_buffer_set_desc_struct>.allocate(capacity: 1)
    set.initialize(to: gss_buffer_set_desc_struct())
    buffer_set.pointee = set
    return gssComplete(minor_status)
}

public func gss_release_buffer_set(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ buffer_set: UnsafeMutablePointer<gss_buffer_set_t?>
) -> OM_uint32 {
    minor_status.pointee = GSSLinuxMinor.success
    guard let handle = buffer_set.pointee else { return 0 }
    if handle.pointee.count > 0, let elements = handle.pointee.elements {
        for index in 0..<handle.pointee.count {
            GSSAlloc.free(elements.advanced(by: index).pointee.value)
        }
        elements.deallocate()
    }
    handle.deinitialize(count: 1)
    handle.deallocate()
    buffer_set.pointee = nil
    return 0
}

public func gss_add_buffer_set_member(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ member_buffer: gss_buffer_t,
    _ buffer_set: UnsafeMutablePointer<gss_buffer_set_t>
) -> OM_uint32 {
    let handle = buffer_set.pointee
    let bytes = gssReadBuffer(UnsafePointer(member_buffer))
    let newCount = handle.pointee.count + 1
    let newElements = UnsafeMutablePointer<gss_buffer_desc>.allocate(capacity: newCount)
    if handle.pointee.count > 0, let old = handle.pointee.elements {
        for index in 0..<handle.pointee.count {
            newElements.advanced(by: index).initialize(to: old.advanced(by: index).pointee)
        }
        old.deallocate()
    }
    var copy = gss_buffer_desc()
    if !bytes.isEmpty {
        if gssFillBuffer(&copy, bytes: bytes) != 0 {
            newElements.deinitialize(count: handle.pointee.count)
            newElements.deallocate()
            return gssFail(minor_status, GSS_S_FAILURE, minor: GSSLinuxMinor.noMemory)
        }
    }
    newElements.advanced(by: handle.pointee.count).initialize(to: copy)
    handle.pointee.elements = newElements
    handle.pointee.count = newCount
    return gssComplete(minor_status)
}

public func gss_encapsulate_token(
    _ input_token: gss_const_buffer_t,
    _ oid: gss_const_OID,
    _ output_token: gss_buffer_t
) -> OM_uint32 {
    output_token.pointee.length = 0
    output_token.pointee.value = nil
    guard let oidBytes = gssOIDBytes(oid) else {
        return gssMajor(GSS_S_FAILURE)
    }
    let token = gssReadBuffer(input_token)
    let oidDER: [UInt8] = [0x06] + gssDERLength(oidBytes.count) + oidBytes
    let inner = oidDER + token
    let wrapped: [UInt8] = [0x60] + gssDERLength(inner.count) + inner
    var unused: OM_uint32 = 0
    if gssFillBuffer(output_token, bytes: wrapped) != 0 {
        unused = GSSLinuxMinor.noMemory
        _ = unused
        return gssMajor(GSS_S_FAILURE)
    }
    return 0
}

public func gss_decapsulate_token(
    _ input_token: gss_const_buffer_t,
    _ oid: gss_const_OID,
    _ output_token: gss_buffer_t
) -> OM_uint32 {
    output_token.pointee.length = 0
    output_token.pointee.value = nil
    guard let expectedOID = gssOIDBytes(oid) else {
        return gssMajor(GSS_S_FAILURE)
    }
    let bytes = gssReadBuffer(input_token)
    guard bytes.count >= 2, bytes[0] == 0x60 else {
        return gssMajor(GSS_S_DEFECTIVE_TOKEN)
    }
    var offset = 1
    guard let innerLen = gssParseDERLength(bytes, offset: &offset) else {
        return gssMajor(GSS_S_DEFECTIVE_TOKEN)
    }
    guard offset + innerLen == bytes.count else {
        return gssMajor(GSS_S_DEFECTIVE_TOKEN)
    }
    guard offset < bytes.count, bytes[offset] == 0x06 else {
        return gssMajor(GSS_S_DEFECTIVE_TOKEN)
    }
    offset += 1
    guard let oidLen = gssParseDERLength(bytes, offset: &offset),
          offset + oidLen <= bytes.count
    else {
        return gssMajor(GSS_S_DEFECTIVE_TOKEN)
    }
    let actualOID = Array(bytes[offset..<(offset + oidLen)])
    guard actualOID == expectedOID else {
        return gssMajor(GSS_S_BAD_MECH)
    }
    offset += oidLen
    let token = Array(bytes[offset...])
    if gssFillBuffer(output_token, bytes: token) != 0 {
        return gssMajor(GSS_S_FAILURE)
    }
    return 0
}
