import Foundation

/// Process-local discovery event. Darwin's daemon does not receive this
/// object; `DDDiscoverySession.report` retains it in-process only.
public class DDDeviceEvent: NSObject {
    public enum EventType: Int, Sendable, Hashable {
        case unknown = 0
        case deviceFound = 40
        case deviceLost = 41
        case deviceChanged = 42
    }

    public let eventType: EventType
    public let device: DDDevice

    @available(*, unavailable)
    public override init() {
        fatalError("DDDeviceEvent requires init(eventType:device:)")
    }

    public init(eventType type: EventType, device: DDDevice) {
        self.eventType = type
        self.device = device
        super.init()
    }
}

public func DDEventTypeToString(_ inValue: DDDeviceEvent.EventType) -> String {
    switch inValue {
    case .unknown: return "DDEventTypeUnknown"
    case .deviceFound: return "DDEventTypeDeviceFound"
    case .deviceLost: return "DDEventTypeDeviceLost"
    case .deviceChanged: return "DDEventTypeDeviceChanged"
    }
}
