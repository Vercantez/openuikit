#!/usr/bin/env bash
# Wrapper so test_phase2.sh can `bash scripts/x86/test_no_existence_reuse.sh`.
# Also proves the scanner fails a planted existence-reuse skip.
set -euo pipefail
ROOT=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)

python3 "$ROOT/scripts/x86/test_no_existence_reuse.py"

PLANT=$(mktemp -d /tmp/existence-reuse-plant.XXXXXX)
cleanup() { rm -rf "$PLANT"; }
trap cleanup EXIT
cat > "$PLANT/bad.inc" <<'EOF'
try_product() {
    local dest=$1
    if [ -f "$dest" ] && phase2_is_x86_macho "$dest"; then
        return 0
    fi
    clang-18 -c src.c -o "$dest"
}
EOF
if python3 - <<PY
from pathlib import Path
import importlib.util, sys
spec = importlib.util.spec_from_file_location(
    "scan", "$ROOT/scripts/x86/test_no_existence_reuse.py"
)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
hits = mod.scan_file(Path("$PLANT/bad.inc"))
sys.exit(0 if hits else 1)
PY
then
    echo "PASS: scanner names a planted existence-reuse skip"
else
    echo "FAIL: scanner missed planted if [ -f ] && phase2_is_x86_macho; return 0" >&2
    exit 1
fi
