#!/bin/zsh
# Manage the temporary Graviton4 box building the Swift stdlib.
#   build_box.sh status|ssh|terminate
set -e
K=/private/tmp/claude-501/-Users-miguelsalinas-uikit/8c75c08f-5c8e-42ec-9353-7334732ef488/scratchpad/aws4
RATE=2.90
case "${1:-status}" in
  status)
    IID=$(aws ec2 describe-instances --filters Name=tag:Name,Values=swiftcore-build Name=instance-state-name,Values=running,pending --query 'Reservations[].Instances[0].InstanceId' --output text 2>/dev/null|head -1)
    [ -z "$IID" -o "$IID" = "None" ] && { echo "no build box"; exit 0; }
    L=$(aws ec2 describe-instances --instance-ids $IID --query 'Reservations[0].Instances[0].LaunchTime' --output text)
    H=$(python3 -c "import datetime;t=datetime.datetime.fromisoformat('$L'.replace('Z','+00:00'));print(round((datetime.datetime.now(datetime.timezone.utc)-t).total_seconds()/3600,2))")
    echo "$IID up ${H}h  ~\$$(python3 -c "print(round($H*$RATE,2))")" ;;
  ssh) exec ssh -o StrictHostKeyChecking=no -o IdentitiesOnly=yes -i $K/key.pem ubuntu@$(cat $K/ip.txt) ;;
  terminate)
    read IID SG < $K/state.txt
    aws ec2 terminate-instances --instance-ids $IID --query 'TerminatingInstances[0].CurrentState.Name' --output text
    aws ec2 wait instance-terminated --instance-ids $IID 2>/dev/null && aws ec2 delete-security-group --group-id $SG 2>/dev/null; aws ec2 delete-key-pair --key-name swiftbuild 2>/dev/null; echo terminated ;;
esac
