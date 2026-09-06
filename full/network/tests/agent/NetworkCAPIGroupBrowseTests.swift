import Foundation
import Network

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testCBrowseDescriptorRoundTrip() {
    let bonjour = "_http._tcp".withCString { type in
        "local.".withCString { domain in
            nw_browse_descriptor_create_bonjour_service(type, domain)
        }
    }
    expect(String(cString: nw_browse_descriptor_get_bonjour_service_type(bonjour)) == "_http._tcp", "type")
    expect(String(cString: nw_browse_descriptor_get_bonjour_service_domain(bonjour)!) == "local.", "domain")
    let app = "my.service".withCString { nw_browse_descriptor_create_application_service($0) }
    expect(String(cString: nw_browse_descriptor_get_application_service_name(app)!) == "my.service", "app name")
}

func testCBrowseResultFromFailedBrowser() {
    let descriptor = "_http._tcp".withCString { type in
        nw_browse_descriptor_create_bonjour_service(type, nil)
    }
    let browser = nw_browser_create(descriptor, nw_parameters_create())
    var result: nw_browse_result_t?
    nw_browser_set_browse_results_changed_handler(browser) { incoming, _, _ in
        result = incoming
    }
    var failed = false
    nw_browser_set_state_changed_handler(browser) { state, error in
        failed = state == nw_browser_state_failed && error != nil
    }
    nw_browser_start(browser)
    expect(failed, "browser fail-closed")
    expect(result != nil, "empty result delivered")
    _ = nw_browse_result_copy_endpoint(result!)
    expect(nw_browse_result_copy_txt_record_object(result!) == nil, "no txt")
    expect(nw_browse_result_get_interfaces_count(result!) == 0, "no interfaces")
    nw_browse_result_enumerate_interfaces(result!) { _ in
        preconditionFailure("no interfaces")
    }
    expect(
        nw_browse_result_get_changes(nil, nil) == nw_browse_result_change_t(UInt64(nw_browse_result_change_identical)),
        "identical"
    )
}

func testCConnectionGroupFailClosed() {
    let endpoint = "224.0.0.251".withCString { host in
        "5353".withCString { port in
            nw_endpoint_create_host(host, port)
        }
    }
    let descriptor = nw_group_descriptor_create_multicast(endpoint)
    expect(nw_group_descriptor_add_endpoint(descriptor, endpoint), "add endpoint")
    var counted = 0
    nw_group_descriptor_enumerate_endpoints(descriptor) { _ in
        counted += 1
        return true
    }
    expect(counted == 2, "multicast plus added")
    nw_multicast_group_descriptor_set_disable_unicast_traffic(descriptor, true)
    expect(nw_multicast_group_descriptor_get_disable_unicast_traffic(descriptor), "disable unicast")
    nw_multicast_group_descriptor_set_specific_source(descriptor, endpoint)
    let multiplex = nw_group_descriptor_create_multiplex(endpoint)
    let group = nw_connection_group_create(multiplex, nw_parameters_create())
    let copiedDescriptor = nw_connection_group_copy_descriptor(group)
    _ = copiedDescriptor
    let copiedParameters = nw_connection_group_copy_parameters(group)
    _ = copiedParameters
    var stateFailed = false
    nw_connection_group_set_state_changed_handler(group) { state, error in
        stateFailed = state == nw_connection_group_state_failed && error != nil
    }
    nw_connection_group_set_queue(group, DispatchQueue(label: "c.group"))
    nw_connection_group_set_new_connection_handler(group) { _ in }
    nw_connection_group_set_receive_handler(group, 1024, true) { _, _, _ in }
    nw_connection_group_start(group)
    expect(stateFailed, "group start fail-closed")
    let context = "msg".withCString { nw_content_context_create($0) }
    expect(nw_connection_group_copy_local_endpoint_for_message(group, context) == nil, "local for message")
    expect(nw_connection_group_copy_path_for_message(group, context) == nil, "path for message")
    expect(nw_connection_group_copy_protocol_metadata(group, nw_protocol_copy_udp_definition()) == nil, "metadata")
    expect(nw_connection_group_copy_protocol_metadata_for_message(group, context, nw_protocol_copy_udp_definition()) == nil, "metadata for message")
    expect(nw_connection_group_copy_remote_endpoint_for_message(group, context) == nil, "remote for message")
    expect(nw_connection_group_extract_connection(group, endpoint, nil) == nil, "extract")
    expect(nw_connection_group_extract_connection_for_message(group, context) == nil, "extract message")
    expect(nw_connection_group_reinsert_extracted_connection(group, nw_connection_create(endpoint, nw_parameters_create())) == false, "reinsert")
    nw_connection_group_reply(group, context, context, nil)
    var sendFailed = false
    nw_connection_group_send_message(group, nil, endpoint, context) { error in
        sendFailed = error != nil
    }
    expect(sendFailed, "send fail-closed")
    nw_connection_group_cancel(group)
}

func testCConnectionCopyStoredEndpoint() {
    let endpoint = "127.0.0.1".withCString { host in
        "80".withCString { port in
            nw_endpoint_create_host(host, port)
        }
    }
    let parameters = nw_parameters_create()
    let connection = nw_connection_create(endpoint, parameters)
    expect(String(cString: nw_endpoint_get_hostname(nw_connection_copy_endpoint(connection))) == "127.0.0.1", "copied hostname")
}
