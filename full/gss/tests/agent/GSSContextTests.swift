import GSS

func testGSSIndicateMechs() {
    var minor: OM_uint32 = 0
    var set: gss_OID_set? = nil
    gssRequire(gss_indicate_mechs(&minor, &set) == 0, "indicate")
    gssRequire(set != nil && set!.pointee.count == 0, "no mechs")
    _ = gss_release_oid_set(&minor, &set)
}

func testGSSIndicateMechsByAttrs() {
    var minor: OM_uint32 = 0
    var set: gss_OID_set? = nil
    gssRequire(gss_indicate_mechs_by_attrs(&minor, nil, nil, nil, &set) == 0, "by attrs")
    gssRequire(set!.pointee.count == 0, "empty")
    _ = gss_release_oid_set(&minor, &set)
}

func testGSSInquireAttrsForMech() {
    var minor: OM_uint32 = 0
    var attrs: gss_OID_set? = nil
    gssWithConstOID(gssKRB5MechOID) { oid in
        gssRequireStatus(
            gss_inquire_attrs_for_mech(&minor, oid, &attrs, nil),
            GSS_S_BAD_MECH,
            "attrs"
        )
    }
}

func testGSSDisplayMechAttr() {
    var minor: OM_uint32 = 0
    var name = gss_buffer_desc()
    gssWithConstOID(gssNTUserNameOID) { oid in
        gssRequireStatus(
            gss_display_mech_attr(&minor, oid, &name, nil, nil),
            GSS_S_BAD_MECH_ATTR,
            "display attr"
        )
    }
}

func testGSSInquireNamesForMech() {
    var minor: OM_uint32 = 0
    var names: gss_OID_set? = nil
    gssWithConstOID(gssKRB5MechOID) { oid in
        gssRequireStatus(
            gss_inquire_names_for_mech(&minor, oid, &names),
            GSS_S_BAD_MECH,
            "names for mech"
        )
    }
}

func testGSSInquireSASLNameForMech() {
    var minor: OM_uint32 = 0
    var sasl = gss_buffer_desc()
    gssWithOID(gssKRB5MechOID) { oid in
        gssRequireStatus(
            gss_inquire_saslname_for_mech(&minor, oid, &sasl, nil, nil),
            GSS_S_BAD_MECH,
            "sasl"
        )
    }
}

func testGSSInquireMechForSASLName() {
    var minor: OM_uint32 = 0
    var mech: gss_OID? = nil
    var name = gss_buffer_desc()
    gssRequireStatus(
        gss_inquire_mech_for_saslname(&minor, &name, &mech),
        GSS_S_BAD_MECH,
        "mech for sasl"
    )
}

func testGSSInitSecContext() {
    var name: gss_name_t? = gssImportUser("host@example.com")
    var minor: OM_uint32 = 0
    var ctx: gss_ctx_id_t? = gssFakeContext()
    var token = gss_buffer_desc()
    var flags: OM_uint32 = 1
    gssRequireStatus(
        gss_init_sec_context(
            &minor, nil, &ctx, name!, nil, 0, 0, nil, nil, nil, &token, &flags, nil
        ),
        GSS_S_UNAVAILABLE,
        "init"
    )
    gssRequire(ctx == nil && token.length == 0 && flags == 0, "cleared")
    _ = gss_release_name(&minor, &name)
}

func testGSSAcceptSecContext() {
    var minor: OM_uint32 = 0
    var ctx: gss_ctx_id_t? = gssFakeContext()
    var token = gss_buffer_desc()
    gssRequireStatus(
        gss_accept_sec_context(
            &minor, &ctx, nil, nil, nil, nil, nil, &token, nil, nil, nil
        ),
        GSS_S_UNAVAILABLE,
        "accept"
    )
    gssRequire(ctx == nil, "no ctx")
}

func testGSSDeleteSecContext() {
    var minor: OM_uint32 = 0
    var ctx: gss_ctx_id_t? = nil
    var token = gss_buffer_desc()
    gssRequireStatus(gss_delete_sec_context(&minor, &ctx, &token), GSS_S_NO_CONTEXT, "delete nil")
    ctx = gssFakeContext()
    gssRequireStatus(gss_delete_sec_context(&minor, &ctx, nil), GSS_S_NO_CONTEXT, "delete fake")
    gssRequire(ctx == nil, "cleared")
}

func testGSSProcessContextToken() {
    var minor: OM_uint32 = 0
    var token = gss_buffer_desc()
    gssRequireStatus(
        gss_process_context_token(&minor, gssFakeContext(), &token),
        GSS_S_NO_CONTEXT,
        "process"
    )
}

func testGSSContextTime() {
    var minor: OM_uint32 = 0
    var time: OM_uint32 = 5
    gssRequireStatus(
        gss_context_time(&minor, gssFakeContext(), &time),
        GSS_S_NO_CONTEXT,
        "time"
    )
    gssRequire(time == 0, "zero")
}

func testGSSInquireContext() {
    var minor: OM_uint32 = 0
    gssRequireStatus(
        gss_inquire_context(&minor, gssFakeContext(), nil, nil, nil, nil, nil, nil, nil),
        GSS_S_NO_CONTEXT,
        "inquire ctx"
    )
}

func testGSSInquireSecContextByOID() {
    var minor: OM_uint32 = 0
    gssWithOID(gssNTUserNameOID) { oid in
        gssRequireStatus(
            gss_inquire_sec_context_by_oid(&minor, gssFakeContext(), oid, nil),
            GSS_S_NO_CONTEXT,
            "by oid"
        )
    }
}

func testGSSExportSecContext() {
    var minor: OM_uint32 = 0
    var ctx: gss_ctx_id_t? = gssFakeContext()
    var token = gss_buffer_desc()
    gssRequireStatus(
        gss_export_sec_context(&minor, &ctx, &token),
        GSS_S_UNAVAILABLE,
        "export ctx"
    )
}

func testGSSImportSecContext() {
    var minor: OM_uint32 = 0
    var token = gss_buffer_desc()
    var ctx: gss_ctx_id_t? = gssFakeContext()
    gssRequireStatus(
        gss_import_sec_context(&minor, &token, &ctx),
        GSS_S_UNAVAILABLE,
        "import ctx"
    )
    gssRequire(ctx == nil, "nil")
}

func testGSSGetMIC() {
    var minor: OM_uint32 = 0
    var message = gss_buffer_desc()
    var token = gss_buffer_desc()
    gssRequireStatus(
        gss_get_mic(&minor, gssFakeContext(), OM_uint32(GSS_C_QOP_DEFAULT), &message, &token),
        GSS_S_NO_CONTEXT,
        "get_mic"
    )
}

func testGSSVerifyMIC() {
    var minor: OM_uint32 = 0
    var message = gss_buffer_desc()
    var token = gss_buffer_desc()
    gssRequireStatus(
        gss_verify_mic(&minor, gssFakeContext(), &message, &token, nil),
        GSS_S_NO_CONTEXT,
        "verify_mic"
    )
}

func testGSSWrap() {
    var minor: OM_uint32 = 0
    var input = gss_buffer_desc()
    var output = gss_buffer_desc()
    var conf: Int32 = 1
    gssRequireStatus(
        gss_wrap(&minor, gssFakeContext(), 1, OM_uint32(GSS_C_QOP_DEFAULT), &input, &conf, &output),
        GSS_S_NO_CONTEXT,
        "wrap"
    )
    gssRequire(conf == 0, "conf")
}

func testGSSUnwrap() {
    var minor: OM_uint32 = 0
    var input = gss_buffer_desc()
    var output = gss_buffer_desc()
    gssRequireStatus(
        gss_unwrap(&minor, gssFakeContext(), &input, &output, nil, nil),
        GSS_S_NO_CONTEXT,
        "unwrap"
    )
}

func testGSSWrapSizeLimit() {
    var minor: OM_uint32 = 0
    var max: OM_uint32 = 9
    gssRequireStatus(
        gss_wrap_size_limit(&minor, gssFakeContext(), 1, OM_uint32(GSS_C_QOP_DEFAULT), 100, &max),
        GSS_S_NO_CONTEXT,
        "wrap size"
    )
    gssRequire(max == 0, "zero")
}

func testGSSPseudoRandom() {
    var minor: OM_uint32 = 0
    var input = gss_buffer_desc()
    var output = gss_buffer_desc()
    gssRequireStatus(
        gss_pseudo_random(&minor, gssFakeContext(), GSS_C_PRF_KEY_FULL, &input, 16, &output),
        GSS_S_NO_CONTEXT,
        "prf"
    )
}

func testGSSSetSecContextOption() {
    var minor: OM_uint32 = 0
    gssWithOID(gssNTUserNameOID) { oid in
        gssRequireStatus(
            gss_set_sec_context_option(&minor, nil, oid, nil),
            GSS_S_UNAVAILABLE,
            "set ctx option"
        )
    }
}
