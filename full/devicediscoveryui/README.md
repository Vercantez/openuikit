# DeviceDiscoveryUI

Linux starting point for Apple's public `DeviceDiscoveryUI` module, reconstructed
from the pinned Xcode 26.1 iPhoneOS symbol graph. Isolated host-gate success
is not integrated Linux success.

## Depth pass 2026-09

SDK depth for `DeviceDiscoveryUI` in `full/devicediscoveryui/` (1556 exact IDs).
This is a fresh seed: owned DeviceDiscoveryUI types are implemented with focused
tests; 1536 synthesized SwiftUI.View members on `DevicePicker` and
`DevicePairingView` are `declared` as identity modifiers (a bulk identity walk
is not evidence of Apple layout). `DDDevicePickerViewController.endpoint` is
`declared` because it is `async throws` and the sealed runner has no run loop.

Coverage this round: **19 implemented / 1537 declared / 1556 total**
(1556 nondeferred, floor 1245). No non-enum test is cited by more than 2
implemented rows (10.5% of the 19 implemented rows). There are no enum-case
tables in this census.

Top-5 implemented evidence:

| Rows | Share | Evidence |
| ---: | ---: | --- |
| 2 | 10.5% | `DevicePairingViewTests.swift#testDevicePairingViewBody` (`Body` typealias + `body`) |
| 2 | 10.5% | `DevicePickerTests.swift#testDevicePickerBody` (`Body` typealias + `body`) |
| 1 | 5.3% | `DDDevicePairingAccessTests.swift#testPairingAccessDefault` |
| 1 | 5.3% | `DDDevicePairingAccessTests.swift#testPairingAccessPermanent` |
| 1 | 5.3% | 15 other focused tests, one identifier each |

Environment: `swiftc` reports Swift 6.2.4, target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK` because `scratch/ladder-corpus/focus-ios` is
absent on this VM. The sealed gate compiles with a clean product tree
(`products=clean`). Active Cursor Build observed on this run was
`bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` (campaign expected
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). Starting commit
`343270ce44481a5ae11b87a6e0713e396ada1ef2` matched.

`origin/agent/fw-devicediscoveryui` did not exist; this pass publishes that
branch from the Cursor-created work branch.

`bash full/devicediscoveryui/tests/acceptance/test_host.sh` ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=DeviceDiscoveryUI lane=leaf-full symbols=1556
FRAMEWORK_FANOUT_REFERENCE_OK
DEVICEDISCOVERYUI_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=DeviceDiscoveryUI dylib=libDeviceDiscoveryUI.dylib
```

The campaign inventory stamp `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` is a host-inventory token, not printed by the sealed framework gate. `swiftc` is Swift 6.2.4 / linux and the gate compiled with a clean product tree.

### What is real

- `DDDevicePairingAccess.default` and `.permanent` are distinct values
  (internal two-case kind). Graph docs: default uses the system access for the
  selected device; permanent grants future access. No Apple raw values exist
  in the census.
- `DDDevicePairingViewController.isSupported(_:)` is always `false` on Linux.
  `init(listenerProvider:access:)` stores both arguments.
  `viewDidLoad()` increments a host counter and does not advertise.
- `DDDevicePickerViewController.isSupported(_:using:)` is always `false`.
  `init?(browseDescriptor:parameters:)` and
  `init?(browseDescriptor:parameters:access:)` return `nil`.
- `DevicePairingView` / `DevicePicker` retain label, fallback, and access.
  `body` is the stored fallback (unsupported host). `onSelect` is retained
  and is not invoked from public APIs.

### Fail-closed boundaries

- No Bonjour, Wi-Fi Aware, or pairing sheet. `isSupported` is `false`.
- Picker convenience initializers return `nil`; they do not trap and do not
  start a browser.
- `endpoint` throws `DeviceDiscoveryUIUnavailable.linuxHost` if awaited.
- `DeviceDiscoveryUIHostControl.invokeStoredOnSelect` is host-only proof that
  `init` retained the closure, not a Darwin device selection.

### Still deferred / unobserved

See `oracle-questions.tsv` for Apple-oracle probes: failable-init vs trap,
`endpoint` error identity, DevicePicker fallback vs chrome, supported
`ListenerProvider` shapes, and `onSelect` queue/timing.
