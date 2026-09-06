import Foundation
import Network

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testCErrorFromFailClosedSend() {
    let endpoint = "127.0.0.1".withCString { host in
        "9".withCString { port in
            nw_endpoint_create_host(host, port)
        }
    }
    let connection = nw_connection_create(endpoint, nw_parameters_create())
    var captured: nw_error_t?
    let context = "default".withCString { nw_content_context_create($0) }
    nw_connection_send(connection, nil, context, true) { error in
        captured = error
    }
    expect(captured != nil, "send error")
    expect(nw_error_get_error_domain(captured!) == nw_error_domain_posix, "posix domain")
    expect(nw_error_get_error_code(captured!) == POSIXErrorCode.EOPNOTSUPP.rawValue, "EOPNOTSUPP")
    let cf = nw_error_copy_cf_error(captured!)
    let ns = cf.takeRetainedValue() as NSError
    expect(ns.code == Int(POSIXErrorCode.EOPNOTSUPP.rawValue), "cf code")
}

func testCDataTransferReportCollectZeros() {
    let endpoint = "127.0.0.1".withCString { host in
        "80".withCString { port in
            nw_endpoint_create_host(host, port)
        }
    }
    let connection = nw_connection_create(endpoint, nw_parameters_create())
    let report = nw_connection_create_new_data_transfer_report(connection)
    expect(nw_data_transfer_report_get_state(report) == nw_data_transfer_report_state_collecting, "collecting")
    var collected: nw_data_transfer_report_t?
    nw_data_transfer_report_collect(report, DispatchQueue(label: "c.dtr")) { collected = $0 }
    expect(collected != nil, "collect invoked")
    expect(nw_data_transfer_report_get_state(report) == nw_data_transfer_report_state_collected, "collected")
    expect(nw_data_transfer_report_get_path_count(report) == 1, "one path")
    expect(nw_data_transfer_report_get_duration_milliseconds(report) == 0, "duration")
    expect(nw_data_transfer_report_get_path_radio_type(report, 0) == nw_interface_radio_type_unknown, "radio")
    expect(nw_data_transfer_report_get_received_application_byte_count(report, 0) == 0, "rx app")
    expect(nw_data_transfer_report_get_received_ip_packet_count(report, 0) == 0, "rx ip")
    expect(nw_data_transfer_report_get_received_transport_byte_count(report, 0) == 0, "rx transport")
    expect(nw_data_transfer_report_get_received_transport_duplicate_byte_count(report, 0) == 0, "rx dup")
    expect(nw_data_transfer_report_get_received_transport_out_of_order_byte_count(report, 0) == 0, "rx ooo")
    expect(nw_data_transfer_report_get_sent_application_byte_count(report, 0) == 0, "tx app")
    expect(nw_data_transfer_report_get_sent_ip_packet_count(report, 0) == 0, "tx ip")
    expect(nw_data_transfer_report_get_sent_transport_byte_count(report, 0) == 0, "tx transport")
    expect(nw_data_transfer_report_get_sent_transport_retransmitted_byte_count(report, 0) == 0, "tx retr")
    expect(nw_data_transfer_report_get_transport_minimum_rtt_milliseconds(report, 0) == 0, "min rtt")
    expect(nw_data_transfer_report_get_transport_rtt_variance(report, 0) == 0, "rtt var")
    expect(nw_data_transfer_report_get_transport_smoothed_rtt_milliseconds(report, 0) == 0, "smoothed rtt")
    let interface = nw_data_transfer_report_copy_path_interface(report, 0)
    expect(nw_interface_get_type(interface) == nw_interface_type_loopback, "loopback interface")
    expect(String(cString: nw_interface_get_name(interface)).isEmpty == false, "interface name")
    expect(nw_interface_get_index(interface) > 0, "interface index")
}

func testCTCPAvailableBuffersDefaultZero() {
    let metadata = nw_ip_create_metadata()
    expect(nw_tcp_get_available_receive_buffer(metadata) == 0, "rx buffer")
    expect(nw_tcp_get_available_send_buffer(metadata) == 0, "tx buffer")
}
