# CoreServices (Swift overlay, not C ABI, not full source compatibility)

This directory is a **legacy-adapter** Swift overlay for the iPhoneOS 26.1
`CoreServices` UTI surface. **CoreServices owns the iPhone UTI C API.**
`MobileCoreServices` is the adapter/reexport, not the owner.

The pinned public surface is 150 exact identifiers: 139 `kUTType*` / `kUTTag*`
/ declaration-key constants and 11 `UTType*` functions. `_UTType*` / `_kUT*`
C ABI exports from the `.tbd` are **not emitted and not verified**. Absence of
those symbols is not an implementation of the C ABI. Central integration must
add a real C-shim/export strategy before platform merge.

## Source-surface status

Staged Foundation/CoreFoundation currently aliases `CFString` to `String` and
has no ownership-capable `CFArray`. The immutable Copy/Create declarations
return `Unmanaged<CFString|CFArray|CFDictionary|CFURL>?`. Those seven APIs
**cannot be published** without a module-local CF lookalike, which this overlay
refuses to invent. They are **deferred** on that central dependency blocker.

This overlay does **not** claim full Swift source compatibility. Callers that
invoke `takeRetainedValue()` on Copy/Create results will not compile until a
class-typed CF universe exists.

Representable public queries (`UTTypeEqual`, `UTTypeConformsTo`,
`UTTypeIsDeclared`, `UTTypeIsDynamic`) and constants use `String`, which is
the staged `CFString` identity. Portable Copy/Create registry behavior is
`@_spi(OpenUIKitHost)` only (`OpenUIKitHostUTType`) and is not the pinned
overlay.

There are no CoreServices-local CF aliases and no test-owned CoreFoundation
module.

## Coverage

- 4 Bool functions + 24 runtime-asserted constants: `implemented`
- 115 compile-only constants: `declared`
- 7 Unmanaged Copy/Create functions: `deferred`
- Nondeferred total 143 (floor 120)

## Fail-closed / partial (host SPI)

- `copyDeclaringBundleURL` → `nil` (no Launch Services bundle database).
- `copyDescription` → `nil` (no Apple localizer strings).
- Unknown tags → `nil` from Create* (fail-closed **partial**; Apple synthesizes
  `dyn.*`. The exact encoding remains an oracle question).

## Do not silently merge

Central integration must choose **one CF universe** and **one canonical UTI
registry**, make `MobileCoreServices` the adapter, and add C exports before
merge. This overlay documents, and does not collapse, these splits:

1. **15 duplicate `MobileCoreServices` constants** (same public names and
   documented UTI strings): `kUTTypeItem`, `kUTTypeContent`, `kUTTypeData`,
   `kUTTypeText`, `kUTTypePlainText`, `kUTTypeUTF8PlainText`, `kUTTypeURL`,
   `kUTTypeFileURL`, `kUTTypeImage`, `kUTTypeJPEG`, `kUTTypePNG`, `kUTTypeGIF`,
   `kUTTypePDF`, `kUTTypeMovie`, `kUTTypeAudio`.
2. **Duplicate UTI registry** versus `UniformTypeIdentifiers._registry`.
3. **Five divergent shared records**:
   - `com.apple.internet-location`: UT parents include `public.stored-url`; this
     overlay has `public.data` only.
   - `com.rsa.pkcs-12`: this overlay also lists `pfx`.
   - `org.gnu.gnu-zip-archive`: MIME `application/gzip` here vs
     `application/x-gzip` in UT.
   - `public.c-plus-plus-header`: this overlay also lists `hpp`.
   - `public.mpeg-4-audio`: UT lists `mp4` and `m4a`; this overlay lists `m4a`
     only so `.mp4` prefers `public.mpeg-4`.

## Gate

```sh
bash tests/acceptance/test_host.sh
bash tests/agent/run_canonical_identity.sh
```
