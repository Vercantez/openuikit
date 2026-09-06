import Foundation
import Network

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testCWebSocketOptionsRoundTrip() {
    let options = nw_ws_create_options(nw_ws_version_13)
    nw_ws_options_set_auto_reply_ping(options, true)
    nw_ws_options_set_skip_handshake(options, true)
    nw_ws_options_set_maximum_message_size(options, 4096)
    "Sec-WebSocket-Protocol".withCString { name in
        "chat".withCString { value in
            nw_ws_options_add_additional_header(options, name, value)
        }
    }
    "chat".withCString { nw_ws_options_add_subprotocol(options, $0) }
    nw_ws_options_set_client_request_handler(options, DispatchQueue(label: "ws.req")) { request in
        _ = request
        return nw_ws_response_create(nw_ws_response_status_reject, nil)
    }
}

func testCWebSocketMetadataRoundTrip() {
    let metadata = nw_ws_create_metadata(nw_ws_opcode_text)
    expect(nw_ws_metadata_get_opcode(metadata) == nw_ws_opcode_text, "opcode")
    nw_ws_metadata_set_close_code(metadata, nw_ws_close_code_normal_closure)
    expect(nw_ws_metadata_get_close_code(metadata) == nw_ws_close_code_normal_closure, "close")
    _ = nw_ws_metadata_copy_server_response(metadata)
    var pong = false
    nw_ws_metadata_set_pong_handler(metadata, DispatchQueue(label: "ws.pong")) { _ in pong = true }
    _ = pong
}

func testCWebSocketResponseRoundTrip() {
    let response = "chat".withCString { proto in
        nw_ws_response_create(nw_ws_response_status_accept, proto)
    }
    expect(nw_ws_response_get_status(response) == nw_ws_response_status_accept, "status")
    expect(String(cString: nw_ws_response_get_selected_subprotocol(response)!) == "chat", "subprotocol")
    "X-Test".withCString { name in
        "1".withCString { value in
            nw_ws_response_add_additional_header(response, name, value)
        }
    }
    var headers = 0
    expect(
        nw_ws_response_enumerate_additional_headers(response) { name, value in
            expect(String(cString: name) == "X-Test", "header name")
            expect(String(cString: value) == "1", "header value")
            headers += 1
            return true
        },
        "enumerate headers"
    )
    expect(headers == 1, "one header")
}
