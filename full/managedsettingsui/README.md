# ManagedSettingsUI

Linux starting point for Apple's public `ManagedSettingsUI` module,
reconstructed from the pinned Xcode 26.1 iPhoneOS symbol graph. Isolated
host-gate success is not integrated Linux success.

## Depth pass 2026-09

SDK depth for `ManagedSettingsUI` in `full/managedsettingsui/` (20 exact
IDs). This is a fresh seed: every public identifier is implemented with a
focused synchronous test. There are no enum or option-set members on this
surface, so no table-driven value sharing.

Coverage this round: **20 implemented / 0 declared / 20 total**
(20 nondeferred, floor 16). No test is cited by more than one implemented
row (5% of implemented rows).

Top-5 implemented evidence:

| Rows | Share | Evidence |
| ---: | ---: | --- |
| 1 | 5% | `ShieldConfigurationLabelTests.swift#testShieldConfigurationLabelStruct` |
| 1 | 5% | `ShieldConfigurationLabelTests.swift#testShieldConfigurationLabelInit` |
| 1 | 5% | `ShieldConfigurationLabelTests.swift#testShieldConfigurationLabelText` |
| 1 | 5% | `ShieldConfigurationLabelTests.swift#testShieldConfigurationLabelColor` |
| 1 | 5% | `ShieldConfigurationTests.swift#testShieldConfigurationStruct` |

The remaining fifteen implemented rows each have their own test (eight
`ShieldConfiguration` stored-field/init tests and six
`ShieldConfigurationDataSource` tests).

Environment: `swiftc` reports Swift 6.2.4, target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK` because `scratch/ladder-corpus/focus-ios` is
absent on this VM. The sealed gate compiles with a clean product tree
(`products=clean`). Active Cursor Build observed on this run was
`bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` (campaign expected
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). Starting commit
`342dd2ee859ac3c9369653620a0b8835883008ad` matched.

`bash full/managedsettingsui/tests/acceptance/test_host.sh` ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=ManagedSettingsUI lane=leaf-full symbols=20
FRAMEWORK_FANOUT_REFERENCE_OK
MANAGEDSETTINGSUI_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=ManagedSettingsUI dylib=libManagedSettingsUI.dylib
```

The campaign inventory stamp `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` is a host-inventory token, not printed by the sealed framework gate. `swiftc` is Swift 6.2.4 / linux and the gate compiled with a clean product tree.

### What is real

- `ShieldConfiguration.Label` stores `text` and the `UIColor` object passed
  to `init(text:color:)`. Empty strings are retained.
- `ShieldConfiguration` is a value type with eight stored `let` fields.
  `init` defaults every argument to `nil`. `ShieldConfiguration()` is the
  documented system-default appearance (all fields `nil`).
- `UIBlurEffect.Style` lookalike raw values match UIKit's C enum
  (`extraLight=0`, `light=1`, `dark=2`, `regular=4`, `prominent=5`).
- `ShieldConfigurationDataSource` subclasses `NSObject`. Default
  `configuration(shielding:)` / `configuration(shielding:in:)` overloads
  record the `Application` / `WebDomain` / `ActivityCategory` identities
  and return `ShieldConfiguration()`. Subclasses can override.

### Fail-closed boundaries

- `ManagedSettingsUIHostControl.presentShield` always throws
  `ManagedSettingsUIUnavailable.linuxHost(operation: "presentShield")`.
  Linux never draws a shield, never loads
  `com.apple.ManagedSettingsUI.shield-configuration`, and never talks to a
  Family Controls / Screen Time daemon.
- Default data-source methods never populate `localizedDisplayName` or
  invent an icon from a bundle identifier.
- Isolated-host `UIColor` / `UIImage` / `UIBlurEffect.Style` /
  `Application` / `WebDomain` / `ActivityCategory` types are
  `#if !canImport` stand-ins. They compile out when the real modules are
  on the link line and are not a UIKit or ManagedSettings port.

### Still deferred / unobserved

See `oracle-questions.tsv` for Apple-oracle probes: default
`configuration(shielding:)` stored fields vs system appearance, extension
timeout/queue, blur compositing when `backgroundBlurStyle` is nil,
secondary-button layout when the primary label is nil, `UIColor` trait
resolution, and `dynamic init` extension loading.
