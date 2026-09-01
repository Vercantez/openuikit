import Dispatch
import Foundation
import SystemConfiguration

private func reflectedType<T>(of value: T) -> String {
    String(reflecting: T.self)
}

@main
struct SystemConfigurationInterfaceOracle {
    static func main() {
        print(
            "layout=flags:\(MemoryLayout<SCNetworkReachabilityFlags>.size),"
                + "context:\(MemoryLayout<SCNetworkReachabilityContext>.size)"
        )
        print(
            "flags=transient:\(SCNetworkReachabilityFlags.transientConnection.rawValue),"
                + "reachable:\(SCNetworkReachabilityFlags.reachable.rawValue),"
                + "required:\(SCNetworkReachabilityFlags.connectionRequired.rawValue),"
                + "traffic:\(SCNetworkReachabilityFlags.connectionOnTraffic.rawValue),"
                + "intervention:\(SCNetworkReachabilityFlags.interventionRequired.rawValue),"
                + "demand:\(SCNetworkReachabilityFlags.connectionOnDemand.rawValue),"
                + "local:\(SCNetworkReachabilityFlags.isLocalAddress.rawValue),"
                + "direct:\(SCNetworkReachabilityFlags.isDirect.rawValue),"
                + "wwan:\(SCNetworkReachabilityFlags(rawValue: 1 << 18).rawValue)"
        )
        print("signature-name=\(reflectedType(of: SCNetworkReachabilityCreateWithName))")
        print("signature-address=\(reflectedType(of: SCNetworkReachabilityCreateWithAddress))")
        print("signature-flags=\(reflectedType(of: SCNetworkReachabilityGetFlags))")
        print("signature-callback=\(reflectedType(of: SCNetworkReachabilitySetCallback))")
        print("signature-dispatch=\(reflectedType(of: SCNetworkReachabilitySetDispatchQueue))")
    }
}
