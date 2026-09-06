import Foundation

#if canImport(FileProvider)
import FileProvider
#endif
#if canImport(UIKit)
import UIKit
#endif

// Isolated-host stand-ins for FileProvider and UIKit types named by the
// public FileProviderUI surface. The sealed host gate compiles this module
// alone. When a real `FileProvider` / `UIKit` module is on the link line,
// these blocks compile out. They are not a Linux FileProvider or UIKit port
// and must not be cited as proof of those identities.

#if !canImport(FileProvider)
/// FileProvider-owned domain identifier. Isolation stand-in only.
public struct NSFileProviderDomainIdentifier: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

/// FileProvider-owned item identifier. Isolation stand-in only.
public struct NSFileProviderItemIdentifier: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}
#endif

#if !canImport(UIKit)
/// UIKit-owned view-controller base. Isolation stand-in only.
open class UIViewController: NSObject {
    public override init() {
        super.init()
    }
}
#endif
