/// Portable Linux starting point for Apple's public `AutomatedDeviceEnrollment`
/// module.
///
/// The pinned Xcode 26.1 iPhoneOS surface is a single SwiftUI `View` modifier:
/// `automatedDeviceEnrollmentAddition(isPresented:)`. Darwin presents a modal
/// that lets a device administrator add hardware purchased outside Apple's
/// official channel into Apple School Manager, Apple Business Manager, or
/// Apple Business Essentials, after sign-in with a Managed Apple Account that
/// includes device-enrollment privileges.
///
/// Linux has no SwiftUI sheet host, ADE / MDM daemon, Managed Apple Account
/// session, or enrollment entitlement. Applying the modifier records the
/// presentation binding and fail-closes: it never presents UI, never signs
/// in, and never enrolls a device. Darwin annotates the method
/// `@MainActor @preconcurrency`; the isolated host has no UI run loop, so
/// the Linux overlay is usable from synchronous tests.

import Foundation

#if canImport(SwiftUI)
import SwiftUI
#endif

// MARK: - Fail-closed host errors

/// Linux-only result when a host asks to present Apple Automated Device
/// Enrollment UI. Not an Apple NSError domain or ADE/MDM status code.
public enum AutomatedDeviceEnrollmentUnavailable: Error, Equatable, Hashable, Sendable {
    /// The named operation requires Apple ADE / MDM services that Linux
    /// does not provide.
    case linuxHost(operation: String)
}

/// Process-local presentation phase for the addition modifier.
/// Not an Apple ADE session state.
public enum AutomatedDeviceEnrollmentAdditionPhase: Equatable, Hashable, Sendable {
    /// No presentation has been requested since the last idle snapshot.
    case idle
    /// The modifier observed `isPresented == true`.
    case requested
    /// Linux refused to present Apple ADE UI. Terminal for that request.
    case refused
}

/// Process-local box for host tests that need a `Binding<Bool>`.
public final class AutomatedDeviceEnrollmentBoolBox: @unchecked Sendable {
    public var value: Bool

    public init(_ value: Bool) {
        self.value = value
    }
}

// MARK: - Process-local presentation ledger

final class AutomatedDeviceEnrollmentAdditionLedger: @unchecked Sendable {
    static let shared = AutomatedDeviceEnrollmentAdditionLedger()

    private let lock = NSLock()
    private var phaseStorage: AutomatedDeviceEnrollmentAdditionPhase = .idle
    private var lastPresentedStorage: Bool?
    private var attachCountStorage = 0
    private var lastErrorStorage: AutomatedDeviceEnrollmentUnavailable?

    private init() {}

    func recordModifier(isPresented: Bool) {
        lock.lock()
        defer { lock.unlock() }
        attachCountStorage += 1
        lastPresentedStorage = isPresented
        if isPresented {
            phaseStorage = .requested
            lastErrorStorage = AutomatedDeviceEnrollmentUnavailable.linuxHost(
                operation: "automatedDeviceEnrollmentAddition"
            )
            phaseStorage = .refused
        } else {
            phaseStorage = .idle
            lastErrorStorage = nil
        }
    }

    func presentAddition() throws {
        let error = AutomatedDeviceEnrollmentUnavailable.linuxHost(
            operation: "automatedDeviceEnrollmentAddition"
        )
        lock.lock()
        lastErrorStorage = error
        phaseStorage = .refused
        lock.unlock()
        throw error
    }

    func reset() {
        lock.lock()
        phaseStorage = .idle
        lastPresentedStorage = nil
        attachCountStorage = 0
        lastErrorStorage = nil
        lock.unlock()
    }

    var phase: AutomatedDeviceEnrollmentAdditionPhase {
        lock.lock()
        defer { lock.unlock() }
        return phaseStorage
    }

    var lastPresented: Bool? {
        lock.lock()
        defer { lock.unlock() }
        return lastPresentedStorage
    }

    var attachCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return attachCountStorage
    }

    var lastError: AutomatedDeviceEnrollmentUnavailable? {
        lock.lock()
        defer { lock.unlock() }
        return lastErrorStorage
    }
}

/// Linux host-test control. Hidden from ordinary
/// `import AutomatedDeviceEnrollment` clients and not part of Apple's
/// public AutomatedDeviceEnrollment surface.
@_spi(OpenUIKitHost)
public enum AutomatedDeviceEnrollmentHostControl {
    public static func boolBinding(
        to box: AutomatedDeviceEnrollmentBoolBox
    ) -> Binding<Bool> {
        Binding(get: { box.value }, set: { box.value = $0 })
    }

    public static func resetLedger() {
        AutomatedDeviceEnrollmentAdditionLedger.shared.reset()
    }

    public static var additionPhase: AutomatedDeviceEnrollmentAdditionPhase {
        AutomatedDeviceEnrollmentAdditionLedger.shared.phase
    }

    public static var lastPresentedFlag: Bool? {
        AutomatedDeviceEnrollmentAdditionLedger.shared.lastPresented
    }

    public static var modifierAttachCount: Int {
        AutomatedDeviceEnrollmentAdditionLedger.shared.attachCount
    }

    public static var lastUnavailableError: AutomatedDeviceEnrollmentUnavailable? {
        AutomatedDeviceEnrollmentAdditionLedger.shared.lastError
    }

    /// Always throws. Linux never presents ADE addition UI, never signs
    /// in with a Managed Apple Account, and never enrolls a device.
    public static func presentAddition() throws {
        try AutomatedDeviceEnrollmentAdditionLedger.shared.presentAddition()
    }
}

/// Isolated-host probe `View` used to attach the public modifier.
/// Darwin has no such type; it is not Apple's ADE modal.
@_spi(OpenUIKitHost)
public struct AutomatedDeviceEnrollmentHostView: View {
    public typealias Body = EmptyView

    public init() {}

    public var body: EmptyView {
        EmptyView()
    }
}

// MARK: - Public surface

extension View {
    /// Presents a modal view that enables users to add devices to their
    /// organization.
    ///
    /// Darwin (iOS 16+) presents Apple School Manager / Apple Business
    /// Manager / Apple Business Essentials addition UI after Managed Apple
    /// Account sign-in. The method is unavailable on macOS, watchOS, and
    /// tvOS. Linux records `isPresented` on a process-local ledger and
    /// returns `self` unchanged. It never presents a sheet, never mutates
    /// the binding (Darwin dismiss/reset is unobserved), and never enrolls
    /// hardware.
    ///
    /// - Parameter isPresented: A binding to a Boolean value that determines
    ///   whether to present the view.
    /// - Returns: On Darwin, the modal the system presents. On Linux, the
    ///   receiver, as an identity modifier.
    public func automatedDeviceEnrollmentAddition(
        isPresented: Binding<Bool>
    ) -> some View {
        AutomatedDeviceEnrollmentAdditionLedger.shared.recordModifier(
            isPresented: isPresented.wrappedValue
        )
        return self
    }
}
