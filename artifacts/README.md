# Artifacts

Built 2026-08-26 on Ubuntu 24.04 aarch64 with the stock swift.org
`swift-6.2.4-RELEASE` Linux toolchain. **No Xcode, no Apple toolchain, no
macOS.** Reproduce with the sequence in `../docs/BUILD_LOG.md` §7.

| file | what |
|---|---|
| `swift-macosx/arm64/libswiftCore.dylib` | the Swift standard library, Mach-O 64-bit **arm64**, install name `/usr/lib/swift/libswiftCore.dylib`, 30,723 exported symbols |
| `swift-macosx/Swift.swiftmodule/arm64-apple-macos.*` | the matching module / interface, so `swiftc -target arm64-apple-macos` can compile against it |
| `libswiftcompat.dylib` | the 29-symbol gap between libswiftCore's imports and machorun's self-hosted Darwin userland (see `../sdk/compat/swiftcompat.c`) |

`libswiftCore.dylib` is linked with `-undefined dynamic_lookup`, because 30 of
its 186 imports are not in the sysroot's `.tbd` files; `libswiftcompat.dylib`
supplies 29 of those 30 and the last (`dyld_stub_binder`) is the loader's own.

To use: put `libswiftCore.dylib` at `darwin/usr/lib/swift/` and
`libswiftcompat.dylib` at `darwin/usr/lib/` under a machorun tree, then link
guests with **`-lswiftCore` before `-lSystem`** — the order matters, and
`../scripts/run_under_machorun.sh` explains why.
