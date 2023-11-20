#!/bin/bash

# Arguments
VM_COUNT=$1
VM_IPS="${@:2}"

# Get the current VM's index
CURRENT_VM_INDEX=$(hostname | grep -o '[0-9]*')

# Ping Test
for ((i=0; i<$VM_COUNT; i++)); do
  SOURCE_IP=$(echo $VM_IPS | cut -d ' ' -f $((i+1)))
  DESTINATION_INDEX=$(( (i+1) % VM_COUNT ))
  DESTINATION_IP=$(echo $VM_IPS | cut -d ' ' -f $((DESTINATION_INDEX + 1)))

  # Run ping and capture result
  ping_result=$(ping -c 1 $DESTINATION_IP > /dev/null 2>&1 && echo "pass" || echo "fail")

  # Output the ping result
  if [ $i -eq $CURRENT_VM_INDEX ]; then
    echo "Ping from $SOURCE_IP to $DESTINATION_IP: $ping_result" > /tmp/ping_results.txt
  fi
done
