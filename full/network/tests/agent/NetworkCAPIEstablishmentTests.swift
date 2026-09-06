import Foundation
import Network

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testCEstablishmentReportSnapshotFromConnection() {
    let endpoint: nw_endpoint_t = "127.0.0.1".withCString { host in
        "80".withCString { port in
            nw_endpoint_create_host(host, port)
        }
    }
    let parameters: nw_parameters_t = nw_parameters_create()
    let connection: nw_connection_t = nw_connection_create(endpoint, parameters)
    var report: nw_establishment_report_t?
    nw_connection_access_establishment_report(connection, DispatchQueue(label: "c.est.depth")) {
        report = $0
    }
    expect(report != nil, "report")
    expect(nw_establishment_report_get_duration_milliseconds(report!) == 0, "duration")
    expect(nw_establishment_report_get_attempt_started_after_milliseconds(report!) == 0, "attempt")
    expect(nw_establishment_report_get_previous_attempt_count(report!) == 0, "previous")
    expect(nw_establishment_report_get_proxy_configured(report!) == false, "proxy configured")
    expect(nw_establishment_report_get_used_proxy(report!) == false, "used proxy")
    expect(nw_establishment_report_copy_proxy_endpoint(report!) == nil, "no proxy endpoint")
    var protocolCount = 0
    nw_establishment_report_enumerate_protocols(report!) { _, handshake, rtt in
        expect(handshake == 0, "handshake")
        expect(rtt == 0, "rtt")
        protocolCount += 1
        return true
    }
    expect(protocolCount == 1, "one protocol")
    var resolutionCount = 0
    nw_establishment_report_enumerate_resolutions(report!) { source, milliseconds, count, preferred, successful in
        expect(source == nw_report_resolution_source_query, "source")
        expect(milliseconds == 0, "ms")
        expect(count == 1, "count")
        _ = preferred
        _ = successful
        resolutionCount += 1
        return true
    }
    expect(resolutionCount == 1, "one resolution")
    var reportCount = 0
    nw_establishment_report_enumerate_resolution_reports(report!) { resolution in
        expect(nw_resolution_report_get_endpoint_count(resolution) == 1, "endpoint count")
        expect(nw_resolution_report_get_milliseconds(resolution) == 0, "resolution ms")
        expect(nw_resolution_report_get_protocol(resolution) == nw_report_resolution_protocol_unknown, "protocol")
        expect(nw_resolution_report_get_source(resolution) == nw_report_resolution_source_query, "res source")
        _ = nw_resolution_report_copy_preferred_endpoint(resolution)
        _ = nw_resolution_report_copy_successful_endpoint(resolution)
        reportCount += 1
        return true
    }
    expect(reportCount == 1, "one resolution report")
}

func testCWebSocketRequestEnumerateFromHandler() {
    let options = nw_ws_create_options(nw_ws_version_13)
    "chat".withCString { nw_ws_options_add_subprotocol(options, $0) }
    "X-Test".withCString { name in
        "1".withCString { value in
            nw_ws_options_add_additional_header(options, name, value)
        }
    }
    var headerCount = 0
    var protoCount = 0
    nw_ws_options_set_client_request_handler(options, DispatchQueue(label: "ws.req.depth")) { request in
        expect(
            nw_ws_request_enumerate_additional_headers(request) { name, value in
                expect(String(cString: name) == "X-Test", "header name")
                expect(String(cString: value) == "1", "header value")
                headerCount += 1
                return true
            },
            "headers"
        )
        expect(
            nw_ws_request_enumerate_subprotocols(request) { proto in
                expect(String(cString: proto) == "chat", "subprotocol")
                protoCount += 1
                return true
            },
            "subprotocols"
        )
        return nw_ws_response_create(nw_ws_response_status_accept, nil)
    }
    expect(headerCount == 1, "one header")
    expect(protoCount == 1, "one proto")
}

func testCTypeObjectsDriveConnectionLifecycle() {
    let endpoint: nw_endpoint_t = "127.0.0.1".withCString { host in
        "9".withCString { port in
            nw_endpoint_create_host(host, port)
        }
    }
    let parameters: nw_parameters_t = nw_parameters_create()
    let connection: nw_connection_t = nw_connection_create(endpoint, parameters)
    let queue: dispatch_queue_t = DispatchQueue(label: "c.types")
    nw_connection_set_queue(connection, queue)
    var sawState = false
    nw_connection_set_state_changed_handler(connection) { _, error in
        sawState = true
        _ = error
    }
    nw_connection_start(connection)
    let context: nw_content_context_t = "typed".withCString { nw_content_context_create($0) }
    var sent = false
    nw_connection_send(connection, nil, context, true) { error in
        expect(error != nil, "send error")
        sent = true
    }
    expect(sent, "send completed")
    nw_connection_cancel(connection)
    _ = sawState
    let pathMonitor: nw_path_monitor_t = nw_path_monitor_create()
    nw_path_monitor_set_queue(pathMonitor, queue)
    nw_path_monitor_start(pathMonitor)
    nw_path_monitor_cancel(pathMonitor)
    expect(nw_listener_create(parameters) != nil, "listener")
    let descriptor: nw_browse_descriptor_t = "svc".withCString {
        nw_browse_descriptor_create_application_service($0)
    }
    let browser: nw_browser_t = nw_browser_create(descriptor, parameters)
    nw_browser_start(browser)
    nw_browser_cancel(browser)
    let txt: nw_txt_record_t = nw_txt_record_create_dictionary()
    _ = txt
    let report = nw_connection_create_new_data_transfer_report(connection)
    let interface: nw_interface_t = nw_data_transfer_report_copy_path_interface(report, 0)
    expect(nw_interface_get_type(interface) == nw_interface_type_loopback, "loopback")
}
