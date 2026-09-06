import Foundation
#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif

// Fail-closed C API imported by the Network overlay. Completions that would
// otherwise hang are invoked with a POSIX EOPNOTSUPP-shaped error object.

private func nwLinuxCError(
    _ domain: nw_error_domain_t = nw_error_domain_posix,
    _ code: Int32 = Int32(POSIXErrorCode.EOPNOTSUPP.rawValue)
) -> nw_error_t {
    let error = _NWLinux_nw_error()
    error.domain = domain
    error.code = code
    return error
}

private func linuxParameters(_ parameters: nw_parameters_t) -> _NWLinux_nw_parameters? {
    parameters as? _NWLinux_nw_parameters
}

private func linuxOptions(_ options: nw_protocol_options_t) -> _NWLinux_nw_protocol_options? {
    options as? _NWLinux_nw_protocol_options
}

private func linuxTXT(_ txt_record: nw_txt_record_t) -> _NWLinux_nw_txt_record? {
    txt_record as? _NWLinux_nw_txt_record
}

private func linuxEndpoint(_ endpoint: nw_endpoint_t) -> _NWLinux_nw_endpoint? {
    endpoint as? _NWLinux_nw_endpoint
}

private func linuxError(_ error: nw_error_t) -> _NWLinux_nw_error? {
    error as? _NWLinux_nw_error
}

private func linuxMetadata(_ metadata: nw_protocol_metadata_t) -> _NWLinux_nw_protocol_metadata? {
    metadata as? _NWLinux_nw_protocol_metadata
}

private func linuxFramer(_ framer: nw_framer_t) -> _NWLinux_nw_framer? {
    framer as? _NWLinux_nw_framer
}

private func linuxInterface(_ interface: nw_interface_t) -> _NWLinux_nw_interface? {
    interface as? _NWLinux_nw_interface
}

private func linuxConnection(_ connection: nw_connection_t) -> _NWLinux_nw_connection? {
    connection as? _NWLinux_nw_connection
}

private func linuxGroup(_ group: nw_connection_group_t) -> _NWLinux_nw_connection_group? {
    group as? _NWLinux_nw_connection_group
}

private func linuxDescriptor(_ descriptor: nw_browse_descriptor_t) -> _NWLinux_nw_browse_descriptor? {
    descriptor as? _NWLinux_nw_browse_descriptor
}

private func linuxBrowseResult(_ result: nw_browse_result_t) -> _NWLinux_nw_browse_result? {
    result as? _NWLinux_nw_browse_result
}

private func linuxContext(_ context: nw_content_context_t) -> _NWLinux_nw_content_context? {
    context as? _NWLinux_nw_content_context
}

private func linuxReport(_ report: nw_data_transfer_report_t) -> _NWLinux_nw_data_transfer_report? {
    report as? _NWLinux_nw_data_transfer_report
}

private func linuxProxy(_ config: nw_proxy_config_t) -> _NWLinux_nw_proxy_config? {
    config as? _NWLinux_nw_proxy_config
}

private func linuxPrivacy(_ context: nw_privacy_context_t) -> _NWLinux_nw_privacy_context? {
    context as? _NWLinux_nw_privacy_context
}

private func linuxDefinition(_ definition: nw_protocol_definition_t) -> _NWLinux_nw_protocol_definition? {
    definition as? _NWLinux_nw_protocol_definition
}

private func linuxGroupDescriptor(_ descriptor: nw_group_descriptor_t) -> _NWLinux_nw_group_descriptor? {
    descriptor as? _NWLinux_nw_group_descriptor
}

private func linuxRelay(_ hop: nw_relay_hop_t) -> _NWLinux_nw_relay_hop? {
    hop as? _NWLinux_nw_relay_hop
}

private func linuxResolver(_ config: nw_resolver_config_t) -> _NWLinux_nw_resolver_config? {
    config as? _NWLinux_nw_resolver_config
}

private func linuxResolution(_ report: nw_resolution_report_t) -> _NWLinux_nw_resolution_report? {
    report as? _NWLinux_nw_resolution_report
}

private func linuxWSRequest(_ request: nw_ws_request_t) -> _NWLinux_nw_ws_request? {
    request as? _NWLinux_nw_ws_request
}

private func linuxWSResponse(_ response: nw_ws_response_t) -> _NWLinux_nw_ws_response? {
    response as? _NWLinux_nw_ws_response
}

private func linuxNamedDefinition(_ identifier: String) -> nw_protocol_definition_t {
    let object = _NWLinux_nw_protocol_definition()
    object.identifier = NWLinuxCString(identifier)
    return object
}

private func linuxLoopbackInterface() -> nw_interface_t {
    let object = _NWLinux_nw_interface()
    if let record = NWPOSIX.snapshotInterfaces().first(where: { $0.interface.type == .loopback }) {
        object.name = NWLinuxCString(record.interface.name)
        object.index = UInt32(record.interface.index)
        object.type = NWPOSIX.cInterfaceType(record.interface.type)
    } else {
        object.name = NWLinuxCString("lo")
        object.index = 1
        object.type = nw_interface_type_loopback
    }
    return object
}

public func nw_advertise_descriptor_copy_txt_record_object(_ advertise_descriptor: nw_advertise_descriptor_t) -> nw_txt_record_t? {
    _ = advertise_descriptor
    return nil
}

public func nw_advertise_descriptor_create_application_service(_ application_service_name: UnsafePointer<CChar>) -> nw_advertise_descriptor_t {
    _ = application_service_name
    return NWLinuxCFactory.make_nw_advertise_descriptor()
}

public func nw_advertise_descriptor_create_bonjour_service(_ name: UnsafePointer<CChar>?, _ type: UnsafePointer<CChar>, _ domain: UnsafePointer<CChar>?) -> nw_advertise_descriptor_t? {
    _ = name
    _ = type
    _ = domain
    return nil
}

public func nw_advertise_descriptor_get_application_service_name(_ advertise_descriptor: nw_advertise_descriptor_t) -> UnsafePointer<CChar>? {
    _ = advertise_descriptor
    return nil
}

public func nw_advertise_descriptor_get_no_auto_rename(_ advertise_descriptor: nw_advertise_descriptor_t) -> Bool {
    _ = advertise_descriptor
    return false
}

public func nw_advertise_descriptor_set_no_auto_rename(_ advertise_descriptor: nw_advertise_descriptor_t, _ no_auto_rename: Bool) {
    _ = advertise_descriptor
    _ = no_auto_rename
}

public func nw_advertise_descriptor_set_txt_record(_ advertise_descriptor: nw_advertise_descriptor_t, _ txt_record: UnsafeRawPointer?, _ txt_length: Int) {
    _ = advertise_descriptor
    _ = txt_record
    _ = txt_length
}

public func nw_advertise_descriptor_set_txt_record_object(_ advertise_descriptor: nw_advertise_descriptor_t, _ txt_record: nw_txt_record_t?) {
    _ = advertise_descriptor
    _ = txt_record
}

public func nw_browse_descriptor_create_application_service(_ application_service_name: UnsafePointer<CChar>) -> nw_browse_descriptor_t {
    let object = _NWLinux_nw_browse_descriptor()
    object.applicationServiceName = NWLinuxCString(String(cString: application_service_name))
    return object
}

public func nw_browse_descriptor_create_bonjour_service(_ type: UnsafePointer<CChar>, _ domain: UnsafePointer<CChar>?) -> nw_browse_descriptor_t {
    let object = _NWLinux_nw_browse_descriptor()
    object.bonjourType = NWLinuxCString(String(cString: type))
    object.bonjourDomain = NWLinuxCString(domain.map { String(cString: $0) } ?? "")
    return object
}

public func nw_browse_descriptor_get_application_service_name(_ descriptor: nw_browse_descriptor_t) -> UnsafePointer<CChar>? {
    linuxDescriptor(descriptor)?.applicationServiceName?.pointer
}

public func nw_browse_descriptor_get_bonjour_service_domain(_ descriptor: nw_browse_descriptor_t) -> UnsafePointer<CChar>? {
    linuxDescriptor(descriptor)?.bonjourDomain.pointer
}

public func nw_browse_descriptor_get_bonjour_service_type(_ descriptor: nw_browse_descriptor_t) -> UnsafePointer<CChar> {
    linuxDescriptor(descriptor)?.bonjourType.pointer ?? withUnsafePointer(to: &NWLinuxCStatics.emptyCString) { $0 }
}

public func nw_browse_descriptor_get_include_txt_record(_ descriptor: nw_browse_descriptor_t) -> Bool {
    linuxDescriptor(descriptor)?.includeTXTRecord ?? false
}

public func nw_browse_descriptor_set_include_txt_record(_ descriptor: nw_browse_descriptor_t, _ include_txt_record: Bool) {
    linuxDescriptor(descriptor)?.includeTXTRecord = include_txt_record
}

public func nw_browse_result_copy_endpoint(_ result: nw_browse_result_t) -> nw_endpoint_t {
    linuxBrowseResult(result)?.endpoint ?? NWLinuxCFactory.make_nw_endpoint()
}

public func nw_browse_result_copy_txt_record_object(_ result: nw_browse_result_t) -> nw_txt_record_t? {
    linuxBrowseResult(result)?.txtRecord
}

public func nw_browse_result_enumerate_interfaces(_ result: nw_browse_result_t, _ enumerator: (nw_interface_t) -> Bool) {
    guard let stored = linuxBrowseResult(result) else { return }
    for interface in stored.interfaces {
        if !enumerator(interface) { return }
    }
}

public func nw_browse_result_get_changes(_ old_result: nw_browse_result_t?, _ new_result: nw_browse_result_t?) -> nw_browse_result_change_t {
    if old_result == nil && new_result == nil {
        return nw_browse_result_change_t(UInt64(nw_browse_result_change_identical))
    }
    return nw_browse_result_change_t(UInt64(nw_browse_result_change_invalid))
}

public func nw_browse_result_get_interfaces_count(_ result: nw_browse_result_t) -> Int {
    linuxBrowseResult(result)?.interfaces.count ?? 0
}

public func nw_browser_cancel(_ browser: nw_browser_t) {
    _ = browser
}

public func nw_browser_copy_browse_descriptor(_ browser: nw_browser_t) -> nw_browse_descriptor_t {
    (browser as? _NWLinux_nw_browser)?.descriptor ?? NWLinuxCFactory.make_nw_browse_descriptor()
}

public func nw_browser_copy_parameters(_ browser: nw_browser_t) -> nw_parameters_t {
    (browser as? _NWLinux_nw_browser)?.parameters ?? NWLinuxCFactory.make_nw_parameters()
}

public func nw_browser_create(_ descriptor: nw_browse_descriptor_t, _ parameters: nw_parameters_t?) -> nw_browser_t {
    let object = _NWLinux_nw_browser()
    object.descriptor = descriptor
    object.parameters = parameters
    return object
}

public func nw_browser_set_browse_results_changed_handler(_ browser: nw_browser_t, _ handler: nw_browser_browse_results_changed_handler_t?) {
    (browser as? _NWLinux_nw_browser)?.resultsHandler = handler
}

public func nw_browser_set_queue(_ browser: nw_browser_t, _ queue: dispatch_queue_t) {
    (browser as? _NWLinux_nw_browser)?.queue = queue
}

public func nw_browser_set_state_changed_handler(_ browser: nw_browser_t, _ state_changed_handler: nw_browser_state_changed_handler_t?) {
    (browser as? _NWLinux_nw_browser)?.stateHandler = state_changed_handler
}

public func nw_browser_start(_ browser: nw_browser_t) {
    guard let stored = browser as? _NWLinux_nw_browser else { return }
    let empty = _NWLinux_nw_browse_result()
    stored.resultsHandler?(empty, empty, true)
    stored.stateHandler?(nw_browser_state_failed, nwLinuxCError())
}

public func nw_connection_access_establishment_report(_ connection: nw_connection_t, _ queue: dispatch_queue_t, _ access_block: @escaping nw_establishment_report_access_block_t) {
    _ = queue
    let report = _NWLinux_nw_establishment_report()
    if let endpoint = linuxConnection(connection)?.endpoint {
        let resolution = _NWLinux_nw_resolution_report()
        resolution.preferredEndpoint = endpoint
        resolution.successfulEndpoint = endpoint
        resolution.endpointCount = 1
        resolution.milliseconds = 0
        resolution.protocolValue = nw_report_resolution_protocol_unknown
        resolution.source = nw_report_resolution_source_query
        report.resolutionReports = [resolution]
        report.resolutions = [
            (nw_report_resolution_source_query, 0, 1, endpoint, endpoint)
        ]
        let definition = linuxNamedDefinition("tcp")
        report.protocols = [(definition, 0, 0)]
    }
    access_block(report)
}

public func nw_connection_batch(_ connection: nw_connection_t, _ batch_block: () -> Void) {
    _ = connection
    batch_block()
}

public func nw_connection_cancel(_ connection: nw_connection_t) {
    _ = connection
}

public func nw_connection_cancel_current_endpoint(_ connection: nw_connection_t) {
    _ = connection
}

public func nw_connection_copy_current_path(_ connection: nw_connection_t) -> nw_path_t? {
    _ = connection
    return NWLinuxCFactory.make_nw_path()
}

public func nw_connection_copy_description(_ connection: nw_connection_t) -> UnsafeMutablePointer<CChar> {
    linuxConnection(connection)?.descriptionText.mutablePointer
        ?? withUnsafeMutablePointer(to: &NWLinuxCStatics.emptyCString) { $0 }
}

public func nw_connection_copy_endpoint(_ connection: nw_connection_t) -> nw_endpoint_t {
    linuxConnection(connection)?.endpoint ?? NWLinuxCFactory.make_nw_endpoint()
}

public func nw_connection_copy_parameters(_ connection: nw_connection_t) -> nw_parameters_t {
    linuxConnection(connection)?.parameters ?? NWLinuxCFactory.make_nw_parameters()
}

public func nw_connection_copy_protocol_metadata(_ connection: nw_connection_t, _ definition: nw_protocol_definition_t) -> nw_protocol_metadata_t? {
    _ = connection
    _ = definition
    return nil
}

public func nw_connection_create(_ endpoint: nw_endpoint_t, _ parameters: nw_parameters_t) -> nw_connection_t {
    let object = _NWLinux_nw_connection()
    object.endpoint = endpoint
    object.parameters = parameters
    if let host = linuxEndpoint(endpoint) {
        object.descriptionText = NWLinuxCString(String(cString: host.hostname.pointer))
    }
    return object
}

public func nw_connection_create_new_data_transfer_report(_ connection: nw_connection_t) -> nw_data_transfer_report_t {
    _ = connection
    return _NWLinux_nw_data_transfer_report()
}

public func nw_connection_force_cancel(_ connection: nw_connection_t) {
    _ = connection
}

public func nw_connection_get_maximum_datagram_size(_ connection: nw_connection_t) -> UInt32 {
    linuxConnection(connection)?.maximumDatagramSize ?? 0
}

public func nw_connection_group_cancel(_ group: nw_connection_group_t) {
    linuxGroup(group)?.cancelled = true
}

public func nw_connection_group_copy_descriptor(_ group: nw_connection_group_t) -> nw_group_descriptor_t {
    linuxGroup(group)?.descriptor ?? NWLinuxCFactory.make_nw_group_descriptor()
}

public func nw_connection_group_copy_local_endpoint_for_message(_ group: nw_connection_group_t, _ context: nw_content_context_t) -> nw_endpoint_t? {
    _ = group
    _ = context
    return nil
}

public func nw_connection_group_copy_parameters(_ group: nw_connection_group_t) -> nw_parameters_t {
    linuxGroup(group)?.parameters ?? NWLinuxCFactory.make_nw_parameters()
}

public func nw_connection_group_copy_path_for_message(_ group: nw_connection_group_t, _ context: nw_content_context_t) -> nw_path_t? {
    _ = group
    _ = context
    return nil
}

public func nw_connection_group_copy_protocol_metadata(_ group: nw_connection_group_t, _ definition: nw_protocol_definition_t) -> nw_protocol_metadata_t? {
    _ = group
    _ = definition
    return nil
}

public func nw_connection_group_copy_protocol_metadata_for_message(_ group: nw_connection_group_t, _ context: nw_content_context_t, _ definition: nw_protocol_definition_t) -> nw_protocol_metadata_t? {
    _ = group
    _ = context
    _ = definition
    return nil
}

public func nw_connection_group_copy_remote_endpoint_for_message(_ group: nw_connection_group_t, _ context: nw_content_context_t) -> nw_endpoint_t? {
    _ = group
    _ = context
    return nil
}

public func nw_connection_group_create(_ group_descriptor: nw_group_descriptor_t, _ parameters: nw_parameters_t) -> nw_connection_group_t {
    let object = _NWLinux_nw_connection_group()
    object.descriptor = group_descriptor
    object.parameters = parameters
    return object
}

public func nw_connection_group_extract_connection(_ group: nw_connection_group_t, _ endpoint: nw_endpoint_t?, _ protocol_options: nw_protocol_options_t?) -> nw_connection_t? {
    _ = group
    _ = endpoint
    _ = protocol_options
    return nil
}

public func nw_connection_group_extract_connection_for_message(_ group: nw_connection_group_t, _ context: nw_content_context_t) -> nw_connection_t? {
    _ = group
    _ = context
    return nil
}

public func nw_connection_group_reinsert_extracted_connection(_ group: nw_connection_group_t, _ connection: nw_connection_t) -> Bool {
    _ = group
    _ = connection
    return false
}

public func nw_connection_group_reply(_ group: nw_connection_group_t, _ inbound_message: nw_content_context_t, _ outbound_message: nw_content_context_t, _ content: dispatch_data_t?) {
    _ = group
    _ = inbound_message
    _ = outbound_message
    _ = content
}

public func nw_connection_group_send_message(_ group: nw_connection_group_t, _ content: dispatch_data_t?, _ endpoint: nw_endpoint_t?, _ context: nw_content_context_t, _ completion: @escaping nw_connection_group_send_completion_t) {
    _ = group
    _ = content
    _ = endpoint
    _ = context
    completion(nwLinuxCError())
}

public func nw_connection_group_set_new_connection_handler(_ group: nw_connection_group_t, _ new_connection_handler: nw_connection_group_new_connection_handler_t?) {
    linuxGroup(group)?.newConnectionHandler = new_connection_handler
}

public func nw_connection_group_set_queue(_ group: nw_connection_group_t, _ queue: dispatch_queue_t) {
    linuxGroup(group)?.queue = queue
}

public func nw_connection_group_set_receive_handler(_ group: nw_connection_group_t, _ maximum_message_size: UInt32, _ reject_oversized_messages: Bool, _ receive_handler: nw_connection_group_receive_handler_t?) {
    _ = maximum_message_size
    _ = reject_oversized_messages
    linuxGroup(group)?.receiveHandler = receive_handler
}

public func nw_connection_group_set_state_changed_handler(_ group: nw_connection_group_t, _ state_changed_handler: nw_connection_group_state_changed_handler_t?) {
    linuxGroup(group)?.stateHandler = state_changed_handler
}

public func nw_connection_group_start(_ group: nw_connection_group_t) {
    guard let stored = linuxGroup(group) else { return }
    stored.started = true
    stored.stateHandler?(nw_connection_group_state_failed, nwLinuxCError())
}

public func nw_connection_receive(_ connection: nw_connection_t, _ minimum_incomplete_length: UInt32, _ maximum_length: UInt32, _ completion: @escaping nw_connection_receive_completion_t) {
    _ = connection
    _ = minimum_incomplete_length
    _ = maximum_length
    _ = completion
    completion(nil, nil, false, nwLinuxCError())
}

public func nw_connection_receive_message(_ connection: nw_connection_t, _ completion: @escaping nw_connection_receive_completion_t) {
    _ = connection
    _ = completion
    completion(nil, nil, false, nwLinuxCError())
}

public func nw_connection_restart(_ connection: nw_connection_t) {
    _ = connection
}

public func nw_connection_send(_ connection: nw_connection_t, _ content: dispatch_data_t?, _ context: nw_content_context_t, _ is_complete: Bool, _ completion: @escaping nw_connection_send_completion_t) {
    _ = connection
    _ = content
    _ = context
    _ = is_complete
    _ = completion
    completion(nwLinuxCError())
}

public func nw_connection_set_better_path_available_handler(_ connection: nw_connection_t, _ handler: nw_connection_boolean_event_handler_t?) {
    _ = connection
    _ = handler
}

public func nw_connection_set_path_changed_handler(_ connection: nw_connection_t, _ handler: nw_connection_path_event_handler_t?) {
    _ = connection
    _ = handler
}

public func nw_connection_set_queue(_ connection: nw_connection_t, _ queue: dispatch_queue_t) {
    _ = connection
    _ = queue
}

public func nw_connection_set_state_changed_handler(_ connection: nw_connection_t, _ handler: nw_connection_state_changed_handler_t?) {
    _ = connection
    _ = handler
}

public func nw_connection_set_viability_changed_handler(_ connection: nw_connection_t, _ handler: nw_connection_boolean_event_handler_t?) {
    _ = connection
    _ = handler
}

public func nw_connection_start(_ connection: nw_connection_t) {
    _ = connection
}

public func nw_content_context_copy_antecedent(_ context: nw_content_context_t) -> nw_content_context_t? {
    linuxContext(context)?.antecedent
}

public func nw_content_context_copy_protocol_metadata(_ context: nw_content_context_t, _ protocol: nw_protocol_definition_t) -> nw_protocol_metadata_t? {
    _ = `protocol`
    return linuxContext(context)?.protocolMetadata.first
}

public func nw_content_context_create(_ context_identifier: UnsafePointer<CChar>) -> nw_content_context_t {
    let object = _NWLinux_nw_content_context()
    object.identifier = NWLinuxCString(String(cString: context_identifier))
    return object
}

public func nw_content_context_foreach_protocol_metadata(_ context: nw_content_context_t, _ foreach_block: @escaping (nw_protocol_definition_t, nw_protocol_metadata_t) -> Void) {
    guard let stored = linuxContext(context) else { return }
    for metadata in stored.protocolMetadata {
        foreach_block(linuxMetadata(metadata)?.definition ?? NWLinuxCFactory.make_nw_protocol_definition(), metadata)
    }
}

public func nw_content_context_get_expiration_milliseconds(_ context: nw_content_context_t) -> UInt64 {
    linuxContext(context)?.expirationMilliseconds ?? 0
}

public func nw_content_context_get_identifier(_ context: nw_content_context_t) -> UnsafePointer<CChar> {
    linuxContext(context)?.identifier.pointer ?? withUnsafePointer(to: &NWLinuxCStatics.emptyCString) { $0 }
}

public func nw_content_context_get_is_final(_ context: nw_content_context_t) -> Bool {
    linuxContext(context)?.isFinal ?? false
}

public func nw_content_context_get_relative_priority(_ context: nw_content_context_t) -> Double {
    linuxContext(context)?.relativePriority ?? 0
}

public func nw_content_context_set_antecedent(_ context: nw_content_context_t, _ antecedent_context: nw_content_context_t?) {
    linuxContext(context)?.antecedent = antecedent_context
}

public func nw_content_context_set_expiration_milliseconds(_ context: nw_content_context_t, _ expiration_milliseconds: UInt64) {
    linuxContext(context)?.expirationMilliseconds = expiration_milliseconds
}

public func nw_content_context_set_is_final(_ context: nw_content_context_t, _ is_final: Bool) {
    linuxContext(context)?.isFinal = is_final
}

public func nw_content_context_set_metadata_for_protocol(_ context: nw_content_context_t, _ protocol_metadata: nw_protocol_metadata_t) {
    linuxContext(context)?.protocolMetadata.append(protocol_metadata)
}

public func nw_content_context_set_relative_priority(_ context: nw_content_context_t, _ relative_priority: Double) {
    linuxContext(context)?.relativePriority = relative_priority
}

public func nw_data_transfer_report_collect(_ report: nw_data_transfer_report_t, _ queue: dispatch_queue_t, _ collect_block: @escaping nw_data_transfer_report_collect_block_t) {
    _ = queue
    linuxReport(report)?.state = nw_data_transfer_report_state_collected
    collect_block(report)
}

public func nw_data_transfer_report_copy_path_interface(_ report: nw_data_transfer_report_t, _ path_index: UInt32) -> nw_interface_t {
    _ = report
    _ = path_index
    return linuxLoopbackInterface()
}

public func nw_data_transfer_report_get_duration_milliseconds(_ report: nw_data_transfer_report_t) -> UInt64 {
    _ = report
    return 0
}

public func nw_data_transfer_report_get_path_count(_ report: nw_data_transfer_report_t) -> UInt32 {
    _ = report
    return 1
}

public func nw_data_transfer_report_get_path_radio_type(_ report: nw_data_transfer_report_t, _ path_index: UInt32) -> nw_interface_radio_type_t {
    _ = report
    _ = path_index
    return nw_interface_radio_type_t(rawValue: 0)
}

public func nw_data_transfer_report_get_received_application_byte_count(_ report: nw_data_transfer_report_t, _ path_index: UInt32) -> UInt64 {
    _ = report
    _ = path_index
    return 0
}

public func nw_data_transfer_report_get_received_ip_packet_count(_ report: nw_data_transfer_report_t, _ path_index: UInt32) -> UInt64 {
    _ = report
    _ = path_index
    return 0
}

public func nw_data_transfer_report_get_received_transport_byte_count(_ report: nw_data_transfer_report_t, _ path_index: UInt32) -> UInt64 {
    _ = report
    _ = path_index
    return 0
}

public func nw_data_transfer_report_get_received_transport_duplicate_byte_count(_ report: nw_data_transfer_report_t, _ path_index: UInt32) -> UInt64 {
    _ = report
    _ = path_index
    return 0
}

public func nw_data_transfer_report_get_received_transport_out_of_order_byte_count(_ report: nw_data_transfer_report_t, _ path_index: UInt32) -> UInt64 {
    _ = report
    _ = path_index
    return 0
}

public func nw_data_transfer_report_get_sent_application_byte_count(_ report: nw_data_transfer_report_t, _ path_index: UInt32) -> UInt64 {
    _ = report
    _ = path_index
    return 0
}

public func nw_data_transfer_report_get_sent_ip_packet_count(_ report: nw_data_transfer_report_t, _ path_index: UInt32) -> UInt64 {
    _ = report
    _ = path_index
    return 0
}

public func nw_data_transfer_report_get_sent_transport_byte_count(_ report: nw_data_transfer_report_t, _ path_index: UInt32) -> UInt64 {
    _ = report
    _ = path_index
    return 0
}

public func nw_data_transfer_report_get_sent_transport_retransmitted_byte_count(_ report: nw_data_transfer_report_t, _ path_index: UInt32) -> UInt64 {
    _ = report
    _ = path_index
    return 0
}

public func nw_data_transfer_report_get_state(_ report: nw_data_transfer_report_t) -> nw_data_transfer_report_state_t {
    linuxReport(report)?.state ?? nw_data_transfer_report_state_collecting
}

public func nw_data_transfer_report_get_transport_minimum_rtt_milliseconds(_ report: nw_data_transfer_report_t, _ path_index: UInt32) -> UInt64 {
    _ = report
    _ = path_index
    return 0
}

public func nw_data_transfer_report_get_transport_rtt_variance(_ report: nw_data_transfer_report_t, _ path_index: UInt32) -> UInt64 {
    _ = report
    _ = path_index
    return 0
}

public func nw_data_transfer_report_get_transport_smoothed_rtt_milliseconds(_ report: nw_data_transfer_report_t, _ path_index: UInt32) -> UInt64 {
    _ = report
    _ = path_index
    return 0
}

public func nw_endpoint_copy_address_string(_ endpoint: nw_endpoint_t) -> UnsafeMutablePointer<CChar> {
    linuxEndpoint(endpoint)?.addressString.mutablePointer
        ?? withUnsafeMutablePointer(to: &NWLinuxCStatics.emptyCString) { $0 }
}

public func nw_endpoint_copy_port_string(_ endpoint: nw_endpoint_t) -> UnsafeMutablePointer<CChar> {
    linuxEndpoint(endpoint)?.portString.mutablePointer
        ?? withUnsafeMutablePointer(to: &NWLinuxCStatics.emptyCString) { $0 }
}

public func nw_endpoint_copy_txt_record(_ endpoint: nw_endpoint_t) -> nw_txt_record_t? {
    linuxEndpoint(endpoint)?.txtRecord
}

public func nw_endpoint_create_address(_ address: UnsafePointer<sockaddr>) -> nw_endpoint_t {
    let object = _NWLinux_nw_endpoint()
    object.type = nw_endpoint_type_address
    object.storeSockaddr(address)
    let family = Int32(address.pointee.sa_family)
    if family == Int32(AF_INET) {
        address.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { sin in
            object.port = UInt16(bigEndian: sin.pointee.sin_port)
            var buffer = [CChar](repeating: 0, count: 16)
            var addr = sin.pointee.sin_addr
            _ = inet_ntop(AF_INET, &addr, &buffer, 16)
            object.addressString = NWLinuxCString(String(cString: buffer))
            object.portString = NWLinuxCString(String(object.port))
        }
    } else if family == Int32(AF_INET6) {
        address.withMemoryRebound(to: sockaddr_in6.self, capacity: 1) { sin6 in
            object.port = UInt16(bigEndian: sin6.pointee.sin6_port)
            var buffer = [CChar](repeating: 0, count: 46)
            var addr = sin6.pointee.sin6_addr
            _ = inet_ntop(AF_INET6, &addr, &buffer, 46)
            object.addressString = NWLinuxCString(String(cString: buffer))
            object.portString = NWLinuxCString(String(object.port))
        }
    }
    return object
}

public func nw_endpoint_create_bonjour_service(_ name: UnsafePointer<CChar>, _ type: UnsafePointer<CChar>, _ domain: UnsafePointer<CChar>) -> nw_endpoint_t {
    let object = _NWLinux_nw_endpoint()
    object.type = nw_endpoint_type_bonjour_service
    object.bonjourName = NWLinuxCString(String(cString: name))
    object.bonjourType = NWLinuxCString(String(cString: type))
    object.bonjourDomain = NWLinuxCString(String(cString: domain))
    return object
}

public func nw_endpoint_create_host(_ hostname: UnsafePointer<CChar>, _ port: UnsafePointer<CChar>) -> nw_endpoint_t {
    let object = _NWLinux_nw_endpoint()
    object.type = nw_endpoint_type_host
    object.hostname = NWLinuxCString(String(cString: hostname))
    object.portString = NWLinuxCString(String(cString: port))
    object.port = UInt16(String(cString: port)) ?? 0
    object.addressString = NWLinuxCString(String(cString: hostname))
    return object
}

public func nw_endpoint_create_url(_ url: UnsafePointer<CChar>) -> nw_endpoint_t {
    let object = _NWLinux_nw_endpoint()
    object.type = nw_endpoint_type_url
    object.url = NWLinuxCString(String(cString: url))
    return object
}

public func nw_endpoint_get_address(_ endpoint: nw_endpoint_t) -> UnsafePointer<sockaddr> {
    linuxEndpoint(endpoint)?.sockaddrPointer
        ?? withUnsafePointer(to: &NWLinuxCStatics.sockaddrStorage) { $0 }
}

public func nw_endpoint_get_bonjour_service_domain(_ endpoint: nw_endpoint_t) -> UnsafePointer<CChar> {
    linuxEndpoint(endpoint)?.bonjourDomain.pointer
        ?? withUnsafePointer(to: &NWLinuxCStatics.emptyCString) { $0 }
}

public func nw_endpoint_get_bonjour_service_name(_ endpoint: nw_endpoint_t) -> UnsafePointer<CChar> {
    linuxEndpoint(endpoint)?.bonjourName.pointer
        ?? withUnsafePointer(to: &NWLinuxCStatics.emptyCString) { $0 }
}

public func nw_endpoint_get_bonjour_service_type(_ endpoint: nw_endpoint_t) -> UnsafePointer<CChar> {
    linuxEndpoint(endpoint)?.bonjourType.pointer
        ?? withUnsafePointer(to: &NWLinuxCStatics.emptyCString) { $0 }
}

public func nw_endpoint_get_hostname(_ endpoint: nw_endpoint_t) -> UnsafePointer<CChar> {
    linuxEndpoint(endpoint)?.hostname.pointer
        ?? withUnsafePointer(to: &NWLinuxCStatics.emptyCString) { $0 }
}

public func nw_endpoint_get_port(_ endpoint: nw_endpoint_t) -> UInt16 {
    linuxEndpoint(endpoint)?.port ?? 0
}

public func nw_endpoint_get_signature(_ endpoint: nw_endpoint_t, _ out_signature_length: UnsafeMutablePointer<Int>) -> UnsafePointer<UInt8>? {
    _ = endpoint
    out_signature_length.pointee = 0
    return nil
}

public func nw_endpoint_get_type(_ endpoint: nw_endpoint_t) -> nw_endpoint_type_t {
    linuxEndpoint(endpoint)?.type ?? nw_endpoint_type_invalid
}

public func nw_endpoint_get_url(_ endpoint: nw_endpoint_t) -> UnsafePointer<CChar> {
    linuxEndpoint(endpoint)?.url.pointer
        ?? withUnsafePointer(to: &NWLinuxCStatics.emptyCString) { $0 }
}

public func nw_error_copy_cf_error(_ error: nw_error_t) -> Unmanaged<CFError> {
    let stored = linuxError(error)
    let domain: String
    switch stored?.domain.rawValue {
    case nw_error_domain_dns.rawValue: domain = String(kNWErrorDomainDNS)
    case nw_error_domain_tls.rawValue: domain = String(kNWErrorDomainTLS)
    case nw_error_domain_wifi_aware.rawValue: domain = String(kNWErrorDomainWiFiAware)
    default: domain = String(kNWErrorDomainPOSIX)
    }
    let code = Int(stored?.code ?? Int32(POSIXErrorCode.EOPNOTSUPP.rawValue))
    return Unmanaged.passRetained(NSError(domain: domain, code: code) as CFError)
}

public func nw_error_get_error_code(_ error: nw_error_t) -> Int32 {
    linuxError(error)?.code ?? 0
}

public func nw_error_get_error_domain(_ error: nw_error_t) -> nw_error_domain_t {
    linuxError(error)?.domain ?? nw_error_domain_invalid
}

private func linuxEstablishment(_ report: nw_establishment_report_t) -> _NWLinux_nw_establishment_report? {
    report as? _NWLinux_nw_establishment_report
}

public func nw_establishment_report_copy_proxy_endpoint(_ report: nw_establishment_report_t) -> nw_endpoint_t? {
    linuxEstablishment(report)?.proxyEndpoint
}

public func nw_establishment_report_enumerate_protocols(_ report: nw_establishment_report_t, _ enumerate_block: (nw_protocol_definition_t, UInt64, UInt64) -> Bool) {
    guard let stored = linuxEstablishment(report) else { return }
    for item in stored.protocols {
        if !enumerate_block(item.0, item.1, item.2) { return }
    }
}

public func nw_establishment_report_enumerate_resolution_reports(_ report: nw_establishment_report_t, _ enumerate_block: (nw_resolution_report_t) -> Bool) {
    guard let stored = linuxEstablishment(report) else { return }
    for item in stored.resolutionReports {
        if !enumerate_block(item) { return }
    }
}

public func nw_establishment_report_enumerate_resolutions(_ report: nw_establishment_report_t, _ enumerate_block: (nw_report_resolution_source_t, UInt64, UInt32, nw_endpoint_t, nw_endpoint_t) -> Bool) {
    guard let stored = linuxEstablishment(report) else { return }
    for item in stored.resolutions {
        if !enumerate_block(item.0, item.1, item.2, item.3, item.4) { return }
    }
}

public func nw_establishment_report_get_attempt_started_after_milliseconds(_ report: nw_establishment_report_t) -> UInt64 {
    linuxEstablishment(report)?.attemptStartedAfterMilliseconds ?? 0
}

public func nw_establishment_report_get_duration_milliseconds(_ report: nw_establishment_report_t) -> UInt64 {
    linuxEstablishment(report)?.durationMilliseconds ?? 0
}

public func nw_establishment_report_get_previous_attempt_count(_ report: nw_establishment_report_t) -> UInt32 {
    linuxEstablishment(report)?.previousAttemptCount ?? 0
}

public func nw_establishment_report_get_proxy_configured(_ report: nw_establishment_report_t) -> Bool {
    linuxEstablishment(report)?.proxyConfigured ?? false
}

public func nw_establishment_report_get_used_proxy(_ report: nw_establishment_report_t) -> Bool {
    linuxEstablishment(report)?.usedProxy ?? false
}

public func nw_framer_async(_ framer: nw_framer_t, _ async_block: @escaping nw_framer_block_t) {
    _ = framer
    async_block()
}

public func nw_framer_copy_local_endpoint(_ framer: nw_framer_t) -> nw_endpoint_t {
    linuxFramer(framer)?.localEndpoint ?? NWLinuxCFactory.make_nw_endpoint()
}

public func nw_framer_copy_options(_ framer: nw_framer_t) -> nw_protocol_options_t {
    linuxFramer(framer)?.options ?? NWLinuxCFactory.make_nw_protocol_options()
}

public func nw_framer_copy_parameters(_ framer: nw_framer_t) -> nw_parameters_t {
    linuxFramer(framer)?.parameters ?? NWLinuxCFactory.make_nw_parameters()
}

public func nw_framer_copy_remote_endpoint(_ framer: nw_framer_t) -> nw_endpoint_t {
    linuxFramer(framer)?.remoteEndpoint ?? NWLinuxCFactory.make_nw_endpoint()
}

public func nw_framer_create_definition(_ identifier: UnsafePointer<CChar>, _ flags: UInt32, _ start_handler: @escaping nw_framer_start_handler_t) -> nw_protocol_definition_t {
    _ = flags
    let definition = linuxNamedDefinition(String(cString: identifier))
    let framer = _NWLinux_nw_framer()
    _ = start_handler(framer)
    return definition
}

public func nw_framer_create_options(_ framer_definition: nw_protocol_definition_t) -> nw_protocol_options_t {
    let options = _NWLinux_nw_protocol_options()
    options.framerDefinition = framer_definition
    return options
}

public func nw_framer_deliver_input(_ framer: nw_framer_t, _ input_buffer: UnsafePointer<UInt8>, _ input_length: Int, _ message: nw_framer_message_t, _ is_complete: Bool) {
    _ = message
    _ = is_complete
    guard let stored = linuxFramer(framer), input_length > 0 else { return }
    stored.input.append(Data(bytes: input_buffer, count: input_length))
}

public func nw_framer_deliver_input_no_copy(_ framer: nw_framer_t, _ input_length: Int, _ message: nw_framer_message_t, _ is_complete: Bool) -> Bool {
    _ = message
    _ = is_complete
    guard let stored = linuxFramer(framer) else { return false }
    return stored.input.count - stored.inputOffset >= input_length
}

public func nw_framer_mark_failed_with_error(_ framer: nw_framer_t, _ error_code: Int32) {
    linuxFramer(framer)?.failedCode = error_code
    linuxFramer(framer)?.ready = false
}

public func nw_framer_mark_ready(_ framer: nw_framer_t) {
    linuxFramer(framer)?.ready = true
}

public func nw_framer_message_access_value(_ message: nw_framer_message_t, _ key: UnsafePointer<CChar>, _ access_value: (UnsafeRawPointer?) -> Bool) -> Bool {
    let name = String(cString: key)
    let pointer = linuxMetadata(message)?.rawValues[name]
    return access_value(pointer.map { UnsafeRawPointer($0) })
}

public func nw_framer_message_copy_object_value(_ message: nw_framer_message_t, _ key: UnsafePointer<CChar>) -> Any? {
    linuxMetadata(message)?.objectValues[String(cString: key)]
}

public func nw_framer_message_create(_ framer: nw_framer_t) -> nw_framer_message_t {
    _ = framer
    let message = _NWLinux_nw_protocol_metadata()
    message.kind = "framer"
    return message
}

public func nw_framer_message_set_object_value(_ message: nw_framer_message_t, _ key: UnsafePointer<CChar>, _ value: Any?) {
    linuxMetadata(message)?.objectValues[String(cString: key)] = value as Any
}

public func nw_framer_message_set_value(_ message: nw_framer_message_t, _ key: UnsafePointer<CChar>, _ value: UnsafeMutableRawPointer?, _ dispose_value: nw_framer_message_dispose_value_t?) {
    _ = dispose_value
    guard let stored = linuxMetadata(message) else { return }
    stored.rawValues[String(cString: key)] = value
}

public func nw_framer_options_copy_object_value(_ options: nw_protocol_options_t, _ key: UnsafePointer<CChar>) -> Any? {
    linuxOptions(options)?.framerObjectValues[String(cString: key)]
}

public func nw_framer_options_set_object_value(_ options: nw_protocol_options_t, _ key: UnsafePointer<CChar>, _ value: Any?) {
    linuxOptions(options)?.framerObjectValues[String(cString: key)] = value as Any
}

public func nw_framer_parse_input(_ framer: nw_framer_t, _ minimum_incomplete_length: Int, _ maximum_length: Int, _ temp_buffer: UnsafeMutablePointer<UInt8>?, _ parse: (UnsafeMutablePointer<UInt8>?, Int, Bool) -> Int) -> Bool {
    guard let stored = linuxFramer(framer) else { return false }
    let available = stored.input.count - stored.inputOffset
    if available < minimum_incomplete_length { return false }
    let amount = min(max(available, 0), max(maximum_length, 0))
    if let temp_buffer, amount > 0 {
        stored.input.copyBytes(to: temp_buffer, from: stored.inputOffset..<(stored.inputOffset + amount))
    }
    let consumed = parse(temp_buffer, amount, true)
    if consumed > 0 {
        stored.inputOffset += min(consumed, amount)
    }
    return consumed > 0
}

public func nw_framer_parse_output(_ framer: nw_framer_t, _ minimum_incomplete_length: Int, _ maximum_length: Int, _ temp_buffer: UnsafeMutablePointer<UInt8>?, _ parse: (UnsafeMutablePointer<UInt8>?, Int, Bool) -> Int) -> Bool {
    guard let stored = linuxFramer(framer) else { return false }
    if stored.output.count < minimum_incomplete_length { return false }
    let amount = min(stored.output.count, max(maximum_length, 0))
    if let temp_buffer, amount > 0 {
        stored.output.copyBytes(to: temp_buffer, from: 0..<amount)
    }
    let consumed = parse(temp_buffer, amount, true)
    return consumed > 0
}

public func nw_framer_pass_through_input(_ framer: nw_framer_t) {
    linuxFramer(framer)?.passThroughInput = true
}

public func nw_framer_pass_through_output(_ framer: nw_framer_t) {
    linuxFramer(framer)?.passThroughOutput = true
}

public func nw_framer_prepend_application_protocol(_ framer: nw_framer_t, _ protocol_options: nw_protocol_options_t) -> Bool {
    _ = framer
    _ = protocol_options
    return false
}

public func nw_framer_protocol_create_message(_ definition: nw_protocol_definition_t) -> nw_framer_message_t {
    let message = _NWLinux_nw_protocol_metadata()
    message.kind = "framer"
    message.definition = definition
    return message
}

public func nw_framer_schedule_wakeup(_ framer: nw_framer_t, _ milliseconds: UInt64) {
    guard let stored = linuxFramer(framer) else { return }
    stored.wakeupMilliseconds = milliseconds
    stored.wakeupHandler?(framer)
}

public func nw_framer_set_cleanup_handler(_ framer: nw_framer_t, _ cleanup_handler: @escaping nw_framer_cleanup_handler_t) {
    linuxFramer(framer)?.cleanupHandler = cleanup_handler
}

public func nw_framer_set_input_handler(_ framer: nw_framer_t, _ input_handler: @escaping nw_framer_input_handler_t) {
    linuxFramer(framer)?.inputHandler = input_handler
}

public func nw_framer_set_output_handler(_ framer: nw_framer_t, _ output_handler: @escaping nw_framer_output_handler_t) {
    linuxFramer(framer)?.outputHandler = output_handler
}

public func nw_framer_set_stop_handler(_ framer: nw_framer_t, _ stop_handler: @escaping nw_framer_stop_handler_t) {
    linuxFramer(framer)?.stopHandler = stop_handler
}

public func nw_framer_set_wakeup_handler(_ framer: nw_framer_t, _ wakeup_handler: @escaping nw_framer_wakeup_handler_t) {
    linuxFramer(framer)?.wakeupHandler = wakeup_handler
}

public func nw_framer_write_output(_ framer: nw_framer_t, _ output_buffer: UnsafePointer<UInt8>, _ output_length: Int) {
    guard let stored = linuxFramer(framer), output_length > 0 else { return }
    stored.output.append(Data(bytes: output_buffer, count: output_length))
}

public func nw_framer_write_output_data(_ framer: nw_framer_t, _ output_data: dispatch_data_t) {
    guard let stored = linuxFramer(framer) else { return }
    stored.output.append(Data(output_data))
}

public func nw_framer_write_output_no_copy(_ framer: nw_framer_t, _ output_length: Int) -> Bool {
    guard let stored = linuxFramer(framer) else { return false }
    _ = output_length
    return stored.ready || stored.output.count >= 0
}

public func nw_group_descriptor_add_endpoint(_ descriptor: nw_group_descriptor_t, _ endpoint: nw_endpoint_t) -> Bool {
    guard let stored = linuxGroupDescriptor(descriptor) else { return false }
    stored.endpoints.append(endpoint)
    return true
}

public func nw_group_descriptor_create_multicast(_ multicast_group: nw_endpoint_t) -> nw_group_descriptor_t {
    let object = _NWLinux_nw_group_descriptor()
    object.isMulticast = true
    object.endpoints = [multicast_group]
    return object
}

public func nw_group_descriptor_create_multiplex(_ remote_endpoint: nw_endpoint_t) -> nw_group_descriptor_t {
    let object = _NWLinux_nw_group_descriptor()
    object.endpoints = [remote_endpoint]
    return object
}

public func nw_group_descriptor_enumerate_endpoints(_ descriptor: nw_group_descriptor_t, _ enumerate_block: (nw_endpoint_t) -> Bool) {
    guard let stored = linuxGroupDescriptor(descriptor) else { return }
    for endpoint in stored.endpoints {
        if !enumerate_block(endpoint) { return }
    }
}

public func nw_interface_get_index(_ interface: nw_interface_t) -> UInt32 {
    linuxInterface(interface)?.index ?? 0
}

public func nw_interface_get_name(_ interface: nw_interface_t) -> UnsafePointer<CChar> {
    linuxInterface(interface)?.name.pointer
        ?? withUnsafePointer(to: &NWLinuxCStatics.emptyCString) { $0 }
}

public func nw_interface_get_type(_ interface: nw_interface_t) -> nw_interface_type_t {
    linuxInterface(interface)?.type ?? nw_interface_type_other
}

public func nw_ip_create_metadata() -> nw_protocol_metadata_t {
    let metadata = _NWLinux_nw_protocol_metadata()
    metadata.kind = "ip"
    return metadata
}

public func nw_ip_metadata_get_ecn_flag(_ metadata: nw_protocol_metadata_t) -> nw_ip_ecn_flag_t {
    linuxMetadata(metadata)?.ipECN ?? nw_ip_ecn_flag_non_ect
}

public func nw_ip_metadata_get_receive_time(_ metadata: nw_protocol_metadata_t) -> UInt64 {
    linuxMetadata(metadata)?.ipReceiveTime ?? 0
}

public func nw_ip_metadata_get_service_class(_ metadata: nw_protocol_metadata_t) -> nw_service_class_t {
    linuxMetadata(metadata)?.ipServiceClass ?? nw_service_class_best_effort
}

public func nw_ip_metadata_set_ecn_flag(_ metadata: nw_protocol_metadata_t, _ ecn_flag: nw_ip_ecn_flag_t) {
    linuxMetadata(metadata)?.ipECN = ecn_flag
}

public func nw_ip_metadata_set_service_class(_ metadata: nw_protocol_metadata_t, _ service_class: nw_service_class_t) {
    linuxMetadata(metadata)?.ipServiceClass = service_class
}

public func nw_ip_options_set_calculate_receive_time(_ options: nw_protocol_options_t, _ calculate_receive_time: Bool) {
    _ = options
    _ = calculate_receive_time
}

public func nw_ip_options_set_disable_fragmentation(_ options: nw_protocol_options_t, _ disable_fragmentation: Bool) {
    _ = options
    _ = disable_fragmentation
}

public func nw_ip_options_set_disable_multicast_loopback(_ options: nw_protocol_options_t, _ disable_multicast_loopback: Bool) {
    _ = options
    _ = disable_multicast_loopback
}

public func nw_ip_options_set_hop_limit(_ options: nw_protocol_options_t, _ hop_limit: UInt8) {
    _ = options
    _ = hop_limit
}

public func nw_ip_options_set_local_address_preference(_ options: nw_protocol_options_t, _ preference: nw_ip_local_address_preference_t) {
    _ = options
    _ = preference
}

public func nw_ip_options_set_use_minimum_mtu(_ options: nw_protocol_options_t, _ use_minimum_mtu: Bool) {
    _ = options
    _ = use_minimum_mtu
}

public func nw_ip_options_set_version(_ options: nw_protocol_options_t, _ version: nw_ip_version_t) {
    _ = options
    _ = version
}

public func nw_listener_cancel(_ listener: nw_listener_t) {
    _ = listener
}

public func nw_listener_create(_ parameters: nw_parameters_t) -> nw_listener_t? {
    _ = parameters
    return NWLinuxCFactory.make_nw_listener()
}

public func nw_listener_create_with_connection(_ connection: nw_connection_t, _ parameters: nw_parameters_t) -> nw_listener_t? {
    _ = connection
    _ = parameters
    return NWLinuxCFactory.make_nw_listener()
}

public func nw_listener_create_with_port(_ port: UnsafePointer<CChar>, _ parameters: nw_parameters_t) -> nw_listener_t? {
    _ = port
    _ = parameters
    return NWLinuxCFactory.make_nw_listener()
}

public func nw_listener_get_new_connection_limit(_ listener: nw_listener_t) -> UInt32 {
    _ = listener
    return 0
}

public func nw_listener_get_port(_ listener: nw_listener_t) -> UInt16 {
    _ = listener
    return 0
}

public func nw_listener_set_advertise_descriptor(_ listener: nw_listener_t, _ advertise_descriptor: nw_advertise_descriptor_t?) {
    _ = listener
    _ = advertise_descriptor
}

public func nw_listener_set_advertised_endpoint_changed_handler(_ listener: nw_listener_t, _ handler: nw_listener_advertised_endpoint_changed_handler_t?) {
    _ = listener
    _ = handler
}

public func nw_listener_set_new_connection_group_handler(_ listener: nw_listener_t, _ handler: nw_listener_new_connection_group_handler_t?) {
    _ = listener
    _ = handler
}

public func nw_listener_set_new_connection_handler(_ listener: nw_listener_t, _ handler: nw_listener_new_connection_handler_t?) {
    _ = listener
    _ = handler
}

public func nw_listener_set_new_connection_limit(_ listener: nw_listener_t, _ new_connection_limit: UInt32) {
    _ = listener
    _ = new_connection_limit
}

public func nw_listener_set_queue(_ listener: nw_listener_t, _ queue: dispatch_queue_t) {
    _ = listener
    _ = queue
}

public func nw_listener_set_state_changed_handler(_ listener: nw_listener_t, _ handler: nw_listener_state_changed_handler_t?) {
    _ = listener
    _ = handler
}

public func nw_listener_start(_ listener: nw_listener_t) {
    _ = listener
}

public func nw_multicast_group_descriptor_get_disable_unicast_traffic(_ multicast_descriptor: nw_group_descriptor_t) -> Bool {
    linuxGroupDescriptor(multicast_descriptor)?.disableUnicast ?? false
}

public func nw_multicast_group_descriptor_set_disable_unicast_traffic(_ multicast_descriptor: nw_group_descriptor_t, _ disable_unicast_traffic: Bool) {
    linuxGroupDescriptor(multicast_descriptor)?.disableUnicast = disable_unicast_traffic
}

public func nw_multicast_group_descriptor_set_specific_source(_ multicast_descriptor: nw_group_descriptor_t, _ source: nw_endpoint_t) {
    linuxGroupDescriptor(multicast_descriptor)?.specificSource = source
}

public func nw_parameters_clear_prohibited_interface_types(_ parameters: nw_parameters_t) {
    _ = parameters
}

public func nw_parameters_clear_prohibited_interfaces(_ parameters: nw_parameters_t) {
    _ = parameters
}

public func nw_parameters_copy(_ parameters: nw_parameters_t) -> nw_parameters_t {
    _ = parameters
    return NWLinuxCFactory.make_nw_parameters()
}

public func nw_parameters_copy_default_protocol_stack(_ parameters: nw_parameters_t) -> nw_protocol_stack_t {
    _ = parameters
    return NWLinuxCFactory.make_nw_protocol_stack()
}

public func nw_parameters_copy_local_endpoint(_ parameters: nw_parameters_t) -> nw_endpoint_t? {
    linuxParameters(parameters)?.localEndpoint
}

public func nw_parameters_copy_required_interface(_ parameters: nw_parameters_t) -> nw_interface_t? {
    linuxParameters(parameters)?.requiredInterface
}

public func nw_parameters_create() -> nw_parameters_t {
    return NWLinuxCFactory.make_nw_parameters()
}

public func nw_parameters_create_application_service() -> nw_parameters_t {
    return NWLinuxCFactory.make_nw_parameters()
}

public func nw_parameters_create_quic(_ configure_quic: @escaping nw_parameters_configure_protocol_block_t) -> nw_parameters_t {
    configure_quic(NWLinuxCFactory.make_nw_protocol_options())
    return NWLinuxCFactory.make_nw_parameters()
}

public func nw_parameters_create_secure_tcp(_ configure_tls: @escaping nw_parameters_configure_protocol_block_t, _ configure_tcp: @escaping nw_parameters_configure_protocol_block_t) -> nw_parameters_t {
    configure_tls(NWLinuxCFactory.make_nw_protocol_options())
    configure_tcp(NWLinuxCFactory.make_nw_protocol_options())
    return NWLinuxCFactory.make_nw_parameters()
}

public func nw_parameters_create_secure_udp(_ configure_dtls: @escaping nw_parameters_configure_protocol_block_t, _ configure_udp: @escaping nw_parameters_configure_protocol_block_t) -> nw_parameters_t {
    configure_dtls(NWLinuxCFactory.make_nw_protocol_options())
    configure_udp(NWLinuxCFactory.make_nw_protocol_options())
    return NWLinuxCFactory.make_nw_parameters()
}

public func nw_parameters_get_allow_ultra_constrained(_ parameters: nw_parameters_t) -> Bool {
    linuxParameters(parameters)?.allowUltraConstrained ?? false
}

public func nw_parameters_get_attribution(_ parameters: nw_parameters_t) -> nw_parameters_attribution_t {
    linuxParameters(parameters)?.attribution ?? .developer
}

public func nw_parameters_get_expired_dns_behavior(_ parameters: nw_parameters_t) -> nw_parameters_expired_dns_behavior_t {
    linuxParameters(parameters)?.expiredDNSBehavior ?? nw_parameters_expired_dns_behavior_t(rawValue: 0)
}

public func nw_parameters_get_fast_open_enabled(_ parameters: nw_parameters_t) -> Bool {
    linuxParameters(parameters)?.fastOpenEnabled ?? false
}

public func nw_parameters_get_include_peer_to_peer(_ parameters: nw_parameters_t) -> Bool {
    linuxParameters(parameters)?.includePeerToPeer ?? false
}

public func nw_parameters_get_local_only(_ parameters: nw_parameters_t) -> Bool {
    linuxParameters(parameters)?.localOnly ?? false
}

public func nw_parameters_get_multipath_service(_ parameters: nw_parameters_t) -> nw_multipath_service_t {
    linuxParameters(parameters)?.multipathService ?? nw_multipath_service_t(rawValue: 0)
}

public func nw_parameters_get_prefer_no_proxy(_ parameters: nw_parameters_t) -> Bool {
    linuxParameters(parameters)?.preferNoProxy ?? false
}

public func nw_parameters_get_prohibit_constrained(_ parameters: nw_parameters_t) -> Bool {
    linuxParameters(parameters)?.prohibitConstrained ?? false
}

public func nw_parameters_get_prohibit_expensive(_ parameters: nw_parameters_t) -> Bool {
    linuxParameters(parameters)?.prohibitExpensive ?? false
}

public func nw_parameters_get_required_interface_type(_ parameters: nw_parameters_t) -> nw_interface_type_t {
    linuxParameters(parameters)?.requiredInterfaceType ?? nw_interface_type_other
}

public func nw_parameters_get_reuse_local_address(_ parameters: nw_parameters_t) -> Bool {
    linuxParameters(parameters)?.reuseLocalAddress ?? false
}

public func nw_parameters_get_service_class(_ parameters: nw_parameters_t) -> nw_service_class_t {
    linuxParameters(parameters)?.serviceClass ?? nw_service_class_best_effort
}

public func nw_parameters_iterate_prohibited_interface_types(_ parameters: nw_parameters_t, _ iterate_block: (nw_interface_type_t) -> Bool) {
    _ = parameters
    _ = iterate_block
}

public func nw_parameters_iterate_prohibited_interfaces(_ parameters: nw_parameters_t, _ iterate_block: (nw_interface_t) -> Bool) {
    _ = parameters
    _ = iterate_block
}

public func nw_parameters_prohibit_interface(_ parameters: nw_parameters_t, _ interface: nw_interface_t) {
    linuxParameters(parameters)?.prohibitedInterfaces.append(interface)
}

public func nw_parameters_prohibit_interface_type(_ parameters: nw_parameters_t, _ interface_type: nw_interface_type_t) {
    _ = parameters
    _ = interface_type
}

public func nw_parameters_require_interface(_ parameters: nw_parameters_t, _ interface: nw_interface_t?) {
    linuxParameters(parameters)?.requiredInterface = interface
}

public func nw_parameters_requires_dnssec_validation(_ parameters: nw_parameters_t) -> Bool {
    linuxParameters(parameters)?.requiresDNSSECValidation ?? false
}

public func nw_parameters_set_allow_ultra_constrained(_ parameters: nw_parameters_t, _ allow_ultra_constrained: Bool) {
    linuxParameters(parameters)?.allowUltraConstrained = allow_ultra_constrained
}

public func nw_parameters_set_attribution(_ parameters: nw_parameters_t, _ attribution: nw_parameters_attribution_t) {
    linuxParameters(parameters)?.attribution = attribution
}

public func nw_parameters_set_expired_dns_behavior(_ parameters: nw_parameters_t, _ expired_dns_behavior: nw_parameters_expired_dns_behavior_t) {
    linuxParameters(parameters)?.expiredDNSBehavior = expired_dns_behavior
}

public func nw_parameters_set_fast_open_enabled(_ parameters: nw_parameters_t, _ fast_open_enabled: Bool) {
    linuxParameters(parameters)?.fastOpenEnabled = fast_open_enabled
}

public func nw_parameters_set_include_peer_to_peer(_ parameters: nw_parameters_t, _ include_peer_to_peer: Bool) {
    linuxParameters(parameters)?.includePeerToPeer = include_peer_to_peer
}

public func nw_parameters_set_local_endpoint(_ parameters: nw_parameters_t, _ local_endpoint: nw_endpoint_t?) {
    linuxParameters(parameters)?.localEndpoint = local_endpoint
}

public func nw_parameters_set_local_only(_ parameters: nw_parameters_t, _ local_only: Bool) {
    linuxParameters(parameters)?.localOnly = local_only
}

public func nw_parameters_set_multipath_service(_ parameters: nw_parameters_t, _ multipath_service: nw_multipath_service_t) {
    linuxParameters(parameters)?.multipathService = multipath_service
}

public func nw_parameters_set_prefer_no_proxy(_ parameters: nw_parameters_t, _ prefer_no_proxy: Bool) {
    linuxParameters(parameters)?.preferNoProxy = prefer_no_proxy
}

public func nw_parameters_set_privacy_context(_ parameters: nw_parameters_t, _ privacy_context: nw_privacy_context_t) {
    linuxParameters(parameters)?.privacyContext = privacy_context
}

public func nw_parameters_set_prohibit_constrained(_ parameters: nw_parameters_t, _ prohibit_constrained: Bool) {
    linuxParameters(parameters)?.prohibitConstrained = prohibit_constrained
}

public func nw_parameters_set_prohibit_expensive(_ parameters: nw_parameters_t, _ prohibit_expensive: Bool) {
    linuxParameters(parameters)?.prohibitExpensive = prohibit_expensive
}

public func nw_parameters_set_required_interface_type(_ parameters: nw_parameters_t, _ interface_type: nw_interface_type_t) {
    linuxParameters(parameters)?.requiredInterfaceType = interface_type
}

public func nw_parameters_set_requires_dnssec_validation(_ parameters: nw_parameters_t, _ requires_dnssec_validation: Bool) {
    linuxParameters(parameters)?.requiresDNSSECValidation = requires_dnssec_validation
}

public func nw_parameters_set_reuse_local_address(_ parameters: nw_parameters_t, _ reuse_local_address: Bool) {
    linuxParameters(parameters)?.reuseLocalAddress = reuse_local_address
}

public func nw_parameters_set_service_class(_ parameters: nw_parameters_t, _ service_class: nw_service_class_t) {
    linuxParameters(parameters)?.serviceClass = service_class
}

public func nw_path_copy_effective_local_endpoint(_ path: nw_path_t) -> nw_endpoint_t? {
    _ = path
    return nil
}

public func nw_path_copy_effective_remote_endpoint(_ path: nw_path_t) -> nw_endpoint_t? {
    _ = path
    return nil
}

public func nw_path_enumerate_gateways(_ path: nw_path_t, _ enumerate_block: (nw_endpoint_t) -> Bool) {
    _ = path
    _ = enumerate_block
}

public func nw_path_enumerate_interfaces(_ path: nw_path_t, _ enumerate_block: (nw_interface_t) -> Bool) {
    _ = path
    _ = enumerate_block
}

public func nw_path_get_link_quality(_ path: nw_path_t) -> nw_link_quality_t {
    _ = path
    return nw_link_quality_t(rawValue: 0)
}

public func nw_path_get_status(_ path: nw_path_t) -> nw_path_status_t {
    _ = path
    return nw_path_status_t(rawValue: 0)
}

public func nw_path_get_unsatisfied_reason(_ path: nw_path_t) -> nw_path_unsatisfied_reason_t {
    _ = path
    return nw_path_unsatisfied_reason_t(rawValue: 0)
}

public func nw_path_has_dns(_ path: nw_path_t) -> Bool {
    _ = path
    return false
}

public func nw_path_has_ipv4(_ path: nw_path_t) -> Bool {
    _ = path
    return false
}

public func nw_path_has_ipv6(_ path: nw_path_t) -> Bool {
    _ = path
    return false
}

public func nw_path_is_constrained(_ path: nw_path_t) -> Bool {
    _ = path
    return false
}

public func nw_path_is_equal(_ path: nw_path_t, _ other_path: nw_path_t) -> Bool {
    _ = path
    _ = other_path
    return false
}

public func nw_path_is_expensive(_ path: nw_path_t) -> Bool {
    _ = path
    return false
}

public func nw_path_is_ultra_constrained(_ path: nw_path_t) -> Bool {
    _ = path
    return false
}

public func nw_path_monitor_cancel(_ monitor: nw_path_monitor_t) {
    _ = monitor
}

public func nw_path_monitor_create() -> nw_path_monitor_t {
    return NWLinuxCFactory.make_nw_path_monitor()
}

public func nw_path_monitor_create_with_type(_ required_interface_type: nw_interface_type_t) -> nw_path_monitor_t {
    _ = required_interface_type
    return NWLinuxCFactory.make_nw_path_monitor()
}

public func nw_path_monitor_prohibit_interface_type(_ monitor: nw_path_monitor_t, _ interface_type: nw_interface_type_t) {
    _ = monitor
    _ = interface_type
}

public func nw_path_monitor_set_cancel_handler(_ monitor: nw_path_monitor_t, _ cancel_handler: @escaping nw_path_monitor_cancel_handler_t) {
    _ = monitor
    _ = cancel_handler
}

public func nw_path_monitor_set_queue(_ monitor: nw_path_monitor_t, _ queue: dispatch_queue_t) {
    _ = monitor
    _ = queue
}

public func nw_path_monitor_set_update_handler(_ monitor: nw_path_monitor_t, _ update_handler: @escaping nw_path_monitor_update_handler_t) {
    _ = monitor
    _ = update_handler
}

public func nw_path_monitor_start(_ monitor: nw_path_monitor_t) {
    _ = monitor
}

public func nw_path_uses_interface_type(_ path: nw_path_t, _ interface_type: nw_interface_type_t) -> Bool {
    _ = path
    _ = interface_type
    return false
}

public func nw_privacy_context_add_proxy(_ privacy_context: nw_privacy_context_t, _ proxy_config: nw_proxy_config_t) {
    linuxPrivacy(privacy_context)?.proxies.append(proxy_config)
}

public func nw_privacy_context_clear_proxies(_ privacy_context: nw_privacy_context_t) {
    linuxPrivacy(privacy_context)?.proxies.removeAll()
}

public func nw_privacy_context_create(_ description: UnsafePointer<CChar>) -> nw_privacy_context_t {
    let object = _NWLinux_nw_privacy_context()
    object.descriptionText = NWLinuxCString(String(cString: description))
    return object
}

public func nw_privacy_context_disable_logging(_ privacy_context: nw_privacy_context_t) {
    linuxPrivacy(privacy_context)?.loggingDisabled = true
}

public func nw_privacy_context_flush_cache(_ privacy_context: nw_privacy_context_t) {
    linuxPrivacy(privacy_context)?.cacheFlushed = true
}

public func nw_privacy_context_require_encrypted_name_resolution(_ privacy_context: nw_privacy_context_t, _ require_encrypted_name_resolution: Bool, _ fallback_resolver_config: nw_resolver_config_t?) {
    guard let stored = linuxPrivacy(privacy_context) else { return }
    stored.requireEncryptedNameResolution = require_encrypted_name_resolution
    stored.fallbackResolver = fallback_resolver_config
}

public func nw_protocol_copy_ip_definition() -> nw_protocol_definition_t {
    linuxNamedDefinition("ip")
}

public func nw_protocol_copy_quic_definition() -> nw_protocol_definition_t {
    linuxNamedDefinition("quic")
}

public func nw_protocol_copy_tcp_definition() -> nw_protocol_definition_t {
    linuxNamedDefinition("tcp")
}

public func nw_protocol_copy_tls_definition() -> nw_protocol_definition_t {
    linuxNamedDefinition("tls")
}

public func nw_protocol_copy_udp_definition() -> nw_protocol_definition_t {
    linuxNamedDefinition("udp")
}

public func nw_protocol_copy_ws_definition() -> nw_protocol_definition_t {
    linuxNamedDefinition("ws")
}

public func nw_protocol_definition_is_equal(_ definition1: nw_protocol_definition_t, _ definition2: nw_protocol_definition_t) -> Bool {
    guard let left = linuxDefinition(definition1), let right = linuxDefinition(definition2) else {
        return false
    }
    return String(cString: left.identifier.pointer) == String(cString: right.identifier.pointer)
        && !String(cString: left.identifier.pointer).isEmpty
}

public func nw_protocol_metadata_copy_definition(_ metadata: nw_protocol_metadata_t) -> nw_protocol_definition_t {
    _ = metadata
    return NWLinuxCFactory.make_nw_protocol_definition()
}

public func nw_protocol_metadata_is_framer_message(_ metadata: nw_protocol_metadata_t) -> Bool {
    _ = metadata
    return false
}

public func nw_protocol_metadata_is_ip(_ metadata: nw_protocol_metadata_t) -> Bool {
    _ = metadata
    return false
}

public func nw_protocol_metadata_is_quic(_ metadata: nw_protocol_metadata_t) -> Bool {
    _ = metadata
    return false
}

public func nw_protocol_metadata_is_tcp(_ metadata: nw_protocol_metadata_t) -> Bool {
    _ = metadata
    return false
}

public func nw_protocol_metadata_is_tls(_ metadata: nw_protocol_metadata_t) -> Bool {
    _ = metadata
    return false
}

public func nw_protocol_metadata_is_udp(_ metadata: nw_protocol_metadata_t) -> Bool {
    _ = metadata
    return false
}

public func nw_protocol_metadata_is_ws(_ metadata: nw_protocol_metadata_t) -> Bool {
    _ = metadata
    return false
}

public func nw_protocol_options_copy_definition(_ options: nw_protocol_options_t) -> nw_protocol_definition_t {
    _ = options
    return NWLinuxCFactory.make_nw_protocol_definition()
}

public func nw_protocol_options_is_quic(_ options: nw_protocol_options_t) -> Bool {
    linuxOptions(options)?.isQUIC ?? false
}

public func nw_protocol_stack_clear_application_protocols(_ stack: nw_protocol_stack_t) {
    _ = stack
}

public func nw_protocol_stack_copy_internet_protocol(_ stack: nw_protocol_stack_t) -> nw_protocol_options_t? {
    _ = stack
    return NWLinuxCFactory.make_nw_protocol_options()
}

public func nw_protocol_stack_copy_transport_protocol(_ stack: nw_protocol_stack_t) -> nw_protocol_options_t? {
    _ = stack
    return NWLinuxCFactory.make_nw_protocol_options()
}

public func nw_protocol_stack_iterate_application_protocols(_ stack: nw_protocol_stack_t, _ iterate_block: (nw_protocol_options_t) -> Void) {
    _ = stack
    _ = iterate_block
}

public func nw_protocol_stack_prepend_application_protocol(_ stack: nw_protocol_stack_t, _ protocol: nw_protocol_options_t) {
    _ = stack
    _ = `protocol`
}

public func nw_protocol_stack_set_transport_protocol(_ stack: nw_protocol_stack_t, _ protocol: nw_protocol_options_t) {
    _ = stack
    _ = `protocol`
}

public func nw_proxy_config_add_excluded_domain(_ config: nw_proxy_config_t, _ excluded_domain: UnsafePointer<CChar>) {
    linuxProxy(config)?.excludedDomains.append(String(cString: excluded_domain))
}

public func nw_proxy_config_add_match_domain(_ config: nw_proxy_config_t, _ match_domain: UnsafePointer<CChar>) {
    linuxProxy(config)?.matchDomains.append(String(cString: match_domain))
}

public func nw_proxy_config_clear_excluded_domains(_ config: nw_proxy_config_t) {
    linuxProxy(config)?.excludedDomains.removeAll()
}

public func nw_proxy_config_clear_match_domains(_ config: nw_proxy_config_t) {
    linuxProxy(config)?.matchDomains.removeAll()
}

public func nw_proxy_config_create_http_connect(_ proxy_endpoint: nw_endpoint_t, _ proxy_tls_options: nw_protocol_options_t?) -> nw_proxy_config_t {
    _ = proxy_tls_options
    let object = _NWLinux_nw_proxy_config()
    object.endpoint = proxy_endpoint
    return object
}

public func nw_proxy_config_create_oblivious_http(_ relay: nw_relay_hop_t, _ relay_resource_path: UnsafePointer<CChar>, _ gateway_key_config: UnsafePointer<UInt8>, _ gateway_key_config_length: Int) -> nw_proxy_config_t {
    _ = relay
    _ = relay_resource_path
    _ = gateway_key_config
    _ = gateway_key_config_length
    return _NWLinux_nw_proxy_config()
}

public func nw_proxy_config_create_relay(_ first_hop: nw_relay_hop_t, _ second_hop: nw_relay_hop_t?) -> nw_proxy_config_t {
    _ = first_hop
    _ = second_hop
    return _NWLinux_nw_proxy_config()
}

public func nw_proxy_config_create_socksv5(_ proxy_endpoint: nw_endpoint_t) -> nw_proxy_config_t {
    let object = _NWLinux_nw_proxy_config()
    object.endpoint = proxy_endpoint
    return object
}

public func nw_proxy_config_enumerate_excluded_domains(_ config: nw_proxy_config_t, _ enumerator: (UnsafePointer<CChar>) -> Void) {
    guard let stored = linuxProxy(config) else { return }
    for domain in stored.excludedDomains {
        domain.withCString { enumerator($0) }
    }
}

public func nw_proxy_config_enumerate_match_domains(_ config: nw_proxy_config_t, _ enumerator: (UnsafePointer<CChar>) -> Void) {
    guard let stored = linuxProxy(config) else { return }
    for domain in stored.matchDomains {
        domain.withCString { enumerator($0) }
    }
}

public func nw_proxy_config_get_failover_allowed(_ proxy_config: nw_proxy_config_t) -> Bool {
    linuxProxy(proxy_config)?.failoverAllowed ?? false
}

public func nw_proxy_config_set_failover_allowed(_ proxy_config: nw_proxy_config_t, _ failover_allowed: Bool) {
    linuxProxy(proxy_config)?.failoverAllowed = failover_allowed
}

public func nw_proxy_config_set_username_and_password(_ proxy_config: nw_proxy_config_t, _ username: UnsafePointer<CChar>, _ password: UnsafePointer<CChar>?) {
    guard let stored = linuxProxy(proxy_config) else { return }
    stored.username = NWLinuxCString(String(cString: username))
    stored.password = NWLinuxCString(password.map { String(cString: $0) } ?? "")
}

public func nw_quic_add_tls_application_protocol(_ options: nw_protocol_options_t, _ application_protocol: UnsafePointer<CChar>) {
    linuxOptions(options)?.quicALPN.append(String(cString: application_protocol))
}

public func nw_quic_copy_sec_protocol_metadata(_ metadata: nw_protocol_metadata_t) -> sec_protocol_metadata_t {
    _ = metadata
    return sec_protocol_metadata()
}

public func nw_quic_copy_sec_protocol_options(_ options: nw_protocol_options_t) -> sec_protocol_options_t {
    _ = options
    return sec_protocol_options()
}

public func nw_quic_create_options() -> nw_protocol_options_t {
    let options = _NWLinux_nw_protocol_options()
    options.isQUIC = true
    return options
}

public func nw_quic_get_application_error(_ metadata: nw_protocol_metadata_t) -> UInt64 {
    linuxMetadata(metadata)?.applicationError ?? 0
}

public func nw_quic_get_application_error_reason(_ metadata: nw_protocol_metadata_t) -> UnsafePointer<CChar>? {
    linuxMetadata(metadata)?.applicationErrorReason?.pointer
}

public func nw_quic_get_idle_timeout(_ options: nw_protocol_options_t) -> UInt32 {
    linuxOptions(options)?.quicIdleTimeout ?? 0
}

public func nw_quic_get_initial_max_data(_ options: nw_protocol_options_t) -> UInt64 {
    linuxOptions(options)?.quicInitialMaxData ?? 0
}

public func nw_quic_get_initial_max_stream_data_bidirectional_local(_ options: nw_protocol_options_t) -> UInt64 {
    linuxOptions(options)?.quicInitialMaxStreamDataBidirectionalLocal ?? 0
}

public func nw_quic_get_initial_max_stream_data_bidirectional_remote(_ options: nw_protocol_options_t) -> UInt64 {
    linuxOptions(options)?.quicInitialMaxStreamDataBidirectionalRemote ?? 0
}

public func nw_quic_get_initial_max_stream_data_unidirectional(_ options: nw_protocol_options_t) -> UInt64 {
    linuxOptions(options)?.quicInitialMaxStreamDataUnidirectional ?? 0
}

public func nw_quic_get_initial_max_streams_bidirectional(_ options: nw_protocol_options_t) -> UInt64 {
    linuxOptions(options)?.quicInitialMaxStreamsBidirectional ?? 0
}

public func nw_quic_get_initial_max_streams_unidirectional(_ options: nw_protocol_options_t) -> UInt64 {
    linuxOptions(options)?.quicInitialMaxStreamsUnidirectional ?? 0
}

public func nw_quic_get_keepalive_interval(_ metadata: nw_protocol_metadata_t) -> UInt16 {
    linuxMetadata(metadata)?.keepaliveInterval ?? 0
}

public func nw_quic_get_local_max_streams_bidirectional(_ metadata: nw_protocol_metadata_t) -> UInt64 {
    linuxMetadata(metadata)?.localMaxStreamsBidirectional ?? 0
}

public func nw_quic_get_local_max_streams_unidirectional(_ metadata: nw_protocol_metadata_t) -> UInt64 {
    linuxMetadata(metadata)?.localMaxStreamsUnidirectional ?? 0
}

public func nw_quic_get_max_datagram_frame_size(_ options: nw_protocol_options_t) -> UInt16 {
    linuxOptions(options)?.quicMaxDatagramFrameSize ?? 0
}

public func nw_quic_get_max_udp_payload_size(_ options: nw_protocol_options_t) -> UInt16 {
    linuxOptions(options)?.quicMaxUDPPayloadSize ?? 0
}

public func nw_quic_get_remote_idle_timeout(_ metadata: nw_protocol_metadata_t) -> UInt64 {
    linuxMetadata(metadata)?.remoteIdleTimeout ?? 0
}

public func nw_quic_get_remote_max_streams_bidirectional(_ metadata: nw_protocol_metadata_t) -> UInt64 {
    linuxMetadata(metadata)?.remoteMaxStreamsBidirectional ?? 0
}

public func nw_quic_get_remote_max_streams_unidirectional(_ metadata: nw_protocol_metadata_t) -> UInt64 {
    linuxMetadata(metadata)?.remoteMaxStreamsUnidirectional ?? 0
}

public func nw_quic_get_stream_application_error(_ metadata: nw_protocol_metadata_t) -> UInt64 {
    linuxMetadata(metadata)?.streamApplicationError ?? 0
}

public func nw_quic_get_stream_id(_ metadata: nw_protocol_metadata_t) -> UInt64 {
    linuxMetadata(metadata)?.streamID ?? 0
}

public func nw_quic_get_stream_is_datagram(_ options: nw_protocol_options_t) -> Bool {
    linuxOptions(options)?.quicStreamIsDatagram ?? false
}

public func nw_quic_get_stream_is_unidirectional(_ options: nw_protocol_options_t) -> Bool {
    linuxOptions(options)?.quicStreamIsUnidirectional ?? false
}

public func nw_quic_get_stream_type(_ stream_metadata: nw_protocol_metadata_t) -> UInt8 {
    linuxMetadata(stream_metadata)?.streamType ?? 0
}

public func nw_quic_get_stream_usable_datagram_frame_size(_ metadata: nw_protocol_metadata_t) -> UInt16 {
    linuxMetadata(metadata)?.usableDatagramFrameSize ?? 0
}

public func nw_quic_set_application_error(_ metadata: nw_protocol_metadata_t, _ application_error: UInt64, _ reason: UnsafePointer<CChar>?) {
    guard let stored = linuxMetadata(metadata) else { return }
    stored.applicationError = application_error
    stored.applicationErrorReason = reason.map { NWLinuxCString(String(cString: $0)) }
}

public func nw_quic_set_idle_timeout(_ options: nw_protocol_options_t, _ idle_timeout: UInt32) {
    linuxOptions(options)?.quicIdleTimeout = idle_timeout
}

public func nw_quic_set_initial_max_data(_ options: nw_protocol_options_t, _ initial_max_data: UInt64) {
    linuxOptions(options)?.quicInitialMaxData = initial_max_data
}

public func nw_quic_set_initial_max_stream_data_bidirectional_local(_ options: nw_protocol_options_t, _ initial_max_stream_data_bidirectional_local: UInt64) {
    linuxOptions(options)?.quicInitialMaxStreamDataBidirectionalLocal = initial_max_stream_data_bidirectional_local
}

public func nw_quic_set_initial_max_stream_data_bidirectional_remote(_ options: nw_protocol_options_t, _ initial_max_stream_data_bidirectional_remote: UInt64) {
    linuxOptions(options)?.quicInitialMaxStreamDataBidirectionalRemote = initial_max_stream_data_bidirectional_remote
}

public func nw_quic_set_initial_max_stream_data_unidirectional(_ options: nw_protocol_options_t, _ initial_max_stream_data_unidirectional: UInt64) {
    linuxOptions(options)?.quicInitialMaxStreamDataUnidirectional = initial_max_stream_data_unidirectional
}

public func nw_quic_set_initial_max_streams_bidirectional(_ options: nw_protocol_options_t, _ initial_max_streams_bidirectional: UInt64) {
    linuxOptions(options)?.quicInitialMaxStreamsBidirectional = initial_max_streams_bidirectional
}

public func nw_quic_set_initial_max_streams_unidirectional(_ options: nw_protocol_options_t, _ initial_max_streams_unidirectional: UInt64) {
    linuxOptions(options)?.quicInitialMaxStreamsUnidirectional = initial_max_streams_unidirectional
}

public func nw_quic_set_keepalive_interval(_ metadata: nw_protocol_metadata_t, _ keepalive_interval: UInt16) {
    linuxMetadata(metadata)?.keepaliveInterval = keepalive_interval
}

public func nw_quic_set_local_max_streams_bidirectional(_ metadata: nw_protocol_metadata_t, _ max_streams_bidirectional: UInt64) {
    linuxMetadata(metadata)?.localMaxStreamsBidirectional = max_streams_bidirectional
}

public func nw_quic_set_local_max_streams_unidirectional(_ metadata: nw_protocol_metadata_t, _ max_streams_unidirectional: UInt64) {
    linuxMetadata(metadata)?.localMaxStreamsUnidirectional = max_streams_unidirectional
}

public func nw_quic_set_max_datagram_frame_size(_ options: nw_protocol_options_t, _ max_datagram_frame_size: UInt16) {
    linuxOptions(options)?.quicMaxDatagramFrameSize = max_datagram_frame_size
}

public func nw_quic_set_max_udp_payload_size(_ options: nw_protocol_options_t, _ max_udp_payload_size: UInt16) {
    linuxOptions(options)?.quicMaxUDPPayloadSize = max_udp_payload_size
}

public func nw_quic_set_stream_application_error(_ metadata: nw_protocol_metadata_t, _ application_error: UInt64) {
    linuxMetadata(metadata)?.streamApplicationError = application_error
}

public func nw_quic_set_stream_is_datagram(_ options: nw_protocol_options_t, _ is_datagram: Bool) {
    linuxOptions(options)?.quicStreamIsDatagram = is_datagram
}

public func nw_quic_set_stream_is_unidirectional(_ options: nw_protocol_options_t, _ is_unidirectional: Bool) {
    linuxOptions(options)?.quicStreamIsUnidirectional = is_unidirectional
}

public func nw_relay_hop_add_additional_http_header_field(_ relay_hop: nw_relay_hop_t, _ field_name: UnsafePointer<CChar>, _ field_value: UnsafePointer<CChar>) {
    linuxRelay(relay_hop)?.headers.append((String(cString: field_name), String(cString: field_value)))
}

public func nw_relay_hop_create(_ http3_relay_endpoint: nw_endpoint_t?, _ http2_relay_endpoint: nw_endpoint_t?, _ relay_tls_options: nw_protocol_options_t?) -> nw_relay_hop_t {
    _ = relay_tls_options
    let object = _NWLinux_nw_relay_hop()
    object.http3Endpoint = http3_relay_endpoint
    object.http2Endpoint = http2_relay_endpoint
    return object
}

public func nw_resolution_report_copy_preferred_endpoint(_ resolution_report: nw_resolution_report_t) -> nw_endpoint_t {
    linuxResolution(resolution_report)?.preferredEndpoint ?? NWLinuxCFactory.make_nw_endpoint()
}

public func nw_resolution_report_copy_successful_endpoint(_ resolution_report: nw_resolution_report_t) -> nw_endpoint_t {
    linuxResolution(resolution_report)?.successfulEndpoint ?? NWLinuxCFactory.make_nw_endpoint()
}

public func nw_resolution_report_get_endpoint_count(_ resolution_report: nw_resolution_report_t) -> UInt32 {
    linuxResolution(resolution_report)?.endpointCount ?? 0
}

public func nw_resolution_report_get_milliseconds(_ resolution_report: nw_resolution_report_t) -> UInt64 {
    linuxResolution(resolution_report)?.milliseconds ?? 0
}

public func nw_resolution_report_get_protocol(_ resolution_report: nw_resolution_report_t) -> nw_report_resolution_protocol_t {
    linuxResolution(resolution_report)?.protocolValue ?? nw_report_resolution_protocol_unknown
}

public func nw_resolution_report_get_source(_ resolution_report: nw_resolution_report_t) -> nw_report_resolution_source_t {
    linuxResolution(resolution_report)?.source ?? nw_report_resolution_source_query
}

public func nw_resolver_config_add_server_address(_ config: nw_resolver_config_t, _ server_address: nw_endpoint_t) {
    linuxResolver(config)?.servers.append(server_address)
}

public func nw_resolver_config_create_https(_ url: UnsafePointer<CChar>) -> nw_resolver_config_t {
    _ = url
    return _NWLinux_nw_resolver_config()
}

public func nw_resolver_config_create_tls(_ hostname: UnsafePointer<CChar>) -> nw_resolver_config_t {
    _ = hostname
    return _NWLinux_nw_resolver_config()
}

public func nw_tcp_create_options() -> nw_protocol_options_t {
    return NWLinuxCFactory.make_nw_protocol_options()
}

public func nw_tcp_get_available_receive_buffer(_ metadata: nw_protocol_metadata_t) -> UInt32 {
    linuxMetadata(metadata)?.tcpAvailableReceive ?? 0
}

public func nw_tcp_get_available_send_buffer(_ metadata: nw_protocol_metadata_t) -> UInt32 {
    linuxMetadata(metadata)?.tcpAvailableSend ?? 0
}

public func nw_tcp_options_set_connection_timeout(_ options: nw_protocol_options_t, _ connection_timeout: UInt32) {
    linuxOptions(options)?.connectionTimeout = connection_timeout
}

public func nw_tcp_options_set_disable_ack_stretching(_ options: nw_protocol_options_t, _ disable_ack_stretching: Bool) {
    linuxOptions(options)?.disableAckStretching = disable_ack_stretching
}

public func nw_tcp_options_set_disable_ecn(_ options: nw_protocol_options_t, _ disable_ecn: Bool) {
    linuxOptions(options)?.disableECN = disable_ecn
}

public func nw_tcp_options_set_enable_fast_open(_ options: nw_protocol_options_t, _ enable_fast_open: Bool) {
    linuxOptions(options)?.enableFastOpen = enable_fast_open
}

public func nw_tcp_options_set_enable_keepalive(_ options: nw_protocol_options_t, _ enable_keepalive: Bool) {
    linuxOptions(options)?.enableKeepalive = enable_keepalive
}

public func nw_tcp_options_set_keepalive_count(_ options: nw_protocol_options_t, _ keepalive_count: UInt32) {
    linuxOptions(options)?.keepaliveCount = keepalive_count
}

public func nw_tcp_options_set_keepalive_idle_time(_ options: nw_protocol_options_t, _ keepalive_idle_time: UInt32) {
    linuxOptions(options)?.keepaliveIdleTime = keepalive_idle_time
}

public func nw_tcp_options_set_keepalive_interval(_ options: nw_protocol_options_t, _ keepalive_interval: UInt32) {
    linuxOptions(options)?.keepaliveInterval = keepalive_interval
}

public func nw_tcp_options_set_maximum_segment_size(_ options: nw_protocol_options_t, _ maximum_segment_size: UInt32) {
    linuxOptions(options)?.maximumSegmentSize = maximum_segment_size
}

public func nw_tcp_options_set_multipath_force_version(_ options: nw_protocol_options_t, _ multipath_force_version: nw_multipath_version_t) {
    linuxOptions(options)?.multipathForceVersion = multipath_force_version
}

public func nw_tcp_options_set_no_delay(_ options: nw_protocol_options_t, _ no_delay: Bool) {
    linuxOptions(options)?.noDelay = no_delay
}

public func nw_tcp_options_set_no_options(_ options: nw_protocol_options_t, _ no_options: Bool) {
    linuxOptions(options)?.noOptions = no_options
}

public func nw_tcp_options_set_no_push(_ options: nw_protocol_options_t, _ no_push: Bool) {
    linuxOptions(options)?.noPush = no_push
}

public func nw_tcp_options_set_persist_timeout(_ options: nw_protocol_options_t, _ persist_timeout: UInt32) {
    linuxOptions(options)?.persistTimeout = persist_timeout
}

public func nw_tcp_options_set_retransmit_connection_drop_time(_ options: nw_protocol_options_t, _ retransmit_connection_drop_time: UInt32) {
    linuxOptions(options)?.retransmitConnectionDropTime = retransmit_connection_drop_time
}

public func nw_tcp_options_set_retransmit_fin_drop(_ options: nw_protocol_options_t, _ retransmit_fin_drop: Bool) {
    linuxOptions(options)?.retransmitFinDrop = retransmit_fin_drop
}

public func nw_tls_copy_sec_protocol_metadata(_ metadata: nw_protocol_metadata_t) -> sec_protocol_metadata_t {
    _ = metadata
    return sec_protocol_metadata()
}

public func nw_tls_copy_sec_protocol_options(_ options: nw_protocol_options_t) -> sec_protocol_options_t {
    _ = options
    return sec_protocol_options()
}

public func nw_tls_create_options() -> nw_protocol_options_t {
    return NWLinuxCFactory.make_nw_protocol_options()
}

public func nw_txt_record_access_bytes(_ txt_record: nw_txt_record_t, _ access_bytes: @escaping nw_txt_record_access_bytes_t) -> Bool {
    guard let stored = linuxTXT(txt_record) else { return false }
    var blob = Data()
    for entry in stored.entries {
        var chunk = Data(entry.key.utf8)
        if !entry.value.isEmpty {
            chunk.append(0x3d)
            chunk.append(entry.value)
        }
        blob.append(UInt8(min(chunk.count, 255)))
        blob.append(contentsOf: chunk.prefix(255))
    }
    return blob.withUnsafeBytes { buffer in
        let base = buffer.bindMemory(to: UInt8.self).baseAddress ?? UnsafePointer(bitPattern: 1)!
        return access_bytes(base, blob.count)
    }
}

public func nw_txt_record_access_key(_ txt_record: nw_txt_record_t, _ key: UnsafePointer<CChar>, _ access_value: @escaping nw_txt_record_access_key_t) -> Bool {
    guard let stored = linuxTXT(txt_record) else { return false }
    let name = String(cString: key)
    guard let entry = stored.entries.first(where: { $0.key == name }) else {
        return access_value(key, nw_txt_record_find_key_not_present, nil, 0)
    }
    return entry.value.withUnsafeBytes { buffer in
        let base = buffer.bindMemory(to: UInt8.self).baseAddress ?? UnsafePointer(bitPattern: 1)!
        return access_value(key, nw_txt_record_find_key_non_empty_value, base, entry.value.count)
    }
}

public func nw_txt_record_apply(_ txt_record: nw_txt_record_t, _ applier: @escaping nw_txt_record_applier_t) -> Bool {
    guard let stored = linuxTXT(txt_record) else { return false }
    for entry in stored.entries {
        let keep = entry.key.withCString { keyPtr in
            entry.value.withUnsafeBytes { buffer in
                let base = buffer.bindMemory(to: UInt8.self).baseAddress
                return applier(keyPtr, nw_txt_record_find_key_non_empty_value, base ?? UnsafePointer(bitPattern: 1)!, entry.value.count)
            }
        }
        if !keep { return false }
    }
    return true
}

public func nw_txt_record_copy(_ txt_record: nw_txt_record_t?) -> nw_txt_record_t? {
    guard let stored = txt_record.flatMap(linuxTXT) else { return nil }
    let copy = _NWLinux_nw_txt_record()
    copy.entries = stored.entries
    return copy
}

public func nw_txt_record_create_dictionary() -> nw_txt_record_t {
    return NWLinuxCFactory.make_nw_txt_record()
}

public func nw_txt_record_create_with_bytes(_ txt_bytes: UnsafePointer<UInt8>, _ txt_len: Int) -> nw_txt_record_t {
    let record = _NWLinux_nw_txt_record()
    let data = Data(bytes: txt_bytes, count: max(txt_len, 0))
    var offset = 0
    while offset < data.count {
        let length = Int(data[offset])
        offset += 1
        guard offset + length <= data.count else { break }
        let slice = data[offset..<(offset + length)]
        offset += length
        if let eq = slice.firstIndex(of: 0x3d) {
            let key = String(bytes: slice[slice.startIndex..<eq], encoding: .utf8) ?? ""
            record.entries.append((key, Data(slice[slice.index(after: eq)...])))
        } else if let key = String(bytes: slice, encoding: .utf8) {
            record.entries.append((key, Data()))
        }
    }
    return record
}

public func nw_txt_record_find_key(_ txt_record: nw_txt_record_t, _ key: UnsafePointer<CChar>) -> nw_txt_record_find_key_t {
    guard let stored = linuxTXT(txt_record) else { return nw_txt_record_find_key_not_present }
    let name = String(cString: key)
    guard let entry = stored.entries.first(where: { $0.key == name }) else {
        return nw_txt_record_find_key_not_present
    }
    return entry.value.isEmpty ? nw_txt_record_find_key_empty_value : nw_txt_record_find_key_non_empty_value
}

public func nw_txt_record_get_key_count(_ txt_record: nw_txt_record_t?) -> Int {
    txt_record.flatMap(linuxTXT)?.entries.count ?? 0
}

public func nw_txt_record_is_dictionary(_ txt_record: nw_txt_record_t) -> Bool {
    linuxTXT(txt_record) != nil
}

public func nw_txt_record_is_equal(_ left: nw_txt_record_t?, _ right: nw_txt_record_t?) -> Bool {
    switch (left.flatMap(linuxTXT), right.flatMap(linuxTXT)) {
    case (nil, nil):
        return true
    case let (l?, r?):
        return l.entries.map(\.key) == r.entries.map(\.key)
            && l.entries.map(\.value) == r.entries.map(\.value)
    default:
        return false
    }
}

public func nw_txt_record_remove_key(_ txt_record: nw_txt_record_t, _ key: UnsafePointer<CChar>) -> Bool {
    guard let stored = linuxTXT(txt_record) else { return false }
    let name = String(cString: key)
    let before = stored.entries.count
    stored.entries.removeAll { $0.key == name }
    return stored.entries.count != before
}

public func nw_txt_record_set_key(_ txt_record: nw_txt_record_t, _ key: UnsafePointer<CChar>, _ value: UnsafePointer<UInt8>?, _ value_len: Int) -> Bool {
    guard let stored = linuxTXT(txt_record) else { return false }
    let name = String(cString: key)
    guard !name.isEmpty else { return false }
    let data: Data
    if let value, value_len > 0 {
        data = Data(bytes: value, count: value_len)
    } else {
        data = Data()
    }
    stored.entries.removeAll { $0.key == name }
    stored.entries.append((name, data))
    return true
}

public func nw_udp_create_metadata() -> nw_protocol_metadata_t {
    let metadata = _NWLinux_nw_protocol_metadata()
    metadata.kind = "udp"
    return metadata
}

public func nw_udp_create_options() -> nw_protocol_options_t {
    return NWLinuxCFactory.make_nw_protocol_options()
}

public func nw_udp_options_set_prefer_no_checksum(_ options: nw_protocol_options_t, _ prefer_no_checksum: Bool) {
    linuxOptions(options)?.preferNoChecksum = prefer_no_checksum
}

public func nw_ws_create_metadata(_ opcode: nw_ws_opcode_t) -> nw_protocol_metadata_t {
    let metadata = _NWLinux_nw_protocol_metadata()
    metadata.kind = "ws"
    metadata.wsOpcode = opcode
    return metadata
}

public func nw_ws_create_options(_ version: nw_ws_version_t) -> nw_protocol_options_t {
    let options = _NWLinux_nw_protocol_options()
    options.wsVersion = version
    return options
}

public func nw_ws_metadata_copy_server_response(_ metadata: nw_protocol_metadata_t) -> nw_ws_response_t {
    linuxMetadata(metadata)?.wsServerResponse ?? NWLinuxCFactory.make_nw_ws_response()
}

public func nw_ws_metadata_get_close_code(_ metadata: nw_protocol_metadata_t) -> nw_ws_close_code_t {
    linuxMetadata(metadata)?.wsCloseCode ?? nw_ws_close_code_t(rawValue: 0)
}

public func nw_ws_metadata_get_opcode(_ metadata: nw_protocol_metadata_t) -> nw_ws_opcode_t {
    linuxMetadata(metadata)?.wsOpcode ?? nw_ws_opcode_t(rawValue: 0)
}

public func nw_ws_metadata_set_close_code(_ metadata: nw_protocol_metadata_t, _ close_code: nw_ws_close_code_t) {
    linuxMetadata(metadata)?.wsCloseCode = close_code
}

public func nw_ws_metadata_set_pong_handler(_ metadata: nw_protocol_metadata_t, _ client_queue: dispatch_queue_t, _ pong_handler: @escaping nw_ws_pong_handler_t) {
    _ = client_queue
    linuxMetadata(metadata)?.pongHandler = pong_handler
}

public func nw_ws_options_add_additional_header(_ options: nw_protocol_options_t, _ name: UnsafePointer<CChar>, _ value: UnsafePointer<CChar>) {
    linuxOptions(options)?.wsHeaders.append((String(cString: name), String(cString: value)))
}

public func nw_ws_options_add_subprotocol(_ options: nw_protocol_options_t, _ subprotocol: UnsafePointer<CChar>) {
    linuxOptions(options)?.wsSubprotocols.append(String(cString: subprotocol))
}

public func nw_ws_options_set_auto_reply_ping(_ options: nw_protocol_options_t, _ auto_reply_ping: Bool) {
    linuxOptions(options)?.wsAutoReplyPing = auto_reply_ping
}

public func nw_ws_options_set_client_request_handler(_ options: nw_protocol_options_t, _ client_queue: dispatch_queue_t, _ handler: @escaping nw_ws_client_request_handler_t) {
    _ = client_queue
    // No HTTP upgrade handshake on Linux. Invoke the handler once with the
    // locally stored subprotocols/headers so callers can enumerate a request
    // they configured; Apple handshake timing is unobserved.
    let request = _NWLinux_nw_ws_request()
    request.headers = linuxOptions(options)?.wsHeaders ?? []
    request.subprotocols = linuxOptions(options)?.wsSubprotocols ?? []
    _ = handler(request)
}

public func nw_ws_options_set_maximum_message_size(_ options: nw_protocol_options_t, _ maximum_message_size: Int) {
    linuxOptions(options)?.wsMaximumMessageSize = maximum_message_size
}

public func nw_ws_options_set_skip_handshake(_ options: nw_protocol_options_t, _ skip_handshake: Bool) {
    linuxOptions(options)?.wsSkipHandshake = skip_handshake
}

public func nw_ws_request_enumerate_additional_headers(_ request: nw_ws_request_t, _ enumerator: (UnsafePointer<CChar>, UnsafePointer<CChar>) -> Bool) -> Bool {
    guard let stored = linuxWSRequest(request) else { return false }
    for (name, value) in stored.headers {
        let keep = name.withCString { namePtr in
            value.withCString { valuePtr in
                enumerator(namePtr, valuePtr)
            }
        }
        if !keep { return false }
    }
    return true
}

public func nw_ws_request_enumerate_subprotocols(_ request: nw_ws_request_t, _ enumerator: (UnsafePointer<CChar>) -> Bool) -> Bool {
    guard let stored = linuxWSRequest(request) else { return false }
    for proto in stored.subprotocols {
        let keep = proto.withCString { enumerator($0) }
        if !keep { return false }
    }
    return true
}

public func nw_ws_response_add_additional_header(_ response: nw_ws_response_t, _ name: UnsafePointer<CChar>, _ value: UnsafePointer<CChar>) {
    linuxWSResponse(response)?.headers.append((String(cString: name), String(cString: value)))
}

public func nw_ws_response_create(_ status: nw_ws_response_status_t, _ selected_subprotocol: UnsafePointer<CChar>?) -> nw_ws_response_t {
    let object = _NWLinux_nw_ws_response()
    object.status = status
    object.selectedSubprotocol = selected_subprotocol.map { NWLinuxCString(String(cString: $0)) }
    return object
}

public func nw_ws_response_enumerate_additional_headers(_ response: nw_ws_response_t, _ enumerator: (UnsafePointer<CChar>, UnsafePointer<CChar>) -> Bool) -> Bool {
    guard let stored = linuxWSResponse(response) else { return false }
    for (name, value) in stored.headers {
        let keep = name.withCString { namePtr in
            value.withCString { valuePtr in
                enumerator(namePtr, valuePtr)
            }
        }
        if !keep { return false }
    }
    return true
}

public func nw_ws_response_get_selected_subprotocol(_ response: nw_ws_response_t) -> UnsafePointer<CChar>? {
    linuxWSResponse(response)?.selectedSubprotocol?.pointer
}

public func nw_ws_response_get_status(_ response: nw_ws_response_t?) -> nw_ws_response_status_t {
    response.flatMap(linuxWSResponse)?.status ?? nw_ws_response_status_invalid
}

