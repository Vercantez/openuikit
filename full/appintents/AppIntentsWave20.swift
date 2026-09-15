import Foundation

// Wave 20: portable in-process coverage for leftover declared surface.
//
// Everything below runs in-process on Linux. Siri, Shortcuts, Spotlight,
// snippet UI, and Apple-service behavior stay fail-closed or deferred.
// Deliberate non-conversions in this increment are documented in the
// README: `AppIntentsExtension.configuration` refines ExtensionFoundation's
// dependency-owned `AppExtension` (not a declared dependency of this lane,
// and the framework never declares a local substitute for a
// dependency-owned type), and `StartWorkoutIntent.init(style:)` cannot be
// expressed as a protocol-extension initializer with no init requirement
// to delegate to.

// MARK: - Never result members

extension Never {
    /// Apple's AppIntents extends `Never` with explicit `= Never` result
    /// aliases. Linux holds no result payload; the aliases name the
    /// uninhabited type itself.
    public typealias Value = Never
    public typealias Dialog = Never
    public typealias Snippet = Never
    public typealias OpensAppIntent = Never
    public typealias Intent = Never

    /// There is no `Never` instance on this host either; the getter names
    /// the nil payload without ever producing a value.
    public var value: Never? { nil }
}
