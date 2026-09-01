# CoreServices (Linux starting point)

This directory is a **legacy-adapter** starting point for Apple's public
`CoreServices` Swift overlay, seeded from the iPhoneOS 26.1 SDK. On Apple
platforms `CoreServices` is an umbrella that re-exports the Uniform Type
Identifier C API also published as `MobileCoreServices`. The pinned public
surface here is that overlay: 139 `kUTType*` / `kUTTag*` / declaration-key
constants and 11 `UTType*` functions.

The modern Swift `UniformTypeIdentifiers` module is a declared dependency for
later integration. This isolated guest compile does not import it; the portable
registry is a local copy of the documented public UTI catalog so the C API can
stand alone.

## What is implemented

- Documented public UTI identifier strings (`public.png`, `public.jpeg`,
  `com.adobe.pdf`, and the rest of the overlay constants).
- Declaration keys (`UTTypeIdentifier`, `UTTypeConformsTo`, tag-class names).
- Case-insensitive identifier equality (`UTTypeEqual`).
- Parent-graph conformance (`UTTypeConformsTo`), including self-conformance
  for unknown identifiers.
- Declared/dynamic tests (`UTTypeIsDeclared`, `UTTypeIsDynamic` via the
  documented `dyn.` prefix).
- Filename-extension and MIME-type tag lookup, including preferred-identifier
  selection that prefers the most general matching declared type (so `.plist`
  maps to `com.apple.property-list`).
- Declaration dictionaries with identifier, conforms-to, and tag specification.
- Copy/Create results use `Unmanaged.passRetained` so callers follow the CF
  +1 retain rule.

Linux Foundation does not provide CoreFoundation `CFString` / `CFArray` /
`CFDictionary` / `CFURL` class types. This module aliases those names to
`NSString` / `NSArray` / `NSDictionary` / `NSURL` so the overlay signatures
compile. That is a Linux spelling bridge, not Apple's CF runtime.

## Fail-closed boundaries

These paths return `nil` / false and must not be treated as Apple parity:

- `UTTypeCopyDeclaringBundleURL` — no Launch Services bundle database.
- `UTTypeCopyDescription` — no Apple localizer or bundle strings.
- Unknown filename extensions and MIME types — no synthesized Apple `dyn.*`
  encoding.
- Tag classes other than `public.filename-extension` and `public.mime-type`
  (no OSType / pasteboard class on this iOS overlay surface).
- Unknown identifiers have no invented pedigree beyond self-equality.

## Not in this Swift overlay

The `.tbd` also exports Launch Services, FSEvents, and CSIdentity C symbols.
Those identifiers are not in `reference/public-surface.tsv` and are not
implemented here. Central review still owns C ABI layout, retain/release
edge cases, and any later re-export relationship with `MobileCoreServices`.

## Gate

```sh
bash full/coreservices/tests/acceptance/test_host.sh
```
