#!/bin/bash
# enumerate_staging.sh -- find every place a BUILT BINARY gets copied into a
# tree that something else later loads, and say which gate (if any) looks at it.
#
# WHY THIS EXISTS. On 2026-08-27 a libswiftcompat.dylib whose pthread_main_np
# returned a constant 1 was sitting in ~/swiftcore-macho/artifacts/concurrency/,
# in exactly the layout machorun's stage_swiftcore.sh reads, one command from
# being installed. Every freshness check passed, because the file was NEWER than
# what was deployed rather than older -- check_stale compares an artefact against
# its source, and this artefact was perfectly current. It was the DEPLOYED copy
# that was old, and better.
#
# That is a category no gate covers, and the reason is scope rather than logic:
# every gate we have grades a list someone happened to write down. So this counts
# the list.
#
# WHAT COUNTS AS A STAGING SITE, stated so the number means something:
# a script that copies a file matching *.dylib / *.so / *.a / *.tbd into a
# directory other than a build output dir. Name is irrelevant -- half of these
# are not called "stage" -- so the search is by CONTENT.
#
# IT PRINTS ITS DENOMINATOR. A sweep reporting "N found" without saying how many
# things it examined is indistinguishable from one that examined nothing; that
# rule was earned twice in one evening (a zsh string comparison that errored so a
# loop body never ran, and a refusal made unreachable by `set -o pipefail`).
set -uo pipefail

ROOTS=${ROOTS:-"$HOME/machorun $HOME/swiftcore-macho $HOME/uikit $HOME/quartz $HOME/swift-macho-linux"}

# Exclusions, named rather than silent. Each one shrinks the denominator and the
# reader is entitled to know by how much and why.
#   .git            not source
#   .claude/worktrees  agent worktrees; byte-copies of the main tree, would
#                   multiply every finding by ~14 and change no conclusion
#   vendor/, third-party libdispatch xcodescripts: upstream's own install
#                   scripts, not ours, and not run by us
EXCL='/\.git/|/\.claude/worktrees/|/vendor/|/libdispatch/xcodescripts/|/node_modules/|/build/survey/'

# A copy of a built binary. `install-name:` is excluded: it is a .tbd YAML key,
# not install(1), and matching it inflated the first run by 17 of 46 sites.
COPY_RE='^[^#]*(\bcp[[:space:]]|\binstall[[:space:]]+-|\brsync[[:space:]])[^|]*\.(dylib|so|a|tbd)([[:space:]"'"'"']|$)'

scanned=0; skipped=0; hits=0
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
: > "$tmp/sites.txt"

for root in $ROOTS; do
  [ -d "$root" ] || continue
  while IFS= read -r f; do
    if printf '%s' "$f" | grep -qE "$EXCL"; then skipped=$((skipped+1)); continue; fi
    scanned=$((scanned+1))
    # A copy of a binary artefact. install(1) counts; so does rsync.
    # `install-name:` is a .tbd YAML key, not the install(1) command. Matching
    # it inflated this sweep by 17 of 46 sites on the first run -- a precision
    # failure reads as a bigger finding, which is the flattering direction.
    if grep -nE "$COPY_RE" "$f" >/dev/null 2>&1; then
      hits=$((hits+1))
      grep -nE "$COPY_RE" "$f" \
        | sed "s|^|${f#$HOME/}:|" >> "$tmp/sites.txt"
    fi
  done < <(find "$root" -name '*.sh' -type f 2>/dev/null)
done

echo "=============================================================="
echo "DENOMINATOR"
echo "  roots examined:       $(echo $ROOTS | wc -w | tr -d ' ')"
echo "  shell scripts scanned:$scanned"
echo "  skipped by exclusion: $skipped   ($EXCL)"
echo "  scripts that copy a built binary: $hits"
echo "  individual copy sites:            $(wc -l < "$tmp/sites.txt" | tr -d ' ')"
echo "=============================================================="
echo
echo "COPY SITES, by script:"
cut -d: -f1 "$tmp/sites.txt" | sort -u | while read -r s; do
  echo "  $s  ($(grep -c "^$s:" "$tmp/sites.txt") site(s))"
done
echo
echo "RAW SITES (script:line: statement):"
sed 's/^/  /' "$tmp/sites.txt" | cut -c1-160

# ============================================================================
# PART 2: the destination trees, DISCOVERED rather than listed.
#
# Part 1 finds the copies. This finds the places they land -- any directory on
# disk holding two or more Darwin dylibs -- and says which gate looks at it.
# Discovery matters more here than in part 1: every gate we have grades a
# hardcoded list, and a tree nobody wrote down is exactly the one that rots.
# ============================================================================
echo
echo "=============================================================="
echo "PART 2: DESTINATION TREES ON DISK"
echo "=============================================================="

# machorun's check_stale.sh is the only freshness gate in the project. Read the
# paths it actually grades out of the script rather than restating them here --
# a copy of its list would drift from it, which is this whole document's subject.
CS="$HOME/machorun/scripts/check_stale.sh"
# The character class MUST include uppercase: libSystem.B.dylib and libobjc.A.dylib
# both have it, and a lowercase-only class silently reported 2 paths where the
# script grades 6. Third bad-regex undercount of the evening; they all read as
# smaller, tidier numbers than the truth.
covered=$(grep -oE '"[A-Za-z0-9/._+-]+\.dylib\|' "$CS" 2>/dev/null | tr -d '"|' | sort -u)
ncov=$(printf '%s\n' "$covered" | grep -c . )
echo "  check_stale.sh grades $ncov path(s), all under machorun/"
echo

trees=$(for root in $ROOTS; do
          [ -d "$root" ] || continue
          find "$root" -name '*.dylib' -type f 2>/dev/null \
            | grep -vE "$EXCL" | xargs -n1 dirname 2>/dev/null
        done | sort | uniq -c | awk '$1>1 {print $1"\t"$2}' | sort -k2)

echo "  trees holding 2+ dylibs: $(printf '%s\n' "$trees" | grep -c .)"
echo
printf "  %-58s %5s  %s\n" "TREE" "N" "GATE THAT LOOKS AT IT"
printf '  %s\n' "----------------------------------------------------------------------------------"
printf '%s\n' "$trees" | while IFS=$'\t' read -r n d; do
  [ -n "$d" ] || continue
  rel=${d#$HOME/}
  case "$rel" in
    machorun/darwin/usr/lib*) g="check_stale + gen_tbd CHECK 4 + objc44/swift_gate" ;;
    machorun/build/*)         g="(build output, not staged)" ;;
    swiftcore-macho/artifacts*) g="build_compat.sh (the SHIM only; nothing checks libswiftCore)" ;;
    swift-macho-linux/scratch/mrroot*) g="require_fresh_root.sh, at each consumer" ;;
    *)                        g="*** NONE ***" ;;
  esac
  printf "  %-58s %5s  %s\n" "$rel" "$n" "$g"
done
