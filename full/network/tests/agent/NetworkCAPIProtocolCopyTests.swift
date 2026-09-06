import Foundation
import Network

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testCProtocolCopyDefinitions() {
    let ip = nw_protocol_copy_ip_definition()
    let quic = nw_protocol_copy_quic_definition()
    let tcp = nw_protocol_copy_tcp_definition()
    let tls = nw_protocol_copy_tls_definition()
    let udp = nw_protocol_copy_udp_definition()
    let ws = nw_protocol_copy_ws_definition()
    expect(nw_protocol_definition_is_equal(tcp, udp) == false, "definition_is_equal")
    _ = ip
    _ = quic
    _ = tls
    _ = ws
    let metadata = nw_udp_create_metadata()
    _ = nw_protocol_metadata_copy_definition(metadata)
    expect(nw_protocol_metadata_is_framer_message(metadata) == false, "is_framer_message")
    expect(nw_protocol_metadata_is_ip(metadata) == false, "is_ip")
    expect(nw_protocol_metadata_is_quic(metadata) == false, "is_quic")
    expect(nw_protocol_metadata_is_tcp(metadata) == false, "is_tcp")
    expect(nw_protocol_metadata_is_tls(metadata) == false, "is_tls")
    expect(nw_protocol_metadata_is_udp(metadata) == false, "is_udp")
    expect(nw_protocol_metadata_is_ws(metadata) == false, "is_ws")
    let options = nw_tcp_create_options()
    expect(nw_protocol_options_is_quic(options) == false, "options_is_quic")
    _ = nw_protocol_options_copy_definition(options)
}

func testCIPOptionsSetters() {
    let stack = nw_parameters_copy_default_protocol_stack(nw_parameters_create())
    let options = nw_protocol_stack_copy_internet_protocol(stack)!
    nw_ip_options_set_calculate_receive_time(options, true)
    nw_ip_options_set_disable_fragmentation(options, true)
    nw_ip_options_set_disable_multicast_loopback(options, true)
    nw_ip_options_set_hop_limit(options, 16)
    nw_ip_options_set_local_address_preference(options, nw_ip_local_address_preference_temporary)
    nw_ip_options_set_use_minimum_mtu(options, true)
    nw_ip_options_set_version(options, nw_ip_version_4)
    _ = options
}

func testCParametersFactoriesAndStack() {
    var tlsConfigured = false
    var tcpConfigured = false
    let tcp = nw_parameters_create_secure_tcp({ _ in tlsConfigured = true }, { _ in tcpConfigured = true })
    expect(tlsConfigured, "configure_tls invoked")
    expect(tcpConfigured, "configure_tcp invoked")
    _ = tcp
    let udp = nw_parameters_create_secure_udp({ _ in }, { _ in })
    _ = udp
    var quicConfigured = false
    let quic = nw_parameters_create_quic { _ in quicConfigured = true }
    expect(quicConfigured, "configure_quic invoked")
    _ = quic
    let parameters = nw_parameters_create()
    let copy = nw_parameters_copy(parameters)
    _ = copy
    let stack = nw_parameters_copy_default_protocol_stack(parameters)
    expect(nw_protocol_stack_copy_internet_protocol(stack) != nil, "copy_internet_protocol")
    expect(nw_protocol_stack_copy_transport_protocol(stack) != nil, "copy_transport_protocol")
    nw_protocol_stack_clear_application_protocols(stack)
    nw_protocol_stack_iterate_application_protocols(stack) { _ in }
    nw_protocol_stack_prepend_application_protocol(stack, nw_tls_create_options())
    nw_protocol_stack_set_transport_protocol(stack, nw_tcp_create_options())
    nw_parameters_clear_prohibited_interface_types(parameters)
    nw_parameters_clear_prohibited_interfaces(parameters)
    nw_parameters_prohibit_interface_type(parameters, nw_interface_type_cellular)
    nw_parameters_iterate_prohibited_interface_types(parameters) { _ in false }
    nw_parameters_iterate_prohibited_interfaces(parameters) { _ in false }
}
