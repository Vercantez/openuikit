# CoreTelephony (Linux starting point)

This directory is a leaf-full Linux port of Apple's public `CoreTelephony`
Swift overlay from the Xcode 26.1 iPhoneOS SDK. It is a reviewable starting
point, not Apple behavioral parity and not a claim of a live telephony stack.

Linux has no baseband radio, SIM, CommCenter, or Apple cellular-plan daemon.
This module therefore implements the public compile-time surface and keeps
every hardware, privacy, entitlement, and Apple-service path **fail-closed**:

- Radio and carrier queries (`CTTelephonyNetworkInfo`, `CTCarrier`) return
  `nil` / `false`. They do not invent an MCC/MNC, ISO country, carrier name,
  or radio-access technology.
- Call monitoring (`CTCall`, `CTCallCenter`) reports no active calls
  (`currentCalls == nil`) and never invokes `callEventHandler`.
- Cellular-data restriction (`CTCellularData`) stays
  `.restrictedStateUnknown` and does not fire the notifier.
- Subscriber APIs expose an empty `subscribers()` list, a stub
  `subscriber()` with `isSIMInserted == false`, `carrierToken == nil`, and
  `refreshCarrierToken() == false`. `identifier` is empty rather than a
  fabricated ICCID.
- Plan provisioning reports `supportsCellularPlan() == false` and
  `supportsEmbeddedSIM == false`. `addPlan` completes with `.fail`.
  `update`, `CTCellularPlanStatus.getTokenWithCompletion`, and
  `checkValidity` complete with an error and never return a token or claim
  that a token is valid.
- Notifications are named and can be observed, but this module does not post
  them.

## What is real

- String constants for call state and radio-access technology, using the
  public identifier names as values (apps compare against the constants).
- `NSNotification.Name.CTRadioAccessTechnologyDidChange` and
  `CTServiceRadioAccessTechnologyDidChange`.
- `CTError` and `kCTErrorDomain*` integer domains (`0`, `1`, `2`).
- Enumerations with `RawRepresentable` / `Hashable` synthesis:
  `CTCellularDataRestrictedState`, `CTCellularPlanCapability`,
  `CTCellularPlanProvisioningAddPlanResult`.
- NSObject subclasses matching the overlay, including `NSSecureCoding` on
  `CTCellularPlanProperties` and `CTCellularPlanProvisioningRequest`.
  Archive keys are Linux-local until an Apple keyed-archive dump exists.
- Both completion-handler and `async` overloads for plan APIs, because Linux
  Swift does not synthesize Apple's concurrency overlay from ObjC.

## Still deferred / oracle

See `oracle-questions.tsv`. In particular this cloud runner has not observed
Apple's exact constant bytes, error payloads, notifier-on-set behavior,
`CTSubscriber.identifier` with no SIM, or NSCoder key names. Those paths stay
fail-closed until a central Apple-oracle probe records them.

The module is not wired into the shared guest package; that is a later
central review step. Run:

```sh
bash tests/acceptance/test_host.sh
```

from this directory, or `bash full/coretelephony/tests/acceptance/test_host.sh`
from the repository root.
