import Foundation
import Network

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testCConnectionCopyAndBatch() {
    let endpoint = "127.0.0.1".withCString { host in
        "80".withCString { port in
            nw_endpoint_create_host(host, port)
        }
    }
    let parameters = nw_parameters_create()
    let connection = nw_connection_create(endpoint, parameters)
    let copiedEndpoint = nw_connection_copy_endpoint(connection)
    _ = copiedEndpoint
    let copiedParameters = nw_connection_copy_parameters(connection)
    _ = copiedParameters
    expect(nw_connection_copy_current_path(connection) != nil, "copy_current_path")
    let description = nw_connection_copy_description(connection)
    expect(description.pointee == 0, "copy_description empty")
    expect(nw_connection_get_maximum_datagram_size(connection) == 0, "maximum_datagram_size")
    var batched = false
    nw_connection_batch(connection) { batched = true }
    expect(batched, "batch")
    nw_connection_cancel_current_endpoint(connection)
    nw_connection_force_cancel(connection)
    nw_connection_restart(connection)
    var sawReport = false
    nw_connection_access_establishment_report(connection, DispatchQueue(label: "c.est")) { report in
        expect(report == nil, "no fabricated establishment report")
        sawReport = true
    }
    expect(sawReport, "access_establishment_report")
    let transfer = nw_connection_create_new_data_transfer_report(connection)
    _ = transfer
}

func testCConnectionHandlersAndIO() {
    let endpoint = "127.0.0.1".withCString { host in
        "9".withCString { port in
            nw_endpoint_create_host(host, port)
        }
    }
    let parameters = nw_parameters_create()
    let connection = nw_connection_create(endpoint, parameters)
    nw_connection_set_queue(connection, DispatchQueue(label: "c.conn"))
    nw_connection_set_state_changed_handler(connection) { _, _ in }
    nw_connection_set_viability_changed_handler(connection) { _ in }
    nw_connection_set_better_path_available_handler(connection) { _ in }
    nw_connection_set_path_changed_handler(connection) { _ in }
    var received = false
    nw_connection_receive(connection, 1, 8) { content, _, complete, error in
        expect(content == nil, "receive content nil")
        expect(complete == false, "receive not complete")
        expect(error != nil, "receive fail-closed")
        received = true
    }
    expect(received, "receive")
    var receivedMessage = false
    nw_connection_receive_message(connection) { content, _, _, error in
        expect(content == nil, "receive_message nil")
        expect(error != nil, "receive_message fail-closed")
        receivedMessage = true
    }
    expect(receivedMessage, "receive_message")
    let context = "default".withCString { nw_content_context_create($0) }
    var sent = false
    nw_connection_send(connection, nil, context, true) { error in
        expect(error != nil, "send fail-closed")
        sent = true
    }
    expect(sent, "send")
    let definition = nw_protocol_copy_tcp_definition()
    expect(nw_connection_copy_protocol_metadata(connection, definition) == nil, "copy_protocol_metadata")
}
