import Foundation

// Module-local stand-ins for types owned by undeclared modules (SwiftUI,
// UIKit, CoreGraphics). The isolated Linux host compiles Foundation only.
// Real modules are imported by tests/agent/PermissionKitDependencyIdentity.swift
// for the later EC2 build. These lookalikes are compiled only when those
// modules are absent.

#if canImport(CoreGraphics)
import CoreGraphics
#else
public typealias CGImage = AnyObject
#endif

#if canImport(UIKit)
import UIKit
#else
public typealias UIViewController = NSObject
#endif

#if canImport(SwiftUI)
import SwiftUI
#else
public protocol View {
    associatedtype Body: View
    @ViewBuilder var body: Body { get }
}

@resultBuilder
public enum ViewBuilder {
    public static func buildBlock() -> EmptyView {
        EmptyView()
    }

    public static func buildBlock<Content: View>(_ content: Content) -> Content {
        content
    }

    public static func buildExpression<Content: View>(_ content: Content) -> Content {
        content
    }
}

public struct EmptyView: View {
    public init() {}
    public var body: Never { preconditionFailure("EmptyView has no body") }
}

extension Never: View {
    public var body: Never { self }
}
#endif
