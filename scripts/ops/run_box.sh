#!/usr/bin/env bash
# Operator runner: replace hand-typed SSM chains.
#
#   scripts/ops/run_box.sh [--dry-run] <arm64|x86> <verify|onboarding|cycle> [main-sha]
#
# Run from the operator Mac. Builds a git bundle, uploads it to the S3 prefix
# in env/contract.json, refuses to launch when the instance has any InProgress
# command (server-side --filters key=Status,value=InProgress), caps the SSM
# comment at 100 chars, waits with get-command-invocation, and prints the
# grep-extracted result lines (BUILD_OK, difftest pass/fail, GATE_B /
# GATE_ONBOARDING, RUNG_SCOREBOARD, CANNOT, STAGE).
set -euo pipefail

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
# shellcheck source=common.inc
. "$HERE/common.inc"
ROOT=$(ops_root)
CONTRACT=$ROOT/env/contract.json

DRY=0
if [ "${1:-}" = "--dry-run" ]; then
    DRY=1
    shift
fi

usage() {
    echo "usage: scripts/ops/run_box.sh [--dry-run] <arm64|x86> <verify|onboarding|cycle> [main-sha]" >&2
    exit 2
}

[ $# -ge 2 ] || usage
ARCH=$1
MODE=$2
SHA=${3:-}

case "$ARCH" in
    arm64|aarch64|x86|x86_64) ;;
    *) usage ;;
esac
case "$MODE" in
    verify|onboarding|cycle) ;;
    *) usage ;;
esac

HOST=$(ops_host_arch "$ARCH")
INSTANCE=$(ops_contract_get "$CONTRACT" "hosts.$HOST.instance_id")
TREE=$(ops_contract_get "$CONTRACT" "hosts.$HOST.tree")
BUCKET=$(ops_contract_get "$CONTRACT" transfer.s3_bucket)
PREFIX=$(ops_contract_get "$CONTRACT" transfer.s3_prefix)
REGION=$(ops_contract_get "$CONTRACT" transfer.s3_region)

if [ -z "$SHA" ]; then
    SHA=$(git -C "$ROOT" rev-parse HEAD)
fi

COMMENT=$(ops_comment "openuikit $ARCH $MODE $SHA")

bundle_key="$PREFIX/${SHA}.bundle"
bundle_s3="s3://$BUCKET/$bundle_key"

remote_cmd() {
    case "$MODE" in
        cycle)
            cat <<EOF
set -eu
cd $TREE
export OPENUIKIT_BUNDLE_URI='$bundle_s3'
export OPENUIKIT_SHA='$SHA'
export OPENUIKIT_S3_REGION='$REGION'
bash scripts/ops/x86_cycle.sh $TREE
EOF
            ;;
        verify)
            cat <<EOF
set -eu
cd $TREE
aws s3 cp '$bundle_s3' /tmp/openuikit-$SHA.bundle --region $REGION
git fetch /tmp/openuikit-$SHA.bundle refs/ops/bundle && [ "$(git rev-parse FETCH_HEAD)" = '$SHA' ]
git checkout --force '$SHA'
python3 scripts/env/prepare.py
sh machorun/scripts/build.sh
sh machorun/scripts/difftest.sh
echo BUILD_OK
if bash full/swiftui/build_focus_widget_guest.sh; then
  echo GATE_B_PASS
else
  echo GATE_B_FAIL
  exit 2
fi
EOF
            ;;
        onboarding)
            cat <<EOF
set -eu
cd $TREE
aws s3 cp '$bundle_s3' /tmp/openuikit-$SHA.bundle --region $REGION
git fetch /tmp/openuikit-$SHA.bundle refs/ops/bundle && [ "$(git rev-parse FETCH_HEAD)" = '$SHA' ]
git checkout --force '$SHA'
python3 scripts/env/prepare.py
if bash full/swiftui/build_focus_onboarding_guest.sh; then
  echo GATE_ONBOARDING_PASS
else
  echo GATE_ONBOARDING_FAIL
  exit 2
fi
EOF
            ;;
    esac
}

build_document() {
    OPS_COMMENT=$COMMENT OPS_INSTANCE=$INSTANCE OPS_COMMANDS=$(remote_cmd) python3 - <<'PY'
import json, os
print(json.dumps({
    "DocumentName": "AWS-RunShellScript",
    "Comment": os.environ["OPS_COMMENT"][:100],
    "InstanceIds": [os.environ["OPS_INSTANCE"]],
    "Parameters": {
        "commands": [os.environ["OPS_COMMANDS"]],
        "executionTimeout": ["14400"],
    },
}, indent=2))
PY
}

DOCUMENT=$(build_document)

if [ "$DRY" -eq 1 ]; then
    echo "$DOCUMENT"
    exit 0
fi

# Refuse to launch when the box has any InProgress command. Server-side
# filter only — never the unfiltered listing (that listing is how an
# InProgress command was missed).
in_progress=$(ops_aws ssm list-commands \
    --instance-id "$INSTANCE" \
    --filters key=Status,value=InProgress \
    --region "$REGION" \
    --output json)
python3 -c 'import json,sys; d=json.load(sys.stdin); cmds=d.get("Commands") or d.get("commands") or [];
sys.exit(0 if not cmds else 2)' <<<"$in_progress" || {
    echo "run_box: refusing to launch: $INSTANCE has InProgress command(s)" >&2
    echo "$in_progress" >&2
    exit 2
}

BUNDLE=${OPENUIKIT_BUNDLE_FILE:-$ROOT/scratch/openuikit-$SHA.bundle}
mkdir -p "$(dirname "$BUNDLE")"
# git bundle wants a ref, not a raw sha (git 2.53: rc=128 for a bare
# object id). Pin a temporary ref at the sha; the box fetches refs/ops/bundle.
git -C "$ROOT" update-ref refs/ops/bundle "$SHA"
git -C "$ROOT" bundle create "$BUNDLE" refs/ops/bundle
ops_aws s3 cp "$BUNDLE" "$bundle_s3" --region "$REGION"

cmd_id=$(ops_aws ssm send-command \
    --cli-input-json "$DOCUMENT" \
    --region "$REGION" \
    --query 'Command.CommandId' \
    --output text)

echo "run_box: sent $cmd_id comment=${#COMMENT} chars (cap 100) instance=$INSTANCE"

# Wait. Stub aws may return immediately.
status=Pending
out=""
tries=0
while [ "$tries" -lt 360 ]; do
    out=$(ops_aws ssm get-command-invocation \
        --command-id "$cmd_id" \
        --instance-id "$INSTANCE" \
        --region "$REGION" \
        --output json || true)
    status=$(python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("Status") or d.get("status") or "Unknown")' <<<"$out" 2>/dev/null || printf 'Unknown\n')
    case "$status" in
        Success|Failed|Cancelled|TimedOut) break ;;
    esac
    tries=$((tries + 1))
    sleep 5
done

python3 -c 'import json,sys; d=json.load(sys.stdin); sys.stdout.write(d.get("StandardOutputContent") or d.get("stdout") or "")' <<<"$out" \
    | ops_extract_result_lines
python3 -c 'import json,sys; d=json.load(sys.stdin); sys.stderr.write(d.get("StandardErrorContent") or d.get("stderr") or "")' <<<"$out" \
    | ops_extract_result_lines >&2 || true

[ "$status" = Success ]
