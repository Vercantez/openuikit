# Portable SystemConfiguration

This frontier implements the iOS `SCNetworkReachability` ABI as a real
Objective-C-compatible framework. It covers all reachability APIs exercised by
the pinned corpus: name/address/address-pair targets, the exact flag OptionSet,
callbacks and context ownership, dispatch/run-loop registration, current flags,
error status, and cancellation of notification delivery.

External connectivity starts **unknown**. The framework does not turn DNS or a
socket's existence into a fabricated route. The Linux application host calls
`OpenSystemConfigurationSetDefaultReachability` when its actual route monitor
changes; live targets receive coalesced callbacks and later targets inherit the
state. Loopback names and addresses are resolved locally and deterministically.
Until the application host owns cross-runtime dispatch/run-loop objects,
callbacks are delivered cooperatively and serially on the host lifecycle
executor.

The guest CoreFoundation boundary does not yet provide constant CFString
objects or CFError construction. Accordingly, `SCCopyLastError()` and
`kCFErrorDomainSystemConfiguration` are fail-closed (`NULL`), while `SCError()`
and `SCErrorString()` expose the complete reachability status used by existing
clients. This avoids embedding an invalid host or Apple CoreFoundation object
inside the Mach-O framework.

The evidence ledger pins six untouched applications. Firefox's complete
`Reachability.swift` is independently typechecked without edits against the
framework during the focused platform proof; the repository-owned consumer
keeps the same public call shapes available to the production package gate.
