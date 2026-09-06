/// Overlay scalar, handle, and descriptor types from the iPhoneOS 26.1
/// `gssapi.h` Clang module.

public typealias OM_uint32 = UInt32
public typealias OM_uint64 = UInt64
public typealias gss_uint32 = UInt32
public typealias gss_qop_t = OM_uint32
public typealias gss_cred_usage_t = Int32

public typealias gss_name_t = OpaquePointer
public typealias gss_const_name_t = OpaquePointer
public typealias gss_cred_id_t = OpaquePointer
public typealias gss_const_cred_id_t = OpaquePointer
public typealias gss_ctx_id_t = OpaquePointer
public typealias gss_auth_identity_t = OpaquePointer

public struct gss_OID_desc_struct {
    public var length: OM_uint32
    public var elements: UnsafeMutableRawPointer!

    public init() {
        self.length = 0
        self.elements = nil
    }

    public init(length: OM_uint32, elements: UnsafeMutableRawPointer!) {
        self.length = length
        self.elements = elements
    }
}

public typealias gss_OID_desc = gss_OID_desc_struct
public typealias gss_OID = UnsafeMutablePointer<gss_OID_desc_struct>
public typealias gss_const_OID = UnsafePointer<gss_OID_desc>

public struct gss_OID_set_desc_struct {
    public var count: Int
    public var elements: gss_OID!

    public init() {
        self.count = 0
        self.elements = nil
    }

    public init(count: Int, elements: gss_OID!) {
        self.count = count
        self.elements = elements
    }
}

public typealias gss_OID_set_desc = gss_OID_set_desc_struct
public typealias gss_OID_set = UnsafeMutablePointer<gss_OID_set_desc_struct>
public typealias gss_const_OID_set = UnsafePointer<gss_OID_set_desc>

public struct gss_buffer_desc_struct {
    public var length: Int
    public var value: UnsafeMutableRawPointer!

    public init() {
        self.length = 0
        self.value = nil
    }

    public init(length: Int, value: UnsafeMutableRawPointer!) {
        self.length = length
        self.value = value
    }
}

public typealias gss_buffer_desc = gss_buffer_desc_struct
public typealias gss_buffer_t = UnsafeMutablePointer<gss_buffer_desc_struct>
public typealias gss_const_buffer_t = UnsafePointer<gss_buffer_desc>
public typealias gss_status_id_t = UnsafeMutablePointer<OM_uint32>

public struct gss_buffer_set_desc_struct {
    public var count: Int
    public var elements: UnsafeMutablePointer<gss_buffer_desc>!

    public init() {
        self.count = 0
        self.elements = nil
    }

    public init(count: Int, elements: UnsafeMutablePointer<gss_buffer_desc>!) {
        self.count = count
        self.elements = elements
    }
}

public typealias gss_buffer_set_desc = gss_buffer_set_desc_struct
public typealias gss_buffer_set_t = UnsafeMutablePointer<gss_buffer_set_desc_struct>

public struct gss_channel_bindings_struct {
    public var initiator_addrtype: OM_uint32
    public var initiator_address: gss_buffer_desc
    public var acceptor_addrtype: OM_uint32
    public var acceptor_address: gss_buffer_desc
    public var application_data: gss_buffer_desc

    public init() {
        self.initiator_addrtype = 0
        self.initiator_address = gss_buffer_desc()
        self.acceptor_addrtype = 0
        self.acceptor_address = gss_buffer_desc()
        self.application_data = gss_buffer_desc()
    }

    public init(
        initiator_addrtype: OM_uint32,
        initiator_address: gss_buffer_desc,
        acceptor_addrtype: OM_uint32,
        acceptor_address: gss_buffer_desc,
        application_data: gss_buffer_desc
    ) {
        self.initiator_addrtype = initiator_addrtype
        self.initiator_address = initiator_address
        self.acceptor_addrtype = acceptor_addrtype
        self.acceptor_address = acceptor_address
        self.application_data = application_data
    }
}

public typealias gss_channel_bindings_t = UnsafeMutablePointer<gss_channel_bindings_struct>
public typealias gss_const_channel_bindings_t = UnsafePointer<gss_channel_bindings_struct>

public struct gss_iov_buffer_desc_struct {
    public var type: OM_uint32
    public var buffer: gss_buffer_desc

    public init() {
        self.type = 0
        self.buffer = gss_buffer_desc()
    }

    public init(type: OM_uint32, buffer: gss_buffer_desc) {
        self.type = type
        self.buffer = buffer
    }
}

public typealias gss_iov_buffer_desc = gss_iov_buffer_desc_struct
public typealias gss_iov_buffer_t = UnsafeMutablePointer<gss_iov_buffer_desc_struct>
