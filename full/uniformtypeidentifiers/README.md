# UniformTypeIdentifiers (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`UniformTypeIdentifiers` module, seeded from the Xcode 26.1 iPhoneOS 26.1
symbol graph, API digester, and TBD exports. It is not wired into the shared
guest package; that integration is a later central-review step.

The existing portable `UTType` registry from the earlier lane is kept. This
wave-5 pass adds the ObjC `UTTypeReference` class, Foundation path overlays,
schema-v2 coverage accounting, and the sealed host-gate probes.

## What is real

- `UTType` is a value-semantic identifier with a built-in registry of common
  system types (filename extensions, MIME types, and parent identifiers).
- Lookup by identifier, filename extension, MIME type, or `UTTagClass` tag is
  case-insensitive for tags and fails closed for unknown identifiers: the host
  OS is not pretended to have registered them.
- `init(exportedAs:conformingTo:)` / `init(importedAs:conformingTo:)` construct
  a value with an optional declared parent. They do not contact Launch Services.
- Conformance walks the registry parents plus any declared parent. `supertypes`,
  `isSubtype(of:)`, and `isSupertype(of:)` follow that graph.
- `UTTagClass.filenameExtension` is `public.filename-extension`;
  `UTTagClass.mimeType` is `public.mime-type`.
- `UTTypeReference` wraps the same `UTType` value so ObjC-named APIs compile.
  Class `tags` uses `[String: [String]]` with tag-class raw values as keys.
  `version` is `NSNumber?`.
- `URL` / `NSString` / `NSURL` append a preferred filename extension when the
  type has one, and leave the path unchanged when it does not.
- `UTType` JSON-codes as a single identifier string.

`tests/agent/UniformTypeIdentifiersRuntime.swift` is a standalone probe that
prints `UNIFORMTYPEIDENTIFIERS_AGENT_RUNTIME_OK`. The sealed schema-v2 gate
derives its runner from `implemented` coverage and `*Tests.swift`.

## Fail-closed boundaries

Linux has no Launch Services database, localized type names, or Apple
`NSItemProvider` type.

- `UTType(_:)` returns `nil` for identifiers absent from the built-in registry.
  Dynamic `dyn.*` identifiers are not synthesized.
- `localizedDescription`, `referenceURL`, and `version` are `nil`.
- `UTTypeReference.init(coder:)` returns `nil`; Apple's keyed archive layout
  is unobserved, so no payload is invented.
- `URLResourceValues.contentType` is always `nil`. Linux Foundation does not
  populate a UTI resource key, and this overlay cannot add stored properties.
- `exportedAs` and `importedAs` are value constructors only. They do not
  register types with a system database; any Apple difference between the two
  is unobserved.

## Deferred

These signatures require `NSItemProvider` /
`NSItemProviderRepresentationVisibility`, which the isolated Linux Foundation
module does not provide. A public framework-local substitute is forbidden:

- `NSItemProvider.registeredContentTypes`
- `NSItemProvider.registeredContentTypesForOpenInPlace`
- `NSItemProvider.registeredContentTypes(conformingTo:)`
- `NSItemProvider.init(contentsOf:contentType:openInPlace:coordinated:visibility:)`
- `loadDataRepresentation` / `loadFileRepresentation`
- `registerDataRepresentation` / `registerFileRepresentation`

`tests/agent/UniformTypeIdentifiersDependencyIdentity.swift` imports
`UniformTypeIdentifiers` and `Foundation` and passes real `URL`, `NSString`,
`NSURL`, and `JSONEncoder` values through public APIs. It is for a later clean
EC2 integration build; the isolated host gate does not compile it.
