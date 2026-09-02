#!/bin/zsh
# Manage the temporary EC2 box used to build a Swift stdlib with
# SWIFT_OBJC_INTEROP=1 (see docs/OBJC_RUNTIME.md, Path B).
#
#   scripts/aws_build_box.sh status     # is it running, how long, rough cost
#   scripts/aws_build_box.sh ssh        # shell onto it
#   scripts/aws_build_box.sh terminate  # DESTROY it (do this when done!)
#
# The instance is tagged Name=openuikit-swift-build / Purpose=temporary-delete-me
# and carries two cost backstops: shutdown-behaviour=terminate, and a
# `shutdown -h +480` set at boot, so it cannot outlive ~8 hours even if
# everyone forgets about it.
set -e
STATE_DIR=/private/tmp/claude-501/-Users-miguelsalinas-uikit/8c75c08f-5c8e-42ec-9353-7334732ef488/scratchpad/aws
RATE=2.90   # approx c8g.16xlarge on-demand USD/hr in us-west-2, incl. EBS

find_instance() {
  aws ec2 describe-instances \
    --filters Name=tag:Name,Values=openuikit-swift-build \
              Name=instance-state-name,Values=running,pending \
    --query 'Reservations[].Instances[0].InstanceId' --output text 2>/dev/null | head -1
}

case "${1:-status}" in
  status)
    IID=$(find_instance)
    if [ -z "$IID" ] || [ "$IID" = "None" ]; then echo "no build box running"; exit 0; fi
    aws ec2 describe-instances --instance-ids "$IID" \
      --query 'Reservations[0].Instances[0].[InstanceId,InstanceType,State.Name,PublicIpAddress,LaunchTime]' \
      --output text
    LAUNCH=$(aws ec2 describe-instances --instance-ids "$IID" \
      --query 'Reservations[0].Instances[0].LaunchTime' --output text)
    HRS=$(python3 -c "
import datetime,sys
t=datetime.datetime.fromisoformat('$LAUNCH'.replace('Z','+00:00'))
print(round((datetime.datetime.now(datetime.timezone.utc)-t).total_seconds()/3600,2))")
    echo "uptime: ${HRS}h  ~\$$(python3 -c "print(round($HRS*$RATE,2))") so far"
    ;;
  ssh)
    IP=$(cat "$STATE_DIR/ip.txt")
    exec ssh -o StrictHostKeyChecking=no -o IdentitiesOnly=yes -i "$STATE_DIR/openuikit-build.pem" ubuntu@"$IP"
    ;;
  terminate)
    IID=$(find_instance)
    if [ -z "$IID" ] || [ "$IID" = "None" ]; then echo "nothing to terminate"; exit 0; fi
    aws ec2 terminate-instances --instance-ids "$IID" --query 'TerminatingInstances[0].CurrentState.Name' --output text
    echo "terminating $IID (EBS volume deletes with it)"
    ;;
  *)
    echo "usage: $0 {status|ssh|terminate}"; exit 1;;
esac
