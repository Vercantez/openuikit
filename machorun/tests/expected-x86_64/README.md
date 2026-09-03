Operator-recorded Darwin/x86_64 (Rosetta 2) baselines live here.

This directory stays empty until a macOS operator re-records a fixture whose
output is genuinely arch-dependent. Do not copy tests/expected/ into here, and
do not invent numbers. See docs/X86_64.md.

Canonical marker used by the in-VM scoreboard: NEEDS_DARWIN_X86_BASELINE.

## Recorded 2026-09-03 (macOS 26.5.2, Rosetta 2, Xcode 26.1 SDK, `-target x86_64-apple-macos12` / `-macos11` for the classic twin)

varargs, varargs_classic, mach, vm_copy, uname, hostbound_surface, fmal, remquol.
Each differs from `tests/expected/` only on the documented arch-dependent lines
(`sizeof(long double)` 16, `machine [x86_64]`, 4 KiB page sums, `ld80_bit_survives yes`,
`strtold_l width 16`). Built by the arm64 fixture script with the two target
variables switched to x86_64 and a separate bin dir; run with `arch -x86_64`.

## Recorded 2026-09-03: `cache_layout_oversize` (loader diagnostic, no Darwin twin)

`tests/manifest.tsv` marks this fixture `norun` on Darwin ("segment filesize
exceeds the file; Darwin has no twin for the loader diagnostic"): the arm64
`tests/expected/` files are machorun's own diagnostic, not an oracle record,
and there is nothing to run under Rosetta. The x86_64 expectation here is the
same diagnostic from the x86_64 loader on the Linux box at main eaf71dd9,
reviewed against arm64: identical shape, 4 KiB packed layout instead of 16 KiB
(`offset 8192+153 exceed the file (8344 bytes)` vs `16384+457 … 16840`), exit 70.
`llvm-otool -l` on the packed x86_64 binary confirms the __LINKEDIT
fileoff+filesize extend past EOF, which is the condition the fixture exists to
diagnose.
