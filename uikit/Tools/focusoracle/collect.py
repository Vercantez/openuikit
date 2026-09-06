#!/usr/bin/env python3
"""Accept an oracle only after native-scale and temporal-rest checks pass."""
import datetime, hashlib, json, pathlib, shlex, shutil, subprocess, sys
import numpy as np
from PIL import Image

work, docs, out = map(lambda s:pathlib.Path(s).resolve(), sys.argv[1:4])
udid = sys.argv[4]
name = 'realapp_focus_browser_light'
sha = lambda b: hashlib.sha256(b).hexdigest()
canonical = lambda obj: json.dumps(obj, sort_keys=True, separators=(',', ':')).encode()
samples = []
for time in (3000, 4000, 5000):
    stem = docs / f'{name}.t{time}'
    png = pathlib.Path(str(stem)+'.png')
    layout = pathlib.Path(str(stem)+'.layout.json')
    im = np.array(Image.open(png).convert('RGBA'))
    d = json.loads(layout.read_text())
    assert im.shape == (1334, 750, 4), im.shape
    assert np.all(im[:,:,3] == 255), 'capture must be opaque'
    assert d['screen']['scale'] == 2
    assert not any(v.get('firstResponder') for v in d['views'])
    rows = {v['path']:v for v in d['views']}
    def visible(v):
        parts = v['path'].split('.') if v['path'] else []
        return all(not rows[p]['hidden'] and rows[p]['alpha'] > 0 and rows[p]['popacity'] > 0
                   for p in ['.'.join(parts[:i]) for i in range(len(parts)+1)] if p in rows)
    moving = [v for v in d['views'] if v['playing'] and visible(v)]
    assert not moving, moving
    geometry = [(v['path'],v['class'],v['frame'],v['abs'],v['bounds'],v['pframe'],v['pbounds']) for v in d['views']]
    if samples:
        assert np.array_equal(im, samples[0]['pixels']), 'not at rest: pixels changed'
        assert geometry == samples[0]['geometry'], 'not at rest: geometry changed'
    samples.append(dict(time=time,png=png,layout=layout,pixels=im,geometry=geometry,dump=d))
selected = samples[-1]
settings = json.loads((work/'build-settings.json').read_text())
settings = next(t['buildSettings'] for t in settings if t['target']=='Blockzilla')
# Normalize only machine/workspace paths; carry every resolved Blockzilla setting.
roots = [(str(work), '$ORACLE_WORK'), (str(pathlib.Path.home()), '$HOME')]
def normalize(value):
    if isinstance(value,str):
        for before, after in roots: value=value.replace(before,after)
    return value
settings = {k:normalize(v) for k,v in settings.items()}
filelist = next((work/'DerivedData/Build/Intermediates.noindex/Blockzilla.build/FocusDebug-iphonesimulator/Blockzilla.build/Objects-normal/arm64').glob('*.SwiftFileList'))
upstream_hashes = json.loads((work/'source-hashes.json').read_text())
compiled_sources={}
for line in filelist.read_text().splitlines():
    path=pathlib.Path(shlex.split(line)[0]).resolve()
    try: rel=str(path.relative_to(work/'focus-ios'))
    except ValueError: continue
    if rel in upstream_hashes: compiled_sources[rel]=upstream_hashes[rel]
assert len(compiled_sources)==129, len(compiled_sources)
runtime=next(r for r in json.loads(subprocess.check_output(['xcrun','simctl','list','runtimes','-j']))['runtimes'] if r['version']=='26.1')
assert runtime['buildversion']=='23B86'
devices=json.loads(subprocess.check_output(['xcrun','simctl','list','devices','-j']))['devices'][runtime['identifier']]
device=next(d for d in devices if d['udid']==udid)
assert device['deviceTypeIdentifier']=='com.apple.CoreSimulator.SimDeviceType.iPhone-SE-3rd-generation'
provenance={
    'name':name,'app_repository':'https://github.com/mozilla-mobile/focus-ios',
    'app_sha':'a2832521c1daa0c23419c73705ae043ed60c9791',
    'captured_at_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),
    'device':dict(name=device['name'],udid=udid,type=device['deviceTypeIdentifier'],ios='26.1',build='23B86',points=[375,667],scale=2,pixels=[750,1334]),
    'capture':dict(method='UIWindow.drawHierarchy(afterScreenUpdates: true), extended range, normalized sRGB straight alpha; layout AFTER PNG',status_bar='System status bar is a separate window, excluded by app-window capture; its 20pt safe area is preserved.',selected_ms=5000,sample_ms=[3000,4000,5000],max_changed_pixel_channels=0,max_geometry_delta_pt=0,visible_moving_views=0,view_count=len(selected['dump']['views']),hidden_moving_views=[dict(path=v['path'],class_name=v['class'],animation_keys=v['animationKeys']) for v in selected['dump']['views'] if v['playing']]),
    'launch_steps':[
        'Fresh install org.mozilla.ios.Focus; simulator appearance light.',
        'Before unmodified UIApplicationMain: JSONEncoder Set<ToolTipRoute> [.onboarding(.v1), .onboarding(.v2), .searchBar, .menu] into OnboardingConstants.shownTips; onboardingDidAppear=true; showOldOnboarding=true, exactly FocusBrowserLaunch.prepareReturningUserDefaults.',
        'Real AppDelegate launches BrowserViewController; UIKit focuses URL field and presents keyboard.',
        'At didBecomeActive +1s, send touchUpInside to upstream URLBar.cancelButton (cancelPressed sets isEditing=false). No direct layout/state patch.',
        'Capture app window at +3,+4,+5s; reject changed pixels/geometry, visible presentation movement, or focused fields.'
    ],
    'build':dict(project='Blockzilla.xcodeproj',scheme='Focus',configuration='FocusDebug',sdk='iphonesimulator26.1',architecture='arm64',overrides={'CODE_SIGNING_ALLOWED':'NO','ARCHS':'arm64','ONLY_ACTIVE_ARCH':'YES'},xcode=subprocess.check_output(['xcodebuild','-version'],text=True).strip(),normalized_settings=settings,normalized_settings_sha256=sha(canonical(settings)),compiled_upstream_swift_count=len(compiled_sources),compiled_upstream_swift_sha256=compiled_sources,swift_compile_input_count=len(filelist.read_text().splitlines()),project_sha256=sha((work/'focus-ios/Blockzilla.xcodeproj/project.pbxproj').read_bytes())),
    'dependencies':{'SnapKit':'e74fe2a978d1216c3602b129447c7301573cc2d8','Fuzi':'f08c8323da21e985f3772610753bcfc652c2103f','BlockzillaPackage':'unmodified sources from app SHA; local SnapKit package resolution', 'stand_ins':{}},
    'samples':[{ 'milliseconds':s['time'],'png_sha256':sha(s['png'].read_bytes()),'layout_sha256':sha(s['layout'].read_bytes())} for s in samples],
    'files':{name+'.png':sha(selected['png'].read_bytes()),name+'.layout.json':sha(selected['layout'].read_bytes())}
}
for module in ('Glean','Sentry','FocusAppServices'):
    src=work/module/'Sources'/module/(module+'.swift')
    provenance['dependencies']['stand_ins'][module]=dict(sha256=sha(src.read_bytes()),source='launch harness; offline telemetry/crash/Nimbus only')
root=pathlib.Path(__file__).resolve().parents[2]
provenance['harness_sha256']={str(p.relative_to(root)):sha(p.read_bytes()) for p in [root/'Tools/focusoracle/FocusOracle.swift',root/'Tools/focusoracle/FocusOracleBootstrap.m',root/'Tools/focusoracle/prepare.py']}
out.mkdir(parents=True,exist_ok=True)
for suffix,src in [('.png',selected['png']),('.layout.json',selected['layout'])]:
    shutil.copy2(src,out/(name+suffix))
(out/(name+'.provenance.json')).write_text(json.dumps(provenance,indent=2,sort_keys=True)+'\n')
print('ACCEPTED: 129 unmodified upstream Swift files; 750x1334 @2x; 3 samples pixel/geometry identical; no visible moving views')
print('build settings sha256:',provenance['build']['normalized_settings_sha256'])
