// Type existence probe for the real Foundation.NSExtensionContext identity.
// Compile this against an actual staged guest Foundation module, or against
// toolchain Foundation. Never compile it with a test-owned module named
// Foundation.
import Foundation

@inline(never)
func requireFoundationNSExtensionContext() {
    let type: Foundation.NSExtensionContext.Type = NSExtensionContext.self
    _ = type
}

requireFoundationNSExtensionContext()
