#!/bin/bash
# Run from uikit/. No fetch/clone; fresh output only. Tools are unchanged.
set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1
out=${1:?usage: bash ../full/ladder/remeasure-2026-09-16.sh /tmp/NEW-OUTPUT}
[[ -f docs/ORACLE_FLOW.md && -d ../full/ladder ]] || { echo 'Run from uikit/' >&2; exit 1; }
[[ ! -e "$out" ]] || { echo 'Output must not exist' >&2; exit 1; }
mkdir -p "$out"
python3 - "$out" <<'PY'
import pathlib,re,subprocess,sys
out=pathlib.Path(sys.argv[1]);base=pathlib.Path('../full/ladder')
sdk=pathlib.Path(subprocess.check_output(['xcrun','--sdk','macosx','--show-sdk-path'],text=True).strip())/'System/iOSSupport/System/Library/Frameworks/UIKit.framework/Headers'
def scan(files,pat):return sorted({m.group(1) for p in files for m in re.finditer(pat,p.read_text(errors='ignore'),re.M)})
for stem,names in [('uikit_sdk_types',scan(sdk.rglob('*.h'),r'^@(?:interface|protocol)\s+([A-Za-z_][A-Za-z0-9_]*)')),('openuikit_types',scan(pathlib.Path('Sources/OpenUIKit').rglob('*.swift'),r'^\s*(?:public|open)\s+(?:final\s+)?(?:class|struct|enum|protocol|typealias)\s+((?:UI|NS|CA)[A-Za-z0-9_]*)'))]:
 (out/f'{stem}-2026-09-16.txt').write_text('\n'.join(names)+'\n');print(stem,len(names))
for stem,folder in [('corpus','ladder-corpus'),('dep','ladder-deps')]:
 root=pathlib.Path.home()/'openuikit/scratch'/folder
 frozen=base/f'{stem}-pins-2026-09-14.tsv'
 assert (root/'PINS.txt').read_bytes()==frozen.read_bytes()
 for row in frozen.read_text().splitlines():
  name,url,sha,*_=row.split('\t')
  assert subprocess.check_output(['git','-C',str(root/name),'rev-parse','HEAD'],text=True).strip()==sha,name
 (out/f'{stem}-pins-2026-09-16.tsv').write_bytes(frozen.read_bytes())
 print(stem,'verified',len(frozen.read_text().splitlines()))
PY
ladder=../full/ladder
corpus="$HOME/openuikit/scratch/ladder-corpus"
deps="$HOME/openuikit/scratch/ladder-deps"
sdk="$out/uikit_sdk_types-2026-09-16.txt"
ours="$out/openuikit_types-2026-09-16.txt"
python3 "$ladder/ladder_census.py" "$corpus" "$sdk" "$ours" "$out/ladder-census-2026-09-16.json"
python3 "$ladder/union_and_imports.py" "$corpus" "$sdk" "$ours" "$out/uikit-union-2026-09-16.json" "$out/imports-full-2026-09-16.json"
zsh "$ladder/nibdeps.sh" "$corpus" > "$out/nibdeps-2026-09-16.tsv"
python3 "$ladder/deps.py" "$corpus" "$out/imports-full-2026-09-16.json" "$out/deps-2026-09-16.json"
python3 "$ladder/ladder_census.py" "$deps" "$sdk" "$ours" "$out/deps-census-2026-09-16.json" 'Demo,Demos,demo,Example,Examples,example,examples,Sample,Samples,TestSamples,Documentation,Playground,Playgrounds,fastlane,Scripts,watchOS Example,Test,Tests,IntegrationTests,UITests,Benchmarks'
python3 "$ladder/dep_class.py" "$out/deps-census-2026-09-16.json" "$out/deps-2026-09-16.json" "$out/dep-classes-2026-09-16.json" "$out/ladder-census-2026-09-16.json"
python3 "$ladder/classify_gaps.py" "$out/ladder-census-2026-09-16.json" "$out/uikit-union-2026-09-16.json" "$out/gap-classes-2026-09-16.json"
python3 "$ladder/model_supply.py" "$out/ladder-census-2026-09-16.json" "$out/model-supply-2026-09-16.json"
python3 "$ladder/score_ladder.py" "$out/ladder-census-2026-09-16.json" "$out/imports-full-2026-09-16.json" "$out/nibdeps-2026-09-16.tsv" "$out/dep-classes-2026-09-16.json" "$out/ladder-scores-2026-09-16.json"
python3 "$ladder/ledger_supply.py" ../full "$out/ledger-supply-2026-09-16.json"
python3 "$ladder/audit-2026-09-16.py" "$out"
