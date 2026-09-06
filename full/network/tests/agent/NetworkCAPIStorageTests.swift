import Foundation
import Network

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testCParametersGetSetRoundTrip() {
    let parameters = nw_parameters_create()
    nw_parameters_set_allow_ultra_constrained(parameters, true)
    expect(nw_parameters_get_allow_ultra_constrained(parameters), "allow_ultra_constrained")
    nw_parameters_set_attribution(parameters, .user)
    expect(nw_parameters_get_attribution(parameters) == .user, "attribution")
    nw_parameters_set_expired_dns_behavior(parameters, nw_parameters_expired_dns_behavior_t(rawValue: 1))
    expect(nw_parameters_get_expired_dns_behavior(parameters).rawValue == 1, "expired_dns_behavior")
    nw_parameters_set_fast_open_enabled(parameters, true)
    expect(nw_parameters_get_fast_open_enabled(parameters), "fast_open_enabled")
    nw_parameters_set_include_peer_to_peer(parameters, true)
    expect(nw_parameters_get_include_peer_to_peer(parameters), "include_peer_to_peer")
    nw_parameters_set_local_only(parameters, true)
    expect(nw_parameters_get_local_only(parameters), "local_only")
    nw_parameters_set_multipath_service(parameters, nw_multipath_service_t(rawValue: 1))
    expect(nw_parameters_get_multipath_service(parameters).rawValue == 1, "multipath_service")
    nw_parameters_set_prefer_no_proxy(parameters, true)
    expect(nw_parameters_get_prefer_no_proxy(parameters), "prefer_no_proxy")
    nw_parameters_set_prohibit_constrained(parameters, true)
    expect(nw_parameters_get_prohibit_constrained(parameters), "prohibit_constrained")
    nw_parameters_set_prohibit_expensive(parameters, true)
    expect(nw_parameters_get_prohibit_expensive(parameters), "prohibit_expensive")
    nw_parameters_set_required_interface_type(parameters, nw_interface_type_wifi)
    expect(nw_parameters_get_required_interface_type(parameters).rawValue == nw_interface_type_wifi.rawValue, "required_interface_type")
    nw_parameters_set_requires_dnssec_validation(parameters, true)
    expect(nw_parameters_requires_dnssec_validation(parameters), "requires_dnssec_validation")
    nw_parameters_set_reuse_local_address(parameters, true)
    expect(nw_parameters_get_reuse_local_address(parameters), "reuse_local_address")
    nw_parameters_set_service_class(parameters, nw_service_class_background)
    expect(nw_parameters_get_service_class(parameters).rawValue == nw_service_class_background.rawValue, "service_class")
    let endpoint = "127.0.0.1".withCString { host in
        "80".withCString { port in
            nw_endpoint_create_host(host, port)
        }
    }
    nw_parameters_set_local_endpoint(parameters, endpoint)
    expect(nw_parameters_copy_local_endpoint(parameters) != nil, "copy_local_endpoint")
    nw_parameters_require_interface(parameters, nil)
    expect(nw_parameters_copy_required_interface(parameters) == nil, "copy_required_interface")
    "agent".withCString { name in
        let privacy = nw_privacy_context_create(name)
        nw_parameters_set_privacy_context(parameters, privacy)
    }
}

func testCTCPOptionsSettersStore() {
    let options = nw_tcp_create_options()
    nw_tcp_options_set_connection_timeout(options, 5)
    nw_tcp_options_set_disable_ack_stretching(options, true)
    nw_tcp_options_set_disable_ecn(options, true)
    nw_tcp_options_set_enable_fast_open(options, true)
    nw_tcp_options_set_enable_keepalive(options, true)
    nw_tcp_options_set_keepalive_count(options, 3)
    nw_tcp_options_set_keepalive_idle_time(options, 10)
    nw_tcp_options_set_keepalive_interval(options, 2)
    nw_tcp_options_set_maximum_segment_size(options, 1400)
    nw_tcp_options_set_multipath_force_version(options, nw_multipath_version_t(rawValue: 0))
    nw_tcp_options_set_no_delay(options, true)
    nw_tcp_options_set_no_options(options, true)
    nw_tcp_options_set_no_push(options, true)
    nw_tcp_options_set_persist_timeout(options, 1)
    nw_tcp_options_set_retransmit_connection_drop_time(options, 4)
    nw_tcp_options_set_retransmit_fin_drop(options, true)
    _ = options
    let udp = nw_udp_create_options()
    nw_udp_options_set_prefer_no_checksum(udp, true)
    _ = udp
}

func testCTXTRecordDictionaryRoundTrip() {
    let record = nw_txt_record_create_dictionary()
    expect(nw_txt_record_is_dictionary(record), "is_dictionary")
    expect(nw_txt_record_get_key_count(record) == 0, "get_key_count empty")
    "path".withCString { key in
        Array(" /".utf8).withUnsafeBufferPointer { bytes in
            expect(
                nw_txt_record_set_key(record, key, bytes.baseAddress, bytes.count),
                "set_key"
            )
        }
    }
    expect(nw_txt_record_get_key_count(record) == 1, "get_key_count")
    "path".withCString { key in
        expect(
            nw_txt_record_find_key(record, key) == nw_txt_record_find_key_non_empty_value,
            "find_key"
        )
        var seen = false
        expect(
            nw_txt_record_access_key(record, key) { _, status, _, length in
                seen = status == nw_txt_record_find_key_non_empty_value && length > 0
                return true
            },
            "access_key"
        )
        expect(seen, "access_key saw value")
    }
    var applied = 0
    expect(
        nw_txt_record_apply(record) { _, _, _, _ in
            applied += 1
            return true
        },
        "apply"
    )
    expect(applied == 1, "apply count")
    var accessed = false
    expect(
        nw_txt_record_access_bytes(record) { _, length in
            accessed = length > 0
            return true
        },
        "access_bytes"
    )
    expect(accessed, "access_bytes nonempty")
    let copy = nw_txt_record_copy(record)
    expect(nw_txt_record_is_equal(record, copy), "is_equal copy")
    let bytes: [UInt8] = [6, 112, 97, 116, 104, 61, 47]
    let fromBytes = bytes.withUnsafeBufferPointer { buffer in
        nw_txt_record_create_with_bytes(buffer.baseAddress!, buffer.count)
    }
    expect(nw_txt_record_get_key_count(fromBytes) == 1, "create_with_bytes")
    "path".withCString { key in
        expect(nw_txt_record_remove_key(record, key), "remove_key")
        expect(
            nw_txt_record_find_key(record, key) == nw_txt_record_find_key_not_present,
            "not_present"
        )
    }
}
