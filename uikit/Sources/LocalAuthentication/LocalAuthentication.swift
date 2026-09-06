// Fail-closed LocalAuthentication for Focus AuthenticationManager
// (a2832521 Blockzilla/Utilities/AuthenticationManager.swift:15).
// Headless launch must not prompt: canEvaluatePolicy is false, biometry
// is .none, evaluatePolicy throws notInteractive. MEASURED so
// AppDelegate's authenticateWithBiometrics path sets .loggedin via the
// `guard userEnabledBiometrics, canEvaluatePolicy` early return when
// Settings.biometricLogin is the default false.

import Foundation
@_exported import Combine
@_exported import UIKit

public enum LABiometryType: Int, Sendable {
    case none = 0
    case touchID = 1
    case faceID = 2
    case opticID = 3
}

public enum LAPolicy: Int, Sendable {
    case deviceOwnerAuthenticationWithBiometrics = 1
    case deviceOwnerAuthentication = 2
}

public enum LAError: Error {
    case notInteractive
}

public final class LAContext {
    public var biometryType: LABiometryType = .none
    public var localizedReason: String = ""
    public var localizedCancelTitle: String?

    public init() {}

    public func canEvaluatePolicy(_ policy: LAPolicy, error: UnsafeMutablePointer<NSError?>?) -> Bool {
        _ = (policy, error)
        return false
    }

    public func evaluatePolicy(
        _ policy: LAPolicy,
        localizedReason: String
    ) async throws -> Bool {
        _ = (policy, localizedReason)
        throw LAError.notInteractive
    }
}
