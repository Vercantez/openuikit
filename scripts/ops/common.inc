# scripts/ops/common.inc -- sourced by run_box.sh / x86_cycle.sh / premerge.sh
if [ -n "${OPENUIKIT_OPS_COMMON_INC:-}" ]; then
    return 0 2>/dev/null || exit 0
fi
OPENUIKIT_OPS_COMMON_INC=1

ops_root() {
    CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P
}

ops_aws() {
    if [ -n "${OPENUIKIT_AWS:-}" ]; then
        "$OPENUIKIT_AWS" "$@"
    else
        aws "$@"
    fi
}

ops_gh() {
    if [ -n "${OPENUIKIT_GH:-}" ]; then
        "$OPENUIKIT_GH" "$@"
    else
        gh "$@"
    fi
}

ops_contract_get() {
    python3 - "$1" "$2" <<'PY'
import json, sys
cur = json.load(open(sys.argv[1], encoding="utf-8"))
for part in sys.argv[2].split("."):
    if isinstance(cur, list):
        cur = cur[int(part)]
    else:
        cur = cur[part]
if isinstance(cur, (dict, list)):
    json.dump(cur, sys.stdout)
    sys.stdout.write("\n")
else:
    print(cur)
PY
}

ops_host_arch() {
    case "$1" in
        arm64|aarch64) printf 'ec2-aarch64\n' ;;
        x86|x86_64) printf 'ec2-x86_64\n' ;;
        *) printf 'ops: unknown arch %s (arm64|x86)\n' "$1" >&2; return 2 ;;
    esac
}

ops_comment() {
    # SSM Comment max 100 chars.
    python3 -c 'import sys; s=sys.argv[1]; sys.stdout.write(s[:100])' "$1"
}

ops_extract_result_lines() {
    grep -E \
        'BUILD_OK|BUILD_FAIL|TBD_CHECK_|^!!|run_linux rc=|build_full rc=|^build_full:|checked out|GATE_B|GATE_ONBOARDING|RUNG_SCOREBOARD|STAGE |CANNOT_|pass [0-9]+ fail|difftest|PREMERGE |GUEST SCOREBOARD' \
        || true
}
