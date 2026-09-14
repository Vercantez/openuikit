import Foundation
import Network

private func capiExpect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testCAPIHostAndPathMonitorFunctions() {
    let endpoint = "127.0.0.1".withCString { host in
        "80".withCString { port in
            nw_endpoint_create_host(host, port)
        }
    }
    let parameters = nw_parameters_create()
    let connection = nw_connection_create(endpoint, parameters)
    nw_connection_start(connection)
    nw_connection_cancel(connection)
    let pathMonitor = nw_path_monitor_create()
    nw_path_monitor_set_queue(pathMonitor, DispatchQueue(label: "c.path"))
    nw_path_monitor_start(pathMonitor)
    nw_path_monitor_cancel(pathMonitor)
    _ = nw_parameters_create_application_service()
    _ = nw_path_monitor_create_with_type(nw_interface_type_loopback)
    capiExpect(nw_interface_type_loopback.rawValue == 4, "loopback raw")
}

func testCObjectTypealiasesAndOSProtocols() {
    let endpoint: nw_endpoint_t = "127.0.0.1".withCString { host in
        "80".withCString { port in
            nw_endpoint_create_host(host, port)
        }
    }
    let _: OS_nw_endpoint = endpoint
    let parameters: nw_parameters_t = nw_parameters_create()
    let _: OS_nw_parameters = parameters
    let connection: nw_connection_t = nw_connection_create(endpoint, parameters)
    let _: OS_nw_connection = connection
    let listener: nw_listener_t? = nw_listener_create(parameters)
    capiExpect(listener != nil, "listener")
    if let listener {
        let _: OS_nw_listener = listener
    }
    let monitor: nw_path_monitor_t = nw_path_monitor_create()
    let _: OS_nw_path_monitor = monitor
    let context: nw_content_context_t = "ctx".withCString { nw_content_context_create($0) }
    let _: OS_nw_content_context = context
    let report: nw_data_transfer_report_t = nw_connection_create_new_data_transfer_report(connection)
    let _: OS_nw_data_transfer_report = report
    let txt: nw_txt_record_t = nw_txt_record_create_dictionary()
    let _: OS_nw_txt_record = txt
    let wsOptions: nw_protocol_options_t = nw_ws_create_options(nw_ws_version_13)
    let _: OS_nw_protocol_options = wsOptions
    let wsMeta: nw_protocol_metadata_t = nw_ws_create_metadata(nw_ws_opcode_text)
    let _: OS_nw_protocol_metadata = wsMeta
    let wsResponse: nw_ws_response_t = nw_ws_response_create(nw_ws_response_status_reject, nil)
    let _: OS_nw_ws_response = wsResponse
    let groupDesc: nw_group_descriptor_t = nw_group_descriptor_create_multiplex(endpoint)
    let _: OS_nw_group_descriptor = groupDesc
    let group: nw_connection_group_t = nw_connection_group_create(groupDesc, parameters)
    let _: OS_nw_connection_group = group
    let browseDesc: nw_browse_descriptor_t = "_http._tcp".withCString {
        nw_browse_descriptor_create_bonjour_service($0, nil)
    }
    let _: OS_nw_browse_descriptor = browseDesc
    let browser: nw_browser_t = nw_browser_create(browseDesc, parameters)
    let _: OS_nw_browser = browser
    let advertise: nw_advertise_descriptor_t = "svc".withCString {
        nw_advertise_descriptor_create_application_service($0)
    }
    let _: OS_nw_advertise_descriptor = advertise
    let privacy: nw_privacy_context_t = "priv".withCString { nw_privacy_context_create($0) }
    let _: OS_nw_privacy_context = privacy
    let proxy: nw_proxy_config_t = nw_proxy_config_create_socksv5(endpoint)
    let _: OS_nw_proxy_config = proxy
    let hop: nw_relay_hop_t = nw_relay_hop_create(endpoint, endpoint, nil)
    let _: OS_nw_relay_hop = hop
    let resolver: nw_resolver_config_t = "example.invalid".withCString { nw_resolver_config_create_tls($0) }
    let _: OS_nw_resolver_config = resolver

    var capturedFramer: nw_framer_t?
    let definition: nw_protocol_definition_t = "alias".withCString { ident in
        nw_framer_create_definition(ident, 0) { framer in
            capturedFramer = framer
            return nw_framer_start_result_ready
        }
    }
    let _: OS_nw_protocol_definition = definition
    if let framer = capturedFramer {
        let _: OS_nw_framer = framer
        let message: nw_framer_message_t = nw_framer_message_create(framer)
        _ = message
    }

    var errorSlot: nw_error_t?
    var pathSlot: nw_path_t?
    var browseResultSlot: nw_browse_result_t?
    var establishmentSlot: nw_establishment_report_t?
    var resolutionSlot: nw_resolution_report_t?
    var interfaceSlot: nw_interface_t?
    var stackSlot: nw_protocol_stack_t?
    var requestSlot: nw_ws_request_t?
    var objectSlot: nw_object_t?
    var ethernetSlot: nw_ethernet_channel_t?
    _ = errorSlot as OS_nw_error?
    _ = pathSlot as OS_nw_path?
    _ = browseResultSlot as OS_nw_browse_result?
    _ = establishmentSlot as OS_nw_establishment_report?
    _ = resolutionSlot as OS_nw_resolution_report?
    _ = interfaceSlot as OS_nw_interface?
    _ = stackSlot as OS_nw_protocol_stack?
    _ = requestSlot as OS_nw_ws_request?
    _ = objectSlot as OS_nw_object?
    _ = ethernetSlot as OS_nw_ethernet_channel?

    let change: nw_browse_result_change_t = 0
    capiExpect(change == 0, "browse change")
    let ifaceEnum: nw_browse_result_enumerate_interface_t = { _ in true }
    let browseChanged: nw_browser_browse_results_changed_handler_t = { _, _, _ in }
    let browserState: nw_browser_state_changed_handler_t = { _, _ in }
    let boolHandler: nw_connection_boolean_event_handler_t = { _ in }
    let newConn: nw_connection_group_new_connection_handler_t = { _ in }
    let groupRecv: nw_connection_group_receive_handler_t = { _, _, _ in }
    let groupSend: nw_connection_group_send_completion_t = { _ in }
    let groupState: nw_connection_group_state_changed_handler_t = { _, _ in }
    let pathEvent: nw_connection_path_event_handler_t = { _ in }
    let recvCompletion: nw_connection_receive_completion_t = { _, _, _, _ in }
    let sendCompletion: nw_connection_send_completion_t = { _ in }
    let connState: nw_connection_state_changed_handler_t = { _, _ in }
    let collect: nw_data_transfer_report_collect_block_t = { _ in }
    let access: nw_establishment_report_access_block_t = { _ in }
    let framerBlock: nw_framer_block_t = {}
    let cleanup: nw_framer_cleanup_handler_t = { _ in }
    let input: nw_framer_input_handler_t = { _ in 0 }
    let dispose: nw_framer_message_dispose_value_t = { _ in }
    let output: nw_framer_output_handler_t = { _, _, _, _ in }
    let parse: nw_framer_parse_completion_t = { _, _, _ in 0 }
    let start: nw_framer_start_handler_t = { _ in nw_framer_start_result_ready }
    let stop: nw_framer_stop_handler_t = { _ in true }
    let wakeup: nw_framer_wakeup_handler_t = { _ in }
    let groupEnum: nw_group_descriptor_enumerate_endpoints_block_t = { _ in true }
    let advertised: nw_listener_advertised_endpoint_changed_handler_t = { _, _ in }
    let newGroup: nw_listener_new_connection_group_handler_t = { _ in }
    let newListenerConn: nw_listener_new_connection_handler_t = { _ in }
    let listenerState: nw_listener_state_changed_handler_t = { _, _ in }
    let configure: nw_parameters_configure_protocol_block_t = { _ in }
    let iterateTypes: nw_parameters_iterate_interface_types_block_t = { _ in true }
    let iterateIfaces: nw_parameters_iterate_interfaces_block_t = { _ in true }
    let enumGateways: nw_path_enumerate_gateways_block_t = { _ in true }
    let enumIfaces: nw_path_enumerate_interfaces_block_t = { _ in true }
    let cancelHandler: nw_path_monitor_cancel_handler_t = {}
    let updateHandler: nw_path_monitor_update_handler_t = { _ in }
    let iterateProtos: nw_protocol_stack_iterate_protocols_block_t = { _ in }
    let domainEnum: nw_proxy_domain_enumerator_t = { _ in }
    let protoEnum: nw_report_protocol_enumerator_t = { _, _, _ in true }
    let resEnum: nw_report_resolution_enumerator_t = { _, _, _, _, _ in true }
    let resReportEnum: nw_report_resolution_report_enumerator_t = { _ in true }
    let txtBytes: nw_txt_record_access_bytes_t = { _, _ in true }
    let txtKey: nw_txt_record_access_key_t = { _, _, _, _ in true }
    let txtApply: nw_txt_record_applier_t = { _, _, _, _ in true }
    let wsHeader: nw_ws_additional_header_enumerator_t = { _, _ in true }
    let wsClient: nw_ws_client_request_handler_t = { _ in
        nw_ws_response_create(nw_ws_response_status_reject, nil)
    }
    let wsPong: nw_ws_pong_handler_t = { _ in }
    let wsProto: nw_ws_subprotocol_enumerator_t = { _ in true }

    boolHandler(true)
    newConn(connection)
    groupSend(nil)
    groupState(nw_connection_group_state_failed, nil)
    sendCompletion(nil)
    connState(nw_connection_state_cancelled, nil)
    collect(report)
    access(nil)
    framerBlock()
    advertised(endpoint, true)
    newListenerConn(connection)
    listenerState(nw_listener_state_cancelled, nil)
    configure(wsOptions)
    cancelHandler()
    iterateProtos(wsOptions)
    "example.invalid".withCString { domainEnum($0) }
    wsPong(nil)
    recvCompletion(nil, nil, true, nil)
    _ = [
        ifaceEnum as Any,
        browseChanged as Any,
        browserState as Any,
        groupRecv as Any,
        pathEvent as Any,
        cleanup as Any,
        input as Any,
        dispose as Any,
        output as Any,
        parse as Any,
        start as Any,
        stop as Any,
        wakeup as Any,
        groupEnum as Any,
        newGroup as Any,
        iterateTypes as Any,
        iterateIfaces as Any,
        enumGateways as Any,
        enumIfaces as Any,
        updateHandler as Any,
        protoEnum as Any,
        resEnum as Any,
        resReportEnum as Any,
        txtBytes as Any,
        txtKey as Any,
        txtApply as Any,
        wsHeader as Any,
        wsClient as Any,
        wsProto as Any,
    ]

    errorSlot = nil
    pathSlot = nil
    browseResultSlot = nil
    establishmentSlot = nil
    resolutionSlot = nil
    interfaceSlot = nil
    stackSlot = nil
    requestSlot = nil
    objectSlot = nil
    ethernetSlot = nil
}
