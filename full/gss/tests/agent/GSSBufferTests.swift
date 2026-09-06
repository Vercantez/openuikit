import GSS

func testGSSReleaseBuffer() {
    var minor: OM_uint32 = 99
    var buffer = gss_buffer_desc()
    gssRequire(gss_release_buffer(&minor, &buffer) == 0, "empty release")
    gssRequire(minor == 0, "minor")
    gssRequire(buffer.value == nil && buffer.length == 0, "cleared")
}

func testGSSCreateReleaseEmptyOIDSet() {
    var minor: OM_uint32 = 1
    var set: gss_OID_set? = nil
    gssRequire(gss_create_empty_oid_set(&minor, &set) == 0, "create")
    gssRequire(set != nil, "set")
    gssRequire(set!.pointee.count == 0, "count")
    gssRequire(gss_release_oid_set(&minor, &set) == 0, "release")
    gssRequire(set == nil, "nil after release")
}

func testGSSAddAndTestOIDSetMember() {
    var minor: OM_uint32 = 0
    var set: gss_OID_set? = nil
    gssRequire(gss_create_empty_oid_set(&minor, &set) == 0, "create")
    gssWithConstOID(gssNTUserNameOID) { oid in
        var present: Int32 = 1
        gssRequire(gss_add_oid_set_member(&minor, oid, &set!) == 0, "add")
        gssRequire(set!.pointee.count == 1, "count 1")
        gssRequire(gss_test_oid_set_member(&minor, oid, set!, &present) == 0, "test")
        gssRequire(present == 1, "present")
        gssRequire(gss_add_oid_set_member(&minor, oid, &set!) == 0, "add duplicate")
        gssRequire(set!.pointee.count == 1, "still 1")
    }
    gssWithConstOID(gssKRB5MechOID) { oid in
        var present: Int32 = 1
        gssRequire(gss_test_oid_set_member(&minor, oid, set!, &present) == 0, "absent test")
        gssRequire(present == 0, "absent")
        gssRequire(gss_add_oid_set_member(&minor, oid, &set!) == 0, "add second")
        gssRequire(set!.pointee.count == 2, "count 2")
    }
    gssRequire(gss_release_oid_set(&minor, &set) == 0, "release")
}

func testGSSOIDEqual() {
    gssRequire(gss_oid_equal(nil, nil) == 1, "nil nil")
    gssWithConstOID(gssNTUserNameOID) { left in
        gssRequire(gss_oid_equal(left, nil) == 0, "nil right")
        gssWithConstOID(gssNTUserNameOID) { right in
            gssRequire(gss_oid_equal(left, right) == 1, "same oid")
        }
        gssWithConstOID(gssKRB5MechOID) { right in
            gssRequire(gss_oid_equal(left, right) == 0, "different oid")
        }
    }
}

func testGSSOIDToStr() {
    var minor: OM_uint32 = 0
    var rendered = gss_buffer_desc()
    gssWithOID(gssKRB5MechOID) { oid in
        gssRequire(gss_oid_to_str(&minor, oid, &rendered) == 0, "oid_to_str")
    }
    let text = withUnsafePointer(to: &rendered) { pointer in
        String(decoding: gssReadBufferForTest(pointer), as: UTF8.self)
    }
    gssRequire(text == "{ 1 2 840 113554 1 2 2 }", "krb5 oid string \(text)")
    gssRequire(gss_release_buffer(&minor, &rendered) == 0, "release")
}

func gssReadBufferForTest(_ buffer: gss_const_buffer_t) -> [UInt8] {
    let length = buffer.pointee.length
    guard length > 0, let value = buffer.pointee.value else { return [] }
    return Array(UnsafeRawBufferPointer(start: value, count: length))
}

func testGSSCreateReleaseEmptyBufferSet() {
    var minor: OM_uint32 = 0
    var set: gss_buffer_set_t? = nil
    gssRequire(gss_create_empty_buffer_set(&minor, &set) == 0, "create")
    gssRequire(set != nil && set!.pointee.count == 0, "empty")
    gssRequire(gss_release_buffer_set(&minor, &set) == 0, "release")
    gssRequire(set == nil, "nil")
}

func testGSSAddBufferSetMember() {
    var minor: OM_uint32 = 0
    var set: gss_buffer_set_t? = nil
    gssRequire(gss_create_empty_buffer_set(&minor, &set) == 0, "create")
    var payload: [UInt8] = [9, 8, 7]
    payload.withUnsafeMutableBytes { raw in
        var member = gss_buffer_desc_struct(length: 3, value: raw.baseAddress)
        gssRequire(gss_add_buffer_set_member(&minor, &member, &set!) == 0, "add")
    }
    gssRequire(set!.pointee.count == 1, "count")
    gssRequire(set!.pointee.elements.pointee.length == 3, "copied length")
    gssRequire(gss_release_buffer_set(&minor, &set) == 0, "release")
}

func testGSSEncapsulateDecapsulateToken() {
    var payload: [UInt8] = [0xde, 0xad, 0xbe, 0xef]
    let payloadCount = payload.count
    var wrapped = gss_buffer_desc()
    var inner = gss_buffer_desc()
    let encapMajor: OM_uint32 = payload.withUnsafeMutableBytes { raw in
        var input = gss_buffer_desc_struct(length: payloadCount, value: raw.baseAddress)
        return gssWithConstOID(gssKRB5MechOID) { oid in
            withUnsafePointer(to: &input) { inputPtr in
                gss_encapsulate_token(inputPtr, oid, &wrapped)
            }
        }
    }
    gssRequire(encapMajor == 0, "encap")
    gssRequire(wrapped.length > payloadCount, "framed")
    let decapMajor: OM_uint32 = gssWithConstOID(gssKRB5MechOID) { oid in
        withUnsafePointer(to: &wrapped) { wrapPtr in
            gss_decapsulate_token(wrapPtr, oid, &inner)
        }
    }
    gssRequire(decapMajor == 0, "decap")
    gssRequire(inner.length == 4, "inner length")
    let recovered = withUnsafePointer(to: &inner) { gssReadBufferForTest($0) }
    gssRequire(recovered == [0xde, 0xad, 0xbe, 0xef], "round trip")
    var minor: OM_uint32 = 0
    gssRequire(gss_release_buffer(&minor, &wrapped) == 0, "release wrap")
    gssRequire(gss_release_buffer(&minor, &inner) == 0, "release inner")
}

func testGSSDecapsulateWrongOID() {
    var payload: [UInt8] = [1, 2]
    var wrapped = gss_buffer_desc()
    var inner = gss_buffer_desc()
    let encapMajor: OM_uint32 = payload.withUnsafeMutableBytes { raw in
        var input = gss_buffer_desc_struct(length: 2, value: raw.baseAddress)
        return gssWithConstOID(gssKRB5MechOID) { oid in
            withUnsafePointer(to: &input) { inputPtr in
                gss_encapsulate_token(inputPtr, oid, &wrapped)
            }
        }
    }
    gssRequire(encapMajor == 0, "encap")
    gssWithConstOID(gssNTUserNameOID) { oid in
        withUnsafePointer(to: &wrapped) { wrapPtr in
            gssRequireStatus(
                gss_decapsulate_token(wrapPtr, oid, &inner),
                GSS_S_BAD_MECH,
                "wrong oid"
            )
        }
    }
    var minor: OM_uint32 = 0
    _ = gss_release_buffer(&minor, &wrapped)
}
