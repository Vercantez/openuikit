#!/bin/zsh
# Regenerates ALL goldens from the real-UIKit oracles:
#   - normal scenes  -> Tools/oracle  (v1, offscreen layer.render)
#   - "window": true -> Tools/oracle2 (v2, real window + drawHierarchy;
#                       its app window flashes briefly on screen)
# Never mix: v2's compositing path shifts flat colors by 1-2 counts vs v1,
# so regenerating a normal scene with v2 would add avoidable noise.
set -e
cd "$(dirname "$0")/.."

[[ -x Tools/oracle/oracle ]] || ./scripts/build_oracle.sh
[[ -x Tools/oracle2/Oracle2.app/Contents/MacOS/oracle2 ]] || ./scripts/build_oracle2.sh

normal=()
windowed=()
for f in fixtures/scenes/*.json; do
  if python3 -c 'import json,sys; sys.exit(0 if json.load(open(sys.argv[1])).get("window") is True else 1)' "$f"; then
    windowed+=("$f")
  else
    normal+=("$f")
  fi
done

if (( ${#normal} > 0 )); then
  ./Tools/oracle/oracle render golden "${normal[@]}"
fi
if (( ${#windowed} > 0 )); then
  ./Tools/oracle2/run.sh render golden "${windowed[@]}"
fi
echo "goldens regenerated: ${#normal} via oracle (v1), ${#windowed} via oracle2 (window)"
