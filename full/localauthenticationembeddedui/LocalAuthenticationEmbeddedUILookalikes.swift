import Foundation

#if canImport(LocalAuthentication)
import LocalAuthentication
#endif
#if canImport(UIKit)
import UIKit
#endif

// Isolated-host stand-ins for UIKit and LocalAuthentication types named by the
// public LocalAuthenticationEmbeddedUI surface. The sealed host gate compiles
// this module alone. When a real `UIKit` / `LocalAuthentication` module is on
// the link line, these blocks compile out. They are not a Linux UIKit or
// LocalAuthentication port and must not be cited as proof of those identities.

#if !canImport(UIKit)

/// UIKit-owned window. Isolation stand-in only.
open class UIWindow: NSObject {
    public override init() {
        super.init()
    }
}

#endif

#if !canImport(LocalAuthentication)

/// LocalAuthentication-owned right. Isolation stand-in only.
///
/// `State` raw values match Apple's `LARightState` order recorded by the
/// in-tree LocalAuthentication port from `LARight.h`: unknown (0),
/// authorizing (1), authorized (2), notAuthorized (3).
open class LARight: NSObject {
    public enum State: Int, Sendable {
        case unknown = 0
        case authorizing = 1
        case authorized = 2
        case notAuthorized = 3
    }

    public override init() {
        super.init()
    }

    private let lock = NSLock()
    private var _state: State = .unknown

    open var tag: Int = 0

    open var state: State {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _state
        }
        set {
            lock.lock()
            _state = newValue
            lock.unlock()
        }
    }
}

#endif
