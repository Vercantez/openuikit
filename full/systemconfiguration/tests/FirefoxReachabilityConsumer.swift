import Foundation
import SystemConfiguration

enum PortableReachabilityStatus {
    case offline
    case wifi
    case cellular
    case unknown
}

func portableConnectionStatus() -> PortableReachabilityStatus {
    var zeroAddress = sockaddr_in()
    zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
    zeroAddress.sin_family = sa_family_t(AF_INET)

    guard let target = withUnsafePointer(to: &zeroAddress, {
        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
            SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, $0)
        }
    }) else {
        return .unknown
    }
    var flags = SCNetworkReachabilityFlags()
    guard SCNetworkReachabilityGetFlags(target, &flags) else {
        return .unknown
    }
    guard flags.contains(.reachable),
          !flags.contains(.connectionRequired) else {
        return .offline
    }
    return flags.contains(.isWWAN) ? .cellular : .wifi
}

func portableMonitorReachabilityChanges() {
    var context = SCNetworkReachabilityContext(
        version: 0,
        info: nil,
        retain: nil,
        release: nil,
        copyDescription: nil
    )
    guard let target = SCNetworkReachabilityCreateWithName(nil, "example.com")
    else { return }
    _ = SCNetworkReachabilitySetCallback(target, { _, flags, _ in
        _ = flags.contains(.reachable)
    }, &context)
    _ = SCNetworkReachabilityScheduleWithRunLoop(
        target,
        CFRunLoopGetMain(),
        CFRunLoopMode.commonModes.rawValue
    )
}
