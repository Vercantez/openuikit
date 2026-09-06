# CoreMIDI Linux starting point

This directory is a clean-room Linux starting implementation of Apple's public
`CoreMIDI` overlay, seeded from the iPhoneOS 26.1 symbol graphs. It builds
module `CoreMIDI` and `libCoreMIDI.dylib` without copying Apple SDK headers,
module maps, or TBD bytes. The isolated guest compile links only the Swift
overlay plus `CoreFoundation` / `Foundation` types the overlay already names.

## What is real

- MIDI 1.0 `MIDIPacket` / `MIDIPacketList` builders, packed `MIDIPacketListAdd`
  / `MIDIPacketNext`, and Swift `ByteCollection` / `ByteSequence` /
  `UnsafeMutableMIDIPacketPointer` collection views.
- MIDI 2.0 / UMP `MIDIEventPacket` / `MIDIEventList` builders,
  `MIDIEventListAdd` / `MIDIEventPacketNext` / `MIDIEventListForEachEvent`, and
  `WordCollection` / `WordSequence` views.
- Documented UMP constructors (`MIDI1UP*`, `MIDI2*`, jitter-reduction /
  stream / function-block / flex-data helpers) and
  `MIDIMessageTypeForUPWord`.
- Exact `kMIDI*` error codes (`-10830`…`-10845`), integer limits,
  `MIDIChannelsWholePort = 0xFF`, `MIDITransformType` raw values (including
  add/scale/min/max/mapValue), protocol / object-type / notification /
  message-type enumerations, and option-set members.
- Process-local `kMIDIProperty*` `CFString` identities and in-process
  `MIDIThruConnectionParams` identity maps (`MIDIThruConnectionParamsInitialize`,
  `MIDIValueMap` 128-byte identity).
- Overlay `Sequence` / `Collection` / `BidirectionalCollection` /
  `MutableCollection` witnesses on packet and event views (map, filter,
  indices, slices, sort, partition, shuffle).
- In-process `MIDINetworkHost` / `MIDINetworkConnection` / `MIDINetworkSession`
  contact lists (no Bonjour advertisement; endpoints stay `0`).
- MIDI-CI / UMP class surface: managers with empty discovery, profile/state
  value types, `MIDICISession` / `MIDICIResponder` that refuse to start, and
  `MIDIUMPMutableEndpoint` / `MIDIUMPMutableFunctionBlock` objects that
  construct in-process but throw `CoreMIDISessionError.notPermitted` on
  enable/register/setName.

## Fail-closed boundaries

Linux has no MIDIServer, USB/Bluetooth MIDI driver, or Apple MIDI Network
driver.

- `MIDIClientCreate` / `MIDIClientCreateWithBlock` return `kMIDIServerStartErr`.
- Port create, virtual source/destination create, device/entity setup, and
  Bluetooth driver calls return `kMIDINotPermitted`.
- `MIDISend` / `MIDISendEventList` return `kMIDINoConnection`;
  `MIDIReceived*` / `MIDIFlushOutput` return `kMIDIUnknownEndpoint`.
- `MIDISendSysex` / `MIDISendUMPSysex*` return `kMIDINotPermitted` and do **not**
  invoke `completionProc`.
- Property get returns `kMIDIUnknownProperty`; property set returns
  `kMIDINotPermitted`. Device/source/destination counts are `0`.
- Thru-connection create/find returns `kMIDINotPermitted` /
  `kMIDIObjectNotFound` and does not leak `CFData`.
- MIDI-CI discovery completes with `[]`. Profile enable/disable and UMP
  endpoint mutation throw rather than inventing a successful session.
- `MIDIGetDriverIORunLoop` returns the current `CFRunLoop`; it is not a Darwin
  driver thread.
- Combine `Sequence.publisher` is `unavailable` (Combine is not a dependency).
- Foundation `SortComparator` / `FormatStyle` members stay `declared`.
- Optional-returning `Sequence.flatMap` and deprecated `Collection.index(of:)`
  stay `declared` under Swift 6 warnings-as-errors.

See `oracle-questions.tsv` for questions that need a central Apple-oracle probe.

## Depth pass 2026-09

Coverage of the 1773 exact public IDs (fresh seed; no prior implemented rows):

| status | count |
| --- | ---: |
| implemented | 1705 |
| declared | 58 |
| unavailable | 10 |
| deferred | 0 |
| not-applicable | 0 |

Nondeferred 1763 (floor 887). Combine `publisher` is `unavailable`. Foundation
`sorted(using:)` / `compare` / `formatted` / `sort(using:)` stay `declared`.
Optional `Sequence.flatMap` and `Collection.index(of:)` stay `declared`.

Top-5 implemented evidence distribution (of 1705 implemented rows):

1. `ConstantsTests.swift#testEnumRawValues` — 216 (table-driven enum raw values)
2. `NetworkCITests.swift#testCIAndUMPClasses` — 189
3. `OptionSetTests.swift#testHashableWitnesses` — 85
4. `OptionSetTests.swift#testOptionSetAlgebra` — 84
5. `PacketEventTests.swift#testMIDIPacketCAPI` — 83

`testEnumRawValues` / `testErrorAndLimitConstants` / `testPropertyKeys` /
`testOptionSetMembers` are table-driven enum, `k…`/`err…`, and option-set
member tests. After those constant rows, no remaining test exceeds 40% of the
remaining implemented rows (`testCIAndUMPClasses` is 13.6%).

The campaign inventory stamp `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4
target=linux products=clean` is a host-inventory token, not printed by the
sealed framework gate. This snapshot's `.cursor/verify-cloud-environment.sh`
fails (`missing corpus checkout: scratch/ladder-corpus/focus-ios`). `swiftc`
is Swift 6.2.4 / linux and the gate compiles with a clean product tree. The
sealed gate was not weakened.
