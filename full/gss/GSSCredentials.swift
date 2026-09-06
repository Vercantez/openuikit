import CoreFoundation

public func gss_acquire_cred(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ desired_name: gss_name_t?,
    _ time_req: OM_uint32,
    _ desired_mechs: gss_OID_set?,
    _ cred_usage: gss_cred_usage_t,
    _ output_cred_handle: UnsafeMutablePointer<gss_cred_id_t?>,
    _ actual_mechs: UnsafeMutablePointer<gss_OID_set?>?,
    _ time_rec: UnsafeMutablePointer<OM_uint32>?
) -> OM_uint32 {
    _ = desired_name
    _ = time_req
    _ = desired_mechs
    _ = cred_usage
    output_cred_handle.pointee = nil
    actual_mechs?.pointee = nil
    time_rec?.pointee = 0
    return gssFail(minor_status, GSS_S_NO_CRED)
}

public func gss_acquire_cred_with_password(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ desired_name: gss_name_t,
    _ password: gss_buffer_t,
    _ time_req: OM_uint32,
    _ desired_mechs: gss_OID_set?,
    _ cred_usage: gss_cred_usage_t,
    _ output_cred_handle: UnsafeMutablePointer<gss_cred_id_t?>,
    _ actual_mechs: UnsafeMutablePointer<gss_OID_set?>?,
    _ time_rec: UnsafeMutablePointer<OM_uint32>?
) -> OM_uint32 {
    _ = desired_name
    _ = password
    _ = time_req
    _ = desired_mechs
    _ = cred_usage
    output_cred_handle.pointee = nil
    actual_mechs?.pointee = nil
    time_rec?.pointee = 0
    return gssFail(minor_status, GSS_S_NO_CRED)
}

public func gss_add_cred(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ input_cred_handle: gss_cred_id_t?,
    _ desired_name: gss_name_t?,
    _ desired_mech: gss_OID?,
    _ cred_usage: gss_cred_usage_t,
    _ initiator_time_req: OM_uint32,
    _ acceptor_time_req: OM_uint32,
    _ output_cred_handle: UnsafeMutablePointer<gss_cred_id_t?>,
    _ actual_mechs: UnsafeMutablePointer<gss_OID_set?>?,
    _ initiator_time_rec: UnsafeMutablePointer<OM_uint32>?,
    _ acceptor_time_rec: UnsafeMutablePointer<OM_uint32>?
) -> OM_uint32 {
    _ = input_cred_handle
    _ = desired_name
    _ = desired_mech
    _ = cred_usage
    _ = initiator_time_req
    _ = acceptor_time_req
    output_cred_handle.pointee = nil
    actual_mechs?.pointee = nil
    initiator_time_rec?.pointee = 0
    acceptor_time_rec?.pointee = 0
    return gssFail(minor_status, GSS_S_NO_CRED)
}

public func gss_release_cred(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ cred_handle: UnsafeMutablePointer<gss_cred_id_t?>
) -> OM_uint32 {
    cred_handle.pointee = nil
    return gssComplete(minor_status)
}

public func gss_destroy_cred(
    _ min_stat: UnsafeMutablePointer<OM_uint32>,
    _ cred_handle: UnsafeMutablePointer<gss_cred_id_t?>
) -> OM_uint32 {
    cred_handle.pointee = nil
    return gssComplete(min_stat)
}

public func gss_inquire_cred(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ cred_handle: gss_cred_id_t?,
    _ name_ret: UnsafeMutablePointer<gss_name_t?>?,
    _ lifetime: UnsafeMutablePointer<OM_uint32>?,
    _ cred_usage: UnsafeMutablePointer<gss_cred_usage_t>?,
    _ mechanisms: UnsafeMutablePointer<gss_OID_set?>?
) -> OM_uint32 {
    name_ret?.pointee = nil
    lifetime?.pointee = 0
    cred_usage?.pointee = 0
    mechanisms?.pointee = nil
    _ = cred_handle
    return gssFail(minor_status, GSS_S_NO_CRED)
}

public func gss_inquire_cred_by_mech(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ cred_handle: gss_cred_id_t?,
    _ mech_type: gss_OID,
    _ cred_name: UnsafeMutablePointer<gss_name_t?>?,
    _ initiator_lifetime: UnsafeMutablePointer<OM_uint32>?,
    _ acceptor_lifetime: UnsafeMutablePointer<OM_uint32>?,
    _ cred_usage: UnsafeMutablePointer<gss_cred_usage_t>?
) -> OM_uint32 {
    _ = cred_handle
    _ = mech_type
    cred_name?.pointee = nil
    initiator_lifetime?.pointee = 0
    acceptor_lifetime?.pointee = 0
    cred_usage?.pointee = 0
    return gssFail(minor_status, GSS_S_NO_CRED)
}

public func gss_inquire_cred_by_oid(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ cred_handle: gss_cred_id_t,
    _ desired_object: gss_OID,
    _ data_set: UnsafeMutablePointer<gss_buffer_set_t?>
) -> OM_uint32 {
    _ = cred_handle
    _ = desired_object
    data_set.pointee = nil
    return gssFail(minor_status, GSS_S_NO_CRED)
}

public func gss_export_cred(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ cred_handle: gss_cred_id_t,
    _ token: gss_buffer_t
) -> OM_uint32 {
    _ = cred_handle
    token.pointee.length = 0
    token.pointee.value = nil
    return gssFail(minor_status, GSS_S_NO_CRED)
}

public func gss_import_cred(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ token: gss_buffer_t,
    _ cred_handle: UnsafeMutablePointer<gss_cred_id_t?>
) -> OM_uint32 {
    _ = token
    cred_handle.pointee = nil
    return gssFail(minor_status, GSS_S_DEFECTIVE_CREDENTIAL)
}

public func gss_set_cred_option(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ cred_handle: UnsafeMutablePointer<gss_cred_id_t?>?,
    _ object: gss_OID,
    _ value: gss_buffer_t?
) -> OM_uint32 {
    _ = cred_handle
    _ = object
    _ = value
    return gssFail(minor_status, GSS_S_UNAVAILABLE)
}

public func gss_iter_creds(
    _ min_stat: UnsafeMutablePointer<OM_uint32>,
    _ flags: OM_uint32,
    _ mech: gss_const_OID?,
    _ useriter: @escaping (gss_OID?, gss_cred_id_t?) -> Void
) -> OM_uint32 {
    _ = flags
    _ = mech
    _ = useriter
    return gssComplete(min_stat)
}

public func gss_iter_creds_f(
    _ min_stat: UnsafeMutablePointer<OM_uint32>,
    _ flags: OM_uint32,
    _ mech: gss_const_OID?,
    _ userctx: UnsafeMutableRawPointer?,
    _ useriter: (UnsafeMutableRawPointer?, gss_OID?, gss_cred_id_t?) -> Void
) -> OM_uint32 {
    _ = flags
    _ = mech
    _ = userctx
    _ = useriter
    return gssComplete(min_stat)
}

public func GSSCreateCredentialFromUUID(_ uuid: CFUUID) -> gss_cred_id_t? {
    _ = uuid
    return nil
}

public func GSSCredentialCopyName(_ cred: gss_cred_id_t) -> gss_name_t? {
    _ = cred
    return nil
}

public func GSSCredentialCopyUUID(_ credential: gss_cred_id_t) -> Unmanaged<CFUUID>? {
    _ = credential
    return nil
}

public func GSSCredentialGetLifetime(_ cred: gss_cred_id_t) -> OM_uint32 {
    _ = cred
    return 0
}
