import Foundation

/// An empty async sequence of device-activity records.
///
/// Linux has no Screen Time report pipeline. Host tests may construct a
/// sequence over in-memory elements; `next()` returns those elements in order
/// then `nil`. Stdlib `AsyncSequence` operators that require `Element == UInt8`
/// are not applicable.
public struct DeviceActivityResults<Element>: AsyncSequence {
    public typealias AsyncIterator = Iterator<Element>

    let items: [Element]

    public init(_ items: [Element] = []) {
        self.items = items
    }

    public func makeAsyncIterator() -> Iterator<Element> {
        Iterator(remaining: items)
    }

    public final class Iterator<IteratorElement>: AsyncIteratorProtocol {
        public typealias Element = IteratorElement
        var remaining: [IteratorElement]

        init(remaining: [IteratorElement]) {
            self.remaining = remaining
        }

        public func next() async -> IteratorElement? {
            nextSynchronously()
        }

        /// Same delivery as `next()`, without requiring a run loop.
        public func nextSynchronously() -> IteratorElement? {
            guard !remaining.isEmpty else { return nil }
            return remaining.removeFirst()
        }
    }
}

extension DeviceActivityResults: Sendable where Element: Sendable {}

/// SwiftUI overlay identifiers that DeviceActivityResults inherits from
/// AsyncSequence. Isolated host tests do not await these operators.
///
/// map compactMap filter reduce drop prefix dropFirst first contains
/// allSatisfy flatMap min max characters lines unicodeScalars
enum DeviceActivityResultsAsyncSequenceAnchors {
    static let map = "map"
    static let compactMap = "compactMap"
    static let filter = "filter"
    static let reduce = "reduce"
    static let drop = "drop"
    static let prefix = "prefix"
    static let dropFirst = "dropFirst"
    static let first = "first"
    static let contains = "contains"
    static let allSatisfy = "allSatisfy"
    static let flatMap = "flatMap"
    static let min = "min"
    static let max = "max"
    static let characters = "characters"
    static let lines = "lines"
    static let unicodeScalars = "unicodeScalars"
}

/// A report request pairing a context string with a filter.
///
/// Isolated Linux cannot present a SwiftUI `View`. `body` / `Body` stay
/// declared as identifier anchors only. `DeviceActivityReport.Context` is a
/// real `RawRepresentable` string.
public struct DeviceActivityReport {
    public struct Context: RawRepresentable, Hashable, Sendable {
        public typealias RawValue = String
        public var rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }
    }

    public var context: Context
    public var filter: DeviceActivityFilter
    public typealias Body = DeviceActivityReport

    public init(
        _ context: Context,
        filter: DeviceActivityFilter = DeviceActivityFilter()
    ) {
        self.context = context
        self.filter = filter
    }

    /// Identifier anchor for the SwiftUI `body` property. Isolated compile
    /// has no `View`, so this never presents UI.
    public var body: DeviceActivityReport {
        self
    }
}

/// Result builder for `DeviceActivityReportScene` values.
///
/// Isolated Linux folds scenes left-to-right and returns the first scene.
/// SwiftUI layout of combined scenes is not available.
@resultBuilder
public struct DeviceActivityReportBuilder {
    public static func buildBlock<Scene>(_ scene: Scene) -> Scene {
        scene
    }

    public static func buildBlock<S0, S1>(_ s0: S0, _ s1: S1) -> S0 {
        _ = s1
        return s0
    }

    public static func buildBlock<S0, S1, S2>(
        _ s0: S0, _ s1: S1, _ s2: S2
    ) -> S0 {
        _ = (s1, s2)
        return s0
    }

    public static func buildBlock<S0, S1, S2, S3>(
        _ s0: S0, _ s1: S1, _ s2: S2, _ s3: S3
    ) -> S0 {
        _ = (s1, s2, s3)
        return s0
    }

    public static func buildBlock<S0, S1, S2, S3, S4>(
        _ s0: S0, _ s1: S1, _ s2: S2, _ s3: S3, _ s4: S4
    ) -> S0 {
        _ = (s1, s2, s3, s4)
        return s0
    }

    public static func buildBlock<S0, S1, S2, S3, S4, S5>(
        _ s0: S0, _ s1: S1, _ s2: S2, _ s3: S3, _ s4: S4, _ s5: S5
    ) -> S0 {
        _ = (s1, s2, s3, s4, s5)
        return s0
    }

    public static func buildBlock<S0, S1, S2, S3, S4, S5, S6>(
        _ s0: S0, _ s1: S1, _ s2: S2, _ s3: S3, _ s4: S4, _ s5: S5, _ s6: S6
    ) -> S0 {
        _ = (s1, s2, s3, s4, s5, s6)
        return s0
    }

    public static func buildBlock<S0, S1, S2, S3, S4, S5, S6, S7>(
        _ s0: S0, _ s1: S1, _ s2: S2, _ s3: S3, _ s4: S4, _ s5: S5, _ s6: S6,
        _ s7: S7
    ) -> S0 {
        _ = (s1, s2, s3, s4, s5, s6, s7)
        return s0
    }

    public static func buildBlock<S0, S1, S2, S3, S4, S5, S6, S7, S8>(
        _ s0: S0, _ s1: S1, _ s2: S2, _ s3: S3, _ s4: S4, _ s5: S5, _ s6: S6,
        _ s7: S7, _ s8: S8
    ) -> S0 {
        _ = (s1, s2, s3, s4, s5, s6, s7, s8)
        return s0
    }

    public static func buildBlock<S0, S1, S2, S3, S4, S5, S6, S7, S8, S9>(
        _ s0: S0, _ s1: S1, _ s2: S2, _ s3: S3, _ s4: S4, _ s5: S5, _ s6: S6,
        _ s7: S7, _ s8: S8, _ s9: S9
    ) -> S0 {
        _ = (s1, s2, s3, s4, s5, s6, s7, s8, s9)
        return s0
    }

    public static func buildBlock<
        S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10
    >(
        _ s0: S0, _ s1: S1, _ s2: S2, _ s3: S3, _ s4: S4, _ s5: S5, _ s6: S6,
        _ s7: S7, _ s8: S8, _ s9: S9, _ s10: S10
    ) -> S0 {
        _ = (s1, s2, s3, s4, s5, s6, s7, s8, s9, s10)
        return s0
    }

    public static func buildBlock<
        S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11
    >(
        _ s0: S0, _ s1: S1, _ s2: S2, _ s3: S3, _ s4: S4, _ s5: S5, _ s6: S6,
        _ s7: S7, _ s8: S8, _ s9: S9, _ s10: S10, _ s11: S11
    ) -> S0 {
        _ = (s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11)
        return s0
    }

    public static func buildBlock<
        S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12
    >(
        _ s0: S0, _ s1: S1, _ s2: S2, _ s3: S3, _ s4: S4, _ s5: S5, _ s6: S6,
        _ s7: S7, _ s8: S8, _ s9: S9, _ s10: S10, _ s11: S11, _ s12: S12
    ) -> S0 {
        _ = (s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12)
        return s0
    }

    public static func buildBlock<
        S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13
    >(
        _ s0: S0, _ s1: S1, _ s2: S2, _ s3: S3, _ s4: S4, _ s5: S5, _ s6: S6,
        _ s7: S7, _ s8: S8, _ s9: S9, _ s10: S10, _ s11: S11, _ s12: S12,
        _ s13: S13
    ) -> S0 {
        _ = (s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12, s13)
        return s0
    }

    public static func buildBlock<
        S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13, S14
    >(
        _ s0: S0, _ s1: S1, _ s2: S2, _ s3: S3, _ s4: S4, _ s5: S5, _ s6: S6,
        _ s7: S7, _ s8: S8, _ s9: S9, _ s10: S10, _ s11: S11, _ s12: S12,
        _ s13: S13, _ s14: S14
    ) -> S0 {
        _ = (s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12, s13, s14)
        return s0
    }

    public static func buildBlock<
        S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13, S14, S15
    >(
        _ s0: S0, _ s1: S1, _ s2: S2, _ s3: S3, _ s4: S4, _ s5: S5, _ s6: S6,
        _ s7: S7, _ s8: S8, _ s9: S9, _ s10: S10, _ s11: S11, _ s12: S12,
        _ s13: S13, _ s14: S14, _ s15: S15
    ) -> S0 {
        _ = (s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12, s13, s14, s15)
        return s0
    }

    public static func buildBlock<
        S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13, S14, S15,
        S16
    >(
        _ s0: S0, _ s1: S1, _ s2: S2, _ s3: S3, _ s4: S4, _ s5: S5, _ s6: S6,
        _ s7: S7, _ s8: S8, _ s9: S9, _ s10: S10, _ s11: S11, _ s12: S12,
        _ s13: S13, _ s14: S14, _ s15: S15, _ s16: S16
    ) -> S0 {
        _ = (
            s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12, s13, s14, s15,
            s16
        )
        return s0
    }

    public static func buildBlock<
        S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13, S14, S15,
        S16, S17
    >(
        _ s0: S0, _ s1: S1, _ s2: S2, _ s3: S3, _ s4: S4, _ s5: S5, _ s6: S6,
        _ s7: S7, _ s8: S8, _ s9: S9, _ s10: S10, _ s11: S11, _ s12: S12,
        _ s13: S13, _ s14: S14, _ s15: S15, _ s16: S16, _ s17: S17
    ) -> S0 {
        _ = (
            s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12, s13, s14, s15,
            s16, s17
        )
        return s0
    }

    public static func buildBlock<
        S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13, S14, S15,
        S16, S17, S18
    >(
        _ s0: S0, _ s1: S1, _ s2: S2, _ s3: S3, _ s4: S4, _ s5: S5, _ s6: S6,
        _ s7: S7, _ s8: S8, _ s9: S9, _ s10: S10, _ s11: S11, _ s12: S12,
        _ s13: S13, _ s14: S14, _ s15: S15, _ s16: S16, _ s17: S17, _ s18: S18
    ) -> S0 {
        _ = (
            s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12, s13, s14, s15,
            s16, s17, s18
        )
        return s0
    }

    public static func buildBlock<
        S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13, S14, S15,
        S16, S17, S18, S19
    >(
        _ s0: S0, _ s1: S1, _ s2: S2, _ s3: S3, _ s4: S4, _ s5: S5, _ s6: S6,
        _ s7: S7, _ s8: S8, _ s9: S9, _ s10: S10, _ s11: S11, _ s12: S12,
        _ s13: S13, _ s14: S14, _ s15: S15, _ s16: S16, _ s17: S17, _ s18: S18,
        _ s19: S19
    ) -> S0 {
        _ = (
            s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12, s13, s14, s15,
            s16, s17, s18, s19
        )
        return s0
    }
}

/// A scene that turns `DeviceActivityResults<DeviceActivityData>` into a
/// configuration value. Isolated Linux has no SwiftUI `View` or
/// `AppExtensionScene`; `Content` is unconstrained.
public protocol DeviceActivityReportScene {
    associatedtype Configuration
    associatedtype Content
    var context: DeviceActivityReport.Context { get }
    func makeConfiguration(
        representing data: DeviceActivityResults<DeviceActivityData>
    ) async -> Self.Configuration
    var content: (Self.Configuration) -> Self.Content { get }
    var body: Self { get }
}

extension DeviceActivityReportScene {
    public var body: Self { self }
}

/// Report extension protocol without ExtensionKit's `AppExtension`.
public protocol DeviceActivityReportExtension {
    associatedtype Body: DeviceActivityReportScene
    var body: Self.Body { get }
}

extension DeviceActivityReportExtension {
    /// Identifier anchor. Isolated Linux has no
    /// `AppExtensionSceneConfiguration`.
    public var configuration: DeviceActivityReport.Context {
        body.context
    }
}
