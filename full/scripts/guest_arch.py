"""Host Darwin/Swift guest triple.

Keep in lockstep with full/scripts/guest_arch.inc. The TARGET triple follows
the host (arm64-apple-macos15.0 or x86_64-apple-macos15.0). Arm64 keeps the
historical output paths; x86_64 writes beside them. Do not unify this with
machorun/scripts/guest_arch.inc (macos11).
"""

from __future__ import annotations

import os
import platform


def guest_arch() -> str:
    explicit = os.environ.get("ARCH", "").strip()
    if explicit in ("x86_64", "arm64"):
        return explicit
    target = os.environ.get("TARGET", "").strip()
    if target.startswith("x86_64"):
        return "x86_64"
    if target.startswith("arm64") or target.startswith("aarch64"):
        return "arm64"
    machine = platform.machine()
    if machine in ("x86_64", "amd64"):
        return "x86_64"
    if machine in ("aarch64", "arm64"):
        return "arm64"
    raise RuntimeError(f"unsupported guest host machine: {machine}")


def macos15_target(arch: str | None = None) -> str:
    return f"{arch or guest_arch()}-apple-macos15.0"


def swift_module_triple(arch: str | None = None) -> str:
    return f"{arch or guest_arch()}-apple-macos"


def otool_cpu(arch: str | None = None) -> str:
    return "X86_64" if (arch or guest_arch()) == "x86_64" else "ARM64"


def out_suffix(arch: str | None = None) -> str:
    """Arm64 keeps historical paths; x86_64 writes beside them."""
    return "-x86_64" if (arch or guest_arch()) == "x86_64" else ""
