#!/bin/bash

# Arguments
VM_COUNT=$1
VM_IPS="${@:2}"

# Ping Test
for ((i=0; i<$VM_COUNT; i++)); do
  SOURCE_IP=$(echo $VM_IPS | cut -d ' ' -f $((i+1)))
  DESTINATION_INDEX=$(( (i+1) % VM_COUNT ))
  DESTINATION_IP=$(echo $VM_IPS | cut -d ' ' -f $((DESTINATION_INDEX + 1)))

  # Run ping and capture result
  ping_result=$(ping -c 1 $DESTINATION_IP > /dev/null 2>&1 && echo "pass" || echo "fail")

  # Output the ping result
  echo "Ping from $SOURCE_IP to $DESTINATION_IP: $ping_result"
done