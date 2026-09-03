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
