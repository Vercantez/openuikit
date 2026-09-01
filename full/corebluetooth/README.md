# CoreBluetooth (Linux starting point)

This directory is a fail-closed portable `CoreBluetooth` module for the
OpenUIKit Linux platform. It reconstructs the public Xcode 26.1 iPhoneOS
Swift surface from the sealed symbol graph. It is not wired into the shared
guest package; that integration is a separate central review step.

## What is real

- `CBUUID` accepts only exact 16-bit (4 hex), 32-bit (8 hex), 128-bit
  hyphenated, or 32-hex encodings. Bytes are big-endian. Bluetooth-base
  UUIDs compact. Malformed strings/data are rejected (`@_spi(OpenUIKitHost)`
  parse helpers return `nil`; public inits trap). Round-trips are tested.
- `CBError` / `CBATTError` expose documented `NS_ERROR_ENUM` codes and
  domains. `typed as NSError` preserves domain, code, and caller `userInfo`
  without inserting `NSLocalizedDescriptionKey`. `NSError as? CBError` does
  **not** rehydrate; tests rebuild via domain/code. `~=` matches both typed
  errors and `NSError` domain/code.
- GATT mutables transfer characteristics, descriptors, and included
  services atomically: prior owners drop the child and stale reverse
  references are cleared.
- Managers report `.unsupported` / `.denied`, never scan, and deliver
  `centralManagerDidUpdateState` / `peripheralManagerDidUpdateState`
  asynchronously on the supplied queue, exactly once per current delegate.
  Replacing the delegate, including after a nil assignment, delivers initial
  state to the new object. `connect` fail-closes with
  `didFailToConnect` after the call returns; `cancelPeripheralConnection`
  does not invent a disconnect for a never-connected peripheral.

## Fail-closed boundaries

- Advertisement/option key **payloads** and
  `CBUUIDCharacteristicObservationScheduleString` are unobserved; constants
  exist as process-local identities only.
- `CBConnectionEventMatchingOption.peripheralUUIDs` /
  `serviceUUIDs` raw strings are unobserved.
- `cancelPeripheralConnection` does not fabricate a disconnect callback for
  a peripheral that was never connected.
- Linux has no radio, TCC prompt, or restore cache. Scans stay idle,
  retrieves return `[]`, advertising/`add` fail with
  `CBError.operationNotSupported`.

## Tests

`tests/agent/CoreBluetoothRuntime.swift` is the host-gate probe and prints
`COREBLUETOOTH_AGENT_RUNTIME_OK`.

`tests/agent/CoreBluetoothDependencyIdentity.swift` is a future EC2 identity
probe: real Foundation / CoreFoundation / Dispatch / CoreBluetooth imports,
cross-module NSError checks, UUID/GATT/callback proofs, and `ldd` of
`libCoreBluetooth.dylib`. It prints
`COREBLUETOOTH_DEPENDENCY_IDENTITY_OK`. It does not claim an integrated
Linux product until that cold build uses real dependency modules.
