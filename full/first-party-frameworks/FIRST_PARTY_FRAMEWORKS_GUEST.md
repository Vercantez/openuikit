# Seven first-party guest frameworks

This production slice adds independent module and dylib boundaries for
`LocalAuthentication`, `SafariServices`, `Network`, `StoreKit`,
`AudioToolbox`, `CoreHaptics`, and `PassKit`. The core guest package publishes
an ARM64 Mach-O `lib<Framework>.dylib` with install ID
`@rpath/lib<Framework>.dylib` for every name. Application source code is not
rewritten to use these modules.

## Service boundary

The portable implementations preserve value construction, mutable request
state, callback cardinality, delegate delivery, and in-memory histories where
those behaviors do not require an Apple service. They fail closed at every OS
service boundary:

- `LAContext` reports no enrolled authenticator and returns or throws a typed
  `LAError`; it never authenticates a user.
- `SFSafariViewController` preserves its URL/configuration and reports an
  explicitly failed initial load. Content-blocker operations return typed
  errors. There is no browser, WebKit renderer, or network-success claim.
- Network paths begin unsatisfied. Connections and listeners transition to a
  typed unsupported failure, and send/receive callbacks report failure.
- Store review requests are countable requests, not successful presentations.
  Catalog, purchase, synchronization, and classic payment operations return
  empty results or typed failures without inventing App Store state.
- AudioToolbox records requested sound IDs but exposes the playback disposition
  as unsupported. It does not claim audio output.
- CoreHaptics constructs patterns and players, reports hardware capabilities
  false, and throws `notSupported` when playback starts.
- PassKit constructs payment/pass request values, rejects unverifiable signed
  pass data, reports payment/pass-library capabilities false, and returns false
  from presentation attempts.

Native iOS can report App Store payment and PassKit capabilities as available.
Linux deliberately reports them unavailable because no equivalent trusted
system service exists. This is a documented fail-closed divergence, not an
emulation result.

## Pinned evidence

`framework_surface_census.py` scans the exact 20-app corpus pinned by
`full/ladder/corpus-pins-2026-08-27.tsv`. The canonical census digest is
`da94bef4f3730314b5f52a6db29ce587c47a364ed41fe4a3aa32b87fa3627821`;
its ordered importing-file inventory digest is
`04901af26af0ace9b065b095c9e180c6637e2d73d7e61d68260d9a5b08b22b78`.

| Framework | Importing files | Apps | Focus files |
|---|---:|---:|---:|
| LocalAuthentication | 46 | 11 | 2 |
| SafariServices | 132 | 17 | 2 |
| Network | 31 | 10 | 1 |
| StoreKit | 48 | 14 | 1 |
| AudioToolbox | 29 | 7 | 1 |
| CoreHaptics | 6 | 4 | 1 |
| PassKit | 58 | 8 | 1 |

`first-party-provenance.json` pins the source manifests, source hashes, corpus
tool/pins, eight distinct untouched Focus files, native oracle, and host test
inputs. `first_party_provenance.py` rejects source deletion, mutation, added
Swift files, manifest reordering, symlinks, policy reordering, and stale output.
The core builder brackets its build with two identical provenance attestations.

The native oracle is pinned to Xcode 26.1 build 17B55 and iOS Simulator SDK
26.1 build 23B77. It records portable raw values/defaults and compiles the
native callback signatures. The host package builds seven dynamic products,
checks their install IDs, rejects Apple-framework self-loads, and runs the full
fail-closed behavior probe. SwiftPM's automatic product linking statically
embeds OpenUIKit in each host-only UI framework product, so macOS may print
duplicate Objective-C class warnings when all three are loaded together. The
authoritative guest package instead links each framework to the one shared
`libUIKit.dylib`/`libOpenUIKit.dylib` boundary and audits that load graph.

The exact untouched-Focus control/candidate comparison uses target
`arm64-apple-macos15.0`, Focus `a2832521c1daa0c23419c73705ae043ed60c9791`,
SnapKit `e74fe2a978d1216c3602b129447c7301573cc2d8`, and UIKit
`62dea0d97a3b9074e5c016820492bd0656b9a35a`. Shadowing only the seven SDK
modules with these production sources changes 234 primary diagnostics to 232:
two removed, zero added, and zero diagnostics while emitting the seven
modules. `tests/focus-first-party-exact-delta.tsv` preserves both removed
diagnostics with multiplicity. The raw log hashes are
`29a4685656973019fe29573aded0657f5f6551fc513c646015043a8b9fa22413`
(control) and
`55a467424712488f261df4bc958fda17deda5b11dd351034960a683e8d287978`
(candidate); normalized hashes are
`55b6526155491262d29de175694502f9b7721260735f0adaa411a8322059204a`
and `d6236001336113d5f55ee839f9d354a70232f6932c4e4fa522faafcb9f685eb9`.
The delta artifact hash is
`3a2f4708bd58e81c2dde28f4a54a028b160b1db4f3f45e383d8ab4da64d2b677`.

## RevenueCat frontier extension

The production package also carries `AdServices` as its thirty-second
first-party Swift module and `libAdServices.dylib` as one of fifty framework
dylibs. This is intentionally separate from the original seven-framework,
20-app provenance census above: it was derived from the exact untouched
RevenueCat `purchases-ios` commit
`57043e7e0173c48d64e171944ac76a34d2467fa1`. Linux has no trusted Apple Ads
attribution service, so `AAAttribution.attributionToken()` fails closed with
the Apple-observed `platformNotSupported` code instead of inventing a token.

The same frontier adds an app-facing `zlib` Clang module and `libz.dylib`.
Its public `z_stream` layout and four RevenueCat-used entry points match the
Apple SDK surface; calls cross a versioned four-function guest/host ABI to the
pinned AArch64 Linux zlib runtime. The package builder validates the 112-byte
stream ABI, exact Mach-O imports/exports, Apple gzip transcript, valid payload,
and malformed-input behavior. After a package succeeds,
`full/adservices/tests/test_revenuecat_frontier_guest.sh` compiles and runs the
five hash-pinned RevenueCat source files without modifying the vendor checkout.

## Gates

From a clean support checkout:

```sh
python3 -B full/first-party-frameworks/first_party_provenance.py production \
  --support-root . \
  --policy full/first-party-frameworks/first-party-provenance.json \
  --output /tmp/first-party-sources.tsv
python3 -B -m unittest -v \
  full/first-party-frameworks/tests/test_first_party_provenance.py \
  full/first-party-frameworks/tests/test_focus_first_party_delta.py
full/first-party-frameworks/tests/test_first_party_host.sh /path/to/pinned/uikit
full/first-party-frameworks/tests/test_first_party_native_26_1.sh
```

The host and native scripts always use fresh temporary build roots and remove
them on exit. The Docker ARM64 guest-package replay remains a separate serialized
gate; a host/static pass is not represented as a Linux runtime pass.
