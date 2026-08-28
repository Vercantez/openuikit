#!/bin/zsh
# Nib dependence per app: how many of an app's .swift files are BOUND to a xib
# or storyboard, which is the thing that matters -- not how many .xib files sit
# in the tree. An app can ship 160 xibs and be code-based in the part you care
# about, or ship 3 and load its whole UI from them (measured: eidolon).
#
#   ./nibdeps.sh <corpus-dir> > nibdeps.tsv
#
# Columns: app <tab> #.swift containing @IBOutlet <tab> #.swift total
# The denominator is the Tests-INCLUDED walk, matching score_ladder.py's other
# per-file ratios.
set -u
C="${1:?usage: nibdeps.sh <corpus-dir>}"
for a in $(ls "$C"); do
  [ -d "$C/$a/.git" ] || continue
  ib=$(grep -rl '@IBOutlet' --include='*.swift' "$C/$a" 2>/dev/null | wc -l | tr -d ' ')
  sw=$(find "$C/$a" -name '*.swift' -not -path '*/.git/*' -not -path '*/Pods/*' \
         -not -path '*/Carthage/*' | wc -l | tr -d ' ')
  printf '%s\t%s\t%s\n' "$a" "$ib" "$sw"
done
