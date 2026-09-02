# ~/quartz, built as Mach-O on Linux — and a precompiled Darwin binary that draws

**Result: 0 patches. 37 translation units, 0 failures. A plain C Mach-O built by
Apple's clang on macOS produces a byte-identical 26,861-byte PNG when run
natively on macOS and under machorun on Linux/arm64.**

```
macOS, natively:       26861 bytes   sha256 96aa747a85f6c35f...
machorun on Linux:     26861 bytes   sha256 96aa747a85f6c35f...
stage checksums (9):   identical
exit status:           0 / 0
```

`scripts/quartz_pixel.sh` is the run. `tests/bin/quartz` is the binary.

---

## 1. The patch ledger

There is no ledger. `patches-quartz/` is empty.

```
$ scripts/build_quartz.sh
== patches applied: 0
== compiling (target arm64-apple-macos11, sysroot /work/sdk)
   warn qz_image.cpp
== compiled 37 objects, 0 failures
== linking darwin/usr/lib/libquartz.dylib
   -> darwin/usr/lib/libquartz.dylib
Mach-O 64-bit arm64 dynamically linked shared library
```

The single warning is `-Wmissing-field-initializers` and a deprecation notice
for `sprintf`, both from `third_party/stb_image_write.h`, both present in
upstream's own macOS build.

Set against `docs/OBJC4_MACHO.md`'s **4**, the interesting thing is not that
zero is smaller. It is *why* the two numbers differ, and it is not the file
format. objc4's four patches all say **"this is not a Mac"** — no dyld shared
cache, no `task_restartable_ranges`, a 48-bit Linux address space that Apple's
`shiftcls` bitfield was not sized for. Every one is about the *kernel and the
address space*, not about Mach-O.

quartz needs none of them because it never asks. It has no `TARGET_OS_*`
conditional, no Mach call, no assumption about the VM ceiling, no packed
pointers, and no dependency on a runtime that has any of those. It is C++17 over
`<stdint.h>`, `<cmath>`, `<vector>`, `<string>` and `<unordered_map>`, and the
only thing it wants from the platform is malloc, memcpy, a handful of
transcendentals and `fopen`/`fwrite`.

**That is the finding, and it is worth stating as a prediction rather than a
congratulation:** the cost of hosting a library under machorun is not
proportional to its size — quartz is ~10k lines of library against the ~45k in
`vendor/objc4/runtime/` — but to how much of Darwin it names. A large portable
library is cheaper to host than a small platform-coupled one.

### What replaced the patches: nothing in quartz, four things around it

Zero patches did **not** mean zero work. Everything that had to change was on
our side of the boundary, which is exactly where the project wants it:

| what | where | why |
|---|---|---|
| `sdk/usr/include/_assert.h` | `sdk/MANIFEST.tsv` +1 row | §2 |
| 113 libm symbols | `darwin/src/math.c` | §3 |
| 12 libc++ out-of-line symbols | `darwin/src/libcxx_std.cpp` | §4 |
| `--no-as-needed -lm` on the loader | `scripts/build.sh` | §3 |

Plus three smaller gaps the fixture found: `ungetc`, `rewind`, `getc`,
`memset_pattern4/8/16`, and `__assert_rtn`.

---

## 2. The SDK hole a single-consumer closure could not see

`sdk/usr/include/` is a *measured dependency closure* — 356 headers, and
`docs/SDK_SURVEY.md` §1 is the measurement. Until quartz, the thing being
measured was `vendor/objc4` and the ABI probe.

objc4 compiles `-DNDEBUG`. Apple's real `assert.h` reads:

```c
#ifdef NDEBUG
#define	assert(e)	((void)0)
#else
#include <_assert.h>
```

So the second branch had never been taken, `_assert.h` had never been staged,
and `assert.h`'s own `#include` had been dangling since the SDK was assembled.
Nothing failed. quartz's `third_party/stb_*.h` include `<assert.h>`
unconditionally and three TUs stopped compiling.

**A staged header set is only closed over the preprocessor branches its
consumers actually take.** A second consumer with different `-D` flags is the
cheapest available way to find the next hole, which is an argument for hosting
more than one library here rather than a cost of doing so. `sdk/PROVENANCE.md`
records it in place.

The header alone would only have moved the failure one step: the non-`NDEBUG`
branch calls `__assert_rtn`, which `libSystem.B.dylib` did not export either. It
does now, reproducing Libc's exact message text — a guest's stderr is compared
byte-for-byte, so `Assertion failed: (e), function f, file x.c, line 12.` is an
ABI string and not a nicety.

---

## 3. libm: the one place this could legitimately have differed

**On Darwin there is no `-lm`.** `libSystem.B.dylib` re-exports
`libsystem_m.dylib`, so a guest that calls `cos()` carries an undefined `_cos`
against libSystem and nothing else. Ours had no math in it at all — 320 exports,
not one of them a math function — because nothing before quartz had needed any.

`darwin/src/math.c` is 113 symbols forwarded to glibc. quartz reaches 13 of
them: `acos acosf atan2 cos cosf exp fmod fmodf frexpf pow powf tan` and
`__sincos_stret`.

### `__sincos_stret` is an ABI, not a function

clang emits a call to `___sincos_stret` instead of separate `sin` and `cos`
whenever it sees both of a value on an Apple target, and quartz's
`QZAffineTransformRotate` does exactly that (`qz_math.cpp:17`:
`double c = std::cos(angle), s = std::sin(angle);`). The return type is a
two-element homogeneous float aggregate, so AAPCS64 returns it in `d0`/`d1`
rather than through `x8`, and **the field order is the ABI**: `__sinval` first,
`__cosval` second. Swap them and every rotation in every guest is silently
transposed — a failure a pixel diff catches and a unit test of libSystem
does not.

### The honest limit

Forwarding to glibc is **not** a claim that glibc's libm and Apple's Libm agree
bit-for-bit, and that claim would be false in general. IEEE 754 pins `+ - * /`
and `sqrt` exactly and says **nothing** about `sin`, `cos`, `tan`, `pow`, `exp`
or `log`; every implementation is free to be off by its own fraction of an ulp.

So the fixture is built to expose it rather than hope. Stage 8 of
`tests/src/quartz.c` is a rotation and nothing else, it is the only stage
that reaches a transcendental (ellipses in stages 7 and 9 are four cubic Beziers
with a constant κ — pure arithmetic, `qz_path.cpp:110`), and its checksum is
printed separately.

**Measured: identical.** All nine stage checksums match and the PNG is
byte-identical. That is *one workload agreeing*, not a proof of agreement, and
`docs/UNIMPLEMENTED.md#libm-ulp` says so. Nothing in `math.c` rounds or clamps a
result to help.

### The loader had to be told to load libm

This one is worth remembering because the symptom names the wrong layer.
`src/resolve.c` binds every `_glibc_<name>` with `dlsym(RTLD_DEFAULT, name)`,
and `RTLD_DEFAULT` searches the **global scope** — libraries actually loaded
into the process. The loader's own C code calls nothing in libm, so Ubuntu's
default `--as-needed` dropped `libm.so.6` from `DT_NEEDED`, and the first guest
to call `sin()` died with:

```
machorun: undefined symbol '_glibc_sin'
  wanted by:  darwin/usr/lib/libSystem.B.dylib
  looked in:  every loaded image (flat lookup)
```

`-Wl,--no-as-needed -lm` in `scripts/build.sh`. The lesson generalises to every
future forwarder: **libSystem's reach is bounded by the loader's own
`DT_NEEDED`**, not by what glibc happens to have installed.

---

## 4. libc++: 12 symbols the headers declare and refuse to define

`darwin/usr/lib/libc++.1.dylib` was 14 symbols — `operator new`/`delete`, the
`__cxa_guard_*` trio, `std::terminate`. That is genuinely everything
`cxx_init` leaves undefined, because its `std::string` fits in the
short-string buffer and every other member is a header inline.

quartz uses `std::string`, `std::vector`, `std::unordered_map`,
`std::unordered_set` and `std::sort` in anger, and reached 12 symbols that
LLVM 18's headers **declare and deliberately do not define inline** — they carry
`extern template` declarations (`string:2129`, `__algorithm/sort.h:916`,
`__hash_table:75`) so that the shipping dylib holds one copy. On Linux that
dylib is an ELF and cannot be linked into a Mach-O guest, so the copy has to
come from us.

`darwin/src/libcxx_std.cpp`, 180 lines, 72 emitted symbols. The split matters:

**Nine are not written at all.** `template class std::basic_string<char>;` is an
explicit instantiation *definition*, which overrides the header's extern-template
declaration and makes the compiler emit **LLVM 18's own code from LLVM 18's own
headers**. That is precisely what libc++'s `src/string.cpp` does. Those nine
cannot silently drift from the header set they are compiled against, because
they *are* that header set.

**`__sort` is one line**, forwarding to `__sort_dispatch<_ClassicAlgPolicy>` —
which is exactly what `std::sort()` calls inline for every type that has no
extern-template specialisation. So `sort<double*>` takes the same code path as
`sort<MyStruct*>` rather than an approximation of it. (Its comparator parameter
is deliberately unused: `__less<T,T>` is an empty struct with no `operator()`,
and libc++'s own comment says why — "it's empty because all comparisons should
be transparent". The transparent `__less<void,void>` is stateless, so
substituting it is not an approximation.)

**Two are written and cannot be wrong**: `to_string(int)` and friends. Decimal
formatting has one right answer.

**One is written and could have been wrong**: `__next_prime`. libc++ reaches it
with a 210-wheel and a table of small primes, but the *contract* is "smallest
prime ≥ n" and trial division gives the same answer. This matters more than it
looks — `__next_prime` picks `unordered_map`'s bucket count, so a different
answer means a different **iteration order** than the same program gets on
macOS. (quartz's five `unordered_map`s are keyed on heap pointers and never
iterated, so it would not have shown up here. Relying on that would be luck.)

### `-fno-exceptions`, and why it is not laziness

Built with exceptions on, quartz leaves **10 further undefined symbols**:
`std::logic_error`'s ctor, `std::length_error`/`out_of_range`/
`bad_array_new_length`'s dtors, their vtables and typeinfos, and
`__cxa_free_exception`. All live in libc++abi, which we do not have.

Every one is reachable only from a `throw` — and machorun cannot deliver a
throw. Apple's binaries carry `__TEXT,__unwind_info` (compact unwind), not
`.eh_frame`, so there is no unwinder; that is `unwind-compact`, the #2 ranked
blocker, and it is the same wall that fails `tests/objc44/038` and `/044`.

quartz itself contains **no `throw`, `try` or `catch`** — the throw sites are
libc++'s own bounds and allocation checks. With `-fno-exceptions` those become
`_LIBCPP_VERBOSE_ABORT`, i.e. a loud trap. Loud abort over silent stub.

**The macOS oracle is built with the same flag** (`scripts/build_quartz_macos.sh`),
so the pixel comparison is not secretly comparing two different C++ dialects.

---

## 5. The fixture, and why it is shaped this way

`tests/src/quartz.c` — plain C, no Objective-C anywhere. That is the whole
point of it. Every other route to "a Darwin binary rasterises on Linux" runs
through `objc_msgSend`, and when a pixel comes out wrong you cannot tell whether
the rasteriser, the loader, libSystem's libm or the ObjC runtime did it. This one
isolates quartz-under-machorun, so a later Objective-C failure has one fewer
suspect.

### Per-stage checksums

Nine drawing stages, each followed by an FNV-1a of the **whole** backing store
and five probe pixels, printed to stdout:

```
stage 1 background         fnv1a=d94f2402c6af0383  171c29ff  171c29ff ...
stage 4 bezier-fill        fnv1a=863bf669fc3ef033  171c29ff  403166ff ...
stage 8 rotated            fnv1a=550799e8b5041e36  171c29ff  403166ff ...
```

A divergence is therefore localised to a drawing stage **on stdout, before the
PNG is compared**. That is the difference between "the PNG differs" and a bug
report. The stages are chosen for what they exercise, not for what they look
like: flat fill, integer-boundary coverage, source-over with fractional alpha,
cubic flattening tolerance, the stroke converter with dashes and round joins,
scanline gradient interpolation, radial gradient, the transcendental rotation,
and an even-odd clip.

### The install-name problem, and why `@rpath` was rejected

The fixture's `LC_LOAD_DYLIB` says `/usr/lib/libquartz.dylib`, which is not a
file on either host. On Linux, machorun's prefix map turns it into
`darwin/usr/lib/libquartz.dylib` — the clang-18 build. On macOS, dyld is pointed
at the Apple-clang build with `DYLD_LIBRARY_PATH`, which **does** apply
leaf-name substitution to absolute install names (verified 2026-08-26: the same
binary that dies with `Library not loaded: /usr/lib/libquartz.dylib` runs when
the variable is set).

`@rpath` would have been the conventional choice and is **wrong here**: it
resolves against the same repository layout on both hosts, so both runs would
load the same file and the Linux run would silently not be testing the Linux
build. A test that cannot fail is worse than no test.

Nothing is installed on the macOS host. `/usr/lib` is untouched.

### Why it is not in `tests/manifest.tsv`

Two structural reasons: its result is a **file** rather than stdout, and its
macOS run needs an environment variable. Teaching `harness/run_macos.sh` either
would put a fixture-specific special case into the thing that grades every other
fixture. `scripts/quartz_pixel.sh` is its differential and follows the same
rules — it re-executes the macOS side every run rather than trusting the
baseline, and it never writes `tests/expected/` except under `--record`, which
only runs on macOS.

---

## 6. Results

```
$ scripts/quartz_pixel.sh
== macOS oracle (native, same bytes)
  exit=0  png=26861 bytes
  oracle vs baseline     matches committed baseline
== machorun on Linux/arm64 (docker, machorun-testbed:24.04)
  exit=0  png=26861 bytes
== differential
  stage checksums        identical
  png                    BYTE-IDENTICAL  (26861 bytes, sha256 96aa747a85f6c35f)
```

Unregressed, re-measured after every change above:

| suite | before | after |
|---|---|---|
| `scripts/difftest.sh` | 19 pass / 1 xfail / 1 no-oracle | **19 / 1 / 1** |
| `scripts/objc44.sh` | 41/44 | **41/44**, same three failures |
| `scripts/gen_tbd.sh` | 3 checks pass | **3 checks pass**, 70 binaries, 260 symbols, 0 unresolved |

---

## 7. What this does and does not establish

**Does.** A precompiled Apple-toolchain Mach-O binary rasterises graphics on
Linux/arm64 and the result is identical, bit for bit, to the same bytes running
on macOS. The drawing engine is C++17 with a 507-symbol C API, built as a Mach-O
dylib on Linux from unpatched sources, and the whole pipeline — malloc, libm,
libc++'s out-of-line members, `fopen`/`fwrite`, a PNG encoder, TLV, static
initialisers in a dylib — runs under our loader against our libSystem.

**Does not.**

1. **It is `QZ*`, not `CG*`.** No `CoreGraphics.framework` exists here. A guest
   linked against Apple's CoreGraphics resolves none of its imports. Bridging is
   separate work with its own ABI questions — `CGColorSpaceRef` is a real
   CoreFoundation object and `QZColorSpaceRef` is not.
2. **34 of 507 exports are exercised** by this fixture, and **36** by all three
   drawing fixtures together — rungs (o) and (p) added exactly two.
   The Core Animation layer tree, text and
   font loading, image decode, PDF, patterns, shadings, CMYK, Display P3, blend
   modes and transparency layers are compiled, exported, and *untested here*.
   Upstream scores 97.46/100 against Apple's frameworks with all of them; that is
   upstream's measurement, not this repository's.
   (`docs/UNIMPLEMENTED.md#quartz-fixture-coverage`.)
3. **One libm workload agreed.** See §3.
4. **No Objective-C is involved, by construction.** Composing quartz with objc4
   — an ObjC drawing API over `QZ*` — is the next rung and is not attempted here.
5. **Swift is still out of reach**, and this work says nothing new about it.
   The reason this milestone went through `~/quartz` rather than `~/uikit` is
   that quartz is C++ and therefore buildable by the same
   `clang -target arm64-apple-macos11` route objc4 already uses, whereas
   OpenUIKit is Swift.

   > **Re-measured 2026-08-26, `docs/STATUS.md` §11.5.** The claim this
   > paragraph passed on second-hand — that `swiftc -target arm64-apple-macos11`
   > on Linux "cannot emit Mach-O at all" — is **false**. With `-parse-stdlib`
   > it emits a valid arm64 Mach-O object (`cf fa ed fe`); the error *"unable to
   > load standard library for target"* is exactly what it says, and
   > `/usr/lib/swift/` on Linux has `linux` and `embedded` and no `macosx`. The
   > wall is a missing Darwin **stdlib**, not a missing backend — which is a
   > distribution and ABI problem, not something machorun can close from this
   > side. The conclusion for this repository is unchanged; the reason is not.

---

## 8. Reproducing it

```sh
# Linux side (in the test-bed container)
scripts/build.sh everything          # loader + darwin/*.dylib + libobjc + libquartz + .tbd

# macOS side
scripts/build_quartz_macos.sh        # the oracle library, Apple's clang
tests/build_fixtures.sh quartz    # the fixture, Apple's clang (committed)

# the differential (from the macOS host; drives docker for the Linux half)
scripts/quartz_pixel.sh
scripts/quartz_pixel.sh --record     # macOS only, rewrites tests/expected/quartz.*
```

Re-pull quartz from upstream with `scripts/vendor_quartz.sh`; check the
committed hashes with `--verify`; see what has changed upstream with `--diff`.
`vendor/quartz/PROVENANCE.md` says what was copied, what was deliberately not,
and under what licence.
