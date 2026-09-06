import Foundation
import Network

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testCFramerMessageObjectValues() {
    let definition = "role".withCString { ident in
        nw_framer_create_definition(ident, UInt32(NW_FRAMER_CREATE_FLAGS_DEFAULT)) { _ in
            nw_framer_start_result_ready
        }
    }
    let options = nw_framer_create_options(definition)
    "role".withCString { key in
        nw_framer_options_set_object_value(options, key, "client")
        expect(nw_framer_options_copy_object_value(options, key) as? String == "client", "options object")
    }
    let message = nw_framer_protocol_create_message(definition)
    "n".withCString { key in
        nw_framer_message_set_object_value(message, key, 4)
        expect(nw_framer_message_copy_object_value(message, key) as? Int == 4, "message object")
        expect(nw_framer_message_access_value(message, key) { $0 == nil }, "raw value absent")
    }
}

func testCFramerHostParseWriteReady() {
    var captured: nw_framer_t?
    let definition = "length-prefix".withCString { ident in
        nw_framer_create_definition(ident, 0) { framer in
            captured = framer
            nw_framer_mark_ready(framer)
            return nw_framer_start_result_ready
        }
    }
    expect(captured != nil, "start handler received framer")
    let framer = captured!
    let bytes: [UInt8] = [0x00, 0x04, 1, 2, 3, 4]
    let message = nw_framer_protocol_create_message(definition)
    bytes.withUnsafeBufferPointer { buffer in
        nw_framer_deliver_input(framer, buffer.baseAddress!, bytes.count, message, true)
    }
    var parsed = 0
    var temp = [UInt8](repeating: 0, count: 6)
    let ok = temp.withUnsafeMutableBufferPointer { buffer in
        nw_framer_parse_input(framer, 2, 6, buffer.baseAddress) { pointer, length, complete in
            expect(complete, "complete")
            expect(length >= 2, "length")
            parsed = pointer?.pointee == 0 ? length : 0
            return min(length, 2)
        }
    }
    expect(ok, "parse_input")
    expect(parsed >= 2, "consumed header")
    let payload: [UInt8] = [9, 9]
    payload.withUnsafeBufferPointer { buffer in
        nw_framer_write_output(framer, buffer.baseAddress!, payload.count)
    }
    nw_framer_write_output_data(framer, DispatchData.empty)
    expect(nw_framer_write_output_no_copy(framer, 2), "write_no_copy")
    expect(nw_framer_parse_output(framer, 1, 8, nil) { _, length, _ in length }, "parse_output")
    nw_framer_mark_failed_with_error(framer, 5)
    nw_framer_pass_through_input(framer)
    nw_framer_pass_through_output(framer)
    var woke = false
    nw_framer_set_wakeup_handler(framer) { _ in woke = true }
    nw_framer_schedule_wakeup(framer, 0)
    expect(woke, "wakeup")
    nw_framer_set_input_handler(framer) { _ in 0 }
    nw_framer_set_output_handler(framer) { _, _, _, _ in }
    nw_framer_set_stop_handler(framer) { _ in true }
    nw_framer_set_cleanup_handler(framer) { _ in }
    nw_framer_async(framer) { }
    _ = nw_framer_copy_local_endpoint(framer)
    _ = nw_framer_copy_remote_endpoint(framer)
    _ = nw_framer_copy_options(framer)
    _ = nw_framer_copy_parameters(framer)
    _ = nw_framer_message_create(framer)
    "raw".withCString { key in
        nw_framer_message_set_value(nw_framer_message_create(framer), key, nil, nil)
    }
    expect(nw_framer_prepend_application_protocol(framer, nw_tcp_create_options()) == false, "prepend fail-closed")
    expect(nw_framer_deliver_input_no_copy(framer, 1, nw_framer_message_create(framer), true), "deliver no copy remaining")
}
