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
