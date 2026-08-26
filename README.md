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
