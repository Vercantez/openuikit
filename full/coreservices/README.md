# CoreServices (Swift source-compatibility overlay)

This directory is a **legacy-adapter** Swift overlay for the iPhoneOS 26.1
`CoreServices` UTI surface. **CoreServices owns the iPhone UTI C API.**
`MobileCoreServices` is the adapter/reexport, not the owner. This starting
point is Swift source compatibility, not a C dylib ABI.

The pinned public surface is 150 exact identifiers: 139 `kUTType*` / `kUTTag*`
/ declaration-key constants and 11 `UTType*` functions. `_UTType*` / `_kUT*`
C ABI exports from the `.tbd` are **not emitted and not verified** here;
central integration must add a real C-shim/export strategy before platform
merge.

Canonical CF identities are staged Foundation/CoreFoundation:

- `CFString == String`
- `CFURL == URL`
- `CFDictionary == [CFString: Any]` (`[String: Any]`)

This overlay binds signatures to those identities. It does **not** publish
module-local `CFString` / `CFArray` / `CFDictionary` / `CFURL` aliases.
`CFArray` has no Foundation identity; list results use `[String]`. Copy/Create
APIs return optional Swift values, not `Unmanaged` CF retains.

The immutable host gate compiles these same sources against system Foundation.
That is not a second CF universe and is not an integration-compatible fallback
dylib.

## What is implemented (runtime-exercised)

`tests/agent/CoreServicesRuntime.swift` exercises all 11 functions and 24
constants. Those rows are `implemented`. The other 115 constants compile as
`declared` overlay names without expected-value assertions.

Exercised behavior: identifier equality, parent-graph conformance, declared vs
`dyn.` tests, filename-extension and MIME tag lookup, preferred-identifier
selection (`.plist` → `com.apple.property-list`), and declaration dictionaries.

## Fail-closed / partial

- `UTTypeCopyDeclaringBundleURL` → `nil` (no Launch Services bundle database).
- `UTTypeCopyDescription` → `nil` (no Apple localizer strings).
- Unknown tags → `nil` from Create* (fail-closed **partial**; Apple synthesizes
  `dyn.*`. The exact encoding remains an oracle question).
- Tag classes other than `public.filename-extension` and `public.mime-type`.

## Do not silently merge

Central integration must choose **one CF universe** and **one canonical UTI
registry**, make `MobileCoreServices` the adapter, and add C exports before
merge. This overlay documents, and does not collapse, these splits:

1. **15 duplicate `MobileCoreServices` constants** (same public names and
   documented UTI strings): `kUTTypeItem`, `kUTTypeContent`, `kUTTypeData`,
   `kUTTypeText`, `kUTTypePlainText`, `kUTTypeUTF8PlainText`, `kUTTypeURL`,
   `kUTTypeFileURL`, `kUTTypeImage`, `kUTTypeJPEG`, `kUTTypePNG`, `kUTTypeGIF`,
   `kUTTypePDF`, `kUTTypeMovie`, `kUTTypeAudio`.
2. **Duplicate UTI registry** versus `UniformTypeIdentifiers._registry`. This
   module keeps a local catalog so the isolated host gate can compile without
   importing that module.
3. **Five divergent shared records** (same identifier, different parents/tags):
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
bash full/coreservices/tests/acceptance/test_host.sh
bash full/coreservices/tests/agent/run_canonical_identity.sh
```
