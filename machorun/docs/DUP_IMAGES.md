# One dylib, two paths — what dyld actually does

**Task #90 asked for a fix whose premise is false, and this file is the
measurement that says so.** The re-scoped fix — row 4 only — has since landed;
see "What was actually implemented" at the end.

#90 was filed after our CoreFoundation appeared **twice** in one guest process:
the same file sat at `/usr/lib/libCFTest.dylib` and at the
`CoreFoundation.framework` slot, both carrying `LC_ID_DYLIB
/usr/lib/libCFTest.dylib`, and objc reported all 22 CF classes as duplicated.
The proposed fix was "dedupe by `LC_ID_DYLIB` the way dyld does".

**dyld does not do that.** Measured with `tests/src/dup_install_name_probe.sh`,
which builds four variants and asks real dyld:

| # | how the second path is reached | files on disk | dep strings | **dyld** | **machorun** |
|---|---|---|---|---|---|
| 1 | `dlopen` of a distinct real path | 2 | n/a | **2 images** | — |
| 2 | dependency, **same** dep string | 2 | same | **1 image** | 1 image |
| 3 | dependency, **different** dep strings | 2 | differ | **2 images** | **2 images** |
| 4 | dependency, different dep strings, **symlink** | **1** | differ | **1 image** | **1 image** (was 2; fixed) |

Row 3 is the CoreFoundation case exactly: two byte-identical real files, two
different `LC_LOAD_DYLIB` strings, one install name. **dyld loads it twice** —
two constructors run, the dylib's static has two addresses, and the image table
lists it twice.

## What that means, in order of importance

**1. machorun was RIGHT, and the guest root was WRONG.** In the shape that
caused the incident, machorun's behaviour already matches Darwin's. Implementing
#90 as written would have made the loader **diverge from dyld** in the one row
where it currently agrees — the opposite of what this project is for. The real
defect was a root that shipped the same library at two paths, and the fixes for
that already landed in foundation-macho: a zero-export placeholder displaces the
duplicate, and `run_ud_guest.sh` REFUSES to run when the CoreFoundation slot is
a byte-identical copy of `libCFTest.dylib`.

**2. dyld's actual rule is two tests, and neither is "read the candidate's
LC_ID_DYLIB and compare".** It dedupes when (a) the requested STRING matches a
loaded image's install name or path — row 2 — or (b) the path resolves to a file
already loaded, i.e. **realpath/inode** — row 4. machorun implements (a) in
`mr_image_find_loaded` (install name OR resolved path, one matcher shared by
`mr_image_is_loaded` so the two can never disagree). It does **not** implement
(b).

**3. So there WAS one genuine divergence — row 4 — and it is now closed.** A symlink
to an already-loaded dylib gets loaded a second time under machorun and once
under dyld. Counted at the time of writing: **zero symlinked dylibs** across
`machorun/darwin`, `mrroot_full`, `mrroot_fe` and the composed container root.
Nothing in the project can currently reach it. Fixing it means keying loaded
images by `(st_dev, st_ino)` in addition to the string, which is a small change
to `mr_image_load` between `parse_load_commands` and registration — but it
should be done because a root grows symlinks the day someone versions a dylib,
not because anything is broken today.

## The trap this nearly walked into

The duplicate-class warning was real, the diagnosis "the loader keys by
requested path" was real, and the conclusion "so the loader should dedupe by
install name" **followed from neither**. It was an inference about dyld that
sounded like a description of dyld. The cost of getting it wrong would not have
been a failing test — every gate would have stayed green while the loader
quietly stopped matching Darwin on row 3, and the next person to hit a
legitimately-duplicated dylib would have seen one image where macOS shows two.

**When a fix is justified by "the way dyld does it", run dyld.** It takes four
variants and a static's address.


## What was actually implemented

Row 4 only: `mr_image_load` records `(st_dev, st_ino)` after its `fstat` and,
before mapping, returns an already-loaded image with the same pair. That is
dyld's *second* dedupe test — same FILE — and it is deliberately **not** a test
on `LC_ID_DYLIB`, so row 3 is untouched.

`tests/src/dup_images.c` is the permanent gate, and it asserts **the split, not
"one image"**: the symlink half must collapse to one image *while the copy half
stays at two*. A loader that deduped on install name would pass the first and
fail the second — in the direction that looks like an improvement, which is why
half a fixture would have been worse than none. Its baseline is recorded from
real dyld like every other fixture, so the contract is Darwin's rather than
ours.

Demonstrated to bite: with the fix stashed, `dup_images` FAILS on exactly lines
2–3 (the symlink half, `agree: no`, `2 images`) and the copy half already
matches. Gates green before and after — difftest 52→53 pass / 0 fail / 1 xfail
/ 0 drift, objc44 100/100, gen_tbd all six, check_stale ok 6, swift_gate both
orders, quartz_pixel 3/3, host_deny 9/9.

**One gate note found on the way:** `gen_tbd.sh` must be run **in the Linux
container**. On macOS it exits 1 with 28 `comm: not in sorted order` lines,
because BSD `comm` rejects input GNU `comm` accepts — a **false red** that reads
exactly like a real regression, and the mirror image of the false green in #74.
`objc44.sh` already refuses to run on Darwin and says so; `gen_tbd.sh` does not.
