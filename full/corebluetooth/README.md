# CoreBluetooth (Linux starting point)

This directory is a fail-closed portable `CoreBluetooth` module for the
OpenUIKit Linux platform. It reconstructs the public Xcode 26.1 iPhoneOS
Swift surface from the sealed symbol graph. It is not wired into the shared
guest package; that integration is a separate central review step.

## What is real

- `CBUUID` parses 16-bit, 32-bit, and 128-bit Bluetooth UUID strings and
  `Data` values, expands the Bluetooth base UUID, compact-forms `uuidString`
  and `data`, and compares equal across short and expanded forms. `UUID` and
  `CFUUID` initializers are implemented.
- Public error types `CBError` and `CBATTError` use the documented
  `NS_ERROR_ENUM` raw values and domains `CBErrorDomain` /
  `CBATTErrorDomain`. Caller `userInfo` is preserved; hashing uses only the
  code.
- Enumerations, option sets, advertisement/option keys, and GATT assigned-
  number strings (`2900`–`2906`, plus Apple's documented L2CAP PSM UUID)
  are present and usable as dictionary keys and GATT constructors.
- `CBMutableService`, `CBMutableCharacteristic`, and `CBMutableDescriptor`
  store local GATT tree state, including reverse `service` /
  `characteristic` pointers.

## Fail-closed boundaries

Linux has no Apple CoreBluetooth radio, TCC Bluetooth prompt, or system
peripheral cache. Fabricating scans, connections, advertisements, or ATT
traffic would be a privacy and bluetooth-hosting bug.

- `CBManager.state` is always `.unsupported`.
- `CBManager.authorization` and `CBPeripheralManager.authorizationStatus()`
  are always `.denied`.
- `CBCentralManager.supports(_:)` is always `false`.
- `scanForPeripherals` does not set `isScanning` and never discovers
  devices. `retrievePeripherals` / `retrieveConnectedPeripherals` return
  `[]`.
- `startAdvertising` leaves `isAdvertising == false` and reports
  `CBError.operationNotSupported` to the delegate. `add(_:)` and L2CAP
  publish/unpublish do the same. `updateValue(_:for:onSubscribedCentrals:)`
  returns `false`.
- Delegate `centralManagerDidUpdateState` /
  `peripheralManagerDidUpdateState` fire once on the supplied queue (or
  `DispatchQueue.main` when the queue is `nil`) so apps can observe the
  unsupported state. Restored peripherals are never invented.

## Still deferred / oracle-open

Exact Apple binary strings for advertisement and manager option keys are
not in the pinned graph; this port uses the public identifier names.
`CBUUIDCharacteristicObservationScheduleString` is similarly unresolved.
Invalid `CBUUID(string:)` input, restore-identifier behavior, and
connection-event matching raw strings are recorded in
`oracle-questions.tsv`.

`tests/agent/CoreBluetoothRuntime.swift` exercises UUID math, errors,
option sets, mutable GATT, and the fail-closed manager callbacks, then
prints `COREBLUETOOTH_AGENT_RUNTIME_OK`.
