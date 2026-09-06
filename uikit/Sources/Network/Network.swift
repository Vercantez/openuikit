// Fail-closed Network.framework IPv4/IPv6 address parse for
// Blockzilla/Extensions/URLExtensions.swift:317 `IPv4Address(host) != nil`
// (focus-e2e.md: 1+1). Parse is structural (dotted-quad / colon-hex),
// not a resolver: no DNS, no interface scan.
//
// MEASURED /tmp/agent_merge_tests.log (fresh worktree, release openrender
// then `swift build --build-tests`): this file compiled at [139/247] as
// the package Network product; URLExtensions.swift.o then referenced
// `Network.IPv4Address.init(String)` / `IPv6Address.init(String)` but
// Blockzilla did not depend on this target, so debug openrender/openhost
// died undefined. The Corrupted JSON line in that log is a separate
// empty SwiftCompilerPlugin teardown frame (non-fatal; build continued
// to Linking). See docs/agent_reports/merge-focus4.md.

import Foundation

public struct IPv4Address: Equatable, Sendable {
    public let rawValue: String

    public init?(_ string: String) {
        let parts = string.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 4 else { return nil }
        for part in parts {
            guard let value = Int(part), (0...255).contains(value) else { return nil }
            if part.count > 1 && part.hasPrefix("0") { return nil }
        }
        self.rawValue = string
    }
}

public struct IPv6Address: Equatable, Sendable {
    public let rawValue: String

    public init?(_ string: String) {
        guard string.contains(":") else { return nil }
        self.rawValue = string
    }
}
