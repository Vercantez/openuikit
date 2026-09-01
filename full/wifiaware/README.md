# WiFiAware Linux starting point

This directory is an isolated, reviewable starting implementation of Apple's
public `WiFiAware` module for OpenUIKit on Linux. The isolated host gate
builds `libWiFiAware.dylib` from this directory alone. That passing gate is
not integrated Linux success: guest `Network` and `OSLog` are not on that
compile graph.

## Public surface

Only declarations present in the exact canonical graph are public. System-
produced values (`WAPairedDevice`, `PairingInfo`, services, `WAEndpoint`,
`WAPath`, performance reports, empty `WAError` details) have no extra
memberwise constructors; where the graph lists `init(from:)`, tests use that
Codable path.

Runtime-proven (`implemented`) behavior includes:

- Fail-closed `WACapabilities` (empty features, maxima `0`)
- `WAParameters` including the graph `init(performanceMode:)`
- `WAError` case tags and `LocalizedError` strings via Codable round-trip
- Empty `WAService.allServices`
- Publisher/subscriber configuration tokens and `wifiAware(_:active:)`
- `WAPairedDevice.allDevices` / `current()` / `next()` throwing
  `wifiAwareUnsupported`

System-produced properties that compile but cannot be constructed from the
public graph (`WAEndpoint`, `WAPath`) and AsyncSequence protocol-extension
sugar are `declared`. Network-facing signatures that need missing guest
Network types, or that do not compile in the isolated gate, are `deferred`.

## Fail-closed boundaries

| Operation | Linux behavior |
| --- | --- |
| Hardware / feature query | `supportedFeatures == []`, maxima `0` |
| Pairing store | `allDevices.current()` and iteration throw `WAError.wifiAwareUnsupported` |
| Declared services | `allServices` is `[:]` |
| `NWBrowser` / `NWListener.Service` / providers | Deferred; no WiFiAware-owned lookalike types |
| Entitlements, UI pairing, datapath | Not implemented; never reported as success |

When compiled against the guest `Network` module, `NWParameters.wifiAware`
stores parameters, `NWError.wifiAware` is `nil`, and `NWPath.wifiAware`
throws `wifiAwareUnsupported`. Those extensions are not part of the isolated
dylib.

## Future EC2 identity run

`tests/agent/WiFiAwareDependencyIdentity.swift` is not executed by the
isolated host gate. A clean EC2 run must build actual guest Foundation,
`os`/`OSLog`, and `Network` modules/dylibs first, build WiFiAware with their
`-I` and `-L` paths, link a client that imports all four modules, pass real
`Network.NWParameters` / `NWPath` / `NWError` / `NWListener` values through
the available integration points, run with `LD_LIBRARY_PATH`, and print
`WIFIAWARE_DEPENDENCY_IDENTITY_OK` only after assertions pass. Guest Network
has no `NWBrowser`, so browse descriptor/endpoint APIs stay deferred.

See `oracle-questions.tsv` for Apple payload, entitlement, and UI questions.
