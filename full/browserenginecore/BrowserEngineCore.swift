#if canImport(Glibc)
import Glibc
#endif
import CoreFoundation
@_exported import Foundation

#if canImport(AVFoundation)
import AVFoundation
#endif

/// Linux starting point for Apple's public `BrowserEngineCore` module.
///
/// Kevent flag integers and fail-closed C wrappers are real. `BEAudioSession`
/// retains the given session object and never invents audio-routing hardware.
/// Isolated Linux has no kqueue, no `AVAudioSession` daemon, and no
/// arm64e pointer-authentication JIT witness. See `README.md`.

// MARK: - Undeclared foreign types
//
// AVFoundation is not a declared dependency of this seed. `BEAudioSession`
// still needs `AVAudioSession` / `AVAudioSessionPortDescription` in its public
// selectors. Isolated host overlays them as `NSObject`. They are never mixed
// with a real AVFoundation session. See `oracle-questions.tsv`.

#if !canImport(AVFoundation)
/// AVFoundation is not a declared dependency. Audio-session arguments
/// type-check as `NSObject` and are never activated by Linux.
public typealias AVAudioSession = NSObject

/// AVFoundation is not a declared dependency. Port descriptions type-check
/// as `NSObject` and never represent a hardware output.
public typealias AVAudioSessionPortDescription = NSObject
#endif

// MARK: - Fail-closed NSError

/// Linux-local domain. Darwin `setPreferredOutput` NSError identity is
/// unobserved; TBD entitlement / JIT helpers are not public Swift-surface
/// identifiers.
let browserEngineCoreLinuxUnavailableDomain = "BrowserEngineCore.linux.unavailable"

let browserEngineCoreLinuxUnavailableCode = 1

func browserEngineCoreUnavailableError(operation: String) -> NSError {
    let message =
        "Linux has no Apple BrowserEngineCore kqueue, JIT witness, or AVAudioSession routing (\(operation))"
    let cfMessage: CFString = message.withCString { pointer in
        CFStringCreateWithCString(
            kCFAllocatorDefault,
            pointer,
            CFStringBuiltInEncodings.UTF8.rawValue
        )!
    }
    precondition(CFGetTypeID(cfMessage) == CFStringGetTypeID())
    return NSError(
        domain: browserEngineCoreLinuxUnavailableDomain,
        code: browserEngineCoreLinuxUnavailableCode,
        userInfo: [
            NSLocalizedDescriptionKey: message
        ]
    )
}

// MARK: - C macros (imported as computed vars)

/// Apple `BEkevent.h`: `#define BE_KEVENT_NO_FLAGS 0x0`.
public var BE_KEVENT_NO_FLAGS: Int32 { 0x0 }

/// Apple `BEkevent.h`: `#define BE_KEVENT_RETURN_IMMEDIATELY 0x1`.
public var BE_KEVENT_RETURN_IMMEDIATELY: Int32 { 0x1 }

/// PAC discriminator for JIT write-protect. Isolated Linux has no ptrauth:
/// clang's discriminator is 0 without pointer authentication. Darwin's
/// arm64e integer is unobserved.
public var BE_JIT_WRITE_PROTECT_TAG: Int { 0 }

// MARK: - Darwin kevent overlays
//
// `be_kevent` / `be_kevent64` take Darwin `sys/event.h` structs. Linux has
// no kqueue; these overlays exist so the public C signatures type-check.
// Layout matches the public BSD `struct kevent` / `struct kevent64_s`.
// They are not a working kqueue.

/// Darwin `struct kevent` overlay for isolated Linux. Not a kqueue.
public struct kevent: Equatable {
    public var ident: UInt
    public var filter: Int16
    public var flags: UInt16
    public var fflags: UInt32
    public var data: Int
    public var udata: UnsafeMutableRawPointer?

    public init(
        ident: UInt = 0,
        filter: Int16 = 0,
        flags: UInt16 = 0,
        fflags: UInt32 = 0,
        data: Int = 0,
        udata: UnsafeMutableRawPointer? = nil
    ) {
        self.ident = ident
        self.filter = filter
        self.flags = flags
        self.fflags = fflags
        self.data = data
        self.udata = udata
    }

    public static func == (lhs: kevent, rhs: kevent) -> Bool {
        lhs.ident == rhs.ident
            && lhs.filter == rhs.filter
            && lhs.flags == rhs.flags
            && lhs.fflags == rhs.fflags
            && lhs.data == rhs.data
            && lhs.udata == rhs.udata
    }
}

/// Darwin `struct kevent64_s` overlay for isolated Linux. Not a kqueue.
public struct kevent64_s: Equatable {
    public var ident: UInt64
    public var filter: Int16
    public var flags: UInt16
    public var fflags: UInt32
    public var data: Int64
    public var udata: UInt64
    public var ext: (UInt64, UInt64)

    public init(
        ident: UInt64 = 0,
        filter: Int16 = 0,
        flags: UInt16 = 0,
        fflags: UInt32 = 0,
        data: Int64 = 0,
        udata: UInt64 = 0,
        ext: (UInt64, UInt64) = (0, 0)
    ) {
        self.ident = ident
        self.filter = filter
        self.flags = flags
        self.fflags = fflags
        self.data = data
        self.udata = udata
        self.ext = ext
    }

    public static func == (lhs: kevent64_s, rhs: kevent64_s) -> Bool {
        lhs.ident == rhs.ident
            && lhs.filter == rhs.filter
            && lhs.flags == rhs.flags
            && lhs.fflags == rhs.fflags
            && lhs.data == rhs.data
            && lhs.udata == rhs.udata
            && lhs.ext.0 == rhs.ext.0
            && lhs.ext.1 == rhs.ext.1
    }
}

// MARK: - be_kevent / be_kevent64

#if canImport(Glibc)
private func browserEngineCoreSetENOSYS() {
    errno = ENOSYS
}
#else
private func browserEngineCoreSetENOSYS() {}
#endif

/// Darwin `be_kevent`. Linux has no kqueue: always returns `-1` / `ENOSYS`
/// and never writes `eventlist`. Flags, including
/// `BE_KEVENT_RETURN_IMMEDIATELY`, do not invent a successful wait.
public func be_kevent(
    _ kq: Int32,
    _ changelist: UnsafePointer<kevent>!,
    _ nchanges: Int32,
    _ eventlist: UnsafeMutablePointer<kevent>!,
    _ nevents: Int32,
    _ be_flags: UInt32
) -> Int32 {
    _ = kq
    _ = changelist
    _ = nchanges
    _ = eventlist
    _ = nevents
    _ = be_flags
    browserEngineCoreSetENOSYS()
    return -1
}

/// Darwin `be_kevent64`. Linux has no kqueue: always returns `-1` / `ENOSYS`
/// and never writes `eventlist`.
public func be_kevent64(
    _ kq: Int32,
    _ changelist: UnsafePointer<kevent64_s>!,
    _ nchanges: Int32,
    _ eventlist: UnsafeMutablePointer<kevent64_s>!,
    _ nevents: Int32,
    _ flags: UInt32
) -> Int32 {
    _ = kq
    _ = changelist
    _ = nchanges
    _ = eventlist
    _ = nevents
    _ = flags
    browserEngineCoreSetENOSYS()
    return -1
}

/// Linux host-test control. Hidden from ordinary `import BrowserEngineCore`
/// clients and not part of Apple's public BrowserEngineCore surface.
@_spi(OpenUIKitHost)
public enum BrowserEngineCoreHostControl {
    public static var linuxUnavailableDomain: String {
        browserEngineCoreLinuxUnavailableDomain
    }

    public static var linuxUnavailableCode: Int {
        browserEngineCoreLinuxUnavailableCode
    }

    public static func wrappedAudioSession(of session: BEAudioSession) -> AVAudioSession {
        session.hostAudioSession
    }
}
