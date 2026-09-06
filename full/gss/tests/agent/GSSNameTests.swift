import CoreFoundation
import GSS

func testGSSImportDisplayReleaseName() {
    var name: gss_name_t? = gssImportUser("alice@EXAMPLE.COM")
    var minor: OM_uint32 = 0
    var displayed = gss_buffer_desc()
    gssRequire(gss_display_name(&minor, name!, &displayed, nil) == 0, "display")
    let text = withUnsafePointer(to: &displayed) { gssReadBufferForTest($0) }
    gssRequire(String(decoding: text, as: UTF8.self) == "alice@EXAMPLE.COM", "round trip")
    gssRequire(gss_release_buffer(&minor, &displayed) == 0, "release buffer")
    gssRequire(gss_release_name(&minor, &name) == 0, "release name")
    gssRequire(name == nil, "nil name")
}

func testGSSCompareName() {
    var left: gss_name_t? = gssImportUser("same")
    var right: gss_name_t? = gssImportUser("same")
    var other: gss_name_t? = gssImportUser("other")
    var minor: OM_uint32 = 0
    var equal: Int32 = 0
    gssRequire(gss_compare_name(&minor, left!, right!, &equal) == 0, "compare equal")
    gssRequire(equal == 1, "equal")
    gssRequire(gss_compare_name(&minor, left!, other!, &equal) == 0, "compare ne")
    gssRequire(equal == 0, "not equal")
    _ = gss_release_name(&minor, &left)
    _ = gss_release_name(&minor, &right)
    _ = gss_release_name(&minor, &other)
}

func testGSSDuplicateName() {
    var src: gss_name_t? = gssImportUser("dup")
    var dest: gss_name_t? = nil
    var minor: OM_uint32 = 0
    gssRequire(gss_duplicate_name(&minor, src!, &dest) == 0, "dup")
    var equal: Int32 = 0
    gssRequire(gss_compare_name(&minor, src!, dest!, &equal) == 0 && equal == 1, "dup equal")
    _ = gss_release_name(&minor, &src)
    _ = gss_release_name(&minor, &dest)
}

func testGSSCanonicalizeNameFailClosed() {
    var name: gss_name_t? = gssImportUser("canon")
    var minor: OM_uint32 = 0
    var output: gss_name_t? = OpaquePointer(bitPattern: 1)
    gssWithOID(gssKRB5MechOID) { oid in
        gssRequireStatus(
            gss_canonicalize_name(&minor, name!, oid, &output),
            GSS_S_BAD_MECH,
            "canonicalize"
        )
    }
    gssRequire(output == nil, "no MN")
    _ = gss_release_name(&minor, &name)
}

func testGSSExportNameNotMN() {
    var name: gss_name_t? = gssImportUser("export")
    var minor: OM_uint32 = 0
    var exported = gss_buffer_desc()
    gssRequireStatus(gss_export_name(&minor, name!, &exported), GSS_S_NAME_NOT_MN, "export")
    gssRequire(exported.length == 0, "no token")
    _ = gss_release_name(&minor, &name)
}

func testGSSInquireName() {
    var name: gss_name_t? = gssImportUser("inquire")
    var minor: OM_uint32 = 0
    var isMN: Int32 = 1
    var mechPtr: gss_OID? = nil
    var attrs: gss_buffer_set_t? = nil
    gssRequire(gss_inquire_name(&minor, name!, &isMN, &mechPtr, &attrs) == 0, "inquire")
    gssRequire(isMN == 0, "not MN")
    gssRequire(mechPtr == nil, "no mech")
    gssRequire(attrs == nil, "no attrs")
    _ = gss_release_name(&minor, &name)
}

func testGSSInquireMechsForName() {
    var name: gss_name_t? = gssImportUser("mechs")
    var minor: OM_uint32 = 0
    var mechs: gss_OID_set? = nil
    gssRequire(gss_inquire_mechs_for_name(&minor, name!, &mechs) == 0, "inquire mechs")
    gssRequire(mechs != nil && mechs!.pointee.count == 0, "empty mechs")
    _ = gss_release_oid_set(&minor, &mechs)
    _ = gss_release_name(&minor, &name)
}

func testGSSCreateNameFromCFString() {
    let cfName = gssMakeCFStringForTest("bob@REALM")
    var error: Unmanaged<CFError>? = nil
    let imported: gss_name_t? = gssWithConstOID(gssNTUserNameOID) { oid in
        GSSCreateName(cfName, oid, &error)
    }
    gssRequire(imported != nil, "create name")
    gssRequire(error == nil, "no error")
    var minor: OM_uint32 = 0
    var displayed = gss_buffer_desc()
    gssRequire(gss_display_name(&minor, imported!, &displayed, nil) == 0, "display")
    let text = withUnsafePointer(to: &displayed) { gssReadBufferForTest($0) }
    gssRequire(String(decoding: text, as: UTF8.self) == "bob@REALM", "cf string")
    _ = gss_release_buffer(&minor, &displayed)
    var handle = imported
    _ = gss_release_name(&minor, &handle)
}

func gssMakeCFStringForTest(_ string: String) -> CFString {
    string.withCString { pointer in
        CFStringCreateWithCString(
            kCFAllocatorDefault,
            pointer,
            CFStringBuiltInEncodings.UTF8.rawValue
        )!
    }
}

func testGSSNameCreateDisplayString() {
    var name: gss_name_t? = gssImportUser("carol")
    let unmanaged = GSSNameCreateDisplayString(name!)
    gssRequire(unmanaged != nil, "display string")
    let cf = unmanaged!.takeRetainedValue()
    var buffer = [CChar](repeating: 0, count: 64)
    gssRequire(
        CFStringGetCString(cf, &buffer, buffer.count, CFStringBuiltInEncodings.UTF8.rawValue),
        "cstring"
    )
    gssRequire(String(cString: buffer) == "carol", "value")
    var minor: OM_uint32 = 0
    _ = gss_release_name(&minor, &name)
}
