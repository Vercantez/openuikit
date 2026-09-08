#!/usr/bin/env python3
"""Reproduce stock Linux Swift #selector walls without modifying the source tree.

Run in the operator's uikit-linux container:
  python3 /work-route-a/uikit/Tools/ingest/route_a_objc_probe.py \
    --out /work-route-a/objc-probes --objc-root /work-route-a/objc4-linux
The output JSON carries every command, exit status, stdout, and stderr. Sources
are retained beside it. Runtime building is explicit (--build-runtime), uses a
copy under --out, and installs no packages. Never use /src or /work for --out.
"""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--objc-root', type=Path, required=True)
    parser.add_argument('--build-runtime', action='store_true')
    args = parser.parse_args()
    out = args.out.resolve()
    if out == Path('/src') or out == Path('/work') or any(p in out.parents for p in (Path('/src'), Path('/work'))):
        parser.error('the operator /src and /work trees are reserved')
    out.mkdir(parents=True, exist_ok=True)
    records = []

    def run(name, command, timeout=120, cwd=out):
        started = time.monotonic()
        try:
            p = subprocess.run([str(x) for x in command], cwd=cwd, capture_output=True, text=True, timeout=timeout)
            record = dict(name=name, command=[str(x) for x in command], cwd=str(cwd), exit=p.returncode, stdout=p.stdout, stderr=p.stderr)
        except subprocess.TimeoutExpired as error:
            def string(value):
                return value.decode(errors='replace') if isinstance(value, bytes) else (value or '')
            record = dict(name=name, command=[str(x) for x in command], cwd=str(cwd), exit='timeout', stdout=string(error.stdout), stderr=string(error.stderr))
        if name.endswith('exported-symbols'):
            raw = record['stdout']
            record['stdout_sha256'] = hashlib.sha256(raw.encode()).hexdigest()
            record['stdout_total_lines'] = len(raw.splitlines())
            record['stdout_filter'] = 'Only lines containing OBJC_CLASS_, OBJC_METACLASS_, or objc_ retained; other symbols irrelevant to ObjC interop.'
            record['stdout'] = ''.join(line + '\n' for line in raw.splitlines() if any(token in line for token in ('OBJC_CLASS_', 'OBJC_METACLASS_', 'objc_')))
        record['seconds'] = round(time.monotonic() - started, 3)
        records.append(record)
        (out / 'results.json').write_text(json.dumps(records, indent=2) + '\n')
        print(f"{name}: exit={record['exit']}", flush=True)
        return record

    def write(name, source):
        path = out / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(source)
        return path

    run('swift-version', ['swiftc', '--version'])
    run('clang-version', ['clang-18', '--version'])
    run('kernel', ['uname', '-a'])
    source = write('FoundationSelector.swift', '''import Foundation
final class Probe: NSObject {
    @objc func tapped() {}
    func action() { _ = #selector(tapped) }
}
''')
    flags = {
        'default': [],
        'experimental': ['-enable-experimental-feature', 'ObjCInterop'],
        'frontend': ['-Xfrontend', '-enable-objc-interop'],
        'both': ['-enable-experimental-feature', 'ObjCInterop', '-Xfrontend', '-enable-objc-interop'],
    }
    for name, arguments in flags.items():
        run('FoundationSelector-' + name, ['swiftc', '-typecheck', *arguments, source])

    local = write('LocalSelector.swift', '''public struct Selector { public init(_ value: String) {} }
public class NSObject {}
final class Probe: NSObject {
    @objc func tapped() {}
    func action() { _ = #selector(tapped) }
}
''')
    for name in ('default', 'experimental', 'frontend'):
        run('local-shim-' + name, ['swiftc', '-typecheck', *flags[name], local])

    shim = out / 'swift-shim'
    shim.mkdir(exist_ok=True)
    foundation = write('swift-shim/Foundation.swift', 'open class NSObject { public init() {} }\n')
    selector = write('swift-shim/ObjectiveC.swift', 'public struct Selector { public let name: String; public init(_ value: String) { name = value } }\n')
    run('emit-Swift-Foundation-shim', ['swiftc', '-emit-module', '-module-name', 'Foundation', foundation, '-emit-module-path', shim / 'Foundation.swiftmodule'])
    run('emit-Swift-ObjectiveC-shim', ['swiftc', '-emit-module', '-module-name', 'ObjectiveC', selector, '-emit-module-path', shim / 'ObjectiveC.swiftmodule'])
    imported = write('ImportedSelector.swift', '''import Foundation
import ObjectiveC
final class Probe: NSObject {
    @objc func tapped() {}
    func action() -> Selector { #selector(tapped) }
}
''')
    for name, arguments in flags.items():
        run('imported-shim-' + name, ['swiftc', '-typecheck', '-I', shim, *arguments, imported])
    run('imported-shim-frontend-object', ['swiftc', '-c', '-I', shim, *flags['frontend'], imported, '-o', out / 'ImportedSelector.o'])
    run('imported-shim-selector-SIL', ['swiftc', '-emit-silgen', '-I', shim, *flags['frontend'], imported, '-o', out / 'ImportedSelector.sil'])
    run('imported-shim-selector-IR', ['swiftc', '-emit-ir', '-I', shim, *flags['frontend'], imported, '-o', out / 'ImportedSelector.ll'])
    objc_only = out / 'objc-only'
    objc_only.mkdir(exist_ok=True)
    shutil.copy2(shim / 'ObjectiveC.swiftmodule', objc_only / 'ObjectiveC.swiftmodule')
    run('stock-Foundation-ObjectiveC-shim-typecheck', ['swiftc', '-typecheck', '-I', objc_only, *flags['frontend'], imported])
    run('stock-Foundation-ObjectiveC-shim-object', ['swiftc', '-c', '-I', objc_only, *flags['frontend'], imported, '-o', out / 'StockFoundationSelector.o'])
    run('imported-shim-frontend-undefined', ['nm', '-u', out / 'ImportedSelector.o'])
    uikit = args.objc_root.parent / 'uikit'
    release = uikit / '.build/aarch64-unknown-linux-gnu/release'
    if (release / 'Modules/OpenUIKit.swiftmodule').exists():
        openui = write('OpenUIKitSelector.swift', '''import Foundation
import OpenUIKit
@MainActor final class Probe: UIViewController {
    @objc func tapped() {}
    func wire(_ button: UIButton) { button.addTarget(self, action: #selector(tapped), for: .touchUpInside) }
}
''')
        module_flags = ['-I', release / 'Modules', '-I', uikit / 'Sources/CQuartz/include', '-I', release / 'CSTBTrueType.build', '-I', release / 'CPortableIO.build']
        for name, arguments in flags.items():
            run('OpenUIKitSelector-' + name, ['swiftc', '-typecheck', *module_flags, *arguments, openui])
        with_shim = write('OpenUIKitSelectorWithShim.swift', 'import ObjectiveC\n' + openui.read_text())
        run('OpenUIKitSelector-ObjectiveC-shim', ['swiftc', '-typecheck', *module_flags, '-I', objc_only, *flags['frontend'], with_shim])
    plain = write('Plain.swift', 'public class Plain { public init() {} }\n')
    run('plain-Swift-interop-object', ['swiftc', '-c', '-parse-as-library', '-Xfrontend', '-enable-objc-interop', plain, '-o', out / 'Plain.o'])
    run('plain-Swift-interop-sections', ['readelf', '-SW', out / 'Plain.o'])
    run('plain-Swift-interop-undefined', ['nm', '-u', out / 'Plain.o'])
    swiftc = Path(shutil.which('swiftc')).resolve()
    swiftlib = swiftc.parent.parent / 'lib/swift/linux/libswiftCore.so'
    run('stock-swiftCore-exported-symbols', ['nm', '-D', '--defined-only', swiftlib])

    if args.build_runtime:
        runtime = out / 'objc4-linux'
        if not runtime.exists():
            shutil.copytree(args.objc_root, runtime, ignore=shutil.ignore_patterns('.git', 'build'))
        if shutil.which('rsync'):
            result = run('objc4-patch', ['bash', runtime / 'scripts/apply-patches.sh'])
        else:
            patched = runtime / 'build/objc4-src'
            shutil.copytree(runtime / 'vendor/objc4', patched, dirs_exist_ok=True)
            result = {'exit': 0}
            for patch in sorted((runtime / 'patches').glob('*.patch')):
                result = run('objc4-patch-' + patch.name, ['patch', '-p1', '-d', patched, '--forward', '--silent', '-i', patch])
                if result['exit'] != 0:
                    break
        if result['exit'] == 0:
            build = runtime / 'build/linux-aarch64'
            result = run('objc4-configure', ['cmake', '-S', runtime, '-B', build, '-G', 'Ninja', '-DCMAKE_BUILD_TYPE=Release', '-DCMAKE_C_COMPILER=clang-18', '-DCMAKE_CXX_COMPILER=clang++-18', '-DCMAKE_C_FLAGS=-I' + str(swiftlib.parent.parent / 'Block'), '-DCMAKE_CXX_FLAGS=-I' + str(swiftlib.parent.parent / 'Block'), '-DCMAKE_SHARED_LINKER_FLAGS=-L' + str(swiftlib.parent) + ' -Wl,-rpath,' + str(swiftlib.parent)])
            if result['exit'] == 0:
                result = run('objc4-build', ['cmake', '--build', build, '--target', 'objc', '--parallel', '2'], timeout=600)
            if result['exit'] == 0:
                run('plain-Swift-link-objc4', ['swiftc', '-Xfrontend', '-enable-objc-interop', plain, '-L', build, '-lobjc', '-o', out / 'plain-objc4'])
                run('stock-Foundation-ObjectiveC-shim-link-objc4', ['swiftc', '-I', objc_only, '-Xfrontend', '-enable-objc-interop', imported, '-L', build, '-lobjc', '-o', out / 'stock-shim-objc4'])
                run('objc4-exported-symbols', ['nm', '-D', '--defined-only', build / 'libobjc.so'])
                objc_source = write('objc4_dispatch.m', '''#include <objc/NSObject.h>
#include <objc/runtime.h>
#include <objc/message.h>
#include <stdio.h>
@interface RouteAProbe: NSObject
- (void)tapped;
@end
@implementation RouteAProbe
- (void)tapped { puts("OBJC4_TARGET_ACTION_FIRED"); }
@end
int main(void) {
    id target = ((id(*)(id,SEL))objc_msgSend)((id)objc_getClass("RouteAProbe"), sel_registerName("new"));
    ((void(*)(id,SEL))objc_msgSend)(target, sel_registerName("tapped"));
    ((void(*)(id,SEL))objc_msgSend)(target, sel_registerName("release"));
    return 0;
}
''')
                compiled = run('objc4-C-target-action-compile', ['clang-18', '-fobjc-runtime=macosx-10.15', '-I', build / 'include', objc_source, '-L', build, '-lobjc', '-Wl,-rpath,' + str(build), '-o', out / 'objc4_dispatch'])
                if compiled['exit'] == 0:
                    run('objc4-C-target-action-run', [out / 'objc4_dispatch'])
                write('clang-shim/ObjCRoot/module.modulemap', 'module ObjCRoot { header "ObjCRoot.h" export * }\n')
                write('clang-shim/ObjCRoot/ObjCRoot.h', '#include <objc/NSObject.h>\n')
                actual_root = write('ObjC4RootSelector.swift', '''import Foundation
import ObjCRoot
import ObjectiveC
final class Probe: ObjCRoot.NSObject {
    @objc func tapped() {}
    func action() -> Selector { #selector(tapped) }
}
''')
                clang_root_flags = ['-Xfrontend', '-enable-objc-interop', '-I', out / 'clang-shim', '-I', build / 'include', '-Xcc', '-fobjc-runtime=macosx-10.15']
                run('objc4-NSObject-ObjectiveC-shim-typecheck', ['swiftc', '-typecheck', *clang_root_flags, '-I', objc_only, actual_root])
                run('objc4-NSObject-ObjectiveC-shim-link', ['swiftc', *clang_root_flags, '-I', objc_only, actual_root, '-L', build, '-lobjc', '-o', out / 'clang-root-shim'])
                allocated = write('ObjC4RootAllocated.swift', actual_root.read_text() + '\nlet target = Probe()!\ntarget.tapped()\n')
                alloc_result = run('objc4-NSObject-allocated-link', ['swiftc', *clang_root_flags, '-I', objc_only, allocated, '-L', build, '-lobjc', '-Xlinker', '-rpath', '-Xlinker', build, '-o', out / 'clang-root-allocated'])
                if alloc_result['exit'] == 0:
                    run('objc4-NSObject-allocated-run', [out / 'clang-root-allocated'])
                pointer_shim = out / 'pointer-shim'
                pointer_shim.mkdir(exist_ok=True)
                pointer_source = write('pointer-shim/ObjectiveC.swift', '@frozen public struct Selector { public var ptr: OpaquePointer }\n')
                run('emit-pointer-ObjectiveC-shim', ['swiftc', '-emit-module', '-module-name', 'ObjectiveC', pointer_source, '-emit-module-path', pointer_shim / 'ObjectiveC.swiftmodule'])
                write('clang-shim/ObjCRoot/ObjCRoot.h', '#include <objc/NSObject.h>\nvoid route_send(void *target, void *selector);\n')
                sender_c = write('route_send.m', '#include <objc/message.h>\nvoid route_send(void *target, void *selector) { ((void(*)(id,SEL))objc_msgSend)((id)target, (SEL)selector); }\n')
                run('objc4-route-send-object', ['clang-18', '-c', '-fobjc-runtime=macosx-10.15', '-I', build / 'include', sender_c, '-o', out / 'route_send.o'])
                action_source = write('ObjC4TargetAction.swift', '''import Foundation
import ObjCRoot
import ObjectiveC
final class Probe: ObjCRoot.NSObject {
    @objc func tapped() { print("SWIFT_OBJC4_TARGET_ACTION_FIRED") }
}
let target = Probe()!
let action = #selector(Probe.tapped)
route_send(Unmanaged.passUnretained(target).toOpaque(), UnsafeMutableRawPointer(action.ptr))
''')
                action_result = run('objc4-raw-selector-target-action-link', ['swiftc', *clang_root_flags, '-I', pointer_shim, action_source, out / 'route_send.o', '-L', build, '-lobjc', '-Xlinker', '-rpath', '-Xlinker', build, '-o', out / 'swift-objc4-target-action'])
                if action_result['exit'] == 0:
                    run('objc4-raw-selector-target-action-run', [out / 'swift-objc4-target-action'])

    print(out / 'results.json', flush=True)


if __name__ == '__main__':
    main()
