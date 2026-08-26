# swift-macho-linux

A decisive spike: **can a Linux-hosted Swift toolchain build a Mach-O dylib for
`arm64-apple-macos`**, so Swift — eventually OpenUIKit — can join the
[machorun](../machorun) stack?

Yes. Trivial Swift, `@objc` classes with `#selector`, generics, collections,
closures and `async` all compile and link to arm64 Mach-O on Linux with
`swift:6.2-noble` + `ld64.lld-18`, and produce byte-identical output to an
Apple-built oracle. The trivial case also runs under machorun. Anything that
touches the Swift runtime stops at one missing artifact: `libswiftCore.dylib`
does not exist as a file on either operating system.

**Read [`docs/SPIKE.md`](docs/SPIKE.md)** — the ladder, what is staged, the two
loud failures found on the way, and the recommendation.

Everything under `scratch/` and `build/` is generated and gitignored;
`scripts/stage_darwin_swift.sh` and `scripts/stage_objc_module.sh` rebuild the
one Apple dependency (15 MB, almost all of it textual `.swiftinterface`).
This repository reads `~/machorun` and never writes into it.
