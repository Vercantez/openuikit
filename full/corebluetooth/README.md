# CoreBluetooth (Linux starting point)

This directory is a fail-closed portable `CoreBluetooth` module for the
OpenUIKit Linux platform. It reconstructs the public Xcode 26.1 iPhoneOS
Swift surface from the sealed symbol graph. It is not wired into the shared
guest package; that integration is a separate central review step.

Coverage: **460 implemented / 14 declared / 474 total** (fully nondeferred).
The 14 remaining `declared` rows are Apple `_BridgedStoredNSError`
synthesized members. Linux implements the observable `CustomNSError` /
`Hashable` overlay instead; a freshly constructed
`NSError(domain:code:)` does not become `CBError` / `CBATTError`.

## What is real

- `CBUUID` accepts only exact 16-bit (4 hex), 32-bit (8 hex), 128-bit
  hyphenated, or 32-hex encodings. Bytes are big-endian. Bluetooth-base
  UUIDs compact. Malformed strings/data are rejected (`@_spi(OpenUIKitHost)`
  parse helpers return `nil`; public inits trap). Round-trips are tested.
- `CBError` / `CBATTError` expose documented `NS_ERROR_ENUM` codes and
  domains. `typed as NSError` preserves domain, code, and caller `userInfo`
  without inserting `NSLocalizedDescriptionKey`. A typed-origin value may
  remain recoverable with `as?` after that hop, depending on Foundation;
  a freshly constructed `NSError(domain:code:)` does **not** become
  `CBError` here. Tests rehydrate that case via domain/code. This is not
  Apple `_BridgedStoredNSError`. `~=` matches typed errors and `NSError`
  domain/code.
- GATT mutables transfer characteristics, descriptors, and included
  services atomically: prior owners drop the child and stale reverse
  references are cleared.
- Without a simulated adapter, managers settle `.unknown` → `.unsupported`
  during `init` (Linux has no radio to query) and keep
  `CBManager.authorization == .denied`. Scans stay idle, retrieves return
  `[]`, `connect` fail-closes with `didFailToConnect` /
  `operationNotSupported` after the call returns, and
  `cancelPeripheralConnection` does not invent a disconnect for a
  never-connected peripheral. State callbacks hop asynchronously onto the
  supplied queue, once per current delegate.

## Depth pass 2026-09

This pass adds an explicit `@_spi(OpenUIKitHost)` simulated adapter
(`CBHostSimulation`) so tests can exercise the public central / peripheral /
GATT / ATT surface **without a radio**. Installing the adapter is the only
path to `.poweredOn`. Authorization stays `.denied` (no TCC grant).

Implemented against the simulated adapter:

- `CBCentralManager.init(delegate:queue:options:)` with restore-identifier
  `willRestoreState` (host-supplied dictionary or empty restoration keys)
  before `centralManagerDidUpdateState`.
- `scanForPeripherals(withServices:options:)` / `stopScan` / `isScanning`
  with `CBCentralManagerScanOptionAllowDuplicatesKey` (duplicates delivered
  twice per scan session when allowed; once otherwise). `didDiscover`
  dictionaries contain every `CBAdvertisementData*` key.
- `connect` / `cancelPeripheralConnection` with documented callback order:
  call returns, then `didConnect` or `didFailToConnect`; user cancel of a
  connected peripheral delivers `didDisconnectPeripheral(error:)` (nil)
  then the timestamp overlay, plus `connectionEventDidOccur` when
  `registerForConnectionEvents` was used. ANCS-authorized simulated
  peripherals also deliver `didUpdateANCSAuthorizationFor`.
- `retrievePeripherals(withIdentifiers:)` and
  `retrieveConnectedPeripherals(withServices:)` return the same
  `CBPeripheral` instances produced by scan/connect.
- `CBPeripheral` GATT: `discoverServices` /
  `discoverCharacteristics` / `discoverDescriptors` /
  `discoverIncludedServices`, `readValue` / `writeValue(.withResponse)` /
  `writeValue(.withoutResponse)` with `maximumWriteValueLength` (512 / 20),
  `setNotifyValue` driving `didUpdateNotificationStateFor` plus an optional
  notify payload, `readRSSI`, `canSendWriteWithoutResponse`, and
  `peripheralIsReady(toSendWriteWithoutResponse:)`. Oversized
  without-response writes are dropped.
- `CBPeripheralManager.add`, `startAdvertising` (including
  `alreadyAdvertising`), `updateValue(for:onSubscribedCentrals:)`,
  `respond(to:withResult:)`, and host-injected
  `didReceiveRead` / `didReceiveWrite` from a simulated `CBCentral`.
- L2CAP publish/open/unpublish remain fail-closed
  (`CBError.operationNotSupported`); `CBL2CAPChannel` is constructible for
  identity tests via host SPI.

## Fail-closed boundaries

- No BlueZ / HCI / kernel radio. `.poweredOn` exists only while a test
  hook adapter is installed.
- Advertisement/option key **payloads** and
  `CBUUIDCharacteristicObservationScheduleString` are unobserved; constants
  exist as process-local identities only. Simulated advertisement
  *dictionaries* use those constants as keys.
- `CBConnectionEventMatchingOption.peripheralUUIDs` /
  `serviceUUIDs` raw strings are unobserved.
- `cancelPeripheralConnection` does not fabricate a disconnect callback for
  a peripheral that was never connected. Cancel during `.connecting` maps
  to `didFailToConnect` / `operationCancelled` (Linux simulation choice).
- Linux has no TCC prompt or Apple restore cache. Restore callbacks fire
  only when `CB*OptionRestoreIdentifierKey` is supplied; restored
  peripherals are never invented.
- `CBCentralManager.supports(.extendedScanAndConnect)` is `false`.

## Tests

`tests/agent/CoreBluetoothRuntime.swift` is the host-gate probe and prints
`COREBLUETOOTH_AGENT_RUNTIME_OK`.

`tests/agent/CoreBluetoothDependencyIdentity.swift` is a future EC2 identity
probe: real Foundation / CoreFoundation / Dispatch / CoreBluetooth imports,
cross-module NSError checks, UUID/GATT/callback proofs, and `ldd` of
`libCoreBluetooth.dylib`. It prints
`COREBLUETOOTH_DEPENDENCY_IDENTITY_OK`. It does not claim an integrated
Linux product until that cold build uses real dependency modules.

Expected sealed-gate markers:

```
CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean
FRAMEWORK_FANOUT_REFERENCE_OK
COREBLUETOOTH_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=CoreBluetooth dylib=libCoreBluetooth.dylib
```
