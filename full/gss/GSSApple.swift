import CoreFoundation

public func gss_aapl_initial_cred(
    _ desired_name: gss_name_t,
    _ desired_mech: gss_const_OID,
    _ attributes: CFDictionary?,
    _ output_cred_handle: UnsafeMutablePointer<gss_cred_id_t?>,
    _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?
) -> OM_uint32 {
    _ = attributes
    output_cred_handle.pointee = nil
    error?.pointee = GSSCreateError(desired_mech, gssMajor(GSS_S_NO_CRED), GSSLinuxMinor.unavailable)
    _ = desired_name
    return gssMajor(GSS_S_NO_CRED)
}

public func gss_aapl_change_password(
    _ name: gss_name_t,
    _ mech: gss_const_OID,
    _ attributes: CFDictionary,
    _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?
) -> OM_uint32 {
    _ = name
    _ = attributes
    error?.pointee = GSSCreateError(mech, gssMajor(GSS_S_UNAVAILABLE), GSSLinuxMinor.unavailable)
    return gssMajor(GSS_S_UNAVAILABLE)
}

public func gss_userok(_ name: gss_name_t, _ user: UnsafePointer<CChar>) -> Int32 {
    _ = name
    _ = user
    return 0
}

public func gss_krb5_ccache_name(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ name: UnsafePointer<CChar>?,
    _ out_name: UnsafeMutablePointer<UnsafePointer<CChar>?>?
) -> OM_uint32 {
    _ = name
    out_name?.pointee = nil
    return gssFail(minor_status, GSS_S_UNAVAILABLE)
}

public func gss_krb5_export_lucid_sec_context(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ context_handle: UnsafeMutablePointer<gss_ctx_id_t?>,
    _ version: OM_uint32,
    _ rctx: UnsafeMutablePointer<UnsafeMutableRawPointer>?
) -> OM_uint32 {
    _ = context_handle
    _ = version
    _ = rctx
    return gssFail(minor_status, GSS_S_UNAVAILABLE)
}

public func gss_krb5_free_lucid_sec_context(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ c: UnsafeMutableRawPointer
) -> OM_uint32 {
    _ = c
    return gssFail(minor_status, GSS_S_UNAVAILABLE)
}

public func gss_krb5_set_allowable_enctypes(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ cred: gss_cred_id_t,
    _ num_enctypes: OM_uint32,
    _ enctypes: UnsafeMutablePointer<Int32>
) -> OM_uint32 {
    _ = cred
    _ = num_enctypes
    _ = enctypes
    return gssFail(minor_status, GSS_S_UNAVAILABLE)
}

public func gsskrb5_extract_authz_data_from_sec_context(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ context_handle: gss_ctx_id_t,
    _ ad_type: Int32,
    _ ad_data: gss_buffer_t
) -> OM_uint32 {
    _ = context_handle
    _ = ad_type
    ad_data.pointee.length = 0
    ad_data.pointee.value = nil
    return gssFail(minor_status, GSS_S_UNAVAILABLE)
}

public func gsskrb5_register_acceptor_identity(_ identity: UnsafePointer<CChar>) -> OM_uint32 {
    _ = identity
    return gssMajor(GSS_S_UNAVAILABLE)
}

public func krb5_gss_register_acceptor_identity(_ identity: UnsafePointer<CChar>) -> OM_uint32 {
    gsskrb5_register_acceptor_identity(identity)
}
