import CoreFoundation
import GSS

func testGSSDisplayStatus() {
    var minor: OM_uint32 = 0
    var context: OM_uint32 = 0
    var buffer = gss_buffer_desc()
    gssRequire(
        gss_display_status(&minor, 0, GSS_C_GSS_CODE, nil, &context, &buffer) == 0,
        "complete"
    )
    let complete = withUnsafePointer(to: &buffer) { gssReadBufferForTest($0) }
    gssRequire(String(decoding: complete, as: UTF8.self).contains("successfully"), "complete text")
    _ = gss_release_buffer(&minor, &buffer)

    context = 0
    gssRequire(
        gss_display_status(
            &minor,
            OM_uint32(truncatingIfNeeded: GSS_S_NO_CONTEXT),
            GSS_C_GSS_CODE,
            nil,
            &context,
            &buffer
        ) == 0,
        "no context"
    )
    let noContext = withUnsafePointer(to: &buffer) { gssReadBufferForTest($0) }
    gssRequire(String(decoding: noContext, as: UTF8.self).contains("context"), "no context text")
    _ = gss_release_buffer(&minor, &buffer)

    context = 0
    gssRequireStatus(
        gss_display_status(&minor, 1, 99, nil, &context, &buffer),
        GSS_S_BAD_STATUS,
        "bad type"
    )
}

func testGSSCreateError() {
    let unmanaged: Unmanaged<CFError>? = gssWithConstOID(gssKRB5MechOID) { oid in
        GSSCreateError(oid, OM_uint32(truncatingIfNeeded: GSS_S_NO_CRED), 1)
    }
    gssRequire(unmanaged != nil, "error")
    let error = unmanaged!.takeRetainedValue()
    gssRequire(CFErrorGetCode(error) == CFIndex(GSS_S_NO_CRED), "code")
    let domain = CFErrorGetDomain(error)
    var chars = [CChar](repeating: 0, count: 64)
    gssRequire(
        CFStringGetCString(domain, &chars, chars.count, CFStringBuiltInEncodings.UTF8.rawValue),
        "domain string"
    )
    gssRequire(String(cString: chars) == GSSModuleInfo.errorDomain, "domain")
}
