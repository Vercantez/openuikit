# AutomatedDeviceEnrollment (Linux starting point)

Leaf-full starting implementation of Apple's public `AutomatedDeviceEnrollment`
surface for Linux. The module is `AutomatedDeviceEnrollment`; the host gate
produces `libAutomatedDeviceEnrollment.dylib`.

This directory is a clean-room Linux starting point seeded from the Xcode 26.1
iPhoneOS 26.1 symbol graph, API digester, TBD exports, and pinned
`dotnet/macios` bindings (which have no AutomatedDeviceEnrollment sources). It
is not wired into the shared guest package; that integration is a later
central-review step.

The pinned public census is **1** precise identifier: the SwiftUI `View`
modifier `automatedDeviceEnrollmentAddition(isPresented:)`.

## Depth pass 2026-09

Fresh seed: no prior `coverage.tsv`. After this pass:
**1 implemented / 0 declared / 0 deferred / 1 total**
(1 nondeferred, floor 1).

The single public identifier has a dedicated top-level `func test*()` that
calls that modifier. There are no public enum/option-set members or C
`k…`/`err…` constants.

Top-5 evidence distribution (share of the 1 implemented row):

| Citations | Evidence |
| ---: | --- |
| 1 | `AutomatedDeviceEnrollmentTests.swift#testAutomatedDeviceEnrollmentAddition` |

No test is cited by more than one implemented row.

## What is real

- Isolated-host `View`, `EmptyView`, `ViewBuilder`, and `Binding` stand-ins
  exist only when SwiftUI is not on the link line. They are not a SwiftUI
  port.
- `Binding<Bool>` get/set stores through the supplied closures.
  `Binding.constant` ignores writes.
- Applying `automatedDeviceEnrollmentAddition(isPresented:)` increments a
  process-local attach count, snapshots the Boolean, and returns `self`.
- `isPresented == false` records phase `.idle` with no error.
- `isPresented == true` records `.requested` then immediately `.refused`
  with `AutomatedDeviceEnrollmentUnavailable.linuxHost(operation:
  "automatedDeviceEnrollmentAddition")`. The binding is not rewritten.

## Fail-closed boundaries

Linux has no ADE / MDM daemon, Managed Apple Account session, Apple School
Manager / Apple Business Manager / Apple Business Essentials UI, or
device-enrollment entitlement.

- The modifier never presents a modal and never enrolls a device.
- `AutomatedDeviceEnrollmentHostControl.presentAddition()` always throws
  the Linux-only unavailable error.
- Darwin `@MainActor` isolation, opaque `some View` identity, and binding
  traffic on dismiss are unobserved (see `oracle-questions.tsv`).
- `AutomatedDeviceEnrollmentUnavailable` is not an Apple NSError domain.

## Environment and gate

`git rev-parse HEAD` at the start of this seed was
`26f5086c5b31ba816742f18d3096152cd32280f4`. `swiftc` is Swift 6.2.4,
target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`
because `scratch/ladder-corpus/focus-ios` is absent from this snapshot.
The sealed framework gate does not require that checkout. The pod
booted from `bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` rather
than campaign `bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`.

`bash full/automateddeviceenrollment/tests/acceptance/test_host.sh` ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=AutomatedDeviceEnrollment lane=leaf-full symbols=1
FRAMEWORK_FANOUT_REFERENCE_OK
AUTOMATEDDEVICEENROLLMENT_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=AutomatedDeviceEnrollment dylib=libAutomatedDeviceEnrollment.dylib
```

The campaign inventory stamp
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`
is a host-inventory token, not printed by the sealed framework gate.
`swiftc` is Swift 6.2.4 / linux and the gate compiled with a clean product
tree (`products=clean`).
