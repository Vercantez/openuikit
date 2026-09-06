/// RFC 2744 / Heimdal `gssapi.h` macros imported by the iPhoneOS 26.1 overlay.
/// Values match the public C headers Apple GSS is derived from (Heimdal).

public var GSS_S_COMPLETE: Int32 { 0 }

public var GSS_C_CALLING_ERROR_OFFSET: Int32 { 24 }
public var GSS_C_ROUTINE_ERROR_OFFSET: Int32 { 16 }
public var GSS_C_SUPPLEMENTARY_OFFSET: Int32 { 0 }
public var GSS_C_CALLING_ERROR_MASK: UInt { 0o377 }
public var GSS_C_ROUTINE_ERROR_MASK: UInt { 0o377 }
public var GSS_C_SUPPLEMENTARY_MASK: UInt { 0o177777 }

public var GSS_S_CALL_INACCESSIBLE_READ: UInt { 1 << 24 }
public var GSS_S_CALL_INACCESSIBLE_WRITE: UInt { 2 << 24 }
public var GSS_S_CALL_BAD_STRUCTURE: UInt { 3 << 24 }

public var GSS_S_BAD_MECH: UInt { 1 << 16 }
public var GSS_S_BAD_NAME: UInt { 2 << 16 }
public var GSS_S_BAD_NAMETYPE: UInt { 3 << 16 }
public var GSS_S_BAD_BINDINGS: UInt { 4 << 16 }
public var GSS_S_BAD_STATUS: UInt { 5 << 16 }
public var GSS_S_BAD_SIG: UInt { 6 << 16 }
public var GSS_S_BAD_MIC: UInt { GSS_S_BAD_SIG }
public var GSS_S_NO_CRED: UInt { 7 << 16 }
public var GSS_S_NO_CONTEXT: UInt { 8 << 16 }
public var GSS_S_DEFECTIVE_TOKEN: UInt { 9 << 16 }
public var GSS_S_DEFECTIVE_CREDENTIAL: UInt { 10 << 16 }
public var GSS_S_CREDENTIALS_EXPIRED: UInt { 11 << 16 }
public var GSS_S_CONTEXT_EXPIRED: UInt { 12 << 16 }
public var GSS_S_FAILURE: UInt { 13 << 16 }
public var GSS_S_BAD_QOP: UInt { 14 << 16 }
public var GSS_S_UNAUTHORIZED: UInt { 15 << 16 }
public var GSS_S_UNAVAILABLE: UInt { 16 << 16 }
public var GSS_S_DUPLICATE_ELEMENT: UInt { 17 << 16 }
public var GSS_S_NAME_NOT_MN: UInt { 18 << 16 }
public var GSS_S_BAD_MECH_ATTR: UInt { 19 << 16 }
public var GSS_S_CRED_UNAVAIL: UInt { GSS_S_FAILURE }

public var GSS_C_DELEG_FLAG: Int32 { 1 }
public var GSS_C_MUTUAL_FLAG: Int32 { 2 }
public var GSS_C_REPLAY_FLAG: Int32 { 4 }
public var GSS_C_SEQUENCE_FLAG: Int32 { 8 }
public var GSS_C_CONF_FLAG: Int32 { 16 }
public var GSS_C_INTEG_FLAG: Int32 { 32 }
public var GSS_C_ANON_FLAG: Int32 { 64 }
public var GSS_C_PROT_READY_FLAG: Int32 { 128 }
public var GSS_C_TRANS_FLAG: Int32 { 256 }
public var GSS_C_DCE_STYLE: Int32 { 4096 }
public var GSS_C_IDENTIFY_FLAG: Int32 { 8192 }
public var GSS_C_EXTENDED_ERROR_FLAG: Int32 { 16384 }
public var GSS_C_DELEG_POLICY_FLAG: Int32 { 32768 }

public var GSS_C_BOTH: Int32 { 0 }
public var GSS_C_INITIATE: Int32 { 1 }
public var GSS_C_ACCEPT: Int32 { 2 }

public var GSS_C_GSS_CODE: Int32 { 1 }
public var GSS_C_MECH_CODE: Int32 { 2 }

public var GSS_C_AF_UNSPEC: Int32 { 0 }
public var GSS_C_AF_LOCAL: Int32 { 1 }
public var GSS_C_AF_INET: Int32 { 2 }
public var GSS_C_AF_IMPLINK: Int32 { 3 }
public var GSS_C_AF_PUP: Int32 { 4 }
public var GSS_C_AF_CHAOS: Int32 { 5 }
public var GSS_C_AF_NS: Int32 { 6 }
public var GSS_C_AF_NBS: Int32 { 7 }
public var GSS_C_AF_ECMA: Int32 { 8 }
public var GSS_C_AF_DATAKIT: Int32 { 9 }
public var GSS_C_AF_CCITT: Int32 { 10 }
public var GSS_C_AF_SNA: Int32 { 11 }
public var GSS_C_AF_DECnet: Int32 { 12 }
public var GSS_C_AF_DLI: Int32 { 13 }
public var GSS_C_AF_LAT: Int32 { 14 }
public var GSS_C_AF_HYLINK: Int32 { 15 }
public var GSS_C_AF_APPLETALK: Int32 { 16 }
public var GSS_C_AF_BSC: Int32 { 17 }
public var GSS_C_AF_DSS: Int32 { 18 }
public var GSS_C_AF_OSI: Int32 { 19 }
public var GSS_C_AF_X25: Int32 { 21 }
public var GSS_C_AF_INET6: Int32 { 24 }
public var GSS_C_AF_NULLADDR: Int32 { 255 }

public var GSS_C_QOP_DEFAULT: Int32 { 0 }
public var GSS_KRB5_CONF_C_QOP_DES: Int32 { 0x0100 }
public var GSS_KRB5_CONF_C_QOP_DES3_KD: Int32 { 0x0200 }

public var GSS_C_INDEFINITE: UInt { 0xffff_ffff }

public var GSS_IOV_BUFFER_TYPE_EMPTY: Int32 { 0 }
public var GSS_IOV_BUFFER_TYPE_DATA: Int32 { 1 }
public var GSS_IOV_BUFFER_TYPE_HEADER: Int32 { 2 }
public var GSS_IOV_BUFFER_TYPE_MECH_PARAMS: Int32 { 3 }
public var GSS_IOV_BUFFER_TYPE_TRAILER: Int32 { 7 }
public var GSS_IOV_BUFFER_TYPE_PADDING: Int32 { 9 }
public var GSS_IOV_BUFFER_TYPE_STREAM: Int32 { 10 }
public var GSS_IOV_BUFFER_TYPE_SIGN_ONLY: Int32 { 11 }
public var GSS_IOV_BUFFER_TYPE_FLAG_MASK: UInt32 { 0xffff_0000 }
public var GSS_IOV_BUFFER_FLAG_ALLOCATE: Int32 { 0x0001_0000 }
public var GSS_IOV_BUFFER_FLAG_ALLOCATED: Int32 { 0x0002_0000 }
public var GSS_IOV_BUFFER_TYPE_FLAG_ALLOCATE: Int32 { GSS_IOV_BUFFER_FLAG_ALLOCATE }
public var GSS_IOV_BUFFER_TYPE_FLAG_ALLOCATED: Int32 { GSS_IOV_BUFFER_FLAG_ALLOCATED }

public var GSS_C_OPTION_MASK: Int32 { 0xffff }
public var GSS_C_CRED_NO_UI: Int32 { 0x1_0000 }
public var GSS_C_PRF_KEY_FULL: Int32 { 0 }
public var GSS_C_PRF_KEY_PARTIAL: Int32 { 1 }

public var kGSSICPassword: String { "kGSSICPassword" }
public var kGSSICCertificate: String { "kGSSICCertificate" }
public var kGSSICVerifyCredential: String { "kGSSICVerifyCredential" }
public var kGSSCredentialUsage: String { "kGSSCredentialUsage" }
public var kGSS_C_INITIATE: String { "kGSS_C_INITIATE" }
public var kGSS_C_ACCEPT: String { "kGSS_C_ACCEPT" }
public var kGSS_C_BOTH: String { "kGSS_C_BOTH" }
public var kGSSICLKDCHostname: String { "kGSSICLKDCHostname" }
public var kGSSICKerberosCacheName: String { "kGSSICKerberosCacheName" }
public var kGSSICSiteName: String { "kGSSICSiteName" }
public var kGSSICAppIdentifierACL: String { "kGSSICAppIdentifierACL" }
public var kGSSICVerifyCredentialAcceptorName: String { "kGSSICVerifyCredentialAcceptorName" }
public var kGSSICCreateNewCredential: String { "kGSSICCreateNewCredential" }
public var kGSSICAppleSourceApp: String { "kGSSICAppleSourceApp" }
public var kGSSICAppleSourceAppAuditToken: String { "kGSSICAppleSourceAppAuditToken" }
public var kGSSICAppleSourceAppPID: String { "kGSSICAppleSourceAppPID" }
public var kGSSICAppleSourceAppSigningIdentity: String { "kGSSICAppleSourceAppSigningIdentity" }
public var kGSSICAuthenticationContext: String { "kGSSICAuthenticationContext" }
public var kGSSChangePasswordOldPassword: String { "kGSSChangePasswordOldPassword" }
public var kGSSChangePasswordNewPassword: String { "kGSSChangePasswordNewPassword" }
