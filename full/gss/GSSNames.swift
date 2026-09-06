import CoreFoundation

public func gss_import_name(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ input_name_buffer: gss_buffer_t,
    _ input_name_type: gss_const_OID?,
    _ output_name: UnsafeMutablePointer<gss_name_t?>
) -> OM_uint32 {
    output_name.pointee = nil
    let display = gssReadBuffer(UnsafePointer(input_name_buffer))
    let nameType = gssOIDBytes(input_name_type) ?? []
    let box = GSSNameBox(display: display, nameType: nameType, isMN: false)
    output_name.pointee = GSSNameStore.retain(box)
    return gssComplete(minor_status)
}

public func gss_display_name(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ input_name: gss_name_t,
    _ output_name_buffer: gss_buffer_t,
    _ output_name_type: UnsafeMutablePointer<gss_OID?>?
) -> OM_uint32 {
    output_name_buffer.pointee.length = 0
    output_name_buffer.pointee.value = nil
    output_name_type?.pointee = nil
    guard let box = GSSNameStore.lookup(input_name) else {
        return gssFail(minor_status, GSS_S_BAD_NAME, minor: GSSLinuxMinor.invalidArgument)
    }
    if gssFillBuffer(output_name_buffer, bytes: box.display) != 0 {
        return gssFail(minor_status, GSS_S_FAILURE, minor: GSSLinuxMinor.noMemory)
    }
    if !box.nameType.isEmpty {
        output_name_type?.pointee = withUnsafeMutablePointer(to: &box.oidStorage) { $0 }
    }
    return gssComplete(minor_status)
}

public func gss_compare_name(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ name1_arg: gss_name_t,
    _ name2_arg: gss_name_t,
    _ name_equal: UnsafeMutablePointer<Int32>
) -> OM_uint32 {
    name_equal.pointee = 0
    guard let left = GSSNameStore.lookup(name1_arg), let right = GSSNameStore.lookup(name2_arg) else {
        return gssFail(minor_status, GSS_S_BAD_NAME, minor: GSSLinuxMinor.invalidArgument)
    }
    if left.display == right.display && left.nameType == right.nameType {
        name_equal.pointee = 1
    }
    return gssComplete(minor_status)
}

public func gss_duplicate_name(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ src_name: gss_name_t,
    _ dest_name: UnsafeMutablePointer<gss_name_t?>
) -> OM_uint32 {
    dest_name.pointee = nil
    guard let box = GSSNameStore.lookup(src_name) else {
        return gssFail(minor_status, GSS_S_BAD_NAME, minor: GSSLinuxMinor.invalidArgument)
    }
    let copy = GSSNameBox(display: box.display, nameType: box.nameType, isMN: box.isMN)
    dest_name.pointee = GSSNameStore.retain(copy)
    return gssComplete(minor_status)
}

public func gss_release_name(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ input_name: UnsafeMutablePointer<gss_name_t?>
) -> OM_uint32 {
    if let name = input_name.pointee {
        GSSNameStore.release(name)
    }
    input_name.pointee = nil
    return gssComplete(minor_status)
}

public func gss_canonicalize_name(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ input_name: gss_name_t,
    _ mech_type: gss_OID,
    _ output_name: UnsafeMutablePointer<gss_name_t?>
) -> OM_uint32 {
    output_name.pointee = nil
    _ = input_name
    _ = mech_type
    return gssFail(minor_status, GSS_S_BAD_MECH)
}

public func gss_export_name(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ input_name: gss_name_t,
    _ exported_name: gss_buffer_t
) -> OM_uint32 {
    exported_name.pointee.length = 0
    exported_name.pointee.value = nil
    guard GSSNameStore.lookup(input_name) != nil else {
        return gssFail(minor_status, GSS_S_BAD_NAME, minor: GSSLinuxMinor.invalidArgument)
    }
    return gssFail(minor_status, GSS_S_NAME_NOT_MN)
}

public func gss_inquire_name(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ input_name: gss_name_t,
    _ name_is_MN: UnsafeMutablePointer<Int32>,
    _ MN_mech: UnsafeMutablePointer<gss_OID?>?,
    _ attrs: UnsafeMutablePointer<gss_buffer_set_t?>?
) -> OM_uint32 {
    name_is_MN.pointee = 0
    MN_mech?.pointee = nil
    attrs?.pointee = nil
    guard let box = GSSNameStore.lookup(input_name) else {
        return gssFail(minor_status, GSS_S_BAD_NAME, minor: GSSLinuxMinor.invalidArgument)
    }
    name_is_MN.pointee = box.isMN ? 1 : 0
    return gssComplete(minor_status)
}

public func gss_inquire_mechs_for_name(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ input_name: gss_name_t,
    _ mech_types: UnsafeMutablePointer<gss_OID_set?>
) -> OM_uint32 {
    mech_types.pointee = nil
    guard GSSNameStore.lookup(input_name) != nil else {
        return gssFail(minor_status, GSS_S_BAD_NAME, minor: GSSLinuxMinor.invalidArgument)
    }
    return gss_create_empty_oid_set(minor_status, mech_types)
}

public func GSSCreateName(
    _ name: CFTypeRef,
    _ name_type: gss_const_OID,
    _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?
) -> gss_name_t? {
    error?.pointee = nil
    var bytes: [UInt8] = []
    if CFGetTypeID(name) == CFStringGetTypeID() {
        let string = unsafeBitCast(name, to: CFString.self)
        guard let encoded = gssCFStringBytes(string) else {
            error?.pointee = GSSCreateError(name_type, gssMajor(GSS_S_BAD_NAME), GSSLinuxMinor.invalidArgument)
            return nil
        }
        bytes = encoded
    } else if CFGetTypeID(name) == CFDataGetTypeID() {
        let data = unsafeBitCast(name, to: CFData.self)
        let length = CFDataGetLength(data)
        if length > 0, let pointer = CFDataGetBytePtr(data) {
            bytes = Array(UnsafeBufferPointer(start: pointer, count: length))
        }
    } else {
        error?.pointee = GSSCreateError(name_type, gssMajor(GSS_S_BAD_NAME), GSSLinuxMinor.invalidArgument)
        return nil
    }
    var storage = bytes
    var minor: OM_uint32 = 0
    var output: gss_name_t? = nil
    let major: OM_uint32 = storage.withUnsafeMutableBytes { raw in
        var buffer = gss_buffer_desc_struct(
            length: bytes.count,
            value: raw.baseAddress
        )
        return gss_import_name(&minor, &buffer, name_type, &output)
    }
    if major != 0 {
        error?.pointee = GSSCreateError(name_type, major, minor)
        return nil
    }
    return output
}

public func GSSNameCreateDisplayString(_ name: gss_name_t) -> Unmanaged<CFString>? {
    var minor: OM_uint32 = 0
    var buffer = gss_buffer_desc()
    let major = gss_display_name(&minor, name, &buffer, nil)
    defer { _ = gss_release_buffer(&minor, &buffer) }
    guard major == 0 else { return nil }
    let bytes = withUnsafePointer(to: &buffer) { gssReadBuffer($0) }
    return bytes.withUnsafeBufferPointer { raw in
        let cf = CFStringCreateWithBytes(
            kCFAllocatorDefault,
            raw.baseAddress,
            bytes.count,
            CFStringBuiltInEncodings.UTF8.rawValue,
            false
        )
        guard let cf else { return nil }
        return Unmanaged.passRetained(cf)
    }
}
