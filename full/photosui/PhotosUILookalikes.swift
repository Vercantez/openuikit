@_exported import Foundation

// Module-local stand-ins for types owned by undeclared modules (Photos,
// UIKit, UniformTypeIdentifiers, CoreTransferable, SwiftUI). The isolated
// Linux host compiles Foundation only. Real modules are imported by
// tests/agent/PhotosUIDependencyIdentity.swift for the later EC2 build.
// These lookalikes are compiled only when those modules are absent.

#if !canImport(UniformTypeIdentifiers)
public struct UTType: Hashable, Sendable {
    public let identifier: String

    public init(identifier: String) {
        self.identifier = identifier
    }

    public static let image = UTType(identifier: "public.image")
    public static let jpeg = UTType(identifier: "public.jpeg")
    public static let movie = UTType(identifier: "public.movie")
    public static let video = UTType(identifier: "public.video")
    public static let data = UTType(identifier: "public.data")
    public static let livePhoto = UTType(identifier: "com.apple.live-photo")

    public func conforms(to type: UTType) -> Bool {
        if identifier == type.identifier {
            return true
        }
        switch (identifier, type.identifier) {
        case ("public.jpeg", "public.image"):
            return true
        case ("public.movie", "public.video"), ("public.video", "public.movie"):
            return true
        case ("com.apple.live-photo", "public.image"):
            return true
        default:
            return false
        }
    }
}
#endif

#if !canImport(Photos)
public final class PHPhotoLibrary: NSObject, @unchecked Sendable {
    public static let shared = PHPhotoLibrary()
}

public final class PHLivePhoto: NSObject, @unchecked Sendable {}

public final class PHAdjustmentData: NSObject, @unchecked Sendable {}

public final class PHContentEditingInput: NSObject, @unchecked Sendable {}

public final class PHContentEditingOutput: NSObject, @unchecked Sendable {}

public struct PHAsset: Sendable {
    public enum PlaybackStyle: Int, Hashable, Sendable {
        case unsupported = 0
        case image = 1
        case imageAnimated = 2
        case livePhoto = 3
        case video = 4
        case videoLooping = 5
    }
}
#endif

#if !canImport(UIKit)
open class UIViewController: NSObject, @unchecked Sendable {}

open class UIImage: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
    }
}

open class UIGestureRecognizer: NSObject, @unchecked Sendable {}

open class UITouch: NSObject, @unchecked Sendable {}

#endif

#if os(Linux)
open class NSItemProvider: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
    }
}
#endif

#if !canImport(CoreTransferable)
public protocol Transferable {}

public protocol TransferRepresentation {}

public struct TransferRepresentationVisibility: Equatable, Hashable, Sendable {
    public static let all = TransferRepresentationVisibility()
}

public struct DataRepresentation<Item>: TransferRepresentation {
    public init(exportedContentType: UTType, exporting: @escaping (Item) -> Data) {
        _ = exportedContentType
        _ = exporting
    }
}
#endif

#if !canImport(SwiftUI)
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

public struct Text: View {
    public let storage: String

    public init(_ string: String) {
        storage = string
    }

    public init(_ key: LocalizedStringKey) {
        storage = key.rawValue
    }

    public init<S: StringProtocol>(_ string: S) {
        storage = String(string)
    }

    public var body: EmptyView { EmptyView() }
}

public struct LocalizedStringKey: ExpressibleByStringLiteral, Hashable, Sendable {
    public let rawValue: String

    public init(stringLiteral value: String) {
        rawValue = value
    }
}

@propertyWrapper
public struct Binding<Value> {
    private let getter: () -> Value
    private let setter: (Value) -> Void

    public var wrappedValue: Value {
        get { getter() }
        nonmutating set { setter(newValue) }
    }

    public var projectedValue: Binding<Value> { self }

    public init(get: @escaping () -> Value, set: @escaping (Value) -> Void) {
        getter = get
        setter = set
    }

    public static func constant(_ value: Value) -> Binding<Value> {
        Binding(get: { value }, set: { _ in })
    }
}

public struct Visibility: Equatable, Hashable, Sendable {
    private let rawValue: UInt8

    private init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    public static let automatic = Visibility(rawValue: 0)
    public static let visible = Visibility(rawValue: 1)
    public static let hidden = Visibility(rawValue: 2)
}

public enum Edge: Hashable, Sendable {
    case top
    case leading
    case bottom
    case trailing

    public struct Set: OptionSet, Hashable, Sendable {
        public let rawValue: UInt8

        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }

        public static let top = Set(rawValue: 1 << 0)
        public static let leading = Set(rawValue: 1 << 1)
        public static let bottom = Set(rawValue: 1 << 2)
        public static let trailing = Set(rawValue: 1 << 3)
        public static let all: Set = [.top, .leading, .bottom, .trailing]
    }
}
#endif

public enum PhotosUIUnavailable: Error, Equatable, Sendable {
    case linuxHost(operation: String)
}
