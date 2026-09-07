@_exported import OpenUIKit

// Measured Simplenote 9b1bb17: MobileCoreServices is imported by two Swift
// files and the only referenced symbol is UTType.data. The macOS 26.1 SDK
// reports "no such module 'MobileCoreServices'", while the iOS simulator SDK
// provides it; this package port keeps the guest route from silently using
// either SDK.
public typealias UTType = OpenUIKit.UTType
