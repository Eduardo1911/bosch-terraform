#!/bin/bash

VM_COUNT=$1
VM_IDS=("${@:2}")
SOURCE=${VM_IDS[0]}

for DESTINATION in "${VM_IDS[@]}"; do
  ping -c 1 -W 1 $(aws ec2 describe-instances --region eu-central-1 --instance-ids $DESTINATION --query "Reservations[0].Instances[0].PublicIpAddress" --output text) > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "Ping from $SOURCE to $DESTINATION: PASS"
  else
    echo "Ping from $SOURCE to $DESTINATION: FAIL"
  fi
done