import CoreFoundation

public func GSSCreateError(
    _ mech: gss_const_OID,
    _ major_status: OM_uint32,
    _ minor_status: OM_uint32
) -> Unmanaged<CFError>? {
    _ = mech
    _ = minor_status
    guard let error = CFErrorCreate(
        kCFAllocatorDefault,
        GSSModuleInfo.errorDomainAsCFString,
        CFIndex(major_status),
        nil
    ) else {
        return nil
    }
    return Unmanaged.passRetained(error)
}

public func gss_display_status(
    _ minor_status: UnsafeMutablePointer<OM_uint32>,
    _ status_value: OM_uint32,
    _ status_type: Int32,
    _ mech_type: gss_OID?,
    _ message_content: UnsafeMutablePointer<OM_uint32>,
    _ status_string: gss_buffer_t
) -> OM_uint32 {
    _ = mech_type
    status_string.pointee.length = 0
    status_string.pointee.value = nil
    if message_content.pointee != 0 {
        message_content.pointee = 0
        return gssComplete(minor_status)
    }
    let text: String
    if status_type == GSS_C_GSS_CODE {
        text = gssDisplayGSSCode(status_value)
    } else if status_type == GSS_C_MECH_CODE {
        text = "unknown mechanism-specific error \(status_value)"
    } else {
        return gssFail(minor_status, GSS_S_BAD_STATUS, minor: GSSLinuxMinor.invalidArgument)
    }
    message_content.pointee = 0
    if gssFillBuffer(status_string, bytes: Array(text.utf8)) != 0 {
        return gssFail(minor_status, GSS_S_FAILURE, minor: GSSLinuxMinor.noMemory)
    }
    return gssComplete(minor_status)
}

func gssDisplayGSSCode(_ status: OM_uint32) -> String {
    if status == 0 {
        return "The routine completed successfully"
    }
    let calling = (UInt(status) >> UInt(GSS_C_CALLING_ERROR_OFFSET)) & GSS_C_CALLING_ERROR_MASK
    let routine = (UInt(status) >> UInt(GSS_C_ROUTINE_ERROR_OFFSET)) & GSS_C_ROUTINE_ERROR_MASK
    if calling != 0 {
        switch calling {
        case 1: return "A required input parameter could not be read"
        case 2: return "A required output parameter could not be written"
        case 3: return "A parameter was malformed"
        default: return "A calling error occurred"
        }
    }
    switch routine {
    case 1: return "An unsupported mechanism was requested"
    case 2: return "An invalid name was supplied"
    case 3: return "A supplied name was of an unsupported type"
    case 4: return "Incorrect channel bindings were supplied"
    case 5: return "An invalid status code was supplied"
    case 6: return "A token had an invalid MIC"
    case 7: return "No credentials were supplied, or the credentials were unavailable or inaccessible"
    case 8: return "No context has been established"
    case 9: return "A token was invalid"
    case 10: return "A credential was invalid"
    case 11: return "The referenced credentials have expired"
    case 12: return "The context has expired"
    case 13: return "Miscellaneous failure"
    case 14: return "The quality-of-protection requested could not be provided"
    case 15: return "The operation is forbidden by local security policy"
    case 16: return "The operation or option is unavailable"
    case 17: return "The requested credential element already exists"
    case 18: return "The provided name was not a mechanism name"
    case 19: return "An unsupported mechanism attribute was requested"
    default: return "A GSS-API error occurred"
    }
}
