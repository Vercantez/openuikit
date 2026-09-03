#!/usr/bin/env python3
"""Load env/contract.json and assert it agrees with the locks it consumes."""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any


class ContractError(RuntimeError):
    pass


def repo_root_from(start: Path | None = None) -> Path:
    cursor = (start or Path(__file__).resolve()).parent
    for candidate in [cursor, *cursor.parents]:
        if (candidate / "env" / "contract.json").is_file() and (
            candidate / "harness" / "Dockerfile"
        ).is_file():
            return candidate
    raise ContractError("cannot locate repository root from env/contract.json")


def load_contract(root: Path | None = None) -> dict[str, Any]:
    root = root or repo_root_from()
    path = root / "env" / "contract.json"
    if not path.is_file() or path.is_symlink():
        raise ContractError(f"contract is missing or a symlink: {path}")
    payload = json.loads(path.read_text(encoding="utf-8"))
    if payload.get("schema") != 1:
        raise ContractError(f"unsupported contract schema: {payload.get('schema')}")
    return payload


def _read(root: Path, relative: str) -> str:
    path = root / relative
    if not path.is_file() or path.is_symlink():
        raise ContractError(f"lock is missing or a symlink: {relative}")
    return path.read_text(encoding="utf-8")


def checkouts_by_id(contract: dict[str, Any]) -> dict[str, dict[str, Any]]:
    rows = contract["checkouts"]
    ids = [row["id"] for row in rows]
    if len(ids) != len(set(ids)):
        raise ContractError("duplicate checkout id")
    return {row["id"]: row for row in rows}


def demanded_by(contract: dict[str, Any], gate: str) -> dict[str, list[dict[str, Any]]]:
    """Rows in each section that list `gate` in demanded_by."""
    out: dict[str, list[dict[str, Any]]] = {}
    for section in (
        "checkouts",
        "built_products",
        "staged_externals",
        "host_requirements",
        "filesystem_preconditions",
    ):
        out[section] = [
            row for row in contract.get(section, []) if gate in row.get("demanded_by", [])
        ]
    return out


def _shell_assign(text: str, name: str) -> str:
    match = re.search(rf"^{re.escape(name)}=([0-9a-f]+)\s*$", text, re.MULTILINE)
    if not match:
        raise ContractError(f"lock is missing {name}")
    return match.group(1)


def _perl_spec(text: str, key: str, field: str) -> str:
    block = re.search(
        rf"'{re.escape(key)}'\s*=>\s*\{{(.*?)^\s*\}},",
        text,
        re.MULTILINE | re.DOTALL,
    )
    if not block:
        raise ContractError(f"pinned_inputs.pl is missing spec {key}")
    match = re.search(rf"{field}\s*=>\s*'([0-9a-f]+)'", block.group(1))
    if not match:
        raise ContractError(f"pinned_inputs.pl {key} is missing {field}")
    return match.group(1)


def validate_against_locks(root: Path | None = None) -> list[str]:
    """Return agreement notes. Raise ContractError on drift vs a lock."""
    root = root or repo_root_from()
    contract = load_contract(root)
    notes: list[str] = []
    checkouts = checkouts_by_id(contract)

    corpus = json.loads(_read(root, ".cursor/scratch-corpus-pins.json"))
    digest = corpus["pinnedImage"]["digest"]
    if contract["pinned_image"]["digest"] != digest:
        raise ContractError(
            f"pinned image digest {contract['pinned_image']['digest']} != corpus lock {digest}"
        )
    notes.append("pinned_image digest agrees with .cursor/scratch-corpus-pins.json")

    dockerfile = _read(root, "harness/Dockerfile")
    if digest not in dockerfile:
        raise ContractError("harness/Dockerfile does not pin the contract image digest")
    notes.append("pinned_image digest agrees with harness/Dockerfile")

    by_corpus_id = {row["id"]: row for row in corpus["sources"]}
    for source_id, lock_row in by_corpus_id.items():
        row = checkouts.get(source_id)
        if row is None:
            raise ContractError(f"contract is missing corpus checkout {source_id}")
        for field in ("repository", "commit", "tree", "destination"):
            if row.get(field) != lock_row[field]:
                raise ContractError(
                    f"{source_id}.{field} {row.get(field)!r} != corpus lock {lock_row[field]!r}"
                )
        notes.append(f"checkout {source_id} agrees with .cursor/scratch-corpus-pins.json")

    vendor = _read(root, "scripts/vendor_pins.sh")
    uikit_tree = _shell_assign(vendor, "EXPECTED_INREPO_UIKIT_TREE")
    machorun_tree = _shell_assign(vendor, "EXPECTED_INREPO_MACHORUN_TREE")
    if checkouts["uikit-inrepo"]["tree"] != uikit_tree:
        raise ContractError("uikit-inrepo tree disagrees with scripts/vendor_pins.sh")
    if checkouts["machorun-inrepo"]["tree"] != machorun_tree:
        raise ContractError("machorun-inrepo tree disagrees with scripts/vendor_pins.sh")
    notes.append("in-repo vendor trees agree with scripts/vendor_pins.sh")

    pinned = _read(root, "full/foundation/pinned_inputs.pl")
    for name in ("swift-foundation", "swift-collections"):
        commit = _perl_spec(pinned, name, "commit")
        tree = _perl_spec(pinned, name, "tree")
        if checkouts[name]["commit"] != commit or checkouts[name]["tree"] != tree:
            raise ContractError(f"{name} disagrees with full/foundation/pinned_inputs.pl")
        notes.append(f"checkout {name} agrees with full/foundation/pinned_inputs.pl")

    evidence = json.loads(_read(root, "full/framework-fanout/external-evidence-sources.json"))
    macios = next(row for row in evidence["sources"] if row["id"] == "dotnet-macios")
    row = checkouts["dotnet-macios"]
    if row["commit"] != macios["commit"] or row["repository"] != macios["repository"]:
        raise ContractError("dotnet-macios disagrees with external-evidence-sources.json")
    notes.append("checkout dotnet-macios agrees with external-evidence-sources.json")

    scf = checkouts["swift-corelibs-foundation"]
    udinc = _read(root, "scripts/x86/ud_guest.inc")
    for token, value in (
        ("PHASE2_UD_GUEST_CF_COMMIT", scf["commit"]),
        ("PHASE2_UD_GUEST_CF_TREE", scf["tree"]),
        ("PHASE2_UD_GUEST_CF_REPO", scf["repository"]),
        ("PHASE2_UD_GUEST_CF_DEST_REL", scf["destination"]),
    ):
        if f"{token}={value}" not in udinc:
            raise ContractError(
                f"swift-corelibs-foundation {token}={value} missing from scripts/x86/ud_guest.inc"
            )
    if "ud-guest-x86" not in scf["demanded_by"]:
        raise ContractError("swift-corelibs-foundation is not demanded_by ud-guest-x86")
    notes.append("checkout swift-corelibs-foundation agrees with scripts/x86/ud_guest.inc")

    swiftcore = next(
        item for item in contract["staged_externals"] if item["id"] == "libswiftCore"
    )
    policy = _read(root, "full/oracle-opencombine/policy.json")
    if swiftcore["sha256"] not in policy:
        raise ContractError("libswiftCore sha256 is not in full/oracle-opencombine/policy.json")
    artifact = root / swiftcore["source"]
    if artifact.is_file() and not artifact.is_symlink():
        import hashlib

        digest_file = hashlib.sha256(artifact.read_bytes()).hexdigest()
        if digest_file != swiftcore["sha256"]:
            raise ContractError(
                f"in-repo libswiftCore artifact {digest_file} != contract {swiftcore['sha256']}"
            )
        notes.append("libswiftCore sha256 agrees with in-repo swiftcore-macho artifact")
    else:
        notes.append("libswiftCore artifact absent; sha256 lock-only")

    widget = contract["focus_widget_attestation_pins"]
    gate = _read(root, "full/swiftui/build_focus_widget_guest.sh")
    compared = 0
    for key, value in widget.items():
        if key == "notes":
            continue
        token = f"{key}={value}"
        if token not in gate:
            raise ContractError(f"focus-widget pin {token} is missing from the gate")
        compared += 1
    notes.append(
        f"focus_widget_attestation_pins {compared}/{compared} agree with "
        "full/swiftui/build_focus_widget_guest.sh"
    )

    every_row = 0
    cited = 0
    for section in (
        "checkouts",
        "built_products",
        "staged_externals",
        "host_requirements",
        "filesystem_preconditions",
    ):
        for row in contract[section]:
            every_row += 1
            if row.get("demanded_by"):
                cited += 1
            else:
                raise ContractError(f"{section} id={row.get('id')} has empty demanded_by")
    notes.append(f"demanded_by cited {cited}/{every_row} environment rows")
    return notes


def main() -> int:
    notes = validate_against_locks()
    print(f"ENV_CONTRACT_LOCKS_OK agreements={len(notes)}/{len(notes)}")
    for note in notes:
        print(f"  {note}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
