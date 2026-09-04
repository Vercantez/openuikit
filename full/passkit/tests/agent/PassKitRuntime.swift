import Foundation
import PassKit

/// Schema-v2 sealed acceptance compiles `tests/agent/*Tests.swift`.
/// This file records the runtime contract those tests exercise: fail-closed
/// pass validation, empty pass library, Apple Pay unavailability, and
/// OptionSet/enum identities corroborated by pinned macios bindings.
enum PassKitRuntime {
    static let passValidationUnavailable = PassKitPortableError.Code.passValidationUnavailable
}
