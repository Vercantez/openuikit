# WiFiAware Linux starting point

This directory is an isolated, reviewable starting implementation of Apple's
public `WiFiAware` module for OpenUIKit on Linux. It is compiled as
`libWiFiAware.dylib` by the framework-fanout host gate. It is not Apple
behavioral parity and it does not talk to a radio, pairing daemon, or
entitlement service.

## What is real

- Value types and enums: `WAParameters`, `WAPerformanceMode`,
  `WAAccessCategory`, `WACapabilities.Feature`, `WAPairedDevice` /
  `PairingInfo`, `WAPublishableService`, `WASubscribableService`,
  `WAEndpoint`, `WAPath`, `WAPerformanceReport`.
- `WAError` cases and empty `*Details` structs, including `LocalizedError`
  strings and Codable round-trip of the case tags.
- Publisher and subscriber *configuration*: `WAPublisherListener.wifiAware`,
  `WASubscriberBrowser.wifiAware`, `Action.connecting`, and `Devices`
  selection tokens (`allPairedDevices`, `userSpecifiedDevices`, `selected`,
  `matching`).
- `WAPairedDevice.allDevices` as a throwing `AsyncSequence` whose `current()`
  and `next()` calls fail closed.
- `WACapabilities.supportedFeatures` is empty and the maximum device/service
  counts are zero.
- `WAService.allServices` dictionaries are empty (no Info.plist service table
  is loaded).

`tests/agent/WiFiAwareRuntime.swift` exercises those paths and prints
`WIFIAWARE_AGENT_RUNTIME_OK`.

## Fail-closed boundaries

| Operation | Linux behavior |
| --- | --- |
| Hardware / feature query | `supportedFeatures == []`, maxima `0` |
| Pairing store | `allDevices.current()` and iteration throw `WAError.wifiAwareUnsupported` |
| Declared services | `allServices` is `[:]` |
| Network listener/browser | Not compiled in the isolated gate; Linux `Network` has no `ListenerProvider`, `BrowserProvider`, `NWBrowser`, or `NWListener.Service` |
| Entitlements, UI pairing, datapath | Not implemented; never reported as success |

`#if canImport(Network)` extensions for `NWParameters.wifiAware`,
`NWError.wifiAware` (`nil`), and `NWPath.wifiAware` (throws unsupported) are
present for later package integration. The isolated host gate does not see the
`Network` or `OSLog` modules, so those extensions are not part of this dylib.

## Still deferred

Coverage rows marked `deferred` are the Network-facing Apple signatures that
cannot be named without types this Linux `Network` starting point does not
provide. See `oracle-questions.tsv` for payload, entitlement, and UI questions
that need a central Apple-oracle probe.

Do not treat a passing host gate as evidence that Wi-Fi Aware discovery or
connections work.
