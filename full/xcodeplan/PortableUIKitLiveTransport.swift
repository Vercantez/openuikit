// Optional platform-owned display/input transport for a packaged UIKit app.
//
// Application and vendor sources never import this file.  The generated host
// attaches only when OPENUIKIT_LIVE_TRANSPORT names a host-created shared
// transport file.  With that variable absent, no file is opened, no renderer
// is called, and PortableUIKitApplicationHost follows its established
// headless path unchanged.

import COpenUIKitLiveTransport
import CPortableIO
import UIKit

@MainActor
final class PortableUIKitLiveTransport {
    private let transport: OpaquePointer
    let scale: CGFloat
    private(set) var quitRequested = false
    private(set) var deliveredInputCount: UInt64 = 0
    private(set) var publishedFrameCount: UInt64 = 0

    private init(transport: OpaquePointer, scale: CGFloat) {
        self.transport = transport
        self.scale = scale
    }

    deinit {
        openui_live_transport_guest_close(transport)
    }

    static func attachIfRequested() -> PortableUIKitLiveTransport? {
        guard let rawPath = cpio_getenv("OPENUIKIT_LIVE_TRANSPORT") else {
            return nil
        }
        let path = String(cString: rawPath)
        precondition(!path.isEmpty,
                     "OPENUIKIT_LIVE_TRANSPORT must name a host-created transport file")

        var requestedScale = 1.0
        if let rawScale = cpio_getenv("OPENUIKIT_LIVE_SCALE") {
            let text = String(cString: rawScale)
            guard let parsed = Double(text), parsed.isFinite, parsed > 0 else {
                preconditionFailure("OPENUIKIT_LIVE_SCALE must be a positive finite number")
            }
            requestedScale = parsed
        }
        guard let transport = path.withCString({
            openui_live_transport_guest_open($0)
        }) else {
            preconditionFailure(
                "OPENUIKIT_LIVE_TRANSPORT is not a valid host-created v1 transport")
        }
        print("PORTABLE_UIKIT_LIVE_ATTACHED scale=\(requestedScale)")
        return PortableUIKitLiveTransport(
            transport: transport,
            scale: CGFloat(requestedScale))
    }

    func drainInput(into window: UIWindow) {
        let state = openui_live_transport_guest_state_flags(transport)
        if state & OPENUI_LIVE_STATE_HOST_QUIT != 0 {
            quitRequested = true
        }

        while true {
            var record = openui_live_input_record_v1()
            let result = openui_live_transport_guest_poll_input(transport, &record)
            if result == OPENUI_LIVE_NO_EVENT { return }
            precondition(result == OPENUI_LIVE_EVENT,
                         "live input ring violated its sequence contract: \(result)")
            deliveredInputCount += 1
            let timestamp = Double(record.timestamp_nanoseconds) / 1_000_000_000
            let point = CGPoint(
                x: CGFloat(record.x) / scale,
                y: CGFloat(record.y) / scale)
            switch record.kind {
            case OPENUI_LIVE_INPUT_TOUCH_DOWN:
                window.sendTouch(.began, at: point, timestamp: timestamp,
                                 touchID: Int(record.touch_id))
            case OPENUI_LIVE_INPUT_TOUCH_MOVE:
                window.sendTouch(.moved, at: point, timestamp: timestamp,
                                 touchID: Int(record.touch_id))
            case OPENUI_LIVE_INPUT_TOUCH_UP:
                window.sendTouch(.ended, at: point, timestamp: timestamp,
                                 touchID: Int(record.touch_id))
            case OPENUI_LIVE_INPUT_TOUCH_CANCEL:
                window.sendTouch(.cancelled, at: point, timestamp: timestamp,
                                 touchID: Int(record.touch_id))
            case OPENUI_LIVE_INPUT_TEXT_UTF8:
                var payload = record.payload
                let text = withUnsafeBytes(of: &payload) { bytes in
                    String(decoding: bytes.prefix(Int(record.payload_count)), as: UTF8.self)
                }
                window.sendText(text, timestamp: timestamp)
            case OPENUI_LIVE_INPUT_KEY:
                if let key = Self.key(from: record.key) {
                    window.sendKey(key, timestamp: timestamp)
                }
            case OPENUI_LIVE_INPUT_QUIT:
                quitRequested = true
            default:
                preconditionFailure("live input carried an unknown event kind")
            }
        }
    }

    private static func key(from raw: UInt32) -> UIKeyEventKey? {
        switch raw {
        case OPENUI_LIVE_KEY_BACKSPACE: return .backspace
        case OPENUI_LIVE_KEY_LEFT: return .left
        case OPENUI_LIVE_KEY_RIGHT: return .right
        case OPENUI_LIVE_KEY_UP: return .up
        case OPENUI_LIVE_KEY_DOWN: return .down
        case OPENUI_LIVE_KEY_RETURN: return .return
        default: return nil
        }
    }

    func publish(window: UIWindow) {
        window.layoutIfNeeded()
        let bitmap = UIRenderer.render(window, scale: scale)
        precondition(bitmap.width > 0 && bitmap.height > 0,
                     "live renderer produced an empty frame")
        precondition(bitmap.width <= Int(UInt32.max)
                     && bitmap.height <= Int(UInt32.max)
                     && bitmap.width <= Int(UInt32.max) / 4,
                     "live renderer dimensions exceed the v1 transport")
        let width = UInt32(bitmap.width)
        let height = UInt32(bitmap.height)
        let stride = width * 4
        let result = bitmap.pixels.withUnsafeBytes { bytes in
            openui_live_transport_guest_publish_rgba(
                transport,
                width,
                height,
                stride,
                bytes.bindMemory(to: UInt8.self).baseAddress,
                UInt64(bytes.count))
        }
        if result == OPENUI_LIVE_BUSY {
            return
        }
        precondition(result == OPENUI_LIVE_OK,
                     "live frame publication failed: \(result)")
        publishedFrameCount += 1
    }

    func requestQuit() {
        quitRequested = true
        openui_live_transport_guest_request_quit(transport)
    }
}
