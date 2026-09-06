import CoreFoundation
import GSS

func gssFakeCred() -> gss_cred_id_t {
    OpaquePointer(bitPattern: 0x51)!
}

func gssFakeContext() -> gss_ctx_id_t {
    OpaquePointer(bitPattern: 0x52)!
}

func testGSSAcquireCred() {
    var minor: OM_uint32 = 0
    var cred: gss_cred_id_t? = gssFakeCred()
    var mechs: gss_OID_set? = nil
    var time: OM_uint32 = 9
    gssRequireStatus(
        gss_acquire_cred(&minor, nil, 0, nil, GSS_C_INITIATE, &cred, &mechs, &time),
        GSS_S_NO_CRED,
        "acquire"
    )
    gssRequire(cred == nil && mechs == nil && time == 0, "cleared")
}

func testGSSAcquireCredWithPassword() {
    var name: gss_name_t? = gssImportUser("pw")
    var passwordBytes = Array("secret".utf8)
    let passwordCount = passwordBytes.count
    var minor: OM_uint32 = 0
    var cred: gss_cred_id_t? = gssFakeCred()
    passwordBytes.withUnsafeMutableBytes { raw in
        var password = gss_buffer_desc_struct(length: passwordCount, value: raw.baseAddress)
        gssRequireStatus(
            gss_acquire_cred_with_password(
                &minor, name!, &password, 0, nil, GSS_C_INITIATE, &cred, nil, nil
            ),
            GSS_S_NO_CRED,
            "password"
        )
    }
    gssRequire(cred == nil, "no cred")
    _ = gss_release_name(&minor, &name)
}

func testGSSAddCred() {
    var minor: OM_uint32 = 0
    var out: gss_cred_id_t? = gssFakeCred()
    gssRequireStatus(
        gss_add_cred(&minor, nil, nil, nil, GSS_C_BOTH, 0, 0, &out, nil, nil, nil),
        GSS_S_NO_CRED,
        "add_cred"
    )
    gssRequire(out == nil, "nil")
}

func testGSSReleaseCred() {
    var minor: OM_uint32 = 0
    var cred: gss_cred_id_t? = nil
    gssRequire(gss_release_cred(&minor, &cred) == 0, "release none")
}

func testGSSDestroyCred() {
    var minor: OM_uint32 = 0
    var cred: gss_cred_id_t? = nil
    gssRequire(gss_destroy_cred(&minor, &cred) == 0, "destroy none")
}

func testGSSInquireCred() {
    var minor: OM_uint32 = 0
    var name: gss_name_t? = gssImportUser("x")
    var lifetime: OM_uint32 = 3
    var usage: gss_cred_usage_t = 9
    var mechs: gss_OID_set? = nil
    gssRequireStatus(
        gss_inquire_cred(&minor, nil, &name, &lifetime, &usage, &mechs),
        GSS_S_NO_CRED,
        "inquire cred"
    )
    gssRequire(lifetime == 0 && usage == 0 && mechs == nil, "cleared")
}

func testGSSInquireCredByMech() {
    var minor: OM_uint32 = 0
    var name: gss_name_t? = nil
    gssWithOID(gssKRB5MechOID) { oid in
        gssRequireStatus(
            gss_inquire_cred_by_mech(&minor, nil, oid, &name, nil, nil, nil),
            GSS_S_NO_CRED,
            "by mech"
        )
    }
}

func testGSSInquireCredByOID() {
    var minor: OM_uint32 = 0
    var data: gss_buffer_set_t? = nil
    gssWithOID(gssNTUserNameOID) { oid in
        gssRequireStatus(
            gss_inquire_cred_by_oid(&minor, gssFakeCred(), oid, &data),
            GSS_S_NO_CRED,
            "by oid"
        )
    }
}

func testGSSExportCred() {
    var minor: OM_uint32 = 0
    var token = gss_buffer_desc()
    gssRequireStatus(gss_export_cred(&minor, gssFakeCred(), &token), GSS_S_NO_CRED, "export cred")
}

func testGSSImportCred() {
    var minor: OM_uint32 = 0
    var token = gss_buffer_desc()
    var cred: gss_cred_id_t? = gssFakeCred()
    gssRequireStatus(
        gss_import_cred(&minor, &token, &cred),
        GSS_S_DEFECTIVE_CREDENTIAL,
        "import cred"
    )
    gssRequire(cred == nil, "nil")
}

func testGSSSetCredOption() {
    var minor: OM_uint32 = 0
    var cred: gss_cred_id_t? = nil
    gssWithOID(gssNTUserNameOID) { oid in
        gssRequireStatus(
            gss_set_cred_option(&minor, &cred, oid, nil),
            GSS_S_UNAVAILABLE,
            "set option"
        )
    }
}

func testGSSIterCreds() {
    var minor: OM_uint32 = 1
    var calls = 0
    gssRequire(gss_iter_creds(&minor, 0, nil) { _, _ in calls += 1 } == 0, "iter")
    gssRequire(calls == 0, "no creds")
}

func testGSSIterCredsF() {
    var minor: OM_uint32 = 1
    var calls = 0
    gssRequire(
        gss_iter_creds_f(&minor, 0, nil, nil) { _, _, _ in calls += 1 } == 0,
        "iter f"
    )
    gssRequire(calls == 0, "no creds f")
}

func testGSSCreateCredentialFromUUID() {
    let uuid = CFUUIDCreate(kCFAllocatorDefault)!
    gssRequire(GSSCreateCredentialFromUUID(uuid) == nil, "no store")
}

func testGSSCredentialCopyName() {
    gssRequire(GSSCredentialCopyName(gssFakeCred()) == nil, "copy name")
}

func testGSSCredentialCopyUUID() {
    gssRequire(GSSCredentialCopyUUID(gssFakeCred()) == nil, "copy uuid")
}

func testGSSCredentialGetLifetime() {
    gssRequire(GSSCredentialGetLifetime(gssFakeCred()) == 0, "lifetime")
}
