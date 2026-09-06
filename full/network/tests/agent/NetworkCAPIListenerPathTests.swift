import Foundation
import Network

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testCListenerCreateAndHandlers() {
    let parameters = nw_parameters_create()
    let listener = nw_listener_create(parameters)
    expect(listener != nil, "listener_create")
    expect(nw_listener_get_port(listener!) == 0, "get_port")
    expect(nw_listener_get_new_connection_limit(listener!) == 0, "get_new_connection_limit")
    nw_listener_set_new_connection_limit(listener!, 4)
    nw_listener_set_queue(listener!, DispatchQueue(label: "c.listener"))
    nw_listener_set_new_connection_handler(listener!) { _ in }
    nw_listener_set_new_connection_group_handler(listener!) { _ in }
    nw_listener_set_state_changed_handler(listener!) { _, _ in }
    nw_listener_set_advertised_endpoint_changed_handler(listener!) { _, _ in }
    nw_listener_set_advertise_descriptor(listener!, nil)
    nw_listener_start(listener!)
    nw_listener_cancel(listener!)
    let endpoint = "127.0.0.1".withCString { host in
        "1".withCString { port in
            nw_endpoint_create_host(host, port)
        }
    }
    let connection = nw_connection_create(endpoint, parameters)
    expect(nw_listener_create_with_connection(connection, parameters) != nil, "create_with_connection")
    "0".withCString { port in
        expect(nw_listener_create_with_port(port, parameters) != nil, "create_with_port")
    }
}

func testCPathQueriesFailClosed() {
    let endpoint = "127.0.0.1".withCString { host in
        "80".withCString { port in
            nw_endpoint_create_host(host, port)
        }
    }
    let connection = nw_connection_create(endpoint, nw_parameters_create())
    let path = nw_connection_copy_current_path(connection)!
    expect(nw_path_copy_effective_local_endpoint(path) == nil, "copy_effective_local_endpoint")
    expect(nw_path_copy_effective_remote_endpoint(path) == nil, "copy_effective_remote_endpoint")
    var gateways = 0
    nw_path_enumerate_gateways(path) { _ in
        gateways += 1
        return false
    }
    expect(gateways == 0, "enumerate_gateways empty")
    var interfaces = 0
    nw_path_enumerate_interfaces(path) { _ in
        interfaces += 1
        return false
    }
    expect(interfaces == 0, "enumerate_interfaces empty")
    expect(nw_path_get_link_quality(path).rawValue == 0, "get_link_quality")
    expect(nw_path_get_status(path).rawValue == 0, "get_status")
    expect(nw_path_get_unsatisfied_reason(path).rawValue == 0, "get_unsatisfied_reason")
    expect(nw_path_has_dns(path) == false, "has_dns")
    expect(nw_path_has_ipv4(path) == false, "has_ipv4")
    expect(nw_path_has_ipv6(path) == false, "has_ipv6")
    expect(nw_path_is_constrained(path) == false, "is_constrained")
    expect(nw_path_is_expensive(path) == false, "is_expensive")
    expect(nw_path_is_ultra_constrained(path) == false, "is_ultra_constrained")
    expect(nw_path_is_equal(path, path) == false, "is_equal fail-closed")
    expect(nw_path_uses_interface_type(path, nw_interface_type_wifi) == false, "uses_interface_type")
}

func testCPathMonitorExtraHandlers() {
    let monitor = nw_path_monitor_create()
    nw_path_monitor_prohibit_interface_type(monitor, nw_interface_type_cellular)
    var cancelled = false
    nw_path_monitor_set_cancel_handler(monitor) { cancelled = true }
    var updated = false
    nw_path_monitor_set_update_handler(monitor) { _ in updated = true }
    nw_path_monitor_set_queue(monitor, DispatchQueue(label: "c.path.extra"))
    nw_path_monitor_start(monitor)
    nw_path_monitor_cancel(monitor)
    _ = cancelled
    _ = updated
}
