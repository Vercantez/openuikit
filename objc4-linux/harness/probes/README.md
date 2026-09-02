# Section-discovery probes

The measurements behind `docs/PORT_MAP.md` §3 and §5. Each is meant to be
re-run, not trusted.

| file | question it answers |
|---|---|
| `probe.m` | What ELF sections does clang emit for Apple-ABI Objective-C? Root class, category, subclass with property, protocol, class ref, selrefs, two `+load`s. Compiled for both `aarch64-unknown-linux-gnu` and `arm64-apple-macos13` from the same source, so the section names can be diffed. |
| `probe2.m` | A second translation unit, to confirm same-named sections concatenate across objects at link time. |
| `stubs.c` | Empty definitions for the runtime symbols clang's Apple-runtime codegen references (`objc_msgSend`, `objc_alloc`, `_objc_empty_cache`), so the probes link without a runtime. |
| `startstop.c` | Do linker-generated `__start_objc_classlist` / `__stop_objc_classlist` encapsulation symbols exist and bound the right array? (Measured: yes, n=3.) |
| `elfscan.c` | Can the runtime recover an arbitrary loaded image's section addresses via `dl_iterate_phdr` + reading `Elf64_Shdr` from the on-disk file + `dlpi_addr`? (Measured: yes.) |
| `sw2.swift` | Does stock Linux `swiftc -Xfrontend -enable-objc-interop` emit `objc_classlist`? (Measured: **no** — it refuses, because stock Foundation's `NSObject` is a Swift class. See PORT_MAP §3.2 "Honest gap".) |

## Re-running

Linux side, in the repo root:

```sh
docker run --rm -v "$PWD":/src -w /src swift:6.2-noble bash -c '
  cd harness/probes
  clang -c -fobjc-runtime=macosx-10.15 -fno-objc-arc -Wno-objc-root-class probe.m -o p1.o
  clang -c -fobjc-runtime=macosx-10.15 -fno-objc-arc -Wno-objc-root-class probe2.m -o p2.o
  readelf -SW p1.o | grep objc_
  clang -shared -fPIC p1.o p2.o stubs.c -o libprobe.so
  clang startstop.c p1.o p2.o stubs.c -o exe && ./exe
  clang elfscan.c -o elfscan -L. -lprobe -Wl,-rpath,"$PWD" && ./elfscan
'
```

macOS oracle side:

```sh
clang -c -target arm64-apple-macos13 -fno-objc-arc -Wno-objc-root-class \
    harness/probes/probe.m -o /tmp/probe_macho.o
otool -l /tmp/probe_macho.o | grep -A1 sectname
```
