// First reusable Foundation umbrella slice for Linux-hosted Mach-O guests.
// FoundationEssentials owns its value types. OpenUIKit continues to own the
// archive/bundle identities it was compiled against while the complete
// swift-foundation umbrella remains future work.
@_exported import FoundationEssentials
import OpenUIKit

public typealias NSCoder = OpenUIKit.NSCoder
public typealias Bundle = OpenUIKit.Bundle

public extension UIApplication {
    func canOpenURL(_ url: URL) -> Bool {
        canOpenURL(url.absoluteString)
    }

    func open(
        _ url: URL,
        options: [OpenExternalURLOptionsKey: Any] = [:],
        completionHandler: ((Bool) -> Void)? = nil
    ) {
        open(
            url.absoluteString,
            options: options,
            completionHandler: completionHandler
        )
    }
}
