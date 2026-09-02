#!/usr/bin/env python3
"""Generate a wave.py manifest from the framework-roadmap demand ranking.

  scripts/cloud/make_wave_manifest.py --top 25 --out /tmp/wave4-manifest.json

Items are the top-N frameworks by 20-app corpus coverage that are NOT listed
in ops/shipped-frameworks.txt (one name per line, '#' comments). The operator
curates that file; this script never guesses what is already shipped.

The generated prompt per framework follows the audited promote-lane shape:
demand evidence first, fail-closed first-party policy, sealed gates,
ordinary-import negative tests, no app-source changes, confined diffs.
This tool PREPARES a manifest; launching is a separate deliberate
`wave.py launch` the operator runs.
"""
import argparse
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]

PREAMBLE = """\
You are porting one Apple framework to this Linux platform monorepo.

House rules (non-negotiable, from full/first-party-frameworks/FIRST_PARTY_FRAMEWORKS_GUEST.md and the promote-lane standard):
- MEASURE FIRST: quote the corpus demand for your framework from full/framework-roadmap/framework-roadmap.json, and census what full/<framework>/ already contains before writing anything (nm any built dylib; a member census, not a guess).
- Fail closed at every OS-service boundary with TYPED Apple errors; preserve value construction, mutable state, callback cardinality, delegate delivery. Never fake a success. Raw constant values and struct layouts are ABI: transcribe from Apple SDK evidence in the repo's evidence lanes, never infer.
- Sealed warnings-as-errors host gate + ordinary-import negative test proving host-only control seams stay hidden (@_spi(OpenUIKitHost) or internal).
- Where behavior needs an Apple runtime oracle you cannot run, record it as an explicit oracle question in the PR, never a guess.
- No app or vendor source changes. Diff confined to full/<framework>/ plus gate wiring. Print denominators next to every verdict. A gate that cannot run refuses loudly with a canonical marker.
- PR body: measured gap table first, implementation summary, gate evidence block, stated deferrals."""

TASK = """\
Port {name} to Linux in full/{lower}/ following the preamble's rules.
Corpus demand rank #{rank} by app coverage in the 20-app ladder.
If full/{lower}/ already exists, this is a REPAIR/EXTEND pass: census the gap
between its exports and the corpus's member-level demand, then close the
highest-demand gaps. If it does not exist, start from the framework's
symbol-graph/evidence seed if one exists under full/framework-fanout/, else
state that the seed is missing as your first finding and build the minimal
demanded surface from SDK evidence."""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--top", type=int, default=25)
    ap.add_argument("--out", required=True)
    ap.add_argument("--name", default="fw-wave")
    args = ap.parse_args()

    roadmap = json.loads(
        (ROOT / "full/framework-roadmap/framework-roadmap.json").read_text())
    ranking = roadmap["iphoneos_runtime_port_candidate_rankings"]["by_app_coverage"]

    shipped_file = ROOT / "ops/shipped-frameworks.txt"
    if not shipped_file.is_file():
        sys.exit(f"make_wave_manifest: missing {shipped_file} — curate it first")
    shipped = {ln.strip() for ln in shipped_file.read_text().splitlines()
               if ln.strip() and not ln.startswith("#")}

    items = []
    for rank, name in enumerate(ranking, 1):
        if name in shipped:
            continue
        items.append({
            "key": name.lower(),
            "prompt": TASK.format(name=name, lower=name.lower(), rank=rank),
        })
        if len(items) >= args.top:
            break

    manifest = {
        "name": args.name,
        "model": "cursor-grok-4.6-high",
        "source": {"repository": "https://github.com/Vercantez/openuikit",
                   "ref": "main"},
        "preamble": PREAMBLE,
        "items": items,
    }
    pathlib.Path(args.out).write_text(json.dumps(manifest, indent=1) + "\n")
    skipped = len(ranking) - len(items)
    print(f"manifest: {len(items)} items written to {args.out} "
          f"(ranking={len(ranking)}, shipped/skipped={skipped})")
    for it in items[:10]:
        print(" ", it["key"])


if __name__ == "__main__":
    main()
