#!/bin/bash
# Provision a build box for the _Concurrency work, and NOTHING else.
#
# SAFETY: this AWS account carries the user's production infrastructure
# (camel-api-production, camelai web, ...). Every resource created here is
# tagged Name=swiftcore-concurrency and its ids are written to
# .work-concurrency/state.env. Teardown acts on those recorded ids ONLY —
# never on a filter, never on "all stopped instances".
set -euo pipefail
W=${W:-/Users/miguelsalinas/swiftcore-macho/.work-concurrency}
REGION=${REGION:-us-west-2}
NAME=swiftcore-concurrency
TYPE=${TYPE:-c8g.16xlarge}          # 64 vCPU Graviton4
AMI=${AMI:-ami-0d81b5e3fc6de11fe}   # Ubuntu 24.04 arm64, us-west-2
mkdir -p "$W"; chmod 700 "$W"

if [ -f "$W/state.env" ]; then
  echo "state.env already exists — refusing to provision a second box:"
  cat "$W/state.env"; exit 1
fi

MYIP=$(curl -s https://checkip.amazonaws.com | tr -d '\n')
VPC=$(aws ec2 describe-vpcs --region "$REGION" --filters Name=isDefault,Values=true \
        --query 'Vpcs[0].VpcId' --output text)

SG=$(aws ec2 create-security-group --region "$REGION" --vpc-id "$VPC" \
       --group-name "$NAME-$(date +%s)" --description "swiftcore concurrency build" \
       --query GroupId --output text)
aws ec2 create-tags --region "$REGION" --resources "$SG" --tags Key=Name,Value=$NAME
aws ec2 authorize-security-group-ingress --region "$REGION" --group-id "$SG" \
   --protocol tcp --port 22 --cidr "$MYIP/32" >/dev/null

KEY="$NAME-$(date +%s)"
aws ec2 create-key-pair --region "$REGION" --key-name "$KEY" \
   --query KeyMaterial --output text > "$W/key.pem"
chmod 600 "$W/key.pem"

IID=$(aws ec2 run-instances --region "$REGION" --image-id "$AMI" --instance-type "$TYPE" \
   --key-name "$KEY" --security-group-ids "$SG" \
   --block-device-mappings 'DeviceName=/dev/sda1,Ebs={VolumeSize=200,VolumeType=gp3,DeleteOnTermination=true}' \
   --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$NAME}]" \
   --instance-initiated-shutdown-behavior terminate \
   --user-data '#!/bin/bash
shutdown -h +360' \
   --query 'Instances[0].InstanceId' --output text)

cat > "$W/state.env" <<EOF
REGION=$REGION
INSTANCE_ID=$IID
SECURITY_GROUP=$SG
KEY_NAME=$KEY
CREATED=$(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

aws ec2 wait instance-running --region "$REGION" --instance-ids "$IID"
IP=$(aws ec2 describe-instances --region "$REGION" --instance-ids "$IID" \
      --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
echo "IP=$IP" >> "$W/state.env"
echo "$IP" > "$W/ip.txt"
cat "$W/state.env"
