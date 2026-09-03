#!/usr/bin/env python3
"""Single registry of verification-environment refusal and verdict markers.

Gates keep emitting the exact strings they emit today. This module is the
place that records what each marker *means*, so counting refusals separately
from passes and failures is uniform.

A marker that is registered but not currently emitted (NEEDS_DARWIN_BASELINE)
must not be introduced into a gate without a documented behavior change.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Iterable


@dataclass(frozen=True)
class Marker:
    """One counted environment marker."""

    name: str
    kind: str  # cannot | pass | summary | refuse
    meaning: str
    emitted_by: tuple[str, ...]
    exit_code: int | None
    currently_emitted: bool = True


# kind=cannot  — honest per-host inability; must not be counted as a test fail
# kind=pass    — a satisfied environment row
# kind=summary — denominator line
# kind=refuse  — gate-local refusal prefix (not a CURSOR_ENV_* token)

MARKERS: dict[str, Marker] = {
    "CURSOR_ENV_CANNOT_BUILD_LOADER": Marker(
        name="CURSOR_ENV_CANNOT_BUILD_LOADER",
        kind="cannot",
        meaning=(
            "machorun/src/tlv_asm.S is aarch64 assembly; the loader is a native "
            "Linux/aarch64 ELF, not a cross-built Mach-O. This host cannot assemble it."
        ),
        emitted_by=(".cursor/install-built-products.sh",),
        exit_code=None,
    ),
    "CURSOR_ENV_CANNOT_GENERATE_TBD": Marker(
        name="CURSOR_ENV_CANNOT_GENERATE_TBD",
        kind="cannot",
        meaning=(
            "machorun/scripts/gen_tbd.sh CHECK 1 requires the host ELF loader so "
            "libSystem.tbd is nm(libSystem.B.dylib) UNION loader-exports. Empty or "
            "unchecked .tbd files are a lie to ld64."
        ),
        emitted_by=(".cursor/install-built-products.sh",),
        exit_code=None,
    ),
    "CURSOR_ENV_CANNOT_STAGE_MRROOT_LOADER": Marker(
        name="CURSOR_ENV_CANNOT_STAGE_MRROOT_LOADER",
        kind="cannot",
        meaning=(
            "scratch/mrroot_full/machorun is that host ELF. Darwin dylibs may still "
            "be staged; execution-shaped gates must refuse with "
            "CURSOR_ENV_CANNOT_EXECUTE_ARM64 rather than exec a stub."
        ),
        emitted_by=(".cursor/install-built-products.sh",),
        exit_code=None,
    ),
    "CURSOR_ENV_CANNOT_STAGE_XCODE_DARWIN_OVERLAYS": Marker(
        name="CURSOR_ENV_CANNOT_STAGE_XCODE_DARWIN_OVERLAYS",
        kind="cannot",
        meaning=(
            "full/foundation/stage_fe_sysroot.sh copies Darwin/Foundation "
            ".swiftinterface and Apple apinotes from an Xcode macOS SDK. Those files "
            "are not redistributable and are not in this repo."
        ),
        emitted_by=(".cursor/install-built-products.sh",),
        exit_code=None,
    ),
    "CURSOR_ENV_CANNOT_STAGE_SIMRUNTIME_OVERLAY_DYLIBS": Marker(
        name="CURSOR_ENV_CANNOT_STAGE_SIMRUNTIME_OVERLAY_DYLIBS",
        kind="cannot",
        meaning=(
            "full/foundation/stage_swift_overlays.sh copies the Swift overlay "
            "closure (libswiftDarwin, libswift_StringProcessing, …) from an iOS "
            "CoreSimulator runtime on macOS."
        ),
        emitted_by=(".cursor/install-built-products.sh",),
        exit_code=None,
    ),
    "CURSOR_ENV_CANNOT_BUILD_OPENCOMBINE_EXPORT": Marker(
        name="CURSOR_ENV_CANNOT_BUILD_OPENCOMBINE_EXPORT",
        kind="cannot",
        meaning=(
            "OpenCombine export/artifacts are produced by compiling and running "
            "under machorun inside a pinned fm-build container. Source can be "
            "cloned without producing export/."
        ),
        emitted_by=(".cursor/install-built-products.sh",),
        exit_code=None,
    ),
    "CURSOR_ENV_CANNOT_BUILD_MODCACHE_SWIFTUI_GUEST": Marker(
        name="CURSOR_ENV_CANNOT_BUILD_MODCACHE_SWIFTUI_GUEST",
        kind="cannot",
        meaning=(
            "scratch/modcache_swiftui_guest is a swiftc module cache from a real "
            "SwiftUI guest compile against a full FE sysroot. An empty directory "
            "would look populated; leaving the path absent is the honest state."
        ),
        emitted_by=(".cursor/install-built-products.sh",),
        exit_code=None,
    ),
    "CURSOR_ENV_CANNOT_EXECUTE_ARM64": Marker(
        name="CURSOR_ENV_CANNOT_EXECUTE_ARM64",
        kind="cannot",
        meaning=(
            "machorun executes arm64 Mach-O natively on Linux/aarch64. This host "
            "can compile and link arm64 Mach-O but cannot run it. Do not qemu or stub. "
            "Canonical text from .cursor/refuse-arm64-execution.sh (exit 2)."
        ),
        emitted_by=(
            ".cursor/refuse-arm64-execution.sh",
            "full/swiftui/build_focus_widget_guest.sh",
            "full/swiftui/build_focus_onboarding_guest.sh",
            "full/swiftui/build_focus_package_guest.sh",
        ),
        exit_code=2,
    ),
    "NEEDS_DARWIN_BASELINE": Marker(
        name="NEEDS_DARWIN_BASELINE",
        kind="cannot",
        meaning=(
            "Unified name for a Darwin baseline this host cannot materialize "
            "(Xcode overlays and/or CoreSimulator overlay dylibs). Not currently "
            "emitted: gates use CURSOR_ENV_CANNOT_STAGE_XCODE_DARWIN_OVERLAYS and "
            "CURSOR_ENV_CANNOT_STAGE_SIMRUNTIME_OVERLAY_DYLIBS. Do not start "
            "emitting this token without a documented behavior change."
        ),
        emitted_by=(),
        exit_code=None,
        currently_emitted=False,
    ),
    "CURSOR_ENV_SUMMARY": Marker(
        name="CURSOR_ENV_SUMMARY",
        kind="summary",
        meaning="One line: can=… cannot=… unavailable=N fingerprint=…",
        emitted_by=(".cursor/verify-cloud-environment.sh",),
        exit_code=None,
    ),
    "ENV_PREPARE_SUMMARY": Marker(
        name="ENV_PREPARE_SUMMARY",
        kind="summary",
        meaning=(
            "One line from scripts/env/prepare.py with denominators "
            "satisfied/cold-built/staged/CANNOT."
        ),
        emitted_by=("scripts/env/prepare.py",),
        exit_code=None,
    ),
    "CURSOR_CORPUS_OK": Marker(
        name="CURSOR_CORPUS_OK",
        kind="pass",
        meaning="One pinned scratch checkout matched commit+tree+origin+clean.",
        emitted_by=(".cursor/clone-pinned-repo.sh",),
        exit_code=0,
    ),
    "CURSOR_SCRATCH_CORPUS_OK": Marker(
        name="CURSOR_SCRATCH_CORPUS_OK",
        kind="pass",
        meaning="Corpus pins N/N cloned or reused.",
        emitted_by=(".cursor/install-scratch-corpus.sh",),
        exit_code=0,
    ),
    "CURSOR_BUILT_PRODUCTS_OK": Marker(
        name="CURSOR_BUILT_PRODUCTS_OK",
        kind="pass",
        meaning="In-VM Mach-O products hashed; loader/tbd flags recorded.",
        emitted_by=(".cursor/install-built-products.sh",),
        exit_code=0,
    ),
    "CURSOR_ENV_TOOLCHAIN_ATTESTED": Marker(
        name="CURSOR_ENV_TOOLCHAIN_ATTESTED",
        kind="pass",
        meaning="Live toolchain fingerprint matches the verify stamp and pinned image digest.",
        emitted_by=(".cursor/attest-cursor-env.sh",),
        exit_code=0,
    ),
    "CURSOR_SWIFT_ENVIRONMENT_OK": Marker(
        name="CURSOR_SWIFT_ENVIRONMENT_OK",
        kind="pass",
        meaning="Swift 6.2.4 linux toolchain inventory passed.",
        emitted_by=(".cursor/verify-cloud-environment.sh",),
        exit_code=0,
    ),
}


CANNOT_PREFIX = "CURSOR_ENV_CANNOT_"

# Gate-local refusal prefixes. These are not CURSOR_ENV_* tokens; they still
# count as refusals, not as test failures, when the text is an environment
# precondition rather than a product assertion.
GATE_REFUSE_PREFIXES: tuple[str, ...] = (
    "core_guest_package: REFUSING --",
    "focus_widget_guest:",
    "build_full: REFUSING TO BUILD --",
    "pinned_inputs: REFUSING --",
    "cursor-env-attest: REFUSING --",
    "cursor-env: REFUSING --",
    "require_fresh_root: REFUSING TO GRADE --",
    "GUEST ROOT NOT USABLE:",
    "ProofError",
)


def cannot_markers() -> tuple[Marker, ...]:
    return tuple(m for m in MARKERS.values() if m.kind == "cannot")


def emitted_cannot_names() -> tuple[str, ...]:
    return tuple(
        m.name for m in cannot_markers() if m.currently_emitted
    )


def parse_marker_line(line: str) -> str | None:
    """Return the marker name if `line` starts with a registered token."""
    stripped = line.strip()
    for name in MARKERS:
        if stripped == name or stripped.startswith(name + " ") or stripped.startswith(name + "="):
            return name
    return None


def classify_line(line: str) -> str:
    """Classify a log line: cannot | pass | summary | refuse | other."""
    name = parse_marker_line(line)
    if name is not None:
        return MARKERS[name].kind
    stripped = line.strip()
    for prefix in GATE_REFUSE_PREFIXES:
        if stripped.startswith(prefix):
            return "refuse"
    return "other"


def count_kinds(lines: Iterable[str]) -> dict[str, int]:
    """Count classified lines. Denominator keys are always present."""
    counts = {"cannot": 0, "pass": 0, "summary": 0, "refuse": 0, "other": 0}
    for line in lines:
        counts[classify_line(line)] += 1
    return counts


def main() -> int:
    emitted = sum(1 for m in MARKERS.values() if m.currently_emitted)
    cannot = sum(1 for m in MARKERS.values() if m.kind == "cannot" and m.currently_emitted)
    reserved = sum(1 for m in MARKERS.values() if not m.currently_emitted)
    print(
        f"ENV_MARKERS_REGISTRY markers={len(MARKERS)} "
        f"emitted={emitted}/{len(MARKERS)} "
        f"cannot={cannot}/{len(MARKERS)} "
        f"reserved={reserved}/{len(MARKERS)}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
