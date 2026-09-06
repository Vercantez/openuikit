import Foundation
import Network

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testCContentContextGetSet() {
    let context = "payload".withCString { nw_content_context_create($0) }
    expect(nw_content_context_copy_antecedent(context) == nil, "copy_antecedent")
    expect(nw_content_context_get_expiration_milliseconds(context) == 0, "get_expiration")
    expect(nw_content_context_get_is_final(context) == false, "get_is_final")
    expect(nw_content_context_get_relative_priority(context) == 0, "get_relative_priority")
    let identifier = nw_content_context_get_identifier(context)
    expect(String(cString: identifier) == "payload", "get_identifier")
    nw_content_context_set_antecedent(context, nil)
    nw_content_context_set_expiration_milliseconds(context, 10)
    expect(nw_content_context_get_expiration_milliseconds(context) == 10, "set_expiration")
    nw_content_context_set_is_final(context, true)
    expect(nw_content_context_get_is_final(context), "set_is_final")
    nw_content_context_set_relative_priority(context, 0.5)
    expect(nw_content_context_get_relative_priority(context) == 0.5, "set_relative_priority")
    let metadata = nw_udp_create_metadata()
    nw_content_context_set_metadata_for_protocol(context, metadata)
    expect(nw_content_context_copy_protocol_metadata(context, nw_protocol_copy_udp_definition()) != nil, "copy_protocol_metadata")
    var visited = 0
    nw_content_context_foreach_protocol_metadata(context) { _, _ in visited += 1 }
    expect(visited == 1, "foreach stored metadata")
}

func testCBrowserCreateAndCopy() {
    let type = "_http._tcp".withCString { typePtr in
        nw_browse_descriptor_create_bonjour_service(typePtr, nil)
    }
    expect(nw_browse_descriptor_get_include_txt_record(type) == false, "include_txt default")
    nw_browse_descriptor_set_include_txt_record(type, true)
    let browser = nw_browser_create(type, nw_parameters_create())
    _ = nw_browser_copy_browse_descriptor(browser)
    _ = nw_browser_copy_parameters(browser)
    nw_browser_set_queue(browser, DispatchQueue(label: "c.browser"))
    nw_browser_set_state_changed_handler(browser) { _, _ in }
    nw_browser_set_browse_results_changed_handler(browser) { _, _, _ in }
    nw_browser_start(browser)
    nw_browser_cancel(browser)
}

func testCAdvertiseDescriptorCreate() {
    "app".withCString { name in
        let descriptor = nw_advertise_descriptor_create_application_service(name)
        expect(nw_advertise_descriptor_get_no_auto_rename(descriptor) == false, "no_auto_rename")
        nw_advertise_descriptor_set_no_auto_rename(descriptor, true)
        expect(nw_advertise_descriptor_copy_txt_record_object(descriptor) == nil, "copy_txt")
        nw_advertise_descriptor_set_txt_record_object(descriptor, nil)
        nw_advertise_descriptor_set_txt_record(descriptor, nil, 0)
        expect(nw_advertise_descriptor_get_application_service_name(descriptor) == nil, "application_service_name")
    }
    "_http._tcp".withCString { type in
        expect(nw_advertise_descriptor_create_bonjour_service(nil, type, nil) == nil, "bonjour advertise fail-closed")
    }
}
