import Foundation
import Network

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testCQUICOptionsGetSetRoundTrip() {
    let options = nw_quic_create_options()
    expect(nw_protocol_options_is_quic(options), "is_quic")
    nw_quic_set_idle_timeout(options, 30)
    expect(nw_quic_get_idle_timeout(options) == 30, "idle_timeout")
    nw_quic_set_initial_max_data(options, 1024)
    expect(nw_quic_get_initial_max_data(options) == 1024, "initial_max_data")
    nw_quic_set_initial_max_stream_data_bidirectional_local(options, 11)
    expect(nw_quic_get_initial_max_stream_data_bidirectional_local(options) == 11, "bidi local")
    nw_quic_set_initial_max_stream_data_bidirectional_remote(options, 12)
    expect(nw_quic_get_initial_max_stream_data_bidirectional_remote(options) == 12, "bidi remote")
    nw_quic_set_initial_max_stream_data_unidirectional(options, 13)
    expect(nw_quic_get_initial_max_stream_data_unidirectional(options) == 13, "uni data")
    nw_quic_set_initial_max_streams_bidirectional(options, 4)
    expect(nw_quic_get_initial_max_streams_bidirectional(options) == 4, "bidi streams")
    nw_quic_set_initial_max_streams_unidirectional(options, 2)
    expect(nw_quic_get_initial_max_streams_unidirectional(options) == 2, "uni streams")
    nw_quic_set_max_datagram_frame_size(options, 1200)
    expect(nw_quic_get_max_datagram_frame_size(options) == 1200, "datagram frame")
    nw_quic_set_max_udp_payload_size(options, 1250)
    expect(nw_quic_get_max_udp_payload_size(options) == 1250, "udp payload")
    nw_quic_set_stream_is_datagram(options, true)
    expect(nw_quic_get_stream_is_datagram(options), "stream datagram")
    nw_quic_set_stream_is_unidirectional(options, true)
    expect(nw_quic_get_stream_is_unidirectional(options), "stream uni")
    "h3".withCString { nw_quic_add_tls_application_protocol(options, $0) }
}

func testCQUICMetadataGetSetRoundTrip() {
    let metadata = nw_ip_create_metadata()
    nw_quic_set_application_error(metadata, 9, "stop")
    expect(nw_quic_get_application_error(metadata) == 9, "application_error")
    expect(String(cString: nw_quic_get_application_error_reason(metadata)! ) == "stop", "reason")
    nw_quic_set_keepalive_interval(metadata, 15)
    expect(nw_quic_get_keepalive_interval(metadata) == 15, "keepalive")
    nw_quic_set_local_max_streams_bidirectional(metadata, 3)
    expect(nw_quic_get_local_max_streams_bidirectional(metadata) == 3, "local bidi")
    nw_quic_set_local_max_streams_unidirectional(metadata, 1)
    expect(nw_quic_get_local_max_streams_unidirectional(metadata) == 1, "local uni")
    expect(nw_quic_get_remote_idle_timeout(metadata) == 0, "remote idle default")
    expect(nw_quic_get_remote_max_streams_bidirectional(metadata) == 0, "remote bidi default")
    expect(nw_quic_get_remote_max_streams_unidirectional(metadata) == 0, "remote uni default")
    nw_quic_set_stream_application_error(metadata, 7)
    expect(nw_quic_get_stream_application_error(metadata) == 7, "stream app error")
    expect(nw_quic_get_stream_id(metadata) == 0, "stream id default")
    expect(nw_quic_get_stream_type(metadata) == 0, "stream type default")
    expect(nw_quic_get_stream_usable_datagram_frame_size(metadata) == 0, "usable datagram")
}
