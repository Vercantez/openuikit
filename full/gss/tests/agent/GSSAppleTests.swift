import CoreFoundation
import GSS

func testGSSAAPLInitialCred() {
    var name: gss_name_t? = gssImportUser("user@REALM")
    var cred: gss_cred_id_t? = gssFakeCred()
    var error: Unmanaged<CFError>? = nil
    let major: OM_uint32 = gssWithConstOID(gssKRB5MechOID) { oid in
        gss_aapl_initial_cred(name!, oid, nil, &cred, &error)
    }
    gssRequireStatus(major, GSS_S_NO_CRED, "aapl initial")
    gssRequire(cred == nil, "no cred")
    gssRequire(error != nil, "cf error")
    _ = error?.takeRetainedValue()
    var minor: OM_uint32 = 0
    _ = gss_release_name(&minor, &name)
}

func testGSSAAPLChangePassword() {
    var name: gss_name_t? = gssImportUser("user@REALM")
    var error: Unmanaged<CFError>? = nil
    let empty = CFDictionaryCreate(
        kCFAllocatorDefault, nil, nil, 0, nil, nil
    )!
    let major: OM_uint32 = gssWithConstOID(gssKRB5MechOID) { oid in
        gss_aapl_change_password(name!, oid, empty, &error)
    }
    gssRequireStatus(major, GSS_S_UNAVAILABLE, "change password")
    gssRequire(error != nil, "cf error")
    _ = error?.takeRetainedValue()
    var minor: OM_uint32 = 0
    _ = gss_release_name(&minor, &name)
}

func testGSSUserok() {
    var name: gss_name_t? = gssImportUser("alice")
    let result = "alice".withCString { pointer in
        gss_userok(name!, pointer)
    }
    gssRequire(result == 0, "fail closed")
    var minor: OM_uint32 = 0
    _ = gss_release_name(&minor, &name)
}

func testGSSKrb5CcacheName() {
    var minor: OM_uint32 = 0
    var out: UnsafePointer<CChar>? = UnsafePointer(bitPattern: 1)
    gssRequireStatus(gss_krb5_ccache_name(&minor, nil, &out), GSS_S_UNAVAILABLE, "ccache")
    gssRequire(out == nil, "nil out")
}

func testGSSKrb5ExportLucidSecContext() {
    var minor: OM_uint32 = 0
    var ctx: gss_ctx_id_t? = gssFakeContext()
    gssRequireStatus(
        gss_krb5_export_lucid_sec_context(&minor, &ctx, 1, nil),
        GSS_S_UNAVAILABLE,
        "lucid export"
    )
}

func testGSSKrb5FreeLucidSecContext() {
    var minor: OM_uint32 = 0
    var storage = 0
    withUnsafeMutableBytes(of: &storage) { raw in
        gssRequireStatus(
            gss_krb5_free_lucid_sec_context(&minor, raw.baseAddress!),
            GSS_S_UNAVAILABLE,
            "lucid free"
        )
    }
}

func testGSSKrb5SetAllowableEnctypes() {
    var minor: OM_uint32 = 0
    var enctypes: [Int32] = [16]
    gssRequireStatus(
        gss_krb5_set_allowable_enctypes(&minor, gssFakeCred(), 1, &enctypes),
        GSS_S_UNAVAILABLE,
        "enctypes"
    )
}

func testGSSKrb5ExtractAuthzData() {
    var minor: OM_uint32 = 0
    var data = gss_buffer_desc()
    gssRequireStatus(
        gsskrb5_extract_authz_data_from_sec_context(&minor, gssFakeContext(), 1, &data),
        GSS_S_UNAVAILABLE,
        "authz"
    )
}

func testGSSKrb5RegisterAcceptorIdentity() {
    let major = "/tmp/keytab".withCString { pointer in
        gsskrb5_register_acceptor_identity(pointer)
    }
    gssRequireStatus(major, GSS_S_UNAVAILABLE, "register")
}

func testKrb5GSSRegisterAcceptorIdentity() {
    let major = "/tmp/keytab".withCString { pointer in
        krb5_gss_register_acceptor_identity(pointer)
    }
    gssRequireStatus(major, GSS_S_UNAVAILABLE, "alias")
}
