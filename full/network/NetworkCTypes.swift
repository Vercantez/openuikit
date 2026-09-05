import Foundation

// MARK: - Host lookalikes for Darwin/Security/CoreFoundation imported names
//
// Isolated host compile may import Foundation only. These aliases match the
// C-imported identities used by Network.framework's overlay. They are not a
// claim that Security.framework or CoreFoundation are linked here.
public typealias OSStatus = Int32
public typealias DNSServiceErrorType = Int32
public typealias CFString = NSString
public typealias CFError = NSError
public typealias dispatch_queue_t = DispatchQueue
public typealias dispatch_data_t = DispatchData

/// Opaque Security `sec_protocol_options` stand-in. Linux stores option
/// bytes locally; it does not perform a TLS handshake.
public final class sec_protocol_options: NSObject, @unchecked Sendable {
    public var encodedData: Data
    public override init() {
        encodedData = Data()
        super.init()
    }
    public init(data: Data) {
        encodedData = data
        super.init()
    }
}
public typealias sec_protocol_options_t = sec_protocol_options
public final class sec_protocol_metadata: NSObject, @unchecked Sendable {
    public var encodedData: Data
    public override init() {
        encodedData = Data()
        super.init()
    }
}
public typealias sec_protocol_metadata_t = sec_protocol_metadata

public let kNWErrorDomainPOSIX: CFString = "kNWErrorDomainPOSIX" as NSString
public let kNWErrorDomainDNS: CFString = "kNWErrorDomainDNS" as NSString
public let kNWErrorDomainTLS: CFString = "kNWErrorDomainTLS" as NSString
public let kNWErrorDomainWiFiAware: CFString = "kNWErrorDomainWiFiAware" as NSString

public var NW_FRAMER_CREATE_FLAGS_DEFAULT: Int32 { 0 }
public var NW_FRAMER_WAKEUP_TIME_FOREVER: UInt64 { ~UInt64(0) }
public var NW_LISTENER_INFINITE_CONNECTION_LIMIT: UInt32 { ~UInt32(0) }
public var NW_QUIC_CONNECTION_DEFAULT_KEEPALIVE: Int32 { 0 }

public enum nw_parameters_attribution_t: UInt8, Sendable {
    case developer = 1
    case user = 2
}

public struct nw_browser_state_t: Hashable, Sendable, RawRepresentable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}

public struct nw_connection_group_state_t: Hashable, Sendable, RawRepresentable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}

public struct nw_connection_state_t: Hashable, Sendable, RawRepresentable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}

public struct nw_data_transfer_report_state_t: Hashable, Sendable, RawRepresentable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}

public struct nw_endpoint_type_t: Hashable, Sendable, RawRepresentable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}

public struct nw_error_domain_t: Hashable, Sendable, RawRepresentable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}

public struct nw_ethernet_channel_state_t: Hashable, Sendable, RawRepresentable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}

public struct nw_framer_start_result_t: Hashable, Sendable, RawRepresentable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}

public struct nw_interface_radio_type_t: Hashable, Sendable, RawRepresentable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}

public struct nw_interface_type_t: Hashable, Sendable, RawRepresentable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}

public struct nw_ip_ecn_flag_t: Hashable, Sendable, RawRepresentable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}

public struct nw_ip_local_address_preference_t: Hashable, Sendable, RawRepresentable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}

public struct nw_ip_version_t: Hashable, Sendable, RawRepresentable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}

public struct nw_link_quality_t: Hashable, Sendable, RawRepresentable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}

public struct nw_listener_state_t: Hashable, Sendable, RawRepresentable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}

public struct nw_multipath_service_t: Hashable, Sendable, RawRepresentable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}

public struct nw_multipath_version_t: Hashable, Sendable, RawRepresentable {
    public var rawValue: Int32
    public init(rawValue: Int32) { self.rawValue = rawValue }
    public init(_ rawValue: Int32) { self.rawValue = rawValue }
}

public struct nw_parameters_expired_dns_behavior_t: Hashable, Sendable, RawRepresentable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}

public struct nw_path_status_t: Hashable, Sendable, RawRepresentable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}

public struct nw_path_unsatisfied_reason_t: Hashable, Sendable, RawRepresentable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}

public struct nw_quic_stream_type_t: Hashable, Sendable, RawRepresentable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}

public struct nw_report_resolution_protocol_t: Hashable, Sendable, RawRepresentable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}

public struct nw_report_resolution_source_t: Hashable, Sendable, RawRepresentable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}

public struct nw_service_class_t: Hashable, Sendable, RawRepresentable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}

public struct nw_txt_record_find_key_t: Hashable, Sendable, RawRepresentable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}

public struct nw_ws_close_code_t: Hashable, Sendable, RawRepresentable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}

public struct nw_ws_opcode_t: Hashable, Sendable, RawRepresentable {
    public var rawValue: Int32
    public init(rawValue: Int32) { self.rawValue = rawValue }
    public init(_ rawValue: Int32) { self.rawValue = rawValue }
}

public struct nw_ws_response_status_t: Hashable, Sendable, RawRepresentable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}

public struct nw_ws_version_t: Hashable, Sendable, RawRepresentable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}

public var nw_browser_state_cancelled: nw_browser_state_t { nw_browser_state_t(rawValue: 3) }
public var nw_browser_state_failed: nw_browser_state_t { nw_browser_state_t(rawValue: 2) }
public var nw_browser_state_invalid: nw_browser_state_t { nw_browser_state_t(rawValue: 0) }
public var nw_browser_state_ready: nw_browser_state_t { nw_browser_state_t(rawValue: 1) }
public var nw_browser_state_waiting: nw_browser_state_t { nw_browser_state_t(rawValue: 4) }

public var nw_connection_group_state_cancelled: nw_connection_group_state_t { nw_connection_group_state_t(rawValue: 4) }
public var nw_connection_group_state_failed: nw_connection_group_state_t { nw_connection_group_state_t(rawValue: 3) }
public var nw_connection_group_state_invalid: nw_connection_group_state_t { nw_connection_group_state_t(rawValue: 0) }
public var nw_connection_group_state_ready: nw_connection_group_state_t { nw_connection_group_state_t(rawValue: 2) }
public var nw_connection_group_state_waiting: nw_connection_group_state_t { nw_connection_group_state_t(rawValue: 1) }

public var nw_connection_state_cancelled: nw_connection_state_t { nw_connection_state_t(rawValue: 5) }
public var nw_connection_state_failed: nw_connection_state_t { nw_connection_state_t(rawValue: 4) }
public var nw_connection_state_invalid: nw_connection_state_t { nw_connection_state_t(rawValue: 0) }
public var nw_connection_state_preparing: nw_connection_state_t { nw_connection_state_t(rawValue: 2) }
public var nw_connection_state_ready: nw_connection_state_t { nw_connection_state_t(rawValue: 3) }
public var nw_connection_state_waiting: nw_connection_state_t { nw_connection_state_t(rawValue: 1) }

public var nw_data_transfer_report_state_collected: nw_data_transfer_report_state_t { nw_data_transfer_report_state_t(rawValue: 2) }
public var nw_data_transfer_report_state_collecting: nw_data_transfer_report_state_t { nw_data_transfer_report_state_t(rawValue: 1) }

public var nw_endpoint_type_address: nw_endpoint_type_t { nw_endpoint_type_t(rawValue: 1) }
public var nw_endpoint_type_bonjour_service: nw_endpoint_type_t { nw_endpoint_type_t(rawValue: 3) }
public var nw_endpoint_type_host: nw_endpoint_type_t { nw_endpoint_type_t(rawValue: 2) }
public var nw_endpoint_type_invalid: nw_endpoint_type_t { nw_endpoint_type_t(rawValue: 0) }
public var nw_endpoint_type_url: nw_endpoint_type_t { nw_endpoint_type_t(rawValue: 4) }

public var nw_error_domain_dns: nw_error_domain_t { nw_error_domain_t(rawValue: 2) }
public var nw_error_domain_invalid: nw_error_domain_t { nw_error_domain_t(rawValue: 0) }
public var nw_error_domain_posix: nw_error_domain_t { nw_error_domain_t(rawValue: 1) }
public var nw_error_domain_tls: nw_error_domain_t { nw_error_domain_t(rawValue: 3) }
public var nw_error_domain_wifi_aware: nw_error_domain_t { nw_error_domain_t(rawValue: 4) }

public var nw_ethernet_channel_state_cancelled: nw_ethernet_channel_state_t { nw_ethernet_channel_state_t(rawValue: 5) }
public var nw_ethernet_channel_state_failed: nw_ethernet_channel_state_t { nw_ethernet_channel_state_t(rawValue: 4) }
public var nw_ethernet_channel_state_invalid: nw_ethernet_channel_state_t { nw_ethernet_channel_state_t(rawValue: 0) }
public var nw_ethernet_channel_state_preparing: nw_ethernet_channel_state_t { nw_ethernet_channel_state_t(rawValue: 2) }
public var nw_ethernet_channel_state_ready: nw_ethernet_channel_state_t { nw_ethernet_channel_state_t(rawValue: 3) }
public var nw_ethernet_channel_state_waiting: nw_ethernet_channel_state_t { nw_ethernet_channel_state_t(rawValue: 1) }

public var nw_framer_start_result_ready: nw_framer_start_result_t { nw_framer_start_result_t(rawValue: 1) }
public var nw_framer_start_result_will_mark_ready: nw_framer_start_result_t { nw_framer_start_result_t(rawValue: 2) }

public var nw_interface_radio_type_cell_cdma: nw_interface_radio_type_t { nw_interface_radio_type_t(rawValue: 135) }
public var nw_interface_radio_type_cell_endc_mmw: nw_interface_radio_type_t { nw_interface_radio_type_t(rawValue: 130) }
public var nw_interface_radio_type_cell_endc_sub6: nw_interface_radio_type_t { nw_interface_radio_type_t(rawValue: 129) }
public var nw_interface_radio_type_cell_evdo: nw_interface_radio_type_t { nw_interface_radio_type_t(rawValue: 136) }
public var nw_interface_radio_type_cell_gsm: nw_interface_radio_type_t { nw_interface_radio_type_t(rawValue: 134) }
public var nw_interface_radio_type_cell_lte: nw_interface_radio_type_t { nw_interface_radio_type_t(rawValue: 128) }
public var nw_interface_radio_type_cell_nr_sa_mmw: nw_interface_radio_type_t { nw_interface_radio_type_t(rawValue: 132) }
public var nw_interface_radio_type_cell_nr_sa_sub6: nw_interface_radio_type_t { nw_interface_radio_type_t(rawValue: 131) }
public var nw_interface_radio_type_cell_wcdma: nw_interface_radio_type_t { nw_interface_radio_type_t(rawValue: 133) }
public var nw_interface_radio_type_unknown: nw_interface_radio_type_t { nw_interface_radio_type_t(rawValue: 0) }
public var nw_interface_radio_type_wifi_a: nw_interface_radio_type_t { nw_interface_radio_type_t(rawValue: 2) }
public var nw_interface_radio_type_wifi_ac: nw_interface_radio_type_t { nw_interface_radio_type_t(rawValue: 5) }
public var nw_interface_radio_type_wifi_ax: nw_interface_radio_type_t { nw_interface_radio_type_t(rawValue: 6) }
public var nw_interface_radio_type_wifi_b: nw_interface_radio_type_t { nw_interface_radio_type_t(rawValue: 1) }
public var nw_interface_radio_type_wifi_g: nw_interface_radio_type_t { nw_interface_radio_type_t(rawValue: 3) }
public var nw_interface_radio_type_wifi_n: nw_interface_radio_type_t { nw_interface_radio_type_t(rawValue: 4) }

public var nw_interface_type_cellular: nw_interface_type_t { nw_interface_type_t(rawValue: 2) }
public var nw_interface_type_loopback: nw_interface_type_t { nw_interface_type_t(rawValue: 4) }
public var nw_interface_type_other: nw_interface_type_t { nw_interface_type_t(rawValue: 0) }
public var nw_interface_type_wifi: nw_interface_type_t { nw_interface_type_t(rawValue: 1) }
public var nw_interface_type_wired: nw_interface_type_t { nw_interface_type_t(rawValue: 3) }

public var nw_ip_ecn_flag_ce: nw_ip_ecn_flag_t { nw_ip_ecn_flag_t(rawValue: 3) }
public var nw_ip_ecn_flag_ect_0: nw_ip_ecn_flag_t { nw_ip_ecn_flag_t(rawValue: 2) }
public var nw_ip_ecn_flag_ect_1: nw_ip_ecn_flag_t { nw_ip_ecn_flag_t(rawValue: 1) }
public var nw_ip_ecn_flag_non_ect: nw_ip_ecn_flag_t { nw_ip_ecn_flag_t(rawValue: 0) }

public var nw_ip_local_address_preference_default: nw_ip_local_address_preference_t { nw_ip_local_address_preference_t(rawValue: 0) }
public var nw_ip_local_address_preference_stable: nw_ip_local_address_preference_t { nw_ip_local_address_preference_t(rawValue: 2) }
public var nw_ip_local_address_preference_temporary: nw_ip_local_address_preference_t { nw_ip_local_address_preference_t(rawValue: 1) }

public var nw_ip_version_4: nw_ip_version_t { nw_ip_version_t(rawValue: 1) }
public var nw_ip_version_6: nw_ip_version_t { nw_ip_version_t(rawValue: 2) }
public var nw_ip_version_any: nw_ip_version_t { nw_ip_version_t(rawValue: 0) }

public var nw_link_quality_good: nw_link_quality_t { nw_link_quality_t(rawValue: 30) }
public var nw_link_quality_minimal: nw_link_quality_t { nw_link_quality_t(rawValue: 10) }
public var nw_link_quality_moderate: nw_link_quality_t { nw_link_quality_t(rawValue: 20) }
public var nw_link_quality_unknown: nw_link_quality_t { nw_link_quality_t(rawValue: 0) }

public var nw_listener_state_cancelled: nw_listener_state_t { nw_listener_state_t(rawValue: 4) }
public var nw_listener_state_failed: nw_listener_state_t { nw_listener_state_t(rawValue: 3) }
public var nw_listener_state_invalid: nw_listener_state_t { nw_listener_state_t(rawValue: 0) }
public var nw_listener_state_ready: nw_listener_state_t { nw_listener_state_t(rawValue: 2) }
public var nw_listener_state_waiting: nw_listener_state_t { nw_listener_state_t(rawValue: 1) }

public var nw_multipath_service_aggregate: nw_multipath_service_t { nw_multipath_service_t(rawValue: 3) }
public var nw_multipath_service_disabled: nw_multipath_service_t { nw_multipath_service_t(rawValue: 0) }
public var nw_multipath_service_handover: nw_multipath_service_t { nw_multipath_service_t(rawValue: 1) }
public var nw_multipath_service_interactive: nw_multipath_service_t { nw_multipath_service_t(rawValue: 2) }

public var nw_multipath_version_0: nw_multipath_version_t { nw_multipath_version_t(rawValue: 0) }
public var nw_multipath_version_1: nw_multipath_version_t { nw_multipath_version_t(rawValue: 1) }
public var nw_multipath_version_unspecified: nw_multipath_version_t { nw_multipath_version_t(rawValue: -1) }

public var nw_parameters_expired_dns_behavior_allow: nw_parameters_expired_dns_behavior_t { nw_parameters_expired_dns_behavior_t(rawValue: 1) }
public var nw_parameters_expired_dns_behavior_default: nw_parameters_expired_dns_behavior_t { nw_parameters_expired_dns_behavior_t(rawValue: 0) }
public var nw_parameters_expired_dns_behavior_persistent: nw_parameters_expired_dns_behavior_t { nw_parameters_expired_dns_behavior_t(rawValue: 3) }
public var nw_parameters_expired_dns_behavior_prohibit: nw_parameters_expired_dns_behavior_t { nw_parameters_expired_dns_behavior_t(rawValue: 2) }

public var nw_path_status_invalid: nw_path_status_t { nw_path_status_t(rawValue: 0) }
public var nw_path_status_satisfiable: nw_path_status_t { nw_path_status_t(rawValue: 3) }
public var nw_path_status_satisfied: nw_path_status_t { nw_path_status_t(rawValue: 1) }
public var nw_path_status_unsatisfied: nw_path_status_t { nw_path_status_t(rawValue: 2) }

public var nw_path_unsatisfied_reason_cellular_denied: nw_path_unsatisfied_reason_t { nw_path_unsatisfied_reason_t(rawValue: 1) }
public var nw_path_unsatisfied_reason_local_network_denied: nw_path_unsatisfied_reason_t { nw_path_unsatisfied_reason_t(rawValue: 3) }
public var nw_path_unsatisfied_reason_not_available: nw_path_unsatisfied_reason_t { nw_path_unsatisfied_reason_t(rawValue: 0) }
public var nw_path_unsatisfied_reason_vpn_inactive: nw_path_unsatisfied_reason_t { nw_path_unsatisfied_reason_t(rawValue: 4) }
public var nw_path_unsatisfied_reason_wifi_denied: nw_path_unsatisfied_reason_t { nw_path_unsatisfied_reason_t(rawValue: 2) }

public var nw_quic_stream_type_bidirectional: nw_quic_stream_type_t { nw_quic_stream_type_t(rawValue: 1) }
public var nw_quic_stream_type_datagram: nw_quic_stream_type_t { nw_quic_stream_type_t(rawValue: 3) }
public var nw_quic_stream_type_unidirectional: nw_quic_stream_type_t { nw_quic_stream_type_t(rawValue: 2) }
public var nw_quic_stream_type_unknown: nw_quic_stream_type_t { nw_quic_stream_type_t(rawValue: 0) }

public var nw_report_resolution_protocol_https: nw_report_resolution_protocol_t { nw_report_resolution_protocol_t(rawValue: 4) }
public var nw_report_resolution_protocol_tcp: nw_report_resolution_protocol_t { nw_report_resolution_protocol_t(rawValue: 2) }
public var nw_report_resolution_protocol_tls: nw_report_resolution_protocol_t { nw_report_resolution_protocol_t(rawValue: 3) }
public var nw_report_resolution_protocol_udp: nw_report_resolution_protocol_t { nw_report_resolution_protocol_t(rawValue: 1) }
public var nw_report_resolution_protocol_unknown: nw_report_resolution_protocol_t { nw_report_resolution_protocol_t(rawValue: 0) }

public var nw_report_resolution_source_cache: nw_report_resolution_source_t { nw_report_resolution_source_t(rawValue: 2) }
public var nw_report_resolution_source_expired_cache: nw_report_resolution_source_t { nw_report_resolution_source_t(rawValue: 3) }
public var nw_report_resolution_source_query: nw_report_resolution_source_t { nw_report_resolution_source_t(rawValue: 1) }

public var nw_service_class_background: nw_service_class_t { nw_service_class_t(rawValue: 1) }
public var nw_service_class_best_effort: nw_service_class_t { nw_service_class_t(rawValue: 0) }
public var nw_service_class_interactive_video: nw_service_class_t { nw_service_class_t(rawValue: 2) }
public var nw_service_class_interactive_voice: nw_service_class_t { nw_service_class_t(rawValue: 3) }
public var nw_service_class_responsive_data: nw_service_class_t { nw_service_class_t(rawValue: 4) }
public var nw_service_class_signaling: nw_service_class_t { nw_service_class_t(rawValue: 5) }

public var nw_txt_record_find_key_empty_value: nw_txt_record_find_key_t { nw_txt_record_find_key_t(rawValue: 3) }
public var nw_txt_record_find_key_invalid: nw_txt_record_find_key_t { nw_txt_record_find_key_t(rawValue: 0) }
public var nw_txt_record_find_key_no_value: nw_txt_record_find_key_t { nw_txt_record_find_key_t(rawValue: 2) }
public var nw_txt_record_find_key_non_empty_value: nw_txt_record_find_key_t { nw_txt_record_find_key_t(rawValue: 4) }
public var nw_txt_record_find_key_not_present: nw_txt_record_find_key_t { nw_txt_record_find_key_t(rawValue: 1) }

public var nw_ws_close_code_abnormal_closure: nw_ws_close_code_t { nw_ws_close_code_t(rawValue: 1006) }
public var nw_ws_close_code_going_away: nw_ws_close_code_t { nw_ws_close_code_t(rawValue: 1001) }
public var nw_ws_close_code_internal_server_error: nw_ws_close_code_t { nw_ws_close_code_t(rawValue: 1011) }
public var nw_ws_close_code_invalid_frame_payload_data: nw_ws_close_code_t { nw_ws_close_code_t(rawValue: 1007) }
public var nw_ws_close_code_mandatory_extension: nw_ws_close_code_t { nw_ws_close_code_t(rawValue: 1010) }
public var nw_ws_close_code_message_too_big: nw_ws_close_code_t { nw_ws_close_code_t(rawValue: 1009) }
public var nw_ws_close_code_no_status_received: nw_ws_close_code_t { nw_ws_close_code_t(rawValue: 1005) }
public var nw_ws_close_code_normal_closure: nw_ws_close_code_t { nw_ws_close_code_t(rawValue: 1000) }
public var nw_ws_close_code_policy_violation: nw_ws_close_code_t { nw_ws_close_code_t(rawValue: 1008) }
public var nw_ws_close_code_protocol_error: nw_ws_close_code_t { nw_ws_close_code_t(rawValue: 1002) }
public var nw_ws_close_code_tls_handshake: nw_ws_close_code_t { nw_ws_close_code_t(rawValue: 1015) }
public var nw_ws_close_code_unsupported_data: nw_ws_close_code_t { nw_ws_close_code_t(rawValue: 1003) }

public var nw_ws_opcode_binary: nw_ws_opcode_t { nw_ws_opcode_t(rawValue: 2) }
public var nw_ws_opcode_close: nw_ws_opcode_t { nw_ws_opcode_t(rawValue: 8) }
public var nw_ws_opcode_cont: nw_ws_opcode_t { nw_ws_opcode_t(rawValue: 0) }
public var nw_ws_opcode_invalid: nw_ws_opcode_t { nw_ws_opcode_t(rawValue: -1) }
public var nw_ws_opcode_ping: nw_ws_opcode_t { nw_ws_opcode_t(rawValue: 9) }
public var nw_ws_opcode_pong: nw_ws_opcode_t { nw_ws_opcode_t(rawValue: 10) }
public var nw_ws_opcode_text: nw_ws_opcode_t { nw_ws_opcode_t(rawValue: 1) }

public var nw_ws_response_status_accept: nw_ws_response_status_t { nw_ws_response_status_t(rawValue: 1) }
public var nw_ws_response_status_invalid: nw_ws_response_status_t { nw_ws_response_status_t(rawValue: 0) }
public var nw_ws_response_status_reject: nw_ws_response_status_t { nw_ws_response_status_t(rawValue: 2) }

public var nw_ws_version_13: nw_ws_version_t { nw_ws_version_t(rawValue: 1) }
public var nw_ws_version_invalid: nw_ws_version_t { nw_ws_version_t(rawValue: 0) }

public var nw_browse_result_change_identical: Int { 1 }
public var nw_browse_result_change_interface_added: Int { 8 }
public var nw_browse_result_change_interface_removed: Int { 16 }
public var nw_browse_result_change_invalid: Int { 0 }
public var nw_browse_result_change_result_added: Int { 2 }
public var nw_browse_result_change_result_removed: Int { 4 }
public var nw_browse_result_change_txt_record_changed: Int { 32 }

public protocol OS_nw_advertise_descriptor: NSObjectProtocol {}
public protocol OS_nw_browse_descriptor: NSObjectProtocol {}
public protocol OS_nw_browse_result: NSObjectProtocol {}
public protocol OS_nw_browser: NSObjectProtocol {}
public protocol OS_nw_connection: NSObjectProtocol {}
public protocol OS_nw_connection_group: NSObjectProtocol {}
public protocol OS_nw_content_context: NSObjectProtocol {}
public protocol OS_nw_data_transfer_report: NSObjectProtocol {}
public protocol OS_nw_endpoint: NSObjectProtocol, Sendable {}
public protocol OS_nw_error: NSObjectProtocol {}
public protocol OS_nw_establishment_report: NSObjectProtocol {}
public protocol OS_nw_ethernet_channel: NSObjectProtocol {}
public protocol OS_nw_framer: NSObjectProtocol {}
public protocol OS_nw_group_descriptor: NSObjectProtocol {}
public protocol OS_nw_interface: NSObjectProtocol {}
public protocol OS_nw_listener: NSObjectProtocol {}
public protocol OS_nw_object: NSObjectProtocol {}
public protocol OS_nw_parameters: NSObjectProtocol {}
public protocol OS_nw_path: NSObjectProtocol {}
public protocol OS_nw_path_monitor: NSObjectProtocol {}
public protocol OS_nw_privacy_context: NSObjectProtocol {}
public protocol OS_nw_protocol_definition: NSObjectProtocol {}
public protocol OS_nw_protocol_metadata: NSObjectProtocol {}
public protocol OS_nw_protocol_options: NSObjectProtocol {}
public protocol OS_nw_protocol_stack: NSObjectProtocol {}
public protocol OS_nw_proxy_config: NSObjectProtocol {}
public protocol OS_nw_relay_hop: NSObjectProtocol {}
public protocol OS_nw_resolution_report: NSObjectProtocol {}
public protocol OS_nw_resolver_config: NSObjectProtocol {}
public protocol OS_nw_txt_record: NSObjectProtocol {}
public protocol OS_nw_ws_request: NSObjectProtocol {}
public protocol OS_nw_ws_response: NSObjectProtocol {}

// Concrete OS_OBJECT stand-ins for C functions that return existentials.
final class _NWLinux_nw_advertise_descriptor: NSObject, OS_nw_advertise_descriptor {}
final class _NWLinux_nw_browse_descriptor: NSObject, OS_nw_browse_descriptor {}
final class _NWLinux_nw_browse_result: NSObject, OS_nw_browse_result {}
final class _NWLinux_nw_browser: NSObject, OS_nw_browser {}
final class _NWLinux_nw_connection: NSObject, OS_nw_connection {}
final class _NWLinux_nw_connection_group: NSObject, OS_nw_connection_group {}
final class _NWLinux_nw_content_context: NSObject, OS_nw_content_context {}
final class _NWLinux_nw_data_transfer_report: NSObject, OS_nw_data_transfer_report {}
final class _NWLinux_nw_endpoint: NSObject, OS_nw_endpoint, Sendable {}
final class _NWLinux_nw_error: NSObject, OS_nw_error {}
final class _NWLinux_nw_establishment_report: NSObject, OS_nw_establishment_report {}
final class _NWLinux_nw_ethernet_channel: NSObject, OS_nw_ethernet_channel {}
final class _NWLinux_nw_framer: NSObject, OS_nw_framer {}
final class _NWLinux_nw_group_descriptor: NSObject, OS_nw_group_descriptor {}
final class _NWLinux_nw_interface: NSObject, OS_nw_interface {}
final class _NWLinux_nw_listener: NSObject, OS_nw_listener {}
final class _NWLinux_nw_object: NSObject, OS_nw_object {}
final class _NWLinux_nw_parameters: NSObject, OS_nw_parameters {}
final class _NWLinux_nw_path: NSObject, OS_nw_path {}
final class _NWLinux_nw_path_monitor: NSObject, OS_nw_path_monitor {}
final class _NWLinux_nw_privacy_context: NSObject, OS_nw_privacy_context {}
final class _NWLinux_nw_protocol_definition: NSObject, OS_nw_protocol_definition {}
final class _NWLinux_nw_protocol_metadata: NSObject, OS_nw_protocol_metadata {}
final class _NWLinux_nw_protocol_options: NSObject, OS_nw_protocol_options {}
final class _NWLinux_nw_protocol_stack: NSObject, OS_nw_protocol_stack {}
final class _NWLinux_nw_proxy_config: NSObject, OS_nw_proxy_config {}
final class _NWLinux_nw_relay_hop: NSObject, OS_nw_relay_hop {}
final class _NWLinux_nw_resolution_report: NSObject, OS_nw_resolution_report {}
final class _NWLinux_nw_resolver_config: NSObject, OS_nw_resolver_config {}
final class _NWLinux_nw_txt_record: NSObject, OS_nw_txt_record {}
final class _NWLinux_nw_ws_request: NSObject, OS_nw_ws_request {}
final class _NWLinux_nw_ws_response: NSObject, OS_nw_ws_response {}

// MARK: - C imported typealiases
public typealias nw_advertise_descriptor_t = any OS_nw_advertise_descriptor
public typealias nw_browse_descriptor_t = any OS_nw_browse_descriptor
public typealias nw_browse_result_t = any OS_nw_browse_result
public typealias nw_browser_t = any OS_nw_browser
public typealias nw_connection_group_t = any OS_nw_connection_group
public typealias nw_connection_t = any OS_nw_connection
public typealias nw_content_context_t = any OS_nw_content_context
public typealias nw_data_transfer_report_t = any OS_nw_data_transfer_report
public typealias nw_endpoint_t = any OS_nw_endpoint
public typealias nw_error_t = any OS_nw_error
public typealias nw_establishment_report_t = any OS_nw_establishment_report
public typealias nw_ethernet_channel_t = any OS_nw_ethernet_channel
public typealias nw_framer_message_t = nw_protocol_metadata_t
public typealias nw_framer_t = any OS_nw_framer
public typealias nw_group_descriptor_t = any OS_nw_group_descriptor
public typealias nw_interface_t = any OS_nw_interface
public typealias nw_listener_t = any OS_nw_listener
public typealias nw_object_t = any OS_nw_object
public typealias nw_parameters_t = any OS_nw_parameters
public typealias nw_path_monitor_t = any OS_nw_path_monitor
public typealias nw_path_t = any OS_nw_path
public typealias nw_privacy_context_t = any OS_nw_privacy_context
public typealias nw_protocol_definition_t = any OS_nw_protocol_definition
public typealias nw_protocol_metadata_t = any OS_nw_protocol_metadata
public typealias nw_protocol_options_t = any OS_nw_protocol_options
public typealias nw_protocol_stack_t = any OS_nw_protocol_stack
public typealias nw_proxy_config_t = any OS_nw_proxy_config
public typealias nw_relay_hop_t = any OS_nw_relay_hop
public typealias nw_resolution_report_t = any OS_nw_resolution_report
public typealias nw_resolver_config_t = any OS_nw_resolver_config
public typealias nw_txt_record_t = any OS_nw_txt_record
public typealias nw_ws_request_t = any OS_nw_ws_request
public typealias nw_ws_response_t = any OS_nw_ws_response
public typealias nw_browse_result_change_t = UInt64
public typealias nw_browse_result_enumerate_interface_t = (nw_interface_t) -> Bool
public typealias nw_browser_browse_results_changed_handler_t = (nw_browse_result_t, nw_browse_result_t, Bool) -> Void
public typealias nw_browser_state_changed_handler_t = (nw_browser_state_t, nw_error_t?) -> Void
public typealias nw_connection_boolean_event_handler_t = (Bool) -> Void
public typealias nw_connection_group_new_connection_handler_t = (nw_connection_t) -> Void
public typealias nw_connection_group_receive_handler_t = (dispatch_data_t?, nw_content_context_t, Bool) -> Void
public typealias nw_connection_group_send_completion_t = (nw_error_t?) -> Void
public typealias nw_connection_group_state_changed_handler_t = (nw_connection_group_state_t, nw_error_t?) -> Void
public typealias nw_connection_path_event_handler_t = (nw_path_t) -> Void
public typealias nw_connection_receive_completion_t = (dispatch_data_t?, nw_content_context_t?, Bool, nw_error_t?) -> Void
public typealias nw_connection_send_completion_t = (nw_error_t?) -> Void
public typealias nw_connection_state_changed_handler_t = (nw_connection_state_t, nw_error_t?) -> Void
public typealias nw_data_transfer_report_collect_block_t = (nw_data_transfer_report_t) -> Void
public typealias nw_establishment_report_access_block_t = (nw_establishment_report_t?) -> Void
public typealias nw_framer_block_t = () -> Void
public typealias nw_framer_cleanup_handler_t = (nw_framer_t) -> Void
public typealias nw_framer_input_handler_t = (nw_framer_t) -> Int
public typealias nw_framer_message_dispose_value_t = (UnsafeMutableRawPointer) -> Void
public typealias nw_framer_output_handler_t = (nw_framer_t, nw_framer_message_t, Int, Bool) -> Void
public typealias nw_framer_parse_completion_t = (UnsafeMutablePointer<UInt8>?, Int, Bool) -> Int
public typealias nw_framer_start_handler_t = (nw_framer_t) -> nw_framer_start_result_t
public typealias nw_framer_stop_handler_t = (nw_framer_t) -> Bool
public typealias nw_framer_wakeup_handler_t = (nw_framer_t) -> Void
public typealias nw_group_descriptor_enumerate_endpoints_block_t = (nw_endpoint_t) -> Bool
public typealias nw_listener_advertised_endpoint_changed_handler_t = (nw_endpoint_t, Bool) -> Void
public typealias nw_listener_new_connection_group_handler_t = (nw_connection_group_t) -> Void
public typealias nw_listener_new_connection_handler_t = (nw_connection_t) -> Void
public typealias nw_listener_state_changed_handler_t = (nw_listener_state_t, nw_error_t?) -> Void
public typealias nw_parameters_configure_protocol_block_t = (nw_protocol_options_t) -> Void
public typealias nw_parameters_iterate_interface_types_block_t = (nw_interface_type_t) -> Bool
public typealias nw_parameters_iterate_interfaces_block_t = (nw_interface_t) -> Bool
public typealias nw_path_enumerate_gateways_block_t = (nw_endpoint_t) -> Bool
public typealias nw_path_enumerate_interfaces_block_t = (nw_interface_t) -> Bool
public typealias nw_path_monitor_cancel_handler_t = () -> Void
public typealias nw_path_monitor_update_handler_t = (nw_path_t) -> Void
public typealias nw_protocol_stack_iterate_protocols_block_t = (nw_protocol_options_t) -> Void
public typealias nw_proxy_domain_enumerator_t = (UnsafePointer<CChar>) -> Void
public typealias nw_report_protocol_enumerator_t = (nw_protocol_definition_t, UInt64, UInt64) -> Bool
public typealias nw_report_resolution_enumerator_t = (nw_report_resolution_source_t, UInt64, UInt32, nw_endpoint_t, nw_endpoint_t) -> Bool
public typealias nw_report_resolution_report_enumerator_t = (nw_resolution_report_t) -> Bool
public typealias nw_txt_record_access_bytes_t = (UnsafePointer<UInt8>, Int) -> Bool
public typealias nw_txt_record_access_key_t = (UnsafePointer<CChar>, nw_txt_record_find_key_t, UnsafePointer<UInt8>?, Int) -> Bool
public typealias nw_txt_record_applier_t = (UnsafePointer<CChar>, nw_txt_record_find_key_t, UnsafePointer<UInt8>, Int) -> Bool
public typealias nw_ws_additional_header_enumerator_t = (UnsafePointer<CChar>, UnsafePointer<CChar>) -> Bool
public typealias nw_ws_client_request_handler_t = (nw_ws_request_t) -> nw_ws_response_t
public typealias nw_ws_pong_handler_t = (nw_error_t?) -> Void
public typealias nw_ws_subprotocol_enumerator_t = (UnsafePointer<CChar>) -> Bool

enum NWLinuxCStatics {
    static var emptyCString: CChar = 0
    static var sockaddrStorage = sockaddr()
}

enum NWLinuxCFactory {
    static func make_nw_advertise_descriptor() -> any OS_nw_advertise_descriptor { _NWLinux_nw_advertise_descriptor() }
    static func make_nw_browse_descriptor() -> any OS_nw_browse_descriptor { _NWLinux_nw_browse_descriptor() }
    static func make_nw_browse_result() -> any OS_nw_browse_result { _NWLinux_nw_browse_result() }
    static func make_nw_browser() -> any OS_nw_browser { _NWLinux_nw_browser() }
    static func make_nw_connection() -> any OS_nw_connection { _NWLinux_nw_connection() }
    static func make_nw_connection_group() -> any OS_nw_connection_group { _NWLinux_nw_connection_group() }
    static func make_nw_content_context() -> any OS_nw_content_context { _NWLinux_nw_content_context() }
    static func make_nw_data_transfer_report() -> any OS_nw_data_transfer_report { _NWLinux_nw_data_transfer_report() }
    static func make_nw_endpoint() -> any OS_nw_endpoint { _NWLinux_nw_endpoint() }
    static func make_nw_error() -> any OS_nw_error { _NWLinux_nw_error() }
    static func make_nw_establishment_report() -> any OS_nw_establishment_report { _NWLinux_nw_establishment_report() }
    static func make_nw_ethernet_channel() -> any OS_nw_ethernet_channel { _NWLinux_nw_ethernet_channel() }
    static func make_nw_framer() -> any OS_nw_framer { _NWLinux_nw_framer() }
    static func make_nw_group_descriptor() -> any OS_nw_group_descriptor { _NWLinux_nw_group_descriptor() }
    static func make_nw_interface() -> any OS_nw_interface { _NWLinux_nw_interface() }
    static func make_nw_listener() -> any OS_nw_listener { _NWLinux_nw_listener() }
    static func make_nw_object() -> any OS_nw_object { _NWLinux_nw_object() }
    static func make_nw_parameters() -> any OS_nw_parameters { _NWLinux_nw_parameters() }
    static func make_nw_path() -> any OS_nw_path { _NWLinux_nw_path() }
    static func make_nw_path_monitor() -> any OS_nw_path_monitor { _NWLinux_nw_path_monitor() }
    static func make_nw_privacy_context() -> any OS_nw_privacy_context { _NWLinux_nw_privacy_context() }
    static func make_nw_protocol_definition() -> any OS_nw_protocol_definition { _NWLinux_nw_protocol_definition() }
    static func make_nw_protocol_metadata() -> any OS_nw_protocol_metadata { _NWLinux_nw_protocol_metadata() }
    static func make_nw_protocol_options() -> any OS_nw_protocol_options { _NWLinux_nw_protocol_options() }
    static func make_nw_protocol_stack() -> any OS_nw_protocol_stack { _NWLinux_nw_protocol_stack() }
    static func make_nw_proxy_config() -> any OS_nw_proxy_config { _NWLinux_nw_proxy_config() }
    static func make_nw_relay_hop() -> any OS_nw_relay_hop { _NWLinux_nw_relay_hop() }
    static func make_nw_resolution_report() -> any OS_nw_resolution_report { _NWLinux_nw_resolution_report() }
    static func make_nw_resolver_config() -> any OS_nw_resolver_config { _NWLinux_nw_resolver_config() }
    static func make_nw_txt_record() -> any OS_nw_txt_record { _NWLinux_nw_txt_record() }
    static func make_nw_ws_request() -> any OS_nw_ws_request { _NWLinux_nw_ws_request() }
    static func make_nw_ws_response() -> any OS_nw_ws_response { _NWLinux_nw_ws_response() }
}

