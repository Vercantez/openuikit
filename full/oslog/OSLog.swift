// Portable public OSLog framework boundary.
//
// The declarations keep a single identity in the lower-level `os` module so
// sources may freely mix `import os` and `import OSLog`. The OSLog dylib
// re-exports that real runtime rather than compiling a second Logger type.

@_exported import os

public enum OSLogPortable {
    public enum Backend: String, Sendable, Hashable {
        case standardError = "standard-error"
    }

    /// Diagnostics are synchronously written to fd 2 by the shared os runtime.
    public static let backend: Backend = .standardError

    /// Linux/machorun has no Apple unified-log daemon or libswiftos runtime.
    public static let supportsUnifiedLogging = false

    /// Event and interval signposts have visible diagnostic semantics.
    public static let supportsSignposts = true

    /// Generated and object-derived signpost IDs are meaningful per process.
    public static let signpostIdentityScope = "process-local"
}
