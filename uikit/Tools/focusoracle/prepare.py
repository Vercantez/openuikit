#!/usr/bin/env python3
"""Prepare an isolated copy of upstream's Xcode project; never edit app sources."""
import hashlib, json, pathlib, plistlib, shutil, subprocess, sys
root = pathlib.Path(__file__).resolve().parents[2]
corpus = pathlib.Path(sys.argv[1]).expanduser().resolve()
work = pathlib.Path(sys.argv[2]).resolve()
sha = subprocess.check_output(['git', '-C', str(corpus), 'rev-parse', 'HEAD'], text=True).strip()
assert sha == 'a2832521c1daa0c23419c73705ae043ed60c9791', sha
subprocess.run(['git', '-C', str(corpus), 'diff', '--quiet', 'HEAD', '--', 'focus-ios'], check=True)
app = work / 'focus-ios'
if not app.exists():
    shutil.copytree(corpus / 'focus-ios', app)
pbx = app / 'Blockzilla.xcodeproj/project.pbxproj'
project = json.loads(subprocess.check_output(['plutil', '-convert', 'json', '-o', '-', str(corpus / 'focus-ios/Blockzilla.xcodeproj/project.pbxproj')]))
objects = project['objects']
# Only the SDKs needing network/Rust/crash reporting use launch's stand-ins.
for name, source in [('Glean', 'Sources/RealAppProbe/FocusModules/Glean/Glean.swift'), ('Sentry', 'Sources/Sentry/Sentry.swift'), ('FocusAppServices', 'Sources/FocusAppServices/FocusAppServices.swift')]:
    package = work / name
    (package / 'Sources' / name).mkdir(parents=True, exist_ok=True)
    shutil.copy2(root / source, package / 'Sources' / name / (name + '.swift'))
    (package / 'Package.swift').write_text('// swift-tools-version:5.5\nimport PackageDescription\nlet package = Package(name: "'+name+'", platforms: [.iOS(.v15)], products: [.library(name: "'+name+'", targets: ["'+name+'"])], targets: [.target(name: "'+name+'")])\n')
for name, pin in [('SnapKit','e74fe2a978d1216c3602b129447c7301573cc2d8'), ('Fuzi','f08c8323da21e985f3772610753bcfc652c2103f')]:
    dep = corpus.parent/'deps'/name
    assert subprocess.check_output(['git','-C',str(dep),'rev-parse','HEAD'],text=True).strip() == pin
    subprocess.run(['git','-C',str(dep),'diff','--quiet','HEAD'],check=True)
paths = {'glean-swift': work/'Glean', 'sentry-cocoa':work/'Sentry', 'rust-components-swift':work/'FocusAppServices', 'SnapKit':corpus.parent/'deps/SnapKit', 'Fuzi':corpus.parent/'deps/Fuzi'}
for obj in objects.values():
    if obj['isa'] == 'XCRemoteSwiftPackageReference':
        name = obj['repositoryURL'].split('/')[-1]
        obj.clear()
        obj.update(isa='XCLocalSwiftPackageReference', relativePath=str(paths[name]))
# BlockzillaPackage's dependency uses the same local, pinned real SnapKit.
manifest = app / 'BlockzillaPackage/Package.swift'
manifest.write_text((corpus/'focus-ios/BlockzillaPackage/Package.swift').read_text().replace('.package(url: "https://github.com/SnapKit/SnapKit.git", from: "5.0.1")', '.package(path: "'+str(paths['SnapKit'])+'")'))
target = objects['E4BF2DD21BACE8CA00DA9D68']
# Keep the original app sources/resources/intent generation and real extensions.
# Replace network code-generation phases with the launch harness generated API.
target['buildPhases'] = [p for p in target['buildPhases'] if objects[p]['isa'] != 'PBXShellScriptBuildPhase']
generated = app/'Blockzilla/Generated'
generated.mkdir(exist_ok=True)
(generated/'Metrics.swift').write_text('import Glean\n')
(generated/'AppNimbus.swift').write_text('import FocusAppServices\ntypealias AppNimbus = FocusAppServices.AppNimbus\nextension String: Error {}\n')
# Add observation-only capture code. Upstream UIApplicationMain stays intact.
for index, name in enumerate(['FocusOracle.swift', 'FocusOracleBootstrap.m']):
    shutil.copy2(root/'Tools/focusoracle'/name, app/name)
    ref = f'F0C0500000000000000000{index:02X}'
    build = f'F0C0510000000000000000{index:02X}'
    objects[ref] = dict(isa='PBXFileReference', path=name, sourceTree='SOURCE_ROOT', lastKnownFileType='sourcecode.swift' if name.endswith('.swift') else 'sourcecode.c.objc')
    objects[build] = dict(isa='PBXBuildFile', fileRef=ref)
    objects['E4BF2DCF1BACE8CA00DA9D68']['files'].append(build)
    objects[objects[project['rootObject']]['mainGroup']]['children'].append(ref)
with pbx.open('wb') as f: plistlib.dump(project,f)
# Every existing upstream Swift/ObjC source remains byte-identical, including packages.
checks = {}
for src in (corpus/'focus-ios').rglob('*'):
    if src.suffix in ('.swift','.m','.h') and src.name != 'Package.swift':
        rel = src.relative_to(corpus/'focus-ios')
        if src.is_file():
            assert src.read_bytes() == (app/rel).read_bytes(), str(rel)
            checks[str(rel)] = hashlib.sha256(src.read_bytes()).hexdigest()
(work/'source-hashes.json').write_text(json.dumps(checks, indent=2, sort_keys=True)+'\n')
print(f'Prepared {app}: {len(checks)} upstream source hashes verified')
