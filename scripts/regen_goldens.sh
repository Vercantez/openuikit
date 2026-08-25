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
simulated=()
for f in fixtures/scenes/*.json; do
  route=$(python3 -c '
import json, sys
s = json.load(open(sys.argv[1]))
# "modal" scenes need REAL iOS (Simulator): Catalyst bridges pageSheet into
# an AppKit sheet window whose chrome UIKit cannot capture (spec v5).
print("sim" if s.get("modal") else ("window" if s.get("window") is True else "normal"))' "$f")
  case $route in
    sim) simulated+=("$f") ;;
    window) windowed+=("$f") ;;
    *) normal+=("$f") ;;
  esac
done

if (( ${#normal} > 0 )); then
  ./Tools/oracle/oracle render golden "${normal[@]}"
fi
if (( ${#windowed} > 0 )); then
  ./Tools/oracle2/run.sh render golden "${windowed[@]}"
fi
if (( ${#simulated} > 0 )); then
  ./scripts/render_sim_scenes.sh golden "${simulated[@]}"
fi
echo "goldens regenerated: ${#normal} via oracle (v1), ${#windowed} via oracle2 (window), ${#simulated} via SimScene (iOS Simulator)"
