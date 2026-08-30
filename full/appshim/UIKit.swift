// Legacy diagnostic UIKit shim.
//
// The production full build compiles ~/uikit/Sources/UIKitShim/UIKit.swift
// verbatim. Keep this older app_probe input on the same re-export contract so
// a diagnostic cannot reintroduce the rival-IndexPath configuration that the
// production path rejects: use the complete Foundation umbrella when it is
// actually available, otherwise use FoundationEssentials' canonical value
// types, then export OpenUIKit's UIKit surface.
#if canImport(Foundation)
@_exported import Foundation
#elseif canImport(FoundationEssentials)
@_exported import FoundationEssentials
#endif
@_exported import OpenUIKit
