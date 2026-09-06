public func gss_indicate_mechs(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ mech_set: UnsafeMutablePointer<gss_OID_set?>
) -> OM_uint32 {
    return gss_create_empty_oid_set(minor_status, mech_set)
}

public func gss_indicate_mechs_by_attrs(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ desired_mech_attrs: gss_const_OID_set?,
    _ except_mech_attrs: gss_const_OID_set?,
    _ critical_mech_attrs: gss_const_OID_set?,
    _ mechs: UnsafeMutablePointer<gss_OID_set?>
) -> OM_uint32 {
    _ = desired_mech_attrs
    _ = except_mech_attrs
    _ = critical_mech_attrs
    return gss_create_empty_oid_set(minor_status, mechs)
}

public func gss_inquire_attrs_for_mech(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ mech: gss_const_OID,
    _ mech_attr: UnsafeMutablePointer<gss_OID_set?>?,
    _ known_mech_attrs: UnsafeMutablePointer<gss_OID_set?>?
) -> OM_uint32 {
    _ = mech
    mech_attr?.pointee = nil
    known_mech_attrs?.pointee = nil
    return gssFail(minor_status, GSS_S_BAD_MECH)
}

public func gss_display_mech_attr(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ mech_attr: gss_const_OID,
    _ name: gss_buffer_t?,
    _ short_desc: gss_buffer_t?,
    _ long_desc: gss_buffer_t?
) -> OM_uint32 {
    _ = mech_attr
    if let name {
        name.pointee.length = 0
        name.pointee.value = nil
    }
    if let short_desc {
        short_desc.pointee.length = 0
        short_desc.pointee.value = nil
    }
    if let long_desc {
        long_desc.pointee.length = 0
        long_desc.pointee.value = nil
    }
    return gssFail(minor_status, GSS_S_BAD_MECH_ATTR)
}

public func gss_inquire_names_for_mech(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ mechanism: gss_const_OID,
    _ name_types: UnsafeMutablePointer<gss_OID_set?>
) -> OM_uint32 {
    _ = mechanism
    name_types.pointee = nil
    return gssFail(minor_status, GSS_S_BAD_MECH)
}

public func gss_inquire_saslname_for_mech(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ desired_mech: gss_OID,
    _ sasl_mech_name: gss_buffer_t?,
    _ mech_name: gss_buffer_t?,
    _ mech_description: gss_buffer_t?
) -> OM_uint32 {
    _ = desired_mech
    if let sasl_mech_name {
        sasl_mech_name.pointee.length = 0
        sasl_mech_name.pointee.value = nil
    }
    if let mech_name {
        mech_name.pointee.length = 0
        mech_name.pointee.value = nil
    }
    if let mech_description {
        mech_description.pointee.length = 0
        mech_description.pointee.value = nil
    }
    return gssFail(minor_status, GSS_S_BAD_MECH)
}

public func gss_inquire_mech_for_saslname(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ sasl_mech_name: gss_buffer_t?,
    _ mech_type: UnsafeMutablePointer<gss_OID?>
) -> OM_uint32 {
    _ = sasl_mech_name
    mech_type.pointee = nil
    return gssFail(minor_status, GSS_S_BAD_MECH)
}

public func gss_init_sec_context(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ initiator_cred_handle: gss_cred_id_t?,
    _ context_handle: UnsafeMutablePointer<gss_ctx_id_t?>,
    _ target_name: gss_name_t,
    _ input_mech_type: gss_OID?,
    _ req_flags: OM_uint32,
    _ time_req: OM_uint32,
    _ input_chan_bindings: gss_channel_bindings_t?,
    _ input_token: gss_buffer_t?,
    _ actual_mech_type: UnsafeMutablePointer<gss_OID?>?,
    _ output_token: gss_buffer_t,
    _ ret_flags: UnsafeMutablePointer<OM_uint32>?,
    _ time_rec: UnsafeMutablePointer<OM_uint32>?
) -> OM_uint32 {
    _ = initiator_cred_handle
    _ = target_name
    _ = input_mech_type
    _ = req_flags
    _ = time_req
    _ = input_chan_bindings
    _ = input_token
    context_handle.pointee = nil
    actual_mech_type?.pointee = nil
    output_token.pointee.length = 0
    output_token.pointee.value = nil
    ret_flags?.pointee = 0
    time_rec?.pointee = 0
    return gssFail(minor_status, GSS_S_UNAVAILABLE)
}

public func gss_accept_sec_context(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ context_handle: UnsafeMutablePointer<gss_ctx_id_t?>,
    _ acceptor_cred_handle: gss_cred_id_t?,
    _ input_token: gss_buffer_t?,
    _ input_chan_bindings: gss_channel_bindings_t?,
    _ src_name: UnsafeMutablePointer<gss_name_t?>?,
    _ mech_type: UnsafeMutablePointer<gss_OID?>?,
    _ output_token: gss_buffer_t,
    _ ret_flags: UnsafeMutablePointer<OM_uint32>?,
    _ time_rec: UnsafeMutablePointer<OM_uint32>?,
    _ delegated_cred_handle: UnsafeMutablePointer<gss_cred_id_t?>?
) -> OM_uint32 {
    _ = acceptor_cred_handle
    _ = input_token
    _ = input_chan_bindings
    context_handle.pointee = nil
    src_name?.pointee = nil
    mech_type?.pointee = nil
    output_token.pointee.length = 0
    output_token.pointee.value = nil
    ret_flags?.pointee = 0
    time_rec?.pointee = 0
    delegated_cred_handle?.pointee = nil
    return gssFail(minor_status, GSS_S_UNAVAILABLE)
}

public func gss_delete_sec_context(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ context_handle: UnsafeMutablePointer<gss_ctx_id_t?>,
    _ output_token: gss_buffer_t?
) -> OM_uint32 {
    if let output_token {
        output_token.pointee.length = 0
        output_token.pointee.value = nil
    }
    if context_handle.pointee == nil {
        return gssFail(minor_status, GSS_S_NO_CONTEXT)
    }
    context_handle.pointee = nil
    return gssFail(minor_status, GSS_S_NO_CONTEXT)
}

public func gss_process_context_token(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ context_handle: gss_ctx_id_t,
    _ token_buffer: gss_buffer_t
) -> OM_uint32 {
    _ = context_handle
    _ = token_buffer
    return gssFail(minor_status, GSS_S_NO_CONTEXT)
}

public func gss_context_time(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ context_handle: gss_ctx_id_t,
    _ time_rec: UnsafeMutablePointer<OM_uint32>
) -> OM_uint32 {
    _ = context_handle
    time_rec.pointee = 0
    return gssFail(minor_status, GSS_S_NO_CONTEXT)
}

public func gss_inquire_context(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ context_handle: gss_ctx_id_t,
    _ src_name: UnsafeMutablePointer<gss_name_t?>?,
    _ targ_name: UnsafeMutablePointer<gss_name_t?>?,
    _ lifetime_rec: UnsafeMutablePointer<OM_uint32>?,
    _ mech_type: UnsafeMutablePointer<gss_OID?>?,
    _ ctx_flags: UnsafeMutablePointer<OM_uint32>?,
    _ locally_initiated: UnsafeMutablePointer<Int32>?,
    _ xopen: UnsafeMutablePointer<Int32>?
) -> OM_uint32 {
    _ = context_handle
    src_name?.pointee = nil
    targ_name?.pointee = nil
    lifetime_rec?.pointee = 0
    mech_type?.pointee = nil
    ctx_flags?.pointee = 0
    locally_initiated?.pointee = 0
    xopen?.pointee = 0
    return gssFail(minor_status, GSS_S_NO_CONTEXT)
}

public func gss_inquire_sec_context_by_oid(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ context_handle: gss_ctx_id_t,
    _ desired_object: gss_OID,
    _ data_set: UnsafeMutablePointer<gss_buffer_set_t>?
) -> OM_uint32 {
    _ = context_handle
    _ = desired_object
    _ = data_set
    return gssFail(minor_status, GSS_S_NO_CONTEXT)
}

public func gss_export_sec_context(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ context_handle: UnsafeMutablePointer<gss_ctx_id_t?>,
    _ interprocess_token: gss_buffer_t?
) -> OM_uint32 {
    if let interprocess_token {
        interprocess_token.pointee.length = 0
        interprocess_token.pointee.value = nil
    }
    context_handle.pointee = nil
    return gssFail(minor_status, GSS_S_UNAVAILABLE)
}

public func gss_import_sec_context(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ interprocess_token: gss_buffer_t,
    _ context_handle: UnsafeMutablePointer<gss_ctx_id_t?>
) -> OM_uint32 {
    _ = interprocess_token
    context_handle.pointee = nil
    return gssFail(minor_status, GSS_S_UNAVAILABLE)
}

public func gss_get_mic(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ context_handle: gss_ctx_id_t,
    _ qop_req: gss_qop_t,
    _ message_buffer: gss_buffer_t,
    _ message_token: gss_buffer_t
) -> OM_uint32 {
    _ = context_handle
    _ = qop_req
    _ = message_buffer
    message_token.pointee.length = 0
    message_token.pointee.value = nil
    return gssFail(minor_status, GSS_S_NO_CONTEXT)
}

public func gss_verify_mic(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ context_handle: gss_ctx_id_t,
    _ message_buffer: gss_buffer_t,
    _ token_buffer: gss_buffer_t,
    _ qop_state: UnsafeMutablePointer<gss_qop_t>?
) -> OM_uint32 {
    _ = context_handle
    _ = message_buffer
    _ = token_buffer
    qop_state?.pointee = 0
    return gssFail(minor_status, GSS_S_NO_CONTEXT)
}

public func gss_wrap(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ context_handle: gss_ctx_id_t,
    _ conf_req_flag: Int32,
    _ qop_req: gss_qop_t,
    _ input_message_buffer: gss_buffer_t,
    _ conf_state: UnsafeMutablePointer<Int32>?,
    _ output_message_buffer: gss_buffer_t
) -> OM_uint32 {
    _ = context_handle
    _ = conf_req_flag
    _ = qop_req
    _ = input_message_buffer
    conf_state?.pointee = 0
    output_message_buffer.pointee.length = 0
    output_message_buffer.pointee.value = nil
    return gssFail(minor_status, GSS_S_NO_CONTEXT)
}

public func gss_unwrap(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ context_handle: gss_ctx_id_t,
    _ input_message_buffer: gss_buffer_t,
    _ output_message_buffer: gss_buffer_t,
    _ conf_state: UnsafeMutablePointer<Int32>?,
    _ qop_state: UnsafeMutablePointer<gss_qop_t>?
) -> OM_uint32 {
    _ = context_handle
    _ = input_message_buffer
    output_message_buffer.pointee.length = 0
    output_message_buffer.pointee.value = nil
    conf_state?.pointee = 0
    qop_state?.pointee = 0
    return gssFail(minor_status, GSS_S_NO_CONTEXT)
}

public func gss_wrap_size_limit(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ context_handle: gss_ctx_id_t,
    _ conf_req_flag: Int32,
    _ qop_req: gss_qop_t,
    _ req_output_size: OM_uint32,
    _ max_input_size: UnsafeMutablePointer<OM_uint32>
) -> OM_uint32 {
    _ = context_handle
    _ = conf_req_flag
    _ = qop_req
    _ = req_output_size
    max_input_size.pointee = 0
    return gssFail(minor_status, GSS_S_NO_CONTEXT)
}

public func gss_pseudo_random(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ context: gss_ctx_id_t,
    _ prf_key: Int32,
    _ prf_in: gss_buffer_t,
    _ desired_output_len: Int,
    _ prf_out: gss_buffer_t
) -> OM_uint32 {
    _ = context
    _ = prf_key
    _ = prf_in
    _ = desired_output_len
    prf_out.pointee.length = 0
    prf_out.pointee.value = nil
    return gssFail(minor_status, GSS_S_NO_CONTEXT)
}

public func gss_set_sec_context_option(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ context_handle: UnsafeMutablePointer<gss_ctx_id_t>?,
    _ object: gss_OID,
    _ value: gss_buffer_t?
) -> OM_uint32 {
    _ = context_handle
    _ = object
    _ = value
    return gssFail(minor_status, GSS_S_UNAVAILABLE)
}
