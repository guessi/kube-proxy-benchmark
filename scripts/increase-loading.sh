#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

TARGET_REPLICAS=50

for replicas in $(seq 10 10 $TARGET_REPLICAS); do
  CURRENT_REPLICA=$(kubectl -n  debug get deployment nginx-deployment -o json | jq -r .spec.replicas)
  if [[ $CURRENT_REPLICA -lt $replicas ]]; then
    kubectl -n debug scale deployment nginx-deployment --replicas "${replicas}"

    echo "Waiting 10 seconds after scaling setting replica count to ${replicas}..."
    sleep 10
  fi
done
