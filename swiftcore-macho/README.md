# swiftcore-macho

**Build the Swift standard library (libswiftCore.dylib and friends) as Darwin
Mach-O, ON LINUX, from swift.org source — no Xcode, no Apple toolchain.**

Tier 3 of the Swift-on-machorun plan (see ~/swift-macho-linux/docs/SPIKE.md):
- Tier 1: stage Apple's libswiftCore from Xcode (de-risks: does machorun's
  loader host the Swift runtime). Running separately.
- Tier 2: build 6.2.4 from source ON macOS targeting Darwin (supported; kills
  the 6.2.1-vs-6.2.4 version skew).
- **Tier 3 (here): build it on a LINUX host, cross-targeting
  arm64-apple-macos, machorun-style.** Fully self-hosted. Hardest, because
  cross-building the *Darwin* stdlib on a *Linux* host is a configuration Apple
  neither supports nor tests.

## What we already know
- The stock Linux swiftc 6.2.4 emits Mach-O for arm64-apple-macos and its
  backend/frontend understand the Darwin triple (measured).
- The Swift stdlib configures STANDALONE against a stock toolchain — no full
  compiler bootstrap — per the objc4-linux investigation (SWIFT_INCLUDE_TOOLS=OFF,
  native tools path pointing at the installed toolchain).
- machorun ships a self-hosted header-only + .tbd SDK, Apple's objc4 as Mach-O,
  and libSystem — the target-side pieces the stdlib build needs, EXCEPT possibly
  Darwin Foundation/CoreFoundation headers, which is the expected wall.

## Method
Scope first, then build. Find the FIRST wall precisely (Foundation headers? gyb?
a build-script host assumption?) before grinding. Differential against a
macOS-built stdlib where it helps. Honest walls are good results.

## Status
Bootstrapping on a Graviton build box. See docs/PLAN.md.

---

## Result (2026-08-26)

**Done.** `libswiftCore.dylib` — Mach-O 64-bit **arm64**, 9.9 MB, 30,723
exported symbols — built on a Linux host from swift.org 6.2.4 source, with no
Xcode and no Apple toolchain. A Swift program linked against it runs to
completion under machorun:

```
$ scripts/run_under_machorun.sh /tmp/hello.swift
hello from Swift on machorun
sorted: [1, 2, 3]
$ echo $?
0
```

Cost: **4 patches** to the Swift source (33 inserted lines, 1 deleted; a 5th is
opt-in), 4 clean-room headers, and a 29-symbol compatibility dylib.

`docs/BUILD_LOG.md` is the full account — every wall in the order it appeared,
what category it was, and what closed it. The headline is §1: libswiftCore
links no Foundation and no CoreFoundation, so the wall that killed the
Linux-target experiment in `~/uikit/docs/OBJC_RUNTIME.md` does not apply to the
Darwin target at all.

## Result (2026-09-03) — x86_64 slice beside arm64

Same recipe, `SWIFTCORE_DARWIN_ARCH=x86_64`, on an x86_64 Linux host.
`artifacts/swift-macosx/x86_64/libswiftCore.dylib` is Mach-O 64-bit **x86_64**,
10 123 624 bytes, install name `/usr/lib/swift/libswiftCore.dylib`, sha256
`8de09dbae55b672287985812c64fe859029197aaf70458aa3097bbbdce4c39fb`. The arm64
dylib is untouched (`dd01686e…12708cb`). Compile+link of a hello-world against
`x86_64-apple-macos15.0` succeeds in-VM; execution is refused here
(`CURSOR_ENV_CANNOT_EXECUTE_X86_SWIFT_GUEST`). `_Concurrency` is still the
§16 libdispatch wall. Recipe: `docs/X86_64.md` / `scripts/build_stdlib.sh`.

Known-open, both on the loader side rather than ours:
* machorun's TLS cannot register pthread-key destructors, so anything reaching
  `SwiftTLSContext` (classes, generics) aborts before `main`.
* machorun's `libSystem` exports a `swift_release` diagnostic stub that shadows
  the real one unless `-lswiftCore` precedes `-lSystem` at link time.
