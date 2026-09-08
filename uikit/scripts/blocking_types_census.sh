#!/bin/bash
# Re-run the existing dated instrument with frozen input contents.
# The shared Simplenote working tree has ignored probe package files. A clean
# detached copy preserves its pinned HEAD without modifying the shared checkout.
set -euo pipefail
cd "$(dirname "$0")/.."
python3 - "${1:?usage: blocking_types_census.sh /tmp/new-output}" <<'PY'
import pathlib, subprocess, sys, tempfile, shlex
out = pathlib.Path(sys.argv[1]).resolve()
if out.exists():
    raise SystemExit('Output must not exist')
original = pathlib.Path.home() / 'openuikit/scratch/ladder-corpus'
with tempfile.TemporaryDirectory(prefix='uikit-blocking-types-census-') as scratch:
    scratch = pathlib.Path(scratch)
    corpus = scratch / 'corpus'
    corpus.mkdir()
    for line in (original / 'PINS.txt').read_text().splitlines():
        name, url, sha, *_ = line.split('\t')
        destination = corpus / name
        if name == 'simplenote-ios':
            subprocess.run(['git', 'clone', '--quiet', '--shared', '--no-checkout', str(original/name), str(destination)], check=True)
            subprocess.run(['git', '-C', str(destination), 'checkout', '--quiet', '--detach', sha], check=True)
        else:
            destination.symlink_to(original/name, target_is_directory=True)
    (corpus/'PINS.txt').write_bytes((original/'PINS.txt').read_bytes())
    script = pathlib.Path('../full/ladder/remeasure-2026-09-16.sh').read_text()
    source = "root=pathlib.Path.home()/'openuikit/scratch'/folder"
    assert script.count(source) == 1
    script = script.replace(source, f"root=pathlib.Path({str(corpus)!r}) if stem=='corpus' else pathlib.Path.home()/'openuikit/scratch'/folder")
    source = 'corpus="$HOME/openuikit/scratch/ladder-corpus"'
    assert script.count(source) == 1
    script = script.replace(source, 'corpus='+shlex.quote(str(corpus)))
    # find normally does not follow a command-line symlink. -H gives this
    # path-relocated corpus the same traversal as the original real directory;
    # file inclusion, scoring rules and classifiers are otherwise unchanged.
    nib = pathlib.Path('../full/ladder/nibdeps.sh').read_text()
    assert nib.count('find "$C/$a"') == 1
    nib = nib.replace('find "$C/$a"', 'find -H "$C/$a"')
    nib_path = scratch/'nibdeps-paths.sh'
    nib_path.write_text(nib)
    source = 'zsh "$ladder/nibdeps.sh" "$corpus"'
    assert script.count(source) == 1
    script = script.replace(source, 'zsh '+shlex.quote(str(nib_path))+' "$corpus"')
    runner = scratch/'remeasure-paths.sh'
    runner.write_text(script)
    subprocess.run(['bash', str(runner), str(out)], check=True)
PY
