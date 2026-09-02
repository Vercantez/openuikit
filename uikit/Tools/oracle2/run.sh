#!/bin/zsh
# Oracle v2 CLI: real-window UIKit renderer for scenes with "window": true.
#   Tools/oracle2/run.sh render <outdir> <scene.json>...
# NOTE: the app window flashes briefly on screen — that is the point
# (render-server compositing). Build first: ./scripts/build_oracle2.sh
BIN="$(dirname "$0")/Oracle2.app/Contents/MacOS/oracle2"
if [[ ! -x "$BIN" ]]; then
  echo "oracle2 not built — run ./scripts/build_oracle2.sh" >&2
  exit 1
fi
exec "$BIN" "$@"
