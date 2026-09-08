#!/usr/bin/env python3
"""Measure Focus's complete Combine+UIControl.swift, original iOS vs lowered ELF.

From uikit/ on the Mac (uses only a suffix-private iPhone 16 / iOS 26.1):
  python3 Tools/ingest/route_a_generic_control_probe.py oracle --out /tmp/generic-oracle
After copying the tree into uikit-linux:/work-route-a/uikit and the oracle JSON:
  python3 Tools/ingest/route_a_generic_control_probe.py linux --out /work-route-a/generic-proof --oracle /work-route-a/oracle.json
The Linux mode temporarily adds a scratch SwiftPM target, restores the copied
manifest in finally, and never edits the upstream source. No ObjC compiler flags,
mock publishers, or substitute action methods are used.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import sys


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('mode', choices=['oracle', 'linux'])
    parser.add_argument('--out', required=True, type=Path)
    parser.add_argument('--oracle', type=Path)
    args = parser.parse_args()
    package = Path(__file__).resolve().parents[2]
    original = package / 'Sources/Blockzilla/Blockzilla/UIComponents/URLBar/Combine+UIControl.swift'
    fixture = package / 'Tools/ingest/fixtures/route_a_generic_control/Probe.swift'
    out = args.out.resolve()
    if out == package or package in out.parents:
        parser.error('evidence and app bundles must be outside the source package')
    out.mkdir(parents=True, exist_ok=True)
    record = {'source_sha256': hashlib.sha256(original.read_bytes()).hexdigest(),
              'probe_sha256': hashlib.sha256(fixture.read_bytes()).hexdigest(), 'commands': []}

    def run(name, command, check=True):
        print(name, flush=True)
        p = subprocess.run(command, cwd=package, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        (out / (name + '.log')).write_text(p.stdout)
        record['commands'].append({'name': name, 'command': command, 'exit': p.returncode})
        (out / 'result.json').write_text(json.dumps(record, indent=2) + '\n')
        if check and p.returncode:
            raise RuntimeError(f'{name}: {p.stdout[-8000:]}')
        return p

    if args.mode == 'oracle':
        suffix = os.environ.get('SIM_DEVICE_SUFFIX', '')
        if sys.platform != 'darwin' or not suffix:
            parser.error('oracle requires Darwin and a private SIM_DEVICE_SUFFIX')
        app = out / 'RouteAGenericControl.app'
        app.mkdir(exist_ok=True)
        bundle = 'org.openuikit.route-a-generic-control'
        (app / 'Info.plist').write_bytes(plistlib.dumps({
            'CFBundleIdentifier': bundle, 'CFBundleExecutable': 'RouteAGenericControl',
            'CFBundleName': 'RouteAGenericControl', 'CFBundlePackageType': 'APPL',
            'CFBundleVersion': '1', 'CFBundleShortVersionString': '1.0',
            'LSRequiresIPhoneOS': True, 'UIDeviceFamily': [1], 'UILaunchScreen': {},
        }))
        run('swift-version', ['xcrun', 'swiftc', '--version'])
        sdk = run('sdk', ['xcrun', '--show-sdk-path', '--sdk', 'iphonesimulator']).stdout.strip()
        run('original-build', ['xcrun', '--sdk', 'iphonesimulator', 'swiftc', '-swift-version', '5', '-O',
                              '-target', 'arm64-apple-ios26.0-simulator', '-sdk', sdk,
                              str(original), str(fixture), '-o', str(app / 'RouteAGenericControl')])
        name = 'OpenUIKit-GenericControl' + suffix
        runtime = 'com.apple.CoreSimulator.SimRuntime.iOS-26-1'
        devices = json.loads(run('devices', ['xcrun', 'simctl', 'list', 'devices', 'available', '-j']).stdout)
        candidates = [d for d in devices['devices'].get(runtime, []) if d['name'] == name]
        if candidates:
            udid = candidates[0]['udid']
            was_booted = candidates[0]['state'] == 'Booted'
        else:
            udid = run('create', ['xcrun', 'simctl', 'create', name,
                                  'com.apple.CoreSimulator.SimDeviceType.iPhone-16', runtime]).stdout.strip()
            was_booted = False
        record['device'] = {'name': name, 'udid': udid, 'runtime': runtime, 'type': 'iPhone 16'}
        try:
            if not was_booted:
                run('boot', ['xcrun', 'simctl', 'boot', udid])
                run('bootstatus', ['xcrun', 'simctl', 'bootstatus', udid, '-b'])
            run('install', ['xcrun', 'simctl', 'install', udid, str(app)])
            container = Path(run('container', ['xcrun', 'simctl', 'get_app_container', udid, bundle, 'data']).stdout.strip())
            capture = container / 'Documents/oracle.json'
            capture.unlink(missing_ok=True)
            run('launch', ['xcrun', 'simctl', 'launch', '--console-pty', udid, bundle])
            oracle = json.loads(capture.read_text())
            oracle['source_sha256'] = record['source_sha256']
            oracle['probe_sha256'] = record['probe_sha256']
            assert oracle['registered_selectors'] == ['eventHandler'], oracle
            (out / 'oracle.json').write_text(json.dumps(oracle, indent=2) + '\n')
            record['oracle'] = oracle
            print(json.dumps(oracle, indent=2), flush=True)
        finally:
            if not was_booted:
                run('shutdown', ['xcrun', 'simctl', 'shutdown', udid], check=False)
    else:
        if sys.platform != 'linux' or Path('/work-route-a') not in package.parents:
            parser.error('run in the isolated Linux /work-route-a package copy')
        if any(p == out or p in out.parents for p in [Path('/src'), Path('/work')]):
            parser.error('/src and /work are reserved')
        if not args.oracle:
            parser.error('--oracle is required for a measured comparison')
        oracle = json.loads(args.oracle.read_text())
        assert oracle['source_sha256'] == record['source_sha256'], 'oracle app source differs'
        assert oracle['probe_sha256'] == record['probe_sha256'], 'oracle probe differs'
        sources = package / 'RouteAGenericControlScratch'
        if sources.exists():
            parser.error(f'scratch target exists: {sources}')
        sources.mkdir()
        manifest = package / 'Package.swift'
        saved = manifest.read_bytes()
        try:
            run('swift-version', ['swift', '--version'])
            shutil.copyfile(original, sources / original.name)
            shutil.copyfile(fixture, sources / fixture.name)
            manifest.write_bytes(saved + b'\npackage.targets.append(.executableTarget(name: "RouteAGenericControlProbe", dependencies: ["UIKit", "Combine"], path: "RouteAGenericControlScratch"))\n')
            build = ['swift', 'build', '-c', 'release', '--product', 'RouteAGenericControlProbe']
            before = run('original-build', build, check=False)
            record['original_diagnostics'] = [s.strip() for s in before.stdout.splitlines() if 'error:' in s]
            assert before.returncode != 0
            assert 'Objective-C interoperability is disabled' in before.stdout
            assert "'#selector' can only be used with the Objective-C runtime" in before.stdout
            run('lower', ['python3', 'Tools/ingest/route_a_selectors.py', 'rewrite', '--route-a',
                          str(original), '--output', str(sources / original.name), '--report', str(out / 'lower.json')])
            run('lowered-build', build)
            execution = run('execution', [str(package / '.build/release/RouteAGenericControlProbe')])
            measurement = json.loads(execution.stdout)
            record['measurement'] = measurement
            record['matches_ios_oracle'] = measurement == oracle['measurement']
            assert record['matches_ios_oracle'], (measurement, oracle['measurement'])
            print('ROUTE_A_GENERIC_CONTROL_PASS specializations=3 deliveries=7 oracle_fields=' + str(len(measurement)), flush=True)
        finally:
            manifest.write_bytes(saved)
            shutil.rmtree(sources)
            record['manifest_restored'] = manifest.read_bytes() == saved
            record['original_source_unchanged'] = hashlib.sha256(original.read_bytes()).hexdigest() == record['source_sha256']
            (out / 'result.json').write_text(json.dumps(record, indent=2) + '\n')
    (out / 'result.json').write_text(json.dumps(record, indent=2) + '\n')


if __name__ == '__main__':
    main()
