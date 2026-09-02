# Portable `Bundle` for Foundation-hidden guests

OpenUIKit's Linux-hosted Mach-O build compiles the framework before a complete
`Foundation` umbrella is available. When `FoundationEssentials` is visible,
the fallback `Bundle` now carries the exact filesystem and image-discovery
surface required by unchanged Mozilla Focus package targets:

- nonoptional `main`, `bundleURL`, and `bundlePath`;
- optional `resourceURL` and `resourcePath`, matching Foundation's API shape;
- failable directory-only `init(path:)` and file-URL-only `init(url:)`;
- `init(for:)`, using a Swift class descriptor's image base to match the dyld
  image table, so a resolved embedded framework wins over an `@rpath` install
  name and the outer application;
- exact named `url(forResource:withExtension:)` lookup.

The named-resource method is intentionally not a general `NSBundle` clone. It
accepts a nonempty exact name, optional extension, leading-dot extension, and
slash-delimited nested name. Nil and empty extensions are equivalent; adding
an extension to a name that already has one appends another suffix, matching
the native result. The lexically standardized candidate must remain beneath
the selected resource root and must exist. The filesystem root is treated as
the single `/` descendant prefix rather than the `//` spelling used for no
valid absolute path. Every candidate component below the selected root is
also checked with `FileManager.destinationOfSymbolicLink`; any symlink is
rejected, including a link whose destination remains inside the root. Only
the underlying POSIX `EINVAL` result expected for an ordinary node is
accepted. Missing, inaccessible, or otherwise uninspectable components fail
closed. This avoids filesystem-resolving URL APIs whose target15
implementation currently reaches an unavailable `getattrlist` syscall.

Nil or empty names fail closed instead of invoking Foundation's implicit
resource enumeration. Localization, subdirectory overloads, and plural
resource enumeration are not declared. Those behaviors include search-order
policy and should be added only for a measured application requirement.

`scripts/prove_portable_bundle.sh` builds the same contract probe against
native Apple Foundation and against all 12 OpenCoreGraphics plus all 100
OpenUIKit sources for `arm64-apple-macos15.0`. Both probes exercise the
filesystem root, flat, `Contents/Resources`, static framework,
main-application, and dynamically linked embedded-framework bundles. The
guest additionally proves fail-closed unnamed lookup, root-boundary behavior,
and leaf/intermediate/in-root symlink rejection before running through
machorun.

The proof requires the sibling `swift-macho-linux` target15 sysroot, complete
FoundationEssentials objects, runtime root, and runtime patch objects produced
by its full build. It never compiles a generated overlay into app or vendor
targets.
