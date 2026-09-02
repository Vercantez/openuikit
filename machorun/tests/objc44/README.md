# tests/objc44 — Apple's objc4 differential corpus, run under machorun

44 Objective-C programs, their recorded macOS behaviour, and the binaries that
produced it. Run them with `scripts/objc44.sh`.

## Where this came from

The sources and the baselines are **`~/objc4-linux`'s**, not ours. That project
ported Apple's objc4 to Linux/ELF and built this corpus to hold it honest: each
test is one source file, compiled and run against Apple's shipping runtime on
macOS to record `<name>.txt`, then compiled and run against the port, with the
two outputs required to be byte-identical.

This directory reuses the corpus to ask a different question — not "does our
ELF port behave like Apple's runtime", but **"does Apple's runtime, compiled as
Mach-O and loaded by machorun, behave like Apple's runtime"**.

* `<name>.txt` — copied verbatim from `~/objc4-linux/tests/expected/`.
  Recorded on **macOS 26.1/arm64 against Apple's shipping libobjc**.
* `<name>` — the Mach-O executable, compiled **on macOS by Apple's clang**
  with `~/objc4-linux/harness/run_macos.sh`'s exact flags.
* `lib041-multi-image.dylib` — 041's companion image (cross-image classes,
  categories and `+load` ordering).
* `lib042-dlopen-dlopen.dylib` — 042's companion, loaded at run time.

## The rule

**Never regenerate a `.txt` from the Linux side.** A mismatch is a failure to
report. The baselines are the only thing in this directory that is not
reproducible from source, and they are the only thing that makes the rest mean
anything.

## The check that makes a Linux mismatch meaningful

Before any of these binaries was run under machorun, all 44 were run
**natively on macOS** and required to reproduce their committed baseline:

```
macOS self-check: 44/44 reproduce the committed baseline (fail=0 missing=0)
```

That is what rules out "my compile differs from the one that recorded the
baseline" as an explanation for a Linux-side difference. Re-run it after any
rebuild — otherwise a FAIL here is ambiguous.

## Rebuilding the binaries (on macOS)

```sh
SDK=$(xcrun --sdk macosx --show-sdk-path)
REPO=~/objc4-linux
CFLAGS="-isysroot $SDK -target arm64-apple-macos13 -O0 -g0
        -fsigned-char -fno-objc-arc -fobjc-exceptions
        -Wno-objc-root-class -Wno-unused-function -Wno-deprecated-declarations
        -I$REPO/tests"
clang $CFLAGS $REPO/tests/001-root-class.m -o 001-root-class -lobjc
```

`-O0` and `-fsigned-char` are pinned deliberately; `~/objc4-linux/harness/
run_macos.sh` explains why (optimisation changes ARC codegen, and plain `char`
has a different signedness in the two ABIs, which would change every
`@encode`). Rebuilt binaries are not byte-reproducible — fresh `LC_UUID` and a
fresh ad-hoc signature — so if you rebuild, re-run the macOS self-check and
commit the binaries in one commit with a note saying why.
