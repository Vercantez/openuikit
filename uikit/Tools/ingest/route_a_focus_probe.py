#!/usr/bin/env python3
"""Compile original and lowered Focus cells, then fire their actions on Linux.

Run only in the isolated operator-container copy, after its release build:
  python3 Tools/ingest/route_a_focus_probe.py --out /work-route-a/focus-probe
The copied Package.swift is temporarily extended, then restored in finally.
No original app source is edited. Full commands/logs and source hashes are kept
under --out. Settings/colors/localization are explicit fixture dependencies;
UIKit, Combine, cell methods and the dispatch registry are production code.
"""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', required=True, type=Path)
    args = parser.parse_args()
    package = Path(__file__).resolve().parents[2]
    out = args.out.resolve()
    reserved = (Path('/src'), Path('/work'))
    if sys.platform != 'linux' or Path('/work-route-a') not in package.parents:
        parser.error('run in the Linux /work-route-a package copy, never the operator trees')
    if any(p == out or p in out.parents for p in reserved):
        parser.error('/src and /work are reserved')
    out.mkdir(parents=True, exist_ok=True)
    sources = package / 'RouteASelectorProbeScratch'
    if sources.exists():
        parser.error(f'scratch target already exists: {sources}')
    sources.mkdir()
    app = package / 'Sources/Blockzilla/Blockzilla'
    originals = [
        app / 'Theme/ThemeCells/ThemeTableViewToggleCell.swift',
        app / 'Tracking Protection/Views/SwitchTableViewCell.swift',
        app / 'Lib/PaddedSwitch.swift',
        app / 'Theme/SystemThemeDelegate.swift',
        app / 'Tracking Protection/Model/ToggleItem.swift',
    ]
    hashes = {str(p.relative_to(package)): hashlib.sha256(p.read_bytes()).hexdigest() for p in originals}
    results = {'source_sha256': hashes, 'commands': []}

    def run(name, command):
        print(name, flush=True)
        p = subprocess.run(command, cwd=package, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        (out / (name + '.log')).write_text(p.stdout)
        results['commands'].append({'name': name, 'command': command, 'exit': p.returncode})
        (out / 'result.json').write_text(json.dumps(results, indent=2) + '\n')
        return p

    manifest = package / 'Package.swift'
    saved = manifest.read_bytes()
    try:
        for source in originals:
            shutil.copyfile(source, sources / source.name)
        for source in (package / 'Tools/ingest/fixtures/route_a_selector').glob('*.swift'):
            shutil.copyfile(source, sources / source.name)
        manifest.write_bytes(saved + b'\npackage.targets.append(.executableTarget(name: "RouteASelectorProbe", dependencies: ["UIKit", "Combine"], path: "RouteASelectorProbeScratch"))\n')
        build = ['swift', 'build', '-c', 'release', '--product', 'RouteASelectorProbe']
        before = run('original-build', build)
        results['original_diagnostics'] = [line.strip() for line in before.stdout.splitlines() if 'error:' in line]
        assert before.returncode != 0, 'original #selector sources unexpectedly compiled'
        assert 'Objective-C interoperability is disabled' in before.stdout
        assert "'#selector' can only be used with the Objective-C runtime" in before.stdout
        for source in originals[:2]:
            lowered = run('lower-' + source.stem, [
                'python3', 'Tools/ingest/route_a_selectors.py', 'rewrite', '--route-a',
                str(source), '--output', str(sources / source.name),
                '--report', str(out / (source.stem + '.json')),
            ])
            assert lowered.returncode == 0, lowered.stdout
        after = run('lowered-build', build)
        assert after.returncode == 0, after.stdout[-8000:]
        probe = run('execution', [str(package / '.build/release/RouteASelectorProbe')])
        assert probe.returncode == 0, probe.stdout
        assert 'ROUTE_A_SELECTOR_PASS cells=2 deliveries=6 unresolved=0' in probe.stdout
        results['execution'] = probe.stdout
        print(probe.stdout, end='')
    finally:
        manifest.write_bytes(saved)
        shutil.rmtree(sources)
        results['original_sources_unchanged'] = all(hashlib.sha256((package / p).read_bytes()).hexdigest() == h for p, h in hashes.items())
        (out / 'result.json').write_text(json.dumps(results, indent=2) + '\n')


if __name__ == '__main__':
    main()
