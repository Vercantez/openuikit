#!/bin/bash
# Tear down the build box created by scripts/provision_box.sh.
#
# SAFETY, and this is the whole reason the script exists rather than a
# remembered command line: THIS AWS ACCOUNT CARRIES THE USER'S PRODUCTION
# INFRASTRUCTURE (camel-api-production, camelai web, ...). Every destructive
# call below names an EXACT id read from .work-concurrency/state.env. There is
# no --filters anywhere in this file and there must never be: a filter that
# matches more than you meant is indistinguishable from one that matched exactly
# what you meant, right up until it isn't.
#
#   scripts/teardown_box.sh            terminate, then delete SG and key
#   scripts/teardown_box.sh --check    report what exists, change nothing
#
# It is safe to re-run: each step tolerates the resource already being gone,
# because the common case for a second run is "the first one half-failed".
set -uo pipefail

W=${W:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/.work-concurrency}
CHECK=0
[ "${1:-}" = "--check" ] && CHECK=1

[ -f "$W/state.env" ] || { echo "no $W/state.env -- nothing recorded to tear down." >&2; exit 1; }
. "$W/state.env"

for v in REGION INSTANCE_ID SECURITY_GROUP KEY_NAME; do
  [ -n "${!v:-}" ] || { echo "state.env is missing $v; refusing to guess." >&2; exit 1; }
done

# Report state before doing anything. A teardown that does not first say what it
# found has no way to tell "already clean" from "acted on the wrong thing".
inst=$(aws ec2 describe-instances --region "$REGION" --instance-ids "$INSTANCE_ID" \
        --query 'Reservations[0].Instances[0].State.Name' --output text 2>/dev/null || echo absent)
[ "$inst" = "None" ] && inst=absent
sg=$(aws ec2 describe-security-groups --region "$REGION" --group-ids "$SECURITY_GROUP" \
        --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null || echo absent)
key=$(aws ec2 describe-key-pairs --region "$REGION" --key-names "$KEY_NAME" \
        --query 'KeyPairs[0].KeyName' --output text 2>/dev/null || echo absent)

echo "region:   $REGION"
echo "instance: $INSTANCE_ID   [$inst]"
echo "sec grp:  $SECURITY_GROUP   [$sg]"
echo "key pair: $KEY_NAME   [$key]"
[ "$CHECK" = 1 ] && exit 0

if [ "$inst" != absent ] && [ "$inst" != terminated ]; then
  echo "terminating $INSTANCE_ID ..."
  aws ec2 terminate-instances --region "$REGION" --instance-ids "$INSTANCE_ID" \
    --query 'TerminatingInstances[0].CurrentState.Name' --output text
  aws ec2 wait instance-terminated --region "$REGION" --instance-ids "$INSTANCE_ID"
  echo "terminated."
fi

# The SG cannot be deleted until the ENI is released, which lags termination.
if [ "$sg" != absent ]; then
  for i in 1 2 3 4 5 6; do
    aws ec2 delete-security-group --region "$REGION" --group-id "$SECURITY_GROUP" 2>/dev/null && \
      { echo "deleted security group $SECURITY_GROUP"; break; }
    [ "$i" = 6 ] && echo "WARNING: could not delete $SECURITY_GROUP -- delete it by hand." >&2
    sleep 10
  done
fi

[ "$key" != absent ] && aws ec2 delete-key-pair --region "$REGION" --key-name "$KEY_NAME" \
  && echo "deleted key pair $KEY_NAME"

rm -f "$W/key.pem"
mv "$W/state.env" "$W/state.env.torndown-$(date -u +%Y%m%dT%H%M%SZ)"
echo "state.env archived; provision_box.sh will create a fresh box next run."
