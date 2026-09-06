import CoreFoundation

/// Linux starting point for Apple's public `OpenAL` Clang overlay, seeded from
/// the Xcode 26.1 iPhoneOS symbol graph.
///
/// Scalar types, OpenAL 1.1 token values, a software device/context/source/buffer
/// state machine, and documented error codes are real. Hardware capture, Apple
/// Spatial Audio, the 3DMixer, and DAC output stay fail-closed.
public enum OpenALModuleInfo {
    public static let moduleName = "OpenAL"
    public static let renderer = "OpenUIKit software OpenAL"
    public static let vendor = "OpenUIKit"
    public static let version = "1.1 OpenUIKit"
    public static let deviceName = "OpenUIKit Soft"
    public static var deviceNameAsCFString: CFString {
        deviceName.withCString { pointer in
            CFStringCreateWithCString(
                kCFAllocatorDefault,
                pointer,
                CFStringBuiltInEncodings.UTF8.rawValue
            )!
        }
    }
}
